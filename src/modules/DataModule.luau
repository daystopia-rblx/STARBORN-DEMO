--[[ DataModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-07
]]
local DataModule = {}

DataModule.Scopes = {
    GLOBAL = "global",
    MONTHLY = "monthly",
    WEEKLY = "weekly",
    DAILY = "daily"
}

DataModule.Types = {
    PLAYER = "PlayerData"
}

DataModule.MetaTemplates = {
    Profile = {
        Created = 0,
        LastUpdate = 0,
        LastServer = "",
        SessionTime = 0,
        PlayTime = 0,
        Analytics = {
            JoinCount = 0,
            LastJoinTime = 0,
            AverageSessionTime = 0,
            Platform = "",
            Region = ""
        }
    },
    Session = {
        StartTime = 0,
        LastSave = 0,
        SaveCount = 0,
        ServerJobId = "",
        LoadTime = 0
    }
}

DataModule.Templates = {
    PlayerData = {
        stats = {
            health = 100,
            stamina = 100,
            level = 1,
            experience = 0
        },

        settings = {
            keybinds = {}
        },

        world = {
            checkpoint = {
                type = nil,
                position = nil,
                lastActivated = 0
            },
            discoveries = {},
            quests = {
                active = {},
                completed = {}
            }
        }
    }
}

DataModule.Validation = {
    PlayerData = {
        required = {"stats", "skills", "equipment", "progress", "settings", "world"},
        types = {
            stats = "table",
            skills = "table",
            equipment = "table",
            progress = "table",
            settings = "table",
            world = "table"
        }
    }
}

return DataModule