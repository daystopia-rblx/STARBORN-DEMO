--[[ CraftModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-11
]]
local CraftModule = {}

function CraftModule.GetCraft(name: string)
    name = name:upper()

    if CraftModule.Templates[name] then return CraftModule.Templates[name] end
    for _, category in pairs(CraftModule.Templates) do
        if category[name] then return category[name] end
    end

    if CraftModule.Crafting[name] then return CraftModule.Crafting[name] end
    if CraftModule.Crafting.CRAFT_TYPES[name] then return CraftModule.Crafting.CRAFT_TYPES[name] end
    if CraftModule.Crafting.CRAFT_PROCESSES[name] then return CraftModule.Crafting.CRAFT_PROCESSES[name] end

    for _, category in pairs(CraftModule.Crafting.CRAFT_PROCESSES) do
        if category[name] then return category[name] end
    end
    return nil
end

function CraftModule.GetStation(name: string): table?
    name = name:upper()
    for _, stationGroup in pairs(CraftModule.CategoryGroups.STATIONS) do
        if CraftModule.Templates[stationGroup][name] then
            return CraftModule.Templates[stationGroup][name]
        end
    end
    return nil
end

function CraftModule.GetMaterial(name: string): table?
    name = name:upper()
    for _, materialGroup in pairs(CraftModule.CategoryGroups.MATERIALS) do
        if CraftModule.Templates[materialGroup][name] then
            return CraftModule.Templates[materialGroup][name]
        end
    end
    return nil
end

function CraftModule.GetProcess(name: string): table?
    name = name:upper()
    for _, processGroup in pairs(CraftModule.CategoryGroups.PROCESSES) do
        if CraftModule.Crafting.CRAFT_PROCESSES[processGroup]
           and CraftModule.Crafting.CRAFT_PROCESSES[processGroup][name] then
            return CraftModule.Crafting.CRAFT_PROCESSES[processGroup][name]
        end
    end
    return nil
end

function CraftModule.GetType(name: string): table?
    return CraftModule.Crafting.CRAFT_TYPES[name:upper()]
end

function CraftModule.GetStations(craftType: string): {string}?
    local type = CraftModule.GetType(craftType)
    if not type then return {} end

    if type.defaults and type.defaults.properties and type.defaults.properties.stations then
        return type.defaults.properties.stations
    elseif type.stations then
        return type.stations
    end

    return {}
end

function CraftModule.CanCraft(craftType: string, stationName: string): boolean
    craftType = craftType:upper()
    stationName = stationName:upper()

    local station = CraftModule.GetStation(stationName)
    if not station then return false end

    local allowedTypes = station.defaults.properties.allowedTypes
    for _, allowedType in ipairs(allowedTypes) do
        if allowedType == craftType then
            return true
        end
    end

    return false
end

CraftModule.Categories = {
    STATIONS = "Crafting Stations",
    MATERIALS = "Crafting Materials",
    PROCESSES = "Crafting Processes"
}

CraftModule.CategoryGroups = {
    STATIONS = {
        "WEAPON_STATIONS",
        "ALCHEMY_STATIONS",
        "COOKING_STATIONS",
        "FARMING_STATIONS"
    },
    MATERIALS = {
        "RAW_MATERIALS",
        "PROCESSED_MATERIALS", 
        "MODIFIER_MATERIALS",
        "METAL_MATERIALS",
        "FABRIC_MATERIALS",
        "FARMING_MATERIALS",
        "ALCHEMY_MATERIALS"
    },
    PROCESSES = {
        "SMITHING_PROCESSES",
        "BREWING_PROCESSES",
        "COOKING_PROCESSES",
        "FARMING_PROCESSES"
    }
}

CraftModule.CRAFT_TYPES = {
    WEAPON_FORGING = "WEAPON_FORGING",
    ARMOR_SMITHING = "ARMOR_SMITHING",
    COOKING = "COOKING",
    ALCHEMY = "ALCHEMY"
}

CraftModule.STATION_TYPES = {
    ANVIL = "ANVIL",
    FORGE = "FORGE",
    CAULDRON = "CAULDRON",
    CAMPFIRE = "CAMPFIRE",
    ALCHEMY_TABLE = "ALCHEMY_TABLE",
    WORKBENCH = "WORKBENCH",
    FARMPLOT = "FARMPLOT"
}

CraftModule.MATERIAL_TYPES = {
    CORE = "CORE",
    MODIFIER = "MODIFIER",
    CATALYST = "CATALYST"
}

CraftModule.TIERS = {
    TIER_1 = "TIER_1",
    TIER_2 = "TIER_2",
    TIER_3 = "TIER_3"
}

--[[ Templates ]]
CraftModule.Templates = {
    WEAPON_STATIONS = {
        ANVIL = {
            defaults = { properties = { interact = "craft", tier = 1, allowedTypes = { CraftModule.CRAFT_TYPES.WEAPON_FORGING, CraftModule.CRAFT_TYPES.ARMOR_SMITHING } } },
            variants = {
                standard = { name = "Anvil", description = "Used for forging weapons and armor" },
                reinforced = { name = "Reinforced Anvil", description = "An improved anvil for more complex weapon forging" }
            }
        },
        FORGE = {
            defaults = { properties = { interact = "craft", tier = 2, allowedTypes = { CraftModule.CRAFT_TYPES.WEAPON_FORGING, CraftModule.CRAFT_TYPES.ARMOR_SMITHING } } },
            variants = { standard = { name = "Forge", description = "A basic forge for creating metal items" } }
        }
    },

    ALCHEMY_STATIONS = {
        CAULDRON = {
            defaults = { properties = { interact = "craft", tier = 1, allowedTypes = { CraftModule.CRAFT_TYPES.ALCHEMY } } },
            variants = { standard = { name = "Cauldron", description = "Used for brewing potions and alchemical mixtures" } }
        },
        ALCHEMY_TABLE = {
            defaults = { properties = { interact = "craft", tier = 2, allowedTypes = { CraftModule.CRAFT_TYPES.ALCHEMY } } },
            variants = { standard = { name = "Alchemy Table", description = "A specialized table for advanced potion crafting" } }
        }
    },

    COOKING_STATIONS = {
        CAMPFIRE = {
            defaults = { properties = { interact = "craft", tier = 1, allowedTypes = { CraftModule.CRAFT_TYPES.COOKING } } },
            variants = { standard = { name = "Campfire", description = "Used for cooking food and simple recipes" } }
        }
    },

    FARMING_STATIONS = {
        FARMPLOT = {
            defaults = { properties = { interact = "plant", tier = 1, allowedTypes = { CraftModule.CRAFT_TYPES.COOKING } } },
            variants = { standard = { name = "Farm Plot", description = "Tilled soil for planting crops" } }
        },
        WORKBENCH = {
            defaults = { properties = { interact = "craft", tier = 1, allowedTypes = { CraftModule.CRAFT_TYPES.COOKING, CraftModule.CRAFT_TYPES.WEAPON_FORGING } } },
            variants = { standard = { name = "Workbench", description = "A simple workbench for various crafting tasks" } }
        }
    },

    RAW_MATERIALS = {
        IRON = {
            defaults = { properties = { rarity = 0.5, type = CraftModule.MATERIAL_TYPES.CORE, value = 10 } },
            variants = {
                standard = { name = "Iron", description = "Common metal used in various crafting recipes" },
                pure = { name = "Pure Iron", description = "High-quality iron with fewer impurities", value = 15 }
            }
        },
        HERBS = {
            defaults = { properties = { rarity = 0.3, type = CraftModule.MATERIAL_TYPES.CORE, value = 5 } },
            variants = { standard = { name = "Herbs", description = "Various plants used in cooking and alchemy" } }
        },
        WHEAT = {
            defaults = { properties = { rarity = 0.2, type = CraftModule.MATERIAL_TYPES.CORE, value = 5 } },
            variants = { standard = { name = "Wheat", description = "A bundle of wheat stalks for baking and brewing" } }
        }
    },

    PROCESSED_MATERIALS = {
        FLOUR = {
            defaults = { properties = { rarity = 0.25, type = CraftModule.MATERIAL_TYPES.CORE, value = 8 } },
            variants = { standard = { name = "Flour", description = "Ground wheat for baking bread and pastries" } }
        },
        LEATHER = {
            defaults = { properties = { rarity = 0.4, type = CraftModule.MATERIAL_TYPES.CORE, value = 8 } },
            variants = { standard = { name = "Leather", description = "Flexible material used for armor and clothing" } }
        }
    },

    MODIFIER_MATERIALS = {
        SHADOWBARK = {
            defaults = { properties = { rarity = 0.8, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 50, effect_type = "BLEED", effect_potency = 2, effect_duration = 5 } },
            variants = { standard = { name = "Shadowbark", description = "Rare bark that adds bleeding effects to weapons" } }
        },
        DRAKHAAR_SCALE = {
            defaults = { properties = { rarity = 0.85, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 75, effect_type = "FIRE_RESIST", effect_potency = 25, effect_duration = 0 } },
            variants = { standard = { name = "Drakhaar Scale", description = "Rare dragon scale that adds fire resistance" } }
        },
        FANCY_CLOTH = {
            defaults = { properties = { rarity = 0.6, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 20, effect_type = "APPEARANCE", effect_potency = 1 } },
            variants = { standard = { name = "Fancy Cloth", description = "High-quality fabric for fine clothing" } }
        },
        EXOTIC_SPICE = {
            defaults = { properties = { rarity = 0.7, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 35, effect_type = "TASTE", effect_potency = 2 } },
            variants = { standard = { name = "Exotic Spice", description = "Rare spices from distant lands" } }
        },
        RARE_SPICE = {
            defaults = { properties = { rarity = 0.75, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 45, effect_type = "TASTE", effect_potency = 3 } },
            variants = { standard = { name = "Rare Spice", description = "Valuable spices that are hard to obtain" } }
        }
    },

    METAL_MATERIALS = {
        COPPER_INGOT = {
            defaults = { properties = { rarity = 0.4, type = CraftModule.MATERIAL_TYPES.CORE, value = 8 } },
            variants = { standard = { name = "Copper Ingot", description = "A bar of refined copper" } }
        },
        IRON_INGOT = {
            defaults = { properties = { rarity = 0.5, type = CraftModule.MATERIAL_TYPES.CORE, value = 15 } },
            variants = { standard = { name = "Iron Ingot", description = "A bar of refined iron" } }
        },
        STEEL_INGOT = {
            defaults = { properties = { rarity = 0.6, type = CraftModule.MATERIAL_TYPES.CORE, value = 25 } },
            variants = { standard = { name = "Steel Ingot", description = "A bar of refined steel" } }
        },
        IRON_SCRAPS = {
            defaults = { properties = { rarity = 0.3, type = CraftModule.MATERIAL_TYPES.CORE, value = 5 } },
            variants = { standard = { name = "Iron Scraps", description = "Leftover pieces of iron" } }
        },
        RARE_METAL_INGOT = {
            defaults = { properties = { rarity = 0.8, type = CraftModule.MATERIAL_TYPES.CORE, value = 100 } },
            variants = { standard = { name = "Rare Metal Ingot", description = "An ingot of unusually valuable metal" } }
        }
    },

    FABRIC_MATERIALS = {
        LEATHER_STRIPS = {
            defaults = { properties = { rarity = 0.35, type = CraftModule.MATERIAL_TYPES.CORE, value = 6 } },
            variants = { standard = { name = "Leather Strips", description = "Strips of leather for crafting" } }
        },
        CLOTH = {
            defaults = { properties = { rarity = 0.3, type = CraftModule.MATERIAL_TYPES.CORE, value = 5 } },
            variants = { standard = { name = "Cloth", description = "Woven fabric for various crafting needs" } }
        },
        THREAD = {
            defaults = { properties = { rarity = 0.25, type = CraftModule.MATERIAL_TYPES.CORE, value = 3 } },
            variants = { standard = { name = "Thread", description = "Spun fiber for sewing and binding" } }
        }
    },

    FARMING_MATERIALS = {
        SEEDS = {
            defaults = { properties = { rarity = 0.2, type = CraftModule.MATERIAL_TYPES.CORE, value = 2 } },
            variants = {
                wheat = { name = "Wheat Seeds", description = "Seeds for growing wheat" },
                vegetable = { name = "Vegetable Seeds", description = "Seeds for growing various vegetables" }
            }
        },
        FERTILIZER = {
            defaults = { properties = { rarity = 0.3, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 8, effect_type = "GROWTH", effect_potency = 1.5 } },
            variants = { standard = { name = "Fertilizer", description = "Improves soil quality and plant growth" } }
        }
    },

    ALCHEMY_MATERIALS = {
        HONEY = {
            defaults = { properties = { rarity = 0.4, type = CraftModule.MATERIAL_TYPES.CORE, value = 12 } },
            variants = { standard = { name = "Honey", description = "Sweet substance used in cooking and potion-making" } }
        },
        OIL = {
            defaults = { properties = { rarity = 0.35, type = CraftModule.MATERIAL_TYPES.CORE, value = 10 } },
            variants = { standard = { name = "Oil", description = "Flammable liquid with various uses" } }
        },
        MAGICAL_ESSENCE = {
            defaults = { properties = { rarity = 0.7, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 75 } },
            variants = { standard = { name = "Magical Essence", description = "Concentrated magical energy in liquid form" } }
        }
    }
}

CraftModule.Crafting = {
    CRAFT_PROCESSES = {
        SMITHING_PROCESSES = {
            FORGING = {
                defaults = { properties = { duration = 5, stationTypes = { CraftModule.STATION_TYPES.ANVIL, CraftModule.STATION_TYPES.FORGE } } },
                variants = { standard = { name = "Forging", description = "Hammer and shape metal to create weapons and armor" } }
            }
        },
        BREWING_PROCESSES = {
            BREWING = {
                defaults = { properties = { duration = 8, stationTypes = { CraftModule.STATION_TYPES.CAULDRON, CraftModule.STATION_TYPES.ALCHEMY_TABLE } } },
                variants = { standard = { name = "Brewing", description = "Mix ingredients to create potions" } }
            }
        },
        COOKING_PROCESSES = {
            COOKING = {
                defaults = { properties = { duration = 6, stationTypes = { CraftModule.STATION_TYPES.CAMPFIRE } } },
                variants = { standard = { name = "Cooking", description = "Prepare food over heat" } }
            }
        },
        FARMING_PROCESSES = {
            PLANTING = {
                defaults = { properties = { duration = 4, stationTypes = { CraftModule.STATION_TYPES.FARMPLOT } } },
                variants = { standard = { name = "Planting", description = "Sow seeds to grow crops" } }
            },
            HARVESTING = {
                defaults = { properties = { duration = 3, stationTypes = { CraftModule.STATION_TYPES.FARMPLOT } } },
                variants = { standard = { name = "Harvesting", description = "Gather mature crops" } }
            }
        }
    },

    CRAFT_TYPES = {
        WEAPON_FORGING = {
            defaults = { properties = { baseSuccessRate = 0.9, baseExperience = 25, stations = { CraftModule.STATION_TYPES.ANVIL, CraftModule.STATION_TYPES.FORGE } } },
            variants = { standard = { name = "Weapon Forging", description = "Create weapons from raw materials" } }
        },
        ARMOR_SMITHING = {
            defaults = { properties = { baseSuccessRate = 0.85, baseExperience = 30, stations = { CraftModule.STATION_TYPES.ANVIL, CraftModule.STATION_TYPES.FORGE } } },
            variants = { standard = { name = "Armor Smithing", description = "Create armor and protective gear" } }
        },
        COOKING = {
            defaults = { properties = { baseSuccessRate = 0.95, baseExperience = 15, stations = { CraftModule.STATION_TYPES.CAMPFIRE } } },
            variants = { standard = { name = "Cooking", description = "Prepare food with various benefits" } }
        },
        ALCHEMY = {
            defaults = { properties = { baseSuccessRate = 0.8, baseExperience = 35, stations = { CraftModule.STATION_TYPES.CAULDRON, CraftModule.STATION_TYPES.ALCHEMY_TABLE } } },
            variants = { standard = { name = "Alchemy", description = "Brew potions and magical mixtures" } }
        }
    }
}

return CraftModule