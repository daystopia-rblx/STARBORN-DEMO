--[[ StateService
    Manages entity states, transitions, and cooldowns
    @author @Daystopia
    @version 1.0.1
    @date 2025-03-31
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
    activeStates = setmetatable({}, { __mode = "k" }),
    stateQueues = {},
    processingStates = {}
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
        local currentState = entity:GetAttribute("STATE")
        if currentState then
            local currentTemplate = Modules.State.Templates[currentState]
            if currentTemplate and currentTemplate.category == template.category then
                if not template.transitions or template.transitions[currentState] == false then
                    return false, "Cannot transition from " .. currentState
                end
            end
        end
    end

    return true
end

function StateService:ProcessState(entity: any)
    if not entity or State.processingStates[entity] then return end

    local queue = State.stateQueues[entity]
    if not queue or #queue == 0 then
        State.stateQueues[entity] = nil
        return
    end

    State.processingStates[entity] = true

    local function processNext()
        if not entity.Parent then
            State.stateQueues[entity] = nil
            State.processingStates[entity] = nil
            return
        end

        local nextState = table.remove(queue, 1)
        if nextState then
            local success = if nextState.force 
                then self:ForceState(entity, nextState.name, nextState.metadata)
                else self:EnterState(entity, nextState.name, nextState.metadata)

            if success and nextState.duration then
                task.delay(nextState.duration, processNext)
            else
                task.spawn(processNext)
            end
        else
            State.stateQueues[entity] = nil
            State.processingStates[entity] = nil
        end
    end

    task.spawn(processNext)
end

function StateService:EnterState(entity: any, stateName: string, metadata: {[string]: any}?): (boolean, string?)
    if not entity then return false, "No entity provided" end

    if State.processingStates[entity] then
        self:QueueState(entity, stateName, metadata)
        return true
    end

    local canEnter, error = self:ValidateState(entity, stateName)
    if not canEnter then
        warn(" Failed to enter state:", error)
        return false, error
    end

    local template = Modules.State.Templates[stateName]

    local currentState = entity:GetAttribute("STATE")
    if currentState then
        self:ExitState(entity, currentState)
    end

    entity:SetAttribute("STATE", stateName)

    State.activeStates[entity] = State.activeStates[entity] or {}
    State.activeStates[entity][stateName] = {
        startTime = os.clock(),
        metadata = metadata
    }

    if template.cooldown then
        local cooldownKey = entity:GetFullName() .. "_" .. stateName
        State.cooldowns[cooldownKey] = os.clock() + template.cooldown
    end

    if template.duration then
        task.delay(template.duration, function()
            if entity:GetAttribute("STATE") == stateName then
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
    if entity:GetAttribute("STATE") ~= stateName then
        warn(" Cannot exit state - not in state")
        return false, "Not in state"
    end

    local template = Modules.State.Templates[stateName]

    entity:SetAttribute("STATE", nil)

    if State.activeStates[entity] then
        local stateData = State.activeStates[entity][stateName]
        if stateData and stateData.metadata and stateData.metadata.cleanup then
            task.spawn(stateData.metadata.cleanup)
        end
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

function StateService:ForceState(entity: any, stateName: string, metadata: {[string]: any}?): boolean
    if not entity then return false end

    State.stateQueues[entity] = {{
        name = stateName,
        metadata = metadata,
        force = true,
        addedTime = os.clock()
    }}

    if not State.processingStates[entity] then
        self:ProcessState(entity)
    end

    return true
end

function StateService:QueueState(entity: any, stateName: string, metadata: {[string]: any}?, delay: number): boolean
    if not entity then return false end

    State.stateQueues[entity] = State.stateQueues[entity] or {}
    local queue = State.stateQueues[entity]

    table.insert(queue, {
        name = stateName,
        metadata = metadata,
        duration = delay,
        force = false,
        addedTime = os.clock()
    })

    if not State.processingStates[entity] then
        self:ProcessState(entity)
    end

    return true
end

function StateService:ChainStates(entity: any, states: {{name: string, metadata: {[string]: any}?, duration: number}}): boolean
    if not entity then return false end

    State.stateQueues[entity] = State.stateQueues[entity] or {}
    local queue = State.stateQueues[entity]

    for _, stateData in ipairs(states) do
        table.insert(queue, {
            name = stateData.name,
            metadata = stateData.metadata,
            duration = stateData.duration,
            force = false,
            addedTime = os.clock()
        })
    end

    if not State.processingStates[entity] then
        self:ProcessState(entity)
    end

    return true
end

function StateService:ClearStates(entity: any): boolean
    if not entity then return false end

    State.stateQueues[entity] = nil
    State.processingStates[entity] = nil
    return true
end

--[[ Getter Functions ]]
function StateService:GetStates(entity: any): {[string]: number}
    return State.activeStates[entity] or {}
end

function StateService:GetQueue(entity: any): {{name: string, metadata: {[string]: any}?, duration: number, addedTime: number}}?
    if not entity then return nil end
    return State.stateQueues[entity]
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