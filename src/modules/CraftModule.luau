--[[ CraftModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local CraftModule = {}

function CraftModule.GetCraft(name: string)
    name = name:upper()
    if CraftModule.Templates[name] then return CraftModule.Templates[name] end
    for _, category in pairs(CraftModule.Templates) do
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
        if CraftModule.Templates[processGroup][name] then
            return CraftModule.Templates[processGroup][name]
        end
    end
    return nil
end

function CraftModule.GetType(name: string): table?
    return CraftModule.Templates[name:upper()]
end

function CraftModule.GetStations(craftType: string): {string}?
    local type = CraftModule.GetType(craftType)
    return type and type.defaults.properties.stations or {}
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
        "COOKING_STATIONS"
    },
    MATERIALS = {
        "CORE_MATERIALS", 
        "MODIFIER_MATERIALS"
    },
    PROCESSES = {
        "SMITHING_PROCESSES",
        "BREWING_PROCESSES",
        "COOKING_PROCESSES"
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
    WORKBENCH = "WORKBENCH"
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
    CORE_MATERIALS = {
        IRON = {
            defaults = { properties = { rarity = 0.5, type = CraftModule.MATERIAL_TYPES.CORE, value = 10 } },
            variants = {
                standard = { name = "Iron", description = "Common metal used in various crafting recipes", icon = "rbxassetid://12345700" },
                pure = { name = "Pure Iron", description = "High-quality iron with fewer impurities", icon = "rbxassetid://12345705", value = 15 }
            }
        },
        LEATHER = {
            defaults = { properties = { rarity = 0.4, type = CraftModule.MATERIAL_TYPES.CORE, value = 8 } },
            variants = { standard = { name = "Leather", description = "Flexible material used for armor and clothing", icon = "rbxassetid://12345701" } }
        },
        HERBS = {
            defaults = { properties = { rarity = 0.3, type = CraftModule.MATERIAL_TYPES.CORE, value = 5 } },
            variants = { standard = { name = "Herbs", description = "Various plants used in cooking and alchemy", icon = "rbxassetid://12345702" } }
        }
    },
    MODIFIER_MATERIALS = {
        SHADOWBARK = {
            defaults = { properties = { rarity = 0.8, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 50, effect_type = "BLEED", effect_potency = 2, effect_duration = 5 } },
            variants = { standard = { name = "Shadowbark", description = "Rare bark that adds bleeding effects to weapons", icon = "rbxassetid://12345703" } }
        },
        DRAKHAAR_SCALE = {
            defaults = { properties = { rarity = 0.85, type = CraftModule.MATERIAL_TYPES.MODIFIER, value = 75, effect_type = "FIRE_RESIST", effect_potency = 25, effect_duration = 0 } },
            variants = { standard = { name = "Drakhaar Scale", description = "Rare dragon scale that adds fire resistance", icon = "rbxassetid://12345704" } }
        }
    },
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
    WEAPON_FORGING = {
        defaults = { properties = { baseSuccessRate = 0.9, baseExperience = 25, stations = { CraftModule.STATION_TYPES.ANVIL, CraftModule.STATION_TYPES.FORGE } } },
        variants = { standard = { name = "Weapon Forging", description = "Create weapons from raw materials", icon = "rbxassetid://12345690" } }
    },
    ARMOR_SMITHING = {
        defaults = { properties = { baseSuccessRate = 0.85, baseExperience = 30, stations = { CraftModule.STATION_TYPES.ANVIL, CraftModule.STATION_TYPES.FORGE } } },
        variants = { standard = { name = "Armor Smithing", description = "Create armor and protective gear", icon = "rbxassetid://12345691" } }
    },
    COOKING = {
        defaults = { properties = { baseSuccessRate = 0.95, baseExperience = 15, stations = { CraftModule.STATION_TYPES.CAMPFIRE } } },
        variants = { standard = { name = "Cooking", description = "Prepare food with various benefits", icon = "rbxassetid://12345692" } }
    },
    ALCHEMY = {
        defaults = { properties = { baseSuccessRate = 0.8, baseExperience = 35, stations = { CraftModule.STATION_TYPES.CAULDRON, CraftModule.STATION_TYPES.ALCHEMY_TABLE } } },
        variants = { standard = { name = "Alchemy", description = "Brew potions and magical mixtures", icon = "rbxassetid://12345693" } }
    }
}

return CraftModule