--[[ AfflictionService
    Disease system for area-based afflictions with progressive symptoms.
    Manages infection spread, symptoms, cures, and immunities.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local AfflictionService = {}

AfflictionService.Dependencies = {
    "Event",
    "Stat",
    "Object",
    "Zone",
    "Inventory",
    "Data"
}

AfflictionService.Modules = {
    "Stat",
    "Zone",
    "Affliction"
}

AfflictionService.Events = {
    Infect = { validate = true },
    Cure = { validate = true },
    Progress = { validate = true }
}

local Services
local Modules

local State = {
    infections = {},
    immunities = {},
    connections = {},
    checkTimers = {}
}

AfflictionService.Listeners = {
    ["Zone.Enter"] = function(self, data)
        if not data.player then return end

        local player = data.player
        local userId = tostring(player.UserId)
        local zoneAttributes = data.attributes

        if not zoneAttributes or not zoneAttributes.ZONE_TYPE then return end

        local zoneType = zoneAttributes.ZONE_TYPE:upper()

        local zoneData = Modules.Zone.GetZone(zoneType)

        for _, category in pairs(Modules.Plague.CategoryGroups) do
            for _, plagueType in ipairs(category) do
                local plagueData = Modules.Plague.GetPlague(plagueType)
                if plagueData and table.find(plagueData.zones, zoneType) then
                    self:StartExposure(player, plagueType)
                end
            end
        end
    end,

    ["Zone.Exit"] = function(self, data)
        if not data.player then return end

        local player = data.player
        local userId = tostring(player.UserId)
        local zoneAttributes = data.attributes

        if not zoneAttributes or not zoneAttributes.ZONE_TYPE then return end

        local zoneType = zoneAttributes.ZONE_TYPE:upper()

        for _, category in pairs(Modules.Plague.CategoryGroups) do
            for _, plagueType in ipairs(category) do
                local plagueData = Modules.Plague.GetPlague(plagueType)
                if plagueData and table.find(plagueData.zones, zoneType) then
                    self:StopExposure(player, plagueType)
                end
            end
        end
    end,

    ["Inventory.Use"] = function(self, data)
        if not (data.entity and data.itemId) then return end

        for _, category in pairs(Modules.Plague.Templates) do
            for plagueType, plagueData in pairs(category) do
                if plagueData.cures and plagueData.cures[data.itemId] then
                    self:AttemptCure(data.entity, plagueType, data.itemId)
                end
            end
        end
    end,

    ["Data.Init"] = function(self, data)
        if not data.player or not data.data or not data.data.PlayerData then return end

        local player = data.player
        local playerData = data.data.PlayerData
        local savedPlagues = playerData.plagues

        if not savedPlagues then return end

        for plagueType, infectionData in pairs(savedPlagues) do
            if Modules.Plague.GetPlague(plagueType) then
                self:LoadInfection(player, plagueType, infectionData)
            end
        end
    end
}

--[[ Core Functions ]]
function AfflictionService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function AfflictionService:Start()
    game:GetService("RunService").Heartbeat:Connect(function()
        self:ProcessDisease()
    end)
    return true
end

function AfflictionService:Cleanup()
    for userId, timers in pairs(State.checkTimers) do
        for _, timer in pairs(timers) do
            timer:Disconnect()
        end
    end

    table.clear(State.infections)
    table.clear(State.immunities)
    table.clear(State.checkTimers)
    table.clear(State.connections)
end

--[[ Disease Functions ]]
function AfflictionService:ProcessDisease()
    for userId, infections in pairs(State.infections) do
        for plagueType, infectionData in pairs(infections) do
            local plagueData = Modules.Plague.GetPlague(plagueType)
            if not plagueData then continue end

            local player = game.Players:GetPlayerByUserId(tonumber(userId))
            if player then
                local stageData = plagueData.stages[infectionData.stage]
                if stageData and stageData.tickEffects then
                    for stat, effect in pairs(stageData.tickEffects) do
                        local value = (type(effect.value) == "function") and effect.value(player) or effect.value
                        Services.Stat:ModifyStat(player, stat, {
                            value = value,
                            operation = "add",
                            metadata = {
                                source = "plague_tick",
                                plagueType = plagueType
                            }
                        })
                    end
                end
            end
        end
    end
end

--[[ Exposure Functions ]]
function AfflictionService:StartExposure(player, plagueType)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    if not plagueData then return end

    State.checkTimers[userId] = State.checkTimers[userId] or {}

    if State.checkTimers[userId][plagueType] then
        State.checkTimers[userId][plagueType]:Disconnect()
    end

    local connection
    connection = task.spawn(function()
        while true do
            task.wait(plagueData.checkInterval)

            if self:CheckImmunity(player, plagueType) then
                continue
            end

            if math.random() < plagueData.infectionChance then
                self:InfectPlayer(player, plagueType)
            end
        end
    end)

    State.checkTimers[userId][plagueType] = {
        Disconnect = function()
            task.cancel(connection)
        end
    }
end

function AfflictionService:StopExposure(player, plagueType)
    local userId = tostring(player.UserId)

    if not State.checkTimers[userId] or not State.checkTimers[userId][plagueType] then
        return
    end

    State.checkTimers[userId][plagueType]:Disconnect()
    State.checkTimers[userId][plagueType] = nil
end

function AfflictionService:InfectPlayer(player, plagueType)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    if not plagueData then return end

    if State.infections[userId] and State.infections[userId][plagueType] then
        return
    end

    State.infections[userId] = State.infections[userId] or {}
    State.infections[userId][plagueType] = {
        stage = 1,
        timeInfected = os.time(),
        lastProgress = os.time()
    }

    self:ApplyEffects(player, plagueType, 1)

    task.spawn(function()
        self:ProcessCycle(player, plagueType)
    end)

    Services.Event:Fire("Plague.Infect", {
        player = player,
        plagueType = plagueType,
        plagueName = plagueData.name,
        stage = 1,
        effects = plagueData.stages[1].effects
    })

    Services.Event:FireTo(player, "Plague.Infect", {
        plagueType = plagueType,
        plagueName = plagueData.name,
        description = plagueData.description,
        stageName = plagueData.stages[1].name,
        stageDesc = plagueData.stages[1].description
    })

    player:SetAttribute("DISEASE_" .. plagueType, true)

    return true
end

function AfflictionService:ProcessCycle(player, plagueType)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    while true do
        if not State.infections[userId] or not State.infections[userId][plagueType] then
            break
        end

        local infection = State.infections[userId][plagueType]
        local currentStage = infection.stage
        local stageData = plagueData.stages[currentStage]

        local now = os.time()
        local timeInStage = now - infection.lastProgress

        if timeInStage >= stageData.duration and currentStage < #plagueData.stages then
            infection.stage = currentStage + 1
            infection.lastProgress = now

            self:ApplyEffects(player, plagueType, infection.stage)

            Services.Event:Fire("Plague.Progress", {
                player = player,
                plagueType = plagueType,
                plagueName = plagueData.name,
                oldStage = currentStage,
                newStage = infection.stage,
                effects = plagueData.stages[infection.stage].effects
            })

            Services.Event:FireTo(player, "Plague.Progress", {
                plagueType = plagueType,
                plagueName = plagueData.name,
                stageName = plagueData.stages[infection.stage].name,
                stageDesc = plagueData.stages[infection.stage].description
            })
        end

        task.wait(plagueData.progressInterval)
    end
end

function AfflictionService:ApplyEffects(player, plagueType, stage)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    if not plagueData or not plagueData.stages[stage] then return end

    local stageData = plagueData.stages[stage]
    local effects = stageData.effects

    if stage > 1 then
        local prevStageEffects = plagueData.stages[stage-1].effects
        for stat, _ in pairs(prevStageEffects) do
            Services.Stat:RemoveBuff(userId, stat, "plague_" .. plagueType)
        end
    end

    for stat, effectData in pairs(effects) do
        local value = effectData.value
        local effectType = effectData.type

        Services.Stat:ApplyBuff(userId, stat, value, "plague_" .. plagueType, effectData.duration)
    end

    player:SetAttribute("AFFLICTION", plagueData.name)
    player:SetAttribute("AFFLICTION_STAGE", stage)
    player:SetAttribute("AFFLICTION_SEVERITY", stage / #plagueData.stages)

    player:SetAttribute("DISEASE_TYPE", plagueType)
    player:SetAttribute("DISEASE_NAME", plagueData.name)
    player:SetAttribute("DISEASE_STAGE", stage)
    player:SetAttribute("DISEASE_MAX_STAGE", #plagueData.stages)
    player:SetAttribute("DISEASE_INFECTED_AT", State.infections[userId][plagueType].timeInfected)

    return true
end

function AfflictionService:AttemptCure(player, plagueType, itemId)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    if not State.infections[userId] or not State.infections[userId][plagueType] then
        return false, "Not infected with " .. plagueData.name
    end

    if not plagueData.cures[itemId] then
        return false, "This item is not effective against " .. plagueData.name
    end

    local cureData = plagueData.cures[itemId]
    local effectiveness = cureData.effectiveness or 0

    local alchemySkill = Services.Stat:GetStat(player, "ALCHEMY") or 1
    if alchemySkill > 1 then
        effectiveness = math.min(1.0, effectiveness + (alchemySkill * 0.005))
    end

    if math.random() <= effectiveness then
        self:CurePlayer(player, plagueType)
        Services.Stat:AddProgress(player, Modules.Plague.Constants.ALCHEMY_XP.CURE_SUCCESS, "ALCHEMY")
        return true, "Successfully cured " .. plagueData.name
    else
        Services.Stat:AddProgress(player, Modules.Plague.Constants.ALCHEMY_XP.CURE_ATTEMPT, "ALCHEMY")
        return false, "The remedy was not effective this time"
    end
end

function AfflictionService:CurePlayer(player, plagueType)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    if not State.infections[userId] or not State.infections[userId][plagueType] then
        return false
    end

    local infection = State.infections[userId][plagueType]
    local currentStage = infection.stage

    local stageData = plagueData.stages[currentStage]
    for stat, _ in pairs(stageData.effects) do
        Services.Stat:RemoveBuff(userId, stat, "plague_" .. plagueType)
    end

    if plagueData.recoveryEffects then
        for stat, effectData in pairs(plagueData.recoveryEffects) do
            Services.Stat:ApplyBuff(userId, stat, effectData.value, "plague_recovery_" .. plagueType, effectData.duration or 3600)
        end
    end

    if plagueData.immunity then
        State.immunities[userId] = State.immunities[userId] or {}
        State.immunities[userId][plagueType] = {
            expireTime = os.time() + plagueData.immunity.duration,
            resistance = plagueData.immunity.resistance
        }
    end

    State.infections[userId][plagueType] = nil
    if not next(State.infections[userId]) then
        player:SetAttribute("AFFLICTION", nil)
        player:SetAttribute("AFFLICTION_STAGE", nil)
        player:SetAttribute("AFFLICTION_SEVERITY", nil)
    end

    player:SetAttribute("DISEASE_" .. plagueType, nil)

    player:SetAttribute("DISEASE_TYPE", nil)
    player:SetAttribute("DISEASE_NAME", nil)
    player:SetAttribute("DISEASE_STAGE", nil)
    player:SetAttribute("DISEASE_MAX_STAGE", nil)
    player:SetAttribute("DISEASE_INFECTED_AT", nil)

    Services.Event:Fire("Plague.Cure", {
        player = player,
        plagueType = plagueType,
        plagueName = plagueData.name
    })

    Services.Event:FireTo(player, "Plague.Cure", {
        plagueType = plagueType,
        plagueName = plagueData.name,
        immunity = plagueData.immunity and plagueData.immunity.duration or 0
    })

    return true
end

function AfflictionService:CheckImmunity(player, plagueType)
    local userId = tostring(player.UserId)

    if not State.immunities[userId] or not State.immunities[userId][plagueType] then
        return false
    end

    local immunity = State.immunities[userId][plagueType]
    local now = os.time()

    if immunity.expireTime <= now then
        State.immunities[userId][plagueType] = nil
        return false
    end

    return math.random() <= immunity.resistance
end

function AfflictionService:LoadInfection(player, plagueType, infectionData)
    local userId = tostring(player.UserId)
    local plagueData = Modules.Plague.GetPlague(plagueType)

    if not plagueData then return end

    if not infectionData.stage or infectionData.stage < 1 or
       infectionData.stage > #plagueData.stages then
        return
    end

    State.infections[userId] = State.infections[userId] or {}
    State.infections[userId][plagueType] = infectionData

    self:ApplyEffects(player, plagueType, infectionData.stage)

    task.spawn(function()
        self:ProcessCycle(player, plagueType)
    end)

    player:SetAttribute("DISEASE_" .. plagueType, true)

    return true
end

return AfflictionService