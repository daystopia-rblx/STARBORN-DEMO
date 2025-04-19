--[[ LootModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-18
]]
local LootModule = {}

LootModule.RARITY_VALUES = {
    COMMON = { min = 5, max = 30 },
    UNCOMMON = { min = 25, max = 75 },
    RARE = { min = 70, max = 150 },
    EPIC = { min = 140, max = 300 },
    LEGENDARY = { min = 280, max = 600 }
}

LootModule.TIER_TO_RARITY_MAPPING = {
    low = { "COMMON", "UNCOMMON" },
    medium = { "UNCOMMON", "RARE" },
    high = { "RARE", "EPIC", "LEGENDARY" }
}

LootModule.ENTITY = {
    VILLAGER = {
        default = {
            {id = "UMBRELS", weight = 70, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "BREAD", weight = 50, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "APPLE", weight = 30, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "COPPER_RING", weight = 20, rarity = "UNCOMMON", quantity = {min = 1, max = 1}}
        },
        farmer = {
            {id = "UMBRELS", weight = 50, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "WHEAT", weight = 70, rarity = "COMMON", quantity = {min = 2, max = 5}},
            {id = "APPLE", weight = 60, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "SICKLE", weight = 20, rarity = "UNCOMMON", quantity = {min = 1, max = 1}}
        },
        baker = {
            {id = "UMBRELS", weight = 60, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "BREAD", weight = 80, rarity = "COMMON", quantity = {min = 1, max = 3}}
        }
    },
    MERCHANT = {
        default = {
            {id = "UMBRELS", weight = 80, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "SILVER_RING", weight = 30, rarity = "UNCOMMON", quantity = {min = 1, max = 1}}
        },
        general = {
            {id = "UMBRELS", weight = 80, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "SILVER_RING", weight = 25, rarity = "UNCOMMON", quantity = {min = 1, max = 1}}
        },
        blacksmith = {
            {id = "UMBRELS", weight = 70, rarity = "COMMON", quantity = {min = 1, max = 3}},
            {id = "IRON_INGOT", weight = 50, rarity = "COMMON", quantity = {min = 1, max = 2}},
            {id = "HAMMER", weight = 30, rarity = "UNCOMMON", quantity = {min = 1, max = 1}}
        }
    },
    GUARD = {
        default = {
            {id = "UMBRELS", weight = 60, rarity = "COMMON", quantity = {min = 1, max = 3}}
        },
        patrol = {
            {id = "UMBRELS", weight = 70, rarity = "COMMON", quantity = {min = 1, max = 3}}
        },
        captain = {
            {id = "UMBRELS", weight = 70, rarity = "UNCOMMON", quantity = {min = 1, max = 3}}
        }
    },
    NOBLE = {
        default = {
            {id = "UMBRELS", weight = 80, rarity = "UNCOMMON", quantity = {min = 1, max = 3}},
            {id = "GOLD_RING", weight = 40, rarity = "RARE", quantity = {min = 1, max = 1}},
            {id = "FANCY_BROOCH", weight = 20, rarity = "RARE", quantity = {min = 1, max = 1}}
        }
    }
}

LootModule.CONTAINER = {
    CHEST = {
        low = {
            {id = "UMBRELS", quantity = {min = 1, max = 3}},
            {id = "BREAD", quantity = {min = 1, max = 3}},
            {id = "APPLE", quantity = {min = 1, max = 3}}
        },
        medium = {
            {id = "SILVER_RING", quantity = {min = 1, max = 1}}
        },
        high = {
            {id = "GOLD_NECKLACE", quantity = {min = 1, max = 1}}
        }
    },
    CRATE = {
        low = {
            {id = "APPLE", quantity = {min = 1, max = 3}},
            {id = "WOODEN_MUG", quantity = {min = 1, max = 2}},
            {id = "COPPER_INGOT", quantity = {min = 1, max = 2}}
        },
        medium = {
            {id = "IRON_INGOT", quantity = {min = 1, max = 2}},
            {id = "FANCY_CLOTH", quantity = {min = 1, max = 1}}
        },
        high = {
            {id = "MAGICAL_ESSENCE", quantity = {min = 1, max = 1}}
        }
    },
    BARREL = {
        low = {
            {id = "WATER_FLASK", quantity = {min = 1, max = 2}},
            {id = "APPLE", quantity = {min = 1, max = 3}}
        },
        medium = {
            {id = "HONEY_JAR", quantity = {min = 1, max = 1}},
            {id = "OIL_FLASK", quantity = {min = 1, max = 1}}
        },
        high = {
            {id = "MAGICAL_ESSENCE", quantity = {min = 1, max = 1}}
        }
    }
}

LootModule.NODE = {
    OAK_TREE = {
        low = {
            {item = "oak_log", quantity = {1, 3}, weight = 80},
            {item = "oak_branch", quantity = {2, 4}, weight = 15},
            {item = "acorn", quantity = {1, 2}, weight = 5}
        }
    },
    PINE_TREE = {
        low = {
            {item = "pine_log", quantity = {1, 3}, weight = 75},
            {item = "pine_cone", quantity = {1, 3}, weight = 15},
            {item = "pine_needles", quantity = {2, 4}, weight = 10}
        }
    },
    BIRCH_TREE = {
         low = {
            {item = "birch_log", quantity = {1, 2}, weight = 80},
            {item = "birch_bark", quantity = {1, 3}, weight = 20}
        }
    },
    IRON_ORE = {
        low = {
            {item = "iron_ore", quantity = {1, 2}, weight = 100}
        },
        high = {
            {item = "iron_ore", quantity = {2, 3}, weight = 95},
            {item = "raw_gemstone", quantity = {1}, weight = 5}
        }
    },
    COPPER_ORE = {
        low = {
            {item = "copper_ore", quantity = {1, 3}, weight = 100}
        }
    },
    GOLD_ORE = {
        low = {
            {item = "gold_ore", quantity = {1, 2}, weight = 100}
        }
    },
    SILVER_ORE = {
        low = {
            {item = "silver_ore", quantity = {1, 2}, weight = 100}
        }
    },
    COTTON_PLANT = {
        low = {
            {item = "cotton_boll", quantity = {2, 4}, weight = 90},
            {item = "plant_fiber", quantity = {1, 2}, weight = 10}
        }
    },
    FLAX_PLANT = {
        low = {
            {item = "flax_fiber", quantity = {2, 4}, weight = 90},
            {item = "flax_seeds", quantity = {1, 2}, weight = 10}
        }
    },
    BERRY_BUSH = {
        low = {
            {item = "berries", quantity = {2, 5}, weight = 100}
        }
    },
    FIRE_CRYSTAL = {
        low = {
            {item = "fire_crystal_shard", quantity = {1, 2}, weight = 90},
            {item = "fire_dust", quantity = {2, 4}, weight = 10}
        }
    },
    WATER_CRYSTAL = {
        low = {
            {item = "water_crystal_shard", quantity = {1, 2}, weight = 90},
            {item = "water_dust", quantity = {2, 4}, weight = 10}
        }
    },
    CORAL = {
         low = {
            {item = "coral_fragment", quantity = {1, 2}, weight = 95},
            {item = "pearl", quantity = {1}, weight = 5}
        }
    }
}

function LootModule:GetTable(sourceType, sourceId, tier, variant)
    if not sourceType or not sourceId then return nil end

    sourceType = sourceType:upper()
    sourceId = sourceId:upper()
    tier = tier and tier:lower() or "low"
    variant = variant and variant:lower() or "default"

    if sourceType == "ENTITY" then
        local entityTable = self.ENTITY[sourceId]
        if not entityTable then return nil end

        return entityTable[variant] or entityTable.default
    elseif sourceType == "CONTAINER" then
        local containerTable = self.CONTAINER[sourceId]
        if not containerTable then return nil end

        return containerTable[tier] or containerTable.low
    elseif sourceType == "NODE" then
        local nodeTable = self.NODE[sourceId]
        if not nodeTable then return nil end

        return nodeTable[tier] or nodeTable.low
    end

    return nil
end

function LootModule:GetRarity(tier)
    tier = tier and tier:lower() or "low"
    return self.TIER_TO_RARITY_MAPPING[tier] or self.TIER_TO_RARITY_MAPPING.low
end

function LootModule:GetValue(rarity)
    rarity = rarity and rarity:upper() or "COMMON"
    return self.RARITY_VALUES[rarity] or self.RARITY_VALUES.COMMON
end

function LootModule:GetQuantity(itemData)
    if not itemData then return 1 end

    if itemData.quantity then
        local min = itemData.quantity.min or 1
        local max = itemData.quantity.max or min
        return math.random(min, max)
    end

    return 1
end

function LootModule:SelectItem(lootTable)
    if not lootTable or #lootTable == 0 then return nil end

    local totalWeight = 0
    for _, itemEntry in ipairs(lootTable) do
        totalWeight = totalWeight + (itemEntry.weight or 1)
    end

    if totalWeight <= 0 then
        return lootTable[math.random(1, #lootTable)]
    end

    local randomValue = math.random() * totalWeight
    local currentWeight = 0

    for _, itemEntry in ipairs(lootTable) do
        currentWeight = currentWeight + (itemEntry.weight or 1)
        if randomValue <= currentWeight then
            return itemEntry
        end
    end

    return lootTable[1]
end

return LootModule