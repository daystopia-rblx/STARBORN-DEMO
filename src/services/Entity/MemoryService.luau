--[[ MemoryService
    Handles NPC emotional memory and relationship tracking with players.
    Provides emotional response generation, memory decay, and relationship management.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local MemoryService = {}

MemoryService.Dependencies = {
    "Data",
    "Event",
    "Stat"
}

MemoryService.Modules = {
    "Person",
    "Stat"
}

MemoryService.Events = {
    Emotion = { validate = true },
    Relationship = { validate = true },
    Apology = { validate = true },
    Reputation = { validate = true }
}

local Services
local Modules
local Players = game:GetService("Players")

--[[ Core Functions ]]
function MemoryService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function MemoryService:Start()
    task.spawn(function()
        while true do
            task.wait(3600)
            for _, player in ipairs(Players:GetPlayers()) do
                self:PruneInteractions(player)
            end
        end
    end)
    return true
end

--[[ Memory Functions ]]
function MemoryService:ProcessApology(player, npcId, offenseType)
    local memory = self:GetMemory(player, npcId)
    local relationship = self:GetRelationship(player, npcId)
    if not (memory and relationship) then return false, "No relationship established" end

    offenseType = string.upper(offenseType or "GENERAL")

    local personData = Services.Object:GetInstance(npcId)
    if not personData then return false, "NPC not found" end

    if not personData:GetAttribute("UNIQUE") then
        return false, "NPC does not have unique relationships with players"
    end

    local trustData = Services.Stat:GetStat(player, "TRUST", {player = player, npcId = npcId}) or {}
    local forgivenessThreshold = trustData.metadata and trustData.metadata.forgivenessThreshold or 30

    local trustFactor = relationship.trust / 100
    local acceptanceChance = 0.5 + (trustFactor * 0.5)

    local emotionIntensity = trustData.current or 0

    if emotionIntensity < 0 then
        acceptanceChance = acceptanceChance + (emotionIntensity / 200)
    end

    memory.apologies = memory.apologies or {}
    table.insert(memory.apologies, {
        offense = offenseType,
        timestamp = os.time()
    })

    local isAccepted = acceptanceChance > (1 - (forgivenessThreshold / 100))
    memory.apologies[#memory.apologies].accepted = isAccepted

    local personType = personData:GetAttribute("TYPE") or "VILLAGER"
    local personVariant = personData:GetAttribute("VARIANT")
    local dialogueType = isAccepted and "accepting" or "rejecting"
    local responses = Modules.Person.GetDialogue(personType, personVariant, "apology", dialogueType)
    local response = responses and responses[math.random(#responses)] or "I hear your apology."

    if isAccepted then
        Services.Stat:ModifyStat(player, "TRUST", {
            operation = "add",
            value = forgivenessThreshold/2,
            metadata = {
                player = player,
                npcId = npcId,
                source = "apology",
                accepted = true
            }
        })

        self:UpdateReputation(player, npcId, forgivenessThreshold/4)
        self:UpdateRelationship(player, npcId)

        Services.Event:Fire("Memory.Apology", {
            player = player,
            npcId = npcId,
            accepted = isAccepted,
            response = response,
            trust = relationship.trust,
            mood = relationship.mood,
            reputation = relationship.reputation
        })
    else
        self:UpdateReputation(player, npcId, -5)
    end

    return isAccepted, response
end

function MemoryService:PruneInteractions(player)
    local playerData = Services.Data:GetPlayerData(player)
    if not playerData or not playerData.memory then return end

    for npcId, memory in pairs(playerData.memory) do
        if memory.interactions then
            local currentTime = os.time()
            local cutoffTime = currentTime - (30 * 86400)
            local i = 1
            while i <= #memory.interactions do
                if memory.interactions[i].timestamp < cutoffTime then
                    table.remove(memory.interactions, i)
                else
                    i = i + 1
                end
            end
        end

        self:UpdateRelationship(player, npcId)
    end
end

--[[ Emotion Functions ]]
function MemoryService:UpdateEmotion(player, npcId, emotionName, intensity)
    local memory = self:GetMemory(player, npcId)
    if not memory then return false end

    emotionName = string.upper(emotionName)
    if not Modules.Stat.Templates[emotionName] then return false end

    memory.interactions = memory.interactions or {}
    table.insert(memory.interactions, {
        type = emotionName,
        intensity = intensity,
        timestamp = os.time()
    })

    Services.Stat:ModifyStat(player, emotionName, {
        operation = "add",
        value = intensity,
        metadata = {
            player = player,
            npcId = npcId,
            source = "interaction"
        }
    })

    if emotionName ~= "TRUST" then
        local trustImpact = 0

        if emotionName == "BETRAYAL" then
            trustImpact = -1
        elseif emotionName == "ANGER" then
            trustImpact = -0.75
        elseif emotionName == "FEAR" or emotionName == "DISGUST" then
            trustImpact = -0.5
        elseif emotionName == "DISAPPOINTMENT" then
            trustImpact = -0.25
        elseif emotionName == "JOY" or emotionName == "GRATITUDE" then
            trustImpact = 0.75
        elseif emotionName == "ADMIRATION" or emotionName == "RESPECT" then
            trustImpact = 0.5
        end

        Services.Stat:ModifyStat(player, "TRUST", {
            operation = "add",
            value = trustImpact * intensity / 10,
            metadata = {
                player = player,
                npcId = npcId,
                source = "emotion_impact",
                sourceEmotion = emotionName
            }
        })
    end

    self:UpdateRelationship(player, npcId)

    Services.Event:Fire("Memory.Emotion", {
        player = player,
        npcId = npcId,
        emotion = emotionName,
        intensity = intensity,
        currentValue = Services.Stat:GetStat(player, emotionName, {player = player, npcId = npcId}) or 0
    })

    return true
end

--[[ Reputation Functions ]]
function MemoryService:UpdateReputation(player, factionOrNpcId, value)
    if not player then return false end

    Services.Stat:ModifyStat(player, "REPUTATION", {
        operation = "add",
        value = value,
        metadata = {
            player = player,
            factionOrNpcId = factionOrNpcId,
            source = "interaction"
        }
    })

    local currentReputation = Services.Stat:GetStat(player, "REPUTATION") or 0

    local personData = Services.Object and Services.Object:GetInstance(factionOrNpcId)
    if personData then
        local memory = self:GetMemory(player, factionOrNpcId)
        if memory then
            memory.reputation = (memory.reputation or 0) + value
            self:UpdateRelationship(player, factionOrNpcId)
        end
    end

    Services.Event:Fire("Memory.Reputation", {
        player = player,
        factionOrNpcId = factionOrNpcId,
        change = value,
        currentValue = currentReputation
    })

    return true
end

function MemoryService:GetReputation(player, factionOrNpcId)
    if not player then return 0 end

    local reputation = Services.Stat:GetStat(player, "REPUTATION", {
        player = player,
        factionOrNpcId = factionOrNpcId
    }) or 0

    return reputation
end

function MemoryService:GetReputationLevel(player, factionOrNpcId)
    local reputation = self:GetReputation(player, factionOrNpcId)

    local reputationTemplate = Modules.Stat.Templates.REPUTATION
    local thresholds = reputationTemplate and reputationTemplate.metadata and 
                      reputationTemplate.metadata.reputationThresholds or {
        INFAMOUS = -80,
        NOTORIOUS = -50,
        SUSPICIOUS = -20,
        NEUTRAL = 0,
        RESPECTED = 20,
        RENOWNED = 50,
        LEGENDARY = 80
    }

    local level = "NEUTRAL"
    for levelName, threshold in pairs(thresholds) do
        if reputation >= threshold then
            level = levelName
        end
    end

    return level
end

--[[ Relationship Functions ]]
function MemoryService:UpdateRelationship(player, npcId)
    local memory = self:GetMemory(player, npcId)
    local relationship = self:GetRelationship(player, npcId)
    if not (memory and relationship) then return end

    local trust = Services.Stat:GetStat(player, "TRUST", {player = player, npcId = npcId}) or 0
    local reputation = self:GetReputation(player, npcId)

    relationship.trust = trust
    relationship.reputation = reputation

    local oldMood = relationship.mood
    local newMood = "NEUTRAL"

    local trustTemplate = Modules.Stat.Templates.TRUST
    local moodThresholds = trustTemplate and trustTemplate.metadata and trustTemplate.metadata.moodThresholds or {
        HOSTILE = -50,
        SUSPICIOUS = -20,
        NEUTRAL = 0,
        FRIENDLY = 30,
        TRUSTED = 70
    }

    for mood, threshold in pairs(moodThresholds) do
        if trust >= threshold then
            newMood = mood
        end
    end

    if oldMood ~= newMood then
        relationship.mood = newMood
        relationship.lastInteraction = os.time()

        Services.Event:Fire("Memory.Relationship", {
            player = player,
            npcId = npcId,
            trust = trust,
            reputation = reputation,
            oldMood = oldMood,
            newMood = newMood
        })
    end
end

--[[ Getter Functions ]]
function MemoryService:GetMemory(player, npcId)
    if not (player and npcId) then return nil end

    local playerData = Services.Data:GetPlayerData(player)
    if not playerData then return nil end

    playerData.memory = playerData.memory or {}
    playerData.memory[npcId] = playerData.memory[npcId] or {
        emotionalStates = {},
        interactions = {},
        apologies = {},
        reputation = 0
    }

    return playerData.memory[npcId]
end

function MemoryService:GetRelationship(player, npcId)
    if not (player and npcId) then return nil end

    local playerData = Services.Data:GetData(player)
    if not playerData then return nil end

    playerData.relationships = playerData.relationships or {}
    playerData.relationships[npcId] = playerData.relationships[npcId] or {
        trust = 0,
        mood = "NEUTRAL",
        lastInteraction = os.time(),
        reputation = 0
    }

    local trust = Services.Stat:GetStat(player, "TRUST", {player = player, npcId = npcId})
    if trust ~= nil then
        playerData.relationships[npcId].trust = trust
    end

    local reputation = self:GetReputation(player, npcId)
    playerData.relationships[npcId].reputation = reputation

    return playerData.relationships[npcId]
end

function MemoryService:GetGreeting(player, npcId)
    local relationship = self:GetRelationship(player, npcId)
    if not relationship then return "Hello." end

    local personData = Services.Object:GetInstance(npcId)
    if not personData then return "Hello." end

    local personType = personData:GetAttribute("TYPE") or "VILLAGER"
    local personVariant = personData:GetAttribute("VARIANT")

    local moodType = (relationship.mood == "FRIENDLY" or relationship.mood == "TRUSTED") and "friendly" or "hostile"
    if relationship.mood == "NEUTRAL" then
        moodType = math.random() > 0.5 and "friendly" or "hostile"
    end

    local greetings = Modules.Person.GetDialogue(personType, personVariant, "greeting", moodType)
    local greeting = greetings and greetings[math.random(#greetings)] or "Hello."

    relationship.lastInteraction = os.time()

    return greeting
end

return MemoryService