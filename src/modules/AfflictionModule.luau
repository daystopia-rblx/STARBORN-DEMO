--[[ AfflictionModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local AfflictionModule = {}

function AfflictionModule.GetPlague(name: string)
    name = name:upper()
    if AfflictionModule.Templates[name] then return AfflictionModule.Templates[name] end
    for _, category in pairs(AfflictionModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

AfflictionModule.Constants = {
    MAX_STAGES = 3,
    MAX_INFECTION_CHANCE = 0.25,

    DEFAULT_CHECK_INTERVAL = 30,
    DEFAULT_PROGRESS_INTERVAL = 300,
    DEFAULT_IMMUNITY_DURATION = 43200,

    SEVERITY = {
        MILD = 0.33,
        MODERATE = 0.66,
        SEVERE = 1.0
    },

    ALCHEMY_XP = {
        CURE_ATTEMPT = 1,
        CURE_SUCCESS = 5,
        CURE_DIFFICULT = 10
    }
}

AfflictionModule.Categories = {
    ENVIRONMENTAL = "Environmental Diseases",
    MAGICAL = "Magical Afflictions",
    UNDEAD = "Undead Curses",
    ELEMENTAL = "Elemental Maladies"
}

AfflictionModule.CategoryGroups = {
    ENVIRONMENTAL = {
        "MARSH_ROT",
        "CAVE_FEVER",
        "DESERT_HEAT",
        "MOUNTAIN_CHILL"
    },
    MAGICAL = {
        "CORRUPTION",
        "ARCANE_FLUX",
        "MANA_SICKNESS"
    },
    UNDEAD = {
        "GRAVE_CHILL",
        "SPECTRAL_DRAIN"
    },
    ELEMENTAL = {
        "FIRE_FEVER",
        "FROST_BLIGHT",
        "STONE_LUNGS"
    }
}

AfflictionModule.Templates = {
    ENVIRONMENTAL = {
        MARSH_ROT = {
            name = "Marsh Rot",
            description = "A disease caught in swampy areas that slowly drains vitality.",
            zones = {"SWAMP", "MARSH", "BOG"},
            infectionChance = 0.05,
            checkInterval = 30,
            progressInterval = 300,
            stages = {
                [1] = {
                    name = "Early Symptoms",
                    description = "Mild fatigue and slight discomfort.",
                    duration = 1800,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.9 },
                        SPEED = { type = "MULTIPLY", value = 0.95 }
                    }
                },
                [2] = {
                    name = "Moderate Infection",
                    description = "Spreading infection weakens the body significantly.",
                    duration = 3600,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.7 },
                        SPEED = { type = "MULTIPLY", value = 0.8 },
                        HEALTH = { type = "MULTIPLY", value = 0.9 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.5 }
                    }
                },
                [3] = {
                    name = "Severe Infection",
                    description = "The disease has taken hold, causing severe debilitation.",
                    duration = 7200,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.5 },
                        SPEED = { type = "MULTIPLY", value = 0.6 },
                        HEALTH = { type = "MULTIPLY", value = 0.7 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.2 },
                        DAMAGE = { type = "MULTIPLY", value = 0.8 }
                    }
                }
            },
            cures = {
                HEALTH_POTION = { effectiveness = 0.3 },
                MANA_FRUIT = { effectiveness = 0.5 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 86400,
                resistance = 0.8
            }
        },

        CAVE_FEVER = {
            name = "Cave Fever",
            description = "A lung infection contracted in damp, dark caves.",
            zones = {"CAVE", "DUNGEON", "MINE"},
            infectionChance = 0.08,
            checkInterval = 45,
            progressInterval = 360,
            stages = {
                [1] = {
                    name = "Mild Fever",
                    description = "A slight fever and occasional coughing.",
                    duration = 1200,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.85 },
                        OXYGEN = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Respiratory Distress",
                    description = "Breathing becomes difficult and painful.",
                    duration = 2400,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.7 },
                        OXYGEN = { type = "MULTIPLY", value = 0.7 },
                        JUMP_POWER = { type = "MULTIPLY", value = 0.8 }
                    }
                },
                [3] = {
                    name = "Lung Infection",
                    description = "Severe respiratory infection impairing all physical activity.",
                    duration = 4800,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.5 },
                        OXYGEN = { type = "MULTIPLY", value = 0.5 },
                        JUMP_POWER = { type = "MULTIPLY", value = 0.5 },
                        SPEED = { type = "MULTIPLY", value = 0.7 }
                    }
                }
            },
            cures = {
                STRENGTH_POTION = { effectiveness = 0.4 },
                GOLDEN_APPLE = { effectiveness = 0.7 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 43200,
                resistance = 0.7
            }
        },

        DESERT_HEAT = {
            name = "Desert Heat",
            description = "A malady caused by extreme heat exposure and dehydration.",
            zones = {"DESERT"},
            infectionChance = 0.1,
            checkInterval = 30,
            progressInterval = 240,
            stages = {
                [1] = {
                    name = "Heat Exhaustion",
                    description = "Fatigue and dizziness from heat exposure.",
                    duration = 900, -- 15 minutes
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.85 },
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        THIRST = { type = "ADD", value = -2 }
                    }
                },
                [2] = {
                    name = "Heat Stroke",
                    description = "Body temperature rising to dangerous levels.",
                    duration = 1800,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.7 },
                        SPEED = { type = "MULTIPLY", value = 0.8 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        THIRST = { type = "ADD", value = -4 },
                        HEALTH = { type = "ADD", value = -1 }
                    }
                },
                [3] = {
                    name = "Critical Dehydration",
                    description = "Severe dehydration causing organ failure.",
                    duration = 2700,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.4 },
                        SPEED = { type = "MULTIPLY", value = 0.6 },
                        HEALTH = { type = "MULTIPLY", value = 0.8 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.6 }
                    },
                    tickEffects = {
                        THIRST = { type = "ADD", value = -6 },
                        HEALTH = { type = "ADD", value = -3 }
                    }
                }
            },
            cures = {
                WATER = { effectiveness = 0.6 },
                CAKE = { effectiveness = 0.3 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 43200,
                resistance = 0.6
            },
            recoveryEffects = {
                THIRST = { type = "ADD", value = 50, duration = 60 },
                STAMINA_REGEN = { type = "MULTIPLY", value = 1.5, duration = 300 }
            }
        },

        MOUNTAIN_CHILL = {
            name = "Mountain Chill",
            description = "A condition caused by extreme cold at high altitudes.",
            zones = {"MOUNTAIN"},
            infectionChance = 0.07,
            checkInterval = 40,
            progressInterval = 300,
            stages = {
                [1] = {
                    name = "Mild Hypothermia",
                    description = "Shivering and reduced dexterity from cold exposure.",
                    duration = 1200,
                    effects = {
                        DEXTERITY = { type = "MULTIPLY", value = 0.9 },
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Moderate Hypothermia",
                    description = "Continued cold exposure causing confusion and weakness.",
                    duration = 2400,
                    effects = {
                        DEXTERITY = { type = "MULTIPLY", value = 0.7 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.8 },
                        STAMINA = { type = "MULTIPLY", value = 0.8 },
                        SPEED = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [3] = {
                    name = "Severe Hypothermia",
                    description = "Life-threatening drop in body temperature.",
                    duration = 3600,
                    effects = {
                        DEXTERITY = { type = "MULTIPLY", value = 0.5 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.6 },
                        STAMINA = { type = "MULTIPLY", value = 0.6 },
                        SPEED = { type = "MULTIPLY", value = 0.7 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.5 }
                    },
                    tickEffects = {
                        HEALTH = { type = "ADD", value = -0.5 }
                    }
                }
            },
            cures = {
                ROAST = { effectiveness = 0.5 },
                STEW = { effectiveness = 0.7 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 36000,
                resistance = 0.7
            },
            recoveryEffects = {
                STAMINA = { type = "ADD", value = 20, duration = 120 },
                HEALTH_REGEN = { type = "MULTIPLY", value = 1.3, duration = 600 }
            }
        }
    },

    MAGICAL = {
        CORRUPTION = {
            name = "Corruption",
            description = "A magical affliction caused by proximity to dark energies.",
            zones = {"CORRUPTION", "VOID", "DARK_SHRINE"},
            infectionChance = 0.1,
            checkInterval = 20,
            progressInterval = 240,
            stages = {
                [1] = {
                    name = "Dark Whispers",
                    description = "Strange whispers distract the mind.",
                    duration = 900,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 0.8 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Shadowed Mind",
                    description = "Thoughts become clouded with dark influence.",
                    duration = 1800,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 0.6 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.7 },
                        MANA = { type = "MULTIPLY", value = 0.8 }
                    }
                },
                [3] = {
                    name = "Corrupted Soul",
                    description = "The corruption has seeped into your very being.",
                    duration = 3600,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 0.4 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.5 },
                        MANA = { type = "MULTIPLY", value = 0.6 },
                        HEALTH = { type = "MULTIPLY", value = 0.8 }
                    }
                }
            },
            cures = {
                MANA_POTION = { effectiveness = 0.3 },
                INVISIBILITY_POTION = { effectiveness = 0.5 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 21600,
                resistance = 0.6
            }
        },

        ARCANE_FLUX = {
            name = "Arcane Flux",
            description = "An unstable condition caused by exposure to wild magical energies.",
            zones = {"ARCANE_GROVE", "CRYSTAL_CAVE", "ANCIENT_RUINS"},
            infectionChance = 0.06,
            checkInterval = 35,
            progressInterval = 260,
            stages = {
                [1] = {
                    name = "Magical Disruption",
                    description = "Minor interference with spell casting and magical abilities.",
                    duration = 1500,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 0.85 },
                        MANA_REGEN = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Arcane Instability",
                    description = "Magic becomes unpredictable and difficult to control.",
                    duration = 3000,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 0.7 },
                        MANA_REGEN = { type = "MULTIPLY", value = 0.7 },
                        MANA = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        MANA = { type = "ADD", value = function(player)
                            return math.random(-5, 5)
                        end }
                    }
                },
                [3] = {
                    name = "Magical Overload",
                    description = "Dangerous magical energies surge through your body.",
                    duration = 4500,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 0.5 },
                        MANA_REGEN = { type = "MULTIPLY", value = 0.5 },
                        MANA = { type = "MULTIPLY", value = 0.6 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        MANA = { type = "ADD", value = function(player)
                            return math.random(-10, 10)
                        end },
                        HEALTH = { type = "ADD", value = function(player)
                            if math.random() < 0.05 then
                                return -2
                            end
                            return 0
                        end }
                    }
                }
            },
            cures = {
                MANA_POTION = { effectiveness = 0.6 },
                MANA_FRUIT = { effectiveness = 0.8 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 28800,
                resistance = 0.7
            },
            recoveryEffects = {
                MANA_REGEN = { type = "MULTIPLY", value = 1.5, duration = 900 },
                MAGIC = { type = "MULTIPLY", value = 1.1, duration = 600 }
            }
        },

        MANA_SICKNESS = {
            name = "Mana Sickness",
            description = "An illness caused by prolonged exposure to concentrated mana.",
            zones = {"ENCHANTED_FOREST"},
            infectionChance = 0.04,
            checkInterval = 60,
            progressInterval = 400,
            stages = {
                [1] = {
                    name = "Mana Sensitivity",
                    description = "Increased sensitivity to magical energies.",
                    duration = 2400,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 1.1 }, -- Actually enhanced
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Mana Oversaturation",
                    description = "Body struggling to contain excess magical energy.",
                    duration = 3600,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 1.2 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.7 },
                        STAMINA = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        HEALTH = { type = "ADD", value = -0.5 }
                    }
                },
                [3] = {
                    name = "Mana Poisoning",
                    description = "Magical energy causing internal damage to the body.",
                    duration = 5400,
                    effects = {
                        MAGIC = { type = "MULTIPLY", value = 1.3 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.4 },
                        STAMINA = { type = "MULTIPLY", value = 0.7 },
                        HEALTH = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        HEALTH = { type = "ADD", value = -1 },
                        MANA = { type = "ADD", value = 1 }
                    }
                }
            },
            cures = {
                HEALTH_POTION = { effectiveness = 0.4 },
                GOLDEN_APPLE = { effectiveness = 0.7 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 43200,
                resistance = 0.6
            }
        }
    },

    UNDEAD = {
        GRAVE_CHILL = {
            name = "Grave Chill",
            description = "A supernatural cold contracted from undead entities.",
            zones = {"CRYPT", "CATACOMB"},
            infectionChance = 0.08,
            checkInterval = 40,
            progressInterval = 320,
            stages = {
                [1] = {
                    name = "Ghostly Touch",
                    description = "Unnatural cold sensation penetrating to the bone.",
                    duration = 1800,
                    effects = {
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.9 },
                        RESOLVE = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Spectral Frost",
                    description = "Supernatural cold spreading through your body.",
                    duration = 3600,
                    effects = {
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.7 },
                        RESOLVE = { type = "MULTIPLY", value = 0.7 },
                        SPEED = { type = "MULTIPLY", value = 0.9 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.8 }
                    }
                },
                [3] = {
                    name = "Death's Embrace",
                    description = "Life force being drained by otherworldly cold.",
                    duration = 5400,
                    effects = {
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.5 },
                        RESOLVE = { type = "MULTIPLY", value = 0.5 },
                        SPEED = { type = "MULTIPLY", value = 0.8 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.5 },
                        HEALTH = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        HEALTH = { type = "ADD", value = function(player)
                            local timeOfDay = game:GetService("Lighting").TimeOfDay
                            local hour = tonumber(string.sub(timeOfDay, 1, 2))
                            if hour >= 18 or hour <= 6 then
                                return -1
                            end
                            return -0.5
                        end }
                    }
                }
            },
            cures = {
                STRENGTH_POTION = { effectiveness = 0.5 },
                GOLDEN_APPLE = { effectiveness = 0.7 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 36000,
                resistance = 0.7
            },
            recoveryEffects = {
                RESOLVE = { type = "ADD", value = 5, duration = 1800 },
                HEALTH_REGEN = { type = "MULTIPLY", value = 1.3, duration = 600 }
            }
        },

        SPECTRAL_DRAIN = {
            name = "Spectral Drain",
            description = "A curse that siphons life energy, caused by contact with spirits.",
            zones = {"VOID", "DARK_SHRINE"},
            infectionChance = 0.05,
            checkInterval = 50,
            progressInterval = 380,
            stages = {
                [1] = {
                    name = "Spiritual Fatigue",
                    description = "A feeling of being watched and drained of energy.",
                    duration = 2400,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.9 },
                        MANA = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Soul Leech",
                    description = "An invisible force slowly draining your life energy.",
                    duration = 4800,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.8 },
                        MANA = { type = "MULTIPLY", value = 0.8 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.8 },
                        MAGIC = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        STAMINA = { type = "ADD", value = -1 },
                        MANA = { type = "ADD", value = -1 }
                    }
                },
                [3] = {
                    name = "Essence Theft",
                    description = "Your very life force is being stolen by unseen entities.",
                    duration = 7200,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.6 },
                        MANA = { type = "MULTIPLY", value = 0.6 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.5 },
                        MAGIC = { type = "MULTIPLY", value = 0.7 },
                        HEALTH = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        STAMINA = { type = "ADD", value = -2 },
                        MANA = { type = "ADD", value = -2 },
                        HEALTH = { type = "ADD", value = -0.5 }
                    }
                }
            },
            cures = {
                MANA_POTION = { effectiveness = 0.4 },
                INVISIBILITY_POTION = { effectiveness = 0.6 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 43200,
                resistance = 0.6
            }
        }
    },

    ELEMENTAL = {
        FIRE_FEVER = {
            name = "Fire Fever",
            description = "An intense fever caused by exposure to elemental fire.",
            zones = {},
            infectionChance = 0.15,
            checkInterval = 30,
            progressInterval = 200,
            stages = {
                [1] = {
                    name = "Burning Blood",
                    description = "Your blood feels like it's boiling.",
                    duration = 1200,
                    effects = {
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.8 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        THIRST = { type = "ADD", value = -1 }
                    }
                },
                [2] = {
                    name = "Internal Combustion",
                    description = "Your core temperature rises to dangerous levels.",
                    duration = 2400,
                    effects = {
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.6 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.7 },
                        SPEED = { type = "MULTIPLY", value = 0.9 }
                    },
                    tickEffects = {
                        THIRST = { type = "ADD", value = -2 },
                        HEALTH = { type = "ADD", value = -0.5 }
                    }
                },
                [3] = {
                    name = "Flame Incarnate",
                    description = "Your body is wracked with unbearable heat.",
                    duration = 3600,
                    effects = {
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.4 },
                        INTELLIGENCE = { type = "MULTIPLY", value = 0.5 },
                        SPEED = { type = "MULTIPLY", value = 0.8 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.5 }
                    },
                    tickEffects = {
                        THIRST = { type = "ADD", value = -3 },
                        HEALTH = { type = "ADD", value = -1 }
                    }
                }
            },
            cures = {
                WATER = { effectiveness = 0.5 },
                SPEED_POTION = { effectiveness = 0.3 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 28800,
                resistance = 0.8
            }
        },

        FROST_BLIGHT = {
            name = "Frost Blight",
            description = "A magical cold that penetrates deeper than natural frost.",
            zones = {},
            infectionChance = 0.15,
            checkInterval = 30,
            progressInterval = 240,
            stages = {
                [1] = {
                    name = "Frozen Touch",
                    description = "Your extremities become numb with magical cold.",
                    duration = 1500,
                    effects = {
                        DEXTERITY = { type = "MULTIPLY", value = 0.9 },
                        SPEED = { type = "MULTIPLY", value = 0.95 }
                    }
                },
                [2] = {
                    name = "Creeping Ice",
                    description = "Magical frost creeps through your veins.",
                    duration = 3000,
                    effects = {
                        DEXTERITY = { type = "MULTIPLY", value = 0.7 },
                        SPEED = { type = "MULTIPLY", value = 0.8 },
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        STAMINA = { type = "ADD", value = -1 }
                    }
                },
                [3] = {
                    name = "Heart of Ice",
                    description = "The magical cold reaches your core, freezing you from within.",
                    duration = 4500,
                    effects = {
                        DEXTERITY = { type = "MULTIPLY", value = 0.5 },
                        SPEED = { type = "MULTIPLY", value = 0.6 },
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.5 },
                        HEALTH_REGEN = { type = "MULTIPLY", value = 0.7 }
                    },
                    tickEffects = {
                        STAMINA = { type = "ADD", value = -2 },
                        HEALTH = { type = "ADD", value = -0.5 }
                    }
                }
            },
            cures = {
                ROAST = { effectiveness = 0.4 },
                STRENGTH_POTION = { effectiveness = 0.6 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 28800,
                resistance = 0.8
            }
        },

        STONE_LUNGS = {
            name = "Stone Lungs",
            description = "A condition where earth magic gradually solidifies the lungs.",
            zones = {},
            infectionChance = 0.1,
            checkInterval = 40,
            progressInterval = 300,
            stages = {
                [1] = {
                    name = "Dusty Breath",
                    description = "Your breathing becomes labored, with dust in every exhale.",
                    duration = 2400,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.9 },
                        OXYGEN = { type = "MULTIPLY", value = 0.9 }
                    }
                },
                [2] = {
                    name = "Gravel Cough",
                    description = "Your coughs bring up small stones and your chest feels heavy.",
                    duration = 4800,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.7 },
                        OXYGEN = { type = "MULTIPLY", value = 0.7 },
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        OXYGEN = { type = "ADD", value = -1 }
                    }
                },
                [3] = {
                    name = "Petrifying Lungs",
                    description = "Your lungs are gradually turning to stone.",
                    duration = 7200,
                    effects = {
                        STAMINA = { type = "MULTIPLY", value = 0.5 },
                        OXYGEN = { type = "MULTIPLY", value = 0.5 },
                        STAMINA_REGEN = { type = "MULTIPLY", value = 0.5 },
                        SPEED = { type = "MULTIPLY", value = 0.8 }
                    },
                    tickEffects = {
                        OXYGEN = { type = "ADD", value = -2 },
                        HEALTH = { type = "ADD", value = -0.5 }
                    }
                }
            },
            cures = {
                WATER = { effectiveness = 0.3 },
                MANA_POTION = { effectiveness = 0.5 },
                ELIXIR = { effectiveness = 1.0 }
            },
            immunity = {
                duration = 36000,
                resistance = 0.7
            },
            recoveryEffects = {
                OXYGEN = { type = "ADD", value = 20, duration = 300 },
                STAMINA_REGEN = { type = "MULTIPLY", value = 1.2, duration = 900 }
            }
        }
    }
}

return AfflictionModule