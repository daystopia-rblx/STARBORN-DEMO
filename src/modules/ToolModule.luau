--[[ ToolModule
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-11
]]
local ToolModule = {}

--[[ Types ]]
type ToolContext = {
    id: string,
    tool: Tool,
    player: Player,
    [string]: any
}

--[[ Tool Types ]]
ToolModule.Types = {
    -- Light Weapons
    FISTS = "fists",
    DAGGER = "dagger",
    GUN = "gun",
    RAPIER = "rapier",
    NUNCHUCKS = "nunchucks",
    BOW = "bow",

    -- Medium Weapons
    LONGSWORD = "longsword",
    SPEAR = "spear",
    KATANA = "katana",
    RIFLE = "rifle",
    TRIDENT = "trident",

    -- Heavy Weapons
    GREATAXE = "greataxe",
    GREATSWORD = "greatsword",
    SCYTHE = "scythe",

    -- Tools
    FISHING_ROD = "fishing_rod",

    -- Consumables
    FOOD = "food",
    DRINK = "drink"
}

--[[ Tool Properties ]]
ToolModule.Properties = {
    CanBeDropped = false,
    Enabled = true,
    ManualActivationOnly = false,
    RequiresHandle = true,
    ToolTip = "",
    AutoPickup = false,

    cursors = {
        default = "",
        hover = "",
        invalid = "",
        active = ""
    },

    inputs = {
        primary = {
            type = "MouseButton1",
            usageType = "single", -- "single", "continuous", "charge", "toggle"
            cooldown = 0.1,
            holdDuration = 0,
            stateOnActivate = "",
            stateOnDeactivate = "",
            requiresState = {},
            preventInStates = {}
        },
        secondary = {
            type = "MouseButton2",
            usageType = "single",
            cooldown = 0.1,
            holdDuration = 0,
            stateOnActivate = "",
            stateOnDeactivate = "",
            requiresState = {},
            preventInStates = {}
        },
        tertiary = {
            type = "MouseButton3",
            usageType = "single",
            cooldown = 0.1,
            holdDuration = 0,
            stateOnActivate = "",
            stateOnDeactivate = "",
            requiresState = {},
            preventInStates = {}
        }
    },

    stateConfig = {
        initialState = "INACTIVE",
        transitions = {},
        onEnterState = {},
        onExitState = {},
        preventInputInStates = {},
    },

    animations = {
        idle = "",
        equip = "",
        unequip = "",
        activate = "",
        deactivate = "",
        states = {}
    },

    sounds = {
        equip = "",
        unequip = "",
        activate = "",
        deactivate = "",
        states = {}
    },

    dataSchema = {},
    defaultData = {},
}

--[[ Tool Templates ]]
ToolModule.Templates = {
    -- Light Weapons
    [ToolModule.Types.FISTS] = {
        ToolTip = "Left click to attack, right click for special moves",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.5,
                stateOnActivate = "ATTACKING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 1.0,
                stateOnActivate = "SPECIAL",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"ATTACKING", "SPECIAL"},
                ATTACKING = {"INACTIVE"},
                SPECIAL = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.DAGGER] = {
        ToolTip = "Left click to stab, right click to slash",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.4,
                stateOnActivate = "STABBING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 0.6,
                stateOnActivate = "SLASHING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"STABBING", "SLASHING"},
                STABBING = {"INACTIVE"},
                SLASHING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.GUN] = {
        ToolTip = "Left click to shoot, right click to aim",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.8,
                stateOnActivate = "SHOOTING",
                stateOnDeactivate = "INACTIVE",
                requiresState = {"INACTIVE", "AIMING"}
            },
            secondary = {
                type = "MouseButton2",
                usageType = "toggle",
                cooldown = 0.2,
                stateOnActivate = "AIMING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"AIMING", "SHOOTING"},
                AIMING = {"INACTIVE", "SHOOTING"},
                SHOOTING = {"INACTIVE", "AIMING"}
            }
        }
    },

    [ToolModule.Types.RAPIER] = {
        ToolTip = "Left click to thrust, right click to feint",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.5,
                stateOnActivate = "THRUSTING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 0.7,
                stateOnActivate = "FEINTING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"THRUSTING", "FEINTING"},
                THRUSTING = {"INACTIVE"},
                FEINTING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.NUNCHUCKS] = {
        ToolTip = "Left click to swing, right click to spin",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.4,
                stateOnActivate = "SWINGING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "continuous",
                cooldown = 0.1,
                stateOnActivate = "SPINNING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"SWINGING", "SPINNING"},
                SWINGING = {"INACTIVE"},
                SPINNING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.BOW] = {
        ToolTip = "Hold left click to charge, release to shoot",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "charge",
                cooldown = 0.1,
                holdDuration = 2,
                stateOnActivate = "CHARGING",
                stateOnDeactivate = "SHOOTING"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"CHARGING"},
                CHARGING = {"SHOOTING", "INACTIVE"},
                SHOOTING = {"INACTIVE"}
            }
        }
    },

    -- Medium Weapons
    [ToolModule.Types.LONGSWORD] = {
        ToolTip = "Left click to slash, right click for overhead",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.7,
                stateOnActivate = "SLASHING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 1.0,
                stateOnActivate = "OVERHEAD",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"SLASHING", "OVERHEAD"},
                SLASHING = {"INACTIVE"},
                OVERHEAD = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.SPEAR] = {
        ToolTip = "Left click to thrust, right click to sweep",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.6,
                stateOnActivate = "THRUSTING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 0.9,
                stateOnActivate = "SWEEPING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"THRUSTING", "SWEEPING"},
                THRUSTING = {"INACTIVE"},
                SWEEPING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.KATANA] = {
        ToolTip = "Left click to slash, right click for draw attack",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.5,
                stateOnActivate = "SLASHING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 1.2,
                stateOnActivate = "DRAWING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"SLASHING", "DRAWING"},
                SLASHING = {"INACTIVE"},
                DRAWING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.RIFLE] = {
        ToolTip = "Left click to shoot, right click to aim",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 1.0,
                stateOnActivate = "SHOOTING",
                stateOnDeactivate = "INACTIVE",
                requiresState = {"INACTIVE", "AIMING"}
            },
            secondary = {
                type = "MouseButton2",
                usageType = "toggle",
                cooldown = 0.2,
                stateOnActivate = "AIMING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"AIMING", "SHOOTING"},
                AIMING = {"INACTIVE", "SHOOTING"},
                SHOOTING = {"INACTIVE", "AIMING"}
            }
        }
    },

    [ToolModule.Types.TRIDENT] = {
        ToolTip = "Left click to thrust, right click to sweep",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.6,
                stateOnActivate = "THRUSTING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 0.9,
                stateOnActivate = "SWEEPING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"THRUSTING", "SWEEPING"},
                THRUSTING = {"INACTIVE"},
                SWEEPING = {"INACTIVE"}
            }
        }
    },

    -- Heavy Weapons
    [ToolModule.Types.GREATAXE] = {
        ToolTip = "Left click to chop, right click to sweep",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 1.2,
                stateOnActivate = "CHOPPING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 1.5,
                stateOnActivate = "SWEEPING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"CHOPPING", "SWEEPING"},
                CHOPPING = {"INACTIVE"},
                SWEEPING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.GREATSWORD] = {
        ToolTip = "Left click to slash, right click for overhead",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 1.0,
                stateOnActivate = "SLASHING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 1.3,
                stateOnActivate = "OVERHEAD",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"SLASHING", "OVERHEAD"},
                SLASHING = {"INACTIVE"},
                OVERHEAD = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.SCYTHE] = {
        ToolTip = "Left click to slash, right click to sweep",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.9,
                stateOnActivate = "SLASHING",
                stateOnDeactivate = "INACTIVE"
            },
            secondary = {
                type = "MouseButton2",
                usageType = "single",
                cooldown = 1.2,
                stateOnActivate = "SWEEPING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"SLASHING", "SWEEPING"},
                SLASHING = {"INACTIVE"},
                SWEEPING = {"INACTIVE"}
            }
        }
    },

    -- Tools
    [ToolModule.Types.FISHING_ROD] = {
        ToolTip = "Left click to cast, hold to reel",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "charge",
                cooldown = 0.1,
                holdDuration = 2,
                description = "Hold to charge cast power",
                stateOnActivate = "CHARGING",
                stateOnDeactivate = "CASTING",
                preventInStates = {"FISHING", "REELING"}
            },
            secondary = {
                type = "MouseButton2",
                usageType = "continuous",
                cooldown = 0.1,
                description = "Hold to reel",
                stateOnActivate = "REELING",
                stateOnDeactivate = "FISHING",
                requiresState = {"FISHING"}
            }
        },
        distance = 50,
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"CHARGING"},
                CHARGING = {"CASTING", "INACTIVE"},
                CASTING = {"FISHING"},
                FISHING = {"REELING", "INACTIVE"},
                REELING = {"FISHING", "INACTIVE"}
            }
        }
    },

    -- Consumables
    [ToolModule.Types.FOOD] = {
        ToolTip = "Left click to consume",
        AutoPickup = true,
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.2,
                stateOnActivate = "CONSUMING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"CONSUMING"},
                CONSUMING = {"INACTIVE"}
            }
        }
    },

    [ToolModule.Types.DRINK] = {
        ToolTip = "Left click to drink",
        AutoPickup = true,
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "single",
                cooldown = 0.2,
                stateOnActivate = "CONSUMING",
                stateOnDeactivate = "INACTIVE"
            }
        },
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"CONSUMING"},
                CONSUMING = {"INACTIVE"}
            }
        }
    }
}

--[[ Utility Functions ]]
function ToolModule:GetTemplate(toolType: string): {[string]: any}
    local normalizedToolType = toolType:gsub(" ", "_"):lower()

    local template = self.Templates[normalizedToolType]

    if not template then
        for typeName, typeValue in pairs(self.Types) do
            if typeValue:lower() == normalizedToolType or typeName:lower() == normalizedToolType then
                template = self.Templates[typeValue]
                break
            end
        end
    end

    if not template then
        warn("No template found for tool type:", toolType)
        return {}
    end

    local mergedTemplate = table.clone(self.Properties)
    for key, value in pairs(template) do
        if type(value) == "table" and type(mergedTemplate[key]) == "table" then
            for subKey, subValue in pairs(value) do
                mergedTemplate[key][subKey] = subValue
            end
        else
            mergedTemplate[key] = value
        end
    end

    return mergedTemplate
end

return ToolModule