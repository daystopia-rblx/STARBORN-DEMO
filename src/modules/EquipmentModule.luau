--[[ EquipmentModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-07
]]
local EquipmentModule = {}

function EquipmentModule.GetEquipment(name: string)
    name = name:upper()
    if EquipmentModule.Templates[name] then return EquipmentModule.Templates[name] end
    for _, category in pairs(EquipmentModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

EquipmentModule.Categories = {
    LIGHT_ARMOR = "Light Armor",
    MEDIUM_ARMOR = "Medium Armor",
    HEAVY_ARMOR = "Heavy Armor",
    ACCESSORIES = "Accessories",
    TRINKETS = "Trinkets"
}

EquipmentModule.CategoryGroups = {
    LIGHT_ARMOR = {
        "LEATHER_HELMET",
        "LEATHER_CHEST",
        "LEATHER_LEGS",
        "LEATHER_BOOTS",
        "LEATHER_GLOVES"
    },
    MEDIUM_ARMOR = {
        "CHAIN_HELMET",
        "CHAIN_CHEST",
        "CHAIN_LEGS",
        "CHAIN_BOOTS",
        "CHAIN_GLOVES"
    },
    HEAVY_ARMOR = {
        "PLATE_HELMET",
        "PLATE_CHEST",
        "PLATE_LEGS",
        "PLATE_BOOTS",
        "PLATE_GLOVES"
    },
    ACCESSORIES = {
        "RING",
        "NECKLACE",
        "BELT"
    },
    TRINKETS = {
        "AMULET",
        "BRACELET",
        "EARRING"
    }
}

EquipmentModule.Templates = {
    LIGHT_ARMOR = {
        LEATHER_HELMET = {
            defaults = {
                slot = "HEAD", defense = 2, weight = 1.0,
                properties = { mobility = 1.0, stealth = 1.2 }
            },
            variants = {
                basic = { name = "Leather Cap", description = "Basic leather head protection" },
                reinforced = { name = "Reinforced Leather Cap", description = "Sturdier leather headgear" }
            }
        },
        LEATHER_CHEST = {
            defaults = {
                slot = "CHEST", defense = 3, weight = 2.0,
                properties = { mobility = 1.0, stealth = 1.2 }
            },
            variants = {
                basic = { name = "Leather Vest", description = "Basic leather torso protection" },
                reinforced = { name = "Reinforced Leather Vest", description = "Sturdier leather torso armor" }
            }
        },
        LEATHER_LEGS = {
            defaults = {
                slot = "LEGS", defense = 2, weight = 1.5,
                properties = { mobility = 1.0, stealth = 1.2 }
            },
            variants = {
                basic = { name = "Leather Pants", description = "Basic leather leg protection" },
                reinforced = { name = "Reinforced Leather Pants", description = "Sturdier leather leg armor" }
            }
        },
        LEATHER_BOOTS = {
            defaults = {
                slot = "FEET", defense = 1, weight = 0.5,
                properties = { mobility = 1.1, stealth = 1.3 }
            },
            variants = {
                basic = { name = "Leather Boots", description = "Basic leather foot protection" },
                reinforced = { name = "Reinforced Leather Boots", description = "Sturdier leather footwear" }
            }
        },
        LEATHER_GLOVES = {
            defaults = {
                slot = "HANDS", defense = 1, weight = 0.5,
                properties = { mobility = 1.1, stealth = 1.3 }
            },
            variants = {
                basic = { name = "Leather Gloves", description = "Basic leather hand protection" },
                reinforced = { name = "Reinforced Leather Gloves", description = "Sturdier leather handgear" }
            }
        }
    },

    MEDIUM_ARMOR = {
        CHAIN_HELMET = {
            defaults = {
                slot = "HEAD", defense = 4, weight = 2.0,
                properties = { mobility = 0.9, stealth = 0.8 }
            },
            variants = {
                basic = { name = "Chain Coif", description = "Basic chainmail head protection" },
                reinforced = { name = "Reinforced Chain Coif", description = "Sturdier chainmail headgear" }
            }
        },
        CHAIN_CHEST = {
            defaults = {
                slot = "CHEST", defense = 6, weight = 4.0,
                properties = { mobility = 0.9, stealth = 0.8 }
            },
            variants = {
                basic = { name = "Chain Hauberk", description = "Basic chainmail torso protection" },
                reinforced = { name = "Reinforced Chain Hauberk", description = "Sturdier chainmail torso armor" }
            }
        },
        CHAIN_LEGS = {
            defaults = {
                slot = "LEGS", defense = 4, weight = 3.0,
                properties = { mobility = 0.9, stealth = 0.8 }
            },
            variants = {
                basic = { name = "Chain Chausses", description = "Basic chainmail leg protection" },
                reinforced = { name = "Reinforced Chain Chausses", description = "Sturdier chainmail leg armor" }
            }
        },
        CHAIN_BOOTS = {
            defaults = {
                slot = "FEET", defense = 2, weight = 1.0,
                properties = { mobility = 0.95, stealth = 0.9 }
            },
            variants = {
                basic = { name = "Chain Boots", description = "Basic chainmail foot protection" },
                reinforced = { name = "Reinforced Chain Boots", description = "Sturdier chainmail footwear" }
            }
        },
        CHAIN_GLOVES = {
            defaults = {
                slot = "HANDS", defense = 2, weight = 1.0,
                properties = { mobility = 0.95, stealth = 0.9 }
            },
            variants = {
                basic = { name = "Chain Gauntlets", description = "Basic chainmail hand protection" },
                reinforced = { name = "Reinforced Chain Gauntlets", description = "Sturdier chainmail handgear" }
            }
        }
    },

    HEAVY_ARMOR = {
        PLATE_HELMET = {
            defaults = {
                slot = "HEAD", defense = 6, weight = 3.0,
                properties = { mobility = 0.8, stealth = 0.6 }
            },
            variants = {
                basic = { name = "Plate Helm", description = "Basic plate head protection" },
                reinforced = { name = "Reinforced Plate Helm", description = "Sturdier plate headgear" }
            }
        },
        PLATE_CHEST = {
            defaults = {
                slot = "CHEST", defense = 8, weight = 6.0,
                properties = { mobility = 0.8, stealth = 0.6 }
            },
            variants = {
                basic = { name = "Plate Cuirass", description = "Basic plate torso protection" },
                reinforced = { name = "Reinforced Plate Cuirass", description = "Sturdier plate torso armor" }
            }
        },
        PLATE_LEGS = {
            defaults = {
                slot = "LEGS", defense = 6, weight = 4.0,
                properties = { mobility = 0.8, stealth = 0.6 }
            },
            variants = {
                basic = { name = "Plate Greaves", description = "Basic plate leg protection" },
                reinforced = { name = "Reinforced Plate Greaves", description = "Sturdier plate leg armor" }
            }
        },
        PLATE_BOOTS = {
            defaults = {
                slot = "FEET", defense = 3, weight = 2.0,
                properties = { mobility = 0.85, stealth = 0.7 }
            },
            variants = {
                basic = { name = "Plate Sabatons", description = "Basic plate foot protection" },
                reinforced = { name = "Reinforced Plate Sabatons", description = "Sturdier plate footwear" }
            }
        },
        PLATE_GLOVES = {
            defaults = {
                slot = "HANDS", defense = 3, weight = 2.0,
                properties = { mobility = 0.85, stealth = 0.7 }
            },
            variants = {
                basic = { name = "Plate Gauntlets", description = "Basic plate hand protection" },
                reinforced = { name = "Reinforced Plate Gauntlets", description = "Sturdier plate handgear" }
            }
        }
    },

    ACCESSORIES = {
        RING = {
            defaults = {
                slot = "RING", defense = 0, weight = 0.1,
                properties = { magic = 1.1, luck = 1.05 }
            },
            variants = {
                silver = { name = "Silver Ring", description = "A simple silver ring" },
                gold = { name = "Gold Ring", description = "An elegant gold ring" }
            }
        },
        NECKLACE = {
            defaults = {
                slot = "NECKLACE", defense = 0, weight = 0.2,
                properties = { magic = 1.15, charisma = 1.1 }
            },
            variants = {
                silver = { name = "Silver Necklace", description = "A delicate silver necklace" },
                gold = { name = "Gold Necklace", description = "A luxurious gold necklace" }
            }
        },
        BELT = {
            defaults = {
                slot = "BELT", defense = 1, weight = 0.5,
                properties = { strength = 1.05, stamina = 1.1 }
            },
            variants = {
                leather = { name = "Leather Belt", description = "A sturdy leather belt" },
                reinforced = { name = "Reinforced Belt", description = "A reinforced leather belt" }
            }
        }
    },

    TRINKETS = {
        AMULET = {
            defaults = {
                slot = "NECKLACE", defense = 0, weight = 0.1,
                properties = { magic = 1.2, wisdom = 1.1 }
            },
            variants = {
                crystal = { name = "Crystal Amulet", description = "A mystical crystal amulet" },
                gem = { name = "Gem Amulet", description = "A precious gem amulet" }
            }
        },
        BRACELET = {
            defaults = {
                slot = "HANDS", defense = 0, weight = 0.2,
                properties = { agility = 1.1, dexterity = 1.05 }
            },
            variants = {
                silver = { name = "Silver Bracelet", description = "A delicate silver bracelet" },
                gold = { name = "Gold Bracelet", description = "An elegant gold bracelet" }
            }
        },
        EARRING = {
            defaults = {
                slot = "HEAD", defense = 0, weight = 0.1,
                properties = { perception = 1.1, charm = 1.05 }
            },
            variants = {
                silver = { name = "Silver Earring", description = "A simple silver earring" },
                gold = { name = "Gold Earring", description = "An elegant gold earring" }
            }
        }
    }
}

return EquipmentModule