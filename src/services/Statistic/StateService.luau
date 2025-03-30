--[[ StateService
    Manages entity states, transitions, and cooldowns
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local StateService = {}

StateService.Dependencies = {
    "Event"
}

StateService.Modules = {
    "State"
}

StateService.Events = {
    Enter = { validate = true },
    Exit = { validate = true },
    Change = { validate = true }
}

--[[ State Management ]]
local Services
local Modules

local State = {
    cooldowns = {},
    activeStates = setmetatable({}, { __mode = "k" })
}

--[[ Core Functions ]]
function StateService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function StateService:Cleanup()
    table.clear(State.cooldowns)
    table.clear(State.activeStates)
end

--[[ State Functions ]]
function StateService:ValidateState(entity: any, stateName: string): (boolean, string?)
    if not entity then return false, "No entity provided" end

    local template = Modules.State.Templates[stateName]
    if not template then return false, "Invalid state" end

    local cooldownKey = entity:GetFullName() .. "_" .. stateName
    local cooldownEnd = State.cooldowns[cooldownKey]
    if cooldownEnd and os.clock() < cooldownEnd then
        return false, "State on cooldown"
    end

    if template.conditions then
        for _, condition in ipairs(template.conditions) do
            if not condition(entity) then
                return false, "Conditions not met"
            end
        end
    end

    if template.exclusive then
        local activeStates = State.activeStates[entity] or {}
        for activeState, _ in pairs(activeStates) do
            local activeTemplate = Modules.State.Templates[activeState]
            if activeTemplate and activeTemplate.category == template.category then
                if not template.transitions or template.transitions[activeState] == false then
                    return false, "Cannot transition from current state"
                end
            end
        end
    end

    return true
end

function StateService:EnterState(entity: any, stateName: string, metadata: {[string]: any}?): (boolean, string?)
    local canEnter, error = self:ValidateState(entity, stateName)
    if not canEnter then return false, error end

    local template = Modules.State.Templates[stateName]

    entity:SetAttribute(stateName, true)

    State.activeStates[entity] = State.activeStates[entity] or {}
    State.activeStates[entity][stateName] = os.clock()

    if template.cooldown then
        local cooldownKey = entity:GetFullName() .. "_" .. stateName
        State.cooldowns[cooldownKey] = os.clock() + template.cooldown
    end

    if template.duration then
        task.delay(template.duration, function()
            if entity:GetAttribute(stateName) then
                self:ExitState(entity, stateName, { reason = "duration_expired" })
            end
        end)
    end

    if template.onEnter then
        task.spawn(template.onEnter, entity)
    end

    Services.Event:Fire("State.Enter", {
        entity = entity,
        state = stateName,
        metadata = metadata
    })

    return true
end

function StateService:ExitState(entity: any, stateName: string, metadata: {[string]: any}?): (boolean, string?)
    if not entity:GetAttribute(stateName) then
        return false, "Not in state"
    end

    local template = Modules.State.Templates[stateName]

    entity:SetAttribute(stateName, nil)

    if State.activeStates[entity] then
        State.activeStates[entity][stateName] = nil
        if not next(State.activeStates[entity]) then
            State.activeStates[entity] = nil
        end
    end

    if template.onExit then
        task.spawn(template.onExit, entity)
    end

    Services.Event:Fire("State.Exit", {
        entity = entity,
        state = stateName,
        metadata = metadata
    })

    return true
end

function StateService:GetStates(entity: any): {[string]: number}
    return State.activeStates[entity] or {}
end

function StateService:GetCategory(entity: any, category: string): {string}
    local states = {}
    local activeStates = self:GetStates(entity)

    for stateName in pairs(activeStates) do
        local template = Modules.State.Templates[stateName]
        if template and template.category == category then
            table.insert(states, stateName)
        end
    end

    return states
end

return StateService