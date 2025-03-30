--[[ InteractClient
    Client-side interaction system with proximity prompts and custom UI.
    Manages interaction feedback, keybinds, cooldowns, and state visualization.
    @author @Daystopia
    @version 1.0.8
    @date 2025-03-27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Modules = {
    Interact = require(ReplicatedStorage.Modules.InteractModule),
    Action = require(ReplicatedStorage.Modules.ActionModule)
}

local Utility = {
    Controller = require(script.Parent.Utility.Controller),
    Animation = require(script.Parent.Utility.Animation),
    Sound = require(script.Parent.Utility.Sound),
    Scale = require(script.Parent.Utility.Scale)
}

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

--[[ Types ]]
type PromptData = {
    prompt: ProximityPrompt,
    inputType: Enum.ProximityPromptInputType?,
    player: Player?,
    duration: number?
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PromptsPerParent = {} :: {[Instance]: {ProximityPrompt}}
local ActiveBillboards = {} :: {[ProximityPrompt]: BillboardGui}
local ActiveProgress = {} :: {[ProximityPrompt]: {startTime: number, duration: number}}
local ActiveHighlights = {} :: {[Instance]: Highlight}
local ActiveTooltips = {} :: {[Instance]: BillboardGui}
local LastInteractionTime = {} :: {[ProximityPrompt]: number}
local ActiveScreenPrompts = {} :: {ProximityPrompt}
local ActiveClickDetectors = {} :: {[Instance]: ClickDetector}
local INTERACTION_COOLDOWN = 0.1
local TOOLTIP_DURATION = 3
local AlternateKeys = {"F", "R", "T", "G", "V", "B", "Y", "H", "N"}
local HoveredPrompts: {ProximityPrompt} = {}

--[[ UI Setup ]]
local function CreatePrompt()
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
    actionText.Font = Enum.Font.GothamBold
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
    keyText.Font = Enum.Font.GothamBold
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

local function UpdateScreenPromptPositions()
    local count = #ActiveScreenPrompts
    if count == 0 then return end

    local spacing = 10
    local containerWidth = 125
    local totalWidth = (containerWidth * count) + (spacing * (count - 1))

    for i, prompt in ipairs(ActiveScreenPrompts) do
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

local function CreateScreenPrompt()
    local promptGui = Instance.new("ScreenGui")
    promptGui.Name = "InteractPrompt"
    promptGui.ResetOnSpawn = false
    promptGui.Parent = PlayerGui
    return promptGui
end

local function CreateScreenContainer(prompt: ProximityPrompt)
    local container = CreatePrompt()
    container.Name = "Container_" .. prompt:GetAttribute("ACTION")
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.Position = UDim2.new(0.5, 0, 0.8, 0)
    container.Visible = false
    container.Parent = PromptUI

    Utility.Scale.AutoScale(container)
    return container
end

local function CreateBillboardPrompt(parent: BasePart, template)
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

    local container = CreatePrompt()
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

local function UpdateTooltipPositions(parent: Instance)
    if not PromptsPerParent[parent] then return end

    local tooltipGui = ActiveTooltips[parent]
    if not tooltipGui then return end

    local promptCount = #PromptsPerParent[parent]
    if promptCount == 0 then return end

    local highestOffset = Vector3.new(0, 0, 0)
    for _, prompt in ipairs(PromptsPerParent[parent]) do
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

local function UpdatePromptPositions(parent: Instance)
    if not PromptsPerParent[parent] then return end

    for i, prompt in ipairs(PromptsPerParent[parent]) do
        local billboard = ActiveBillboards[prompt]
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

    UpdateTooltipPositions(parent)
end

local function CreateTooltip(parent: Instance, isScreen: boolean?)
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
        textLabel.Font = Enum.Font.GothamBold
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
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextWrapped = true
        textLabel.TextScaled = true
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.Parent = container

        billboardGui.Parent = parent
        return billboardGui, textLabel
    end
end

local function CleanupTooltip(parent: Instance)
    local tooltip = ActiveTooltips[parent]
    if tooltip then
        if tooltip.Parent then
            tooltip:Destroy()
        end
        ActiveTooltips[parent] = nil
    end
end

local function ShowTooltip(parent: Instance, isScreen: boolean?)
    if ActiveTooltips[parent] then
        if typeof(ActiveTooltips[parent]) == "Instance" then
            ActiveTooltips[parent]:Destroy()
        end
        ActiveTooltips[parent] = nil
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
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart or (rootPart.Position - parent.Position).Magnitude > maxDistance then
            CleanupTooltip(parent)
            return
        end
    end

    local tooltipUI, textLabel = CreateTooltip(parent, isScreen)
    ActiveTooltips[parent] = tooltipUI

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
        UpdateTooltipPositions(parent)
    else
        local promptCount = #ActiveScreenPrompts
        if promptCount > 0 then
            frame.Position = UDim2.new(0.5, 0, 0.7, 60 - ((promptCount - 1) * 35))
        end
    end

    Utility.Animation.Group({
        Utility.Animation.To(frame, {
            BackgroundTransparency = 0.2
        }, {
            duration = 0.2,
            easingStyle = Utility.Animation.Easing.Linear
        }),
        Utility.Animation.To(textLabel, {
            TextTransparency = 0
        }, {
            duration = 0.2,
            easingStyle = Utility.Animation.Easing.Linear
        })
    })

    task.delay(TOOLTIP_DURATION, function()
        if tooltipUI and tooltipUI.Parent then
            Utility.Animation.Group({
                Utility.Animation.To(frame, {
                    BackgroundTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Animation.Easing.Linear
                }),
                Utility.Animation.To(textLabel, {
                    TextTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Animation.Easing.Linear,
                    onComplete = function()
                        tooltipUI:Destroy()
                        ActiveTooltips[parent] = nil
                    end
                })
            })
        end
    end)
end

PromptUI = CreateScreenPrompt()

--[[ Events ]]
local Events = {
    ["Interact.Create"] = {
        handler = function(data)
            local prompt = data.prompt
            local template = data.template
            if not (prompt and template) then return end
            prompt:SetAttribute("STYLE", template.style)
        end
    }
}

--[[ Utility Functions ]]
local function CanInteract(player: Player): boolean
    if not player then return false end

    local character = player.Character
    if not character then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function GetKey(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
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

    local prompts = PromptsPerParent[prompt.Parent]
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

local function UpdatePrompt(container: Frame, prompt: ProximityPrompt, keyText: string, hasHoldDuration: boolean)
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

local function CreateHighlight(parent: Instance)
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

local function CleanupHighlight(parent: Instance)
    local highlight = ActiveHighlights[parent]
    if highlight then
        Utility.Animation.To(highlight, {
            OutlineTransparency = 1
        }, {
            duration = 0.2,
            easingStyle = Utility.Animation.Easing.Linear,
            onComplete = function()
                highlight:Destroy()
                ActiveHighlights[parent] = nil
            end
        })
    end
end

local function FlashHighlight(parent: Instance, duration: number)
    local highlight = ActiveHighlights[parent]
    if highlight then
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        task.wait(duration)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

local function CheckCooldown(prompt, currentTime)
    if not CanInteract(LocalPlayer) then
        Utility.Sound.Prompt("Error")
        FlashHighlight(prompt.Parent, INTERACTION_COOLDOWN)
        return true
    end

    local actionType = prompt:GetAttribute("ACTION")
    if not actionType then return false end

    local actionConfig = Modules.Action.Types[actionType:upper()]
    if not actionConfig then return false end

    local cooldown = actionConfig.cooldown or INTERACTION_COOLDOWN
    local lastInteraction = LastInteractionTime[prompt]

    if lastInteraction and (currentTime - lastInteraction) < cooldown then
        Utility.Sound.Prompt("Error")
        FlashHighlight(prompt.Parent, cooldown)
        return true
    end

    LastInteractionTime[prompt] = currentTime
    return false
end

-- [[ Prompt Events ]]
local PromptEvents = {
    Triggered = function(prompt: ProximityPrompt)
        local style = prompt:GetAttribute("STYLE")
        if style == "default" then return end

        local currentTime = os.clock()
        if CheckCooldown(prompt, currentTime) then return end

        Utility.Sound.Prompt("Click")

        local container = style == "custom"
            and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
            or (ActiveBillboards[prompt] and ActiveBillboards[prompt].Container)
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

        Utility.Animation.To(container, {
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

            Utility.Animation.To(billboard, {Size = newBillboardSize}, {duration = 0.06})
        end
    end,

    TriggerEnded = function(prompt: ProximityPrompt)
        local style = prompt:GetAttribute("STYLE")
        if style == "default" then return end

        local container = style == "custom" 
            and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
            or (ActiveBillboards[prompt] and ActiveBillboards[prompt].Container)
        if not container then return end

        local originalSize = prompt:GetAttribute("OriginalContainerSize") or container.Size
        local originalBgTransparency = prompt:GetAttribute("OriginalBgTransparency") or container.BackgroundTransparency

        Utility.Animation.To(container, {
            Size = originalSize,
            BackgroundTransparency = originalBgTransparency
        }, {
            duration = 0.06
        })

        local billboard = container.Parent
        if billboard:IsA("BillboardGui") then
            local originalBillboardSize = prompt:GetAttribute("OriginalBillboardSize") or billboard.Size
            Utility.Animation.To(billboard, {Size = originalBillboardSize}, {duration = 0.06})
        end

        prompt:SetAttribute("OriginalContainerSize", nil)
        prompt:SetAttribute("OriginalBgTransparency", nil)
        prompt:SetAttribute("OriginalBillboardSize", nil)

        Services.Event:FireServer("Client.Interact.Trigger", {prompt = prompt})
    end,

    Shown = function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
        if not CanInteract(LocalPlayer) then return end

        local style = prompt:GetAttribute("STYLE")
        if style == "default" then return end

        Utility.Sound.Prompt("Hover")

        local parent = prompt.Parent
        if not parent then return end

        local highlight = ActiveHighlights[parent]
        if not highlight then
            highlight = CreateHighlight(parent)
            ActiveHighlights[parent] = highlight
        end

        local template = Modules.Interact.Templates[prompt:GetAttribute("ACTION"):lower()]
        if template and template.highlightColor then
            highlight.OutlineColor = template.highlightColor
        else
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        end

        Utility.Animation.To(highlight, {
            OutlineTransparency = 0.2
        }, {
            duration = 0.2,
            easingStyle = Utility.Animation.Easing.Linear
        })

        local hasHoldDuration = prompt.HoldDuration > 0
        local keyText = GetKey(prompt, inputType)

        if style == "custom" then
            local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
            if not container then
                container = CreateScreenContainer(prompt)
            end
            UpdatePrompt(container, prompt, keyText, hasHoldDuration)
            container.Visible = true
            table.insert(ActiveScreenPrompts, prompt)
            UpdateScreenPromptPositions()
            ShowTooltip(prompt.Parent, true)
        elseif style == "billboard" then
            local parent = prompt.Parent
            if not parent:IsA("BasePart") then return end

            if not PromptsPerParent[parent] then
                PromptsPerParent[parent] = {}
            end
            table.insert(PromptsPerParent[parent], prompt)

            local billboard = ActiveBillboards[prompt]
            if not billboard then
                billboard = CreateBillboardPrompt(parent, template)
                ActiveBillboards[prompt] = billboard
            else
                billboard.Parent = parent
                billboard.Enabled = true
            end

            UpdatePromptPositions(parent)
            UpdatePrompt(billboard.Container, prompt, keyText, hasHoldDuration)
            ShowTooltip(prompt.Parent, false)
        end

        Services.Event:FireServer("Client.Interact.Show", {
            prompt = prompt,
            inputType = inputType
        })
    end,

    Hidden = function(prompt: ProximityPrompt)
        local style = prompt:GetAttribute("STYLE")
        if style == "default" then return end

        if style == "custom" then
            local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
            if container then
                container.Visible = false
                container.ProgressBar.Visible = false
                Utility.Controller.UpdateProgress(container.ProgressBar, 0)
            end

            for i, p in ipairs(ActiveScreenPrompts) do
                if p == prompt then
                    table.remove(ActiveScreenPrompts, i)
                    break
                end
            end
            UpdateScreenPromptPositions()

            local parent = prompt.Parent
            if parent then
                local hasRemainingPrompts = false
                for _, p in ipairs(ActiveScreenPrompts) do
                    if p.Parent == parent then
                        hasRemainingPrompts = true
                        break
                    end
                end

                if not hasRemainingPrompts then
                    CleanupHighlight(parent)
                    CleanupTooltip(parent)
                end
            end
        elseif style == "billboard" then
            local billboard = ActiveBillboards[prompt]
            if billboard then
                billboard.Enabled = false
                billboard.Container.ProgressBar.Visible = false
                billboard.Container.ProgressBar.Fill.Size = UDim2.new(0, 0, 1, 0)
            end
        end

        local parent = prompt.Parent
        if not parent then return end

        if PromptsPerParent[parent] then
            for i, p in ipairs(PromptsPerParent[parent]) do
                if p == prompt then
                    table.remove(PromptsPerParent[parent], i)
                    break
                end
            end

            if #PromptsPerParent[parent] == 0 then
                PromptsPerParent[parent] = nil
                CleanupHighlight(parent)
                CleanupTooltip(parent)
            else
                UpdatePromptPositions(parent)
            end
        end

        local model = parent:FindFirstAncestorOfClass("Model")
        if model and model ~= parent then
            local modelHasPrompts = false
            for _, part in ipairs(model:GetDescendants()) do
                if PromptsPerParent[part] and #PromptsPerParent[part] > 0 then
                    modelHasPrompts = true
                    break
                end
            end

            if not modelHasPrompts and ActiveHighlights[model] then
                Utility.Animation.To(ActiveHighlights[model], {
                    OutlineTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Animation.Easing.Linear,
                    onComplete = function()
                        if ActiveHighlights[model] then
                            ActiveHighlights[model]:Destroy()
                            ActiveHighlights[model] = nil
                        end
                    end
                })
                CleanupTooltip(model)
            end
        else
            local hasRemainingPrompts = false
            if parent:IsA("Model") then
                for _, part in ipairs(parent:GetDescendants()) do
                    if PromptsPerParent[part] and #PromptsPerParent[part] > 0 then
                        hasRemainingPrompts = true
                        break
                    end
                end
            else
                hasRemainingPrompts = PromptsPerParent[parent] and #PromptsPerParent[parent] > 0
            end

            if not hasRemainingPrompts and ActiveHighlights[parent] then
                Utility.Animation.To(ActiveHighlights[parent], {
                    OutlineTransparency = 1
                }, {
                    duration = 0.2,
                    easingStyle = Utility.Animation.Easing.Linear,
                    onComplete = function()
                        if ActiveHighlights[parent] then
                            ActiveHighlights[parent]:Destroy()
                            ActiveHighlights[parent] = nil
                        end
                    end
                })
                CleanupTooltip(parent)
            end
        end

        ActiveProgress[prompt] = nil
        LastInteractionTime[prompt] = nil

        Services.Event:FireServer("Client.Interact.Hide", {prompt = prompt})
    end,

    HoldBegan = function(prompt: ProximityPrompt, player: Player)
        local style = prompt:GetAttribute("STYLE")
        if style == "default" then return end

        local duration = prompt.HoldDuration
        if duration > 0 then
            local progressBar = style == "custom"
                and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
                or (ActiveBillboards[prompt] and ActiveBillboards[prompt].Container.ProgressBar)

            if progressBar then
                progressBar.Visible = true
                progressBar.Fill.Size = UDim2.new(0, 0, 1, 0)
            end

            ActiveProgress[prompt] = {
                startTime = tick(),
                duration = duration
            }
        else
            local container = style == "custom"
                and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
                or (ActiveBillboards[prompt] and ActiveBillboards[prompt].Container)

            if container then
                local scale = 0.9
                local currentSize = container.Size
                local newSize = UDim2.new(
                    currentSize.X.Scale * scale,
                    currentSize.X.Offset * scale,
                    currentSize.Y.Scale * scale,
                    currentSize.Y.Offset * scale
                )

                Utility.Animation.To(container, {
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

                    Utility.Animation.To(billboard, {Size = newBillboardSize}, {duration = 0.06})
                end
            end
        end

        Services.Event:FireServer("Client.Interact.Start", {
            prompt = prompt,
            player = player,
            duration = duration
        })
    end,

    HoldEnded = function(prompt: ProximityPrompt, player: Player)
        local style = prompt:GetAttribute("STYLE")
        if style == "default" then return end

        local progressData = ActiveProgress[prompt]
        if progressData then
            local progressBar = style == "custom"
                and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
                or (ActiveBillboards[prompt] and ActiveBillboards[prompt].Container.ProgressBar)

            if progressBar then
                local elapsed = tick() - progressData.startTime
                local progress = elapsed / progressData.duration

                if progress >= 0.95 then
                    progressBar.Fill.Size = UDim2.new(1, 0, 1, 0)
                    task.wait(0.1)
                    progressBar.Visible = false
                    progressBar.Fill.Size = UDim2.new(0, 0, 1, 0)
                else
                    Utility.Animation.To(progressBar.Fill, {
                        Size = UDim2.new(0, 0, 1, 0)
                    }, {
                        duration = 0.15,
                        easingStyle = Utility.Animation.Easing.Quad,
                        onComplete = function()
                            progressBar.Visible = false
                        end
                    })
                end
            end

            ActiveProgress[prompt] = nil
        end

        Services.Event:FireServer("Client.Interact.End", {
            prompt = prompt,
            player = player
        })
    end
}

--[[ Click Events ]]
local ClickEvents = {
    MouseClick = function(detector: ClickDetector)
        if not CanInteract(LocalPlayer) then
            Utility.Sound.Prompt("Error")
            FlashHighlight(detector.Parent, INTERACTION_COOLDOWN)
            return
        end

        local style = detector:GetAttribute("STYLE")
        if style == "default" then return end

        local currentTime = os.clock()
        if CheckCooldown(detector, currentTime) then return end

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

        Utility.Animation.To(container, {
            Size = newSize,
            BackgroundTransparency = 0
        }, {
            duration = 0.06,
            onComplete = function()
                local originalSize = detector:GetAttribute("OriginalContainerSize")
                local originalBgTransparency = detector:GetAttribute("OriginalBgTransparency")

                if originalSize and originalBgTransparency then
                    Utility.Animation.To(container, {
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

        Services.Event:FireServer("Client.Interact.Trigger", {detector = detector})
    end,

    MouseHoverEnter = function(detector: ClickDetector)
        if not CanInteract(LocalPlayer) then return end

        local style = detector:GetAttribute("STYLE")
        if style == "default" then return end

        local actionType = detector:GetAttribute("ACTION")
        if not actionType then return end

        Utility.Sound.Prompt("Hover")

        local parent = detector.Parent
        if not parent then return end

        local highlight = ActiveHighlights[parent]
        if not highlight then
            highlight = CreateHighlight(parent)
            ActiveHighlights[parent] = highlight
        end

        local template = Modules.Interact.Templates[actionType:lower()]
        if template and template.highlightColor then
            highlight.OutlineColor = template.highlightColor
        else
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        end

        Utility.Animation.To(highlight, {
            OutlineTransparency = 0.2
        }, {
            duration = 0.2,
            easingStyle = Utility.Animation.Easing.Linear
        })

        Services.Event:FireServer("Client.Interact.Show", {detector = detector})
    end,

    MouseHoverLeave = function(detector: ClickDetector)
        local style = detector:GetAttribute("STYLE")
        if style == "default" then return end

        local parent = detector.Parent
        if not parent then return end

        LastInteractionTime[detector] = nil

        Services.Event:FireServer("Client.Interact.Hide", {detector = detector})
    end,

    RightMouseClick = function(detector: ClickDetector)
        local style = detector:GetAttribute("STYLE")
        if style == "default" then return end

        local currentTime = os.clock()
        if CheckCooldown(detector, currentTime) then return end

        Utility.Sound.Prompt("Click")

        local actionType = detector:GetAttribute("ACTION")
        if not actionType then return end

        local container = style == "custom"
            and PromptUI:FindFirstChild("Container_" .. actionType)
            or (ActiveBillboards[detector] and ActiveBillboards[detector].Container)
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

        Utility.Animation.To(container, {
            Size = newSize,
            BackgroundTransparency = 0
        }, {
            duration = 0.06
        })

        Services.Event:FireServer("Client.Interact.Right", {detector = detector})
    end
}

--[[ Initialization ]]
local function SetupClick(detector: ClickDetector)
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
        ClickEvents.MouseClick(detector)
    end)
    detector.MouseHoverEnter:Connect(function()
        ClickEvents.MouseHoverEnter(detector)
    end)
    detector.MouseHoverLeave:Connect(function()
        ClickEvents.MouseHoverLeave(detector)
    end)
    detector.RightMouseClick:Connect(function()
        ClickEvents.RightMouseClick(detector)
    end)

    if not ActiveClickDetectors[detector.Parent] then
        ActiveClickDetectors[detector.Parent] = {}
    end
    ActiveClickDetectors[detector.Parent][detector.Name] = detector
end

local function Initialize()
    for eventName, event in pairs(Events) do
        Services.Event:Connect(eventName, event.handler)
    end

    local promptEvents = {
        {ProximityPromptService.PromptShown, PromptEvents.Shown},
        {ProximityPromptService.PromptHidden, PromptEvents.Hidden},
        {ProximityPromptService.PromptButtonHoldBegan, PromptEvents.HoldBegan},
        {ProximityPromptService.PromptButtonHoldEnded, PromptEvents.HoldEnded},
        {ProximityPromptService.PromptTriggered, PromptEvents.Triggered},
        {ProximityPromptService.PromptTriggerEnded, PromptEvents.TriggerEnded}
    }

    for _, event in ipairs(promptEvents) do
        event[1]:Connect(event[2])
    end

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ClickDetector") then
            SetupClick(descendant)
        end
    end

    workspace.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("ClickDetector") then
            SetupClick(descendant)
        end
    end)

    task.spawn(function()
        local RunService = game:GetService("RunService")
        RunService.RenderStepped:Connect(function(deltaTime)
            for prompt, data in pairs(ActiveProgress) do
                if not prompt.Enabled then continue end

                local progressBar = prompt:GetAttribute("STYLE") == "custom"
                    and PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION")).ProgressBar
                    or (ActiveBillboards[prompt] and ActiveBillboards[prompt].Container.ProgressBar)

                if progressBar then
                    local elapsed = (tick() - data.startTime) + deltaTime
                    progressBar.Fill.Size = UDim2.new(math.min(elapsed / data.duration, 1), 0, 1, 0)
                end
            end
        end)
    end)

    task.spawn(function()
        local RunService = game:GetService("RunService")
        RunService.RenderStepped:Connect(function()
            local character = LocalPlayer.Character
            local characterRoot = character and character:FindFirstChild("HumanoidRootPart")

            if not characterRoot or not CanInteract(LocalPlayer) then
                for prompt in HoveredPrompts do
                    prompt.MaxActivationDistance = 0

                    local style = prompt:GetAttribute("STYLE")
                    if style == "custom" then
                        local container = PromptUI:FindFirstChild("Container_" .. prompt:GetAttribute("ACTION"))
                        if container then
                            container.Visible = false
                        end
                    elseif style == "billboard" then
                        local billboard = ActiveBillboards[prompt]
                        if billboard then
                            billboard.Enabled = false
                        end
                    end
                end
                table.clear(HoveredPrompts)

                for _, highlight in pairs(ActiveHighlights) do
                    highlight:Destroy()
                end
                table.clear(ActiveHighlights)

                for _, tooltip in pairs(ActiveTooltips) do
                    if typeof(tooltip) == "Instance" then
                        tooltip:Destroy()
                    end
                end
                table.clear(ActiveTooltips)
                return
            end

            local foundPrompts = {}
            local userInputType = UserInputService:GetLastInputType()
            local isTouchOrGamepad = userInputType == Enum.UserInputType.Touch or userInputType == Enum.UserInputType.Gamepad1

            local function checkPrompt(obj: Instance, part: BasePart, distance: number?)
                if not (obj:IsA("ProximityPrompt") and obj.Enabled) then return end
                if not CanInteract(LocalPlayer) then return end

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
                local mouse = LocalPlayer:GetMouse()
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

            for prompt in HoveredPrompts do
                if not foundPrompts[prompt] then
                    prompt.MaxActivationDistance = 0
                end
            end

            table.clear(HoveredPrompts)
            for prompt in foundPrompts do
                HoveredPrompts[prompt] = true
            end
        end)
    end)
end

Initialize()