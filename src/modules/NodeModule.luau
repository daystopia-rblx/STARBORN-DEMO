--[[ NodeModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-18
]]
local NodeModule = {}

function NodeModule.GetNode(name)
    name = name:upper()
    if NodeModule.Templates[name] then return NodeModule.Templates[name] end
    for _, category in pairs(NodeModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

NodeModule.Categories = {
    TREES = "Trees",
    ORES = "Ores",
    PLANTS = "Plants",
    CRYSTALS = "Crystals",
    UNDERWATER = "Underwater"
}

NodeModule.CategoryGroups = {
    TREES = {
        "COMMON_TREES",
        "RARE_TREES"
    },
    ORES = {
        "COMMON_ORES",
        "RARE_ORES"
    },
    PLANTS = {
        "FIBER_PLANTS",
        "FRUIT_PLANTS",
        "HERB_PLANTS"
    },
    CRYSTALS = {
        "ELEMENTAL_CRYSTALS",
        "MANA_CRYSTALS"
    },
    UNDERWATER = {
        "CORAL_TYPES",
        "SEAWEED_TYPES",
        "SHELLFISH"
    }
}

NodeModule.Templates = {
    COMMON_TREES = {
        OAK_TREE = {
            defaults = { durability = 100, hardness = 1.5, respawnTime = 300, interaction = "chop", tier = "low" },
            variants = {
                standard = { name = "Oak Tree", description = "A sturdy oak tree suitable for harvesting wood" },
                ancient = { name = "Ancient Oak", description = "An ancient oak with dense, high-quality wood", durability = 150, hardness = 2.0, tier = "low" }
            }
        },
        PINE_TREE = {
            defaults = { durability = 120, hardness = 1.7, respawnTime = 330, interaction = "chop", tier = "low" },
            variants = {
                standard = { name = "Pine Tree", description = "A tall pine tree with straight grain wood" }
            }
        },
        BIRCH_TREE = {
            defaults = { durability = 90, hardness = 1.3, respawnTime = 280, interaction = "chop", tier = "low" },
            variants = {
                standard = { name = "Birch Tree", description = "A slender birch tree with distinctive white bark" }
            }
        }
    },

    COMMON_ORES = {
        IRON_ORE = {
            defaults = { durability = 150, hardness = 2.0, respawnTime = 420, interaction = "mine", tier = "low" },
            variants = {
                standard = { name = "Iron Ore", description = "Common iron ore deposit" }
            }
        },
        COPPER_ORE = {
            defaults = { durability = 120, hardness = 1.8, respawnTime = 360, interaction = "mine", tier = "low" },
            variants = {
                standard = { name = "Copper Ore", description = "Reddish copper ore deposit" }
            }
        }
    },

    RARE_ORES = {
        GOLD_ORE = {
            defaults = { durability = 200, hardness = 2.5, respawnTime = 600, interaction = "mine", tier = "medium" },
            variants = {
                standard = { name = "Gold Ore", description = "Valuable gold ore vein" }
            }
        },
        SILVER_ORE = {
            defaults = { durability = 180, hardness = 2.3, respawnTime = 540, interaction = "mine", tier = "medium" },
            variants = {
                standard = { name = "Silver Ore", description = "Shimmering silver ore deposit" }
            }
        }
    },

    FIBER_PLANTS = {
        COTTON_PLANT = {
            defaults = { durability = 50, hardness = 1.0, respawnTime = 180, interaction = "harvest", tier = "low" },
            variants = {
                standard = { name = "Cotton Plant", description = "Fluffy cotton plants ready for harvesting" }
            }
        },
        FLAX_PLANT = {
            defaults = { durability = 45, hardness = 1.0, respawnTime = 160, interaction = "harvest", tier = "low" },
            variants = {
                standard = { name = "Flax Plant", description = "Tall flax plants used for making linen" }
            }
        }
    },

    FRUIT_PLANTS = {
        BERRY_BUSH = {
            defaults = { durability = 40, hardness = 1.0, respawnTime = 240, interaction = "gather", tier = "low" },
            variants = {
                standard = { name = "Berry Bush", description = "A bush laden with sweet berries" }
            }
        }
    },

    ELEMENTAL_CRYSTALS = {
        FIRE_CRYSTAL = {
            defaults = { durability = 100, hardness = 2.4, respawnTime = 1200, interaction = "mine", tier = "high" },
            variants = {
                standard = { name = "Fire Crystal", description = "A glowing red crystal radiating heat" }
            }
        },
        WATER_CRYSTAL = {
            defaults = { durability = 95, hardness = 2.0, respawnTime = 1200, interaction = "mine", tier = "high" },
            variants = {
                standard = { name = "Water Crystal", description = "A deep blue crystal with flowing patterns" }
            }
        }
    },

    CORAL_TYPES = {
        CORAL = {
            defaults = { durability = 70, hardness = 1.8, respawnTime = 720, interaction = "mine", underwater = true, tier = "medium" },
            variants = {
                standard = { name = "Coral", description = "Vibrant underwater coral formation" },
                brain = { name = "Brain Coral", description = "Coral with intricate brain-like patterns", tier = "medium" }
            }
        }
    }
}

return NodeModule