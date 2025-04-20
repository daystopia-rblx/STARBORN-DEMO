--[[ StatService
    Comprehensive stat system with multipliers, regeneration, and progression.
    Manages player attributes, experience gains, and real-time stat updates.
    @author @Daystopia
    @version 1.1.3
    @date 2025-04-10
]]
local StatService = {}

StatService.Dependencies = {
    "Event",
    "Object"
}

StatService.Modules = {
    "Stat",
    "Person"
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

local State = {
    players = {},
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
    }),
    buffs = {}
}

StatService.Listeners = {
    ["Player.Join"] = function(self, data)
        local player = data.player
        if player.Character then
            player.Character:SetAttribute("ENTITY", true)
            self:RegisterEntity(player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            character:SetAttribute("ENTITY", true)
            task.wait()
            self:RegisterEntity(character)
        end)
    end,

    ["Data.Init"] = function(self, data)
        local player = data.player
        local userId = data.userId
        local playerData = data.data and data.data.PlayerData

        if not playerData or not playerData.stats then return end

        State.players[userId] = {}

        for statKey, template in pairs(Modules.Stat.Templates) do
            if template.playerSpecific then
                local storageType = self:GetStorage(template)

                if storageType == Modules.Stat.Constants.STORAGE_TYPE.PLAYER_DATA or
                   storageType == Modules.Stat.Constants.STORAGE_TYPE.BOTH then

                    for targetId, relationshipData in pairs(playerData.relationships or {}) do
                        if not State.players[userId][targetId] then
                            State.players[userId][targetId] = {}
                        end

                        local dataKey = statKey:lower()
                        if relationshipData[dataKey] ~= nil then
                           State.players[userId][targetId][statKey] = {
                               value = relationshipData[dataKey],
                               timestamp = relationshipData.lastInteraction or os.time()
                           }
                        end
                    end
                end
            end
        end

        if player.Character then
            player.Character:SetAttribute("ENTITY", true)
        end
    end,

    ["Weather.Update"] = function(self, data)
        local weatherType = data.type
        local intensity = data.intensity
        local weatherEffects = {
            ["Rain"] = {
                stat = "STAMINA",
                multiplier = 1 - (0.05 * intensity)
            },
            ["Thunderstorm"] = {
                stat = "STAMINA",
                multiplier = 1 - (0.1 * intensity)
            },
            ["Snow"] = {
                stat = "SPEED",
                multiplier = 0.8
            },
            ["Windy"] = {
                stat = "STAMINA",
                multiplier = 1 - (0.03 * intensity)
            }
        }

        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if not character then continue end

            local playerId = tostring(player.UserId)
            local effect = weatherEffects[weatherType]

            if effect then
                self:ApplyBuff(playerId, effect.stat, effect.multiplier, "weather_" .. weatherType)
            else
                for stat, buffs in pairs(State.buffs[playerId] or {}) do
                    for i, buff in ipairs(buffs) do
                        if buff.reason:find("weather_") then
                            self:RemoveBuff(playerId, stat, buff.reason)
                        end
                    end
                end
            end
        end
    end
}

-- [[ Core Functions ]]
function StatService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function StatService:Start()
    self:RegisterStats()
    self:StartCycle()
    return true
end

function StatService:Cleanup()
    Services.Object:UnregisterScanner("ENTITY")

    table.clear(State.multipliers)
    table.clear(State.cycles)
    table.clear(State.players)

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

--[[ Registration Functions ]]
function StatService:RegisterStats()
    Services.Object:RegisterScanner("ENTITY",
        function(instance)
            if instance:IsA("Model") then
                self:RegisterEntity(instance)
            end
        end,
        function(instance)
            if instance:IsA("Model") then
                self:UnregisterEntity(instance)
            end
        end
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            player.Character:SetAttribute("ENTITY", true)
        end
        player.CharacterAdded:Connect(function(character)
            character:SetAttribute("ENTITY", true)
        end)
    end
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

function StatService:GetStorage(template, entity)
    if not template.storageType then
        local isUnique = entity and typeof(entity) == "Instance" and entity:GetAttribute("UNIQUE")
        if template.playerSpecific and isUnique then
            return Modules.Stat.Constants.STORAGE_TYPE.PLAYER_DATA
        else
            return template.playerSpecific
                and Modules.Stat.Constants.STORAGE_TYPE.PLAYER_DATA
                or Modules.Stat.Constants.STORAGE_TYPE.ATTRIBUTE
        end
    end

    return template.storageType
end

function StatService:GetStat(target, statName, options)
    if not (target and statName) then return nil end

    local statKey = statName:upper()
    local template = Modules.Stat.Templates[statKey]
    if not template then return nil end

    local isUnique = typeof(target) == "Instance" and target:GetAttribute("UNIQUE")
    local storageType = self:GetStorage(template, target)

    if template.playerSpecific then
        local player, targetId

        if type(options) == "table" then
            player = options.player
            targetId = options.targetId
        end

        if not (player and targetId) then return nil end

        local userId = tostring(player.UserId)
        local baseValue = self:GetBaseStat(target, statName, options)
        local buffMultiplier = self:GetBuff(userId, statKey)

        return baseValue * buffMultiplier
    else
        if typeof(target) ~= "Instance" then return nil end

        local baseValue = target:GetAttribute(statKey) or template.baseValue
        local buffMultiplier = 1

        return baseValue * buffMultiplier
    end
end

function StatService:SetStat(target, statName, value, options)
    if not (target and statName) then return false end

    local statKey = statName:upper()
    local template = Modules.Stat.Templates[statKey]
    if not template then return false end

    local isUnique = typeof(target) == "Instance" and target:GetAttribute("UNIQUE")
    local storageType = self:GetStorage(template, target)

    if template.playerSpecific then
        local player, targetId

        if type(options) == "table" then
            player = options.player
            targetId = options.targetId
        end

        if not (player and targetId) then return false end

        local oldValue = nil
        local shouldUpdatePlayerData = storageType == Modules.Stat.Constants.STORAGE_TYPE.PLAYER_DATA or
                                      storageType == Modules.Stat.Constants.STORAGE_TYPE.BOTH

        local shouldUpdateAttribute = storageType == Modules.Stat.Constants.STORAGE_TYPE.ATTRIBUTE or
                                     storageType == Modules.Stat.Constants.STORAGE_TYPE.BOTH

        if template.minValue ~= nil then
            value = math.max(template.minValue, value)
        end

        if template.maxValue ~= nil then
            value = math.min(template.maxValue, value)
        end

        if shouldUpdatePlayerData or isUnique then
            local userId = tostring(player.UserId)

            State.players[userId] = State.players[userId] or {}
            State.players[userId][targetId] = State.players[userId][targetId] or {}

            if State.players[userId][targetId][statKey] then
                oldValue = State.players[userId][targetId][statKey].value
            else
                State.players[userId][targetId][statKey] = {
                    value = template.baseValue or 0,
                    timestamp = os.time()
                }
                oldValue = State.players[userId][targetId][statKey].value
            end

            State.players[userId][targetId][statKey].value = value
            State.players[userId][targetId][statKey].timestamp = os.time()
        end

        if shouldUpdateAttribute and not isUnique then
            if typeof(target) == "Instance" then
                if oldValue == nil then
                    oldValue = target:GetAttribute(statKey) or template.baseValue or 0
                end
                target:SetAttribute(statKey, value)
            end
        end

        Services.Event:Fire("Stat.Update", {
            player = player,
            target = targetId,
            stat = statKey,
            type = "player_stat",
            value = value,
            previousValue = oldValue or 0,
            metadata = options and options.metadata
        })

        return true
    else
        if typeof(target) ~= "Instance" then return false end

        local attrName = statKey
        local oldValue = target:GetAttribute(attrName)

        if template.fixed then
            return false, "Cannot modify fixed stat"
        end

        target:SetAttribute(attrName, value)

        if template.effects then
            for effectName, effect in pairs(template.effects) do
                local targetStat, effectType = effectName:match("(.+)_(.+)")
                if targetStat and effectType then
                    local effectValue = type(effect.value) == "function" and effect.value(target) or effect.value
                    if effect.type == "MULTIPLY" then
                        effectValue = value * effectValue
                    elseif effect.type == "PERCENT" then
                        effectValue = value * (effectValue / 100)
                    end
                    target:SetAttribute(targetStat .. "_" .. effectType, effectValue)
                end
            end
        end

        if not (options and options.skipSync) then
            if target:IsA("Model") and template.syncProperties then
                for actionType, syncData in pairs(template.syncProperties) do
                    if actionType ~= "default" then
                        local instance

                        if syncData.class == "Humanoid" then
                            instance = target:FindFirstChildOfClass("Humanoid")
                        elseif syncData.class == "Self" then
                            instance = target
                        else
                            instance = target:FindFirstChildOfClass(syncData.class)
                        end

                        if instance then
                            local shouldSync = true
                            if syncData.condition then
                                shouldSync = syncData.condition(target, value, options)
                            end

                            if shouldSync then
                                instance[syncData.property] = value
                            end
                        end
                    end
                end
            end
        end

        local eventData = {
            entity = target,
            stat = attrName,
            value = value,
            previousValue = oldValue,
            effects = template.effects,
            metadata = options
        }

        if attrName == "HEALTH" and target:IsA("Model") then
            local humanoid = target:FindFirstChild("Humanoid")
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
end


function StatService:SetMultiple(targets, statName, amount, options)
    local template = Modules.Stat.Templates[statName]
    if not template then return false end

    for _, target in ipairs(targets) do
        self:SetStat(target, statName, amount, options)
    end

    return true
end

function StatService:ModifyStat(target, statName, modification)
    if not (target and statName and modification) then return false end

    local statKey = statName:upper()
    local template = Modules.Stat.Templates[statKey]
    if not template then return false end

    local operation = modification.operation or "add"
    local operationFunc = StatOperations[operation]
    if not operationFunc then return false end

    if template.playerSpecific then
        local player, targetId

        if type(modification.metadata) == "table" then
            player = modification.metadata.player
            targetId = modification.metadata.targetId
        end

        if not (player and targetId) then return false end

        local currentValue = self:GetStat(target, statName, {player = player, targetId = targetId})
        if currentValue == nil then return false end

        local newValue = operationFunc(currentValue, modification.value)

        local success = self:SetStat(target, statName, newValue, {
            player = player,
            targetId = targetId,
            operation = operation,
            change = modification.value,
            previousValue = currentValue,
            metadata = modification.metadata
        })

        return success
    else
        if typeof(target) ~= "Instance" then return false end

        local attrName = statKey
        local currentValue = target:GetAttribute(attrName)

        if not currentValue then
            return false, "Stat not initialized"
        end

        if template.fixed then
            return false, "Cannot modify fixed stat"
        end

        local newValue = operationFunc(currentValue, modification.value)

        newValue = self:ApplyEffects(target, attrName, newValue)

        if modification.clamp ~= false then
            newValue = math.max(newValue, template.minValue or 0)
            if template.maxValue then
                newValue = math.min(newValue, template.maxValue)
            end
        end

        local success, result = self:SetStat(target, attrName, newValue, {
            operation = operation,
            change = modification.value,
            previousValue = currentValue,
            metadata = modification.metadata
        })

        if success then
            Services.Event:Fire("Stat.Update", {
                entity = target,
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
end

function StatService:ModifyMultiple(targets, statName, modification)
    local template = Modules.Stat.Templates[statName]
    if not template then return end

    for _, target in ipairs(targets) do
        self:ModifyStat(target, statName, modification)
    end

    return true
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
        if humanoid and (humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
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

function StatService:ApplyStat(target, player, statName, operation, amount, options)
    if not (target and statName and operation and amount) then return false end

    local targetId
    local isUnique = typeof(target) == "Instance" and target:GetAttribute("UNIQUE")

    if isUnique then
        targetId = Services.Object:GetID(target)
        if not targetId then return false end
    end

    local statKey = statName:upper()
    local template = Modules.Stat.Templates[statKey]
    if not template then return false end

    local currentValue
    if isUnique and player then
        currentValue = self:GetStat(player, statName, {
            player = player,
            targetId = targetId
        })
    else
        currentValue = typeof(target) == "Instance" and target:GetAttribute(statKey)
    end

    if currentValue == nil then
        currentValue = template.baseValue or 0
    end

    local newValue = currentValue
    if operation == "add" then
        newValue = currentValue + amount
    elseif operation == "subtract" then
        newValue = currentValue - amount
    elseif operation == "multiply" then
        newValue = currentValue * amount
    elseif operation == "divide" then
        if amount ~= 0 then
            newValue = currentValue / amount
        end
    elseif operation == "set" then
        newValue = amount
    end

    if template.minValue ~= nil then
        newValue = math.max(template.minValue, newValue)
    end

    if template.maxValue ~= nil then
        newValue = math.min(template.maxValue, newValue)
    end

    if isUnique and player then
        self:SetStat(player, statName, newValue, {
            player = player,
            targetId = targetId,
            source = options and options.source or operation,
            amount = amount,
            operation = operation,
            metadata = options
        })

        if options and options.showVisual and typeof(target) == "Instance" then
            target:SetAttribute(statKey, newValue)
        end
    else
        self:SetStat(target, statName, newValue, options)
    end

    return true, newValue, currentValue
end

function StatService:StartCycle()
    task.spawn(function()
        local lastPlayerDataUpdate = 0

        while true do
            local currentTime = tick()

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

            if (currentTime - lastPlayerDataUpdate) >= 60 then
                for _, player in ipairs(Players:GetPlayers()) do
                    self:ProcessPlayer(player)
                end
                lastPlayerDataUpdate = currentTime
            end

            task.wait(1)
        end
    end)
end

function StatService:ProcessPlayer(player, dt)
    if not player then return end

    local userId = tostring(player.UserId)
    if not State.players[userId] then return end

    for targetId, stats in pairs(State.players[userId]) do
        for statKey, statData in pairs(stats) do
            local template = Modules.Stat.Templates[statKey]
            if template then
                local now = os.time()
                local timePassed = now - statData.timestamp
                local decayAmount = 0

                if template.decay and template.decay.amount and timePassed > 0 then
                    local decayPerSecond = template.decay.amount / 3600
                    decayAmount = decayPerSecond * timePassed

                    if decayAmount > 0 then
                        local newValue = math.max(
                            template.minValue or 0, 
                            statData.value - decayAmount
                        )

                        local storageType = self:GetStorage(template)
                        local shouldUpdatePlayerData = storageType == Modules.Stat.Constants.STORAGE_TYPE.PLAYER_DATA or
                                                      storageType == Modules.Stat.Constants.STORAGE_TYPE.BOTH

                        local shouldUpdateAttribute = storageType == Modules.Stat.Constants.STORAGE_TYPE.ATTRIBUTE or
                                                     storageType == Modules.Stat.Constants.STORAGE_TYPE.BOTH

                        if shouldUpdatePlayerData then
                            statData.value = newValue
                            statData.timestamp = now
                        end

                        if shouldUpdateAttribute then
                            local entity = Services.Object:GetInstance(targetId)
                            if entity then
                                entity:SetAttribute(statKey, newValue)
                            end
                        end

                        Services.Event:Fire("Stat.Update", {
                            player = player,
                            target = targetId,
                            stat = statKey,
                            type = "decay",
                            value = newValue,
                            previousValue = statData.value,
                            decayAmount = decayAmount
                        })
                    end
                end
            end
        end
    end
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

--[[ Buff Functions ]]
function StatService:ApplyBuff(playerId: string, stat: string, multiplier: number, reason: string, duration: number?)
    State.buffs[playerId] = State.buffs[playerId] or {}
    State.buffs[playerId][stat] = State.buffs[playerId][stat] or {}
    table.insert(State.buffs[playerId][stat], { multiplier = multiplier, reason = reason, duration = duration })

    if duration then
        task.delay(duration, function()
            self:RemoveBuff(playerId, stat, reason)
        end)
    end
end

function StatService:RemoveBuff(playerId: string, stat: string, reason: string)
    if State.buffs[playerId] and State.buffs[playerId][stat] then
        for i, buff in ipairs(State.buffs[playerId][stat]) do
            if buff.reason == reason then
                table.remove(State.buffs[playerId][stat], i)
                break
            end
        end
        if #State.buffs[playerId][stat] == 0 then
            State.buffs[playerId][stat] = nil
        end
    end
end

function StatService:GetBuff(playerId: string, stat: string): number
    if State.buffs[playerId] and State.buffs[playerId][stat] then
        local totalMultiplier = 1
        for _, buff in ipairs(State.buffs[playerId][stat]) do
            totalMultiplier = totalMultiplier * buff.multiplier
        end
        return totalMultiplier
    end
    return 1
end

--[[ Registration Fucntions ]]
function StatService:ApplyProfile(entity, profileName, options)
    if not entity or not profileName then return false end

    local profile = Modules.Stat.EntityProfiles[profileName:upper()]
    if not profile then return false end

    options = options or {}

    local player = Players:GetPlayerFromCharacter(entity)
    local targetId = player and tostring(player.UserId)

    for _, statName in ipairs(profile.stats) do
        local template = Modules.Stat.Templates[statName]
        if template then
            local baseValue = options[statName] or template.baseValue
            local statOptions = { source = "profile_" .. profileName:lower() }

            if template.playerSpecific and player and targetId then
                statOptions.player = player
                statOptions.targetId = targetId
            end

            self:SetStat(entity, statName, baseValue, statOptions)
        end
    end

    if options.enableCycles ~= false then
        for _, statName in ipairs(profile.cycles) do
            self:EnableCycle(entity, statName)
        end
    end

    return true
end

function StatService:RegisterEntity(entity: Instance): boolean
    if not entity:IsA("Model") then return false end

    local isEntity = entity:GetAttribute("ENTITY")
    if not isEntity then return false end

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

    local isCharacter = Players:GetPlayerFromCharacter(entity) ~= nil
    local entityType = entity:GetAttribute("TYPE") or (isCharacter and "CHARACTER" or "Person")

    local success = self:ApplyProfile(entity, entityType)

    if success and isCharacter then
        for _, statName in ipairs(Modules.Stat.EntityProfiles.CHARACTER.stats) do
            local value = entity:GetAttribute(statName)
        end
    end

    if entityType == "Person" or Modules.Person.Categories[entityType] then
        local personType = entityType
        if personType == "Person" then
            personType = entity:GetAttribute("PERSON_TYPE") or "VILLAGER"
        end

        local variant = entity:GetAttribute("VARIANT")
        local customStats = Modules.Person.GetStats(personType, variant)

        if customStats then
            for statName, value in pairs(customStats) do
                self:SetStat(entity, statName, value, { source = "person_template" })
            end

            entity:SetAttribute("PERSON_TYPE", personType)
            if variant then
                entity:SetAttribute("VARIANT", variant)
            end
        end
    end

    local humanoid = entity:FindFirstChild("Humanoid")
    if humanoid then
        State.connections[entity].Humanoid = {}

        local connections = StatService.StatHandlers.Humanoid.setupSync(self, entity, humanoid)
        if connections then
            State.connections[entity].Humanoid.sync = {
                connections = connections,
                cleanup = StatService.StatHandlers.Humanoid.cleanup
            }
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

        local connections = StatService.StatHandlers.Humanoid.setupSync(self, entity, humanoid)
        if connections then
            State.connections[entity].Humanoid.sync = {
                connections = connections,
                cleanup = StatService.StatHandlers.Humanoid.cleanup
            }
        end
    end
end

--[[ Stat Handlers ]]--
StatService.StatHandlers = {
    Humanoid = {
        setupSync = function(self, entity, humanoid)
            local connections = {}

            for statName, template in pairs(Modules.Stat.Templates) do
                if template.syncProperties then
                    for actionType, syncData in pairs(template.syncProperties) do
                        if syncData.class == "Humanoid" then
                            local propertyName = syncData.property

                            if actionType == "default" then
                                self:SetStat(entity, statName, humanoid[propertyName], {
                                    source = "humanoid",
                                    skipSync = true
                                })

                                table.insert(connections, humanoid:GetPropertyChangedSignal(propertyName):Connect(function()
                                    local shouldSync = true
                                    if syncData.condition then
                                        shouldSync = syncData.condition(entity, humanoid[propertyName], {source = "property_change"})
                                    end

                                    if shouldSync then
                                        self:SetStat(entity, statName, humanoid[propertyName], {
                                            source = "humanoid",
                                            skipSync = true
                                        })
                                    end
                                end))
                            end
                        end
                    end
                end
            end

            table.insert(connections, humanoid.HealthChanged:Connect(function(health)
                self:SetStat(entity, "HEALTH", health, {
                    source = "humanoid",
                    skipSync = true
                })
            end))

            table.insert(connections, humanoid.Died:Connect(function()
                self:SetStat(entity, "HEALTH", 0, {
                    source = "humanoid",
                    skipSync = true
                })
            end))

            table.insert(connections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
                local isMoving = humanoid.MoveDirection.Magnitude > 0
                self:SetStat(entity, "SPEED", humanoid.WalkSpeed, {
                    source = "humanoid",
                    skipSync = true,
                    metadata = isMoving and { state = "MOVING" } or nil
                })
            end))

            return connections
        end,

        cleanup = function(connections)
            for _, connection in pairs(connections) do
                connection:Disconnect()
            end
        end
    }
}

return StatService