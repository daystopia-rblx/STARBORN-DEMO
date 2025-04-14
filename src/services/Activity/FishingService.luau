--[[ FishingService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-15
]]
local FishingService = {}

--[[ Dependencies ]]
FishingService.Dependencies = {
    "Event",
    "Data",
    "Stat",
    "Inventory",
    "Object",
    "Interact",
    "Animation",
    "Time",
    "Weather",
    "Audio"
}

FishingService.Modules = {
    "Fish"
}

--[[ Events ]]
FishingService.Events = {
    Cast = { validate = true },
    Bite = { validate = true },
    Catch = { validate = true },
    Fail = { validate = true },
    Discover = { validate = true }
}

--[[ Types ]]
type FishingSession = {
    id: string,
    playerId: string,
    rodId: string,
    spotId: string?,
    castTime: number,
    castPower: number,
    castPosition: Vector3,
    biteTime: number?,
    fishId: string?,
    fishRarity: string?,
    complete: boolean,
    successful: boolean,
    character: Model?,
    animations: {[string]: any}?,
    sounds: {[string]: any}?
}

type FishingSpot = {
    id: string,
    position: Vector3,
    radius: number,
    type: string,
    timeRestriction: {start: number, finish: number}?,
    weatherRestriction: {[string]: boolean}?,
    seasonRestriction: {[string]: boolean}?,
    fishPool: {[string]: number},
    discovered: {[string]: boolean}
}

--[[ Constants ]]
local BITE_TIME_RANGE = {
    MIN = 3,
    MAX = 15
}

local FISH_RARITY = {
    COMMON = "common",
    UNCOMMON = "uncommon",
    RARE = "rare",
    LEGENDARY = "legendary"
}

--[[ State ]]
local Services
local Modules
local State = {
    fishingSessions = {},
    activeRods = {},
    fishingSpots = {},
    discoveredSpots = {}
}

--[[ Event Listeners ]]
FishingService.Listeners = {
    ["Data.Init"] = function(self, data)
        if not data or not data.userId or not data.player then return end

        local userId = data.userId
        local playerData = data.data.PlayerData

        if playerData and playerData.fishing and playerData.fishing.discoveredSpots then
            State.discoveredSpots[userId] = playerData.fishing.discoveredSpots
        else
            State.discoveredSpots[userId] = {}
        end
    end,

    ["Player.Left"] = function(self, data)
        if not data or not data.userId then return end

        local userId = data.userId

        if State.activeRods[userId] then
            local sessionId = State.activeRods[userId]
            self:CancelFishing(userId, sessionId)
        end
    end
}

--[[ Core Functions ]]
function FishingService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function FishingService:Start()
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:UpdateSessions(dt)
    end)

    self:RegisterSpot()
    return true
end

--[[ Spot Registration ]]
function FishingService:RegisterSpot(spotId, attributes)
    if not spotId then
        Services.Object:RegisterScanner("FISHING_SPOT",
            function(instance)
                if not (instance:IsA("Model") or instance:IsA("BasePart")) then
                    return
                end

                local spotId = Services.Object:GetID(instance)
                if not spotId then return end

                local position
                if instance:IsA("Model") then
                    position = instance.PrimaryPart and
                        instance.PrimaryPart.Position or
                        instance:GetPivot().Position
                else
                    position = instance.Position
                end

                local attributes = {
                    id = spotId,
                    instance = instance,
                    position = position,
                    radius = instance:GetAttribute("RADIUS") or 10,
                    type = instance:GetAttribute("TYPE") or "pond",
                    timeRestriction = {
                        start = instance:GetAttribute("TIME_START") or 0,
                        finish = instance:GetAttribute("TIME_END") or 24
                    },
                    weatherRestriction = {},
                    seasonRestriction = {},
                    fishPool = {}
                }

                local weatherAttr = instance:GetAttribute("WEATHER")
                if weatherAttr and type(weatherAttr) == "string" then
                    for _, weather in ipairs(string.split(weatherAttr, ",")) do
                        attributes.weatherRestriction[weather] = true
                    end
                end

                local seasonAttr = instance:GetAttribute("SEASON")
                if seasonAttr and type(seasonAttr) == "string" then
                    for _, season in ipairs(string.split(seasonAttr, ",")) do
                        attributes.seasonRestriction[season] = true
                    end
                end

                local fishPoolAttr = instance:GetAttribute("FISH_POOL")
                if fishPoolAttr and type(fishPoolAttr) == "string" then
                    local spotType = fishPoolAttr:upper()
                    if Modules.Fish.Spots[spotType] and Modules.Fish.Spots[spotType].defaults.fishPool then
                        attributes.fishPool = Modules.Fish.Spots[spotType].defaults.fishPool
                    else
                        attributes.fishPool = Modules.Fish.DefaultPool
                    end
                else
                    attributes.fishPool = Modules.Fish.DefaultPool
                end

                self:RegisterSpot(spotId, attributes)
            end,
            function(instance)
                if not (instance:IsA("Model") or instance:IsA("BasePart")) then
                    return
                end

                local spotId = Services.Object:GetID(instance)
                if spotId and State.fishingSpots[spotId] then
                    State.fishingSpots[spotId] = nil
                end
            end
        )
        return
    end

    if not attributes.instance then return end
    if not attributes.position then return end

    State.fishingSpots[spotId] = attributes
end

--[[ Fishing Functions ]]
function FishingService:StartFishing(player, rodId, castPower, castPosition)
    if not player or not rodId then return false, "Invalid parameters" end

    local userId = tostring(player.UserId)

    if State.activeRods[userId] then
        return false, "Already fishing"
    end

    local rodStats = self:GetRod(rodId)
    if not rodStats then
        return false, "Invalid rod"
    end

    local castDistance = castPower * rodStats.castDistance
    local sessionId = Services.Data:GenerateId("UUID")

    local spotId, spotData = self:FindSpot(castPosition, castDistance)

    local character = player.Character

    local session = {
        id = sessionId,
        playerId = userId,
        rodId = rodId,
        spotId = spotId,
        castTime = os.time(),
        castPower = castPower,
        castPosition = castPosition,
        biteTime = nil,
        fishId = nil,
        fishRarity = nil,
        complete = false,
        successful = false,
        character = character,
        animations = {},
        sounds = {}
    }

    State.fishingSessions[sessionId] = session
    State.activeRods[userId] = sessionId

    if character then
        session.animations.cast = Services.Animation:PlayAnimation(character, {
            preset = "FISHING.CAST",
            looped = false,
            priority = Enum.AnimationPriority.Action
        })

        task.delay(1, function()
            if session.complete then return end
            if session.animations.cast then
                session.animations.cast:Stop()
                session.animations.cast = nil
            end

            session.animations.idle = Services.Animation:PlayAnimation(character, {
                preset = "FISHING.IDLE",
                looped = true,
                priority = Enum.AnimationPriority.Core
            })
        end)
    end

    if spotId and not State.discoveredSpots[userId][spotId] then
        State.discoveredSpots[userId][spotId] = true

        Services.Event:Fire("Fishing.Discover", {
            playerId = userId,
            spotId = spotId,
            spotType = spotData.type
        })
    end

    local skill = Services.Stat:GetStat(player, "FISHING") or 1
    local skillBoost = math.min(skill / 100, 0.5)

    local baseRodSpeed = rodStats.reelSpeed
    local adjustedSpeed = baseRodSpeed * (1 + skillBoost)
    local minBiteTime = BITE_TIME_RANGE.MIN / adjustedSpeed
    local maxBiteTime = BITE_TIME_RANGE.MAX / adjustedSpeed
    local biteTime = minBiteTime + (maxBiteTime - minBiteTime) * math.random()

    task.delay(biteTime, function()
        if not session or session.complete then return end
        session.biteTime = os.time()

        local fishId, fishRarity = self:DetermineFish(session)
        session.fishId = fishId
        session.fishRarity = fishRarity

        if session.animations.idle then
            session.animations.idle:Stop()
            session.animations.idle = nil
        end

        if character then
            session.animations.bite = Services.Animation:PlayAnimation(character, {
                preset = "FISHING.BITE",
                looped = true,
                priority = Enum.AnimationPriority.Core
            })
        end

        Services.Event:Fire("Fishing.Bite", {
            sessionId = sessionId,
            playerId = userId,
            fishRarity = fishRarity
        })

        session.autoReelTimer = task.delay(5, function()
            if not session.complete then
                self:FailFishing(sessionId)
            end
        end)
    end)

    Services.Event:Fire("Fishing.Cast", {
        sessionId = sessionId,
        playerId = userId,
        rodId = rodId,
        castPower = castPower,
        spotId = spotId
    })

    return true, sessionId
end

function FishingService:ReelFishing(playerId, sessionId)
    local session = State.fishingSessions[sessionId]
    if not session or session.complete then return false end

    if session.playerId ~= playerId then return false end

    if not session.biteTime then
        return false, "No bite yet"
    end

    local player = game.Players:GetPlayerByUserId(tonumber(playerId))
    if not player then return false end

    local skillLevel = self:GetSkill(player)
    local rodStats = self:GetRod(session.rodId)

    if session.autoReelTimer then
        task.cancel(session.autoReelTimer)
        session.autoReelTimer = nil
    end

    local timingSinceMotion = os.time() - session.biteTime
    local perfectTiming = timingSinceMotion >= 0.5 and timingSinceMotion <= 1.5

    local baseSuccess = 0.7
    local skillBonus = skillLevel * 0.02
    local timingBonus = perfectTiming and 0.2 or 0

    local success = math.random() < (baseSuccess + skillBonus + timingBonus)

    session.complete = true
    session.successful = success

    if session.animations.bite then
        session.animations.bite:Stop()
        session.animations.bite = nil
    end

    if session.character then
        session.animations.reel = Services.Animation:PlayAnimation(session.character, {
            preset = "FISHING.REEL",
            looped = false,
            priority = Enum.AnimationPriority.Action
        })

        if success then
            task.delay(0.8, function()
                if session.animations.reel then
                    session.animations.reel:Stop()
                    session.animations.reel = nil
                end

                session.animations.catch = Services.Animation:PlayAnimation(session.character, {
                    preset = "FISHING.CATCH",
                    looped = false,
                    priority = Enum.AnimationPriority.Action
                })
            end)
        end
    end

    if success then
        local fishData = Modules.Fish.GetFish(session.fishId)
        local fishName = "unknown fish"
        if fishData and fishData.variants and fishData.variants.standard then
            fishName = fishData.variants.standard.name
        end

        Services.Inventory:AddItem(player, session.fishId, 1)

        local rarityMultiplier = 1
        if session.fishRarity == FISH_RARITY.UNCOMMON then
            rarityMultiplier = 1.5
        elseif session.fishRarity == FISH_RARITY.RARE then
            rarityMultiplier = 2.5
        elseif session.fishRarity == FISH_RARITY.LEGENDARY then
            rarityMultiplier = 5
        end

        local expGained = math.floor(10 * rarityMultiplier)
        Services.Stat:AddProgress(player, expGained, "FISHING")

        Services.Event:Fire("Fishing.Catch", {
            sessionId = sessionId,
            playerId = session.playerId,
            fishId = session.fishId,
            fishName = fishName,
            fishRarity = session.fishRarity,
            expGained = expGained
        })
    else
        Services.Event:Fire("Fishing.Fail", {
            sessionId = sessionId,
            playerId = session.playerId,
            reason = "reel_failed"
        })
    end

    task.delay(success and 2 or 1.5, function()
        self:CleanupSession(session)
        State.activeRods[playerId] = nil
    end)

    return true
end

function FishingService:CancelFishing(playerId, sessionId)
    local session = State.fishingSessions[sessionId]
    if not session or session.complete then return false end

    if session.playerId ~= playerId then return false end

    session.complete = true
    session.successful = false

    self:CleanupSession(session)

    Services.Event:Fire("Fishing.Fail", {
        sessionId = sessionId,
        playerId = playerId,
        reason = "cancelled"
    })

    State.activeRods[playerId] = nil
    return true
end

function FishingService:FailFishing(sessionId)
    local session = State.fishingSessions[sessionId]
    if not session or session.complete then return false end

    session.complete = true
    session.successful = false

    if session.animations.bite then
        session.animations.bite:Stop()
        session.animations.bite = nil
    end

    Services.Event:Fire("Fishing.Fail", {
        sessionId = sessionId,
        playerId = session.playerId,
        reason = "time_expired"
    })

    task.delay(1.5, function()
        self:CleanupSession(session)
        State.activeRods[session.playerId] = nil
    end)

    return true
end

function FishingService:DetermineFish(session)
    local spotData = session.spotId and State.fishingSpots[session.spotId]
    local fishPool = spotData and spotData.fishPool or Modules.Fish.DefaultPool

    local player = game.Players:GetPlayerByUserId(tonumber(session.playerId))
    local skillLevel = player and self:GetSkill(player) or 1

    local rodStats = self:GetRod(session.rodId)
    local rarityBonus = (rodStats.rarityBonus or 0) + (skillLevel * 0.01)

    local currentWeather = Services.Weather:GetWeather().type
    local currentTime = Services.Time:GetTime().hour
    local timeOfDay = Services.Time:GetTimeOfDay()

    if timeOfDay == "Dawn" or timeOfDay == "Dusk" then
        rarityBonus = rarityBonus + 0.05
    end

    if currentWeather == "Rain" then
        rarityBonus = rarityBonus + 0.1
    elseif currentWeather == "Thunderstorm" then
        rarityBonus = rarityBonus + 0.2
    end

    if rodStats.specialWeather and rodStats.specialWeather == currentWeather then
        rarityBonus = rarityBonus + (rodStats.weatherBonus or 0.1)
    end

    local weightedPool = {}

    for _, fishEntry in ipairs(fishPool) do
        local adjustedEntry = table.clone(fishEntry)
        local weight = fishEntry.weight

        if fishEntry.rarity == FISH_RARITY.UNCOMMON then
            weight = weight * (1 + rarityBonus)
        elseif fishEntry.rarity == FISH_RARITY.RARE then
            weight = weight * (1 + rarityBonus * 2)
        elseif fishEntry.rarity == FISH_RARITY.LEGENDARY then
            weight = weight * (1 + rarityBonus * 3)
        end

        adjustedEntry.weight = weight
        table.insert(weightedPool, adjustedEntry)
    end

    if #weightedPool == 0 then
        return "SILVERSCALE", FISH_RARITY.COMMON
    end

    local selectedFish = Modules.Loot:SelectItem(weightedPool)

    if selectedFish then
        return selectedFish.id, selectedFish.rarity
    end

    return "SILVERSCALE", FISH_RARITY.COMMON
end

--[[ Spot Functions ]]
function FishingService:FindSpot(position, maxDistance)
    local closestSpot = nil
    local closestDistance = maxDistance or 100

    for spotId, spotData in pairs(State.fishingSpots) do
        local spotPosition

        if spotData.instance then
            if spotData.instance:IsA("Model") then
                spotPosition = spotData.instance.PrimaryPart and
                    spotData.instance.PrimaryPart.Position or
                    spotData.instance:GetPivot().Position
            else
                spotPosition = spotData.instance.Position
            end
        else
            continue
        end

        local distance = (spotPosition - position).Magnitude
        if distance < closestDistance and distance <= spotData.radius then
            local isValid = self:ValidateSpot(spotData)
            if isValid then
                closestSpot = spotData
                closestDistance = distance
            end
        end
    end

    return closestSpot and closestSpot.id, closestSpot
end

function FishingService:ValidateSpot(spotData)
    if not spotData then return false end

    if spotData.timeRestriction then
        local currentTime = Services.Time:GetTime().hour
        if currentTime < spotData.timeRestriction.start or
           currentTime > spotData.timeRestriction.finish then
            return false
        end
    end

    if spotData.weatherRestriction then
        local currentWeather = Services.Weather:GetWeather().type
        if spotData.weatherRestriction[currentWeather] == false then
            return false
        end
    end

    return true
end

--[[ Session Functions ]]
function FishingService:UpdateSessions(dt)
    for sessionId, session in pairs(State.fishingSessions) do
        if not session.complete and not session.biteTime and os.time() - session.castTime > 60 then
            self:FailFishing(sessionId)
        end
    end
end

function FishingService:CleanupSession(session)
    if not session then return end

    for _, anim in pairs(session.animations or {}) do
        if anim.Stop then
            anim:Stop()
        end
    end
    session.animations = {}

    if session.autoReelTimer then
        task.cancel(session.autoReelTimer)
        session.autoReelTimer = nil
    end
end

function FishingService:GetSession(playerId)
    if not playerId then return nil end

    local sessionId = State.activeRods[playerId]
    if not sessionId then return nil end

    return State.fishingSessions[sessionId]
end

--[[ Getter Functions ]]
function FishingService:GetRod(rodId)
    local rodData = Modules.Fish and Modules.Fish.GetRod(rodId)
    if not rodData or not rodData.defaults then
        return {
            castDistance = 20,
            reelSpeed = 1,
            rarityBonus = 0
        }
    end

    return rodData.defaults
end

function FishingService:GetSkill(player)
    if not player then return 1 end

    local skillLevel = Services.Stat:GetStat(player, "FISHING") or 1
    return skillLevel
end

function FishingService:GetDiscoveries(userId)
    return State.discoveredSpots[userId] or {}
end

return FishingService