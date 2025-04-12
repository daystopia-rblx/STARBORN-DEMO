--[[ FoodModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-11
]]
local FoodModule = {}

function FoodModule.GetFood(name: string)
    name = name:upper()
    if FoodModule.Templates[name] then return FoodModule.Templates[name] end
    for _, category in pairs(FoodModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

FoodModule.Categories = {
    COMMON_FOOD = "Common Food",
    RARE_FOOD = "Rare Food",
    EXOTIC_FOOD = "Exotic Food",
    POTIONS = "Potions"
}

FoodModule.CategoryGroups = {
    COMMON_FOOD = {
        "BREAD",
        "APPLE",
        "CHEESE",
        "STEW",
        "WATER"
    },
    RARE_FOOD = {
        "ROAST",
        "PIE",
        "WINE",
        "CAKE"
    },
    EXOTIC_FOOD = {
        "ELIXIR",
        "RESONANCE_FRUIT",
        "GOLDEN_APPLE",
        "DRAGON_STEAK"
    },
    POTIONS = {
        "HEALTH_POTION",
        "RESONANCE_POTION",
        "STRENGTH_POTION",
        "INVISIBILITY_POTION",
        "SPEED_POTION",
        "VITALITY_POTION",
        "FORTITUDE_POTION",
        "RESISTANCE_POTION",
        "REGENERATION_POTION"
    }
}

FoodModule.Templates = {
    COMMON_FOOD = {
        BREAD = {
            defaults = { tool = "food", duration = 60, useTime = 1.5, effects = { health = 5, stamina = 3 } },
            variants = {
                basic = { name = "Wheat Bread", description = "A simple loaf of bread" },
                dark = { name = "Dark Rye Bread", description = "A hearty dark bread" }
            }
        },
        APPLE = {
            defaults = { tool = "food", duration = 30, useTime = 1.2, effects = { health = 3, stamina = 5 } },
            variants = {
                red = { name = "Red Apple", description = "A crisp, juicy apple" }
            }
        },
        CHEESE = {
            defaults = { tool = "food", duration = 45, useTime = 1.0, effects = { health = 4, stamina = 2 } },
            variants = {
                cheddar = { name = "Cheddar Cheese", description = "A sharp, aged cheese" }
            }
        },
        STEW = {
            defaults = { tool = "food", duration = 90, useTime = 2.5, effects = { health = 8, stamina = 6 } },
            variants = {
                beef = { name = "Beef Stew", description = "A hearty meat stew" }
            }
        },
        WATER = {
            defaults = { tool = "drink", duration = 20, useTime = 1.0, effects = { stamina = 6 } },
            variants = {
                fresh = { name = "Fresh Water", description = "Clean, refreshing water" }
            }
        }
    },

    RARE_FOOD = {
        ROAST = {
            defaults = { tool = "food", duration = 120, useTime = 3.0, effects = { health = 12, stamina = 10, strength = 2 } },
            variants = {
                venison = { name = "Venison Roast", description = "Tender roasted deer meat" }
            }
        },
        PIE = {
            defaults = { tool = "food", duration = 150, useTime = 2.0, effects = { health = 10, stamina = 8, intelligence = 2 } },
            variants = {
                berry = { name = "Berry Pie", description = "Sweet berry filling in a flaky crust" }
            }
        },
        CAKE = {
            defaults = { tool = "food", duration = 100, useTime = 2.0, effects = { health = 8, stamina = 12 } },
            variants = {
                chocolate = { name = "Chocolate Cake", description = "Rich, decadent chocolate cake" }
            }
        }
    },

    EXOTIC_FOOD = {
        RESONANCE_FRUIT = {
            defaults = { tool = "food", duration = 240, useTime = 1.5, effects = { magic = 25, intelligence = 5 } },
            variants = {
                blue = { name = "Blue Resonance Fruit", description = "Rare fruit that restores magical energy" }
            }
        },
        GOLDEN_APPLE = {
            defaults = { tool = "food", duration = 400, useTime = 2.0, effects = { health = 15, stamina = 15, strength = 3, dexterity = 3 } },
            variants = {
                enchanted = { name = "Enchanted Golden Apple", description = "Mythical apple with powerful enhancement properties" }
            }
        },
        DRAGON_STEAK = {
            defaults = { tool = "food", duration = 600, useTime = 4.0, effects = { health = 30, stamina = 30, strength = 10, resistance = 5 } },
            variants = {
                rare = { name = "Rare Dragon Steak", description = "Extremely rare meat with extraordinary properties" }
            }
        }
    },

    POTIONS = {
        HEALTH_POTION = {
            defaults = { tool = "drink", duration = 0, useTime = 0.8, effects = { health = 25 } },
            variants = {
                minor = { name = "Minor Health Potion", description = "Restores a small amount of health", effects = { health = 20 } },
                major = { name = "Major Health Potion", description = "Restores a significant amount of health", effects = { health = 60 }, rarity = "RARE" }
            }
        },
        RESONANCE_POTION = {
            defaults = { tool = "drink", duration = 0, useTime = 0.8, effects = { magic = 30 } },
            variants = {
                minor = { name = "Minor Resonance Potion", description = "Restores a small amount of magical energy", effects = { magic = 25 } },
                major = { name = "Major Resonance Potion", description = "Restores a significant amount of magical energy", effects = { magic = 75 }, rarity = "RARE" }
            }
        },
        STRENGTH_POTION = {
            defaults = { tool = "drink", duration = 300, useTime = 1.0, effects = { strength = 8 } },
            variants = {
                minor = { name = "Minor Strength Potion", description = "Slightly increases physical strength", effects = { strength = 7 }, duration = 240 },
                major = { name = "Major Strength Potion", description = "Significantly increases physical strength", effects = { strength = 22 }, duration = 480, rarity = "RARE" }
            }
        },
        INVISIBILITY_POTION = {
            defaults = { tool = "drink", duration = 120, useTime = 1.2, effects = { stealth = 20 } },
            variants = {
                minor = { name = "Minor Invisibility Potion", description = "Grants light invisibility", effects = { stealth = 20 }, duration = 90 },
                major = { name = "Major Invisibility Potion", description = "Grants significant invisibility", effects = { stealth = 45 }, duration = 240, rarity = "RARE" }
            }
        },
        SPEED_POTION = {
            defaults = { tool = "drink", duration = 150, useTime = 0.9, effects = { speed = 12 } },
            variants = {
                minor = { name = "Minor Speed Potion", description = "Slightly increases movement speed", effects = { speed = 10 }, duration = 120 },
                major = { name = "Major Speed Potion", description = "Significantly increases movement speed", effects = { speed = 30 }, duration = 240, rarity = "RARE" }
            }
        },
        VITALITY_POTION = {
            defaults = { tool = "drink", duration = 240, useTime = 1.0, effects = { stamina = 15, health_regen = 2 } },
            variants = {
                minor = { name = "Minor Vitality Potion", description = "Slightly increases stamina and health regeneration", effects = { stamina = 15, health_regen = 1 }, duration = 180 },
                major = { name = "Major Vitality Potion", description = "Significantly increases stamina and health regeneration", effects = { stamina = 40, health_regen = 4 }, duration = 420, rarity = "RARE" }
            }
        },
        FORTITUDE_POTION = {
            defaults = { tool = "drink", duration = 270, useTime = 1.0, effects = { defense = 10, resistance = 5 } },
            variants = {
                minor = { name = "Minor Fortitude Potion", description = "Slightly increases defense and resistance", effects = { defense = 8, resistance = 4 }, duration = 210 },
                major = { name = "Major Fortitude Potion", description = "Significantly increases defense and resistance", effects = { defense = 25, resistance = 12 }, duration = 450, rarity = "RARE" }
            }
        },
        RESISTANCE_POTION = {
            defaults = { tool = "drink", duration = 300, useTime = 1.0, effects = { fire_resist = 15, cold_resist = 15, poison_resist = 15 } },
            variants = {
                minor = { name = "Minor Resistance Potion", description = "Slightly increases elemental resistances", effects = { fire_resist = 15, cold_resist = 15, poison_resist = 15 }, duration = 240 },
                major = { name = "Major Resistance Potion", description = "Significantly increases elemental resistances", effects = { fire_resist = 40, cold_resist = 40, poison_resist = 40 }, duration = 480, rarity = "RARE" }
            }
        },
        REGENERATION_POTION = {
            defaults = { tool = "drink", duration = 180, useTime = 1.0, effects = { health_regen = 3, resonance_regen = 2 } },
            variants = {
                minor = { name = "Minor Regeneration Potion", description = "Grants slight health and magic regeneration", effects = { health_regen = 3, resonance_regen = 2 }, duration = 150 },
                major = { name = "Major Regeneration Potion", description = "Grants significant health and magic regeneration", effects = { health_regen = 9, resonance_regen = 6 }, duration = 360, rarity = "RARE" }
            }
        }
    }
}

return FoodModule