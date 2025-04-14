--[[ GuildModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local GuildModule = {}

--[[ Types ]]
export type Guild = {
    id: string,
    name: string,
    description: string,
    createdAt: number,
    createdBy: string,
    level: number,
    xp: number,
    leader: string,
    members: {[string]: GuildMember},
    banner: GuildBanner,
    vault: GuildVault,
    messageBoard: GuildMessageBoard,
    territories: {[string]: GuildTerritory},
    wars: {[string]: GuildWar}
}

export type GuildMember = {
    joinedAt: number,
    rank: string,
    contribution: number,
    lastActive: number?
}

export type GuildBanner = {
    shape: string,
    primaryColor: Color3,
    secondaryColor: Color3,
    symbol: string?,
    pattern: string?
}

export type GuildVault = {
    umbrels: number,
    items: {[string]: number}
}

export type GuildMessageBoard = {
    pinned: string,
    messages: {GuildMessage}
}

export type GuildMessage = {
    id: string,
    author: string,
    content: string,
    timestamp: number,
    pinned: boolean?
}

export type GuildTerritory = {
    claimedAt: number,
    benefit: string
}

export type GuildWar = {
    againstId: string,
    territoryId: string?,
    startedAt: number,
    role: string
}

--[[ Constants ]]
GuildModule.RANKS = {
    LEADER = {
        id = "LEADER",
        name = "Guild Leader",
        level = 5,
        permissions = {"ALL"}
    },
    COUNCIL = {
        id = "COUNCIL",
        name = "Council Member",
        level = 4,
        permissions = {"INVITE", "KICK", "EDIT_MOTD", "BANK_DEPOSIT", "BANK_WITHDRAW", "WAR_PARTICIPATE"}
    },
    OFFICER = {
        id = "OFFICER",
        name = "Officer",
        level = 4,
        permissions = {"INVITE", "KICK", "EDIT_MOTD", "BANK_WITHDRAW", "BANK_DEPOSIT", "WAR_DECLARE"}
    },
    VETERAN = {
        id = "VETERAN",
        name = "Veteran",
        level = 3,
        permissions = {"INVITE", "BANK_DEPOSIT", "WAR_PARTICIPATE"}
    },
    MEMBER = {
        id = "MEMBER",
        name = "Member",
        level = 2,
        permissions = {"BANK_DEPOSIT", "WAR_PARTICIPATE"}
    },
    RECRUIT = {
        id = "RECRUIT",
        name = "Recruit",
        level = 1,
        permissions = {"WAR_PARTICIPATE"}
    }
}

GuildModule.BANNER_SHAPES = {
    "TRIANGLE",
    "RECTANGLE",
    "TATTERED",
    "ROUNDED",
    "SHIELD"
}

GuildModule.TERRITORY_BENEFITS = {
    RESOURCE_BOOST = {
        id = "RESOURCE_BOOST",
        name = "Resource Boost",
        description = "Increases resource gathering by 15%"
    },
    HEALTH_REGEN = {
        id = "HEALTH_REGEN",
        name = "Health Regeneration",
        description = "Increases health regeneration by 10%"
    },
    DAMAGE_BOOST = {
        id = "DAMAGE_BOOST",
        name = "Damage Boost",
        description = "Increases damage by 5%"
    }
}

GuildModule.WAR_STAGES = {
    PREPARATION = {
        id = "PREPARATION",
        name = "Preparation",
        description = "Prepare for battle by recruiting members and gathering resources",
        duration = 86400
    },
    BATTLE = {
        id = "BATTLE",
        name = "Battle",
        description = "Fight for control of territory",
        duration = 86400
    }
}

GuildModule.WAR_TYPES = {
    OPEN_WORLD = {
        id = "OPEN_WORLD",
        name = "Open World Battle",
        description = "Territory control through optional PvP combat",
        minPlayers = 5,
        maxPlayers = 25
    },
    SKIRMISH = {
        id = "SKIRMISH",
        name = "Guild Skirmish",
        description = "Instanced battle with set teams and win conditions",
        minPlayers = 3,
        maxPlayers = 10
    },
    BANNER_SIEGE = {
        id = "BANNER_SIEGE",
        name = "Banner Siege",
        description = "Defend or attack the enemy's war banner",
        minPlayers = 8,
        maxPlayers = 20
    }
}

GuildModule.LEVEL_XP_REQUIREMENTS = {
    [1] = 0,
    [2] = 2000,
    [3] = 5000,
    [4] = 10000,
    [5] = 20000,
    [6] = 35000,
    [7] = 60000,
    [8] = 100000,
    [9] = 150000,
    [10] = 250000
}

GuildModule.LEVEL_MEMBER_LIMITS = {
    [1] = 15,
    [2] = 20,
    [3] = 25,
    [4] = 30,
    [5] = 35,
    [6] = 40,
    [7] = 45,
    [8] = 50,
    [9] = 75,
    [10] = 100
}

--[[ Templates ]]
GuildModule.Templates = {
    Guild = function(params: {
        id: string,
        name: string,
        description: string?,
        createdBy: string,
        bannerShape: string?,
        primaryColor: Color3?,
        secondaryColor: Color3?,
        symbol: string?,
        pattern: string?,
        motd: string?
    }): Guild
        return {
            id = params.id,
            name = params.name,
            description = params.description or "A new guild",
            createdAt = os.time(),
            createdBy = params.createdBy,
            level = 1,
            xp = 0,
            leader = params.createdBy,
            members = {
                [params.createdBy] = {
                    joinedAt = os.time(),
                    rank = "LEADER",
                    contribution = 0,
                    lastActive = os.time()
                }
            },
            banner = {
                shape = params.bannerShape or "RECTANGLE",
                primaryColor = params.primaryColor or Color3.fromRGB(200, 200, 200),
                secondaryColor = params.secondaryColor or Color3.fromRGB(100, 100, 100),
                symbol = params.symbol or "DEFAULT",
                pattern = params.pattern
            },
            vault = {
                umbrels = 0,
                items = {}
            },
            messageBoard = {
                pinned = params.motd or "Welcome to " .. params.name .. "!",
                messages = {}
            },
            territories = {},
            wars = {}
        }
    end,

    War = function(params: {
        id: string,
        attackerId: string,
        defenderId: string,
        territoryId: string?,
        warType: string
    }): {
        id: string,
        attackerId: string,
        defenderId: string,
        startedAt: number,
        territoryId: string?,
        warType: string,
        stages: {any},
        scores: {[string]: number}
    }
        return {
            id = params.id,
            attackerId = params.attackerId,
            defenderId = params.defenderId,
            startedAt = os.time(),
            territoryId = params.territoryId,
            warType = params.warType or "OPEN_WORLD",
            stages = {
                {
                    id = "PREPARATION",
                    startAt = os.time(),
                    endAt = os.time() + GuildModule.WAR_STAGES.PREPARATION.duration,
                    status = "ACTIVE"
                },
                {
                    id = "BATTLE",
                    startAt = os.time() + GuildModule.WAR_STAGES.PREPARATION.duration,
                    endAt = os.time() + GuildModule.WAR_STAGES.PREPARATION.duration + GuildModule.WAR_STAGES.BATTLE.duration,
                    status = "PENDING"
                }
            },
            scores = {
                [params.attackerId] = 0,
                [params.defenderId] = 0
            }
        }
    end,

    Message = function(params: {
        author: string,
        content: string,
        pinned: boolean?
    }): GuildMessage
        return {
            id = tostring(os.time()) .. "_" .. math.random(1000, 9999),
            author = params.author,
            content = params.content,
            timestamp = os.time(),
            pinned = params.pinned or false
        }
    end
}

--[[ Utility Functions ]]
function GuildModule:GetLimit(level: number): number
    return GuildModule.LEVEL_MEMBER_LIMITS[level] or GuildModule.LEVEL_MEMBER_LIMITS[1]
end

function GuildModule:GetExperience(currentLevel: number): number
    return GuildModule.LEVEL_XP_REQUIREMENTS[currentLevel + 1] or math.huge
end

function GuildModule:CheckPermission(rankId: string, permission: string): boolean
    if not GuildModule.RANKS[rankId] then
        return false
    end

    if table.find(GuildModule.RANKS[rankId].permissions, "ALL") then
        return true
    end

    return table.find(GuildModule.RANKS[rankId].permissions, permission) ~= nil
end

function GuildModule:GetBenefit(benefitId: string): {id: string, name: string, description: string}?
    return GuildModule.TERRITORY_BENEFITS[benefitId]
end

return GuildModule