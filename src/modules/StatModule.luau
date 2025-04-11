--[[ StatModule
    @author @Daystopia
    @version 1.0.4
    @date 2025-04-10
]]
local StatModule = {}

--[[ Types ]]
export type Modifier = "MULTIPLY" | "ADD" | "PERCENT"

export type Stat = {
    current: number,
    baseValue: number,
    minValue: number?,
    maxValue: number?,

    regen: {
        amount: number,
        interval: number,
        condition: ((entity: any) -> boolean)?
    }?,
    decay: {
        amount: number,
        interval: number,
        condition: ((entity: any) -> boolean)?
    }?,
    lastUpdate: number?,

    modifiers: {[string]: {
        id: string,
        value: number,
        type: Modifier,
        duration: number?,
        source: string?
    }}?,

    category: string,
    displayName: string?,
    description: string?,
    icon: string?,
    color: Color3?,
    format: string?,

    multiplier: boolean?,
    fixed: boolean?,
    hidden: boolean?,

    dependencies: {[string]: number}?,
    effects: {[string]: {
        type: Modifier,
        value: number | ((entity: any) -> number)
    }}?,

    requirements: {
        level: number?,
        progress: number?,
        stats: {[string]: number}?,
        conditions: {[string]: (entity: any) -> boolean}?
    }?,

    syncProperties: {[string]: {
        class: string,
        property: string,
        condition: ((entity: any, value: any, metadata: any) -> boolean)?
    }}?,

    storageType: string?,
    playerSpecific: boolean?,
    metadata: {[string]: any}?
}

--[[ Constants ]]
StatModule.Constants = {
    -- System Constants
    CATEGORIES = {
        VITAL = "VITAL",
        RESOURCE = "RESOURCE",
        ATTRIBUTE = "ATTRIBUTE",
        COMBAT = "COMBAT",
        PROGRESSION = "PROGRESSION",
        SURVIVAL = "SURVIVAL",
        WEAPON = "WEAPON",
        MEMORY = "MEMORY",
        CRAFT = "CRAFT"
    },

    STORAGE_TYPE = {
        ATTRIBUTE = "ATTRIBUTE",
        PLAYER_DATA = "PLAYER_DATA",
        BOTH = "BOTH",
        WORLD_DATA = "WORLD_DATA"
    },

    OPERATIONS = {
        ADD = "add",
        SUBTRACT = "subtract",
        MULTIPLY = "multiply",
        DIVIDE = "divide",
        POWER = "power",
        ROOT = "root",
        SET = "set",
        MIN = "min",
        MAX = "max"
    },

    -- Progression Constants
    PROGRESSION = {
        MAX_LEVEL = 100,
        BASE_PROGRESS = 100,
        GROWTH_RATE = 1.1,
        ATTRIBUTE_POINTS_PER_LEVEL = 3
    },

    -- Combat Constants
    COMBAT = {
        -- Damage
        BASE_DAMAGE = 10,
        CRITICAL_MULTIPLIER = 2.0,
        BACKSTAB_MULTIPLIER = 1.5,
        HEADSHOT_MULTIPLIER = 1.25,

        -- Posture
        POSTURE_BREAK_THRESHOLD = 0,
        POSTURE_RECOVERY_DELAY = 1.5,
        PERFECT_PARRY_WINDOW = 0.2,

        -- Block
        BLOCK_ANGLE = 180,
        BLOCK_STAMINA_COST = 5,
        BLOCK_POSTURE_DAMAGE = 10,

        -- Attack Costs
        LIGHT_ATTACK_STAMINA = 15,
        HEAVY_ATTACK_STAMINA = 30,
        CRITICAL_ATTACK_STAMINA = 40,

        -- Movement Costs
        SPRINT_STAMINA_DRAIN = 5,
        ROLL_STAMINA_COST = 20,
        JUMP_STAMINA_COST = 10
    },

    -- Resource Constants
    RESOURCE = {
        -- Regeneration Intervals
        HEALTH_REGEN_INTERVAL = 5,
        STAMINA_REGEN_INTERVAL = 1,
        MANA_REGEN_INTERVAL = 3,
        BLOOD_REGEN_INTERVAL = 10,

        -- Regeneration Amounts
        HEALTH_REGEN_AMOUNT = 1,
        STAMINA_REGEN_AMOUNT = 10,
        MANA_REGEN_AMOUNT = 2,
        BLOOD_REGEN_AMOUNT = 0.5,

        -- Resource Caps
        BASE_HEALTH = 100,
        MAX_HEALTH = 1000,
        BASE_STAMINA = 100,
        MAX_STAMINA = 200,
        BASE_MANA = 100,
        MAX_MANA = 300
    },

    -- Survival Constants
    SURVIVAL = {
        -- Depletion Rates
        HUNGER_DECAY_RATE = 1,
        HUNGER_DECAY_INTERVAL = 60,
        THIRST_DECAY_RATE = 1.5,
        THIRST_DECAY_INTERVAL = 45,

        -- Effect Thresholds
        CRITICAL_HUNGER_THRESHOLD = 25,
        CRITICAL_THIRST_THRESHOLD = 25,

        -- Penalties
        LOW_HUNGER_STAMINA_PENALTY = 0.5,
        LOW_HUNGER_MOVEMENT_PENALTY = 0.75,
        LOW_THIRST_HEALTH_PENALTY = 0.5,
        LOW_THIRST_STAMINA_PENALTY = 0.5
    },

    -- Movement Constants
    MOVEMENT = {
        -- Walking
        BASE_WALK_SPEED = 10,
        WALK_CAMERA_FOV = 68,

        -- Sprinting
        SPRINT_MULTIPLIER = 2.6,  -- 26/10
        SPRINT_DOUBLE_TAP_DELAY = 0.2,
        SPRINT_CAMERA_FOV = 76,
        SPRINT_CAMERA_MOTION_BLUR = true,
        SPRINT_CAMERA_MOTION_BLUR_AMOUNT = 4,

        -- Crouching
        CROUCH_MULTIPLIER = 0.7,  -- 7/10

        -- Other movement constants
        MIN_MOVEMENT_SPEED = 4,
        MAX_MOVEMENT_SPEED = 40,

        -- Underwater
        OXYGEN_DRAIN_RATE = 5,
        OXYGEN_REGEN_RATE = 10,
        OXYGEN_CRITICAL_THRESHOLD = 25
    },

    -- Weapon Constants
    WEAPON = {
        DURABILITY_LOSS_RATE = 1,
        SHARPNESS_LOSS_RATE = 0.5,
        REPAIR_COST_MULTIPLIER = 1.5,
        MIN_DURABILITY_DAMAGE_MULT = 0.5,
        MAX_SHARPNESS_CRIT_MULT = 1.2
    },

    -- Crafting Constants
    CRAFT = {
        BASE_SUCCESS_RATE = 0.8,
        SKILL_SUCCESS_BONUS = 0.01,
        MAX_SUCCESS_RATE = 0.99,
        BASE_MATERIAL_RETURN = 0.5,
        SKILL_RETURN_BONUS = 0.01,
        SKILL_PROGRESS_MULTIPLIER = 2.0,
        MAX_SKILL_LEVEL = 100
    }
}

--[[ Entity Profiles ]]
StatModule.EntityProfiles = {
    CHARACTER = {
        stats = {
            "HEALTH",
            "BLOOD",
            "OXYGEN",
            "MANA",
            "STAMINA",
            "POSTURE",
            "RESONANCE",
            "SPEED",
            "JUMP_POWER",
            "HUNGER",
            "THIRST",
            "FORGING",
            "SMITHING",
            "COOKING",
            "ALCHEMY"
        },
        cycles = {
            "HEALTH",
            "BLOOD",
            "MANA",
            "STAMINA",
            "POSTURE",
            "HUNGER",
            "THIRST",
            "OXYGEN"
        }
    },

    PERSON = {
        stats = {
            "HEALTH",
            "MANA",
            "STAMINA",
            "POSTURE",
            "RESONANCE",
            "SPEED",
            "TRUST",
            "MEMORY",
            "EMOTION"
        },
        cycles = {
            "HEALTH",
            "MANA",
            "STAMINA",
            "POSTURE",
            "TRUST",
            "MEMORY",
            "EMOTION"
        }
    },

    WEAPON = {
        stats = {
            "DURABILITY",
            "SHARPNESS",
            "DAMAGE",
            "CRITICAL"
        },
        cycles = {
            "DURABILITY",
            "SHARPNESS"
        }
    }
}

--[[ Templates ]]
StatModule.Templates = {
    -- Levels
    LEVEL = {
        baseValue = 1,
        minValue = 1,
        maxValue = StatModule.Constants.PROGRESSION.MAX_LEVEL,
        category = "PROGRESSION",
        displayName = "Level",
        description = "Character's overall level",
        icon = "",
        color = Color3.fromRGB(255, 215, 0),
        format = "%.0f",
        requirements = {
            progress = StatModule.Constants.PROGRESSION.BASE_PROGRESS,
            conditions = {
                growth = function(entity)
                    local currentLevel = entity:GetAttribute("LEVEL") or 1
                    return StatModule.Constants.PROGRESSION.BASE_PROGRESS * (currentLevel ^ StatModule.Constants.PROGRESSION.GROWTH_RATE)
                end
            }
        },
        effects = {
            ATTRIBUTE_POINTS = {
                type = "MULTIPLY",
                value = StatModule.Constants.PROGRESSION.ATTRIBUTE_POINTS_PER_LEVEL
            }
        }
    },

    FORGING = {
        baseValue = 1,
        minValue = 1,
        maxValue = StatModule.Constants.CRAFT.MAX_SKILL_LEVEL,
        category = "CRAFT",
        displayName = "Weapon Forging",
        description = "Skill at crafting weapons",
        icon = "",
        color = Color3.fromRGB(150, 75, 0),
        format = "%.0f",
        playerSpecific = true,
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        effects = {
            WEAPON_FORGING_SUCCESS_RATE = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("FORGING") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_SUCCESS_BONUS
                end
            },
            WEAPON_FORGING_MATERIAL_RETURN = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("FORGING") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_RETURN_BONUS
                end
            },
            LEVEL_PROGRESS = {
                type = "ADD",
                value = function(entity)
                    return 0.5
                end
            }
        }
    },

    SMITHING = {
        baseValue = 1,
        minValue = 1,
        maxValue = StatModule.Constants.CRAFT.MAX_SKILL_LEVEL,
        category = "CRAFT",
        displayName = "Armor Smithing",
        description = "Skill at crafting armor and protective equipment",
        icon = "",
        color = Color3.fromRGB(100, 100, 150),
        format = "%.0f",
        playerSpecific = true,
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        effects = {
            ARMOR_SMITHING_SUCCESS_RATE = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("SMITHING") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_SUCCESS_BONUS
                end
            },
            ARMOR_SMITHING_MATERIAL_RETURN = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("SMITHING") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_RETURN_BONUS
                end
            },
            LEVEL_PROGRESS = {
                type = "ADD",
                value = function(entity)
                    return 0.5
                end
            }
        }
    },

    COOKING = {
        baseValue = 1,
        minValue = 1,
        maxValue = StatModule.Constants.CRAFT.MAX_SKILL_LEVEL,
        category = "CRAFT",
        displayName = "Cooking",
        description = "Skill at preparing food and consumables",
        icon = "",
        color = Color3.fromRGB(255, 160, 0),
        format = "%.0f",
        playerSpecific = true,
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        effects = {
            COOKING_SUCCESS_RATE = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("COOKING") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_SUCCESS_BONUS
                end
            },
            COOKING_MATERIAL_RETURN = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("COOKING") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_RETURN_BONUS
                end
            },
            LEVEL_PROGRESS = {
                type = "ADD",
                value = function(entity)
                    return 0.5
                end
            }
        }
    },

    ALCHEMY = {
        baseValue = 1,
        minValue = 1,
        maxValue = StatModule.Constants.CRAFT.MAX_SKILL_LEVEL,
        category = "CRAFT",
        displayName = "Alchemy",
        description = "Skill at brewing potions and mixing ingredients",
        icon = "",
        color = Color3.fromRGB(120, 0, 180),
        format = "%.0f",
        playerSpecific = true,
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        effects = {
            ALCHEMY_SUCCESS_RATE = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("ALCHEMY") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_SUCCESS_BONUS
                end
            },
            ALCHEMY_MATERIAL_RETURN = {
                type = "ADD",
                value = function(entity)
                    local skillLevel = entity:GetAttribute("ALCHEMY") or 1
                    return skillLevel * StatModule.Constants.CRAFT.SKILL_RETURN_BONUS
                end
            },
            LEVEL_PROGRESS = {
                type = "ADD",
                value = function(entity)
                    return 0.5
                end
            }
        }
    },

    -- Progression
    REPUTATION = {
        baseValue = 0,
        minValue = -100,
        maxValue = 100,
        decay = {
            amount = 0.05,
            interval = 86400
        },
        category = "MEMORY",
        displayName = "Global Reputation",
        description = "Overall standing in the world affecting how all NPCs view you initially",
        icon = "",
        color = Color3.fromRGB(255, 223, 0),
        format = "%.0f",
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        playerSpecific = true,
        effects = {
            TRUST_GAIN = {
                type = "MULTIPLY",
                value = function(entity)
                    local reputation = entity:GetAttribute("REPUTATION") or 0
                    return 1 + (reputation / 200)
                end
            },
            FACTION_STANDING_GAIN = {
                type = "MULTIPLY",
                value = function(entity)
                    local reputation = entity:GetAttribute("REPUTATION") or 0
                    return 1 + (reputation / 200)
                end
            }
        },
        metadata = {
            reputationThresholds = {
                INFAMOUS = -80,
                NOTORIOUS = -50,
                SUSPICIOUS = -20,
                NEUTRAL = 0,
                RESPECTED = 20,
                RENOWNED = 50,
                LEGENDARY = 80
            },
            decayRate = 0.05,
            gainRate = 1.0,
            lossRate = 2.0
        }
    },

    -- Vital Stats
    HEALTH = {
        baseValue = StatModule.Constants.RESOURCE.BASE_HEALTH,
        minValue = 0,
        maxValue = StatModule.Constants.RESOURCE.MAX_HEALTH,
        regen = {
            amount = StatModule.Constants.RESOURCE.HEALTH_REGEN_AMOUNT,
            interval = StatModule.Constants.RESOURCE.HEALTH_REGEN_INTERVAL,
            condition = function(entity)
                return entity:GetAttribute("BLOOD") > 0
            end
        },
        category = "VITAL",
        displayName = "Health",
        description = "Character's life force",
        icon = "",
        color = Color3.fromRGB(255, 0, 0),
        format = "%.0f/%.0f",
        syncProperties = {
            default = {
                class = "Humanoid",
                property = "Health"
            },
            max = {
                class = "Humanoid",
                property = "MaxHealth"
            }
        }
    },

    BLOOD = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        regen = { amount = 0.5, interval = 10 },
        category = "VITAL",
        displayName = "Blood",
        description = "Blood level affecting consciousness",
        icon = "",
        color = Color3.fromRGB(128, 0, 0),
        format = "%.0f/%.0f"
    },

    POSTURE = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        regen = {
            amount = 5,
            interval = 1,
            condition = function(entity)
                return not entity:GetAttribute("BLOCKING")
            end
        },
        category = "COMBAT",
        displayName = "Posture",
        description = "Block pressure tolerance",
        icon = "",
        color = Color3.fromRGB(255, 215, 0),
        format = "%.0f/%.0f"
    },

    STAMINA = {
        baseValue = StatModule.Constants.RESOURCE.BASE_STAMINA,
        minValue = 0,
        maxValue = StatModule.Constants.RESOURCE.MAX_STAMINA,
        regen = {
            amount = StatModule.Constants.RESOURCE.STAMINA_REGEN_AMOUNT,
            interval = StatModule.Constants.RESOURCE.STAMINA_REGEN_INTERVAL,
            condition = function(entity)
                return not (entity:GetAttribute("RUNNING") or entity:GetAttribute("BLOCKING"))
            end
        },
        category = "RESOURCE",
        displayName = "Stamina",
        description = "Energy for physical actions",
        icon = "",
        color = Color3.fromRGB(0, 255, 0),
        format = "%.0f/%.0f",
        effects = {
            MOVEMENT = { type = "MULTIPLY", value = 1 }
        }
    },

    MANA = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        regen = { amount = 2, interval = 3 },
        category = "RESOURCE",
        displayName = "Mana",
        description = "Magical energy for abilities",
        icon = "",
        color = Color3.fromRGB(0, 0, 255),
        format = "%.0f/%.0f"
    },

    OXYGEN = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        decay = {
            amount = StatModule.Constants.MOVEMENT.OXYGEN_DRAIN_RATE,
            interval = 1,
            condition = function(entity)
                return entity:GetAttribute("UNDERWATER")
            end
        },
        regen = {
            amount = StatModule.Constants.MOVEMENT.OXYGEN_REGEN_RATE,
            interval = 1,
            condition = function(entity)
                return not entity:GetAttribute("UNDERWATER")
            end
        },
        category = "VITAL",
        displayName = "Oxygen",
        description = "Breath meter for swimming",
        icon = "",
        color = Color3.fromRGB(135, 206, 235),
        format = "%.0f/%.0f",
        effects = {
            STAMINA_REGEN = {
                type = "MULTIPLY",
                value = function(entity)
                    local oxygen = entity:GetAttribute("OXYGEN") or 100
                    return 0.25 + (0.75 * (oxygen / 100))
                end
            },
            DAMAGE = {
                type = "MULTIPLY",
                value = function(entity)
                    local oxygen = entity:GetAttribute("OXYGEN") or 100
                    return 0.5 + (0.5 * (oxygen / 100))
                end
            },
            MOVEMENT = {
                type = "MULTIPLY",
                value = function(entity)
                    local oxygen = entity:GetAttribute("OXYGEN") or 100
                    return 0.6 + (0.4 * (oxygen / 100))
                end
            },
            HEALTH = {
                type = "ADD",
                value = function(entity)
                    local oxygen = entity:GetAttribute("OXYGEN") or 100
                    if oxygen <= 0 then
                        return -10
                    end
                    return 0
                end
            }
        },
        dependencies = {
            STAMINA = function(entity)
                local oxygen = entity:GetAttribute("OXYGEN") or 100
                if oxygen < 25 then
                    return -(5 * (1 - oxygen/25))
                end
                return 0
            end
        }
    },

    SPEED = {
        baseValue = StatModule.Constants.MOVEMENT.BASE_WALK_SPEED,
        minValue = StatModule.Constants.MOVEMENT.MIN_MOVEMENT_SPEED,
        maxValue = StatModule.Constants.MOVEMENT.MAX_MOVEMENT_SPEED,
        category = "ATTRIBUTE",
        displayName = "Movement Speed",
        description = "Character's movement velocity",
        icon = "",
        color = Color3.fromRGB(124, 252, 0),
        format = "%.1f",
        modifiers = {
            RUNNING = {
                id = "RUNNING",
                value = StatModule.Constants.MOVEMENT.SPRINT_MULTIPLIER,
                type = "MULTIPLY"
            },
            CROUCHING = {
                id = "CROUCHING",
                value = StatModule.Constants.MOVEMENT.CROUCH_MULTIPLIER,
                type = "MULTIPLY"
            },
            SWIMMING = {
                id = "SWIMMING",
                value = StatModule.Constants.MOVEMENT.SWIM_MULTIPLIER,
                type = "MULTIPLY"
            }
        },
        syncProperties = {
            default = {
                class = "Humanoid",
                property = "WalkSpeed"
            }
        }
    },

    JUMP_POWER = {
        baseValue = 50,
        minValue = 0,
        maxValue = 100,
        category = "ATTRIBUTE",
        displayName = "Jump Power",
        description = "Character's jumping ability",
        icon = "",
        color = Color3.fromRGB(135, 206, 235),
        format = "%.1f",
        modifiers = {
            CROUCHING = {
                id = "CROUCHING",
                value = 0.5,
                type = "MULTIPLY"
            },
            SWIMMING = {
                id = "SWIMMING",
                value = 0.25,
                type = "MULTIPLY"
            }
        },
        syncProperties = {
            default = {
                class = "Humanoid",
                property = "JumpPower"
            }
        }
    },

    -- Core Attributes
    STRENGTH = {
        baseValue = 10,
        minValue = 1,
        maxValue = 100,
        category = StatModule.Constants.CATEGORIES.ATTRIBUTE,
        displayName = "Strength",
        description = "Physical strength.",
        icon = "",
        color = Color3.fromRGB(200, 50, 50),
        format = "%.0f",
        effects = {
            PENETRATION = {
                type = "PERCENT",
                value = function(entity)
                    local strength = entity:GetAttribute("STRENGTH") or 10
                    return math.floor(strength / 10)
                end
            }
        }
    },

    GRIT = {
        baseValue = 10,
        minValue = 1,
        maxValue = 100,
        category = StatModule.Constants.CATEGORIES.ATTRIBUTE,
        displayName = "Grit",
        description = "Resilience against threats.",
        icon = "",
        color = Color3.fromRGB(100, 100, 100),
        format = "%.0f",
        effects = {
            MAX_HEALTH_ADD = {
                type = "ADD",
                value = function(entity)
                    local grit = entity:GetAttribute("GRIT") or 10
                    return grit * 0.5
                end
            }
        }
    },

    DEXTERITY = {
        baseValue = 10,
        minValue = 1,
        maxValue = 100,
        category = StatModule.Constants.CATEGORIES.ATTRIBUTE,
        displayName = "Dexterity",
        description = "Sleight of Hand and Nimbleness.",
        icon = "",
        color = Color3.fromRGB(50, 200, 50),
        format = "%.0f",
        effects = {
            STEALTH_SKILL = {
                type = "ADD",
                value = 0.1 
            }
        }
    },

    INTELLIGENCE = {
        baseValue = 10,
        minValue = 1,
        maxValue = 100,
        category = StatModule.Constants.CATEGORIES.ATTRIBUTE,
        displayName = "Intelligence",
        description = "Logic and problem-solving skills.",
        icon = "",
        color = Color3.fromRGB(50, 50, 200),
        format = "%.0f",
        effects = {
            MAX_ETHER_ADD = {
                type = "ADD",
                value = 2
            }
        }
    },

    RESOLVE = {
        baseValue = 10,
        minValue = 1,
        maxValue = 100,
        category = StatModule.Constants.CATEGORIES.ATTRIBUTE,
        displayName = "Resolve",
        description = "Capacity for mental stability and integrity.",
        icon = "",
        color = Color3.fromRGB(150, 50, 150),
        format = "%.0f",
        effects = {
            TEMPO_ADD = {
                type = "ADD",
                value = 0.5
            }
        }
    },

    -- Combat Stats
    DAMAGE = {
        baseValue = 10,
        minValue = 0,
        maxValue = 1000,
        category = "COMBAT",
        displayName = "Damage",
        description = "Base damage dealt by attacks",
        icon = "",
        color = Color3.fromRGB(220, 20, 60),
        format = "%.0f",
        modifiers = {
            STANCE = {
                id = "STANCE",
                value = 1,
                type = "MULTIPLY"
            },
            RESONANCE = {
                id = "RESONANCE",
                value = 1,
                type = "MULTIPLY"
            },
            WEAPON = {
                id = "WEAPON",
                value = 1,
                type = "MULTIPLY"
            }
        }
    },

    RESONANCE = {
        baseValue = 0,
        minValue = 0,
        maxValue = 100
    },

    -- Survival Stats
    HUNGER = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        decay = {
            amount = StatModule.Constants.SURVIVAL.HUNGER_DECAY_RATE,
            interval = StatModule.Constants.SURVIVAL.HUNGER_DECAY_INTERVAL
        },
        category = "SURVIVAL",
        displayName = "Hunger",
        description = "Food satiation level",
        icon = "",
        color = Color3.fromRGB(255, 165, 0),
        format = "%.0f/%.0f",
        effects = {
            STAMINA_REGEN = {
                type = "MULTIPLY",
                value = function(entity)
                    local hunger = entity:GetAttribute("HUNGER") or 100
                    if hunger <= StatModule.Constants.SURVIVAL.CRITICAL_HUNGER_THRESHOLD then
                        return 1 - (0.5 * (1 - hunger/StatModule.Constants.SURVIVAL.CRITICAL_HUNGER_THRESHOLD))
                    end
                    return 1
                end
            },
            SPEED = {
                type = "MULTIPLY",
                value = function(entity)
                    local hunger = entity:GetAttribute("HUNGER") or 100
                    if hunger <= StatModule.Constants.SURVIVAL.CRITICAL_HUNGER_THRESHOLD then
                        return 1 - (0.25 * (1 - hunger/StatModule.Constants.SURVIVAL.CRITICAL_HUNGER_THRESHOLD))
                    end
                    return 1
                end
            }
        }
    },

    THIRST = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        decay = {
            amount = StatModule.Constants.SURVIVAL.THIRST_DECAY_RATE,
            interval = StatModule.Constants.SURVIVAL.THIRST_DECAY_INTERVAL
        },
        category = "SURVIVAL",
        displayName = "Thirst",
        description = "Hydration level",
        icon = "",
        color = Color3.fromRGB(0, 191, 255),
        format = "%.0f/%.0f",
        effects = {
            HEALTH_REGEN = {
                type = "MULTIPLY",
                value = function(entity)
                    local thirst = entity:GetAttribute("THIRST") or 100
                    if thirst <= StatModule.Constants.SURVIVAL.CRITICAL_THIRST_THRESHOLD then
                        return 1 - (0.5 * (1 - thirst/StatModule.Constants.SURVIVAL.CRITICAL_THIRST_THRESHOLD))
                    end
                    return 1
                end
            },
            STAMINA_REGEN = {
                type = "MULTIPLY",
                value = function(entity)
                    local thirst = entity:GetAttribute("THIRST") or 100
                    if thirst <= StatModule.Constants.SURVIVAL.CRITICAL_THIRST_THRESHOLD then
                        return 1 - (0.5 * (1 - thirst/StatModule.Constants.SURVIVAL.CRITICAL_THIRST_THRESHOLD))
                    end
                    return 1
                end
            }
        }
    },

    -- Weapon Stats
    DURABILITY = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        decay = {
            amount = StatModule.Constants.WEAPON.DURABILITY_LOSS_RATE,
            interval = 1,
            condition = function(entity)
                return entity:GetAttribute("ATTACKING")
            end
        },
        category = "WEAPON",
        displayName = "Weapon Durability",
        description = "Weapon condition",
        icon = "",
        color = Color3.fromRGB(128, 128, 128),
        format = "%.0f/%.0f",
        effects = {
            DAMAGE_MULTIPLIER = {
                type = "MULTIPLY",
                value = StatModule.Constants.WEAPON.MIN_DURABILITY_DAMAGE_MULT
            }
        }
    },

    SHARPNESS = {
        baseValue = 100,
        minValue = 0,
        maxValue = 100,
        decay = {
            amount = StatModule.Constants.WEAPON.SHARPNESS_LOSS_RATE,
            interval = 1,
            condition = function(entity)
                return entity:GetAttribute("ATTACKING")
            end
        },
        category = "WEAPON",
        displayName = "Weapon Sharpness",
        description = "Weapon edge quality",
        icon = "",
        color = Color3.fromRGB(192, 192, 192),
        format = "%.0f/%.0f",
        effects = {
            CRITICAL_MULTIPLIER = {
                type = "MULTIPLY",
                value = StatModule.Constants.WEAPON.MAX_SHARPNESS_CRIT_MULT
            }
        }
    },

    CRITICAL = {
        baseValue = 5,
        minValue = 0,
        maxValue = 100,
        category = "COMBAT",
        displayName = "Critical",
        description = "Chance to deal critical damage",
        icon = "",
        color = Color3.fromRGB(255, 0, 0),
        format = "%.1f%%",
        effects = {
            CRITICAL_CHANCE = {
                type = "PERCENT",
                value = 1
            },
            CRITICAL_MULTIPLIER = {
                type = "MULTIPLY",
                value = 0.01
            }
        }
    },

    -- Memory Stats
    TRUST = {
        baseValue = 0,
        minValue = -100,
        maxValue = 100,
        decay = {
            amount = 0.05,
            interval = 86400
        },
        category = "MEMORY",
        displayName = "Trust",
        description = "Level of trust in relationship, including forgiveness behavior",
        icon = "",
        color = Color3.fromRGB(0, 100, 200),
        format = "%.0f",
        metadata = {
            moodThresholds = {
                HOSTILE = -50,
                SUSPICIOUS = -20,
                NEUTRAL = 0,
                FRIENDLY = 30,
                TRUSTED = 70
            },
            forgivenessThreshold = 30,
            trustGainRate = 1.0,
            trustLossRate = 1.0
        },
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        playerSpecific = true
    },

    MEMORY = {
        baseValue = 604800,
        minValue = 3600,
        maxValue = 9999999,
        decay = {
            amount = 86400,
            interval = 86400
        },
        category = "MEMORY",
        displayName = "Memory Duration",
        description = "How long an NPC remembers interactions",
        icon = "",
        color = Color3.fromRGB(150, 120, 180),
        format = "%.0f",
        storageType = StatModule.Constants.STORAGE_TYPE.ATTRIBUTE,
        playerSpecific = false,
        fixed = true
    },

    EMOTION = {
        baseValue = 0,
        minValue = -100,
        maxValue = 100,
        decay = {
            amount = 0.1,
            interval = 3600
        },
        category = "MEMORY",
        displayName = "Emotion",
        description = "Current emotional state affecting dialogue and interactions",
        icon = "",
        color = Color3.fromRGB(255, 165, 0),
        format = "%.0f",
        storageType = StatModule.Constants.STORAGE_TYPE.PLAYER_DATA,
        playerSpecific = true,
        effects = {
            DIALOGUE_RESPONSE = {
                type = "MULTIPLY",
                value = function(entity)
                    local emotion = entity:GetAttribute("EMOTION") or 0
                    return 1 + (emotion / 100)
                end
            },
            RELATIONSHIP_GAIN = {
                type = "MULTIPLY",
                value = function(entity)
                    local emotion = entity:GetAttribute("EMOTION") or 0
                    return 1 + (emotion / 200)
                end
            }
        },
        metadata = {
            emotionThresholds = {
                BETRAYED = -50,
                DISTRUSTFUL = -20,
                NEUTRAL = 0,
                FRIENDLY = 30,
                DEVOTED = 70
            },
            decayRate = 0.1,
            gainRate = 1.0,
            lossRate = 1.0
        }
    }
}

return StatModule