--[[ AdminModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-19
]]
local AdminModule = {}

AdminModule.Constants = {
    PERMISSIONS = {
        FOUNDER = 255,
        LEAD_DEVELOPER = 6,
        DEVELOPER = 5,
        STAFF = 4,
        WAVE_1 = 3,
        TESTER = 2,
        OUTSIDER = 1
    },

    WHTIELIST = {
        USERS = {},
        ROLES = {
            ["33939088_255"] = true,
            ["33939088_6+"] = true,
            ["33939088_5"] = true,
        }
    },

    BLACKLIST = {
        USERS = {},
        ROLES = {}
    },

    COMMANDS = {
        HELP = {
            name = "help",
            syntax = "/help [command]",
            description = "Displays available commands or details about a specific command",
            minPermission = 0
        },
        BAN = {
            name = "ban",
            syntax = "/ban <player> [duration] [reason]",
            description = "Bans a player from the game",
            minPermission = 100
        },
        TEMPBAN = {
            name = "tempban",
            syntax = "/tempban <player> <duration> [reason]",
            description = "Temporarily bans a player from the game",
            minPermission = 100
        },
        KICK = {
            name = "kick",
            syntax = "/kick <player> [reason]",
            description = "Kicks a player from the game",
            minPermission = 50
        },
        WARN = {
            name = "warn",
            syntax = "/warn <player> <message>",
            description = "Issues a warning to a player",
            minPermission = 10
        },
        MUTE = {
            name = "mute",
            syntax = "/mute <player> [duration] [reason]",
            description = "Prevents a player from chatting",
            minPermission = 10
        },
        UNMUTE = {
            name = "unmute",
            syntax = "/unmute <player>",
            description = "Allows a muted player to chat again",
            minPermission = 10
        },
        LIST_ADD = {
            name = "listadd",
            syntax = "/listadd <whitelist|blacklist> <player|groupId_roleId> [reason] [duration]",
            description = "Adds a player or role to the specified list",
            minPermission = 100
        },
        LIST_REMOVE = {
            name = "listremove",
            syntax = "/listremove <whitelist|blacklist> <player|groupId_roleId>",
            description = "Removes a player or role from the specified list",
            minPermission = 100
        },
        LIST_TOGGLE = {
            name = "listtoggle",
            syntax = "/listtoggle <whitelist|blacklist> <enable|disable>",
            description = "Enables or disables the specified list",
            minPermission = 100
        },
        PERMISSIONS = {
            name = "setperm",
            syntax = "/setperm <player> <level>",
            description = "Sets a player's permission level",
            minPermission = 100
        }
    },

    BAN_DURATIONS = {
        HOUR = 3600,
        DAY = 86400,
        WEEK = 604800,
        MONTH = 2592000,
        PERMANENT = 0
    },

    MUTE_DURATIONS = {
        SHORT = 300,
        MEDIUM = 1800,
        LONG = 3600,
        DAY = 86400
    },

    MAX_WARNINGS = 3,
    WARNING_EXPIRY = 259200,
    MAX_BAN_HISTORY = 100,
    MAX_CHAT_HISTORY = 100,
    MAX_COMMAND_HISTORY = 100,
    GROUP_ID = 33939088,
    DEFAULT_BAN_DURATION = 86400,
    DEFAULT_MUTE_DURATION = 1800
}

AdminModule.PERMISSION_LEVELS = {
    FOUNDER = {
        level = 255,
        commands = {"*"}
    },
    LEAD_DEVELOPER = {
        level = 6,
        commands = {"*"}
    }
}

function AdminModule.FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return "Permanent"
    end

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60

    local result = ""
    if days > 0 then result = result .. days .. "d " end
    if hours > 0 then result = result .. hours .. "h " end
    if minutes > 0 then result = result .. minutes .. "m " end
    if seconds > 0 then result = result .. seconds .. "s" end

    return result
end

function AdminModule.ParseTime(timeString)
    if not timeString or timeString == "" then
        return nil
    end

    if timeString:lower() == "perm" or timeString:lower() == "permanent" then
        return 0
    end

    local total = 0
    local days = timeString:match("(%d+)d")
    local hours = timeString:match("(%d+)h")
    local minutes = timeString:match("(%d+)m")
    local seconds = timeString:match("(%d+)s")

    if days then total = total + tonumber(days) * 86400 end
    if hours then total = total + tonumber(hours) * 3600 end
    if minutes then total = total + tonumber(minutes) * 60 end
    if seconds then total = total + tonumber(seconds) end

    if total == 0 and timeString:match("%d+") then
        local justNumbers = timeString:match("(%d+)")
        if justNumbers then
            total = tonumber(justNumbers) * 60
        end
    end

    return total > 0 and total or nil
end

function AdminModule.ParseCommand(message)
    if not message or message == "" then return nil end

    local args = {}
    for arg in message:gmatch("%S+") do
        table.insert(args, arg)
    end

    if #args == 0 then return nil end

    local command = string.lower(args[1])
    if command:sub(1, 1) == "/" then
        command = command:sub(2)
    end

    return {
        command = command,
        player = args[2],
        duration = args[3],
        reason = table.concat(args, " ", 4)
    }
end

function AdminModule.GetRole(permissionLevel)
    if not permissionLevel then return nil end

    for roleName, roleData in pairs(AdminModule.PERMISSION_LEVELS) do
        if roleData.level <= permissionLevel then
            return {
                name = roleName,
                level = roleData.level,
                commands = roleData.commands
            }
        end
    end

    return nil
end

function AdminModule.ValidatePermission(permissionLevel, commandName)
    if not permissionLevel or not commandName then return false end

    local role = AdminModule.GetRole(permissionLevel)
    if not role then return false end

    for _, cmd in ipairs(role.commands) do
        if cmd == "*" or cmd:lower() == commandName:lower() then
            return true
        end
    end

    return false
end

return AdminModule