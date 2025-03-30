--[[ StateModule
    Handles entity state definitions and transitions
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local StateModule = {}

export type StateDefinition = {
    category: string,
    displayName: string,
    description: string?,
    exclusive: boolean?,
    duration: number?,
    cooldown: number?,
    transitions: {[string]: boolean}?,
    conditions: {(entity: any) -> boolean}?,
    onEnter: ((entity: any) -> ())?,
    onExit: ((entity: any) -> ())?,
    metadata: {[string]: any}?
}

--[[ Constants ]]
StateModule.Categories = {
    COMBAT = "COMBAT",
    MOVEMENT = "MOVEMENT",
    STATUS = "STATUS",
    INTERACTION = "INTERACTION",
    STANCE = "STANCE",
    EMOTE = "EMOTE"
}

--[[ Templates ]]
StateModule.Templates = {
    -- Combat States
    BLOCKING = {
        category = "COMBAT",
        displayName = "Blocking",
        description = "Currently blocking attacks",
        exclusive = true,
        cooldown = 0.5,
        transitions = {
            ROLLING = false,
            ATTACKING = false,
            PARRYING = true
        }
    },

    PARRYING = {
        category = "COMBAT",
        displayName = "Parrying",
        description = "Executing a parry",
        exclusive = true,
        duration = 0.3,
        cooldown = 1,
        transitions = {
            BLOCKING = true,
            ROLLING = false,
            ATTACKING = true
        }
    },

    ATTACKING = {
        category = "COMBAT",
        displayName = "Attacking",
        description = "Executing an attack",
        exclusive = true,
        cooldown = 0.2,
        transitions = {
            BLOCKING = false,
            ROLLING = true,
            PARRYING = false
        }
    },

    LIGHT_ATTACK = {
        category = "COMBAT",
        displayName = "Light Attack",
        description = "Executing a light attack",
        exclusive = true,
        duration = 0.4,
        cooldown = 0.2,
        transitions = {
            CRITICAL_ATTACK = true,
            BLOCKING = false,
            ROLLING = true
        }
    },

    CRITICAL_ATTACK = {
        category = "COMBAT",
        displayName = "Critical Attack",
        description = "Executing a powerful attack",
        exclusive = true,
        duration = 0.8,
        cooldown = 1.5,
        transitions = {
            LIGHT_ATTACK = false,
            BLOCKING = false,
            ROLLING = true
        }
    },

    FEINTING = {
        category = "COMBAT",
        displayName = "Feinting",
        description = "Canceling an attack",
        exclusive = true,
        duration = 0.2,
        cooldown = 0.5,
        transitions = {
            ATTACKING = true,
            BLOCKING = true,
            ROLLING = true
        }
    },

    -- Movement States
    ROLLING = {
        category = "MOVEMENT",
        displayName = "Rolling",
        description = "Executing an evasive roll",
        exclusive = true,
        duration = 0.5,
        cooldown = 1,
        transitions = {
            BLOCKING = false,
            ATTACKING = false,
            PARRYING = false,
            RUNNING = false
        }
    },

    RUNNING = {
        category = "MOVEMENT",
        displayName = "Sprinting",
        description = "Moving at increased speed",
        exclusive = true,
        transitions = {
            BLOCKING = true,
            ROLLING = true,
            SLIDING = true
        }
    },

    SLIDING = {
        category = "MOVEMENT",
        displayName = "Sliding",
        description = "Executing a slide",
        exclusive = true,
        duration = 0.7,
        cooldown = 1.5,
        transitions = {
            RUNNING = true,
            ROLLING = true
        }
    },

    WALL_RUNNING = {
        category = "MOVEMENT",
        displayName = "Wall Running",
        description = "Running along a wall",
        exclusive = true,
        transitions = {
            WALL_CLIMBING = true,
            JUMPING = true,
            LEDGE_HANGING = true
        }
    },

    WALL_CLIMBING = {
        category = "MOVEMENT",
        displayName = "Wall Climbing",
        description = "Climbing a wall",
        exclusive = true,
        transitions = {
            WALL_RUNNING = true,
            LEDGE_HANGING = true
        }
    },

    LEDGE_HANGING = {
        category = "MOVEMENT",
        displayName = "Ledge Hanging",
        description = "Hanging from a ledge",
        exclusive = true,
        transitions = {
            WALL_CLIMBING = true,
            JUMPING = true
        }
    },

    JUMPING = {
        category = "MOVEMENT",
        displayName = "Jumping",
        description = "In mid-air jump",
        exclusive = true,
        duration = 0.5,
        transitions = {
            WALL_RUNNING = true,
            LEDGE_HANGING = true,
            ROLLING = true
        }
    },

    SWINGING = {
        category = "MOVEMENT",
        displayName = "Swinging",
        description = "Swinging from an object",
        exclusive = true,
        transitions = {
            JUMPING = true,
            LEDGE_HANGING = true
        }
    },

    CROUCHING = {
        category = "MOVEMENT",
        displayName = "Crouching",
        description = "In crouched position",
        exclusive = true,
        transitions = {
            SLIDING = true,
            ROLLING = true,
            RUNNING = true
        }
    },

    SWIMMING = {
        category = "MOVEMENT",
        displayName = "Swimming",
        description = "Moving through water",
        exclusive = true,
        transitions = {
            JUMPING = true,
            SPRINTING = false,
            ROLLING = false,
            ATTACKING = true,
            BLOCKING = false
        },
        onEnter = function(entity)
            entity:SetAttribute("UNDERWATER", true)
        end,
        onExit = function(entity)
            entity:SetAttribute("UNDERWATER", false)
        end
    },

    -- Status States
    KNOCKED = {
        category = "STATUS",
        displayName = "Knocked Out",
        description = "Incapacitated and vulnerable",
        exclusive = true,
        transitions = {
            DEAD = true,
            EXECUTING = false
        }
    },

    EXECUTING = {
        category = "STATUS",
        displayName = "Executing",
        description = "Performing execution on knocked enemy",
        exclusive = true,
        duration = 2,
        transitions = {
            KNOCKED = false
        }
    },

    DEAD = {
        category = "STATUS",
        displayName = "Dead",
        description = "Character is dead",
        exclusive = true,
        transitions = {}
    },

    CARRYING = {
        category = "STATUS",
        displayName = "Carrying",
        description = "Carrying another character",
        exclusive = true,
        transitions = {
            RUNNING = true,
            ROLLING = false,
            ATTACKING = false
        }
    },

    -- Stance States
    STANCE_NORMAL = {
        category = "STANCE",
        displayName = "Normal Stance",
        description = "Default combat stance",
        exclusive = true,
        transitions = {
            STANCE_DEFENSIVE = true,
            STANCE_AGGRESSIVE = true
        },
        onEnter = function(entity)
            entity:SetAttribute("STANCE_DAMAGE", 1)
            entity:SetAttribute("STANCE_POSTURE", 1)
        end
    },

    STANCE_DEFENSIVE = {
        category = "STANCE",
        displayName = "Defensive Stance",
        description = "Defense-focused stance",
        exclusive = true,
        transitions = {
            STANCE_NORMAL = true,
            STANCE_AGGRESSIVE = true
        },
        onEnter = function(entity)
            entity:SetAttribute("STANCE_DAMAGE", 0.8)
            entity:SetAttribute("STANCE_POSTURE", 1.2)
        end,
        onExit = function(entity)
            entity:SetAttribute("STANCE_DAMAGE", 1)
            entity:SetAttribute("STANCE_POSTURE", 1)
        end
    },

    STANCE_AGGRESSIVE = {
        category = "STANCE",
        displayName = "Aggressive Stance",
        description = "Attack-focused stance",
        exclusive = true,
        transitions = {
            STANCE_NORMAL = true,
            STANCE_DEFENSIVE = true
        },
        onEnter = function(entity)
            entity:SetAttribute("STANCE_DAMAGE", 1.2)
            entity:SetAttribute("STANCE_POSTURE", 0.8)
        end,
        onExit = function(entity)
            entity:SetAttribute("STANCE_DAMAGE", 1)
            entity:SetAttribute("STANCE_POSTURE", 1)
        end
    },

    -- Interaction States
    INTERACTING = {
        category = "INTERACTION",
        displayName = "Interacting",
        description = "Interacting with object/entity",
        exclusive = true,
        transitions = {
            ATTACKING = false,
            ROLLING = true
        }
    },

    -- Emote States
    EMOTING = {
        category = "EMOTE",
        displayName = "Emoting",
        description = "Playing an emote animation",
        exclusive = true,
        transitions = {
            ATTACKING = true,
            ROLLING = true,
            BLOCKING = true
        }
    }
}

return StateModule