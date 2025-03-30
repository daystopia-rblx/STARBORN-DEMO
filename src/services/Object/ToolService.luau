--[[ ToolService
    Advanced tool system with inheritance, customization, and state management.
    Handles tool templates, interactions, equipping, and control scheme configuration.
    @author @Daystopia
    @version 1.0.2
    @date 2025-03-09
]]
local ToolService = {}
local Players = game:GetService("Players")

--[[ Dependencies ]]
ToolService.Dependencies = {
    "Event",
    "Object"
}

--[[ Modules ]]
ToolService.Modules = {
    "Tool"
}

--[[ Events ]]
ToolService.Events = {
    Create = true,
    Equip = true,
    Unequip = true,
    Activate = true,
    Deactivate = true,
    State = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Types ]]
type ToolContext = {
    id: string,
    tool: Tool,
    player: Player,
    toolType: string,
    currentState: string,
    toolData: {[string]: any},
    lastStateChange: number,
    [string]: any
}

--[[ State ]]
local state = {
    activeTools = {} :: {[Player]: {[string]: ToolContext}},
    toolTemplates = {} :: {[Tool]: {[string]: any}},
    connections = {} :: {[Tool]: {RBXScriptConnection}},
    cooldowns = {} :: {[Tool]: {[string]: number}}
}

--[[ Cleanup ]]
local function CleanTool(tool: Tool)
    local connections = state.connections[tool]
    if connections then
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
        state.connections[tool] = nil
    end

    state.toolTemplates[tool] = nil
    state.cooldowns[tool] = nil
end

local function CleanPlayer(player: Player)
    if state.activeTools[player] then
        for _, context in pairs(state.activeTools[player]) do
            ToolService:DeactivateTool(player, context.tool)
        end
        state.activeTools[player] = nil
    end
end

--[[ Listeners ]]
ToolService.Listeners = {
    ["Object.Update"] = function(self, data)
        local instance = data.instance
        if not instance or not instance:IsA("Tool") then return end

        CleanTool(instance)

        local toolType = data.attributes and data.attributes.toolType or instance:GetAttribute("TOOL")
        if toolType then
            self:CreateTool(data.id, instance, toolType)
        end
    end
}

--[[ Core Functions ]]
function ToolService:Init(services, modules)
    Services = services
    Modules = modules

    Players.PlayerRemoving:Connect(CleanPlayer)
    return true
end

--[[ Tool Management ]]
function ToolService:CreateTool(id: string, tool: Tool, toolType: string): boolean
    if not tool:IsA("Tool") then return false end

    local template = Modules.Tool:GetTemplate(toolType:lower())
    if not template then
        local templateKeys = {}
        for k in pairs(Modules.Tool.Templates) do
            table.insert(templateKeys, tostring(k))
        end
        warn("No template found for tool type:", toolType)
        return false
    end

    tool:SetAttribute("TOOL", toolType)

    if template.CanBeDropped ~= nil then
        tool.CanBeDropped = template.CanBeDropped
    elseif template.canBeDropped ~= nil then
        tool.CanBeDropped = template.canBeDropped
    end

    if template.Enabled ~= nil then 
        tool.Enabled = template.Enabled
    elseif template.enabled ~= nil then
        tool.Enabled = template.enabled
    end

    if template.ManualActivationOnly ~= nil then 
        tool.ManualActivationOnly = template.ManualActivationOnly 
    elseif template.manualActivationOnly ~= nil then
        tool.ManualActivationOnly = template.manualActivationOnly
    end

    if template.RequiresHandle ~= nil then 
        tool.RequiresHandle = template.RequiresHandle 
    elseif template.requiresHandle ~= nil then
        tool.RequiresHandle = template.requiresHandle
    end

    if template.ToolTip then
        tool.ToolTip = template.ToolTip
    elseif template.toolTip then
        tool.ToolTip = template.toolTip
    end

    local handle = tool:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        local autoPickup = template.AutoPickup
        if autoPickup == nil then
            autoPickup = template.autoPickup
        end

        if autoPickup == nil then
            autoPickup = false
        end

        handle.CanTouch = autoPickup
    end

    if template.distance then tool:SetAttribute("DISTANCE", template.distance) end
    if template.cursors then
        for cursorType, cursorId in pairs(template.cursors) do
            if cursorId ~= "" then
                tool:SetAttribute("CURSOR_" .. string.upper(cursorType), cursorId)
            end
        end
    end

    local animations = tool:FindFirstChild("Animations") or Instance.new("Folder")
    animations.Name = "Animations"
    animations.Parent = tool

    if template.animations then
        for name, animationId in pairs(template.animations) do
            if type(animationId) == "string" and animationId ~= "" then
                local animation = animations:FindFirstChild(name) or Instance.new("Animation")
                animation.Name = name
                animation.AnimationId = animationId
                animation.Parent = animations
            end
        end
    end

    -- Handle sounds
    local sounds = tool:FindFirstChild("Sounds") or Instance.new("Folder")
    sounds.Name = "Sounds"
    sounds.Parent = tool

    if template.sounds then
        for name, soundId in pairs(template.sounds) do
            if type(soundId) == "string" and soundId ~= "" then
                local sound = sounds:FindFirstChild(name) or Instance.new("Sound")
                sound.Name = name
                sound.SoundId = soundId
                sound.Parent = sounds
            elseif type(soundId) == "table" and soundId.id and soundId.id ~= "" then
                local sound = sounds:FindFirstChild(name) or Instance.new("Sound")
                sound.Name = name
                sound.SoundId = soundId.id
                if soundId.volume then sound.Volume = soundId.volume end
                if soundId.pitch then sound.PlaybackSpeed = soundId.pitch end
                if soundId.looped ~= nil then sound.Looped = soundId.looped end
                sound.Parent = sounds
            end
        end
    end

    -- Set initial state
    if template.stateConfig and template.stateConfig.initialState then
        tool:SetAttribute("STATE", template.stateConfig.initialState)
    elseif template.state then
        tool:SetAttribute("STATE", "INACTIVE")
    end

    state.toolTemplates[tool] = template

    local connections = {
        tool.Equipped:Connect(function(mouse)
            local player = Players:GetPlayerFromCharacter(tool.Parent)
            if player then
                self:EquipTool(player, tool)
            end
        end),
        tool.Unequipped:Connect(function()
            local player = Players:GetPlayerFromCharacter(tool.Parent)
            if player then
                self:UnequipTool(player, tool)
            end
        end),
        tool.Activated:Connect(function()
            local player = Players:GetPlayerFromCharacter(tool.Parent)
            if player then
                self:ActivateTool(player, tool)
            end
        end),
        tool.Deactivated:Connect(function()
            local player = Players:GetPlayerFromCharacter(tool.Parent)
            if player then
                self:DeactivateTool(player, tool)
            end
        end)
    }

    state.connections[tool] = connections

    Services.Event:Fire("Tool.Create", {
        id = id,
        tool = tool,
        template = template
    })

    return true
end

function ToolService:EquipTool(player: Player, tool: Tool): boolean
    local template = state.toolTemplates[tool]
    if not template then
        warn("No template found for tool:", tool.Name)
        return false
    end

    local context: ToolContext = {
        id = Services.Object:GetID(tool),
        tool = tool,
        player = player,
        toolType = tool:GetAttribute("TOOL")
    }

    state.activeTools[player] = state.activeTools[player] or {}
    state.activeTools[player][tool:GetAttribute("TOOL")] = context

    Services.Event:Fire("Tool.Equip", {
        player = player,
        tool = tool,
        context = context
    })

    return true
end

function ToolService:UnequipTool(player: Player, tool: Tool): boolean
    local playerTools = state.activeTools[player]
    if not playerTools then return false end

    local toolType = tool:GetAttribute("TOOL")
    local context = playerTools[toolType]
    if not context then return false end

    playerTools[toolType] = nil
    if not next(playerTools) then
        state.activeTools[player] = nil
    end

    Services.Event:Fire("Tool.Unequip", {
        player = player,
        tool = tool,
        context = context
    })

    return true
end

function ToolService:ValidateState(tool: Tool, newState: string): boolean
    local template = state.toolTemplates[tool]
    if not template then return false end

    local currentState = tool:GetAttribute("STATE")
    local validTransitions = template.stateConfig.transitions[currentState]

    return validTransitions and table.find(validTransitions, newState) ~= nil
end

function ToolService:ChangeState(tool: Tool, newState: string): boolean
    if not self:ValidateState(tool, newState) then return false end

    local currentState = tool:GetAttribute("STATE")
    local template = state.toolTemplates[tool]

    if template.stateConfig.onExitState[currentState] then
        local success = template.stateConfig.onExitState[currentState](tool)
        if success == false then return false end
    end

    tool:SetAttribute("STATE", newState)

    if template.stateConfig.onEnterState[newState] then
        template.stateConfig.onEnterState[newState](tool)
    end

    Services.Event:Fire("Tool.State", {
        tool = tool,
        oldState = currentState,
        newState = newState
    })

    return true
end

function ToolService:ActivateTool(player: Player, tool: Tool, inputType: string?, data: {[string]: any}?): boolean
    local template = state.toolTemplates[tool]
    if not template then return false end

    local currentState = tool:GetAttribute("STATE")
    local inputConfig = inputType and template.inputs[inputType]

    if template.stateConfig.preventInputInStates[currentState] then return false end
    if inputConfig then
        if inputConfig.requiresState and #inputConfig.requiresState > 0 then
            if not table.find(inputConfig.requiresState, currentState) then return false end
        end
        if inputConfig.preventInStates and table.find(inputConfig.preventInStates, currentState) then
            return false
        end
    end

    if inputConfig and inputConfig.stateOnActivate then
        if not self:ChangeState(tool, inputConfig.stateOnActivate) then
            return false
        end
    end

    Services.Event:Fire("Tool.Activate", {
        tool = tool,
        player = player,
        inputType = inputType,
        data = data
    })

    return true
end

function ToolService:DeactivateTool(player: Player, tool: Tool, inputType: string?, data: {[string]: any}?): boolean
    local template = state.toolTemplates[tool]
    if not template then return false end

    local inputConfig = inputType and template.inputs[inputType]

    if inputConfig and inputConfig.stateOnDeactivate then
        self:ChangeState(tool, inputConfig.stateOnDeactivate, data)
    end

    return true
end

function ToolService:ValidateTool(player: Player, requiredTools: {string}): boolean
    if not player then return false end

    local character = player.Character
    if character then
        local equippedTool = character:FindFirstChildOfClass("Tool")
        if equippedTool then
            local toolType = equippedTool:GetAttribute("TOOL")
            if toolType then
                for toolName in toolType:gmatch("[^,]+") do
                    toolName = toolName:match("^%s*(.-)%s*$")
                    for _, requiredTool in ipairs(requiredTools) do
                        if toolName:lower() == requiredTool:lower() then
                            return true
                        end
                    end
                end
            end

            local toolCapability = equippedTool:GetAttribute("CAPABILITY")
            if toolCapability then
                for capabilityName in toolCapability:gmatch("[^,]+") do
                    capabilityName = capabilityName:match("^%s*(.-)%s*$")
                    for _, requiredTool in ipairs(requiredTools) do
                        if capabilityName:lower() == requiredTool:lower() then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

return ToolService