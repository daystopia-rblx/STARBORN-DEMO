--[[ ObjectModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-03-31
]]
local ObjectModule = {}

function ObjectModule.GetObject(name: string)
    name = name:upper()
    if ObjectModule.Templates[name] then return ObjectModule.Templates[name] end
    for _, category in pairs(ObjectModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

ObjectModule.Categories = {
    FURNITURE = "Furniture",
    CHECKPOINTS = "Checkpoints",
    MISC_ITEMS = "Miscellaneous Items",
    VALUABLES = "Valuables",
    BOOKS = "Books",
    KEYS = "Keys",
    TOOLS = "Tools"
}

ObjectModule.CategoryGroups = {
    FURNITURE = {
        "SEATING"
    },
    CHECKPOINTS = {
        "BONFIRE",
        "BED"
    },
    MISC_ITEMS = {
        "CONTAINERS",
        "MISCELLANEOUS"
    },
    VALUABLES = {
        "JEWELRY",
        "TREASURES"
    },
    BOOKS = {
        "COMMON_BOOKS",
        "MAGIC_BOOKS"
    },
    KEYS = {
        "KEYS"
    },
    TOOLS = {
        "FARMING_TOOLS",
        "SMITHING_TOOLS",
        "WRITING_TOOLS",
        "UTILITY_TOOLS"
    }
}

ObjectModule.Templates = {
    SEATING = {
        CHAIR = {
            defaults = { properties = { interaction = "seat" } },
            variants = {
                wooden = { name = "Wooden Chair", prefix = "Wooden", price = 10.00, description = "A basic wooden chair" },
            }
        }
    },

    CHECKPOINTS = {
        BONFIRE = {
            defaults = { properties = { interaction = "rest", checkpoint = true, heal_rate = 1.0 } },
            variants = {
                standard = { name = "Bonfire", description = "A place of respite. Rest here to restore health and set your spawn point." }
            }
        },
        BED = {
            defaults = { properties = { interaction = "rest", checkpoint = true, heal_rate = 1.5 } },
            variants = {
                standard = { name = "Bed", description = "A modest bed for resting. Rest here to restore health and set your spawn point." }
            }
        }
    },

    CONTAINERS = {
        WATER_FLASK = {
            defaults = { properties = { interaction = "use", value = 5 } },
            variants = {
                standard = { name = "Water Flask", description = "A flask filled with clean water" }
            }
        },
        WOODEN_BOWL = {
            defaults = { properties = { interaction = "collect", value = 2 } },
            variants = {
                standard = { name = "Wooden Bowl", description = "A simple wooden bowl" }
            }
        },
        WOODEN_MUG = {
            defaults = { properties = { interaction = "collect", value = 3 } },
            variants = {
                standard = { name = "Wooden Mug", description = "A sturdy drinking vessel" }
            }
        },
        WOODEN_CUP = {
            defaults = { properties = { interaction = "collect", value = 2 } },
            variants = {
                standard = { name = "Wooden Cup", description = "A simple drinking cup" }
            }
        }
    },

    FARMING_TOOLS = {
        WATERING_CAN = {
            defaults = { properties = { interaction = "use", value = 15, tool = true } },
            variants = {
                standard = { name = "Watering Can", description = "Used to water crops and plants" }
            }
        },
        SOW = {
            defaults = { properties = { interaction = "use", value = 18, tool = true } },
            variants = {
                standard = { name = "Sow", description = "Used to till soil for planting" }
            }
        },
        SICKLE = {
            defaults = { properties = { interaction = "use", value = 20, tool = true } },
            variants = {
                standard = { name = "Sickle", description = "Used to harvest crops efficiently" }
            }
        }
    },

    SMITHING_TOOLS = {
        HAMMER = {
            defaults = { properties = { interaction = "use", value = 25, tool = true } },
            variants = {
                standard = { name = "Hammer", description = "A sturdy smithing hammer" }
            }
        },
        TONGS = {
            defaults = { properties = { interaction = "use", value = 15, tool = true } },
            variants = {
                standard = { name = "Tongs", description = "Used for handling hot metal in forges" }
            }
        }
    },

    WRITING_TOOLS = {
        QUILL = {
            defaults = { properties = { interaction = "use", value = 8, tool = true } },
            variants = {
                standard = { name = "Quill", description = "A writing implement made from a feather" }
            }
        },
        INK_BOTTLE = {
            defaults = { properties = { interaction = "use", value = 12, tool = true } },
            variants = {
                standard = { name = "Ink Bottle", description = "A small bottle of black ink" }
            }
        },
        PARCHMENT = {
            defaults = { properties = { interaction = "use", value = 5, tool = true } },
            variants = {
                standard = { name = "Parchment", description = "Prepared animal skin for writing" }
            }
        }
    },

    JEWELRY = {
        COPPER_RING = {
            defaults = { properties = { interaction = "collect", value = 15, equipable = true } },
            variants = {
                standard = { name = "Copper Ring", description = "A simple ring made of copper" }
            }
        },
        SILVER_RING = {
            defaults = { properties = { interaction = "collect", value = 40, equipable = true } },
            variants = {
                standard = { name = "Silver Ring", description = "A ring made of polished silver" }
            }
        },
        GOLD_RING = {
            defaults = { properties = { interaction = "collect", value = 80, equipable = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Gold Ring", description = "A valuable ring made of gold" }
            }
        },
        GOLD_NECKLACE = {
            defaults = { properties = { interaction = "collect", value = 100, equipable = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Gold Necklace", description = "An elegant necklace made of gold" }
            }
        },
        FANCY_BROOCH = {
            defaults = { properties = { interaction = "collect", value = 120, equipable = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Fancy Brooch", description = "An ornate brooch with decorative elements" }
            }
        },
        SILVER_GOBLET = {
            defaults = { properties = { interaction = "collect", value = 35 } },
            variants = {
                standard = { name = "Silver Goblet", description = "A drinking vessel made of silver" }
            }
        },
        GOLDEN_GOBLET = {
            defaults = { properties = { interaction = "collect", value = 90, rarity = "RARE" } },
            variants = {
                standard = { name = "Golden Goblet", description = "A drinking vessel made of gold" }
            }
        }
    },

    COMMON_BOOKS = {
        BOOK = {
            defaults = { properties = { interaction = "read", value = 10 } },
            variants = {
                standard = { name = "Common Book", description = "A typical book with mundane information" }
            }
        },
        SCROLL = {
            defaults = { properties = { interaction = "read", value = 8 } },
            variants = {
                standard = { name = "Torn Scroll", description = "A damaged scroll with partial information" }
            }
        },
        NOTES = {
            defaults = { properties = { interaction = "read", value = 20 } },
            variants = {
                standard = { name = "Notes", description = "Notes taken by a learned individual" }
            }
        },
        MAP = {
            defaults = { properties = { interaction = "read", value = 40, rarity = "UNCOMMON" } },
            variants = {
                standard = { name = "Map", description = "A map showing locations" }
            }
        },
        SCHEMATICS = {
            defaults = { properties = { interaction = "read", value = 75, rarity = "RARE" } },
            variants = {
                standard = { name = "Schematics", description = "Technical drawings for advanced designs" }
            }
        }
    },

    MAGIC_BOOKS = {
        TOME = {
            defaults = { properties = { interaction = "read", value = 50, rarity = "UNCOMMON" } },
            variants = {
                standard = { name = "Tome", description = "A book containing magical knowledge" }
            }
        },
        SPELLBOOK = {
            defaults = { properties = { interaction = "read", value = 100, rarity = "RARE" } },
            variants = {
                standard = { name = "Spellbook", description = "A book containing magical spells" }
            }
        },
        MANUSCRIPT = {
            defaults = { properties = { interaction = "read", value = 150, rarity = "RARE" } },
            variants = {
                standard = { name = "Manuscript", description = "An extremely old document with historical significance" }
            }
        }
    },

    KEYS = {
        SMALL_KEY = {
            defaults = { properties = { interaction = "use", value = 10, key = true } },
            variants = {
                standard = { name = "Small Key", description = "A basic key that opens simple locks" }
            }
        },
        MERCHANT_KEY = {
            defaults = { properties = { interaction = "use", value = 30, key = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Merchant Key", description = "A key belonging to a merchant" }
            }
        },
        SHOP_KEY = {
            defaults = { properties = { interaction = "use", value = 35, key = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Shop Key", description = "A key that opens a shop door or container" }
            }
        },
        FORGE_KEY = {
            defaults = { properties = { interaction = "use", value = 40, key = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Forge Key", description = "A key that opens a blacksmith's forge" }
            }
        },
        CELL_KEY = {
            defaults = { properties = { interaction = "use", value = 50, key = true, rarity = "EPIC" } },
            variants = {
                standard = { name = "Cell Key", description = "A key that opens prison cells" }
            }
        },
        INN_KEY = {
            defaults = { properties = { interaction = "use", value = 20, key = true } },
            variants = {
                standard = { name = "Inn Key", description = "A key to a room at an inn" }
            }
        },
        TEMPLE_KEY = {
            defaults = { properties = { interaction = "use", value = 60, key = true, rarity = "RARE" } },
            variants = {
                standard = { name = "Temple Key", description = "A key that opens sacred areas of a temple" }
            }
        }
    },

    MISCELLANEOUS = {
        TEST_PICKUP = {
            defaults = { properties = { interaction = "pickup", value = 5 } },
            variants = {
                standard = { name = "Unowned Item", description = "An item that can be picked up by anyone" }
            }
        },

        TEST_OWNED = {
            defaults = { properties = { interaction = "pickup", value = 10 } },
            variants = {
                standard = {
                    name = "Owned Item",
                    description = "A test item with an owner",
                    initialAttributes = { OWNER = "TestOwner" }
                }
            }
        }
    }
}

return ObjectModule