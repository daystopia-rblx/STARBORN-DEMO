--[[ RecipeModule
    Defines crafting recipes, their requirements, and outcomes.
    Handles recipe discovery and organization by crafting type and tier.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local RecipeModule = {}

--[[ Constants ]]
RecipeModule.DISCOVERY_METHODS = {
    DEFAULT = "DEFAULT",
    EXPLORATION = "EXPLORATION",
    QUEST = "QUEST",
    NPC = "NPC",
    EXPERIMENTATION = "EXPERIMENTATION"
}

--[[ Types ]]
export type Recipe = {
    id: string,
    name: string,
    description: string,
    craftType: string,
    tier: string,
    materials: {
        core: {[string]: number},
        modifiers: {[string]: number}?,
        catalysts: {[string]: number}?
    },
    result: {
        itemId: string,
        quantity: number,
        modifiers: {[string]: any}?
    },
    stationTypes: {string},
    process: string,
    timeRequired: number,
    skillRequired: number,
    successRate: number,
    discoveryMethod: string,
    discoveryHint: string?
}

--[[ Recipe Templates ]]
RecipeModule.Recipes = {
    -- Weapon Recipes (Tier 1)
    IRON_SWORD = {
        id = "IRON_SWORD",
        name = "Iron Sword",
        description = "A basic iron sword with decent damage",
        craftType = "WEAPON_FORGING",
        tier = "TIER_1",
        materials = {
            core = {
                IRON = 3,
                WOOD = 1
            }
        },
        result = {
            itemId = "IRON_SWORD",
            quantity = 1
        },
        stationTypes = {"ANVIL", "FORGE"},
        process = "FORGING",
        timeRequired = 8,
        skillRequired = 1,
        successRate = 0.95,
        discoveryMethod = "DEFAULT",
        discoveryHint = "A basic sword made from iron ingots."
    },

    -- Weapon Recipes (Tier 2)
    ARIDORIAN_SCIMITAR = {
        id = "ARIDORIAN_SCIMITAR",
        name = "Aridorian Scimitar",
        description = "A curved blade from the desert regions",
        craftType = "WEAPON_FORGING",
        tier = "TIER_2",
        materials = {
            core = {
                IRON = 2,
                STEEL = 2,
                WOOD = 1
            },
            modifiers = {
                DESERT_ESSENCE = 1
            }
        },
        result = {
            itemId = "ARIDORIAN_SCIMITAR",
            quantity = 1,
            modifiers = {
                BONUS_BLEED = 10
            }
        },
        stationTypes = {"ANVIL", "FORGE"},
        process = "FORGING",
        timeRequired = 12,
        skillRequired = 15,
        successRate = 0.85,
        discoveryMethod = "EXPLORATION",
        discoveryHint = "The secret to crafting this curved blade may be found in the Aridoria region."
    },

    -- Weapon Recipes (Tier 3)
    GLOOMREAVER_FANG_BLADE = {
        id = "GLOOMREAVER_FANG_BLADE",
        name = "Gloomreaver Fang Blade",
        description = "A deadly blade crafted from the fang of the Gloomreaver beast",
        craftType = "WEAPON_FORGING",
        tier = "TIER_3",
        materials = {
            core = {
                STEEL = 4,
                GLOOMREAVER_FANG = 1,
                ANCIENT_WOOD = 2
            },
            modifiers = {
                SHADOWBARK = 2
            },
            catalysts = {
                BLACKSMITH_ESSENCE = 1
            }
        },
        result = {
            itemId = "GLOOMREAVER_FANG_BLADE",
            quantity = 1,
            modifiers = {
                BONUS_BLEED = 25,
                BONUS_DARKNESS = 15
            }
        },
        stationTypes = {"ANVIL", "FORGE"},
        process = "FORGING",
        timeRequired = 20,
        skillRequired = 30,
        successRate = 0.70,
        discoveryMethod = "QUEST",
        discoveryHint = "This powerful blade requires the fang of the legendary Gloomreaver."
    },

    -- Armor Recipes (Tier 1)
    LEATHER_ARMOR = {
        id = "LEATHER_ARMOR",
        name = "Leather Armor",
        description = "Basic protective gear made from animal hide",
        craftType = "ARMOR_SMITHING",
        tier = "TIER_1",
        materials = {
            core = {
                LEATHER = 5,
                THREAD = 2
            }
        },
        result = {
            itemId = "LEATHER_ARMOR",
            quantity = 1
        },
        stationTypes = {"WORKBENCH"},
        process = "FORGING",
        timeRequired = 10,
        skillRequired = 1,
        successRate = 0.95,
        discoveryMethod = "DEFAULT",
        discoveryHint = "Basic armor crafted from leather."
    },

    -- Armor Recipes (Tier 2)
    RIDGEGUARD_CLOAK = {
        id = "RIDGEGUARD_CLOAK",
        name = "Ridgeguard Cloak",
        description = "A sturdy cloak that provides protection against the elements",
        craftType = "ARMOR_SMITHING",
        tier = "TIER_2",
        materials = {
            core = {
                LEATHER = 3,
                TREATED_CLOTH = 4,
                SILVER_THREAD = 2
            },
            modifiers = {
                FROST_ESSENCE = 1
            }
        },
        result = {
            itemId = "RIDGEGUARD_CLOAK",
            quantity = 1,
            modifiers = {
                COLD_RESIST = 25
            }
        },
        stationTypes = {"WORKBENCH"},
        process = "FORGING",
        timeRequired = 15,
        skillRequired = 18,
        successRate = 0.85,
        discoveryMethod = "NPC",
        discoveryHint = "The mountain dwellers know the secret to crafting this protective cloak."
    },

    -- Potions (Tier 1)
    MINOR_HEALING_POTION = {
        id = "MINOR_HEALING_POTION",
        name = "Minor Healing Potion",
        description = "Restores a small amount of health when consumed",
        craftType = "ALCHEMY",
        tier = "TIER_1",
        materials = {
            core = {
                RED_HERB = 2,
                WATER = 1
            }
        },
        result = {
            itemId = "MINOR_HEALING_POTION",
            quantity = 1
        },
        stationTypes = {"CAULDRON"},
        process = "BREWING",
        timeRequired = 5,
        skillRequired = 1,
        successRate = 0.95,
        discoveryMethod = "DEFAULT",
        discoveryHint = "A basic healing potion known to most alchemists."
    },

    -- Food (Tier 1)
    GRILLED_MEAT = {
        id = "GRILLED_MEAT",
        name = "Grilled Meat",
        description = "Cooked meat that restores health and stamina",
        craftType = "COOKING",
        tier = "TIER_1",
        materials = {
            core = {
                RAW_MEAT = 1
            },
            modifiers = {
                SALT = 1
            }
        },
        result = {
            itemId = "GRILLED_MEAT",
            quantity = 1
        },
        stationTypes = {"CAMPFIRE"},
        process = "COOKING",
        timeRequired = 4,
        skillRequired = 1,
        successRate = 0.98,
        discoveryMethod = "DEFAULT",
        discoveryHint = "A simple cooking recipe known to all."
    }
}

--[[ Recipe Collections ]]
function RecipeModule.InitializeCollections()
    RecipeModule.RecipesByType = {}
    RecipeModule.RecipesByTier = {}
    RecipeModule.RecipesByDiscovery = {}

    for craftType, _ in pairs(require(script.Parent.CraftModule).CRAFT_TYPES) do
        RecipeModule.RecipesByType[craftType] = {}
    end

    for tier, _ in pairs(require(script.Parent.CraftModule).TIERS) do
        RecipeModule.RecipesByTier[tier] = {}
    end

    for discoveryMethod, _ in pairs(RecipeModule.DISCOVERY_METHODS) do
        RecipeModule.RecipesByDiscovery[discoveryMethod] = {}
    end

    for recipeId, recipe in pairs(RecipeModule.Recipes) do
        if RecipeModule.RecipesByType[recipe.craftType] then
            table.insert(RecipeModule.RecipesByType[recipe.craftType], recipeId)
        end

        if RecipeModule.RecipesByTier[recipe.tier] then
            table.insert(RecipeModule.RecipesByTier[recipe.tier], recipeId)
        end

        if RecipeModule.RecipesByDiscovery[recipe.discoveryMethod] then
            table.insert(RecipeModule.RecipesByDiscovery[recipe.discoveryMethod], recipeId)
        end
    end
end

--[[ Utility Functions ]]
function RecipeModule.GetRecipe(recipeId: string): Recipe?
    return RecipeModule.Recipes[recipeId]
end

function RecipeModule.GetRecipesByType(craftType: string): {string}
    return RecipeModule.RecipesByType[craftType] or {}
end

function RecipeModule.GetRecipesByTier(tier: string): {string}
    return RecipeModule.RecipesByTier[tier] or {}
end

function RecipeModule.GetRecipesByDiscovery(method: string): {string}
    return RecipeModule.RecipesByDiscovery[method] or {}
end

function RecipeModule.GetDefaultRecipes(): {string}
    return RecipeModule.RecipesByDiscovery[RecipeModule.DISCOVERY_METHODS.DEFAULT] or {}
end

function RecipeModule.ValidateStation(recipeId: string, stationType: string): boolean
    local recipe = RecipeModule.Recipes[recipeId]
    if not recipe then return false end

    for _, allowedStation in ipairs(recipe.stationTypes) do
        if allowedStation == stationType then
            return true
        end
    end

    return false
end

function RecipeModule.CheckMaterials(recipeId: string, inventory: {[string]: number}): (boolean, {[string]: number})
    local recipe = RecipeModule.Recipes[recipeId]
    if not recipe then return false, {} end

    local missingMaterials = {}

    for materialId, requiredAmount in pairs(recipe.materials.core) do
        local availableAmount = inventory[materialId] or 0
        if availableAmount < requiredAmount then
            missingMaterials[materialId] = requiredAmount - availableAmount
        end
    end

    if recipe.materials.modifiers then
        for materialId, requiredAmount in pairs(recipe.materials.modifiers) do
            local availableAmount = inventory[materialId] or 0
            if availableAmount < requiredAmount then
                missingMaterials[materialId] = requiredAmount - availableAmount
            end
        end
    end

    if recipe.materials.catalysts then
        for materialId, requiredAmount in pairs(recipe.materials.catalysts) do
            local availableAmount = inventory[materialId] or 0
            if availableAmount < requiredAmount then
                missingMaterials[materialId] = requiredAmount - availableAmount
            end
        end
    end

    return next(missingMaterials) == nil, missingMaterials
end

function RecipeModule.AddRecipe(recipe: Recipe): boolean
    if not recipe or not recipe.id then
        return false
    end

    RecipeModule.Recipes[recipe.id] = recipe

    if RecipeModule.RecipesByType[recipe.craftType] then
        table.insert(RecipeModule.RecipesByType[recipe.craftType], recipe.id)
    end

    if RecipeModule.RecipesByTier[recipe.tier] then
        table.insert(RecipeModule.RecipesByTier[recipe.tier], recipe.id)
    end

    if RecipeModule.RecipesByDiscovery[recipe.discoveryMethod] then
        table.insert(RecipeModule.RecipesByDiscovery[recipe.discoveryMethod], recipe.id)
    end

    return true
end

RecipeModule.InitializeCollections()

return RecipeModule