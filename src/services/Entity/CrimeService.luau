--[[ CrimeService
    Manages criminal activities including theft, bounties, and law enforcement.
    Handles detection, reputation impact, and consequences of criminal actions.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-14
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
            if incomingData and incomingData.bounties and incomingData.lastUpdate and
               (not State.crimeData or not State.crimeData.lastUpdate or
                incomingData.lastUpdate > State.crimeData.lastUpdate) then
                State.crimeData = incomingData
                State.bounties = State.crimeData.bounties
            end
        end
    end,

    ["Combat.Death"] = function(self, data)
        local entity = data.entity
        local player = data.source

        if entity and entity:GetAttribute("TYPE") and player and player:IsA("Player") then
            if entity.ClassName ~= "Model" or entity:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(entity) then
                local isHostile = entity:GetAttribute("HOSTILE") or false
                if not isHostile then
                    self:CommitMurder(player, entity)
                end
            end
        end
    end,

    ["Combat.Damage"] = function(self, data)
        local target = data.target
        local attacker = data.source
        local damage = data.damage and data.damage.amount or 0

        if target and target:GetAttribute("TYPE") and attacker and attacker:IsA("Player") then
            if not game.Players:GetPlayerFromCharacter(target) then
                local isHostile = target:GetAttribute("HOSTILE") or false
                if not isHostile and damage > 0 then
                    self:CommitAssault(attacker, target, damage)
                end
            end
        end
    end,

    ["Location.Trespass"] = function(self, data)
        local player = data.player
        local locationId = data.locationId
        local location = Services.Location:GetLocation(locationId)

        if not (player and location) then return end

        local success, result = self:StartTresspass(player, location, data.reason)

        if success then
            Services.Event:Fire("Crime.Crime", {
                type = "TRESPASS",
                player = player,
                locationId = locationId,
                locationType = data.locationType,
                reason = data.reason,
                detected = result.detected,
                bounty = result.bounty
            })
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
    timestamp: number
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
function CrimeService:CalculateOutcome(player, crimeType, context)
    local crimeSettings = Modules.Crime.BountyConfig[crimeType]
    if not crimeSettings then
        return false, 0, "Invalid crime type", nil
    end

    local env = self:GetEnviornment(player)

    local securityLevel = context.securityLevel or Modules.Crime.SecurityLevels.NOVICE

    if context.useZoneSecurity then
        securityLevel = math.max(securityLevel, env.baseSecurityLevel)
    end

    local playerDexterity = player:GetAttribute("DEXTERITY") or 0
    local success = math.random(1, 100) <= Modules.Crime:GetSuccess(playerDexterity, securityLevel, context.value or 0)

    local detected = success and (math.random(1, 100) <= Modules.Crime:GetDetection(
        playerDexterity,
        securityLevel,
        context.value or 0,
        env.lightLevel,
        env.soundLevel,
        env.lineOfSight
    ))

    local baseBounty = crimeSettings.base or 50
    local finalBounty = detected and baseBounty * (1 + (securityLevel or 1) * 0.5) * (1 + (context.value or 0) / 1000) or 0

    return success, math.floor(finalBounty + 0.5), detected, env
end

function CrimeService:GetEnviornment(player)
    local playerZones = Services.Zone:GetZones(player)
    local zoneType = "VILLAGE"

    for zoneId, _ in pairs(playerZones) do
        local zoneData = Services.Zone.zones and Services.Zone.zones[zoneId]
        if zoneData and zoneData.zone then
            if zoneData.zone == "TOWN" or zoneData.zone == "CITY" then
                zoneType = zoneData.zone
                break
            elseif zoneData.zone == "VILLAGE" then
                zoneType = "VILLAGE"
            elseif zoneData.zone == "WILDERNESS" and zoneType == "VILLAGE" then
                zoneType = "WILDERNESS"
            end
        end
    end

    local timeOfDay = Services.Time:GetTimeOfDay()
    local lightLevel = "NORMAL"
    local soundLevel = "NORMAL"
    local lineOfSight = "VISIBLE"

    if timeOfDay == "NIGHT" then
        lightLevel = "DARK"
    elseif timeOfDay == "DUSK" then
        lightLevel = "DIM"
    elseif timeOfDay == "DAWN" then
        lightLevel = "DIM"
    end

    if zoneType == "CITY" then
        soundLevel = "LOUD"
    elseif zoneType == "WILDERNESS" then
        soundLevel = "QUIET"
    end

    local baseSecurityLevel = Modules.Crime.SecurityLevels.NOVICE
    if zoneType == "CITY" then
        baseSecurityLevel = Modules.Crime.SecurityLevels.HIGH
    elseif zoneType == "TOWN" then
        baseSecurityLevel = Modules.Crime.SecurityLevels.MEDIUM
    elseif zoneType == "VILLAGE" then
        baseSecurityLevel = Modules.Crime.SecurityLevels.LOW
    end

    return {
        zoneType = zoneType,
        timeOfDay = timeOfDay,
        lightLevel = lightLevel,
        soundLevel = soundLevel,
        lineOfSight = lineOfSight,
        baseSecurityLevel = baseSecurityLevel
    }
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

    Services.Data:AddGlobal(Services.Data.GLOBAL_KEYS.CRIME_DATA, "recentCrimes", crimeData, 100)

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

    local success, msg = Services.Inventory:AddItem(player, loot.id, 1, player, metadata)
    if not success then
        warn(string.format("AddLoot failed for player %s, item %s: %s", player.Name, loot.id, msg or "Unknown error"))
    end
    return success
end

--[[ Theft Functions ]]
function CrimeService:AttemptTheft(context: TheftContext): (boolean, CrimeResult)
    if not context.player then return false, {error = "Invalid player"} end
    if not context.targetInstance then return false, {error = "Invalid target instance"} end
    if not context.itemId then return false, {error = "Invalid item ID"} end

    local player = context.player
    local targetInstance = context.targetInstance
    local itemId = context.itemId
    local value = context.value or 10
    local metadata = context.metadata or {}
    local owner = targetInstance:GetAttribute("OWNER")

    if not owner or owner == player then
        return false, {error = "Item not owned by someone else or ownership changed"}
    end

    local locationId = context.locationId
    local isBurglary = false
    local crimeType = Modules.Crime.Types.THEFT
    local location

    if locationId then
        location = Services.Location:GetLocation(locationId)
        if location and location.isTrespassing then
            isBurglary = true
            crimeType = Modules.Crime.Types.BURGLARY
        end
    end

    local securityLevel = (location and location.securityLevel) or Modules.Crime.SecurityLevels.NOVICE
    local success, bounty, detected, env = self:CalculateOutcome(
        player,
        crimeType,
        {
            securityLevel = securityLevel,
            value = value,
            useZoneSecurity = true
        }
    )

    local outcome = {
        success = success,
        detected = detected,
        bounty = bounty,
        value = value,
        isBurglary = isBurglary
    }

    if outcome.success then
        local itemData = {
            id = itemId,
            value = value,
            name = targetInstance:GetAttribute("NAME")
        }

        local contextData = {
            sourceEntity = owner,
            originalId = targetInstance:GetAttribute("ID")
        }

        if isBurglary and locationId then
            contextData.sourceLocation = locationId
            contextData.burglary = true
        end

        local addSuccess = self:AddLoot(player, itemData, contextData)

        if addSuccess then
            targetInstance:Destroy()
        else
            outcome.success = false
            outcome.error = "Failed to add stolen item to inventory"
        end
    end

    if outcome.detected then
        local target = targetInstance

        if isBurglary and location then
            target = {
                id = locationId,
                type = "LOCATION",
                locationType = location.type,
                securityLevel = securityLevel,
                factionId = location.factionId,
                ownerId = location.ownerId
            }
        end

        local detectionResult = self:DetectPlayer(player, target, { value = value }, crimeType)
        outcome.bounty = detectionResult.bountyAmount
    end

    Services.Event:Fire("Crime.Crime", {
        type = isBurglary and "BURGLARY" or "THEFT",
        subType = "OBJECT",
        player = player,
        targetId = targetInstance:GetAttribute("ID"),
        targetType = targetInstance:GetAttribute("TYPE"),
        locationId = locationId,
        locationType = location and location.type or nil,
        itemId = itemId,
        success = outcome.success,
        detected = outcome.detected,
        value = value,
        bounty = outcome.bounty
    })

    return outcome.success, outcome
end

function CrimeService:AttemptPickpocket(context: TheftContext): (boolean, CrimeResult)
    local player = context.player
    local targetId = context.targetId

    local target = Services.Object:GetInstance(targetId)
    if not target then return false, {error = "Target not found"} end

    local targetType = target:GetAttribute("TYPE") or "VILLAGER"

    local securityLevel = Modules.Crime.SecurityLevels.NOVICE
    if targetType == "GUARD" then
        securityLevel = Modules.Crime.SecurityLevels.ADEPT
    elseif targetType == "MERCHANT" then
        securityLevel = Modules.Crime.SecurityLevels.APPRENTICE
    end

    local success, bounty, detected = self:CalculateOutcome(
        player,
        Modules.Crime.Types.PICKPOCKET,
        {
            securityLevel = securityLevel,
            value = 0,
            useZoneSecurity = true
        }
    )

    local outcome = {
        success = success,
        detected = detected,
        bounty = bounty
    }

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

--[[ Trespass Functions ]]
function CrimeService:StartTresspass(player, location, reason)
    if not player or not location then return false, {error = "Invalid parameters"} end

    local securityLevel = location.securityLevel or Modules.Crime.SecurityLevels.NOVICE

    local success, bounty, detected = self:CalculateOutcome(
        player,
        Modules.Crime.Types.TRESPASSING,
        {
            securityLevel = securityLevel,
            value = 0,
            useZoneSecurity = true
        }
    )

    success = true

    local locationWrapper = {
        id = location.id,
        type = "LOCATION",
        locationType = location.type,
        securityLevel = securityLevel,
        factionId = location.factionId,
        ownerId = location.ownerId
    }

    if detected then
        local detectionResult = self:DetectPlayer(player, locationWrapper, {
            value = Modules.Crime.BountyConfig.TRESPASSING.base or 50
        }, Modules.Crime.Types.TRESPASSING)

        bounty = detectionResult and detectionResult.bountyAmount or bounty
    end

    return true, {
        success = success,
        detected = detected,
        bounty = detected and bounty or 0,
        reason = reason
    }
end

function CrimeService:PickLock(player, locationId): (boolean, CrimeResult)
    if not player or not locationId then return false, {error = "Invalid parameters"} end

    local location = Services.Location:GetLocation(locationId)
    if not location then return false, {error = "Location not found"} end

    if not location.isLocked then
        return false, {error = "Location is not locked, not trespassing"}
    end

    local playerDexterity = player:GetAttribute("DEXTERITY") or 0
    local lockLevel = location.lockLevel or 1
    local securityLevel = location.securityLevel or Modules.Crime.SecurityLevels.NOVICE

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

    local success, bounty, detected = self:CalculateOutcome(
        player,
        Modules.Crime.Types.TRESPASSING,
        {
            securityLevel = securityLevel,
            value = 0,
            useZoneSecurity = true,
            specialDefenses = {
                magical = location.magicalDefenses,
                traps = location.trapDefenses
            }
        }
    )

    local roll = math.random(1, 100)
    success = roll <= successChance

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

--[[ Violent Functions ]]
function CrimeService:CommitAssault(player, victim, damageAmount)
    if not player or not victim then return false, { error = "Invalid parameters" } end

    local victimType = victim:GetAttribute("TYPE") or "VILLAGER"
    local victimId = victim:GetAttribute("ID")
    local securityLevel = victim:GetAttribute("SECURITY_LEVEL") or Modules.Crime.SecurityLevels.NOVICE

    local valueModifier = 1
    if victimType == "GUARD" then
        valueModifier = 2
    elseif victimType == "MERCHANT" or victim:GetAttribute("UNIQUE") then
        valueModifier = 1.5
    end

    local success, bountyAmount, detected, env = self:CalculateOutcome(
        player,
        Modules.Crime.Types.ASSAULT,
        {
            securityLevel = securityLevel,
            value = damageAmount * 0.5,
            useZoneSecurity = true
        }
    )

    success = true

    if detected then
        local detectionResult = self:DetectPlayer(player, victim, {
            value = Modules.Crime.BountyConfig.ASSAULT.base * valueModifier
        }, Modules.Crime.Types.ASSAULT)

        bountyAmount = detectionResult and detectionResult.bountyAmount or bountyAmount
    end

    Services.Event:Fire("Crime.Crime", {
        type = "ASSAULT",
        player = player,
        targetId = victimId,
        targetType = victimType,
        damage = damageAmount,
        success = success,
        detected = detected
    })

    return true, {
        success = success,
        detected = detected,
        bounty = detected and bountyAmount or 0
    }
end

function CrimeService:CommitMurder(player, victim)
    if not player or not victim then return false, { error = "Invalid parameters" } end

    local victimType = victim:GetAttribute("TYPE") or "VILLAGER"
    local victimId = victim:GetAttribute("ID")
    local securityLevel = victim:GetAttribute("SECURITY_LEVEL") or Modules.Crime.SecurityLevels.NOVICE

    local valueModifier = 1
    if victimType == "GUARD" then
        valueModifier = 2
    elseif victimType == "MERCHANT" or victim:GetAttribute("UNIQUE") then
        valueModifier = 1.5
    end

    local success, bountyAmount, detected, env = self:CalculateOutcome(
        player,
        Modules.Crime.Types.MURDER,
        {
            securityLevel = securityLevel,
            value = Modules.Crime.BountyConfig.MURDER.min * (valueModifier - 1),
            useZoneSecurity = true
        }
    )

    success = true

    if detected then
        local detectionResult = self:DetectPlayer(player, victim, {
            value = Modules.Crime.BountyConfig.MURDER.min * valueModifier
        }, Modules.Crime.Types.MURDER)

        bountyAmount = detectionResult and detectionResult.bountyAmount or bountyAmount
    end

    Services.Event:Fire("Crime.Crime", {
        type = "MURDER",
        player = player,
        targetId = victimId,
        targetType = victimType,
        success = success,
        detected = detected
    })

    return true, {
        success = success,
        detected = detected,
        bounty = detected and bountyAmount or 0
    }
end

--[[ Bounty Functions ]]
function CrimeService:AddBounty(player, amount, reason, issuerId): (boolean, number)
    local playerId = type(player) == "number" and player or player.UserId

    State.crimeData = Services.Data:GetGlobal(Services.Data.GLOBAL_KEYS.CRIME_DATA)
    State.crimeData.bounties = State.crimeData.bounties or {}
    State.bounties = State.crimeData.bounties

    amount = math.min(
        math.max(amount, Modules.Crime.BountyConfig.MIN_BOUNTY),
        Modules.Crime.BountyConfig.MAX_BOUNTY
    )

    local bounty = {
        playerId = playerId,
        amount = amount,
        reason = reason,
        issuerId = issuerId,
        timestamp = os.time()
    }

    local existingBountyIndex = nil
    for i, b in ipairs(State.crimeData.bounties) do
        if b.playerId == playerId and b.reason == reason then
            existingBountyIndex = i
            break
        end
    end

    if existingBountyIndex then
        State.crimeData.bounties[existingBountyIndex].amount = State.crimeData.bounties[existingBountyIndex].amount + amount
        State.crimeData.bounties[existingBountyIndex].timestamp = os.time()
        amount = State.crimeData.bounties[existingBountyIndex].amount
    else
        table.insert(State.crimeData.bounties, bounty)
    end

    local success = Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.CRIME_DATA, State.crimeData)
    if not success then
        return false, 0
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

    local currentBounties = State.bounties or {}
    local bounties = {}
    local totalAmount = 0

    for _, bounty in ipairs(currentBounties) do
        if bounty.playerId == playerId then
            table.insert(bounties, bounty)
            totalAmount = totalAmount + bounty.amount
        end
    end

    return totalAmount, bounties
end

function CrimeService:GetBounties(count, crimeType)
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

function CrimeService:ClearBounty(player, captor): boolean
    local playerId = type(player) == "number" and player or player.UserId

    State.crimeData = Services.Data:GetGlobal(Services.Data.GLOBAL_KEYS.CRIME_DATA)
    if not State.crimeData then return false end
    State.crimeData.bounties = State.crimeData.bounties or {}

    local totalBounty = 0
    local remainingBounties = {}
    local cleared = false

    for _, bounty in ipairs(State.crimeData.bounties) do
        if bounty.playerId == playerId then
            totalBounty = totalBounty + bounty.amount
            cleared = true
        else
            table.insert(remainingBounties, bounty)
        end
    end

    if not cleared then
        return false
    end

    State.crimeData.bounties = remainingBounties
    State.bounties = remainingBounties

    local success = Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.CRIME_DATA, State.crimeData)
    if not success then return false end

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
        cleared = true,
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

return CrimeService