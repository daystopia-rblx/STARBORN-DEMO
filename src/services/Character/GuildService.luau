--[[ GuildService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local GuildService = {}

GuildService.Dependencies = {
    "Data",
    "Event",
    "Inventory",
    "Economy"
}

GuildService.Modules = {
    "Guild"
}

GuildService.Events = {
    Create = { validate = true },
    Join = { validate = true },
    Leave = { validate = true },
    Rank = { validate = true },
    Level = { validate = true },
    Banner = { validate = true },
    Territory = { validate = true }
}

local Services
local Modules
local HttpService = game:GetService("HttpService")

local State = {
    guilds = {},
    playerGuilds = {},
    territories = {},
    wars = {}
}

GuildService.Listeners = {
    ["Data.Global"] = function(self, data)
        if data.key == Services.Data.GLOBAL_KEYS.GUILD_DATA then
            local incomingData = data.data
            if incomingData and incomingData.guilds and incomingData.lastUpdate and
               (not State.guildData or not State.guildData.lastUpdate or
                incomingData.lastUpdate > State.guildData.lastUpdate) then
                State.guildData = incomingData
                State.guilds = State.guildData.guilds
                State.territories = State.guildData.territories
                State.wars = State.guildData.wars
            end
        end
    end
}

--[[ Core Functions ]]
function GuildService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function GuildService:Start()
    self:InitializeGuilds()

    task.spawn(function()
        while true do
            task.wait(3600)

            self:UpdateTerritories()
            self:CheckWars()

            if State.guildsChanged then
                Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)
                State.guildsChanged = false
            end
        end
    end)

    return true
end

--[[ Guild Functions ]]
function GuildService:InitializeGuilds()
    State.guilds = Services.Data:GetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA)

    if not State.guilds or not next(State.guilds) then
        State.guilds = {}
        Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)
    end
end

function GuildService:CreateGuild(player, guildData)
    if not player or not guildData or not guildData.name then
        return false, "Missing required guild information"
    end

    local userId = tostring(player.UserId)
    local playerLevel = player:GetAttribute("LEVEL") or 1

    if playerLevel < 10 then
        return false, "You must be at least level 10 to create a guild"
    end

    local playerGuildId = self:GetPlayer(player)
    if playerGuildId then
        return false, "You are already in a guild"
    end

    local guildCreationCost = 5000
    local playerBalance = Services.Economy:GetBalance(userId) or 0

    if playerBalance < guildCreationCost then
        return false, "You need " .. guildCreationCost .. " Umbrels to create a guild"
    end

    for _, guild in pairs(State.guilds) do
        if guild.name:lower() == guildData.name:lower() then
            return false, "A guild with this name already exists"
        end
    end

    local foundingMembers = guildData.foundingMembers or {}

    local guildId = HttpService:GenerateGUID(false)

    local newGuild = Modules.Guild.Templates.Guild({
        id = guildId,
        name = guildData.name,
        description = guildData.description,
        createdBy = userId,
        bannerShape = guildData.bannerShape,
        primaryColor = guildData.primaryColor,
        secondaryColor = guildData.secondaryColor,
        symbol = guildData.symbol,
        pattern = guildData.pattern,
        motd = guildData.motd
    })

    Services.Economy:RemoveCurrency(userId, guildCreationCost, {
        type = "guild_creation",
        guildId = guildId,
        guildName = guildData.name
    })

    State.guilds[guildId] = newGuild
    State.playerGuilds[userId] = guildId
    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)
    Services.Data:SetData(userId, "PlayerData", {
        guildId = guildId
    })

    Services.Event:Fire("Guild.Create", {
        player = player,
        guildId = guildId,
        guildName = newGuild.name
    })

    for _, memberId in ipairs(foundingMembers) do
        if memberId ~= userId then
            newGuild.members[memberId] = {
                joinedAt = os.time(),
                rank = "COUNCIL",
                contribution = 0,
                lastActive = os.time()
            }
            State.playerGuilds[memberId] = guildId
        end
    end

    return true, {
        guildId = guildId,
        name = newGuild.name
    }
end

function GuildService:GetGuild(guildId)
    if not guildId then return nil end
    return State.guilds[guildId]
end

function GuildService:GetPlayer(player)
    if not player then return nil end

    local userId = tostring(player.UserId)

    if State.playerGuilds[userId] then
        return State.playerGuilds[userId]
    end

    local playerData = Services.Data:GetData(userId, "PlayerData")
    if playerData and playerData.guildId then
        State.playerGuilds[userId] = playerData.guildId
        return playerData.guildId
    end

    return nil
end


function GuildService:AddExperience(guildId, xpAmount, source)
    local guild = self:GetGuild(guildId)
    if not guild then return false end

    guild.xp = guild.xp + xpAmount

    local xpRequired = Modules.Guild:GetExperience(guild.level)
    if guild.xp >= xpRequired and guild.level < 10 then
        guild.level = guild.level + 1
        guild.xp = guild.xp - xpRequired

        Services.Event:Fire("Guild.Level", {
            guildId = guildId,
            guildName = guild.name,
            newLevel = guild.level,
            source = source
        })
    end

    State.guildsChanged = true

    return true
end

function GuildService:AddMessage(player, message)
    if not player or not message or message == "" then
        return false, "Invalid player or message"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    local guildMessage = Modules.Guild.Templates.Message({
        author = userId,
        content = message
    })

    guild.messageBoard.messages = guild.messageBoard.messages or {}
    table.insert(guild.messageBoard.messages, guildMessage)

    if #guild.messageBoard.messages > 50 then
        table.remove(guild.messageBoard.messages, 1)
    end

    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)

    return true, {
        messageId = guildMessage.id
    }
end

--[[ Banner Functions ]]
function GuildService:UpdateBanner(player, bannerData)
    if not player or not bannerData then
        return false, "Invalid player or banner data"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    if not (guild.leader == userId or Modules.Guild:CheckPermission(memberRank, "EDIT_BANNER")) then
        return false, "You don't have permission to update the guild banner"
    end

    if bannerData.shape and not table.find(Modules.Guild.BANNER_SHAPES, bannerData.shape) then
        return false, "Invalid banner shape"
    end

    guild.banner = {
        shape = bannerData.shape or guild.banner.shape,
        primaryColor = bannerData.primaryColor or guild.banner.primaryColor,
        secondaryColor = bannerData.secondaryColor or guild.banner.secondaryColor,
        symbol = bannerData.symbol or guild.banner.symbol,
        pattern = bannerData.pattern or guild.banner.pattern
    }

    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)

    Services.Event:Fire("Guild.Banner", {
        guildId = guildId,
        guildName = guild.name,
        banner = guild.banner,
        updatedBy = userId
    })

    return true, {
        banner = guild.banner
    }
end

--[[ Member Functions ]]
function GuildService:JoinGuild(player, guildId, inviteCode)
    if not player or not guildId then
        return false, "Invalid player or guild"
    end

    local userId = tostring(player.UserId)
    local playerGuildId = self:GetPlayer(player)

    if playerGuildId then
        return false, "You are already in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberCount = 0
    for _ in pairs(guild.members) do
        memberCount += 1
    end

    if memberCount >= Modules.Guild:GetLimit(guild.level) then
        return false, "Guild has reached maximum member capacity"
    end

    if guild.inviteOnly and not inviteCode then
        return false, "This guild requires an invitation"
    end

    if guild.inviteOnly and inviteCode ~= guild.inviteCode then
        return false, "Invalid invitation code"
    end

    guild.members[userId] = {
        joinedAt = os.time(),
        rank = "RECRUIT",
        contribution = 0,
        lastActive = os.time()
    }

    State.playerGuilds[userId] = guildId
    State.guildsChanged = true

    Services.Data:SetData(userId, "PlayerData", {
        guildId = guildId
    })

    Services.Event:Fire("Guild.Join", {
        player = player,
        guildId = guildId,
        guildName = guild.name
    })

    return true, {
        guildId = guildId,
        name = guild.name,
        rank = "RECRUIT"
    }
end

function GuildService:LeaveGuild(player)
    if not player then
        return false, "Invalid player"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    if guild.leader == userId then
        local officers = {}
        for memberId, memberData in pairs(guild.members) do
            if memberData.rank == "OFFICER" then
                table.insert(officers, memberId)
            end
        end

        if #officers > 0 then
            guild.leader = officers[1]
            guild.members[officers[1]].rank = "LEADER"
        else
            local oldestMember = nil
            local oldestJoinTime = math.huge

            for memberId, memberData in pairs(guild.members) do
                if memberId ~= userId and memberData.joinedAt < oldestJoinTime then
                    oldestMember = memberId
                    oldestJoinTime = memberData.joinedAt
                end
            end

            if oldestMember then
                guild.leader = oldestMember
                guild.members[oldestMember].rank = "LEADER"
            else
                State.guilds[guildId] = nil
                Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)

                State.playerGuilds[userId] = nil
                Services.Data:SetData(userId, "PlayerData", {
                    guildId = nil
                })

                Services.Event:Fire("Guild.Leave", {
                    player = player,
                    guildId = guildId,
                    guildName = guild.name,
                    guildDissolved = true
                })

                return true, {
                    guildId = guildId,
                    name = guild.name,
                    dissolved = true
                }
            end
        end
    end

    guild.members[userId] = nil
    State.playerGuilds[userId] = nil
    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)
    Services.Data:SetData(userId, "PlayerData", {
        guildId = nil
    })

    Services.Event:Fire("Guild.Leave", {
        player = player,
        guildId = guildId,
        guildName = guild.name
    })

    return true, {
        guildId = guildId,
        name = guild.name
    }
end

function GuildService:PromoteMember(player, targetUserId)
    if not player or not targetUserId then
        return false, "Invalid player or target"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    if not (guild.leader == userId or Modules.Guild:CheckPermission(memberRank, "PROMOTE")) then
        return false, "You don't have permission to promote members"
    end

    if not guild.members[targetUserId] then
        return false, "Target user is not a member of this guild"
    end

    local targetRank = guild.members[targetUserId].rank
    local newRank = nil

    if targetRank == "RECRUIT" then
        newRank = "MEMBER"
    elseif targetRank == "MEMBER" then
        newRank = "VETERAN"
    elseif targetRank == "VETERAN" then
        if guild.leader == userId then
            newRank = "OFFICER"
        else
            return false, "Only the Guild Leader can promote to Officer"
        end
    elseif targetRank == "OFFICER" then
        if guild.leader == userId then
            guild.leader = targetUserId
            newRank = "LEADER"
            guild.members[userId].rank = "OFFICER"
        else
            return false, "Only the Guild Leader can transfer leadership"
        end
    end

    if not newRank then
        return false, "Cannot promote from current rank"
    end

    guild.members[targetUserId].rank = newRank
    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)

    Services.Event:Fire("Guild.Rank", {
        promotedBy = userId,
        targetId = targetUserId,
        guildId = guildId,
        newRank = newRank
    })

    local targetPlayer = game.Players:GetPlayerByUserId(tonumber(targetUserId))
    if targetPlayer then
        Services.Event:FireTo(
            targetPlayer,
            "Notification",
            {
                type = "GUILD_PROMOTION",
                title = "Guild Promotion",
                message = "You have been promoted to " .. Modules.Guild.RANKS[newRank].name .. " in " .. guild.name,
                duration = 10
            }
        )
    end

    return true, {
        targetId = targetUserId,
        newRank = newRank
    }
end

function GuildService:DemoteMember(player, targetUserId)
    if not player or not targetUserId then
        return false, "Invalid player or target"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    if not (guild.leader == userId or Modules.Guild:CheckPermission(memberRank, "DEMOTE")) then
        return false, "You don't have permission to demote members"
    end

    if not guild.members[targetUserId] then
        return false, "Target user is not a member of this guild"
    end

    if targetUserId == guild.leader then
        return false, "Cannot demote the Guild Leader"
    end

    local targetRank = guild.members[targetUserId].rank
    local newRank = nil

    if targetRank == "OFFICER" then
        if guild.leader == userId then
            newRank = "VETERAN"
        else
            return false, "Only the Guild Leader can demote Officers"
        end
    elseif targetRank == "VETERAN" then
        newRank = "MEMBER"
    elseif targetRank == "MEMBER" then
        newRank = "RECRUIT"
    else
        return false, "Cannot demote from current rank"
    end

    guild.members[targetUserId].rank = newRank
    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)

    Services.Event:Fire("Guild.Rank", {
        demotedBy = userId,
        targetId = targetUserId,
        guildId = guildId,
        newRank = newRank
    })

    local targetPlayer = game.Players:GetPlayerByUserId(tonumber(targetUserId))
    if targetPlayer then
        Services.Event:FireTo(
            targetPlayer,
            "Notification",
            {
                type = "GUILD_DEMOTION",
                title = "Guild Demotion",
                message = "You have been demoted to " .. Modules.Guild.RANKS[newRank].name .. " in " .. guild.name,
                duration = 10
            }
        )
    end

    return true, {
        targetId = targetUserId,
        newRank = newRank
    }
end

--[[ Territory Functions ]]
function GuildService:ClaimTerritory(player, territoryId)
    if not player or not territoryId then
        return false, "Invalid player or territory"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local territory = State.territories[territoryId]
    if not territory then
        return false, "Territory not found"
    end

    if territory.ownerId and territory.ownerId ~= guildId then
        local territoryGuild = self:GetGuild(territory.ownerId)
        if territoryGuild then
            return false, "This territory is claimed by " .. territoryGuild.name
        end
    end

    local territoryCount = 0
    for _ in pairs(guild.territories) do
        territoryCount += 1
    end

    if territoryCount >= guild.level then
        return false, "Your guild cannot control more territories at its current level"
    end

    territory.ownerId = guildId
    territory.claimedAt = os.time()
    territory.defendedBy = {}

    guild.territories[territoryId] = {
        claimedAt = os.time(),
        benefit = territory.defaultBenefit or "RESOURCE_BOOST"
    }

    State.guildsChanged = true

    Services.Data:SetGlobal(Services.Data.GLOBAL_KEYS.GUILD_DATA, State.guilds)

    Services.Event:Fire("Guild.Territory", {
        guildId = guildId,
        guildName = guild.name,
        territoryId = territoryId,
        territoryName = territory.name,
        action = "CLAIM",
        byPlayer = userId
    })

    return true, {
        territoryId = territoryId,
        territoryName = territory.name
    }
end

function GuildService:UpdateTerritories()
    for territoryId, territory in pairs(State.territories) do
        if territory.ownerId then
            local guild = self:GetGuild(territory.ownerId)
            if guild then
                local benefit = guild.territories[territoryId] and guild.territories[territoryId].benefit

                if benefit == "RESOURCE_BOOST" then
                    for memberId, _ in pairs(guild.members) do
                        local player = game.Players:GetPlayerByUserId(tonumber(memberId))
                        if player then
                            Services.Stat:ApplyBuff(
                                memberId,
                                "RESOURCE_GATHERING",
                                1.15,
                                "guild_territory_" .. territoryId,
                                60)
                        end
                    end
                elseif benefit == "HEALTH_REGEN" then
                    for memberId, _ in pairs(guild.members) do
                        local player = game.Players:GetPlayerByUserId(tonumber(memberId))
                        if player then
                            Services.Stat:ApplyBuff(
                                memberId,
                                "HEALTH_REGEN",
                                1.10,
                                "guild_territory_" .. territoryId,
                                60)
                        end
                    end
                elseif benefit == "DAMAGE_BOOST" then
                    for memberId, _ in pairs(guild.members) do
                        local player = game.Players:GetPlayerByUserId(tonumber(memberId))
                        if player then
                            Services.Stat:ApplyBuff(
                                memberId,
                                "DAMAGE",
                                1.05,
                                "guild_territory_" .. territoryId,
                                60)
                        end
                    end
                end
            end
        end
    end

    return true
end

function GuildService:TransferTerritory(territoryId, newOwnerId)
    if not territoryId or not State.territories[territoryId] then
        return false
    end

    local oldOwnerId = State.territories[territoryId].ownerId
    if oldOwnerId == newOwnerId then
        return true
    end

    if oldOwnerId and State.guilds[oldOwnerId] then
        State.guilds[oldOwnerId].territories[territoryId] = nil
    end

    if newOwnerId and State.guilds[newOwnerId] then
        State.guilds[newOwnerId].territories[territoryId] = {
            claimedAt = os.time(),
            benefit = State.territories[territoryId].defaultBenefit
        }
    end

    State.territories[territoryId].ownerId = newOwnerId
    State.territories[territoryId].claimedAt = os.time()

    State.guildsChanged = true
    return true
end

--[[ Vault Functions ]]
function GuildService:DepositVault(player, resourceType, resourceId, amount)
    if not player then
        return false, "Invalid player"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    if not Modules.Guild:CheckPermission(memberRank, "BANK_DEPOSIT") then
        return false, "You don't have permission to deposit to the guild vault"
    end

    if resourceType == "CURRENCY" then
        if not amount or amount <= 0 then
            return false, "Invalid amount"
        end

        local playerBalance = Services.Economy:GetBalance(userId) or 0
        if playerBalance < amount then
            return false, "You don't have enough Umbrels"
        end

        local success = Services.Economy:RemoveCurrency(userId, amount, {
            type = "guild_deposit",
            guildId = guildId
        })

        if not success then
            return false, "Failed to remove currency from your account"
        end

        guild.vault.umbrels = guild.vault.umbrels + amount
        guild.members[userId].contribution = (guild.members[userId].contribution or 0) + amount

        Services.Event:Fire("Guild.Vault", {
            action = "DEPOSIT",
            resourceType = "CURRENCY",
            player = player,
            guildId = guildId,
            amount = amount,
            newTotal = guild.vault.umbrels
        })

    elseif resourceType == "ITEM" then
        if not resourceId then
            return false, "Invalid item"
        end

        amount = amount or 1

        if not Services.Inventory:GetItem(player, resourceId, amount) then
            return false, "You don't have enough of this item"
        end

        local success = Services.Inventory:RemoveItem(player, resourceId, amount)
        if not success then
            return false, "Failed to remove item from inventory"
        end

        guild.vault.items[resourceId] = (guild.vault.items[resourceId] or 0) + amount

        Services.Trade:TransferOwnership(resourceId, guildId, "FACTION")

        Services.Event:Fire("Guild.Vault", {
            action = "DEPOSIT",
            resourceType = "ITEM",
            player = player,
            guildId = guildId,
            itemId = resourceId,
            amount = amount
        })
    else
        return false, "Invalid resource type"
    end

    State.guildsChanged = true
    return true
end

function GuildService:WithdrawVault(player, resourceType, resourceId, amount)
    if not player then
        return false, "Invalid player"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    if not Modules.Guild:CheckPermission(memberRank, "BANK_WITHDRAW") then
        return false, "You don't have permission to withdraw from the guild vault"
    end

    if resourceType == "CURRENCY" then
        if not amount or amount <= 0 then
            return false, "Invalid amount"
        end

        if guild.vault.umbrels < amount then
            return false, "Not enough Umbrels in the guild vault"
        end

        local success = Services.Economy:AddCurrency(userId, amount, {
            type = "guild_withdrawal",
            guildId = guildId
        })

        if not success then
            return false, "Failed to add currency to your account"
        end

        guild.vault.umbrels = guild.vault.umbrels - amount

        Services.Event:Fire("Guild.Vault", {
            action = "WITHDRAW",
            resourceType = "CURRENCY",
            player = player,
            guildId = guildId,
            amount = amount,
            newTotal = guild.vault.umbrels
        })

    elseif resourceType == "ITEM" then
        if not resourceId then
            return false, "Invalid item"
        end

        amount = amount or 1

        if not guild.vault.items[resourceId] or guild.vault.items[resourceId] < amount then
            return false, "Not enough of this item in the guild vault"
        end

        local success = Services.Inventory:AddItem(player, resourceId, amount, guildId, {
            source = "guild_vault",
            guildId = guildId,
            withdrawnAt = os.time()
        })

        if not success then
            return false, "Failed to add item to your inventory"
        end

        guild.vault.items[resourceId] = guild.vault.items[resourceId] - amount
        if guild.vault.items[resourceId] <= 0 then
            guild.vault.items[resourceId] = nil
        end

        Services.Event:Fire("Guild.Vault", {
            action = "WITHDRAW",
            resourceType = "ITEM",
            player = player,
            guildId = guildId,
            itemId = resourceId,
            amount = amount
        })
    else
        return false, "Invalid resource type"
    end

    State.guildsChanged = true
    return true
end

function GuildService:GetVault(player)
    if not player then
        return false, "Invalid player"
    end

    local userId = tostring(player.UserId)
    local guildId = self:GetPlayer(player)

    if not guildId then
        return false, "You are not in a guild"
    end

    local guild = self:GetGuild(guildId)
    if not guild then
        return false, "Guild not found"
    end

    local memberRank = guild.members[userId] and guild.members[userId].rank
    if not memberRank then
        return false, "You are not a member of this guild"
    end

    local canSeeVault = Modules.Guild:CheckPermission(memberRank, "BANK_DEPOSIT") or
                        Modules.Guild:CheckPermission(memberRank, "BANK_WITHDRAW")

    if not canSeeVault then
        return false, "You don't have permission to view the guild vault"
    end

    local vaultItems = {}
    for itemId, quantity in pairs(guild.vault.items) do
        local itemTemplate = Services.Inventory:GetTemplate(itemId)
        local itemName = (itemTemplate and itemTemplate.name) or itemId

        table.insert(vaultItems, {
            id = itemId,
            name = itemName,
            quantity = quantity
        })
    end

    return true, {
        umbrels = guild.vault.umbrels,
        items = vaultItems
    }
end

return GuildService
