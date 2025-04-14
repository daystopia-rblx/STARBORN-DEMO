--[[ ZoneModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-14
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

function ZoneModule.GetLocation(name: string)
    name = name:upper()
    if ZoneModule.Templates[name] then return ZoneModule.Templates[name] end
    for _, category in pairs(ZoneModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

function ZoneModule.GetHours(locationSubType)
    return locationSubType and ZoneModule.Hours[locationSubType:upper()] or nil
end

function ZoneModule.CheckOpen(template, currentHour)
    if not template or not template.hours then
        return false
    end

    local hours = template.hours

    if hours.hour_open == nil or hours.hour_close == nil then
        return false
    end

    if hours.hour_open < hours.hour_close then
        return currentHour >= hours.hour_open and currentHour < hours.hour_close
    else
        return currentHour >= hours.hour_open or currentHour < hours.hour_close
    end
end

ZoneModule.Categories = {
    -- Zones
    SAFE = "Safe Areas",
    WILDERNESS = "Wilderness Areas",
    DUNGEON = "Dungeon Areas",
    MAGICAL = "Magical Areas",
    CORRUPTED = "Corrupted Areas",

    -- Locations
    HOMES = "Residential Buildings",
    SHOPS = "Commercial Establishments",
    INNS = "Hospitality Locations",
    RELIGIOUS = "Religious Buildings",
    GOVERNMENT = "Government Buildings"
}

ZoneModule.CategoryGroups = {
    -- Zones
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
    },
    -- Locations
    HOMES = {
        "COMMONER_HOME",
        "NOBLE_MANSION"
    },
    SHOPS = {
        "GENERAL_STORE",
        "BLACKSMITH"
    },
    INNS = {
        "VILLAGE_INN"
    },
    RELIGIOUS = {
        "TEMPLE"
    }
}

ZoneModule.Hours = {
    STORE = {hour_open = 8, hour_close = 20},
    INN = {hour_open = 10, hour_close = 2},
    TEMPLE = {hour_open = 6, hour_close = 22},
    GUILD = {hour_open = 8, hour_close = 22},
    HOME = {hour_open = nil, hour_close = nil},
    BLACK_MARKET = {hour_open = 22, hour_close = 4},
    ALWAYS_OPEN = {hour_open = 0, hour_close = 24}
}

ZoneModule.Templates = {
    -- SAFE ZONES
    SAFE = {
        TOWN = {
            category = "SAFE",
            defaults = {zone = "default"},
            variants = {default = {name = "Town", description = "A bustling settlement with protective walls and guards."}}
        },
        VILLAGE = {
            category = "SAFE",
            defaults = {zone = "default"},
            variants = {default = {name = "Village", description = "A small rural settlement with simple defenses."}}
        },
        OUTPOST = {
            category = "SAFE",
            defaults = {zone = "default"},
            variants = {default = {name = "Outpost", description = "A fortified position at the edge of civilization."}}
        },
        SANCTUARY = {
            category = "SAFE",
            defaults = {zone = "default"},
            variants = {default = {name = "Sanctuary", description = "A blessed location protected by divine energy."}}
        }
    },

    -- WILDERNESS ZONES
    WILDERNESS = {
        FOREST = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Forest", description = "Dense woodland with abundant resources and wildlife."}}
        },
        SWAMP = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Swamp", description = "Waterlogged terrain with stagnant pools and thick vegetation."}}
        },
        MARSH = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Marsh", description = "Wetlands with reed beds and shallow waters."}}
        },
        BOG = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Bog", description = "Waterlogged, spongy terrain with acidic waters."}}
        },
        PLAINS = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Plains", description = "Open grasslands with sparse tree cover."}}
        },
        MOUNTAIN = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Mountain", description = "High elevation rocky terrain with steep slopes."}}
        },
        DESERT = {
            category = "WILDERNESS",
            defaults = {zone = "default"},
            variants = {default = {name = "Desert", description = "Arid, sandy region with extreme temperatures."}}
        }
    },

    -- DUNGEON ZONES
    DUNGEON = {
        CAVE = {
            category = "DUNGEON",
            defaults = {zone = "default"},
            variants = {default = {name = "Cave", description = "Natural underground hollow with limited light."}}
        },
        MINE = {
            category = "DUNGEON",
            defaults = {zone = "default"},
            variants = {default = {name = "Mine", description = "Excavated tunnels for resource extraction."}}
        },
        DUNGEON = {
            category = "DUNGEON",
            defaults = {zone = "default"},
            variants = {default = {name = "Dungeon", description = "Ancient constructed underground complex."}}
        },
        CRYPT = {
            category = "DUNGEON",
            defaults = {zone = "default"},
            variants = {default = {name = "Crypt", description = "Burial chambers housing the dead."}}
        },
        CATACOMB = {
            category = "DUNGEON",
            defaults = {zone = "default"},
            variants = {default = {name = "Catacomb", description = "Extensive network of underground burial tunnels."}}
        }
    },

    -- MAGICAL ZONES
    MAGICAL = {
        ARCANE_GROVE = {
            category = "MAGICAL",
            defaults = {zone = "default"},
            variants = {default = {name = "Arcane Grove", description = "Forest infused with natural magic energies."}}
        },
        CRYSTAL_CAVE = {
            category = "MAGICAL",
            defaults = {zone = "default"},
            variants = {default = {name = "Crystal Cave", description = "Cavern lined with magical crystals that emit light."}}
        },
        ANCIENT_RUINS = {
            category = "MAGICAL",
            defaults = {zone = "default"},
            variants = {default = {name = "Ancient Ruins", description = "Remnants of a lost magical civilization."}}
        },
        ENCHANTED_FOREST = {
            category = "MAGICAL",
            defaults = {zone = "default"},
            variants = {default = {name = "Enchanted Forest", description = "Woodland transformed by powerful enchantments."}}
        }
    },

    -- CORRUPTED ZONES
    CORRUPTED = {
        CORRUPTION = {
            category = "CORRUPTED",
            defaults = {zone = "default"},
            variants = {default = {name = "Corruption", description = "Land tainted by dark energies."}}
        },
        VOID = {
            category = "CORRUPTED",
            defaults = {zone = "default"},
            variants = {default = {name = "Void", description = "Area where reality has broken down."}}
        },
        DARK_SHRINE = {
            category = "CORRUPTED",
            defaults = {zone = "default"},
            variants = {default = {name = "Dark Shrine", description = "Unholy site dedicated to forbidden powers."}}
        },
        BLIGHT = {
            category = "CORRUPTED",
            defaults = {zone = "default"},
            variants = {default = {name = "Blight", description = "Land corrupted beyond recovery, leaching life itself."}}
        }
    },

    -- HOME LOCATIONS
    HOMES = {
        COMMONER_HOME = {
            category = "HOMES",
            defaults = { zone = "settlement", location_type = "interior", security = 1, ownership = "personal", guards = 0, lock_level = 1 },
            variants = { default = { name = "Commoner's Home", description = "A simple dwelling for common folk" } }
        },
        NOBLE_MANSION = {
            category = "HOMES",
            defaults = { zone = "settlement", location_type = "interior", security = 3, ownership = "personal", guards = 2, lock_level = 3 },
            variants = { default = { name = "Noble's Mansion", description = "An opulent residence for the wealthy" } }
        }
    },

    -- SHOP LOCATIONS
    SHOPS = {
        GENERAL_STORE = {
            category = "SHOPS",
            defaults = { zone = "settlement", location_type = "interior", security = 2, ownership = "personal", hours = ZoneModule.Hours.STORE, store_type = "general", guards = 0, lock_level = 2 },
            variants = { default = { name = "General Store", description = "A shop selling various goods and supplies" } }
        },
        BLACKSMITH = {
            category = "SHOPS",
            defaults = { zone = "settlement", location_type = "interior", security = 2, ownership = "personal", hours = ZoneModule.Hours.STORE, store_type = "smithy", guards = 0, lock_level = 2 },
            variants = { default = { name = "Blacksmith", description = "A forge for crafting and repairing metal items" } }
        }
    },

    -- INN LOCATIONS
    INNS = {
        VILLAGE_INN = {
            category = "INNS",
            defaults = { zone = "settlement", location_type = "interior", security = 2, ownership = "personal", hours = ZoneModule.Hours.INN, guards = 1, lock_level = 2 },
            variants = { default = { name = "Village Inn", description = "A cozy establishment offering food and lodging" } }
        }
    },

    -- RELIGIOUS LOCATIONS
    RELIGIOUS = {
        TEMPLE = {
            category = "RELIGIOUS",
            defaults = { zone = "settlement", location_type = "interior", security = 3, ownership = "faction", hours = ZoneModule.Hours.TEMPLE, guards = 2, lock_level = 3 },
            variants = { default = { name = "Temple", description = "A sacred place of worship and reflection" } }
        }
    }
}

return ZoneModule