--[[ InteractController
    Client-side interaction system with proximity prompts and custom UI.
    Manages interaction feedback, keybinds, cooldowns, and state visualization.
    @author @Daystopia
    @version 1.0.8
    @date 2025-03-27
]]
local InteractController = {}

InteractController.Dependencies = {
    "Event"
}

InteractController.Modules = {
    "Interact",
    "Action"
}

--[[ Types ]]
type PromptData = {
    prompt: ProximityPrompt,
    inputType: Enum.ProximityPromptInputType?,
    player: Player?,
    duration: number?
}

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

--[[ State ]]
local Controllers
local Modules
local PromptUI

--[[ Utility ]]
local Utility = {
    Controller = require(ReplicatedStorage.Modules.Utility.Controller),
    Sound = require(ReplicatedStorage.Modules.Utility.Sound),
    Scale = require(ReplicatedStorage.Modules.Utility.Scale),
    Style = require(ReplicatedStorage.Modules.Utility.Style)
}

--[[ Constants ]]
local INTERACTION_COOLDOWN = 0.1
local TOOLTIP_DURATION = 3
local AlternateKeys = {"F", "R", "T", "G", "V", "B", "Y", "H", "N"}

--[[ Input Mappings ]]
local InputDisplay = {
    -- Gamepad Buttons
    [Enum.KeyCode.ButtonX] = { image = "rbxasset://textures/ui/Controls/xboxX.png" },
    [Enum.KeyCode.ButtonY] = { image = "rbxasset://textures/ui/Controls/xboxY.png" },
    [Enum.KeyCode.ButtonA] = { image = "rbxasset://textures/ui/Controls/xboxA.png" },
    [Enum.KeyCode.ButtonB] = { image = "rbxasset://textures/ui/Controls/xboxB.png" },
    [Enum.KeyCode.DPadLeft] = { image = "rbxasset://textures/ui/Controls/dpadLeft.png" },
    [Enum.KeyCode.DPadRight] = { image = "rbxasset://textures/ui/Controls/dpadRight.png" },
    [Enum.KeyCode.DPadUp] = { image = "rbxasset://textures/ui/Controls/dpadUp.png" },
    [Enum.KeyCode.DPadDown] = { image = "rbxasset://textures/ui/Controls/dpadDown.png" },
    [Enum.KeyCode.ButtonSelect] = { image = "rbxasset://textures/ui/Controls/xboxmenu.png" },
    [Enum.KeyCode.ButtonL1] = { image = "rbxasset://textures/ui/Controls/xboxLS.png" },
    [Enum.KeyCode.ButtonR1] = { image = "rbxasset://textures/ui/Controls/xboxRS.png" },

    -- Special Keyboard Keys
    [Enum.KeyCode.Backspace] = { image = "rbxasset://textures/ui/Controls/backspace.png" },
    [Enum.KeyCode.Return] = { image = "rbxasset://textures/ui/Controls/return.png" },
    [Enum.KeyCode.LeftShift] = { image = "rbxasset://textures/ui/Controls/shift.png" },
    [Enum.KeyCode.RightShift] = { image = "rbxasset://textures/ui/Controls/shift.png" },
    [Enum.KeyCode.Tab] = { image = "rbxasset://textures/ui/Controls/tab.png" },
    [Enum.KeyCode.Space] = { image = "rbxasset://textures/ui/Controls/spacebar.png" },

    -- Special Characters
    ["'"] = { image = "rbxasset://textures/ui/Controls/apostrophe.png" },
    [","] = { image = "rbxasset://textures/ui/Controls/comma.png" },
    ["`"] = { image = "rbxasset://textures/ui/Controls/graveaccent.png" },
    ["."] = { image = "rbxasset://textures/ui/Controls/period.png" },

    -- Text Mappings
    [Enum.KeyCode.LeftControl] = { text = "Ctrl" },
    [Enum.KeyCode.RightControl] = { text = "Ctrl" },
    [Enum.KeyCode.LeftAlt] = { text = "Alt" },
    [Enum.KeyCode.RightAlt] = { text = "Alt" },
    [Enum.KeyCode.F1] = { text = "F1" },
    [Enum.KeyCode.F2] = { text = "F2" },
    [Enum.KeyCode.F3] = { text = "F3" },
    [Enum.KeyCode.F4] = { text = "F4" },
    [Enum.KeyCode.F5] = { text = "F5" },
    [Enum.KeyCode.F6] = { text = "F6" },
    [Enum.KeyCode.F7] = { text = "F7" },
    [Enum.KeyCode.F8] = { text = "F8" },
    [Enum.KeyCode.F9] = { text = "F9" },
    [Enum.KeyCode.F10] = { text = "F10" },
    [Enum.KeyCode.F11] = { text = "F11" },
    [Enum.KeyCode.F12] = { text = "F12" }
}

--[[ State Variables ]]
local State = {
    LocalPlayer = Players.LocalPlayer,
    PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui"),
    PromptsPerParent = {} :: {[Instance]: {ProximityPrompt}},
    ActiveBillboards = {} :: {[ProximityPrompt]: BillboardGui},
    ActiveProgress = {} :: {[ProximityPrompt]: {startTime: number, duration: number}},
    ActiveHighlights = {} :: {[Instance]: Highlight},
    ActiveTooltips = {} :: {[Instance]: BillboardGui},
    LastInteractionTime = {} :: {[ProximityPrompt]: number},
    ActiveScreenPrompts = {} :: {ProximityPrompt},
    ActiveClickDetectors = {} :: {[Instance]: ClickDetector},
    HoveredPrompts = {} :: {[ProximityPrompt]: boolean}
}

--[[ Events ]]
InteractController.Events = {
    Trigger = true,
    Show = true,
    Hide = true,
    Start = true,
    End = true,
    Right = true
}

--[[ Listeners ]]
InteractController.Listeners = {
    ["Interact.Create"] = function(self, data)
        local prompt = data.prompt
        local template = data.template
        if not (prompt and template) then return end
        prompt:SetAttribute("STYLE", template.style)
    end
}

--[[ UI Functions ]]
function InteractController:CreatePrompt()
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 125, 0, 62)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    container.BackgroundTransparency = 0.2
    container.BorderSizePixel = 0

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = container

    local actionText = Instance.new("TextLabel")
    actionText.Name = "ActionText"
    actionText.Size = UDim2.new(1, 0, 0.35, 0)
    actionText.Position = UDim2.new(0, 0, 0.1, 0)
    actionText.BackgroundTransparency = 1
    actionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionText.FontFace = Font.new(Utility.Style.Typography.Body.Font, Utility.Style.Typography.Body.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    actionText.TextWrapped = true
    actionText.TextScaled = true
    actionText.TextXAlignment = Enum.TextXAlignment.Center
    actionText.TextYAlignment = Enum.TextYAlignment.Center
    actionText.RichText = true
    actionText.Parent = container

    local keyText = Instance.new("TextLabel")
    keyText.Name = "KeyText"
    keyText.Size = UDim2.new(1, 0, 0.25, 0)
    keyText.Position = UDim2.new(0, 0, 0.40, 0)
    keyText.BackgroundTransparency = 1
    keyText.TextColor3 = Color3.fromRGB(200, 200, 200)
    keyText.FontFace = Font.new(Utility.Style.Typography.Body.Font, Utility.Style.Typography.Body.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    keyText.TextWrapped = true
    keyText.TextScaled = true
    keyText.TextXAlignment = Enum.TextXAlignment.Center
    keyText.TextYAlignment = Enum.TextYAlignment.Center
    keyText.RichText = true
    keyText.Parent = container

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0.8, 0, 0.15, 0)
    progressBar.Position = UDim2.new(0.1, 0, 0.7, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBar.BackgroundTransparency = 0.5
    progressBar.BorderSizePixel = 0
    progressBar.Visible = false
    progressBar.Parent = container

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 4)
    progressCorner.Parent = progressBar

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(65, 140, 240)
    fill.BorderSizePixel = 0
    fill.Parent = progressBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    return container
end

function InteractController:UpdateScreenPromptPositions()
    local count = #State.ActiveScreenPrompts
    if count == 0 then return end

    local spacing = 10
    local containerWidth = 125
    local totalWidth = (containerWidth * count) + (spacing * (count - 1))

    for i, prompt in ipairs(State.ActiveScreenPrompts) do
        local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
        if container then
            container.AnchorPoint = Vector2.new(0.5, 0)
            container.Position = UDim2.new(
                0.5,
                ((i - (count + 1)/2) * (containerWidth + spacing)),
                0.8,
                0
            )
        end
    end
end

function InteractController:CreateScreenPrompt()
    local promptGui = Instance.new("ScreenGui")
    promptGui.Name = "InteractPrompt"
    promptGui.ResetOnSpawn = false
    promptGui.Parent = State.PlayerGui
    return promptGui
end

function InteractController:CreateScreenContainer(prompt: ProximityPrompt)
    local container = self:CreatePrompt()
    container.Name = "Container_" .. prompt:GetAttribute("ACTION")
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.Position = UDim2.new(0.5, 0, 0.8, 0)
    container.Visible = false
    container.Parent = PromptUI

    Utility.Scale.AutoScale(container)
    return container
end

function InteractController:CreateBillboardPrompt(parent: BasePart, template)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "InteractPrompt"
    billboardGui.Size = UDim2.fromScale(2.5, 1.25)
    local offset = template and (
        type(template.offset) == "table" and template.offset.prompt or
        template.offset or
        Vector3.new(0, 1.5, 0)
    )
    billboardGui.StudsOffset = offset
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 40

    local container = self:CreatePrompt()
    container.Size = UDim2.fromScale(1, 1)
    container.Position = UDim2.fromScale(0, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Parent = billboardGui

    container.ActionText.TextSize = 20
    container.KeyText.TextSize = 18

    billboardGui.Parent = parent
    return billboardGui
end

function InteractController:UpdateTooltipPositions(parent: Instance)
    if not State.PromptsPerParent[parent] then return end

    local tooltipGui = State.ActiveTooltips[parent]
    if not tooltipGui then return end

    local promptCount = #State.PromptsPerParent[parent]
    if promptCount == 0 then return end

    local highestOffset = Vector3.new(0, 0, 0)
    for _, prompt in ipairs(State.PromptsPerParent[parent]) do
        local template = Modules.Interact.Templates[prompt:GetAttribute("ACTION"):lower()]
        if template then
            local tooltipOffset = type(template.offset) == "table" and template.offset.tooltip or
                Vector3.new(0, 3, 0)
            if tooltipOffset.Y > highestOffset.Y then
                highestOffset = tooltipOffset
            end
        end
    end

    highestOffset = highestOffset + Vector3.new(0, (promptCount - 1) * 1.5, 0)
    tooltipGui.StudsOffset = highestOffset
end

function InteractController:UpdatePromptPositions(parent: Instance)
    if not State.PromptsPerParent[parent] then return end

    for i, prompt in ipairs(State.PromptsPerParent[parent]) do
        local billboard = State.ActiveBillboards[prompt]
        if billboard then
            local template = Modules.Interact.Templates[prompt:GetAttribute("ACTION"):lower()]
            local baseOffset = template and (
                type(template.offset) == "table" and template.offset.prompt or
                template.offset or
                Vector3.new(0, 1.8, 0)
            )
            billboard.StudsOffset = baseOffset + Vector3.new(0, (i - 1) * 1.5, 0)
        end
    end

    self:UpdateTooltipPositions(parent)
end

function InteractController:CreateTooltip(parent: Instance, isScreen: boolean?)
    if isScreen then
        local container = Instance.new("Frame")
        container.Name = "TooltipContainer"
        container.Size = UDim2.fromScale(0.08, 0.03)
        container.Position = UDim2.new(0.5, 0, 0.7, 0)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        container.BackgroundTransparency = 0.2
        container.BorderSizePixel = 0
        container.Parent = PromptUI

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = container

        local uiPadding = Instance.new("UIPadding")
        uiPadding.PaddingLeft = UDim.new(0.05, 0)
        uiPadding.PaddingRight = UDim.new(0.05, 0)
        uiPadding.PaddingTop = UDim.new(0.1, 0)
        uiPadding.PaddingBottom = UDim.new(0.1, 0)
        uiPadding.Parent = container

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TooltipText"
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.Position = UDim2.fromScale(0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextTransparency = 1
        textLabel.FontFace = Font.new(Utility.Style.Typography.Body.Font, Utility.Style.Typography.Body.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        textLabel.TextWrapped = true
        textLabel.TextScaled = true
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.Parent = container

        return container, textLabel
    else
        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "TooltipGui"
        billboardGui.Size = UDim2.fromScale(2.5, 0.6)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.MaxDistance = 40

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.fromScale(1, 1)
        container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        container.BackgroundTransparency = 0.2
        container.BorderSizePixel = 0
        container.Parent = billboardGui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = container

        local uiPadding = Instance.new("UIPadding")
        uiPadding.PaddingLeft = UDim.new(0.05, 0)
        uiPadding.PaddingRight = UDim.new(0.05, 0)
        uiPadding.PaddingTop = UDim.new(0.1, 0)
        uiPadding.PaddingBottom = UDim.new(0.1, 0)
        uiPadding.Parent = container

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TooltipText"
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.Position = UDim2.fromScale(0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextTransparency = 1
        textLabel.FontFace = Font.new(Utility.Style.Typography.Body.Font, Utility.Style.Typography.Body.Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        textLabel.TextWrapped = true
        textLabel.TextScaled = true
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.Parent = container

        billboardGui.Parent = parent
        return billboardGui, textLabel
    end
end

function InteractController:CleanupTooltip(parent: Instance)
    local tooltip = State.ActiveTooltips[parent]
    if tooltip then
        if tooltip.Parent then
            tooltip:Destroy()
        end
        State.ActiveTooltips[parent] = nil
    end
end

function InteractController:ShowTooltip(parent: Instance, isScreen: boolean?)
    if State.ActiveTooltips[parent] then
        if typeof(State.ActiveTooltips[parent]) == "Instance" then
            State.ActiveTooltips[parent]:Destroy()
        end
        State.ActiveTooltips[parent] = nil
    end

    local detector = parent:FindFirstChildWhichIsA("ClickDetector")
    local prompt = parent:FindFirstChildWhichIsA("ProximityPrompt")
    local maxDistance = 8

    if detector then
        maxDistance = detector.MaxActivationDistance
    elseif prompt then
        maxDistance = prompt.MaxActivationDistance
    end

    if not isScreen then
        local character = State.LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart or (rootPart.Position - parent.Position).Magnitude > maxDistance then
            self:CleanupTooltip(parent)
            return
        end
    end

    local tooltipUI, textLabel = self:CreateTooltip(parent, isScreen)
    State.ActiveTooltips[parent] = tooltipUI

    local name = parent:GetAttribute("NAME")
    if not name then
        local model = parent
        if parent:IsA("BasePart") then
            while model and model.Parent ~= workspace do
                model = model.Parent
                if model:IsA("Model") and model:GetAttribute("NAME") then
                    break
                end
            end
        end
        name = model:GetAttribute("NAME") or model.Name
    end

    textLabel.Text = name

    local frame = isScreen and tooltipUI or tooltipUI:FindFirstChildOfClass("Frame")
    if not frame then return end

    frame.BackgroundTransparency = 1
    textLabel.TextTransparency = 1

    if not isScreen then
        self:UpdateTooltipPositions(parent)
    else
        local promptCount = #State.ActiveScreenPrompts
        if promptCount > 0 then
            frame.Position = UDim2.new(0.5, 0, 0.7, 60 - ((promptCount - 1) * 35))
        end
    end

    Utility.Controller.Group({
        Utility.Controller.To(frame, {
            BackgroundTransparency = 0.2
        }, {
            duration = 0.2,
            easingStyle = Utility.Controller.Easing.Linear
        }),
        Utility.Controller.To(textLabel, {
            TextTransparency = 0
        }, {
            duration = 0.2,
            easingStyle = Utility.Controller.Easing.Linear
        })
    })

    task.delay(TOOLTIP_DURATION, function()
        if tooltipUI and tooltipUI.Parent then
            Utility.Controller.Group({
                Utility.Controller.To(frame, {
                    BackgroundTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Controller.Easing.Linear
                }),
                Utility.Controller.To(textLabel, {
                    TextTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Controller.Easing.Linear,
                    onComplete = function()
                        tooltipUI:Destroy()
                        State.ActiveTooltips[parent] = nil
                    end
                })
            })
        end
    end)
end

--[[ Core Functions ]]
function InteractController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function InteractController:Start()
    State.PlayerGui = State.LocalPlayer:WaitForChild("PlayerGui")
    PromptUI = self:CreateScreenPrompt()

    self:SetupEvents()
    self:SetupWorkspaceListeners()
    self:SetupRenderStepEvents()

    return true
end

--[[ Utility Functions ]]
function InteractController:CanInteract(player: Player): boolean
    if not player then return false end

    local character = player.Character
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

function InteractController:GetKey(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
    if inputType == Enum.ProximityPromptInputType.Gamepad then
        local gamepadKey = prompt.GamepadKeyCode
        local display = InputDisplay[gamepadKey]
        if display and display.image then
            return string.format(
                "%s <img src='%s' size='16'/>",
                prompt.HoldDuration > 0 and "Hold" or "Press",
                display.image
            )
        end
        return string.format("%s [%s]", prompt.HoldDuration > 0 and "Hold" or "Press", gamepadKey.Name:gsub("Button", ""))
    elseif inputType == Enum.ProximityPromptInputType.Touch then
        return prompt.HoldDuration > 0 and "Hold here" or "Tap here"
    end

    local prompts = State.PromptsPerParent[prompt.Parent]
    local keyCode = prompt.KeyboardKeyCode
    local baseKey = keyCode.Name

    if prompts then
        local keyCount = 0
        for _, p in ipairs(prompts) do
            if p ~= prompt and p.KeyboardKeyCode.Name == baseKey then
                keyCount += 1
            end
        end

        local alternateKey = AlternateKeys[keyCount]
        if keyCount > 0 and alternateKey then
            prompt.KeyboardKeyCode = Enum.KeyCode[alternateKey]
            keyCode = prompt.KeyboardKeyCode
            baseKey = alternateKey
        end
    end

    local display = InputDisplay[keyCode] or InputDisplay[baseKey]
    local keyText
    if display then
        if display.image then
            keyText = string.format("<img src='%s' size='16'/>", display.image)
        else
            keyText = display.text
        end
    else
        keyText = baseKey
    end

    return string.format("%s [%s]", prompt.HoldDuration > 0 and "Hold" or "Press", keyText)
end

function InteractController:UpdatePrompt(container: Frame, prompt: ProximityPrompt, keyText: string, hasHoldDuration: boolean)
    local template = Modules.Interact.Templates[prompt:GetAttribute("ACTION"):lower()]
    if not template then return end

    local function updateActionText()
        local parent = prompt.Parent
        if parent then
            local state = parent:GetAttribute("STATE")
            if state and template.state and template.state[state] then
                local stateValue = template.state[state]
                container.ActionText.Text = type(stateValue) == "table" and stateValue.text or stateValue
                if type(stateValue) == "table" and stateValue.cursor then
                    local detector = parent:FindFirstChildWhichIsA("ClickDetector")
                    if detector then
                        detector.CursorIcon = stateValue.cursor
                    end
                end
            else
                container.ActionText.Text = prompt.ActionText
                if template.cursor then
                    local detector = parent:FindFirstChildWhichIsA("ClickDetector")
                    if detector then
                        detector.CursorIcon = template.cursor
                    end
                end
            end
        end
    end

    updateActionText()

    if prompt.Parent then
        prompt.Parent:GetAttributeChangedSignal("STATE"):Connect(updateActionText)
    end

    container.KeyText.Text = keyText
    container.ProgressBar.Visible = hasHoldDuration

    if template then
        container.ProgressBar.Fill.BackgroundColor3 = template.color
    end

    if not hasHoldDuration then
        container.ActionText.Position = UDim2.new(0, 0, 0.1, 0)
        container.KeyText.Position = UDim2.new(0, 0, 0.5, 0)
    end
end

function InteractController:CreateHighlight(parent: Instance)
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 1

    local function setParent(target)
        highlight.Parent = target
        return highlight
    end

    if parent:IsA("BasePart") then
        if parent:GetAttribute("INTERACTION") then return setParent(parent) end
        local model = parent
        while model and model.Parent ~= workspace do
            model = model.Parent
            if model:IsA("Model") and model:GetAttribute("INTERACTION") then return setParent(model) end
        end
        return setParent(parent)
    elseif parent:IsA("Model") and parent:GetAttribute("INTERACTION") then
        return setParent(parent)
    end
    return setParent(parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart"))
end

function InteractController:CleanupHighlight(parent: Instance)
    local highlight = State.ActiveHighlights[parent]
    if highlight then
        Utility.Controller.To(highlight, {
            OutlineTransparency = 1
        }, {
            duration = 0.2,
            easingStyle = Utility.Controller.Easing.Linear,
            onComplete = function()
                highlight:Destroy()
                State.ActiveHighlights[parent] = nil
            end
        })
    end
end

function InteractController:FlashHighlight(parent: Instance, duration: number)
    local highlight = State.ActiveHighlights[parent]
    if highlight then
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        task.wait(duration)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

function InteractController:CheckCooldown(prompt, currentTime)
    if not self:CanInteract(State.LocalPlayer) then
        Utility.Sound.Prompt("Error")
        self:FlashHighlight(prompt.Parent, INTERACTION_COOLDOWN)
        return true
    end

    local actionType = prompt:GetAttribute("ACTION")
    if not actionType then return false end

    local actionConfig = Modules.Action.Types and Modules.Action.Types[actionType:upper()]
    if not actionConfig then return false end

    local cooldown = actionConfig.cooldown or INTERACTION_COOLDOWN
    local lastInteraction = State.LastInteractionTime[prompt]

    if lastInteraction and (currentTime - lastInteraction) < cooldown then
        Utility.Sound.Prompt("Error")
        self:FlashHighlight(prompt.Parent, cooldown)
        return true
    end

    State.LastInteractionTime[prompt] = currentTime
    return false
end

-- [[ Prompt Events ]]
function InteractController:Triggered(prompt: ProximityPrompt)
    local style = prompt:GetAttribute("STYLE")
    if style == "default" then return end

    local currentTime = os.clock()
    if self:CheckCooldown(prompt, currentTime) then return end

    Utility.Sound.Prompt("Click")

    local container = style == "custom"
        and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
    or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container)
    if not container then return end

    prompt:SetAttribute("OriginalContainerSize", container.Size)
    prompt:SetAttribute("OriginalBgTransparency", container.BackgroundTransparency)

    local scale = 0.9
    local currentSize = container.Size
    local newSize = UDim2.new(
        currentSize.X.Scale * scale,
        currentSize.X.Offset * scale,
        currentSize.Y.Scale * scale,
        currentSize.Y.Offset * scale
    )

    Utility.Controller.To(container, {
        Size = newSize,
        BackgroundTransparency = 0
    }, {
        duration = 0.06
    })

    local billboard = container.Parent
    if billboard:IsA("BillboardGui") then
        prompt:SetAttribute("OriginalBillboardSize", billboard.Size)

        local newBillboardSize = UDim2.new(
            billboard.Size.X.Scale * scale,
            billboard.Size.X.Offset * scale,
            billboard.Size.Y.Scale * scale,
            billboard.Size.Y.Offset * scale
        )

        Utility.Controller.To(billboard, {Size = newBillboardSize}, {duration = 0.06})
    end
end

function InteractController:TriggerEnded(prompt: ProximityPrompt)
    local style = prompt:GetAttribute("STYLE")
    if style == "default" then return end

    local container = style == "custom" 
        and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
        or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container)
    if not container then return end

    local originalSize = prompt:GetAttribute("OriginalContainerSize") or container.Size
    local originalBgTransparency = prompt:GetAttribute("OriginalBgTransparency") or container.BackgroundTransparency

    Utility.Controller.To(container, {
        Size = originalSize,
        BackgroundTransparency = originalBgTransparency
    }, {
        duration = 0.06
    })

    local billboard = container.Parent
    if billboard:IsA("BillboardGui") then
        local originalBillboardSize = prompt:GetAttribute("OriginalBillboardSize") or billboard.Size
        Utility.Controller.To(billboard, {Size = originalBillboardSize}, {duration = 0.06})
    end

    prompt:SetAttribute("OriginalContainerSize", nil)
    prompt:SetAttribute("OriginalBgTransparency", nil)
    prompt:SetAttribute("OriginalBillboardSize", nil)

    Controllers.Event:FireServer("Interact.Trigger", {prompt = prompt})
end

function InteractController:Shown(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
    if not self:CanInteract(State.LocalPlayer) then return end

    local style = prompt:GetAttribute("STYLE")
    if style == "default" then return end

    Utility.Sound.Prompt("Hover")

    local parent = prompt.Parent
    if not parent then return end

    local highlight = State.ActiveHighlights[parent]
    if not highlight then
        highlight = self:CreateHighlight(parent)
        State.ActiveHighlights[parent] = highlight
    end

    local template = Modules.Interact.Templates[prompt:GetAttribute("ACTION"):lower()]
    if template and template.highlightColor then
        highlight.OutlineColor = template.highlightColor
    else
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end

    Utility.Controller.To(highlight, {
        OutlineTransparency = 0.2
    }, {
        duration = 0.2,
        easingStyle = Utility.Controller.Easing.Linear
    })

    local hasHoldDuration = prompt.HoldDuration > 0
    local keyText = self:GetKey(prompt, inputType)

    if style == "custom" then
        local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
        if not container then
            container = self:CreateScreenContainer(prompt)
        end
        self:UpdatePrompt(container, prompt, keyText, hasHoldDuration)
        container.Visible = true
        table.insert(State.ActiveScreenPrompts, prompt)
        self:UpdateScreenPromptPositions()
        self:ShowTooltip(prompt.Parent, true)
    elseif style == "billboard" then
        local parent = prompt.Parent
        if not parent:IsA("BasePart") then return end

        if not State.PromptsPerParent[parent] then
            State.PromptsPerParent[parent] = {}
        end
        table.insert(State.PromptsPerParent[parent], prompt)

        local billboard = State.ActiveBillboards[prompt]
        if not billboard then
            billboard = self:CreateBillboardPrompt(parent, template)
            State.ActiveBillboards[prompt] = billboard
        else
            billboard.Parent = parent
            billboard.Enabled = true
        end

        self:UpdatePromptPositions(parent)
        self:UpdatePrompt(billboard.Container, prompt, keyText, hasHoldDuration)
        self:ShowTooltip(prompt.Parent, false)
    end

    Controllers.Event:FireServer("Interact.Show", {
        prompt = prompt,
        inputType = inputType
    })
end

function InteractController:Hidden(prompt: ProximityPrompt)
    local style = prompt:GetAttribute("STYLE")
    if style == "default" then return end

    if style == "custom" then
        local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
        if container then
            container.Visible = false
            container.ProgressBar.Visible = false
            Utility.Controller.UpdateProgress(container.ProgressBar, 0)
        end

        for i, p in ipairs(State.ActiveScreenPrompts) do
            if p == prompt then
                table.remove(State.ActiveScreenPrompts, i)
                break
            end
        end
        self:UpdateScreenPromptPositions()

        local parent = prompt.Parent
        if parent then
            local hasRemainingPrompts = false
            for _, p in ipairs(State.ActiveScreenPrompts) do
                if p.Parent == parent then
                    hasRemainingPrompts = true
                    break
                end
            end

            if not hasRemainingPrompts then
                self:CleanupHighlight(parent)
                self:CleanupTooltip(parent)
            end
        end
    elseif style == "billboard" then
        local billboard = State.ActiveBillboards[prompt]
        if billboard then
            billboard.Enabled = false
            billboard.Container.ProgressBar.Visible = false
            billboard.Container.ProgressBar.Fill.Size = UDim2.new(0, 0, 1, 0)
        end
    end

    local parent = prompt.Parent
    if not parent then return end

    if State.PromptsPerParent[parent] then
        for i, p in ipairs(State.PromptsPerParent[parent]) do
            if p == prompt then
                table.remove(State.PromptsPerParent[parent], i)
                break
            end
        end

        if #State.PromptsPerParent[parent] == 0 then
            State.PromptsPerParent[parent] = nil
            self:CleanupHighlight(parent)
            self:CleanupTooltip(parent)
        else
            self:UpdatePromptPositions(parent)
        end
    end

    local model = parent:FindFirstAncestorOfClass("Model")
    if model and model ~= parent then
        local modelHasPrompts = false
        for _, part in ipairs(model:GetDescendants()) do
            if State.PromptsPerParent[part] and #State.PromptsPerParent[part] > 0 then
                modelHasPrompts = true
                break
            end
        end

        if not modelHasPrompts and State.ActiveHighlights[model] then
            Utility.Controller.To(State.ActiveHighlights[model], {
                OutlineTransparency = 1
            }, {
                duration = 0.2,
                easingStyle = Utility.Controller.Easing.Linear,
                onComplete = function()
                    if State.ActiveHighlights[model] then
                        State.ActiveHighlights[model]:Destroy()
                        State.ActiveHighlights[model] = nil
                    end
                end
            })
            self:CleanupTooltip(model)
        else
            local hasRemainingPrompts = false
            if parent:IsA("Model") then
                for _, part in ipairs(parent:GetDescendants()) do
                    if State.PromptsPerParent[part] and #State.PromptsPerParent[part] > 0 then
                        hasRemainingPrompts = true
                        break
                    end
                end
            else
                hasRemainingPrompts = State.PromptsPerParent[parent] and #State.PromptsPerParent[parent] > 0
            end

            if not hasRemainingPrompts and State.ActiveHighlights[parent] then
                Utility.Controller.To(State.ActiveHighlights[parent], {
                    OutlineTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Controller.Easing.Linear,
                    onComplete = function()
                        if State.ActiveHighlights[parent] then
                            State.ActiveHighlights[parent]:Destroy()
                            State.ActiveHighlights[parent] = nil
                        end
                    end
                })
                self:CleanupTooltip(parent)
            end
        end
    end

    State.ActiveProgress[prompt] = nil
    State.LastInteractionTime[prompt] = nil

    Controllers.Event:FireServer("Interact.Hide", {prompt = prompt})
end

function InteractController:HoldBegan(prompt: ProximityPrompt, player: Player)
    local style = prompt:GetAttribute("STYLE")
    if style == "default" then return end

    local duration = prompt.HoldDuration
    if duration > 0 then
        local progressBar = style == "custom"
            and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
        or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container.ProgressBar)

        if progressBar then
            progressBar.Visible = true
            progressBar.Fill.Size = UDim2.new(0, 0, 1, 0)
        end

        State.ActiveProgress[prompt] = {
            startTime = tick(),
            duration = duration
        }
    else
        local container = style == "custom"
            and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
        or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container)

        if container then
            local scale = 0.9
            local currentSize = container.Size
            local newSize = UDim2.new(
                currentSize.X.Scale * scale,
                currentSize.X.Offset * scale,
                currentSize.Y.Scale * scale,
                currentSize.Y.Offset * scale
            )

            Utility.Controller.To(container, {
                Size = newSize,
                BackgroundTransparency = 0
            }, {
                duration = 0.06
            })

            local billboard = container.Parent
            if billboard:IsA("BillboardGui") then
                local originalBillboardSize = billboard.Size
                local newBillboardSize = UDim2.new(
                    originalBillboardSize.X.Scale * scale,
                    originalBillboardSize.X.Offset * scale,
                    originalBillboardSize.Y.Scale * scale,
                    originalBillboardSize.Y.Offset * scale
                )

                Utility.Controller.To(billboard, {Size = newBillboardSize}, {duration = 0.06})
            end
        end
    end

    Controllers.Event:FireServer("Interact.Start", {
        prompt = prompt,
        player = player,
        duration = duration
    })
end

function InteractController:HoldEnded(prompt: ProximityPrompt, player: Player)
    local style = prompt:GetAttribute("STYLE")
    if style == "default" then return end

    local progressData = State.ActiveProgress[prompt]
    if progressData then
        local progressBar = style == "custom"
            and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
        or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container.ProgressBar)

        if progressBar then
            local elapsed = tick() - progressData.startTime
            local progress = elapsed / progressData.duration

            if progress >= 0.95 then
                progressBar.Fill.Size = UDim2.new(1, 0, 1, 0)
                task.wait(0.1)
                progressBar.Visible = false
                progressBar.Fill.Size = UDim2.new(0, 0, 1, 0)
            else
                Utility.Controller.To(progressBar.Fill, {
                    Size = UDim2.new(0, 0, 1, 0)
                }, {
                    duration = 0.15,
                    easingStyle = Utility.Controller.Easing.Quad,
                    onComplete = function()
                        progressBar.Visible = false
                    end
                })
            end
        end

        State.ActiveProgress[prompt] = nil
    end

    Controllers.Event:FireServer("Interact.End", {
        prompt = prompt,
        player = player
    })
end

--[[ Click Events ]]
function InteractController:MouseClick(detector: ClickDetector)
    if not self:CanInteract(State.LocalPlayer) then
        Utility.Sound.Prompt("Error")
        self:FlashHighlight(detector.Parent, INTERACTION_COOLDOWN)
        return
    end

    local style = detector:GetAttribute("STYLE")
    if style == "default" then return end

    local currentTime = os.clock()
    if self:CheckCooldown(detector, currentTime) then return end

    Utility.Sound.Prompt("Click")

    local actionType = detector:GetAttribute("ACTION")
    if not actionType then return end

    local container
    if style == "custom" then
        container = PromptUI:FindFirstChild("Container_" .. actionType)
    elseif style == "billboard" then
        local billboard = detector.Parent:FindFirstChild("InteractPrompt")
        if billboard then
            container = billboard:FindFirstChild("Container")
        end
    end

    if not container then return end

    detector:SetAttribute("OriginalContainerSize", container.Size)
    detector:SetAttribute("OriginalBgTransparency", container.BackgroundTransparency)

    local scale = 0.9
    local currentSize = container.Size
    local newSize = UDim2.new(
        currentSize.X.Scale * scale,
        currentSize.X.Offset * scale,
        currentSize.Y.Scale * scale,
        currentSize.Y.Offset * scale
    )

    Utility.Controller.To(container, {
        Size = newSize,
        BackgroundTransparency = 0
    }, {
        duration = 0.06,
        onComplete = function()
            local originalSize = detector:GetAttribute("OriginalContainerSize")
            local originalBgTransparency = detector:GetAttribute("OriginalBgTransparency")

            if originalSize and originalBgTransparency then
                Utility.Controller.To(container, {
                    Size = originalSize,
                    BackgroundTransparency = originalBgTransparency
                }, {
                    duration = 0.06
                })

                detector:SetAttribute("OriginalContainerSize", nil)
                detector:SetAttribute("OriginalBgTransparency", nil)
            end
        end
    })

    Controllers.Event:FireServer("Interact.Trigger", {detector = detector})
end

function InteractController:MouseHoverEnter(detector: ClickDetector)
    if not self:CanInteract(State.LocalPlayer) then return end

    local style = detector:GetAttribute("STYLE")
    if style == "default" then return end

    local actionType = detector:GetAttribute("ACTION")
    if not actionType then return end

    Utility.Sound.Prompt("Hover")

    local parent = detector.Parent
    if not parent then return end

    local highlight = State.ActiveHighlights[parent]
    if not highlight then
        highlight = self:CreateHighlight(parent)
        State.ActiveHighlights[parent] = highlight
    end

    local template = Modules.Interact.Templates[actionType:lower()]
    if template and template.highlightColor then
        highlight.OutlineColor = template.highlightColor
    else
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end

    Utility.Controller.To(highlight, {
        OutlineTransparency = 0.2
    }, {
        duration = 0.2,
        easingStyle = Utility.Controller.Easing.Linear
    })

    Controllers.Event:FireServer("Interact.Show", {detector = detector})
end

function InteractController:MouseHoverLeave(detector: ClickDetector)
    local style = detector:GetAttribute("STYLE")
    if style == "default" then return end

    local parent = detector.Parent
    if not parent then return end

    State.LastInteractionTime[detector] = nil

    Controllers.Event:FireServer("Interact.Hide", {detector = detector})
end

function InteractController:RightMouseClick(detector: ClickDetector)
    local style = detector:GetAttribute("STYLE")
    if style == "default" then return end

    local currentTime = os.clock()
    if self:CheckCooldown(detector, currentTime) then return end

    Utility.Sound.Prompt("Click")

    local actionType = detector:GetAttribute("ACTION")
    if not actionType then return end

    local container = style == "custom"
        and PromptUI:FindFirstChild("Container_" .. actionType)
    or (State.ActiveBillboards[detector] and State.ActiveBillboards[detector].Container)
    if not container then return end

    detector:SetAttribute("OriginalContainerSize", container.Size)
    detector:SetAttribute("OriginalBgTransparency", container.BackgroundTransparency)

    local scale = 0.9
    local currentSize = container.Size
    local newSize = UDim2.new(
        currentSize.X.Scale * scale,
        currentSize.X.Offset * scale,
        currentSize.Y.Scale * scale,
        currentSize.Y.Offset * scale
    )

    Utility.Controller.To(container, {
        Size = newSize,
        BackgroundTransparency = 0
    }, {
        duration = 0.06
    })

    Controllers.Event:FireServer("Interact.Right", {detector = detector})
end

--[[ Initialization ]]
function InteractController:SetupClick(detector: ClickDetector)
    local actionType = detector:GetAttribute("ACTION")
    if not actionType then
        -- warn("Click detector has no ACTION attribute:", detector)
        return
    end

    local template = Modules.Interact.Templates[actionType:lower()]
    if not template then
        warn("No template found for action type:", actionType)
        return
    end

    local parent = detector.Parent
    if not parent then
        warn("Click detector has no parent:", detector)
        return
    end

    local currentState = parent:GetAttribute("STATE")
    local normalizedState = currentState and string.lower(currentState)

    if normalizedState and template.state then
        local stateKey = nil
        for key in pairs(template.state) do
            if string.lower(key) == normalizedState then
                stateKey = key
                break
            end
        end

        if stateKey then
            local stateValue = template.state[stateKey]
            if type(stateValue) == "table" and stateValue.cursor then
                detector.CursorIcon = stateValue.cursor
            else
                warn("No cursor defined for state:", stateKey)
            end
        end
    elseif template.cursor then
        detector.CursorIcon = template.cursor
    else
        warn("No cursor defined in template or state for action type:", actionType)
    end

    detector.MouseClick:Connect(function()
        self:MouseClick(detector)
    end)
    detector.MouseHoverEnter:Connect(function()
        self:MouseHoverEnter(detector)
    end)
    detector.MouseHoverLeave:Connect(function()
        self:MouseHoverLeave(detector)
    end)
    detector.RightMouseClick:Connect(function()
        self:RightMouseClick(detector)
    end)

    if not State.ActiveClickDetectors[detector.Parent] then
        State.ActiveClickDetectors[detector.Parent] = {}
    end
    State.ActiveClickDetectors[detector.Parent][detector.Name] = detector
end

function InteractController:SetupEvents()
    local self = self
    local promptEvents = {
        {ProximityPromptService.PromptShown, function(...) self:Shown(...) end},
        {ProximityPromptService.PromptHidden, function(...) self:Hidden(...) end},
        {ProximityPromptService.PromptButtonHoldBegan, function(...) self:HoldBegan(...) end},
        {ProximityPromptService.PromptButtonHoldEnded, function(...) self:HoldEnded(...) end},
        {ProximityPromptService.PromptTriggered, function(...) self:Triggered(...) end},
        {ProximityPromptService.PromptTriggerEnded, function(...) self:TriggerEnded(...) end}
    }

    for _, event in ipairs(promptEvents) do
        event[1]:Connect(event[2])
    end

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ClickDetector") then
            self:SetupClick(descendant)
        end
    end

    workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ClickDetector") then
            self:SetupClick(descendant)
        end
    end)

    task.spawn(function()
        local RunService = game:GetService("RunService")
        RunService.RenderStepped:Connect(function(deltaTime)
            for prompt, data in pairs(State.ActiveProgress) do
                if not prompt.Enabled then continue end

                local progressBar = prompt:GetAttribute("STYLE") == "custom"
                    and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
                    or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container.ProgressBar)

                if progressBar then
                    local elapsed = (tick() - data.startTime) + deltaTime
                    progressBar.Fill.Size = UDim2.new(math.min(elapsed / data.duration, 1), 0, 1, 0)
                end
            end
        end)
    end)

    task.spawn(function()
        local self = self
        local RunService = game:GetService("RunService")
        RunService.RenderStepped:Connect(function()
            local character = State.LocalPlayer.Character
            local characterRoot = character and character:FindFirstChild("HumanoidRootPart")

            if not characterRoot or not self:CanInteract(State.LocalPlayer) then
                for prompt in pairs(State.HoveredPrompts) do
                    prompt.MaxActivationDistance = 0

                    local style = prompt:GetAttribute("STYLE")
                    if style == "custom" then
                        local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
                        if container then
                            container.Visible = false
                        end
                    elseif style == "billboard" then
                        local billboard = State.ActiveBillboards[prompt]
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
                table.clear(State.HoveredPrompts)

                for _, highlight in pairs(State.ActiveHighlights) do
                    highlight:Destroy()
                end
                table.clear(State.ActiveHighlights)

                for _, tooltip in pairs(State.ActiveTooltips) do
                    if typeof(tooltip) == "Instance" then
                        tooltip:Destroy()
                    end
                end
                table.clear(State.ActiveTooltips)
                return
            end

            local foundPrompts = {}
            local userInputType = UserInputService:GetLastInputType()
            local isTouchOrGamepad = userInputType == Enum.UserInputType.Touch or userInputType == Enum.UserInputType.Gamepad1

            local function checkPrompt(obj: Instance, part: BasePart, distance: number?)
                if not (obj:IsA("ProximityPrompt") and obj.Enabled) then return end
                if not self:CanInteract(State.LocalPlayer) then return end

                local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                local maxDistance = distance or (template and template.distance or 8)
                local model = part:FindFirstAncestorOfClass("Model")

                if model and model.PrimaryPart then
                    local _, nearestPoint = model:GetBoundingBox()
                    if (characterRoot.Position - nearestPoint).Magnitude <= maxDistance then
                        foundPrompts[obj] = true
                        obj.MaxActivationDistance = maxDistance
                    end
                elseif (characterRoot.Position - part.Position).Magnitude <= maxDistance then
                    foundPrompts[obj] = true
                    obj.MaxActivationDistance = maxDistance
                end
            end

            local foundMouseHover = false
            if not isTouchOrGamepad then
                local mouse = State.LocalPlayer:GetMouse()
                local camera = workspace.CurrentCamera
                local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)

                local ignoreList = {}
                for _, player in Players:GetPlayers() do
                    if player.Character then
                        table.insert(ignoreList, player.Character)
                    end
                end

                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = ignoreList
                raycastParams.CollisionGroup = "Default"

                local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 200, raycastParams)
                if raycastResult then
                    local hitPart = raycastResult.Instance
                    local model = hitPart:FindFirstAncestorOfClass("Model") or hitPart

                    local current = hitPart
                    while current and current ~= workspace do
                        for _, obj in ipairs(current:GetChildren()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                local maxDistance = template and template.distance or 8
                                foundMouseHover = true
                                foundPrompts[obj] = true
                                obj.MaxActivationDistance = maxDistance
                            end
                        end

                        if current:IsA("Model") and current.PrimaryPart then
                            for _, obj in ipairs(current.PrimaryPart:GetChildren()) do
                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                    local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                    local maxDistance = template and template.distance or 8
                                    foundMouseHover = true
                                    foundPrompts[obj] = true
                                    obj.MaxActivationDistance = maxDistance
                                end
                            end
                        end

                        current = current.Parent
                    end

                    if model:IsA("Model") then
                        if model.PrimaryPart then
                            for _, obj in ipairs(model.PrimaryPart:GetChildren()) do
                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                    local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                    local maxDistance = template and template.distance or 8
                                    foundMouseHover = true
                                    foundPrompts[obj] = true
                                    obj.MaxActivationDistance = maxDistance
                                end
                            end
                        end

                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                for _, obj in ipairs(part:GetChildren()) do
                                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                                        local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                        local maxDistance = template and template.distance or 8
                                        foundMouseHover = true
                                        foundPrompts[obj] = true
                                        obj.MaxActivationDistance = maxDistance
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if not foundMouseHover then
                for _, part in ipairs(workspace:GetPartBoundsInRadius(characterRoot.Position, 30)) do
                    for _, obj in ipairs(part:GetChildren()) do
                        checkPrompt(obj, part)
                    end

                    local model = part:FindFirstAncestorOfClass("Model")
                    if model then
                        if model.PrimaryPart then
                            for _, obj in ipairs(model.PrimaryPart:GetChildren()) do
                                checkPrompt(obj, model.PrimaryPart)
                            end
                        end

                        for _, modelPart in ipairs(model:GetDescendants()) do
                            if modelPart:IsA("BasePart") then
                                for _, obj in ipairs(modelPart:GetChildren()) do
                                    checkPrompt(obj, modelPart)
                                end
                            end
                        end
                    end
                end
            end

            for prompt in pairs(State.HoveredPrompts) do
                if not foundPrompts[prompt] then
                    prompt.MaxActivationDistance = 0
                end
            end

            table.clear(State.HoveredPrompts)
            for prompt in pairs(foundPrompts) do
                State.HoveredPrompts[prompt] = true
            end
        end)
    end)
end

function InteractController:SetupWorkspaceListeners()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ClickDetector") then
            self:SetupClick(descendant)
        end
    end

    workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ClickDetector") then
            self:SetupClick(descendant)
        end
    end)
end

function InteractController:SetupRenderStepEvents()
    local self = self
    task.spawn(function()
        local RunService = game:GetService("RunService")
        RunService.RenderStepped:Connect(function(deltaTime)
            for prompt, data in pairs(State.ActiveProgress) do
                if not prompt.Enabled then continue end

                local progressBar = prompt:GetAttribute("STYLE") == "custom"
                    and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
                    or (State.ActiveBillboards[prompt] and State.ActiveBillboards[prompt].Container.ProgressBar)

                if progressBar then
                    local elapsed = (tick() - data.startTime) + deltaTime
                    progressBar.Fill.Size = UDim2.new(math.min(elapsed / data.duration, 1), 0, 1, 0)
                end
            end
        end)
    end)

    task.spawn(function()
        local self = self
        local RunService = game:GetService("RunService")
        RunService.RenderStepped:Connect(function()
            local character = State.LocalPlayer.Character
            local characterRoot = character and character:FindFirstChild("HumanoidRootPart")

            if not characterRoot or not self:CanInteract(State.LocalPlayer) then
                for prompt in pairs(State.HoveredPrompts) do
                    prompt.MaxActivationDistance = 0

                    local style = prompt:GetAttribute("STYLE")
                    if style == "custom" then
                        local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
                        if container then
                            container.Visible = false
                        end
                    elseif style == "billboard" then
                        local billboard = State.ActiveBillboards[prompt]
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
                table.clear(State.HoveredPrompts)

                for _, highlight in pairs(State.ActiveHighlights) do
                    highlight:Destroy()
                end
                table.clear(State.ActiveHighlights)

                for _, tooltip in pairs(State.ActiveTooltips) do
                    if typeof(tooltip) == "Instance" then
                        tooltip:Destroy()
                    end
                end
                table.clear(State.ActiveTooltips)
                return
            end

            local foundPrompts = {}
            local userInputType = UserInputService:GetLastInputType()
            local isTouchOrGamepad = userInputType == Enum.UserInputType.Touch or userInputType == Enum.UserInputType.Gamepad1

            local function checkPrompt(obj: Instance, part: BasePart, distance: number?)
                if not (obj:IsA("ProximityPrompt") and obj.Enabled) then return end
                if not self:CanInteract(State.LocalPlayer) then return end

                local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                local maxDistance = distance or (template and template.distance or 8)
                local model = part:FindFirstAncestorOfClass("Model")

                if model and model.PrimaryPart then
                    local _, nearestPoint = model:GetBoundingBox()
                    if (characterRoot.Position - nearestPoint).Magnitude <= maxDistance then
                        foundPrompts[obj] = true
                        obj.MaxActivationDistance = maxDistance
                    end
                elseif (characterRoot.Position - part.Position).Magnitude <= maxDistance then
                    foundPrompts[obj] = true
                    obj.MaxActivationDistance = maxDistance
                end
            end

            local foundMouseHover = false
            if not isTouchOrGamepad then
                local mouse = State.LocalPlayer:GetMouse()
                local camera = workspace.CurrentCamera
                local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)

                local ignoreList = {}
                for _, player in Players:GetPlayers() do
                    if player.Character then
                        table.insert(ignoreList, player.Character)
                    end
                end

                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = ignoreList
                raycastParams.CollisionGroup = "Default"

                local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 200, raycastParams)
                if raycastResult then
                    local hitPart = raycastResult.Instance
                    local model = hitPart:FindFirstAncestorOfClass("Model") or hitPart

                    local current = hitPart
                    while current and current ~= workspace do
                        for _, obj in ipairs(current:GetChildren()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                local maxDistance = template and template.distance or 8
                                foundMouseHover = true
                                foundPrompts[obj] = true
                                obj.MaxActivationDistance = maxDistance
                            end
                        end

                        if current:IsA("Model") and current.PrimaryPart then
                            for _, obj in ipairs(current.PrimaryPart:GetChildren()) do
                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                    local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                    local maxDistance = template and template.distance or 8
                                    foundMouseHover = true
                                    foundPrompts[obj] = true
                                    obj.MaxActivationDistance = maxDistance
                                end
                            end
                        end

                        current = current.Parent
                    end

                    if model:IsA("Model") then
                        if model.PrimaryPart then
                            for _, obj in ipairs(model.PrimaryPart:GetChildren()) do
                                if obj:IsA("ProximityPrompt") and obj.Enabled then
                                    local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                    local maxDistance = template and template.distance or 8
                                    foundMouseHover = true
                                    foundPrompts[obj] = true
                                    obj.MaxActivationDistance = maxDistance
                                end
                            end
                        end

                        for _, part in ipairs(model:GetDescendants()) do
                            if part:IsA("BasePart") then
                                for _, obj in ipairs(part:GetChildren()) do
                                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                                        local template = Modules.Interact.Templates[obj:GetAttribute("ACTION"):lower()]
                                        local maxDistance = template and template.distance or 8
                                        foundMouseHover = true
                                        foundPrompts[obj] = true
                                        obj.MaxActivationDistance = maxDistance
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if not foundMouseHover then
                for _, part in ipairs(workspace:GetPartBoundsInRadius(characterRoot.Position, 30)) do
                    for _, obj in ipairs(part:GetChildren()) do
                        checkPrompt(obj, part)
                    end

                    local model = part:FindFirstAncestorOfClass("Model")
                    if model then
                        if model.PrimaryPart then
                            for _, obj in ipairs(model.PrimaryPart:GetChildren()) do
                                checkPrompt(obj, model.PrimaryPart)
                            end
                        end

                        for _, modelPart in ipairs(model:GetDescendants()) do
                            if modelPart:IsA("BasePart") then
                                for _, obj in ipairs(modelPart:GetChildren()) do
                                    checkPrompt(obj, modelPart)
                                end
                            end
                        end
                    end
                end
            end

            for prompt in pairs(State.HoveredPrompts) do
                if not foundPrompts[prompt] then
                    prompt.MaxActivationDistance = 0
                end
            end

            table.clear(State.HoveredPrompts)
            for prompt in pairs(foundPrompts) do
                State.HoveredPrompts[prompt] = true
            end
        end)
    end)
end

return InteractController