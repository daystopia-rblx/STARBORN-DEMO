--[[ StatModule
    @author @Daystopia
    @version 1.0.3
    @date 2025-04-03
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
        WEAPON = "WEAPON"
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
    }
}

--[[ Templates ]]
StatModule.Templates = {
    -- Level/Progression
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
        format = "%.0f/%.0f"
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
        maxValue = 100,
        decay = {
            amount = 5,
            interval = 1,
            condition = function(entity)
                return not entity:GetAttribute("ATTACKING")
            end
        },
        category = "COMBAT",
        displayName = "Resonance",
        description = "Combat momentum meter",
        icon = "",
        color = Color3.fromRGB(255, 128, 0),
        format = "%.0f/%.0f",
        effects = {
            DAMAGE_MULTIPLIER = { type = "MULTIPLY", value = 1.5 }
        }
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
    }
}

return StatModule