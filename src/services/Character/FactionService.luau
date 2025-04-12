--[[ FactionService
    Handles faction relationships, diplomacy, and conflict resolution between factions.
    Supports mediation, negotiation, and diplomatic actions between factions.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local FactionService = {}

FactionService.Dependencies = {
    "Data",
    "Event",
    "Stat",
    "Inventory",
    "World",
    "Economy"
}

FactionService.Modules = {
    "Dialogue",
    "Faction"
}

FactionService.Events = {
    Join = { validate = true },
    Left = { validate = true },
    Relationship = { validate = true },
    Rank = { validate = true },
    Conflict = { validate = true },
    Diplomacy = { validate = true }
}

local Services
local Modules
local HttpService = game:GetService("HttpService")

local State = {
    factionData = nil,
    playerStandings = {}
}

FactionService.ViolationTypes = {
    DISRESPECT = "DISRESPECT",
    ASSIST_RIVALS = "ASSIST_RIVALS",
    ATTACK_ALLIES = "ATTACK_ALLIES",
    DISRUPT_MISSIONS = "DISRUPT_MISSIONS",
    STEAL_RESOURCES = "STEAL_RESOURCES"
}

--[[ Helper Functions ]]
local function ValidateData()
    if not State.factionData then
        State.factionData = Services.Data:GetGlobal(Services.Data.GLOBAL_KEYS.FACTION_DATA)
    end
    return State.factionData
end

local function SaveData(forced)
    if forced then
        local factionData = State.factionData
        if factionData then
            factionData.lastUpdate = os.time()
            Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.FACTION_DATA, factionData)
            Services.Data:SaveGlobal(Services.Data.GLOBAL_KEYS.FACTION_DATA)
        end
    end
end

--[[ Listeners ]]
FactionService.Listeners = {
    ["Data.Init"] = function(self, data)
        local player = data.player
        if not player then return end

        local userId = tostring(player.UserId)
        local playerData = data.data and data.data.PlayerData

        State.playerStandings[userId] = {}

        if playerData then
            if playerData.factions then
                for factionId, factionData in pairs(playerData.factions) do
                    State.playerStandings[userId][factionId] = table.clone(factionData)
                end
            end

            if playerData.primaryFaction and not State.playerStandings[userId][playerData.primaryFaction] then
                State.playerStandings[userId][playerData.primaryFaction] = {
                    standing = 0,
                    reputation = 0,
                    rank = "NEUTRAL",
                    lastInteraction = os.time()
                }
            end
        end

        ValidateData()
    end,

    ["Data.Global"] = function(self, data)
        if data.key == Services.Data.GLOBAL_KEYS.FACTION_DATA then
            local incomingData = data.data
            if incomingData and incomingData.lastUpdate and
               (not State.factionData or not State.factionData.lastUpdate or
                incomingData.lastUpdate > State.factionData.lastUpdate) then
                State.factionData = incomingData
            end
        end
    end
}

--[[ Core Functions ]]
function FactionService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function FactionService:Start()
    ValidateData()
    self:CheckConflicts()
    self:InitializeFactions()

    task.spawn(function()
        while true do
            task.wait(3600)
            local factionDataBefore = State.factionData and HttpService:JSONEncode(State.factionData) or "{}"

            State.factionData = Services.Data:GetGlobal(Services.Data.GLOBAL_KEYS.FACTION_DATA, true)

            local hadChanges = self:UpdateRelationships()
            hadChanges = self:CheckConflicts() or hadChanges
            local factionDataAfter = State.factionData and HttpService:JSONEncode(State.factionData) or "{}"

            if hadChanges or factionDataBefore ~= factionDataAfter then
                SaveData(true)
            end
        end
    end)

    return true
end

--[[ Faction Functions ]]
function FactionService:InitializeFactions()
    local factionData = ValidateData()
    if not factionData or not factionData.factions or next(factionData.factions) == nil then
        local defaultConfig = Modules.Faction.Templates.Default()
        Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.FACTION_DATA, defaultConfig)
        State.factionData = defaultConfig
        SaveData(true)
    end
end

function FactionService:GetFaction(factionId)
    local factionData = ValidateData()
    if not factionData or not factionData.factions then return nil end
    return factionData.factions[factionId]
end

function FactionService:GetFactions()
    local factionData = ValidateData()
    return factionData and factionData.factions or {}
end

function FactionService:GetPlayer(player)
    if not player then return nil end
    local userId = tostring(player.UserId)

    for cachedFactionId, factionData in pairs(State.playerStandings[userId] or {}) do
        if factionData.isPrimary then
            return cachedFactionId
        end
    end

    return nil
end

function FactionService:GetRelationship(factionId1, factionId2)
    local faction1 = self:GetFaction(factionId1)
    if not faction1 then return nil end

    faction1.relationships = faction1.relationships or {}
    faction1.relationships[factionId2] = faction1.relationships[factionId2] or {
        value = 0,
        state = "NEUTRAL",
        lastUpdate = os.time()
    }

    return faction1.relationships[factionId2]
end

function FactionService:GetState(value)
    local state = "NEUTRAL"
    local highestThreshold = -math.huge

    for stateName, stateData in pairs(self.RelationshipStates) do
        if stateData.threshold <= value and stateData.threshold > highestThreshold then
            state = stateName
            highestThreshold = stateData.threshold
        end
    end

    return state
end

function FactionService:UpdateRelationship(factionId1, factionId2, change)
    local relationship = self:GetRelationship(factionId1, factionId2)
    if not relationship then return false end

    local oldValue = relationship.value
    local oldState = relationship.state

    relationship.value = math.clamp(relationship.value + change, -10000, 10000)
    relationship.state = Modules.Faction.GetState(relationship.value)
    relationship.lastUpdate = os.time()

    local oppositeRelationship = self:GetRelationship(factionId2, factionId1)
    if oppositeRelationship then
        oppositeRelationship.value = relationship.value
        oppositeRelationship.state = relationship.state
        oppositeRelationship.lastUpdate = os.time()
    end

    if oldState ~= relationship.state then
        Services.Event:Fire("Faction.Relationship", {
            faction1 = factionId1,
            faction2 = factionId2,
            oldValue = oldValue,
            newValue = relationship.value,
            oldState = oldState,
            newState = relationship.state
        })

        SaveData(true)
    end

    return true
end

function FactionService:UpdateRelationships()
    local factions = self:GetFactions()
    local changesMade = false

    for factionId1, faction1 in pairs(factions) do
        for factionId2, relationship in pairs(faction1.relationships or {}) do
            if relationship.state == "WAR" then
                local warDuration = os.time() - (relationship.conflictStart or relationship.lastUpdate)
                local warDays = math.floor(warDuration / 86400)

                if warDays >= 30 then
                    if math.random() < 0.2 then
                        if self:UpdateRelationship(factionId1, factionId2, 500) then
                           changesMade = true
                        end
                    end

                    if self:ApplyWar(factionId1, warDays) then
                       changesMade = true
                    end
                    if self:ApplyWar(factionId2, warDays) then
                       changesMade = true
                    end
                end
            elseif relationship.state == "ALLIANCE" then
                local allianceDuration = os.time() - (relationship.allianceStart or relationship.lastUpdate)
                local allianceDays = math.floor(allianceDuration / 86400)

                if allianceDays >= 30 and math.random() < 0.3 then
                    if self:UpdateRelationship(factionId1, factionId2, 200) then
                       changesMade = true
                    end
                end
            end
        end
    end
    return changesMade
end

function FactionService:ApplyWar(factionId, warDays)
    local faction = self:GetFaction(factionId)
    if not faction then return false end

    local changesMade = false

    faction.resources = faction.resources or {}
    faction.population = faction.population or 1000

    for resource, amount in pairs(faction.resources) do
        local newAmount = math.max(0, amount - (amount * 0.05 * (warDays / 30)))
        if newAmount ~= amount then
           faction.resources[resource] = newAmount
           changesMade = true
        end
    end

    local populationLoss = math.min(faction.population * 0.02, faction.population * (warDays / 150))
    local newPopulation = math.max(100, faction.population - populationLoss)
    if newPopulation ~= faction.population then
       faction.population = newPopulation
       changesMade = true
    end

    if faction.territories then
        for territory, control in pairs(faction.territories) do
            if math.random() < 0.1 * (warDays / 30) then
                local newControl = math.max(0, control - 0.1)
                if newControl ~= control then
                   faction.territories[territory] = newControl
                   changesMade = true
                end
            end
        end
    end

    if warDays % 7 == 0 then
        for _, memberId in ipairs(faction.members or {}) do
            local player = game.Players:GetPlayerByUserId(tonumber(memberId))
            if player then
                Services.Inventory:AddItem(player, "WAR_RATIONS", 3)
                Services.Inventory:AddItem(player, "BANDAGES", 2)

                if math.random() < 0.3 then
                    local items = {"SHARPENING_STONE", "ARMOR_PATCH", "COMBAT_TONIC"}
                    local randomItem = items[math.random(#items)]
                    Services.Inventory:AddItem(player, randomItem, 1)
                end
            end
        end
    end

    return changesMade
end

--[[ Player Functions ]]
function FactionService:GetStanding(player, factionId)
    if not player then return nil end
    local userId = tostring(player.UserId)

    if State.playerStandings[userId] and State.playerStandings[userId][factionId] then
        return State.playerStandings[userId][factionId]
    end

    State.playerStandings[userId] = State.playerStandings[userId] or {}
    State.playerStandings[userId][factionId] = table.clone(Modules.Data.Templates.PlayerFactionStanding)
    State.playerStandings[userId][factionId].lastInteraction = os.time()

    return State.playerStandings[userId][factionId]
end

function FactionService:JoinFaction(player, factionId)
    if not player or not factionId then return false, "Invalid player or faction" end

    local faction = self:GetFaction(factionId)
    if not faction then return false, "Faction not found" end

    local userId = tostring(player.UserId)

    local primaryFactionId = nil
    for cachedFactionId, _ in pairs(State.playerStandings[userId] or {}) do
        if State.playerStandings[userId][cachedFactionId].isPrimary then
            primaryFactionId = cachedFactionId
            break
        end
    end

    if primaryFactionId and primaryFactionId ~= factionId then
        local playerLevel = player:GetAttribute("LEVEL") or 1
        if playerLevel < 40 and not Services.Inventory:GetItem(player, "SIGIL_OF_SEVERANCE") then
            return false, "You must be level 40 or have a Sigil of Severance to change factions"
        end

        local previousFaction = primaryFactionId
        local factionItems = {
            [Modules.Faction.FACTION_IDS.UMBRAL_PACT] = "UMBRAL_CLOAK",
            [Modules.Faction.FACTION_IDS.DAWNWARDENS] = "DAWN_CLOAK",
            [Modules.Faction.FACTION_IDS.SHATTERED_FANG] = "FANG_CLOAK"
        }

        local previousItem = factionItems[previousFaction]
        if previousItem then
            Services.Inventory:RemoveItem(player, previousItem)
        end

        if State.playerStandings[userId][previousFaction] then
            State.playerStandings[userId][previousFaction].standing = -1000
            State.playerStandings[userId][previousFaction].reputation = 0
            State.playerStandings[userId][previousFaction].rank = "TRAITOR"
            State.playerStandings[userId][previousFaction].lastInteraction = os.time()
            State.playerStandings[userId][previousFaction].isPrimary = false
        end
    end

    State.playerStandings[userId] = State.playerStandings[userId] or {}
    if not State.playerStandings[userId][factionId] then
        State.playerStandings[userId][factionId] = {
            standing = 500,
            reputation = 0,
            rank = "INITIATE",
            lastInteraction = os.time(),
            isPrimary = true
        }
    else
        State.playerStandings[userId][factionId].standing = math.max(500, State.playerStandings[userId][factionId].standing)
        State.playerStandings[userId][factionId].rank = "INITIATE"
        State.playerStandings[userId][factionId].isPrimary = true
    end

    faction.members = faction.members or {}
    if not table.find(faction.members, userId) then
        table.insert(faction.members, userId)
        SaveData(true)
    end

    Services.Data:SetData(userId, "PlayerData", {
        primaryFaction = factionId,
        factions = State.playerStandings[userId]
    })

    local factionItems = {
        [Modules.Faction.FACTION_IDS.UMBRAL_PACT] = {
            ["UMBRAL_CLOAK"] = 1,
            ["BLOOD_ESSENCE"] = 3
        },
        [Modules.Faction.FACTION_IDS.DAWNWARDENS] = {
            ["DAWN_CLOAK"] = 1,
            ["LIGHT_CRYSTAL"] = 3
        },
        [Modules.Faction.FACTION_IDS.SHATTERED_FANG] = {
            ["FANG_CLOAK"] = 1,
            ["SURVIVAL_KIT"] = 3
        }
    }

    local items = factionItems[factionId] or {}
    for itemId, quantity in pairs(items) do
        Services.Inventory:AddItem(player, itemId, quantity)
    end

    SaveData()

    Services.Event:Fire("Faction.Join", {
        player = player,
        faction = factionId,
        isNew = not table.find(faction.members, userId),
        standing = State.playerStandings[userId][factionId].standing,
        rank = State.playerStandings[userId][factionId].rank
    })

    return true, {
        standing = State.playerStandings[userId][factionId].standing,
        rank = State.playerStandings[userId][factionId].rank,
        items = items
    }
end

function FactionService:LeaveFaction(player, factionId)
    if not player then return false, "Invalid player" end

    local userId = tostring(player.UserId)

    local leavingFactionId = factionId
    if not leavingFactionId then
        for cachedFactionId, factionData in pairs(State.playerStandings[userId] or {}) do
            if factionData.isPrimary then
                leavingFactionId = cachedFactionId
                break
            end
        end
    end

    if not leavingFactionId then
        return false, "Player is not in a faction"
    end

    local faction = self:GetFaction(leavingFactionId)
    if not faction then return false, "Faction not found" end

    local playerLevel = player:GetAttribute("LEVEL") or 1
    if playerLevel < 40 and not Services.Inventory:GetItem(player, "SIGIL_OF_SEVERANCE") then
        return false, "You must be level 40 or have a Sigil of Severance to leave your faction"
    end

    if playerLevel < 40 then
        local success = Services.Inventory:RemoveItem(player, "SIGIL_OF_SEVERANCE", 1)
        if not success then
            return false, "Failed to use Sigil of Severance"
        end
    end

    local factionItems = {
        [Modules.Faction.FACTION_IDS.UMBRAL_PACT] = {"UMBRAL_CLOAK", "BLOOD_ESSENCE"},
        [Modules.Faction.FACTION_IDS.DAWNWARDENS] = {"DAWN_CLOAK", "LIGHT_CRYSTAL"},
        [Modules.Faction.FACTION_IDS.SHATTERED_FANG] = {"FANG_CLOAK", "SURVIVAL_KIT"}
    }

    if factionItems[leavingFactionId] then
        for _, itemId in ipairs(factionItems[leavingFactionId]) do
            Services.Inventory:RemoveItem(player, itemId)
        end
    end

    if faction.members then
        local foundMember = false
        for i, memberId in ipairs(faction.members) do
            if memberId == userId then
                table.remove(faction.members, i)
                foundMember = true
                break
            end
        end

        if foundMember then
            SaveData(true)
        end
    end

    Services.Data:SetData(userId, "PlayerData", {
        primaryFaction = nil,
        factions = State.playerStandings[userId] or {}
    })

    SaveData()

    local standingValue = State.playerStandings[userId] and 
                         State.playerStandings[userId][leavingFactionId] and
                         State.playerStandings[userId][leavingFactionId].standing or -2000

    Services.Event:Fire("Faction.Left", {
        player = player,
        faction = leavingFactionId,
        reason = "voluntary",
        standing = standingValue
    })

    return true, {
        factionId = leavingFactionId,
        message = "You have left " .. (faction.name or "your faction") .. "."
    }
end

function FactionService:RecordViolation(userId, violationType, source, details)
    assert(type(userId) == "number", "UserId must be a number")
    assert(type(violationType) == "string", "ViolationType must be a string")

    local player = game.Players:GetPlayerByUserId(userId)
    local userIdStr = tostring(userId)

    if not State.playerStandings[userIdStr] then
        return false
    end

    State.violations = State.violations or {}
    State.violations[userIdStr] = State.violations[userIdStr] or {}

    table.insert(State.violations[userIdStr], {
        type = violationType,
        timestamp = os.time(),
        source = source or "SYSTEM",
        details = details or {}
    })

    Services.Data:SetData(userIdStr, "PlayerData", {
        factionViolations = State.violations[userIdStr]
    })

    return true
end

function FactionService:CheckViolations(userId, violationType, count, timeframeInDays)
    assert(type(userId) == "number", "UserId must be a number")

    local userIdStr = tostring(userId)

    State.violations = State.violations or {}
    local playerViolations = State.violations[userIdStr]

    if not playerViolations then
        return false
    end

    count = count or 3
    timeframeInDays = timeframeInDays or 7
    local currentTime = os.time()
    local timeframeInSeconds = timeframeInDays * 86400

    local recentViolations = 0

    for _, violation in ipairs(playerViolations) do
        if (not violationType or violation.type == violationType) and 
           (currentTime - violation.timestamp) <= timeframeInSeconds then
            recentViolations = recentViolations + 1
        end
    end

    return recentViolations >= count
end

function FactionService:ExpelMember(targetUserId, factionId, reason, reasonCode)
    if not targetUserId or not factionId then
        return false, "Missing required parameters"
    end

    local faction = self:GetFaction(factionId)
    if not faction then return false, "Faction not found" end

    local targetPlayer = game.Players:GetPlayerByUserId(tonumber(targetUserId))
    if not State.playerStandings[targetUserId] then
        return false, "Target player data not found"
    end

    local primaryFactionId = nil
    for cachedFactionId, factionData in pairs(State.playerStandings[targetUserId]) do
        if factionData.isPrimary then
            primaryFactionId = cachedFactionId
            break
        end
    end

    if not primaryFactionId or primaryFactionId ~= factionId then
        return false, "Target player is not a member of this faction"
    end

    local validReasonCodes = {
        ASSIST_RIVALS = "Assisting rival factions",
        ATTACK_ALLIES = "Attacking faction allies",
        DISRUPT_MISSIONS = "Disrupting faction missions",
        STEAL_RESOURCES = "Stealing faction resources",
        DISRESPECT = "Disrespecting faction leaders"
    }

    local expulsionReason = reason
    local expulsionReasonCode = reasonCode
    if reasonCode and validReasonCodes[reasonCode] then
        if not reason or reason == "" then
            expulsionReason = validReasonCodes[reasonCode]
        end
    else
        expulsionReasonCode = "FACTION_VIOLATION"
    end

    if faction.members then
        local foundMember = false
        for i, memberId in ipairs(faction.members) do
            if memberId == targetUserId then
                table.remove(faction.members, i)
                foundMember = true
                break
            end
        end

        if foundMember then
            SaveData(true)
        end
    end

    if State.playerStandings[targetUserId] and State.playerStandings[targetUserId][factionId] then
        State.playerStandings[targetUserId][factionId].standing = -5000
        State.playerStandings[targetUserId][factionId].rank = "EXPELLED"
        State.playerStandings[targetUserId][factionId].lastInteraction = os.time()
        State.playerStandings[targetUserId][factionId].expulsionReason = expulsionReasonCode
        State.playerStandings[targetUserId][factionId].isPrimary = false
    end

    Services.Data:SetData(targetUserId, "PlayerData", {
        primaryFaction = nil,
        factions = State.playerStandings[targetUserId]
    })

    SaveData()

    Services.Event:Fire("Faction.Left", {
        userId = targetUserId,
        faction = factionId,
        reason = "expelled",
        expelledBy = "NPC_LEADER",
        leaderId = faction.leaderId,
        reasonCode = expulsionReasonCode,
        message = expulsionReason or "Expelled by faction leader",
        standing = State.playerStandings[targetUserId] and
                  State.playerStandings[targetUserId][factionId] and
                  State.playerStandings[targetUserId][factionId].standing or -5000
    })

    if targetPlayer then
        Services.Event:FireTo(
            targetPlayer,
            "Notification",
            {
                type = "FACTION_EXPELLED",
                title = "Faction Expulsion",
                message = "You have been expelled from " .. (faction.name or "your faction") .. " by " .. 
                         (faction.leaderName or "the faction leader") .. ".\nReason: " .. (expulsionReason or "Violation of faction values"),
                duration = 15
            }
        )

        local factionItems = {
            [Modules.Faction.FACTION_IDS.UMBRAL_PACT] = {"UMBRAL_CLOAK", "BLOOD_ESSENCE"},
            [Modules.Faction.FACTION_IDS.DAWNWARDENS] = {"DAWN_CLOAK", "LIGHT_CRYSTAL"},
            [Modules.Faction.FACTION_IDS.SHATTERED_FANG] = {"FANG_CLOAK", "SURVIVAL_KIT"}
        }

        if factionItems[factionId] then
            for _, itemId in ipairs(factionItems[factionId]) do
                Services.Inventory:RemoveItem(targetPlayer, itemId)
            end
        end
    end

    return true, {
        factionId = factionId,
        targetId = targetUserId,
        reasonCode = expulsionReasonCode,
        message = "Player has been expelled from the faction by the faction leader"
    }
end

function FactionService:UpdateStanding(player, factionId, change)
    local standing = self:GetStanding(player, factionId)
    if not standing then return false end

    local oldStanding = standing.standing
    standing.standing = math.clamp(standing.standing + change, -10000, 10000)
    standing.lastInteraction = os.time()

    local oldRank = standing.rank
    standing.rank = Modules.Faction.GetState(standing.standing)

    local userId = tostring(player.UserId)
    if State.playerStandings[userId] and State.playerStandings[userId][factionId] then
        State.playerStandings[userId][factionId] = standing
    end

    Services.Data:SetData(userId, "PlayerData", {
        factions = State.playerStandings[userId] or {}
    })

    if oldRank ~= standing.rank then
        Services.Event:Fire("Faction.Rank", {
            player = player,
            faction = factionId,
            oldStanding = oldStanding,
            newStanding = standing.standing,
            oldRank = oldRank,
            newRank = standing.rank
        })
    end

    return true
end

--[[ Conflict Functions ]]
function FactionService:GetConflicts()
    local factionData = ValidateData()
    return factionData and factionData.conflicts or {}
end

function FactionService:GetConflict(conflictId)
    if not conflictId then return nil end

    local conflicts = self:GetConflicts()

    for _, conflict in ipairs(conflicts) do
        if conflict.id == conflictId then
            return conflict
        end
    end

    return nil
end

function FactionService:GetFactionConflicts(factionId1, factionId2)
    local conflicts = self:GetConflicts()

    for _, conflict in ipairs(conflicts) do
        if (conflict.factions[1] == factionId1 and conflict.factions[2] == factionId2) or
           (conflict.factions[1] == factionId2 and conflict.factions[2] == factionId1) then
            return conflict
        end
    end

    return nil
end

function FactionService:CheckConflicts()
    local factionData = ValidateData()
    if not factionData then return {} end

    local conflicts = {}
    local factions = factionData.factions or {}
    local hasChanges = false

    for factionId1, faction1 in pairs(factions) do
        for factionId2, relationship in pairs(faction1.relationships or {}) do
            if relationship.state == "WAR" or relationship.state == "HOSTILE" then
                local conflictId = factionId1 .. "_vs_" .. factionId2

                local existingConflict = nil
                for _, conflict in ipairs(factionData.conflicts or {}) do
                    if conflict.id == conflictId or
                       (conflict.factions[1] == factionId1 and conflict.factions[2] == factionId2) or
                       (conflict.factions[1] == factionId2 and conflict.factions[2] == factionId1) then
                        existingConflict = conflict
                        break
                    end
                end

                if existingConflict then
                    if existingConflict.relationship ~= relationship or
                       existingConflict.intensity ~= (relationship.state == "WAR" and 2 or 1) then
                        existingConflict.relationship = relationship
                        existingConflict.intensity = relationship.state == "WAR" and 2 or 1
                        hasChanges = true
                    end
                    table.insert(conflicts, existingConflict)
                else
                    local newConflict = {
                        id = conflictId,
                        factions = {factionId1, factionId2},
                        relationship = relationship,
                        intensity = relationship.state == "WAR" and 2 or 1,
                        cause = "Territorial dispute",
                        startDate = relationship.conflictStart or os.time()
                    }
                    table.insert(conflicts, newConflict)
                    hasChanges = true
                end
            end
        end
    end

    local currentConflictsCount = #(factionData.conflicts or {})
    local newConflictsCount = #conflicts

    if currentConflictsCount ~= newConflictsCount then
        hasChanges = true
    end

    if hasChanges then
        factionData.conflicts = conflicts
        SaveData(true)
    end

    return conflicts
end

function FactionService:ResolveConflict(conflictId, resolution)
    local conflict = self:GetConflict(conflictId)
    if not conflict then return false end

    local factionId1 = conflict.factions[1]
    local factionId2 = conflict.factions[2]
    local factionData = ValidateData()

    if not factionData or not factionData.conflicts then return false end

    local found = false
    for i, c in ipairs(factionData.conflicts) do
        if c.id == conflictId then
            table.remove(factionData.conflicts, i)
            found = true
            break
        end
    end

    if found then
        if Services.World then
            Services.World:SetState("resolved_conflict_" .. conflictId, {
                resolution = resolution,
                factions = {factionId1, factionId2},
                date = os.time()
            })
        end

        Services.Event:Fire("Faction.Conflict", {
            conflictId = conflictId,
            factions = {factionId1, factionId2},
            resolution = resolution
        })

        SaveData(true)
        return true
    end

    return false
end

--[[ Diplomacy Functions ]]
function FactionService:GetDiplomacy(player, conflict)
    local options = {}
    local faction1 = conflict.factions[1]
    local faction2 = conflict.factions[2]

    local playerStanding1 = self:GetStanding(player, faction1)
    local playerStanding2 = self:GetStanding(player, faction2)

    for optionId, optionData in pairs(Modules.Faction.DiplomaticOptions) do
        local available = true
        local requirements = optionData.requirements or {}

        if requirements.minReputation then
            if not (playerStanding1 and playerStanding1.reputation >= requirements.minReputation and
                   playerStanding2 and playerStanding2.reputation >= requirements.minReputation) then
                available = false
            end
        end

        if requirements.minRelationship then
            if not (playerStanding1 and playerStanding1.standing >= requirements.minRelationship and
                   playerStanding2 and playerStanding2.standing >= requirements.minRelationship) then
                available = false
            end
        end

        if requirements.minStat then
            for statName, minValue in pairs(requirements.minStat) do
                local stat = Services.Stat:GetStat(player, string.upper(statName))
                if not stat or stat < minValue then
                    available = false
                    break
                end
            end
        end

        if requirements.minUmbrels then
            local umbrels = Services.Economy:GetBalance(tostring(player.UserId)) or 0
            if umbrels < requirements.minUmbrels then
                available = false
            end
        end

        if available then
            table.insert(options, {
                id = optionId,
                name = optionId:sub(1, 1) .. optionId:sub(2):lower(),
                description = optionData.description,
                icon = optionData.icon,
                color = optionData.color
            })
        end
    end

    return options
end

function FactionService:AttemptDiplomacy(player, conflict, optionId)
    if not conflict or not optionId then return false, "Invalid conflict or diplomatic option" end

    local faction1 = conflict.factions[1]
    local faction2 = conflict.factions[2]
    local optionData = Modules.Faction.DiplomaticOptions[optionId]
    local outcomeData = Modules.Faction.NegotiationOutcomes[optionId]

    if not (optionData and outcomeData) then 
        return false, "Invalid diplomatic approach"
    end

    local options = self:GetDiplomacy(player, conflict)
    local optionAvailable = false

    for _, option in ipairs(options) do
        if option.id == optionId then
            optionAvailable = true
            break
        end
    end

    if not optionAvailable then
        return false, "Requirements not met for this diplomatic approach"
    end

    if optionId == "BRIBE" and optionData.requirements.minUmbrels then
        Services.Economy:RemoveCurrency(tostring(player.UserId), optionData.requirements.minUmbrels, {
            type = "faction_diplomacy",
            faction1 = faction1,
            faction2 = faction2,
            optionId = optionId
        })
    end

    local roll = math.random()
    local outcome = nil
    local cumulativeChance = 0

    for outcomeName, outcomeInfo in pairs(outcomeData) do
        cumulativeChance = cumulativeChance + (outcomeInfo.chance or 0)
        if roll <= cumulativeChance then
            outcome = outcomeName
            break
        end
    end

    if not outcome then
        outcome = next(outcomeData)
    end

    local result = outcomeData[outcome]

    if result.factionRelationshipChange then
        local scaledChange = result.factionRelationshipChange * 20
        self:UpdateRelationship(faction1, faction2, scaledChange)
    end

    if result.reputationGain then
        local scaledGain = result.reputationGain * 20
        self:UpdateStanding(player, faction1, scaledGain)
        self:UpdateStanding(player, faction2, scaledGain)
    elseif result.reputationLoss then
        local scaledLoss = result.reputationLoss * 20
        self:UpdateStanding(player, faction1, scaledLoss)
        self:UpdateStanding(player, faction2, scaledLoss)
    end

    if optionId == "BRIBE" and outcome == "FAILURE" and result.umbrelsReturn then
        local refundAmount = math.floor(optionData.requirements.minUmbrels * result.umbrelsReturn)
        Services.Economy:AddCurrency(tostring(player.UserId), refundAmount, {
            type = "faction_diplomacy_refund",
            faction1 = faction1,
            faction2 = faction2,
            optionId = optionId,
            outcome = outcome
        })
    end

    local relationship = self:GetRelationship(faction1, faction2)
    if relationship and relationship.state ~= "WAR" and relationship.state ~= "HOSTILE" then
        self:ResolveConflict(conflict.id, "PEACEFUL")
        self:CheckConflicts()
    end

    Services.Event:Fire("Faction.Diplomacy", {
        player = player,
        faction1 = faction1,
        faction2 = faction2,
        approach = optionId,
        outcome = outcome,
        relationship = relationship and relationship.value or 0,
        state = relationship and relationship.state or "NEUTRAL"
    })

    local faction1Data = self:GetFaction(faction1)
    local faction2Data = self:GetFaction(faction2)
    local faction1Name = faction1Data and faction1Data.name or faction1
    local faction2Name = faction2Data and faction2Data.name or faction2

    local message = result.message or "Your diplomatic efforts had an effect."

    return true, {
        success = outcome == "SUCCESS",
        outcome = outcome,
        relationship = relationship and relationship.state or "NEUTRAL",
        message = message
    }
end

--[[ Dialogue Functions ]]
function FactionService:GetDialogue(conflictId)
    local conflict = self:GetConflict(conflictId)
    if not conflict then return nil end

    local faction1Data = self:GetFaction(conflict.factions[1])
    local faction2Data = self:GetFaction(conflict.factions[2])

    if not (faction1Data and faction2Data) then return nil end

    return Modules.Dialogue.Templates.ConflictDialogue({
        id = conflict.id,
        title = faction1Data.name .. " vs " .. faction2Data.name .. " Conflict",
        speaker = "Diplomat",
        factions = {faction1Data.name, faction2Data.name},
        conflictType = conflict.conflictType,
        cause = conflict.cause
    })
end

return FactionService
