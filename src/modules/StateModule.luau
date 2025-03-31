--[[ StateModule
    Handles entity state definitions and transitions
    @author @Daystopia
    @version 1.0.1
    @date 2025-03-31
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
    BLOCK = {
        category = "COMBAT",
        displayName = "Blocking",
        description = "Currently blocking attacks",
        exclusive = true,
        cooldown = 0.2,
        transitions = {
            ROLL = false,
            ATTACK = false,
            PARRY = true
        }
    },

    PARRY = {
        category = "COMBAT",
        displayName = "Parrying",
        description = "Executing a parry",
        exclusive = true,
        duration = 0.3,
        cooldown = 0.2,
        transitions = {
            BLOCK = true,
            ROLL = false,
            ATTACK = true
        }
    },

    ATTACK = {
        category = "COMBAT",
        displayName = "Attacking",
        description = "Executing an attack",
        exclusive = true,
        cooldown = 0.2,
        transitions = {
            BLOCK = false,
            ROLL = true,
            PARRY = false
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
            BLOCK = false,
            ROLL = true
        }
    },

    CRITICAL_ATTACK = {
        category = "COMBAT",
        displayName = "Critical Attack",
        description = "Executing a powerful attack",
        exclusive = true,
        duration = 0.8,
        cooldown = 0.2,
        transitions = {
            LIGHT_ATTACK = false,
            BLOCK = false,
            ROLL = true
        }
    },

    FEINT = {
        category = "COMBAT",
        displayName = "Feinting",
        description = "Canceling an attack",
        exclusive = true,
        duration = 0.2,
        cooldown = 0.2,
        transitions = {
            ATTACK = true,
            BLOCK = true,
            ROLL = true
        }
    },

    -- Movement States
    ROLL = {
        category = "MOVEMENT",
        displayName = "Rolling",
        description = "Executing an evasive roll",
        exclusive = true,
        duration = 0.8,
        cooldown = 0.2,
        transitions = {
            BLOCK = false,
            ATTACK = false,
            PARRY = false,
            RUN = true,
            DASH = true,
            SLIDE = true,
            CROUCH = true,
            JUMP = true,
            WALK = true
        }
    },

    WALK = {
        category = "MOVEMENT",
        displayName = "Walking",
        description = "Moving at normal speed",
        exclusive = true,
        transitions = {
            RUN = true,
            BLOCK = true,
            ROLL = true,
            SLIDE = true,
            DASH = true,
            CROUCH = true,
            JUMP = true,
            IDLE = true
        }
    },

    IDLE = {
        category = "MOVEMENT",
        displayName = "Idle",
        description = "Standing still",
        exclusive = true,
        transitions = {
            WALK = true,
            RUN = true,
            BLOCK = true,
            ROLL = true,
            DASH = true,
            CROUCH = true,
            JUMP = true
        }
    },

    RUN = {
        category = "MOVEMENT",
        displayName = "Running",
        description = "Moving at increased speed",
        exclusive = true,
        transitions = {
            WALK = true,
            IDLE = true,
            BLOCK = true,
            ROLL = true,
            SLIDE = true,
            DASH = true
        }
    },

    SLIDE = {
        category = "MOVEMENT",
        displayName = "Sliding",
        description = "Executing a slide",
        exclusive = true,
        duration = 0.7,
        cooldown = 0.2,
        transitions = {
            RUN = true,
            ROLL = true,
            DASH = true
        }
    },

    WALL_RUN = {
        category = "MOVEMENT",
        displayName = "Wall Running",
        description = "Running along a wall",
        exclusive = true,
        transitions = {
            WALL_CLIMB = true,
            JUMP = true,
            HANG = true
        }
    },

    WALL_CLIMB = {
        category = "MOVEMENT",
        displayName = "Wall Climbing",
        description = "Climbing a wall",
        exclusive = true,
        transitions = {
            WALL_RUN = true,
            HANG = true
        }
    },

    HANG = {
        category = "MOVEMENT",
        displayName = "Ledge Hanging",
        description = "Hanging from a ledge",
        exclusive = true,
        transitions = {
            WALL_CLIMB = true,
            JUMP = true
        }
    },

    JUMP = {
        category = "MOVEMENT",
        displayName = "Jumping",
        description = "In mid-air jump",
        exclusive = true,
        duration = 0.5,
        transitions = {
            WALL_RUN = true,
            HANG = true,
            ROLL = true
        }
    },

    LAND = {
        category = "MOVEMENT",
        displayName = "Landing",
        description = "Landing from a jump or fall",
        exclusive = true,
        duration = 0.5,
        cooldown = 0.1,
        transitions = {
            WALK = true,
            RUN = true,
            ROLL = true,
            CROUCH = true,
            IDLE = true
        }
    },

    SWING = {
        category = "MOVEMENT",
        displayName = "Swinging",
        description = "Swinging from an object",
        exclusive = true,
        transitions = {
            JUMP = true,
            HANG = true
        }
    },

    DASH = {
        category = "MOVEMENT",
        displayName = "Dashing",
        description = "Executing a quick dash",
        exclusive = true,
        duration = 0.3,
        cooldown = 0.2,
        transitions = {
            RUN = true,
            ROLL = true,
            SLIDE = true
        }
    },

    VAULT = {
        category = "MOVEMENT",
        displayName = "Vaulting",
        description = "Vaulting over an obstacle",
        exclusive = true,
        duration = 0.5,
        cooldown = 0.2,
        transitions = {
            RUN = true,
            ROLL = true
        }
    },

    CROUCH = {
        category = "MOVEMENT",
        displayName = "Crouching",
        description = "In crouched position",
        exclusive = true,
        transitions = {
            SLIDE = true,
            ROLL = true,
            RUN = true
        }
    },

    SWIM = {
        category = "MOVEMENT",
        displayName = "Swimming",
        description = "Moving through water",
        exclusive = true,
        transitions = {
            JUMP = true,
            SPRINT = false,
            ROLL = false,
            ATTACK = true,
            BLOCK = false
        },
        onEnter = function(entity)
            if entity:GetAttribute("UNDERWATER") then
                entity:SetAttribute("UNDERWATER", true)
            end
        end,
        onExit = function(entity)
            if entity:GetAttribute("UNDERWATER") then
                entity:SetAttribute("UNDERWATER", false)
            end
        end
    },

    -- Status States
    KNOCK = {
        category = "STATUS",
        displayName = "Knocked Out",
        description = "Incapacitated and vulnerable",
        exclusive = true,
        transitions = {
            DEAD = true,
            EXECUTE = false
        }
    },

    EXECUTE = {
        category = "STATUS",
        displayName = "Executing",
        description = "Performing execution on knocked enemy",
        exclusive = true,
        duration = 2,
        transitions = {
            KNOCK = false
        }
    },

    DEAD = {
        category = "STATUS",
        displayName = "Dead",
        description = "Character is dead",
        exclusive = true,
        transitions = {}
    },

    CARRY = {
        category = "STATUS",
        displayName = "Carrying",
        description = "Carrying another character",
        exclusive = true,
        transitions = {
            RUN = true,
            ROLL = false,
            ATTACK = false
        }
    },

    GRIP = {
        category = "STATUS",
        displayName = "Gripped",
        description = "Being held by another character",
        exclusive = true,
        transitions = {
            ATTACK = false,
            BLOCK = false,
            ROLL = false
        }
    },

    INVINCIBLE = {
        category = "STATUS",
        displayName = "Invincible",
        description = "Temporarily immune to all damage",
        exclusive = true,
        duration = 0.5,
        transitions = {
            ATTACK = true,
            BLOCK = true,
            ROLL = true
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
    INTERACT = {
        category = "INTERACTION",
        displayName = "Interacting",
        description = "Interacting with object/entity",
        exclusive = true,
        transitions = {
            ATTACK = false,
            ROLL = true
        }
    },

    -- Emote States
    EMOTE = {
        category = "EMOTE",
        displayName = "Emoting",
        description = "Playing an emote animation",
        exclusive = true,
        transitions = {
            ATTACK = true,
            ROLL = true,
            BLOCK = true
        }
    }
}

return StateModule