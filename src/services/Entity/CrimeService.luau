--[[ CrimeService
    Manages criminal activities including theft, bounties, and law enforcement.
    Handles detection, reputation impact, and consequences of criminal actions.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local CrimeService = {}

--[[ State ]]
local Services
local Modules
local State = {
    bounties = {}
}

--[[ Dependencies ]]
CrimeService.Dependencies = {
    "Event",
    "Memory",
    "Store",
    "Inventory",
    "Economy",
    "Object",
    "Data",
    "Location",
    "Loot",
    "Faction",
    "Time",
    "Zone"
}

--[[ Modules ]]
CrimeService.Modules = {
    "Store",
    "Location",
    "Crime"
}

--[[ Events ]]
CrimeService.Events = {
    Crime = { validate = true },
    Bounty = { validate = true },
    Arrest = { validate = true },
    Detect = { validate = true }
}

CrimeService.Listeners = {
    ["Data.Global"] = function(self, data)
        if data.key == Services.Data.GLOBAL_KEYS.CRIME_DATA then
            local incomingData = data.data
            if incomingData and incomingData.lastUpdate and incomingData.bounties then
                State.bounties = incomingData.bounties
            end
        end
    end
}

--[[ Types ]]
type TheftContext = {
    player: Player,
    targetId: string,
    itemId: string?,
    value: number?,
    isStore: boolean,
    isLocation: boolean,
    metadata: {[string]: any}?
}

type CrimeResult = {
    success: boolean,
    detected: boolean,
    loot: any?,
    value: number?,
    error: string?
}

type BountyData = {
    playerId: number,
    amount: number,
    reason: string,
    issuerId: string?,
    timestamp: number,
    expiryTime: number?
}

--[[ Core Functions ]]
function CrimeService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function CrimeService:Start()
    return true
end

--[[ Crime Functions ]]
function CrimeService:CalculateOutcome(player, crimeType, difficulty, value)
    local crimeSettings = Modules.Crime.BountyConfig[crimeType]
    if not crimeSettings then
        return false, 0, "Invalid crime type"
    end

    local playerDexterity = player:GetAttribute("DEXTERITY") or 0
    local success = math.random(1, 100) <= Modules.Crime:GetSuccess(playerDexterity, difficulty, value)
    local detected = success and (math.random(1, 100) <= Modules.Crime:GetDetection(playerDexterity, difficulty, value, "DAY", "CLEAR", "VILLAGE"))

    local baseBounty = crimeSettings.base
    local finalBounty = detected and baseBounty * (1 + (difficulty or 1) * 0.5) * (1 + (value or 0) / 1000) or 0

    return success, math.floor(finalBounty + 0.5), detected
end

function CrimeService:DetectPlayer(player, target, item, crimeType)
    if not player or not target then return end

    local entityType
    if type(target) == "table" and target.type and target.type == "LOCATION" then
        entityType = "location"
    else
        entityType = "entity"
    end

    local factionId, ownerId

    if entityType == "location" then
        factionId = target.factionId
        ownerId = target.ownerId
    else
        factionId = target:GetAttribute("FACTION")
        ownerId = target:GetAttribute("OWNER") or target:GetAttribute("ID")
    end

    if ownerId then
        Services.Memory:UpdateReputation(
            player,
            ownerId,
            Modules.Crime.ReputationImpact.THEFT_CAUGHT.INDIVIDUAL
        )
    end

    if factionId then
        Services.Memory:UpdateReputation(
            player,
            factionId,
            Modules.Crime.ReputationImpact.THEFT_CAUGHT.FACTION
        )
    end

    Services.Memory:UpdateReputation(
        player,
        "GLOBAL",
        Modules.Crime.ReputationImpact.THEFT_CAUGHT.GLOBAL
    )

    local value = item and (item.value or item.price) or Modules.Crime.BountyConfig.BASE_THEFT_BOUNTY
    local bountyAmount = value * Modules.Crime.BountyConfig.VALUE_MULTIPLIER

    crimeType = crimeType or Modules.Crime.Types.THEFT

    self:AddBounty(player, bountyAmount, crimeType, ownerId)

    local targetId
    if entityType == "location" then
        targetId = target.id
    else
        targetId = target:GetAttribute("ID")
    end

    local crimeData = {
        type = crimeType.split and crimeType:split(".")[1] or crimeType,
        subType = crimeType.split and crimeType:split(".")[2] or nil,
        playerId = player.UserId,
        targetId = targetId,
        value = value,
        timestamp = os.time(),
        detected = true
    }

    if entityType == "location" then
        crimeData.locationId = targetId
        crimeData.locationType = target.locationType
    else
        if item and item.id then
            crimeData.itemId = item.id
        end
    end

    Services.Data:AddGlobal("CrimeData", "recentCrimes", crimeData, 100)

    if entityType == "entity" and ownerId then
        Services.Event:Fire("Crime.Detect", {
            entityId = ownerId,
            playerId = player.UserId,
            reaction = "hostile"
        })
    end

    return {
        ownerId = ownerId,
        factionId = factionId,
        bountyAmount = bountyAmount
    }
end

function CrimeService:AddLoot(player, loot, contextData)
    if not player or not loot or not loot.id then return false end

    local metadata = {
        stolen = true,
        timestamp = os.time()
    }

    if contextData then
        for k, v in pairs(contextData) do
            metadata[k] = v
        end
    end

    return Services.Inventory:AddItem(player, loot.id, 1, metadata)
end

--[[ Theft Functions ]]
function CrimeService:AttemptTheft(context: TheftContext): (boolean, CrimeResult)
    if not context.player then return false, {error = "Invalid player"} end
    if not context.targetId then return false, {error = "Invalid target"} end

    if context.isStore then
        return self:AttemptShoplift(context)
    elseif context.isLocation then
        return self:AttemptBurglary(context)
    else
        return self:AttemptPickpocket(context)
    end
end

function CrimeService:AttemptShoplift(context: TheftContext): (boolean, CrimeResult)
    local player = context.player
    local storeId = context.targetId
    local itemId = context.itemId

    if not Services.Store:IsStoreOpenForPlayer(player, storeId) then
        return false, {error = "Store not open"}
    end

    local store = Services.Store:GetStore(storeId)
    if not store then return false, {error = "Store not found"} end

    local item = store.inventory[itemId]
    if not item then return false, {error = "Item not found"} end

    local outcome = self:CalculateOutcome({
        player = player,
        securityLevel = store.securityLevel or 1,
        itemValue = item.price,
        locationType = store.locationType or "VILLAGE"
    })

    if outcome.success then
        Services.Inventory:AddItem(player, item.itemId, 1, {
            stolen = true,
            storeId = storeId,
            timestamp = os.time()
        })

        Services.Store:RemoveInventory(storeId, itemId, 1)
    end

    if outcome.detected then
        local storeEntity = Services.Object:GetInstance(storeId)
        if storeEntity then
            self:DetectPlayer(player, storeEntity, item, Modules.Crime.Types.SHOPLIFT)
        end
    else
        if outcome.success then
            local storeOwnerFaction = store.factionId
            if storeOwnerFaction then
                Services.Memory:UpdateReputation(
                    player,
                    storeOwnerFaction,
                    Modules.Crime.ReputationImpact.THEFT_UNCAUGHT.FACTION
                )
            end
        end
    end

    Services.Event:Fire("Crime.Crime", {
        type = "THEFT",
        subType = "SHOPLIFT",
        player = player,
        storeId = storeId,
        itemId = itemId,
        success = outcome.success,
        detected = outcome.detected,
        value = item.price
    })

    return true, {
        success = outcome.success,
        detected = outcome.detected,
        value = item.price
    }
end

function CrimeService:AttemptPickpocket(context: TheftContext): (boolean, CrimeResult)
    local player = context.player
    local targetId = context.targetId

    local target = Services.Object:GetInstance(targetId)
    if not target then return false, {error = "Target not found"} end

    local targetType = target:GetAttribute("TYPE") or "VILLAGER"

    local securityLevel = 1
    if targetType == "GUARD" then
        securityLevel = 3
    elseif targetType == "MERCHANT" then
        securityLevel = 2
    end

    local outcome = self:CalculateOutcome({
        player = player,
        securityLevel = securityLevel,
        itemValue = 0,
        locationType = "VILLAGE"
    })

    local loot = nil
    if outcome.success then
        loot = Services.Loot:GenerateEntity(targetType, target:GetAttribute("VARIANT"))
        if loot and loot.id then
            self:AddLoot(player, loot, {
                sourceEntity = targetId
            })
        end
    end

    if outcome.detected then
        self:DetectPlayer(player, target, loot, Modules.Crime.Types.PICKPOCKET)
    else
        if outcome.success then
            local targetFaction = target:GetAttribute("FACTION")
            if targetFaction then
                Services.Memory:UpdateReputation(
                    player,
                    targetFaction,
                    Modules.Crime.ReputationImpact.THEFT_UNCAUGHT.FACTION
                )
            end
        end
    end

    Services.Event:Fire("Crime.Crime", {
        type = "THEFT",
        subType = "PICKPOCKET",
        player = player,
        targetId = targetId,
        targetType = targetType,
        success = outcome.success,
        detected = outcome.detected,
        loot = loot
    })

    return outcome.success, {
        success = outcome.success,
        detected = outcome.detected,
        loot = loot
    }
end

function CrimeService:AttemptBurglary(context: TheftContext): (boolean, CrimeResult)
    if not context.player then return false, {error = "Invalid player"} end
    local player = context.player
    local locationId = context.targetId

    local location = Services.Location:GetLocation(locationId)
    if not location then return false, {error = "Location not found"} end

    local playerZones = Services.Zone:GetZones(player)
    local isInLocation = playerZones[locationId] ~= nil

    if not isInLocation then
        return false, {error = "Player must be inside the location to commit burglary"}
    end

    local template = Modules.Location.GetLocation(location.templateId)
    if not template then return false, {error = "Invalid location template"} end

    local securityLevel = location.securityLevel or template.defaults.security or 1
    local ownerId = Services.Location:GetOwner(locationId)

    local successModifier = 0
    if location.magicalDefenses then
        successModifier -= 10
    end
    if location.trapDefenses then
        successModifier -= 10
    end

    local outcome = self:CalculateOutcome({
        player = player,
        securityLevel = securityLevel,
        itemValue = 0,
        successModifier = successModifier
    })

    local locationWrapper = {
        id = locationId,
        type = "LOCATION",
        templateId = location.templateId,
        locationType = location.locationType or template.defaults.location_type,
        securityLevel = securityLevel,
        factionId = location.factionId,
        ownerId = ownerId
    }

    if outcome.detected then
        self:DetectPlayer(player, locationWrapper, {value = Modules.Crime.BountyConfig.BASE_BURGLARY_BOUNTY}, Modules.Crime.Types.BURGLARY)
    end

    Services.Event:Fire("Crime.Crime", {
        type = "BURGLARY",
        player = player,
        locationId = locationId,
        locationType = template.defaults.location_type,
        locationSubType = location.templateId,
        success = outcome.success,
        detected = outcome.detected
    })

    return true, {
        success = outcome.success,
        detected = outcome.detected
    }
end

function CrimeService:AttemptTrespass(player, locationId): (boolean, CrimeResult)
    if not player or not locationId then return false, {error = "Invalid parameters"} end

    local location = Services.Location:GetLocation(locationId)
    if not location then return false, {error = "Location not found"} end

    if not location.isLocked then
        return false, {error = "Location is not locked, not trespassing"}
    end

    local playerDexterity = player:GetAttribute("DEXTERITY") or 0
    local lockLevel = location.lockLevel or 1
    local securityLevel = location.securityLevel or 1

    local baseChance = 20
    local dexterityBonus = playerDexterity * 7
    local lockPenalty = lockLevel * 15

    local specialDefensePenalty = 0
    if location.magicalDefenses then
        specialDefensePenalty = specialDefensePenalty + 20
    end
    if location.trapDefenses then
        specialDefensePenalty = specialDefensePenalty + 15
    end

    local successChance = math.clamp(
        baseChance + dexterityBonus - lockPenalty - specialDefensePenalty,
        5,
        90
    )

    local detectionChance = Modules.Crime:GetDetection(
        playerDexterity,
        securityLevel,
        0,
        Services.Time:GetTimeOfDay(),
        nil,
        location.locationType or "VILLAGE"
    )

    local roll = math.random(1, 100)
    local success = roll <= successChance

    local detectionRoll = math.random(1, 100)
    local detected = detectionRoll <= detectionChance

    if success then
        Services.Location:LockLocation(locationId, false)
        Services.Location:EnterLocation(player, locationId)
    end

    local locationWrapper = {
        id = locationId,
        type = "LOCATION",
        locationType = location.type,
        securityLevel = securityLevel,
        factionId = location.factionId,
        ownerId = location.ownerId
    }

    if detected then
        self:DetectPlayer(player, locationWrapper, {value = Modules.Crime.BountyConfig.BASE_THEFT_BOUNTY}, Modules.Crime.Types.TRESPASSING)
    end

    Services.Event:Fire("Crime.Crime", {
        type = "TRESPASS",
        player = player,
        locationId = locationId,
        locationType = location.type,
        locationSubType = location.subType,
        success = success,
        detected = detected
    })

    return true, {
        success = success,
        detected = detected
    }
end

--[[ Bounty Functions ]]
function CrimeService:AddBounty(player, amount, reason, issuerId): (boolean, number)
    local playerId = type(player) == "number" and player or player.UserId

    amount = math.min(
        math.max(amount, Modules.Crime.BountyConfig.MIN_BOUNTY),
        Modules.Crime.BountyConfig.MAX_BOUNTY
    )

    local bounty = {
        playerId = playerId,
        amount = amount,
        reason = reason,
        issuerId = issuerId,
        timestamp = os.time(),
        expiryTime = os.time() + Modules.Crime.BountyConfig.DEFAULT_EXPIRY
    }

    local existingBountyIndex = nil
    for i, b in ipairs(State.bounties) do
        if b.playerId == playerId and b.reason == reason then
            existingBountyIndex = i
            break
        end
    end

    if existingBountyIndex then
        State.bounties[existingBountyIndex].amount = State.bounties[existingBountyIndex].amount + amount
        State.bounties[existingBountyIndex].timestamp = os.time()
        State.bounties[existingBountyIndex].expiryTime = os.time() + Modules.Crime.BountyConfig.DEFAULT_EXPIRY
        amount = State.bounties[existingBountyIndex].amount
    else
        table.insert(State.bounties, bounty)
    end

    Services.Event:Fire("Crime.Bounty", {
        playerId = playerId,
        amount = amount,
        reason = reason,
        issuerId = issuerId
    })

    return true, amount
end

function CrimeService:GetBounty(player): (number, {BountyData})
    local playerId = type(player) == "number" and player or player.UserId

    local bounties = {}
    local totalAmount = 0

    for _, bounty in ipairs(State.bounties) do
        if bounty.playerId == playerId and bounty.expiryTime > os.time() then
            table.insert(bounties, bounty)
            totalAmount = totalAmount + bounty.amount
        end
    end

    return totalAmount, bounties
end

function CrimeService:ClearBounty(player, captor): boolean
    local playerId = type(player) == "number" and player or player.UserId

    local totalBounty = 0
    local remainingBounties = {}

    for _, bounty in ipairs(State.bounties) do
        if bounty.playerId == playerId then
            totalBounty = totalBounty + bounty.amount
        else
            table.insert(remainingBounties, bounty)
        end
    end

    if totalBounty == 0 then
        return false
    end

    State.bounties = remainingBounties

    if captor then
        local captorId = type(captor) == "number" and captor or captor.UserId
        Services.Economy:AddCurrency(tostring(captorId), totalBounty, {
            source = "bounty_reward",
            target = playerId
        })

        Services.Memory:UpdateReputation(
            captor,
            "AUTHORITY",
            Modules.Crime.ReputationImpact.BOUNTY_CLEARED.FACTION
        )
    end

    Services.Event:Fire("Crime.Bounty", {
        playerId = playerId,
        amount = totalBounty,
        captorId = captor and (type(captor) == "number" and captor or captor.UserId) or nil
    })

    return true
end

function CrimeService:ClaimBounty(hunter, target): (boolean, number)
    if not hunter or not target then return false, 0 end

    local targetId = type(target) == "number" and target or target.UserId
    local hunterId = type(hunter) == "number" and hunter or hunter.UserId

    local totalBounty = self:GetBounty(target)
    if totalBounty <= 0 then return false, 0 end

    local success = self:ClearBounty(target, hunter)
    if not success then
        return false, 0
    end

    Services.Event:Fire("Crime.Arrest", {
        playerId = targetId,
        captorId = hunterId,
        amount = totalBounty
    })

    return true, totalBounty
end

--[[ Getter Functions ]]
function CrimeService:GetRecent(count, crimeType)
    count = count or 50
    local crimeData = Services.Data:GetGlobal(Services.Data.GLOBAL_KEYS.CRIME_DATA) or {}
    local recentCrimes = crimeData.recentCrimes or {}

    if not crimeType then
        local result = {}
        for i = math.max(1, #recentCrimes - count + 1), #recentCrimes do
            table.insert(result, recentCrimes[i])
        end
        return result
    else
        local result = {}
        for i = #recentCrimes, 1, -1 do
            if recentCrimes[i].type == crimeType then
                table.insert(result, recentCrimes[i])
                if #result >= count then
                    break
                end
            end
        end
        return result
    end
end

return CrimeService