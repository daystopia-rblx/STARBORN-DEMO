--[[ WarService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local WarService = {}

WarService.Dependencies = {
    "Data",
    "Event",
    "Guild"
}

WarService.Modules = {
    "Guild"
}

WarService.Events = {
    Declare = { validate = true },
    Stage = { validate = true },
    Action = { validate = true },
    Result = { validate = true }
}

local Services
local Modules
local HttpService = game:GetService("HttpService")

local State = {
    wars = {},
    guildsChanged = false
}

function WarService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function WarService:Start()
    task.spawn(function()
        while true do
            task.wait(60)
            self:CheckWars()

            if State.guildsChanged then
                Services.Guild:NotifyWarChanges(State.wars)
                State.guildsChanged = false
            end
        end
    end)

    return true
end

--[[ War Functions ]]
function WarService:RegisterWar(warId, attackerId, defenderId, territoryId)
    local attackerGuild = Services.Guild:GetGuild(attackerId)
    local defenderGuild = Services.Guild:GetGuild(defenderId)

    if attackerGuild then
        attackerGuild.wars[warId] = {
            againstId = defenderId,
            territoryId = territoryId,
            startedAt = os.time(),
            role = "ATTACKER"
        }
    end

    if defenderGuild then
        defenderGuild.wars[warId] = {
            againstId = attackerId,
            territoryId = territoryId,
            startedAt = os.time(),
            role = "DEFENDER"
        }
    end

    State.guildsChanged = true
    return true
end

function WarService:RemoveWar(warId)
    for _, guild in pairs(Services.Guild:GetAllGuilds()) do
        if guild.wars and guild.wars[warId] then
            guild.wars[warId] = nil
        end
    end
    State.guildsChanged = true
    return true
end

function WarService:DeclareWar(player, targetGuildId, territoryId, warType)
    if not player or not targetGuildId then
        return false, "Invalid player or target guild"
    end

    local userId = tostring(player.UserId)
    local guildId = Services.Guild:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = Services.Guild:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    if not (guild.leader == userId or Modules.Guild:CheckPermission(memberRank, "WAR_DECLARE")) then
        return false, "You don't have permission to declare war"
    end

    local targetGuild = Services.Guild:GetGuild(targetGuildId)
    if not targetGuild then
        return false, "Target guild not found"
    end

    if guildId == targetGuildId then
        return false, "Cannot declare war on your own guild"
    end

    for warId, war in pairs(State.wars) do
        if (war.attackerId == guildId and war.defenderId == targetGuildId) or
           (war.attackerId == targetGuildId and war.defenderId == guildId) then
            return false, "War already exists between these guilds"
        end
    end

    if warType and not Modules.Guild.WAR_TYPES[warType] then
        return false, "Invalid war type"
    end

    local warTypeId = warType or "OPEN_WORLD"
    local warTypeConfig = Modules.Guild.WAR_TYPES[warTypeId]

    local activeAttackerMembers = 0
    for memberId, memberData in pairs(guild.members) do
        if os.time() - (memberData.lastActive or 0) < 604800 then
            activeAttackerMembers += 1
        end
    end

    local activeDefenderMembers = 0
    for memberId, memberData in pairs(targetGuild.members) do
        if os.time() - (memberData.lastActive or 0) < 604800 then
            activeDefenderMembers += 1
        end
    end

    if activeAttackerMembers < warTypeConfig.minPlayers or activeDefenderMembers < warTypeConfig.minPlayers then
        return false, "Both guilds need at least " .. warTypeConfig.minPlayers .. " active members for this war type"
    end

    local warId = HttpService:GenerateGUID(false)

    local newWar = Modules.Guild.Templates.War({
        id = warId,
        attackerId = guildId,
        defenderId = targetGuildId,
        territoryId = territoryId,
        warType = warTypeId
    })

    if warTypeId == "BANNER_SIEGE" then
        newWar.bannerHealth = 1000
        newWar.bannerLocation = nil
    elseif warTypeId == "SKIRMISH" then
        newWar.rounds = 3
        newWar.currentRound = 0
        newWar.roundWins = {
            [guildId] = 0,
            [targetGuildId] = 0
        }
    end

    State.wars[warId] = newWar
    State.guildsChanged = true

    self:RegisterWar(warId, guildId, targetGuildId, territoryId)

    Services.Event:Fire("War.Declare", {
        warId = warId,
        attackerId = guildId,
        attackerName = guild.name,
        defenderId = targetGuildId,
        defenderName = targetGuild.name,
        territoryId = territoryId,
        warType = warTypeId,
        action = "DECLARE",
        byPlayer = userId
    })

    return true, {
        warId = warId,
        defender = targetGuild.name,
        warType = warTypeConfig.name,
        territory = territoryId and Services.Guild:GetTerritory(territoryId) and Services.Guild:GetTerritory(territoryId).name
    }
end

function WarService:CheckWars()
    local currentTime = os.time()
    local changesOccurred = false

    for warId, war in pairs(State.wars) do
        for i, stage in ipairs(war.stages) do
            if stage.status == "ACTIVE" and currentTime > stage.endAt then
                stage.status = "COMPLETED"

                if i < #war.stages then
                    war.stages[i + 1].status = "ACTIVE"

                    Services.Event:Fire("War.Stage", {
                        warId = warId,
                        attackerId = war.attackerId,
                        defenderId = war.defenderId,
                        stage = war.stages[i + 1].id,
                        action = "STAGE_START"
                    })
                else
                    local winnerGuildId = nil
                    if war.scores[war.attackerId] > war.scores[war.defenderId] then
                        winnerGuildId = war.attackerId
                    else
                        winnerGuildId = war.defenderId
                    end

                    local attackerGuild = Services.Guild:GetGuild(war.attackerId)
                    local defenderGuild = Services.Guild:GetGuild(war.defenderId)

                    if war.territoryId then
                        Services.Guild:TransferTerritory(war.territoryId, winnerGuildId)
                    end

                    Services.Guild:AddExperience(war.attackerId, winnerGuildId == war.attackerId and 500 or 200, "WAR_PARTICIPATION")
                    Services.Guild:AddExperience(war.defenderId, winnerGuildId == war.defenderId and 500 or 200, "WAR_PARTICIPATION")
                    self:RemoveWar(warId)

                    Services.Event:Fire("War.Result", {
                        warId = warId,
                        attackerId = war.attackerId,
                        attackerName = attackerGuild and attackerGuild.name or "Unknown Guild",
                        defenderId = war.defenderId,
                        defenderName = defenderGuild and defenderGuild.name or "Unknown Guild",
                        winnerId = winnerGuildId,
                        winnerName = (winnerGuildId == war.attackerId and attackerGuild and attackerGuild.name) or
                                   (defenderGuild and defenderGuild.name) or "Unknown Guild",
                        action = "RESOLVED"
                    })

                    State.wars[warId] = nil
                end

                changesOccurred = true
            end
        end
    end

    if changesOccurred then
        State.guildsChanged = true
    end

    return changesOccurred
end

function WarService:GetWar(warId)
    return State.wars[warId]
end


function WarService:GetWars(warId)
    local war = State.wars[warId]
    if not war then
        return false, "War not found"
    end

    local attackerGuild = Services.Guild:GetGuild(war.attackerId)
    local defenderGuild = Services.Guild:GetGuild(war.defenderId)

    if not attackerGuild or not defenderGuild then
        return false, "One of the guilds no longer exists"
    end

    local territory = nil
    if war.territoryId then
        local territoryData = Services.Guild:GetTerritory(war.territoryId)
        if territoryData then
            territory = {
                id = war.territoryId,
                name = territoryData.name,
                location = territoryData.location
            }
        end
    end

    local warTypeInfo = {}
    if war.warType == "BANNER_SIEGE" then
        warTypeInfo = {
            bannerHealth = war.bannerHealth or 1000,
            bannerLocation = war.bannerLocation,
            lastRepair = war.lastRepair
        }
    elseif war.warType == "SKIRMISH" then
        warTypeInfo = {
            rounds = war.rounds or 3,
            currentRound = war.currentRound or 0,
            roundWins = war.roundWins,
            teams = war.teams
        }
    elseif war.warType == "OPEN_WORLD" then
        warTypeInfo = {
            controlPoints = war.controlPoints,
            kills = war.kills
        }
    end

    return true, {
        id = war.id,
        warType = war.warType,
        attackerId = war.attackerId,
        attackerName = attackerGuild.name,
        defenderId = war.defenderId,
        defenderName = defenderGuild.name,
        scores = war.scores,
        startedAt = war.startedAt,
        stages = war.stages,
        territory = territory,
        typeSpecific = warTypeInfo
    }
end

function WarService:GetGuilds(guildId)
    local guildWars = {}

    for warId, war in pairs(State.wars) do
        if war.attackerId == guildId or war.defenderId == guildId then
            guildWars[warId] = war
        end
    end

    return guildWars
end

--[[ Action Functions ]]
function WarService:RecordKill(player, targetPlayer, warId)
    local war = State.wars[warId]
    if not war or war.warType ~= "OPEN_WORLD" then
        return false, "Invalid war or war type"
    end

    local userId = tostring(player.UserId)
    local targetUserId = tostring(targetPlayer.UserId)
    local attackerGuildId = Services.Guild:GetPlayer(player)
    local defenderGuildId = Services.Guild:GetPlayer(targetPlayer)

    if attackerGuildId ~= war.attackerId and attackerGuildId ~= war.defenderId then
        return false, "You are not part of this war"
    end

    if defenderGuildId ~= war.attackerId and defenderGuildId ~= war.defenderId then
        return false, "Target is not part of this war"
    end

    if attackerGuildId == defenderGuildId then
        return false, "Cannot record kills against your own guild"
    end

    if war.stages[2].status ~= "ACTIVE" then
        return false, "Combat stage is not active"
    end

    war.scores[attackerGuildId] = war.scores[attackerGuildId] + 10

    war.kills = war.kills or {}
    war.kills[userId] = (war.kills[userId] or 0) + 1

    State.guildsChanged = true

    Services.Event:Fire("War.Action", {
        warId = warId,
        attackerId = war.attackerId,
        defenderId = war.defenderId,
        action = "PVP_KILL",
        killerId = userId,
        targetId = targetUserId,
        guildScores = war.scores
    })

    return true, {
        newScore = war.scores[attackerGuildId],
        personalKills = war.kills[userId]
    }
end

function WarService:CapturePoint(player, warId, pointId, position)
    local war = State.wars[warId]
    if not war or war.warType ~= "OPEN_WORLD" then
        return false, "Invalid war or war type"
    end

    local userId = tostring(player.UserId)
    local guildId = Services.Guild:GetPlayer(player)

    if guildId ~= war.attackerId and guildId ~= war.defenderId then
        return false, "You are not part of this war"
    end

    if war.stages[2].status ~= "ACTIVE" then
        return false, "Battle stage is not active"
    end

    war.controlPoints = war.controlPoints or {}

    local lastCapture = war.controlPoints[pointId] and war.controlPoints[pointId].capturedAt or 0
    if os.time() - lastCapture < 300 then
        return false, "This point was recently captured, try again later"
    end

    war.controlPoints[pointId] = {
        ownerId = guildId,
        capturedAt = os.time(),
        position = position,
        capturedBy = userId
    }

    war.scores[guildId] = war.scores[guildId] + 25

    local pointsHeld = 0
    for _, point in pairs(war.controlPoints) do
        if point.ownerId == guildId then
            pointsHeld += 1
        end
    end

    if pointsHeld >= 3 then
        war.scores[guildId] = war.scores[guildId] + 50
    end

    State.guildsChanged = true

    Services.Event:Fire("War.Action", {
        warId = warId,
        attackerId = war.attackerId,
        defenderId = war.defenderId,
        action = "CONTROL_POINT_CAPTURED",
        pointId = pointId,
        guildId = guildId,
        capturedBy = userId,
        position = position,
        guildScores = war.scores
    })

    return true, {
        newScore = war.scores[guildId],
        pointsHeld = pointsHeld
    }
end

function WarService:StartSiege(warId, bannerLocation)
    local war = State.wars[warId]
    if not war or war.warType ~= "BANNER_SIEGE" then
        return false, "Invalid war or war type"
    end

    if war.stages[1].status ~= "COMPLETED" then
        return false, "Cannot setup banner during preparation stage"
    end

    war.bannerLocation = bannerLocation
    State.guildsChanged = true

    Services.Event:Fire("War.Action", {
        warId = warId,
        attackerId = war.attackerId,
        defenderId = war.defenderId,
        action = "BANNER_PLACED",
        location = bannerLocation
    })

    return true
end

function WarService:AttackBanner(player, warId, damage)
    local war = State.wars[warId]
    if not war or war.warType ~= "BANNER_SIEGE" then
        return false, "Invalid war or war type"
    end

    local userId = tostring(player.UserId)
    local guildId = Services.Guild:GetPlayer(player)

    if not guildId or (guildId ~= war.attackerId and guildId ~= war.defenderId) then
        return false, "You are not part of this war"
    end

    if guildId ~= war.attackerId then
        return false, "Only attacking guild can damage the banner"
    end

    if war.stages[2].status ~= "ACTIVE" then
        return false, "Banner battle is not active"
    end

    war.bannerHealth = math.max(0, war.bannerHealth - damage)

    if war.bannerHealth <= 0 then
        war.scores[war.attackerId] = math.huge
        war.stages[2].status = "COMPLETED"

        State.guildsChanged = true

        Services.Event:Fire("War.Action", {
            warId = warId,
            attackerId = war.attackerId,
            defenderId = war.defenderId,
            action = "BANNER_DESTROYED"
        })
    end

    return true, {
        health = war.bannerHealth,
        maxHealth = 1000,
        damageDealt = damage
    }
end

function WarService:DefendBanner(player, warId, health)
    local war = State.wars[warId]
    if not war or war.warType ~= "BANNER_SIEGE" then
        return false, "Invalid war or war type"
    end

    local userId = tostring(player.UserId)
    local guildId = Services.Guild:GetPlayer(player)

    if guildId ~= war.defenderId then
        return false, "Only defending guild can repair banner"
    end

    if war.stages[2].status ~= "ACTIVE" then
        return false, "Banner battle is not active"
    end

    war.lastRepair = war.lastRepair or 0

    if os.time() - war.lastRepair < 60 then
        return false, "Banner was recently repaired, try again later"
    end

    local repairAmount = math.min(health, 100)

    war.bannerHealth = math.min(1000, war.bannerHealth + repairAmount)
    war.lastRepair = os.time()

    war.defenderActivity = war.defenderActivity or {}
    war.defenderActivity[userId] = (war.defenderActivity[userId] or 0) + repairAmount

    State.guildsChanged = true

    Services.Event:Fire("War.Action", {
        warId = warId,
        attackerId = war.attackerId,
        defenderId = war.defenderId,
        action = "BANNER_REPAIRED",
        repairedBy = userId,
        amount = repairAmount,
        currentHealth = war.bannerHealth
    })

    return true, {
        health = war.bannerHealth,
        maxHealth = 1000,
        repairAmount = repairAmount
    }
end

function WarService:RegisterSkirmish(player, warId, teamMembers)
    local war = State.wars[warId]
    if not war or war.warType ~= "SKIRMISH" then
        return false, "Invalid war or war type"
    end

    local userId = tostring(player.UserId)
    local guildId = Services.Guild:GetPlayer(player)

    if guildId ~= war.attackerId and guildId ~= war.defenderId then
        return false, "You are not part of this war"
    end

    local guild = Services.Guild:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId].rank
    if not (guild.leader == userId or Modules.Guild:CheckPermission(memberRank, "WAR_DECLARE")) then
        return false, "You don't have permission to register war teams"
    end

    local warType = Modules.Guild.WAR_TYPES["SKIRMISH"]
    if #teamMembers < warType.minPlayers or #teamMembers > warType.maxPlayers then
        return false, "Team must have between " .. warType.minPlayers .. " and " .. warType.maxPlayers .. " members"
    end

    for _, memberId in ipairs(teamMembers) do
        if not guild.members[memberId] then
            return false, "All team members must be in your guild"
        end
    end

    war.teams = war.teams or {}
    war.teams[guildId] = {
        members = teamMembers,
        registeredAt = os.time(),
        registeredBy = userId
    }

    State.guildsChanged = true

    Services.Event:Fire("War.Action", {
        warId = warId,
        guildId = guildId,
        action = "SKIRMISH_TEAM_REGISTERED",
        teamSize = #teamMembers,
        registeredBy = userId
    })

    if war.teams[war.attackerId] and war.teams[war.defenderId] then
        Services.Event:Fire("War.Action", {
            warId = warId,
            attackerId = war.attackerId,
            defenderId = war.defenderId,
            action = "SKIRMISH_TEAMS_READY"
        })
    end

    return true, {
        teamSize = #teamMembers,
        isReady = war.teams[war.attackerId] ~= nil and war.teams[war.defenderId] ~= nil
    }
end

function WarService:SkirmishResult(warId, winnerGuildId, roundScore)
    local war = State.wars[warId]
    if not war or war.warType ~= "SKIRMISH" then
        return false, "Invalid war or war type"
    end

    if war.stages[2].status ~= "ACTIVE" then
        return false, "Skirmish battle is not active"
    end

    if winnerGuildId ~= war.attackerId and winnerGuildId ~= war.defenderId then
        return false, "Invalid winner guild ID"
    end

    war.currentRound += 1
    war.roundWins[winnerGuildId] += 1

    war.scores[war.attackerId] += (winnerGuildId == war.attackerId) and roundScore or 0
    war.scores[war.defenderId] += (winnerGuildId == war.defenderId) and roundScore or 0

    if war.roundWins[war.attackerId] > war.rounds/2 or war.roundWins[war.defenderId] > war.rounds/2 then
        war.stages[2].status = "COMPLETED"
        State.guildsChanged = true
    end

    Services.Event:Fire("War.Action", {
        warId = warId,
        attackerId = war.attackerId,
        defenderId = war.defenderId,
        action = "SKIRMISH_ROUND",
        winnerGuildId = winnerGuildId,
        currentRound = war.currentRound,
        roundScore = roundScore,
        attackerWins = war.roundWins[war.attackerId],
        defenderWins = war.roundWins[war.defenderId]
    })

    return true
end

return WarService