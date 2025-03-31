--[[ StatService
    Comprehensive stat system with multipliers, regeneration, and progression.
    Manages player attributes, experience gains, and real-time stat updates.
    @author @Daystopia
    @version 1.1.1
    @date 2025-03-31
]]
local StatService = {}

StatService.Dependencies = {
    "Data",
    "Event"
}

StatService.Modules = {
    "Stat"
}

StatService.Events = {
    Set = { validate = true },
    Update = { validate = true },
    Reset = { validate = true },
    Level = { validate = true },
    Points = { validate = true }
}

local Services
local Modules

--[[ State Management ]]--
local State = {
    playerMultipliers = {},
    regenTasks = setmetatable({}, {__mode = "k"}),
    points = setmetatable({}, {
        __index = function(self, key)
            if not rawget(self, key) then
                rawset(self, key, {})
            end
            return rawget(self, key)
        end
    })
}

-- [[ Core Functions ]]
function StatService:Init(services, modules)
    Services = services
    Modules = modules
    self:StartRegen()
    return true
end

function StatService:Cleanup()
    table.clear(State.playerMultipliers)
    table.clear(State.regenTasks)
    table.clear(State.points)
end

--[[ Progression Functions ]]--
function StatService:AddProgress(entity, amount, target, metadata)
    if not entity or amount <= 0 then return false, "Invalid input" end
    if not target then target = "LEVEL" end

    local currentProgress = entity:GetAttribute(target .. "_PROGRESS") or 0
    local currentLevel = entity:GetAttribute(target) or 1
    local template = Modules.Stat.Templates[target]

    if not template then return false, "Invalid target stat" end

    local baseValue = template.constants and template.constants.progressRequired or Modules.Stat.Constants.PROGRESS_REQUIRED
    local multiplier = template.constants and template.constants.progressGrowthRate or Modules.Stat.Constants.PROGRESS_GROWTH_RATE
    local maxLevel = template.constants and template.constants.maxLevel or Modules.Stat.Constants.MAX_LEVEL

    local newProgress = currentProgress + amount
    local requiredProgress = self:CalculateProgress(currentLevel, currentProgress, baseValue, multiplier)
    local leveled = false
    local oldLevel = currentLevel

    while newProgress >= requiredProgress and currentLevel < maxLevel do
        currentLevel += 1
        newProgress -= requiredProgress
        requiredProgress = self:CalculateProgress(currentLevel, 0, baseValue, multiplier)
        leveled = true

        if target == "LEVEL" then
            self:AddPoints(entity, "ATTRIBUTE", Modules.Stat.Constants.PROGRESSION.ATTRIBUTE_POINTS_PER_LEVEL)
        end
    end

    entity:SetAttribute(target .. "_PROGRESS", newProgress)
    if leveled then
        entity:SetAttribute(target, currentLevel)

        if target == "LEVEL" then
            Services.Event:Fire("Stat.Level", {
                entity = entity,
                oldLevel = oldLevel,
                newLevel = currentLevel,
                points = self:GetPoints(entity, "ATTRIBUTE")
            })
        end
    end

    Services.Event:Fire("Stat.Update", {
        entity = entity,
        stat = target,
        type = "progress",
        value = newProgress,
        level = currentLevel,
        previousLevel = oldLevel,
        change = amount,
        metadata = metadata
    })

    return true
end

function StatService:GetProgress(entity, target)
    if not entity then return nil end
    if not target then target = "LEVEL" end

    local currentLevel = entity:GetAttribute(target) or 1
    local currentProgress = entity:GetAttribute(target .. "_PROGRESS") or 0
    local template = Modules.Stat.Templates[target]

    if not template then return nil end

    local baseValue = template.constants and template.constants.progressRequired or Modules.Stat.Constants.PROGRESS_REQUIRED
    local multiplier = template.constants and template.constants.progressGrowthRate or Modules.Stat.Constants.PROGRESS_GROWTH_RATE

    return self:CalculateProgress(currentLevel, currentProgress, baseValue, multiplier)
end

function StatService:CalculateProgress(level: number, progress: number, baseValue: number, multiplier: number)
    return math.floor(baseValue * (level ^ multiplier))
end

--[[ Points Functions ]]--
function StatService:AddPoints(entity: any, pointType: string, amount: number)
    if not (entity and pointType) then return end

    local userId = entity.UserId
    if not userId then return end

    State.points[userId][pointType] = (State.points[userId][pointType] or 0) + amount

    Services.Event:Fire("Stat.Points", {
        entity = entity,
        type = pointType,
        points = State.points[userId][pointType],
        added = amount
    })
end

function StatService:GetPoints(entity: any, pointType: string): number
    if not (entity and pointType) then return 0 end

    local userId = entity.UserId
    if not userId then return 0 end

    return State.points[userId][pointType] or 0
end

function StatService:SpendPoints(entity: any, pointType: string, target: string, amount: number): boolean
    if not (entity and pointType and target and amount > 0) then return false end

    local userId = entity.UserId
    if not userId then return false end

    local availablePoints = State.points[userId][pointType] or 0
    if availablePoints < amount then return false end

    local template = Modules.Stat.Templates[target]
    if not template then return false end

    if pointType == "ATTRIBUTE" and template.category ~= "ATTRIBUTE" then
        return false
    end

    local success = self:ModifyStat(entity, target, {
        operation = "add",
        value = amount,
        metadata = { 
            source = "points",
            type = pointType
        }
    })

    if success then
        State.points[userId][pointType] -= amount

        Services.Event:Fire("Stat.Points", {
            entity = entity,
            type = pointType,
            points = State.points[userId][pointType],
            spent = amount,
            target = target
        })
    end

    return success
end

--[[ Stat Functions ]]--
local StatOperations = {
    add = function(current, value) return current + value end,
    subtract = function(current, value) return current - value end,
    multiply = function(current, value) return current * value end,
    divide = function(current, value)
        if value == 0 then return current end
        return current / value
    end,
    power = function(current, value) return current ^ value end,
    root = function(current, value)
        if value == 0 then return current end
        if current < 0 and value % 2 == 0 then return 0 end
        return math.sign(current) * math.abs(current) ^ (1 / value)
    end,
    set = function(_, value) return value end,
    min = function(current, value) return math.min(current, value) end,
    max = function(current, value) return math.max(current, value) end
}

function StatService:SetStat(entity: {GetAttribute: (string) -> any, SetAttribute: (string, any) -> nil}, statName: string, value: number, metadata: {[string]: any}?): (boolean, any?)
    if not (entity and statName) then
        return false, "Missing required parameters"
    end

    local attrName = statName:upper()
    local template = Modules.Stat.Templates[attrName]

    if not template then
        return false, "Invalid stat"
    end

    if template.fixed then
        return false, "Cannot modify fixed stat"
    end

    local oldValue = entity:GetAttribute(attrName)
    entity:SetAttribute(attrName, value)

    if template.effects then
        for effectType, effect in pairs(template.effects) do
            local effectValue = effect.value
            if effect.type == "MULTIPLY" then
                effectValue = value * effect.value
            elseif effect.type == "PERCENT" then
                effectValue = value * (effect.value / 100)
            end
            entity:SetAttribute(attrName .. "_" .. effectType, effectValue)
        end
    end

    if template.global and template.type == "MULTIPLIER" then
        for affectedStat, statTemplate in pairs(Modules.Stat.Templates) do
            if statTemplate.multiplier and affectedStat ~= attrName then
                local currentMultiplier = entity:GetAttribute(affectedStat .. "_MULTIPLIER") or Modules.Stat.Constants.MULTIPLIER
                entity:SetAttribute(affectedStat .. "_MULTIPLIER", currentMultiplier * value)
            end
        end
    end

    Services.Event:Fire("Stat.Set", {
        entity = entity,
        stat = attrName,
        value = value,
        previousValue = oldValue,
        effects = template.effects,
        metadata = metadata
    })

    return true, value
end

function StatService:ModifyStat(entity: {GetAttribute: (string) -> any, SetAttribute: (string, any) -> nil}, statName: string, modification: {operation: string?, value: number, clamp: boolean?, metadata: {[string]: any}?}): (boolean, any?)
    if not (entity and statName) then
        return false, "Missing required parameters"
    end

    local attrName = statName:upper()
    local currentValue = entity:GetAttribute(attrName)
    local template = Modules.Stat.Templates[attrName]

    if not currentValue then
        return false, "Stat not initialized"
    end

    if not template then
        return false, "Invalid stat"
    end

    if template.fixed then
        return false, "Cannot modify fixed stat"
    end

    local operation = modification.operation or "add"
    local operationFunc = StatOperations[operation]
    if not operationFunc then
        return false, "Invalid operation"
    end

    local newValue = operationFunc(currentValue, modification.value)

    newValue = self:ApplyEffects(entity, attrName, newValue)

    if modification.clamp ~= false then
        newValue = math.max(newValue, template.minValue or 0)
        if template.maxValue then
            newValue = math.min(newValue, template.maxValue)
        end
    end

    local success, result = self:SetStat(entity, attrName, newValue, {
        operation = operation,
        change = modification.value,
        previousValue = currentValue,
        metadata = modification.metadata
    })

    if success then
        Services.Event:Fire("Stat.Update", {
            entity = entity,
            stat = attrName,
            type = "modify",
            value = newValue,
            previousValue = currentValue,
            operation = operation,
            change = modification.value,
            metadata = modification.metadata
        })
    end

    return success, result
end

--[[ Effect Functions ]]--
function StatService:CalculateEffects(entity: any, statName: string, effectType: string): {baseEffects: {[string]: number}, chainedEffects: {[string]: number}, metadata: {[string]: any}}
    local result = {
        baseEffects = {},
        chainedEffects = {},
        metadata = {
            sources = {},
            order = {}
        }
    }

    for operation in pairs(StatOperations) do
        result.baseEffects[operation] = 0
        result.chainedEffects[operation] = operation == "multiply" and 1 or 0
    end

    for sourceStat, template in pairs(Modules.Stat.Templates) do
        if template.effects and template.effects[statName .. "_" .. effectType] then
            local effect = template.effects[statName .. "_" .. effectType]
            local value = effect.value

            if type(value) == "function" then
                value = value(entity)
            end

            local operation = effect.type:lower()
            if operation == "percent" then
                result.baseEffects.add += value / 100
            elseif StatOperations[operation] then
                if operation == "multiply" or operation == "divide" then
                    result.chainedEffects[operation] = operation == "multiply"
                        and (result.chainedEffects[operation] * value)
                        or (result.chainedEffects[operation] + (1/value))
                else
                    result.baseEffects[operation] += value
                end

                table.insert(result.metadata.order, operation)
            end

            table.insert(result.metadata.sources, {
                stat = sourceStat,
                type = operation,
                value = value
            })
        end
    end

    return result
end

function StatService:ApplyEffects(entity: any, statName: string, baseValue: number): number
    local template = Modules.Stat.Templates[statName]
    if not template then return baseValue end

    local effects = {}
    for otherStat, otherTemplate in pairs(Modules.Stat.Templates) do
        if otherTemplate.effects then
            for effectName, _ in pairs(otherTemplate.effects) do
                local targetStat, effectType = effectName:match("(.+)_(.+)")
                if targetStat == statName then
                    effects[effectType] = true
                end
            end
        end
    end

    local finalValue = baseValue
    for effectType in pairs(effects) do
        local effect = self:CalculateEffects(entity, statName, effectType)

        for operation, value in pairs(effect.baseEffects) do
            if value ~= 0 then
                finalValue = StatOperations[operation](finalValue, value)
            end
        end

        for operation, value in pairs(effect.chainedEffects) do
            if operation == "multiply" and value ~= 1 or
               operation ~= "multiply" and value ~= 0 then
                finalValue = StatOperations[operation](finalValue, value)
            end
        end
    end

    return finalValue
end

--[[ Regen Functions ]]--
function StatService:RegenStat(entity: {GetAttribute: (string) -> any}, statName: string): (boolean, any?)
    if not entity then return false, nil end

    local attrName = statName:upper()
    local template = Modules.Stat.Templates[attrName]
    if not template or not template.regen then return false, nil end

    local currentValue = entity:GetAttribute(attrName)
    if not currentValue then return false, nil end

    local maxValue = template.maxValue
    if maxValue and currentValue >= maxValue then return false, nil end

    if template.regen.condition and not template.regen.condition(entity) then
        return false, nil
    end

    local regenRate = template.regen.amount

    local effects = self:CalculateEffects(entity, attrName, "REGEN")
    regenRate = (regenRate + effects.value) * effects.multiplier

    return self:ModifyStat(entity, statName, {
        value = regenRate,
        operation = "add",
        clamp = true,
        metadata = {
            type = "regen",
            baseAmount = template.regen.amount,
            finalAmount = regenRate,
            effects = effects.metadata.sources
        }
    })
end

function StatService:StartRegen()
    task.spawn(function()
        while true do
            task.wait(1)
            for entity, stats in pairs(State.regenTasks) do
                if entity:IsDescendantOf(game) then
                    for statName in pairs(stats) do
                        self:RegenStat(entity, statName)
                    end
                else
                    State.regenTasks[entity] = nil
                end
            end
        end
    end)
end

function StatService:EnableRegen(entity: {}, statName: string)
    if not entity then return end
    State.regenTasks[entity] = State.regenTasks[entity] or {}
    State.regenTasks[entity][statName] = true
end

function StatService:DisableRegen(entity: {}, statName: string)
    if not entity or not State.regenTasks[entity] then return end
    State.regenTasks[entity][statName] = nil
    if not next(State.regenTasks[entity]) then
        State.regenTasks[entity] = nil
    end
end

return StatService