--[[ ZoneModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local ZoneModule = {}

function ZoneModule.GetZone(name: string)
    name = name:upper()
    if ZoneModule.Templates[name] then return ZoneModule.Templates[name] end
    for _, category in pairs(ZoneModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

ZoneModule.Categories = {
    SAFE = "Safe Areas",
    WILDERNESS = "Wilderness Areas",
    DUNGEON = "Dungeon Areas",
    MAGICAL = "Magical Areas",
    CORRUPTED = "Corrupted Areas"
}

ZoneModule.CategoryGroups = {
    SAFE = {
        "TOWN",
        "VILLAGE",
        "OUTPOST",
        "SANCTUARY"
    },
    WILDERNESS = {
        "FOREST",
        "SWAMP",
        "MARSH",
        "BOG",
        "PLAINS",
        "MOUNTAIN",
        "DESERT"
    },
    DUNGEON = {
        "CAVE",
        "MINE",
        "DUNGEON",
        "CRYPT",
        "CATACOMB"
    },
    MAGICAL = {
        "ARCANE_GROVE",
        "CRYSTAL_CAVE",
        "ANCIENT_RUINS",
        "ENCHANTED_FOREST"
    },
    CORRUPTED = {
        "CORRUPTION",
        "VOID",
        "DARK_SHRINE",
        "BLIGHT"
    }
}
ZoneModule.Templates = {
    -- Safe Areas
    SAFE = {
        TOWN = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Town",
                    description = "A bustling settlement with protective walls and guards."
                }
            }
        },
        VILLAGE = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Village",
                    description = "A small rural settlement with simple defenses."
                }
            }
        },
        OUTPOST = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Outpost",
                    description = "A fortified position at the edge of civilization."
                }
            }
        },
        SANCTUARY = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Sanctuary",
                    description = "A blessed location protected by divine energy."
                }
            }
        }
    },

    -- Wilderness Areas
    WILDERNESS = {
        FOREST = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Forest",
                    description = "Dense woodland with abundant resources and wildlife."
                }
            }
        },
        SWAMP = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Swamp",
                    description = "Waterlogged terrain with stagnant pools and thick vegetation."
                }
            }
        },
        MARSH = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Marsh",
                    description = "Wetlands with reed beds and shallow waters."
                }
            }
        },
        BOG = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Bog",
                    description = "Waterlogged, spongy terrain with acidic waters."
                }
            }
        },
        PLAINS = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Plains",
                    description = "Open grasslands with sparse tree cover."
                }
            }
        },
        MOUNTAIN = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Mountain",
                    description = "High elevation rocky terrain with steep slopes."
                }
            }
        },
        DESERT = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Desert",
                    description = "Arid, sandy region with extreme temperatures."
                }
            }
        }
    },

    -- Dungeon Areas
    DUNGEON = {
        CAVE = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Cave",
                    description = "Natural underground hollow with limited light."
                }
            }
        },
        MINE = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Mine",
                    description = "Excavated tunnels for resource extraction."
                }
            }
        },
        DUNGEON = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Dungeon",
                    description = "Ancient constructed underground complex."
                }
            }
        },
        CRYPT = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Crypt",
                    description = "Burial chambers housing the dead."
                }
            }
        },
        CATACOMB = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Catacomb",
                    description = "Extensive network of underground burial tunnels."
                }
            }
        }
    },

    -- Magical Areas
    MAGICAL = {
        ARCANE_GROVE = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Arcane Grove",
                    description = "Forest infused with natural magic energies."
                }
            }
        },
        CRYSTAL_CAVE = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Crystal Cave",
                    description = "Cavern lined with magical crystals that emit light."
                }
            }
        },
        ANCIENT_RUINS = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Ancient Ruins",
                    description = "Remnants of a lost magical civilization."
                }
            }
        },
        ENCHANTED_FOREST = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Enchanted Forest",
                    description = "Woodland transformed by powerful enchantments."
                }
            }
        }
    },

    -- Corrupted Areas
    CORRUPTED = {
        CORRUPTION = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Corruption",
                    description = "Land tainted by dark energies."
                }
            }
        },
        VOID = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Void",
                    description = "Area where reality has broken down."
                }
            }
        },
        DARK_SHRINE = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Dark Shrine",
                    description = "Unholy site dedicated to forbidden powers."
                }
            }
        },
        BLIGHT = {
            defaults = {
                zone = "default",
            },
            variants = {
                default = {
                    name = "Blight",
                    description = "Land corrupted beyond recovery, leaching life itself."
                }
            }
        }
    }
}

return ZoneModule