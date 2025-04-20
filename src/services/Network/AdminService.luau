--[[ AdminService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-19
]]
local AdminService = {}

AdminService.Dependencies = {
    "Event",
    "Data"
}

AdminService.Modules = {
    "Data",
    "Admin"
}

AdminService.Events = {
    Command = { validate = true },
    Permission = { validate = true },
    Mute = { validate = true }
}

--[[ Services ]]
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local Services
local Modules

--[[ State ]]
local State = {
    permissions = {},
    whitelist = {
        enabled = false,
        users = {},
        roles = {}
    },
    blacklist = {
        enabled = false,
        users = {}
    },
    warnings = {},
    mutes = {},
    commandHistory = {},
    chatHistory = {}
}

--[[ Listeners ]]
AdminService.Listeners = {
    ["Data.Global"] = function(self, data)
        if data.key == Services.Data.GLOBAL_KEYS.ADMIN_DATA then
            local incomingData = data.data
            if incomingData and incomingData.lastUpdate and
               (not State.adminData or not State.adminData.lastUpdate or
                incomingData.lastUpdate > State.adminData.lastUpdate) then
                State.adminData = incomingData
                State.permissions = incomingData.permissions or {}
                State.whitelist = incomingData.whitelist or { enabled = false, users = {}, roles = {} }
                State.blacklist = incomingData.blacklist or { enabled = false, users = {}, roles = {} }
            end
        end
    end,

    ["Player.Join"] = function(self, data)
        local player = data.player
        if not player then return end

        if self:CheckBan(player) then
            player:Kick("You are banned from this game: " .. self:GetReason(player))
            return
        end

        if self:ValidateList("whitelist") then
            if not self:CheckList(player, "whitelist") then
                player:Kick("You are not whitelisted for this game.")
                return
            end
        else
            if self:ValidateList("blacklist") and self:CheckList(player, "blacklist") then
                player:Kick("You are blacklisted from this game: " .. self:GetReason(player))
                return
            end
        end

        self:SetupPermissions(player)
    end,

    ["Admin.Command"] = function(self, playerWhoFired, data)
        if not data or not data.command then return end

        local player = playerWhoFired
        if not player or not player:IsA("Player") then return end

        local success, message = self:ProcessCommand(player, data.command)

        Services.Event:FireTo(player, "Admin.Command", {
            success = success,
            message = message
        })
    end,

    ["Admin.Mute"] = function(self, playerWhoFired, data)
        local playerToCheck = playerWhoFired

        if not playerToCheck or not playerToCheck:IsA("Player") then return end

        local isMuted = self:CheckMute(playerToCheck)
        local muteData = nil

        if isMuted then
            local userId = tostring(playerToCheck.UserId)
            muteData = State.mutes[userId]
        end

        Services.Event:FireTo(playerToCheck, "Admin.Mute", {
            isMuted = isMuted,
            expiry = muteData and muteData.expiry or nil,
            reason = muteData and muteData.reason or nil
        })
    end
}

--[[ Core Functions ]]
function AdminService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function AdminService:Start()
    task.spawn(function()
        while task.wait(600) do
            self:CleanupExpiry()
        end
    end)
    return true
end

--[[ Command Functions ]]
function AdminService:BanPlayer(admin, target, reason, duration)
    if not self:ValidatePermission(admin, "ban") then
        return false, "Insufficient permissions to ban players"
    end

    if not target or not target:IsA("Player") then
        return false, "Invalid target player"
    end

    duration = duration or Modules.Admin.Constants.DEFAULT_BAN_DURATION
    if type(duration) ~= "number" or duration < 0 then
        duration = Modules.Admin.Constants.DEFAULT_BAN_DURATION
    end

    local expiry = os.time() + duration
    local targetId = tostring(target.UserId)
    local adminId = admin and tostring(admin.UserId) or "System"

    State.blacklist.users[targetId] = {
        reason = reason or "No reason provided",
        expiry = expiry,
        admin = adminId,
        timestamp = os.time()
    }

    local adminData = Services.Data:GetGlobal("AdminData")
    adminData.blacklist.users[targetId] = State.blacklist.users[targetId]
    Services.Data:SetGlobal("AdminData", adminData)

    self:LogCommand("ban", adminId, targetId, {
        reason = reason,
        duration = duration,
        expiry = expiry
    })

    target:Kick("You have been banned: " .. (reason or "No reason provided"))

    return true, "Player banned successfully"
end

function AdminService:KickPlayer(admin, target, reason)
    if not self:ValidatePermission(admin, "kick") then
        return false, "Insufficient permissions to kick players"
    end

    if not target or not target:IsA("Player") then
        return false, "Invalid target player"
    end

    local targetId = tostring(target.UserId)
    local adminId = admin and tostring(admin.UserId) or "System"

    self:LogCommand("kick", adminId, targetId, {
        reason = reason
    })

    target:Kick("You have been kicked: " .. (reason or "No reason provided"))

    return true, "Player kicked successfully"
end

function AdminService:WarnPlayer(admin, target, message)
    if not self:ValidatePermission(admin, "warn") then
        return false, "Insufficient permissions to warn players"
    end

    if not target or not target:IsA("Player") then
        return false, "Invalid target player"
    end

    local targetId = tostring(target.UserId)
    local adminId = admin and tostring(admin.UserId) or "System"

    State.warnings[targetId] = State.warnings[targetId] or {}

    table.insert(State.warnings[targetId], {
        message = message or "No reason provided",
        timestamp = os.time(),
        admin = adminId
    })

    if #State.warnings[targetId] >= Modules.Admin.Constants.MAX_WARNINGS then
        local reason = "Exceeded maximum warnings"
        self:KickPlayer(admin, target, reason)
    end

    Services.Data:UpdateData(targetId, "AdminData", function(data)
        data = data or {}
        data.warnings = State.warnings[targetId]
        return data
    end)

    self:LogCommand("warn", adminId, targetId, {
        message = message,
        warningCount = #State.warnings[targetId]
    })

    return true, "Player warned successfully"
end

function AdminService:MutePlayer(admin, target, reason, duration)
    if not self:ValidatePermission(admin, "mute") then
        return false, "Insufficient permissions to mute players"
    end

    if not target or not target:IsA("Player") then
        return false, "Invalid target player"
    end

    duration = duration or Modules.Admin.Constants.DEFAULT_MUTE_DURATION
    if type(duration) ~= "number" or duration < 0 then
        duration = Modules.Admin.Constants.DEFAULT_MUTE_DURATION
    end

    local expiry = os.time() + duration
    local targetId = tostring(target.UserId)
    local adminId = admin and tostring(admin.UserId) or "System"

    State.mutes[targetId] = {
        expiry = expiry,
        reason = reason or "No reason provided",
        admin = adminId,
        timestamp = os.time()
    }

    Services.Data:UpdateData(targetId, "AdminData", function(data)
        data = data or {}
        data.muted = State.mutes[targetId]
        return data
    end)

    self:LogCommand("mute", adminId, targetId, {
        reason = reason,
        duration = duration,
        expiry = expiry
    })

    return true, "Player muted successfully"
end

function AdminService:UnmutePlayer(admin, target)
    if not self:ValidatePermission(admin, "unmute") then
        return false, "Insufficient permissions to unmute players"
    end

    if not target or not target:IsA("Player") then
        return false, "Invalid target player"
    end

    local targetId = tostring(target.UserId)
    local adminId = admin and tostring(admin.UserId) or "System"

    if not State.mutes[targetId] then
        return false, "Player is not muted"
    end

    State.mutes[targetId] = nil

    Services.Data:UpdateData(targetId, "AdminData", function(data)
        data = data or {}
        data.muted = nil
        return data
    end)

    self:LogCommand("unmute", adminId, targetId, {})

    return true, "Player unmuted successfully"
end

--[[ Permission Functions ]]
function AdminService:SetupPermissions(player)
    if not player then return end

    local userId = tostring(player.UserId)

    if State.permissions[userId] then
        return
    end

    local success, groupInfo = pcall(function()
        return GroupService:GetGroupsAsync(player.UserId)
    end)
end

function AdminService:SetPermission(admin, target, level)
    if not self:ValidatePermission(admin, "permissions") then
        return false, "Insufficient permissions to modify permissions"
    end

    if not target then
        return false, "Invalid target player"
    end

    local targetId
    if typeof(target) == "Instance" and target:IsA("Player") then
        targetId = tostring(target.UserId)
    else
        targetId = tostring(target)
    end

    local adminId = admin and tostring(admin.UserId) or "System"

    State.permissions[targetId] = level

    local adminData = Services.Data:GetGlobal("AdminData")
    adminData.permissions = adminData.permissions or {}
    adminData.permissions[targetId] = level
    Services.Data:SetGlobal("AdminData", adminData)

    self:LogCommand("setpermission", adminId, targetId, {
        level = level
    })

    Services.Event:Fire("Admin.Permission", {
        admin = admin,
        targetId = targetId,
        level = level
    })

    return true, "Permission level set successfully"
end

function AdminService:GetPermission(player)
    if not player then return 0 end

    local userId = typeof(player) == "Instance"
        and tostring(player.UserId)
        or tostring(player)

    return State.permissions[userId] or 0
end

function AdminService:ValidatePermission(player, command)
    if not player then return false end

    if player == "System" then return true end

    local level = self:GetPermission(player)

    for roleName, roleData in pairs(Modules.Admin.PERMISSION_LEVELS) do
        if level >= roleData.level then
            for _, cmd in ipairs(roleData.commands) do
                if cmd == "*" or cmd == command then
                    return true
                end
            end
        end
    end

    return false
end

--[[ List Functions ]]
function AdminService:AddToList(admin, target, listType, isGroup, data)
    if not self:ValidatePermission(admin, "permissions") then
        return false, "Insufficient permissions to modify " .. listType
    end

    if not listType or (listType ~= "whitelist" and listType ~= "blacklist") then
        return false, "Invalid list type specified"
    end

    local adminId = admin and tostring(admin.UserId) or "System"
    local targetId = ""

    if isGroup then
        local isValidFormat = false

        local groupIdStr, roleIdStr = target:match("(%d+)_(%d+)$")
        if groupIdStr and roleIdStr then
            isValidFormat = true
        end

        if not isValidFormat then
            local groupId = target:match("(%d+)_%*$")
            if groupId then
                isValidFormat = true
            end
        end

        if not isValidFormat then
            local groupId, minRank = target:match("(%d+)_(%d+)%+$")
            if groupId and minRank then
                isValidFormat = true
            end
        end

        if not isValidFormat then
            return false, "Invalid group role format. Use: 'groupId_roleId', 'groupId_*', or 'groupId_10+'"
        end

        State[listType].roles = State[listType].roles or {}
        State[listType].roles[target] = data or true
        targetId = target
    else
        targetId = typeof(target) == "Instance"
            and tostring(target.UserId)
            or tostring(target)

        if listType == "blacklist" then
            data = data or {
                reason = "No reason provided",
                expiry = 0,
                admin = adminId,
                timestamp = os.time()
            }
            State[listType].users[targetId] = data
        else
            State[listType].users[targetId] = data or true
        end
    end

    local adminData = Services.Data:GetGlobal("AdminData")
    adminData[listType] = adminData[listType] or { enabled = false, users = {}, roles = {} }

    if isGroup then
        adminData[listType].roles[target] = data or true
    else
        adminData[listType].users[targetId] = data or true
    end

    Services.Data:SetGlobal("AdminData", adminData)

    self:LogCommand(listType .. "_add", adminId, tostring(target), {
        isGroup = isGroup,
        data = data
    })

    return true, "Added to " .. listType .. " successfully"
end

function AdminService:RemoveFromList(admin, target, listType, isGroup)
    if not self:ValidatePermission(admin, "permissions") then
        return false, "Insufficient permissions to modify " .. listType
    end

    if not listType or (listType ~= "whitelist" and listType ~= "blacklist") then
        return false, "Invalid list type specified"
    end

    local adminId = admin and tostring(admin.UserId) or "System"

    if isGroup then
        if State[listType].roles then
            State[listType].roles[target] = nil
        end
    else
        local targetId = typeof(target) == "Instance"
            and tostring(target.UserId)
            or tostring(target)

        State[listType].users[targetId] = nil
    end

    local adminData = Services.Data:GetGlobal("AdminData")
    if adminData[listType] then
        if isGroup then
            if adminData[listType].roles then
                adminData[listType].roles[target] = nil
            end
        else
            local targetId = typeof(target) == "Instance"
                and tostring(target.UserId)
                or tostring(target)

            adminData[listType].users[targetId] = nil
        end

        Services.Data:SetGlobal("AdminData", adminData)
    end

    self:LogCommand(listType .. "_remove", adminId, tostring(target), {
        isGroup = isGroup
    })

    return true, "Removed from " .. listType .. " successfully"
end

function AdminService:SetList(admin, listType, enabled)
    if not self:ValidatePermission(admin, "permissions") then
        return false, "Insufficient permissions to modify " .. listType
    end

    if not listType or (listType ~= "whitelist" and listType ~= "blacklist") then
        return false, "Invalid list type specified"
    end

    local adminId = admin and tostring(admin.UserId) or "System"

    local adminData = Services.Data:GetGlobal("AdminData")
    adminData[listType] = adminData[listType] or { enabled = false, users = {}, roles = {} }
    adminData[listType].enabled = enabled

    Services.Data:SetGlobal("AdminData", adminData)

    self:LogCommand(listType .. "_toggle", adminId, "system", {
        enabled = enabled
    })

    return true, listType .. " " .. (enabled and "enabled" or "disabled") .. " successfully"
end

function AdminService:ValidateList(listType)
    if not listType or (listType ~= "whitelist" and listType ~= "blacklist") then
        return false
    end

    local adminData = Services.Data:GetGlobal("AdminData")
    return adminData and adminData[listType] and adminData[listType].enabled or false
end

function AdminService:CheckList(player, listType)
    if not player or not listType or (listType ~= "whitelist" and listType ~= "blacklist") then
        return false
    end

    local userId = tostring(player.UserId)
    local adminData = Services.Data:GetGlobal("AdminData")

    if not adminData or not adminData[listType] then
        return false
    end

    if adminData[listType].users[userId] then
        if listType == "blacklist" then
            local banData = adminData[listType].users[userId]
            if banData and (banData.expiry == 0 or banData.expiry > os.time()) then
                return true
            end
            return false
        end
        return true
    end

    if listType == "whitelist" and adminData[listType].roles then
        local success, groupInfo = pcall(function()
            return GroupService:GetGroupsAsync(player.UserId)
        end)

        if success then
            for _, group in ipairs(groupInfo) do
                local exactRoleKey = tostring(group.Id) .. "_" .. tostring(group.Rank)
                if adminData[listType].roles[exactRoleKey] then
                    return true
                end

                local wildcardRoleKey = tostring(group.Id) .. "_*"
                if adminData[listType].roles[wildcardRoleKey] then
                    return true
                end

                for roleKey, _ in pairs(adminData[listType].roles) do
                    local groupId, rankPlusStr = roleKey:match("(%d+)_(%d+)%+")
                    if groupId and rankPlusStr and tostring(group.Id) == groupId then
                        local minRank = tonumber(rankPlusStr)
                        if minRank and group.Rank >= minRank then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

--[[ Ban Functions ]]
function AdminService:CheckBan(player)
    return self:CheckList(player, "blacklist")
end

function AdminService:GetReason(player)
    if not player then return "Unknown reason" end

    local userId = tostring(player.UserId)

    local userBan = State.blacklist.users[userId]
    if userBan then
        return userBan.reason or "No reason provided"
    end

    return "Unknown reason"
end

--[[ Chat Functions ]]
function AdminService:HelpCommand(player, commandName)
    if not player then return false, "Invalid player" end

    local userPermission = self:GetPermission(player)
    local availableCommands = {}

    if commandName and commandName ~= "" then
        local command
        for _, cmd in pairs(Modules.Admin.Constants.COMMANDS) do
            if cmd.name:lower() == commandName:lower() then
                command = cmd
                break
            end
        end

        if not command then
            return false, "Command not found: " .. commandName
        end

        if userPermission < command.minPermission then
            return false, "You don't have permission to use this command"
        end

        return true, string.format("%s\n%s\n%s",
            command.syntax,
            command.description,
            "Required Permission: " .. command.minPermission
        )
    end

    for _, cmd in pairs(Modules.Admin.Constants.COMMANDS) do
        if userPermission >= cmd.minPermission then
            table.insert(availableCommands, cmd.syntax)
        end
    end

    if #availableCommands == 0 then
        return false, "You don't have permission to use any commands"
    end

    table.sort(availableCommands)
    return true, "Available commands:\n" .. table.concat(availableCommands, "\n")
end

function AdminService:ProcessCommand(player, message)
    if not player or not message then return false, "Invalid command" end

    local parsedCommand = Modules.Admin.ParseCommand(message)
    if not parsedCommand or not parsedCommand.command then return false, "Invalid command format" end

    local commandName = parsedCommand.command:lower()
    local targetName = parsedCommand.player
    local duration = parsedCommand.duration
    local reason = parsedCommand.reason

    local targetPlayer = nil
    if targetName then
        local targetNameLower = targetName:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == targetNameLower
               or p.DisplayName:lower() == targetNameLower
               or tostring(p.UserId):lower() == targetNameLower then
                targetPlayer = p
                break
            end
        end
    end

    local success, result

    if commandName == "help" then
        success, result = self:HelpCommand(player, targetName)
    elseif commandName == "ban" or commandName == "tempban" then
        if not targetPlayer then
            return false, "Target player not found"
        end
        local banDuration = 0
        if commandName == "tempban" and duration then
            banDuration = Modules.Admin.ParseTime(duration) or Modules.Admin.Constants.BAN_DURATIONS.DAY
        end
        success, result = self:BanPlayer(player, targetPlayer, reason, banDuration)
    elseif commandName == "kick" then
        if not targetPlayer then
            return false, "Target player not found"
        end
        success, result = self:KickPlayer(player, targetPlayer, reason)
    elseif commandName == "warn" then
        if not targetPlayer then
            return false, "Target player not found"
        end
        success, result = self:WarnPlayer(player, targetPlayer, reason or duration)
    elseif commandName == "mute" then
        if not targetPlayer then
            return false, "Target player not found"
        end
        local muteDuration = duration and Modules.Admin.ParseTime(duration) or Modules.Admin.Constants.MUTE_DURATIONS.MEDIUM
        success, result = self:MutePlayer(player, targetPlayer, reason, muteDuration)
    elseif commandName == "unmute" then
        if not targetPlayer then
            return false, "Target player not found"
        end
        success, result = self:UnmutePlayer(player, targetPlayer)
    elseif commandName == "setperm" or commandName == "permission" then
        if not targetPlayer then
            return false, "Target player not found"
        end
        local level = tonumber(duration)
        if level then
            success, result = self:SetPermission(player, targetPlayer, level)
        else
            success, result = false, "Invalid permission level"
        end
    elseif commandName == "listadd" then
        local listType = targetName
        local target = duration
        local listData = reason

        if not listType then
            return false, "List type required (whitelist/blacklist)"
        end

        if not target then
            return false, "Target required"
        end

        if listType == "whitelist" or listType == "blacklist" then
            local isGroup = target and target:match("(%d+)_(%d+)") ~= nil
            success, result = self:AddToList(player, target, listType, isGroup, listData)
        else
            success, result = false, "Invalid list type"
        end
    elseif commandName == "listremove" then
        local listType = targetName
        local target = duration

        if not listType then
            return false, "List type required (whitelist/blacklist)"
        end

        if not target then
            return false, "Target required"
        end

        if listType == "whitelist" or listType == "blacklist" then
            local isGroup = target and target:match("(%d+)_(%d+)") ~= nil
            success, result = self:RemoveFromList(player, target, listType, isGroup)
        else
            success, result = false, "Invalid list type"
        end
    elseif commandName == "listtoggle" then
        local listType = targetName
        local enabled = duration == "enable" or duration == "true" or duration == "1"

        if not listType then
            return false, "List type required (whitelist/blacklist)"
        end

        if listType == "whitelist" or listType == "blacklist" then
            success, result = self:SetList(player, listType, enabled)
        else
            success, result = false, "Invalid list type"
        end
    else
        return false, "Unknown command: " .. commandName
    end

    if success ~= nil then
        return success, result
    end

    return false, "Command processing failed"
end

function AdminService:ProcessChat(player, message)
    if not player then return end

    local userId = tostring(player.UserId)

    State.chatHistory[userId] = State.chatHistory[userId] or {}
    table.insert(State.chatHistory[userId], {
        message = message,
        timestamp = os.time()
    })

    if #State.chatHistory[userId] > Modules.Admin.Constants.MAX_CHAT_HISTORY then
        table.remove(State.chatHistory[userId], 1)
    end

    if self:CheckMute(player) then
        return false
    end

    return true
end

function AdminService:CheckMute(player)
    if not player then return false end

    local userId = tostring(player.UserId)

    local muteData = State.mutes[userId]
    if muteData and (muteData.expiry > os.time()) then
        return true
    end

    return false
end

--[[ Log Functions ]]
function AdminService:LogCommand(command, adminId, targetId, data)
    table.insert(State.commandHistory, {
        command = command,
        adminId = adminId,
        targetId = targetId,
        timestamp = os.time(),
        data = data
    })

    if #State.commandHistory > Modules.Admin.Constants.MAX_COMMAND_HISTORY then
        table.remove(State.commandHistory, 1)
    end
end

function AdminService:CleanupExpiry()
    local now = os.time()

    for userId, banData in pairs(State.blacklist.users) do
        if banData.expiry > 0 and banData.expiry < now then
            State.blacklist.users[userId] = nil
        end
    end

    for userId, muteData in pairs(State.mutes) do
        if muteData.expiry < now then
            State.mutes[userId] = nil
        end
    end

    for userId, warnings in pairs(State.warnings) do
        local validWarnings = {}
        for _, warning in ipairs(warnings) do
            if warning.timestamp > (now - Modules.Admin.Constants.WARNING_EXPIRY) then
                table.insert(validWarnings, warning)
            end
        end

        if #validWarnings > 0 then
            State.warnings[userId] = validWarnings
        else
            State.warnings[userId] = nil
        end
    end

    local adminData = Services.Data:GetGlobal("AdminData")
    adminData.blacklist.users = State.blacklist.users
    Services.Data:SetGlobal("AdminData", adminData)
end

return AdminService