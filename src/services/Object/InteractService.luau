--[[ InteractService
    Advanced interaction system with proximity prompts and multi-prompt support.
    Handles interaction validation, state management, and automatic key binding.
    @author @Daystopia
    @version 1.0.5
    @date 2025-03-09
]]
local InteractService = {}
local Players = game:GetService("Players")

--[[ Dependencies ]]
InteractService.Dependencies = {
    "Event",
    "Object",
    "Tool"
}

--[[ Modules ]]
InteractService.Modules = {
    "Interact"
}

--[[ Events ]]
InteractService.Events = {
    Start = true,
    End = true,
    Show = true,
    Hide = true,
    Create = true,
    Trigger = true,
    Right = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Types ]]
type InteractionContext = {
    id: string,
    instance: Instance,
    player: Player,
    interactionType: string,
    [string]: any
}

--[[ State ]]
local state = {
    activeInteractions = {} :: {[Player]: InteractionContext},
    prompts = {} :: {[Instance]: {[string]: ProximityPrompt}},
    clickDetectors = {} :: {[Instance]: {[string]: ClickDetector}},
    connections = {} :: {[Instance]: {RBXScriptConnection}},
    holdTimers = {} :: {[Player]: {start: number, duration: number, connection: RBXScriptConnection?}}
}

--[[ Cleanup ]]
local function CleanPrompt(instance: Instance)
    local prompts = state.prompts[instance]
    if prompts then
        for _, prompt in pairs(prompts) do
            if typeof(prompt) == "Instance" then
                prompt:Destroy()
            end
        end
        state.prompts[instance] = nil
    end

    local detectors = state.clickDetectors[instance]
    if detectors then
        for _, detector in pairs(detectors) do
            if typeof(detector) == "Instance" then
                detector:Destroy()
            end
        end
        state.clickDetectors[instance] = nil
    end

    local connections = state.connections[instance]
    if connections then
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
        state.connections[instance] = nil
    end
end

local function CleanPlayer(player: Player)
    if state.activeInteractions[player] then
        InteractService:EndInteraction(player)
    end
    if state.holdTimers[player] then
        if state.holdTimers[player].connection then
            state.holdTimers[player].connection:Disconnect()
        end
        state.holdTimers[player] = nil
    end
end

--[[ Listeners ]]
InteractService.Listeners = {
    ["Object.Update"] = function(self, data)
        local instance = data.instance
        if not instance then return end

        CleanPrompt(instance)

        for _, child in ipairs(instance:GetDescendants()) do
            if child:IsA("Seat") or child:IsA("VehicleSeat") then
                child.Disabled = true
            end
        end

        local interactionType = data.attributes and data.attributes.interaction or instance:GetAttribute("INTERACTION")
        if interactionType then
            if type(interactionType) == "string" then
                local types = {}
                for iType in interactionType:gmatch("[^,]+") do
                    table.insert(types, iType:match("^%s*(.-)%s*$"))
                end
                interactionType = types
            end
            self:CreatePrompt(data.id, instance, interactionType)
        end

        for _, child in ipairs(instance:GetDescendants()) do
            if child:IsA("BasePart") then
                local componentInteraction = child:GetAttribute("INTERACTION")
                if componentInteraction then
                    if type(componentInteraction) == "string" then
                        local types = {}
                        for iType in componentInteraction:gmatch("[^,]+") do
                            table.insert(types, iType:match("^%s*(.-)%s*$"))
                        end
                        componentInteraction = types
                    end
                    self:CreatePrompt(data.id .. "_" .. child.Name, child, componentInteraction)
                end
            end
        end
    end,

    ["Tool.Equip"] = function(self, data)
        if not data.player then return end
        task.defer(function()
            self:RefreshPrompts(data.player)
        end)
    end,

    ["Tool.Unequip"] = function(self, data)
        if not data.player then return end
        task.defer(function()
            self:RefreshPrompts(data.player)
        end)
    end
}

--[[ Core Functions ]]
function InteractService:Init(services, modules)
    Services = services
    Modules = modules

    Players.PlayerRemoving:Connect(CleanPlayer)
    return true
end

--[[ Utility Functions ]]
local function GetStyle(styleString: string?): Enum.ProximityPromptStyle
    if styleString == "default" then
        return Enum.ProximityPromptStyle.Default
    elseif styleString == "custom" or styleString == "billboard" then
        return Enum.ProximityPromptStyle.Custom
    end
    return Enum.ProximityPromptStyle.Default
end

--[[ Timer Functions ]]
local function StartTimer(player: Player, instance: Instance, actionType: string, holdDuration: number)
    if state.holdTimers[player] then
        if state.holdTimers[player].connection then
            state.holdTimers[player].connection:Disconnect()
        end
    end

    state.holdTimers[player] = {
        start = tick(),
        duration = holdDuration,
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - state.holdTimers[player].start
            if elapsed >= holdDuration then
                InteractService:StartInteraction(player, instance, actionType)
                if state.holdTimers[player].connection then
                    state.holdTimers[player].connection:Disconnect()
                end
                state.holdTimers[player] = nil
            end
        end)
    }
end

local function CancelTimer(player: Player)
    if state.holdTimers[player] then
        if state.holdTimers[player].connection then
            state.holdTimers[player].connection:Disconnect()
        end
        state.holdTimers[player] = nil
    end
end

--[[ Prompt Management ]]
function InteractService:CreatePrompt(id: string, instance: Instance, interactionType: string | {string})
    local localPlayer = Players.LocalPlayer

    if type(interactionType) == "string" then
        interactionType = {interactionType:lower()}
    else
        local types = {}
        for i, iType in ipairs(interactionType) do
            table.insert(types, iType:lower())
        end
        interactionType = types
    end

    local targetPart = instance:IsA("BasePart") and instance or
        instance:IsA("Model") and instance.PrimaryPart or
        instance:FindFirstChild("Handle") or
        instance:FindFirstChildWhichIsA("BasePart")

    if not targetPart then return end

    if instance:IsA("Model") and not instance.PrimaryPart then
        instance.PrimaryPart = targetPart
    end

    CleanPrompt(instance)

    local validTypes = {}
    for _, iType in ipairs(interactionType) do
        if Modules.Interact.Templates[iType] then
            table.insert(validTypes, iType)
        end
    end

    local exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    local currentController = instance:GetAttribute("CONTROLLER")
    local isControlled = currentController and currentController ~= ""

    local AlternateKeys = {"F", "R", "T", "G", "V", "B", "Y", "H", "N"}
    local prompts = {}
    local detectors = {}

    for i, iType in ipairs(validTypes) do
        local template = Modules.Interact.Templates[iType]
        if not template then continue end

        if template.visible then
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "InteractionPrompt"
            prompt.ObjectText = instance:GetAttribute("NAME") or ""
            prompt.ActionText = template.prompt or "Interact"
            prompt.KeyboardKeyCode = Enum.KeyCode[i == 1 and (template.key or "E") or AlternateKeys[i-1]]
            prompt.GamepadKeyCode = Enum.KeyCode[template.gamepadKey or "ButtonX"]
            prompt.ClickablePrompt = template.clickablePrompt or true
            prompt.RequiresLineOfSight = template.lineOfSight ~= false
            prompt.HoldDuration = type(template.hold) == "number" and template.hold or 0
            prompt.MaxActivationDistance = template.distance or 8
            prompt.Style = GetStyle(template.style)
            prompt.UIOffset = Vector2.new(0, 2 + (i-1) * 1.5)
            prompt:SetAttribute("STYLE", template.style or "default")
            prompt:SetAttribute("ACTION", iType)
            prompt.AutoLocalize = true

            if template.requires then
                prompt.Enabled = Services.Tool:ValidateTool(localPlayer, template.requires)
            else
                prompt.Enabled = not isControlled
            end

            local controllerChanged = instance:GetAttributeChangedSignal("CONTROLLER"):Connect(function()
                local controller = instance:GetAttribute("CONTROLLER")
                if template.requires then
                    prompt.Enabled = Services.Tool:ValidateTool(localPlayer, template.requires)
                else
                    prompt.Enabled = not (controller and controller ~= "")
                end
            end)

            local connections = {
                prompt.Triggered:Connect(function(player)
                    self:StartInteraction(player, instance, iType)
                end),
                prompt.PromptButtonHoldEnded:Connect(function(player)
                    self:EndInteraction(player)
                end),
                instance.AncestryChanged:Connect(function(_, parent)
                    if not parent then
                        controllerChanged:Disconnect()
                        CleanPrompt(instance)
                    end
                end)
            }

            state.connections[instance] = connections

            local function updatePromptText()
                local state = instance:GetAttribute("STATE")
                if state and template.state and template.state[state] then
                    local stateValue = template.state[state]
                    prompt.ActionText = type(stateValue) == "table" and stateValue.text or stateValue
                end
            end

            local stateConnection = instance:GetAttributeChangedSignal("STATE"):Connect(updatePromptText)
            table.insert(connections, stateConnection)

            updatePromptText()

            if pcall(function() prompt.Parent = targetPart end) then
                prompts[iType] = prompt
            else
                controllerChanged:Disconnect()
                for _, connection in ipairs(connections) do
                    connection:Disconnect()
                end
                prompt:Destroy()
            end
        end

        if template.click then
            local detector = Instance.new("ClickDetector")
            detector.Name = "ClickDetector"
            detector.MaxActivationDistance = template.maxDistance or 7
            detector:SetAttribute("STYLE", template.style or "default")
            detector:SetAttribute("ACTION", iType)

            if template.requires then
                detector.MaxActivationDistance = 0
            end

            if template.cursorIcon then
                detector.CursorIcon = template.cursorIcon
            end

            detector.MouseClick:Connect(function(player)
                if template.requires and not Services.Tool:ValidateTool(player, template.requires) then
                    return
                end

                if template.hold and template.hold > 0 then
                    StartTimer(player, instance, iType, template.hold)
                else
                    self:StartInteraction(player, instance, iType)
                end
            end)

            if pcall(function() detector.Parent = targetPart end) then
                detectors[iType] = detector
            else
                detector:Destroy()
            end
        end
    end

    if next(prompts) then
        state.prompts[instance] = prompts
    end
    if next(detectors) then
        state.clickDetectors[instance] = detectors
    end

    Services.Event:Fire("Interact.Create", {
        id = id,
        instance = instance,
        prompts = prompts,
        detectors = detectors
    })

    return prompts, detectors
end

--[[ Interaction Management ]]
function InteractService:StartInteraction(
    player: Player,
    instance: Instance,
    actionType: string
): boolean
    local id = Services.Object:GetID(instance)
    local object = id and Services.Object:GetInstance(id)

    if not id and instance:GetAttribute("INTERACTION") then
        local parent = instance
        while parent and parent.Parent ~= workspace do
            parent = parent.Parent
            if parent then
                local parentId = Services.Object:GetID(parent)
                if parentId then
                    id = parentId .. "_" .. instance.Name
                    object = Services.Object:GetInstance(parentId)
                    break
                end
            end
        end
    end

    local template = actionType and Modules.Interact.Templates[actionType:lower()]

    if not (id and object and template) then
        warn("Invalid interaction parameters - ID:", id, "Object:", object, "Template:", template)
        return false
    end

    if template.requires and not Services.Tool:ValidateTool(player, template.requires) then
        warn("Missing required tool for interaction:", actionType)
        return false
    end

    local context: InteractionContext = {
        id = id,
        instance = instance,
        player = player,
        interactionType = actionType
    }

    state.activeInteractions[player] = state.activeInteractions[player] or {}
    state.activeInteractions[player][actionType:lower()] = context

    Services.Event:Fire("Interact.Start", {
        player = player,
        instance = instance,
        context = context
    })

    return true
end

function InteractService:EndInteraction(
    player: Player,
    actionType: string?
): boolean
    local playerInteractions = state.activeInteractions[player]
    if not playerInteractions then return false end

    if actionType then
        local context = playerInteractions[actionType:lower()]
        if not context then return false end

        playerInteractions[actionType:lower()] = nil
        if not next(playerInteractions) then
            state.activeInteractions[player] = nil
        end

        Services.Event:Fire("Interact.End", {
            player = player,
            instance = context.instance,
            context = context
        })
    else
        for type, context in pairs(playerInteractions) do
            Services.Event:Fire("Interact.End", {
                player = player,
                instance = context.instance,
                context = context
            })
        end
        state.activeInteractions[player] = nil
    end

    return true
end

function InteractService:RefreshPrompts(player: Player)
    local equippedTools = {}
    local character = player.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            local toolType = tool:GetAttribute("TOOL")
            if toolType then
                for toolName in toolType:gmatch("[^,]+") do
                    toolName = toolName:match("^%s*(.-)%s*$")
                    equippedTools[toolName:lower()] = true
                end
            end

            local toolCapability = tool:GetAttribute("CAPABILITY")
            if toolCapability then
                for capabilityName in toolCapability:gmatch("[^,]+") do
                    capabilityName = capabilityName:match("^%s*(.-)%s*$")
                    equippedTools[capabilityName:lower()] = true
                end
            end
        end
    end

    for _, instance in ipairs(workspace:GetDescendants()) do
        local parent = instance.Parent
        if not parent then continue end

        if instance:IsA("ProximityPrompt") then
            local actionType = instance:GetAttribute("ACTION")
            if not actionType then continue end

            local template = Modules.Interact.Templates[actionType:lower()]
            if not template then continue end

            if template.requires then
                local isEnabled = false
                for _, requiredTool in ipairs(template.requires) do
                    if equippedTools[requiredTool:lower()] then
                        isEnabled = true
                        break
                    end
                end

                instance.Enabled = isEnabled
                instance.ObjectText = isEnabled and (parent:GetAttribute("NAME") or "") or ""
            end
        elseif instance:IsA("ClickDetector") then
            local actionType = instance:GetAttribute("ACTION")
            if not actionType then continue end

            local template = Modules.Interact.Templates[actionType:lower()]
            if not template then continue end

            if template.requires then
                local isEnabled = false
                for _, requiredTool in ipairs(template.requires) do
                    if equippedTools[requiredTool:lower()] then
                        isEnabled = true
                        break
                    end
                end

                instance.MaxActivationDistance = isEnabled and (template.maxDistance or 7) or 0
            end
        end
    end
end

return InteractService