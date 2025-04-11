--[[ FoodModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
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
        "MANA_FRUIT",
        "GOLDEN_APPLE",
        "DRAGON_STEAK"
    },
    POTIONS = {
        "HEALTH_POTION",
        "MANA_POTION",
        "STRENGTH_POTION",
        "INVISIBILITY_POTION",
        "SPEED_POTION"
    }
}

FoodModule.Templates = {
    COMMON_FOOD = {
        BREAD = {
            defaults = { tool = "food", duration = 60, useTime = 1.5, statEffects = { health = 5, stamina = 3 } },
            variants = {
                basic = { name = "Wheat Bread", description = "A simple loaf of bread" },
                dark = { name = "Dark Rye Bread", description = "A hearty dark bread" }
            }
        },
        APPLE = {
            defaults = { tool = "food", duration = 30, useTime = 1.2, statEffects = { health = 3, stamina = 5 } },
            variants = {
                red = { name = "Red Apple", description = "A crisp, juicy apple" }
            }
        },
        CHEESE = {
            defaults = { tool = "food", duration = 45, useTime = 1.0, statEffects = { health = 4, stamina = 2 } },
            variants = {
                cheddar = { name = "Cheddar Cheese", description = "A sharp, aged cheese" }
            }
        },
        STEW = {
            defaults = { tool = "food", duration = 90, useTime = 2.5, statEffects = { health = 8, stamina = 6 } },
            variants = {
                beef = { name = "Beef Stew", description = "A hearty meat stew" }
            }
        },
        WATER = {
            defaults = { tool = "drink", duration = 20, useTime = 1.0, statEffects = { stamina = 6 } },
            variants = {
                fresh = { name = "Fresh Water", description = "Clean, refreshing water" }
            }
        }
    },

    RARE_FOOD = {
        ROAST = {
            defaults = { tool = "food", duration = 120, useTime = 3.0, statEffects = { health = 12, stamina = 10, strength = 2 } },
            variants = {
                venison = { name = "Venison Roast", description = "Tender roasted deer meat" }
            }
        },
        PIE = {
            defaults = { tool = "food", duration = 150, useTime = 2.0, statEffects = { health = 10, stamina = 8, intelligence = 2 } },
            variants = {
                berry = { name = "Berry Pie", description = "Sweet berry filling in a flaky crust" }
            }
        },
        WINE = {
            defaults = { tool = "drink", duration = 100, useTime = 1.0, statEffects = { stamina = 8, happiness = 3 } },
            variants = {
                red = { name = "Red Wine", description = "A fine aged wine" }
            }
        },
        CAKE = {
            defaults = { tool = "food", duration = 100, useTime = 2.0, statEffects = { health = 8, stamina = 12, happiness = 5 } },
            variants = {
                chocolate = { name = "Chocolate Cake", description = "Rich, decadent chocolate cake" }
            }
        }
    },

    EXOTIC_FOOD = {
        MANA_FRUIT = {
            defaults = { tool = "food", duration = 240, useTime = 1.5, statEffects = { magic = 25, intelligence = 5 } },
            variants = {
                blue = { name = "Blue Mana Fruit", description = "Rare fruit that restores magical energy" }
            }
        },
        GOLDEN_APPLE = {
            defaults = { tool = "food", duration = 400, useTime = 2.0, statEffects = { health = 15, stamina = 15, strength = 3, dexterity = 3 } },
            variants = {
                enchanted = { name = "Enchanted Golden Apple", description = "Mythical apple with powerful enhancement properties" }
            }
        },
        DRAGON_STEAK = {
            defaults = { tool = "food", duration = 600, useTime = 4.0, statEffects = { health = 30, stamina = 30, strength = 10, resistance = 5 } },
            variants = {
                rare = { name = "Rare Dragon Steak", description = "Extremely rare meat with extraordinary properties" }
            }
        }
    },

    POTIONS = {
        HEALTH_POTION = {
            defaults = { tool = "drink", duration = 180, useTime = 0.8, statEffects = { health = 25 } },
            variants = {
                minor = { name = "Minor Health Potion", description = "Restores a small amount of health" },
                major = { name = "Major Health Potion", description = "Restores a significant amount of health", statEffects = { health = 50 } }
            }
        },
        MANA_POTION = {
            defaults = { tool = "drink", duration = 200, useTime = 0.8, statEffects = { magic = 30 } },
            variants = {
                minor = { name = "Minor Mana Potion", description = "Restores a small amount of mana" },
                major = { name = "Major Mana Potion", description = "Restores a significant amount of mana", statEffects = { magic = 60 } }
            }
        },
        STRENGTH_POTION = {
            defaults = { tool = "drink", duration = 300, useTime = 1.0, statEffects = { strength = 8 } },
            variants = {
                standard = { name = "Strength Potion", description = "Temporarily increases physical strength" },
                superior = { name = "Superior Strength Potion", description = "Greatly increases physical strength", statEffects = { strength = 15 } }
            }
        },
        INVISIBILITY_POTION = {
            defaults = { tool = "drink", duration = 120, useTime = 1.2, statEffects = { stealth = 20 } },
            variants = {
                cloudy = { name = "Cloudy Invisibility Potion", description = "Makes the user partially invisible" },
                clear = { name = "Clear Invisibility Potion", description = "Makes the user completely invisible", duration = 180 }
            }
        },
        SPEED_POTION = {
            defaults = { tool = "drink", duration = 150, useTime = 0.9, statEffects = { speed = 12 } },
            variants = {
                swift = { name = "Swift Potion", description = "Temporarily increases movement speed" },
                haste = { name = "Haste Potion", description = "Greatly increases movement speed", statEffects = { speed = 20 } }
            }
        }
    }
}

return FoodModule