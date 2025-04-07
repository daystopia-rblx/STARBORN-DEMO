--[[ SkillModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-07
]]
local SkillModule = {}

export type Skill = {
    id: string,
    name: string,
    description: string,
    category: string,
    type: string,
    rarity: string,
    requirements: {
        level: number?,
        stats: {[string]: number}?,
        skills: {string}?,
        conditions: {(player: Player) -> boolean}?
    }?,
    effects: {[string]: {
        type: string,
        value: number | ((player: Player) -> number)
    }}?,
    cooldown: number?,
    manaCost: number?,
    staminaCost: number?,
    isPassive: boolean,
    metadata: {[string]: any}?
}

SkillModule.Constants = {
    CATEGORIES = {
        COMBAT = "COMBAT",
        MOVEMENT = "MOVEMENT",
        UTILITY = "UTILITY",
        RESONANCE = "RESONANCE",
        OATH = "OATH",
        MURMUR = "MURMUR"
    },

    TYPES = {
        ACTIVE = "ACTIVE",
        PASSIVE = "PASSIVE",
        STANCE = "STANCE",
        TECHNIQUE = "TECHNIQUE"
    },

    RARITIES = {
        COMMON = "COMMON",
        UNCOMMON = "UNCOMMON",
        RARE = "RARE",
        LEGENDARY = "LEGENDARY"
    },

    MAX_ACTIVE_SKILLS = 8,
    MAX_PASSIVE_SKILLS = 4,
    SKILL_POINTS_PER_LEVEL = 2
}

SkillModule.Templates = {
    -- Combat Skills
    PERFECT_PARRY = {
        id = "PERFECT_PARRY",
        name = "Perfect Parry",
        description = "Perfectly timed parries restore posture and grant a brief damage boost",
        category = "COMBAT",
        type = "PASSIVE",
        rarity = "COMMON",
        requirements = {
            level = 5
        },
        effects = {
            POSTURE_RESTORE = {
                type = "ADD",
                value = 20
            },
            DAMAGE_BOOST = {
                type = "MULTIPLY",
                value = 1.2
            }
        },
        isPassive = true,
        metadata = {
            duration = 3,
            parryWindow = 0.2
        }
    },

    ROLL_MASTERY = {
        id = "ROLL_MASTERY",
        name = "Roll Mastery",
        description = "Reduces stamina cost of rolling and grants brief invulnerability",
        category = "MOVEMENT",
        type = "PASSIVE",
        rarity = "UNCOMMON",
        requirements = {
            level = 10,
            stats = {
                STAMINA = 20
            }
        },
        effects = {
            ROLL_STAMINA_COST = {
                type = "MULTIPLY",
                value = 0.7
            }
        },
        isPassive = true,
        metadata = {
            iFrames = 0.3
        }
    },

    RESONANT_STRIKE = {
        id = "RESONANT_STRIKE",
        name = "Resonant Strike",
        description = "Channel your resonance into a powerful strike",
        category = "RESONANCE",
        type = "ACTIVE",
        rarity = "RARE",
        requirements = {
            level = 20,
            stats = {
                RESONANCE = 50
            }
        },
        effects = {
            DAMAGE = {
                type = "MULTIPLY",
                value = function(player)
                    local resonance = player:GetAttribute("RESONANCE") or 0
                    return 1 + (resonance / 100)
                end
            }
        },
        cooldown = 15,
        staminaCost = 40,
        isPassive = false,
        metadata = {
            animation = "resonant_strike",
            particles = "resonance_burst"
        }
    },

    BLOOD_OATH = {
        id = "BLOOD_OATH",
        name = "Blood Oath",
        description = "Sacrifice health to gain immense power",
        category = "OATH",
        type = "STANCE",
        rarity = "LEGENDARY",
        requirements = {
            level = 30,
            stats = {
                HEALTH = 100,
                BLOOD = 80
            }
        },
        effects = {
            DAMAGE = {
                type = "MULTIPLY",
                value = 1.5
            },
            HEALTH_DRAIN = {
                type = "ADD",
                value = -5
            }
        },
        cooldown = 60,
        isPassive = false,
        metadata = {
            duration = 20,
            particles = "blood_aura"
        }
    },

    SHADOW_STEP = {
        id = "SHADOW_STEP",
        name = "Shadow Step",
        description = "Quick dash that leaves afterimages",
        category = "MOVEMENT",
        type = "TECHNIQUE",
        rarity = "UNCOMMON",
        requirements = {
            level = 15,
            stats = {
                STAMINA = 30
            }
        },
        cooldown = 8,
        staminaCost = 25,
        isPassive = false,
        metadata = {
            distance = 10,
            afterimages = 3
        }
    },

    WEAPON_MASTER = {
        id = "WEAPON_MASTER",
        name = "Weapon Master",
        description = "Gain increased damage with all weapon types",
        category = "COMBAT",
        type = "PASSIVE",
        rarity = "RARE",
        requirements = {
            level = 25
        },
        effects = {
            WEAPON_DAMAGE = {
                type = "MULTIPLY",
                value = 1.15
            }
        },
        isPassive = true
    }
}

SkillModule.CategoryGroups = {
    COMBAT = {
        "PERFECT_PARRY",
        "WEAPON_MASTER"
    },
    MOVEMENT = {
        "ROLL_MASTERY",
        "SHADOW_STEP"
    },
    RESONANCE = {
        "RESONANT_STRIKE"
    },
    OATH = {
        "BLOOD_OATH"
    }
}

function SkillModule.GetSkill(id: string): Skill?
    return SkillModule.Templates[id:upper()]
end

return SkillModule
