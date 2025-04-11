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


ZoneModule.Constants = {
    DAMAGE = {
        CORRUPTION = 3,
        BLIGHT = 5,
        VOID = 7,
        HEAT = 2
    },

    PENALTIES = {
        DARKNESS_VISION = 0.5,
        DARKNESS_ATTACK = 0.7,
        CORRUPTION_MANA = 0.5
    },

    BONUSES = {
        REST = 1.5,
        MANA_REGEN = 2.0,
        HEALTH_REGEN = 1.5
    }
}

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
            type = "zone",
            zone = "default",
            name = "Town",
            description = "A bustling settlement with protective walls and guards."
        },
        VILLAGE = {
            type = "zone",
            zone = "default",
            name = "Village",
            description = "A small rural settlement with simple defenses."
        },
        OUTPOST = {
            type = "zone",
            zone = "default",
            name = "Outpost",
            description = "A fortified position at the edge of civilization."
        },
        SANCTUARY = {
            type = "zone",
            zone = "default",
            name = "Sanctuary",
            description = "A blessed location protected by divine energy."
        }
    },

    -- Wilderness Areas
    WILDERNESS = {
        FOREST = {
            type = "zone",
            zone = "default",
            name = "Forest",
            description = "Dense woodland with abundant resources and wildlife."
        },
        SWAMP = {
            type = "zone",
            zone = "default",
            name = "Swamp",
            description = "Waterlogged terrain with stagnant pools and thick vegetation."
        },
        MARSH = {
            type = "zone",
            zone = "default",
            name = "Marsh",
            description = "Wetlands with reed beds and shallow waters."
        },
        BOG = {
            type = "zone",
            zone = "default",
            name = "Bog",
            description = "Waterlogged, spongy terrain with acidic waters."
        },
        PLAINS = {
            type = "zone",
            zone = "default",
            name = "Plains",
            description = "Open grasslands with sparse tree cover."
        },
        MOUNTAIN = {
            type = "zone",
            zone = "default",
            name = "Mountain",
            description = "High elevation rocky terrain with steep slopes."
        },
        DESERT = {
            type = "zone",
            zone = "default",
            name = "Desert",
            description = "Arid, sandy region with extreme temperatures."
        }
    },

    -- Dungeon Areas
    DUNGEON = {
        CAVE = {
            type = "zone",
            zone = "default",
            name = "Cave",
            description = "Natural underground hollow with limited light."
        },
        MINE = {
            type = "zone",
            zone = "default",
            name = "Mine",
            description = "Excavated tunnels for resource extraction."
        },
        DUNGEON = {
            type = "zone",
            zone = "default",
            name = "Dungeon",
            description = "Ancient constructed underground complex."
        },
        CRYPT = {
            type = "zone",
            zone = "default",
            name = "Crypt",
            description = "Burial chambers housing the dead."
        },
        CATACOMB = {
            type = "zone",
            zone = "default",
            name = "Catacomb",
            description = "Extensive network of underground burial tunnels."
        }
    },

    -- Magical Areas
    MAGICAL = {
        ARCANE_GROVE = {
            type = "zone",
            zone = "default",
            name = "Arcane Grove",
            description = "Forest infused with natural magic energies."
        },
        CRYSTAL_CAVE = {
            type = "zone",
            zone = "default",
            name = "Crystal Cave",
            description = "Cavern lined with magical crystals that emit light."
        },
        ANCIENT_RUINS = {
            type = "zone",
            zone = "default",
            name = "Ancient Ruins",
            description = "Remnants of a lost magical civilization."
        },
        ENCHANTED_FOREST = {
            type = "zone",
            zone = "default",
            name = "Enchanted Forest",
            description = "Woodland transformed by powerful enchantments."
        }
    },

    -- Corrupted Areas
    CORRUPTED = {
        CORRUPTION = {
            type = "zone",
            zone = "default",
            name = "Corruption",
            description = "Land tainted by dark energies."
        },
        VOID = {
            type = "zone",
            zone = "default",
            name = "Void",
            description = "Area where reality has broken down."
        },
        DARK_SHRINE = {
            type = "zone",
            zone = "default",
            name = "Dark Shrine",
            description = "Unholy site dedicated to forbidden powers."
        },
        BLIGHT = {
            type = "zone",
            zone = "default",
            name = "Blight",
            description = "Land corrupted beyond recovery, leaching life itself."
        }
    }
}

return ZoneModule