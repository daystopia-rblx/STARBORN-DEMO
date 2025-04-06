--[[ StatService
    Comprehensive stat system with multipliers, regeneration, and progression.
    Manages player attributes, experience gains, and real-time stat updates.
    @author @Daystopia
    @version 1.1.2
    @date 2025-04-01
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
    Update = { validate = true },
    Reset = { validate = true },
    Level = { validate = true },
    Points = { validate = true }
}

local Players = game:GetService("Players")
local Services
local Modules

StatService.Listeners = {
    [workspace.DescendantAdded] = function(self, instance: Instance)
        if instance:IsA("Model") then
            self:RegisterEntity(instance)
        end
    end,

    [workspace.DescendantRemoving] = function(self, instance: Instance)
        if instance:IsA("Model") then
            self:UnregisterEntity(instance)
        end
    end,

    ["Player.Join"] = function(self, data)
        local player = data.player
        if player.Character then
            self:RegisterEntity(player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            self:RegisterEntity(character)
        end)
    end
}

--[[ State Management ]]
local State = {
    multipliers = {},
    cycles = setmetatable({}, {__mode = "k"}),
    connections = setmetatable({}, {__mode = "k"}),
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
    return true
end

function StatService:Start()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            self:RegisterEntity(player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            self:RegisterEntity(character)
        end)
    end

    for _, instance in workspace:GetDescendants() do
        if instance:IsA("Model") then
            self:RegisterEntity(instance)
        end
    end

    self:StartCycle()
    return true
end

function StatService:Cleanup()
    table.clear(State.multipliers)
    table.clear(State.cycles)

    for entity, entityConnections in pairs(State.connections) do
        for _, typeConnections in pairs(entityConnections) do
            for _, handler in pairs(typeConnections) do
                if handler.cleanup then
                    handler.cleanup(handler.connections)
                end
            end
        end
    end
    table.clear(State.connections)
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
        for effectName, effect in pairs(template.effects) do
            local targetStat, effectType = effectName:match("(.+)_(.+)")
            if targetStat and effectType then
                local effectValue = type(effect.value) == "function" and effect.value(entity) or effect.value
                if effect.type == "MULTIPLY" then
                    effectValue = value * effectValue
                elseif effect.type == "PERCENT" then
                    effectValue = value * (effectValue / 100)
                end
                entity:SetAttribute(targetStat .. "_" .. effectType, effectValue)
            end
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

    if not (metadata and metadata.skipSync) then
        if entity:IsA("Model") then
            local humanoid = entity:FindFirstChild("Humanoid")
            if humanoid then
                if attrName == "HEALTH" then
                    if metadata and metadata.operation == "max" then
                        humanoid.MaxHealth = value
                    else
                        humanoid.Health = value
                    end
                elseif attrName == "SPEED" then
                    humanoid.WalkSpeed = value
                elseif attrName == "JUMP_POWER" then
                    humanoid.JumpPower = value
                end
            end
        end
    end

    local eventData = {
        entity = entity,
        stat = attrName,
        value = value,
        previousValue = oldValue,
        effects = template.effects,
        metadata = metadata
    }

    if attrName == "HEALTH" and entity:IsA("Model") then
        local humanoid = entity:FindFirstChild("Humanoid")
        if humanoid then
            eventData.maxValue = humanoid.MaxHealth
        else
            eventData.maxValue = template.maxValue
        end
    else
        eventData.maxValue = template.maxValue
    end

    Services.Event:Fire("Stat.Update", eventData)

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

--[[ Modification Functions ]]--
function StatService:CycleStat(entity: {GetAttribute: (string) -> any}, statName: string): (boolean, any?)
    if not entity then return false, nil end

    if entity:IsA("Model") then
        local humanoid = entity:FindFirstChild("Humanoid")
        if humanoid and (humanoid.Health <= 0 or not humanoid:GetState() == Enum.HumanoidStateType.Dead) then
            return false, nil
        end
    end

    local attrName = statName:upper()
    local template = Modules.Stat.Templates[attrName]
    if not template or (not template.regen and not template.decay) then return false, nil end

    local currentValue = entity:GetAttribute(attrName)
    if not currentValue then return false, nil end

    if template.regen then
        local maxValue = template.maxValue
        if not maxValue or currentValue < maxValue then
            if not template.regen.condition or template.regen.condition(entity) then
                local regenRate = template.regen.amount
                local effects = self:CalculateEffects(entity, attrName, "REGEN")
                for operation, value in pairs(effects.baseEffects) do
                    if value ~= 0 then
                        regenRate = StatOperations[operation](regenRate, value)
                    end
                end

                for operation, value in pairs(effects.chainedEffects) do
                    if operation == "multiply" and value ~= 1 or
                       operation ~= "multiply" and value ~= 0 then
                        regenRate = StatOperations[operation](regenRate, value)
                    end
                end

                self:ModifyStat(entity, statName, {
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
        end
    end

    if template.decay then
        if not template.decay.condition or template.decay.condition(entity) then
            local decayRate = template.decay.amount
            self:ModifyStat(entity, statName, {
                value = decayRate,
                operation = "subtract",
                clamp = true,
                metadata = {
                    type = "decay",
                    baseAmount = template.decay.amount,
                    finalAmount = decayRate
                }
            })
        end
    end

    return true
end

function StatService:StartCycle()
    task.spawn(function()
        while true do
            task.wait(1)
            for entity, stats in pairs(State.cycles) do
                if entity:IsDescendantOf(game) then
                    local shouldProcess = true
                    if entity:IsA("Model") then
                        local humanoid = entity:FindFirstChild("Humanoid")
                        if humanoid and (humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
                            shouldProcess = false
                        end
                    end

                    if shouldProcess then
                        for statName, config in pairs(stats) do
                            local currentTime = tick()
                            local lastUpdate = config.lastUpdate or 0
                            local interval = config.interval or 1

                            if (currentTime - lastUpdate) >= interval then
                                self:CycleStat(entity, statName)
                                config.lastUpdate = currentTime
                            end
                        end
                    end
                else
                    State.cycles[entity] = nil
                end
            end
        end
    end)
end

function StatService:EnableCycle(entity: {}, statName: string)
    if not entity then return end

    local template = Modules.Stat.Templates[statName:upper()]
    if not template or (not template.regen and not template.decay) then
        return
    end

    local interval = template.decay and template.decay.interval or template.regen and template.regen.interval or 1

    State.cycles[entity] = State.cycles[entity] or {}
    State.cycles[entity][statName] = {
        interval = interval,
        lastUpdate = tick()
    }
end

function StatService:DisableCycle(entity: {}, statName: string)
    if not entity or not State.cycles[entity] then return end
    State.cycles[entity][statName] = nil
    if not next(State.cycles[entity]) then
        State.cycles[entity] = nil
    end
end

--[[ Registration Fucntions ]]
function StatService:RegisterEntity(entity: Instance): boolean
    if not entity:IsA("Model") then return false end

    local isEntity = entity:GetAttribute("ENTITY")
    local isCharacter = Players:GetPlayerFromCharacter(entity) ~= nil

    if not (isEntity or isCharacter) then return false end

    if State.connections[entity] then
        for _, typeConnections in pairs(State.connections[entity]) do
            for _, handler in pairs(typeConnections) do
                if handler.cleanup then
                    handler.cleanup(handler.connections)
                end
            end
        end
    end

    State.connections[entity] = {}

    if isCharacter then
        -- Vital Stats
        self:SetStat(entity, "HEALTH", 100, { source = "init" })
        self:SetStat(entity, "BLOOD", 100, { source = "init" })
        self:SetStat(entity, "OXYGEN", 100, { source = "init" })

        -- Resource Stats
        self:SetStat(entity, "MANA", 100, { source = "init" })
        self:SetStat(entity, "STAMINA", 100, { source = "init" })

        -- Combat Stats
        self:SetStat(entity, "POSTURE", 100, { source = "init" })
        self:SetStat(entity, "RESONANCE", 0, { source = "init" })

        -- Movement Stats
        self:SetStat(entity, "SPEED", Modules.Stat.Constants.MOVEMENT.BASE_WALK_SPEED, { source = "init" })
        self:SetStat(entity, "JUMP_POWER", 50, { source = "init" })

        -- Survival Stats
        self:SetStat(entity, "HUNGER", 100, { source = "init" })
        self:SetStat(entity, "THIRST", 100, { source = "init" })

        -- Regeneration/Decay
        self:EnableCycle(entity, "HEALTH")
        self:EnableCycle(entity, "BLOOD")
        self:EnableCycle(entity, "MANA")
        self:EnableCycle(entity, "STAMINA")
        self:EnableCycle(entity, "POSTURE")
        self:EnableCycle(entity, "HUNGER")
        self:EnableCycle(entity, "THIRST")
        self:EnableCycle(entity, "OXYGEN")
    end

    local humanoid = entity:FindFirstChild("Humanoid")
    if humanoid then
        State.connections[entity].Humanoid = {}

        for statName, handler in pairs(StatService.StatHandlers.Humanoid) do
            local connections = handler.setup(self, entity, humanoid)
            if connections then
                State.connections[entity].Humanoid[statName] = {
                    connections = connections,
                    cleanup = handler.cleanup
                }
            end
        end
    end

    return true
end

function StatService:UnregisterEntity(entity: Instance)
    if not entity then return end

    if State.connections[entity] then
        for _, typeConnections in pairs(State.connections[entity]) do
            for _, handler in pairs(typeConnections) do
                if handler.cleanup then
                    handler.cleanup(handler.connections)
                end
            end
        end
        State.connections[entity] = nil
    end

    if State.cycles[entity] then
        State.cycles[entity] = nil
    end
end

function StatService:SetupEntity(entity: Instance)
    if State.connections[entity] then
        for _, typeConnections in pairs(State.connections[entity]) do
            for _, handler in pairs(typeConnections) do
                if handler.cleanup then
                    handler.cleanup(handler.connections)
                end
            end
        end
    end

    State.connections[entity] = {}

    local humanoid = entity:FindFirstChild("Humanoid")
    if humanoid then
        State.connections[entity].Humanoid = {}

        for statName, handler in pairs(StatService.StatHandlers.Humanoid) do
            local connections = handler.setup(self, entity, humanoid)
            if connections then
                State.connections[entity].Humanoid[statName] = {
                    connections = connections,
                    cleanup = handler.cleanup
                }
            end
        end
    end
end

--[[ Stat Handlers ]]--
StatService.StatHandlers = {
    Humanoid = {
        health = {
            setup = function(self, entity: Model, humanoid: Humanoid)
                self:SetStat(entity, "HEALTH", humanoid.Health, {
                    source = "humanoid",
                    skipSync = true
                })

                self:SetStat(entity, "HEALTH", humanoid.MaxHealth, {
                    source = "humanoid",
                    skipSync = true,
                    operation = "max"
                })

                return {
                    healthChanged = humanoid.HealthChanged:Connect(function(health)
                        self:SetStat(entity, "HEALTH", health, {
                            source = "humanoid",
                            skipSync = true
                        })
                    end),

                    died = humanoid.Died:Connect(function()
                        self:SetStat(entity, "HEALTH", 0, {
                            source = "humanoid",
                            skipSync = true
                        })
                    end)
                }
            end,

            cleanup = function(connections)
                for _, connection in pairs(connections) do
                    connection:Disconnect()
                end
            end
        },

        speed = {
            setup = function(self, entity: Model, humanoid: Humanoid)
                self:SetStat(entity, "SPEED", humanoid.WalkSpeed, {
                    source = "humanoid",
                    skipSync = true
                })

                return {
                    walkSpeedChanged = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                        self:SetStat(entity, "SPEED", humanoid.WalkSpeed, {
                            source = "humanoid",
                            skipSync = true
                        })
                    end),

                    stateChanged = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
                        local isMoving = humanoid.MoveDirection.Magnitude > 0
                        if isMoving then
                            self:SetStat(entity, "SPEED", humanoid.WalkSpeed, {
                                source = "humanoid",
                                skipSync = true,
                                metadata = { state = "MOVING" }
                            })
                        else
                            self:SetStat(entity, "SPEED", humanoid.WalkSpeed, {
                                source = "humanoid",
                                skipSync = true
                            })
                        end
                    end)
                }
            end,

            cleanup = function(connections)
                for _, connection in pairs(connections) do
                    connection:Disconnect()
                end
            end
        }
    },
}

return StatService