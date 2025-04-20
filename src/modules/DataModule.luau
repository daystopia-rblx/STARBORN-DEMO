--[[ DataModule
    @author @Daystopia
    @version 1.0.3
    @date 2025-04-12
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
                id = nil,
                type = nil,
                location = nil,
                position = nil,
                lastActivated = 0
            },
            discoveries = {}
        },

        relationships = {},

        memory = {},

        primaryFaction = nil,
        factions = {},
        factionViolations = {},

        economy = {
            balance = 50,
            lastUpdated = 0,
            transactions = {},
            multipliers = {}
        },

        quests = {
            active = {},
            completed = {},
            failed = {},
            lastUpdated = 0,
            tracked = nil
        },

        skills = {
            weapon_forging = {
                level = 1,
                experience = 0
            },
            armor_smithing = {
                level = 1,
                experience = 0
            },
            cooking = {
                level = 1,
                experience = 0
            },
            alchemy = {
                level = 1,
                experience = 0
            }
        },

        crafting = {
            discoveries = {}
        }
    },

    AdminData = {
        permissions = {},
        warnings = {},
        muted = nil,
        chatLogs = {},
        history = {},
        whitelist = {
            enabled = false,
            users = {},
            roles = {}
        },
        blacklist = {
            enabled = false,
            users = {}
        },
        lastUpdate = 0
    },

    FactionData = {
        factions = {},
        conflicts = {},
        lastUpdate = 0,
        version = "1.0.0"
    },

    CrimeData = {
        bounties = {},
        criminalRecords = {},
        mostWanted = {},
        recentCrimes = {},
        statistics = {
            totalBounties = 0,
            totalBountiesClaimed = 0,
            highestBounty = 0
        },
        lastUpdate = 0,
        version = "1.0.0"
    },

    QuestState = {
        id = nil,
        type = nil,
        status = nil,
        progress = {},
        branch = nil,
        startTime = 0,
        endTime = nil,
        participants = {},
        isTracked = false,
        failReason = nil
    },

    GuildData = {
        guilds = {},
        territories = {},
        wars = {},
        lastUpdate = 0,
        version = "1.0.0"
    }
}

DataModule.Validation = {
    PlayerData = {
        required = {"stats", "skills", "equipment", "progress", "settings", "world", "relationships", "memory", "economy", "quests"},
        types = {
            stats = "table",
            skills = "table",
            equipment = "table",
            progress = "table",
            settings = "table",
            world = "table",
            relationships = "table",
            memory = "table",
            economy = "table",
            quests = "table"
        }
    },

    AdminData = {
        required = {"permissions", "warnings"},
        types = {
            permissions = "table",
            warnings = "table",
            muted = "table",
            chatLogs = "table",
            history = "table"
        }
    }
}

return DataModule