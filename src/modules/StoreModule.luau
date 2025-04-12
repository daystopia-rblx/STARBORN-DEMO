--[[ StoreModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local StoreModule = {}

function StoreModule:GetItems(storeType)
    if not storeType then return {} end
    storeType = storeType:upper()
    return self.Items[storeType] or {}
end

function StoreModule:GetRestock(storeType)
    if not storeType then return 1 end
    storeType = storeType:upper()
    return self.RestockIntervals[storeType] or 1
end

StoreModule.Categories = {
    GENERAL = "General Goods",
    BLACKSMITH = "Weapons & Armor",
    INVOCATION = "Magical Items",
    RELIC = "Rare Artifacts",
    BLOOD = "Forbidden Goods",
    GUILD = "Guild Supplies",
    BLACK_MARKET = "Illicit Goods"
}

StoreModule.StoreTypes = {
    GENERAL = "general",
    BLACKSMITH = "blacksmith",
    INVOCATION = "invocation",
    RELIC = "relic",
    BLOOD = "blood",
    GUILD = "guild",
    BLACK_MARKET = "black_market"
}

StoreModule.RestockIntervals = {
    GENERAL = 1,
    BLACKSMITH = 2,
    INVOCATION = 3,
    RELIC = 7,
    BLOOD = 14,
    GUILD = 1,
    BLACK_MARKET = 0.5
}

StoreModule.Items = {
    GENERAL = {
        {itemId = "HEALING_POTION", price = 25, minQuantity = 3, maxQuantity = 10},
        {itemId = "BREAD", price = 5, minQuantity = 5, maxQuantity = 15},
        {itemId = "TORCH", price = 10, minQuantity = 2, maxQuantity = 8},
        {itemId = "ROPE", price = 15, minQuantity = 1, maxQuantity = 5},
        {itemId = "WATER_FLASK", price = 8, minQuantity = 2, maxQuantity = 7},
        {itemId = "BACKPACK", price = 35, minQuantity = 1, maxQuantity = 3}
    },
    BLACKSMITH = {
        {itemId = "IRON_SWORD", price = 150, minQuantity = 1, maxQuantity = 3},
        {itemId = "IRON_SHIELD", price = 120, minQuantity = 1, maxQuantity = 2},
        {itemId = "LEATHER_ARMOR", price = 100, minQuantity = 1, maxQuantity = 3},
        {itemId = "REPAIR_KIT", price = 50, minQuantity = 2, maxQuantity = 5},
        {itemId = "IRON_DAGGER", price = 85, minQuantity = 1, maxQuantity = 3},
        {itemId = "IRON_INGOT", price = 20, minQuantity = 2, maxQuantity = 6}
    },
    INVOCATION = {
        {itemId = "MINOR_INVOCATION_SCROLL", price = 75, minQuantity = 1, maxQuantity = 5},
        {itemId = "MAGIC_DUST", price = 35, minQuantity = 3, maxQuantity = 8},
        {itemId = "SPELL_FRAGMENT", price = 120, minQuantity = 1, maxQuantity = 3},
        {itemId = "MANA_POTION", price = 45, minQuantity = 2, maxQuantity = 6},
        {itemId = "ENCHANTED_INK", price = 60, minQuantity = 1, maxQuantity = 4},
        {itemId = "BLANK_SCROLL", price = 25, minQuantity = 1, maxQuantity = 5}
    },
    RELIC = {
        {itemId = "ANCIENT_RELIC", price = 300, minQuantity = 1, maxQuantity = 2},
        {itemId = "MYSTERIOUS_ARTIFACT", price = 250, minQuantity = 1, maxQuantity = 3},
        {itemId = "ENCHANTED_GEM", price = 200, minQuantity = 1, maxQuantity = 3},
        {itemId = "HISTORICAL_DOCUMENT", price = 180, minQuantity = 1, maxQuantity = 2},
        {itemId = "FORGOTTEN_IDOL", price = 350, minQuantity = 1, maxQuantity = 1}
    },
    BLOOD = {
        {itemId = "BLOOD_VIAL", price = 100, minQuantity = 1, maxQuantity = 3},
        {itemId = "CRIMSON_CRYSTAL", price = 400, minQuantity = 1, maxQuantity = 1},
        {itemId = "LIFE_ESSENCE", price = 250, minQuantity = 1, maxQuantity = 2},
        {itemId = "BONE_CHARM", price = 200, minQuantity = 1, maxQuantity = 2},
        {itemId = "SACRIFICIAL_DAGGER", price = 300, minQuantity = 1, maxQuantity = 1}
    },
    GUILD = {
        {itemId = "GUILD_EMBLEM", price = 50, minQuantity = 1, maxQuantity = 5},
        {itemId = "FACTION_SUPPLIES", price = 75, minQuantity = 2, maxQuantity = 7},
        {itemId = "GUILD_UNIFORM", price = 120, minQuantity = 1, maxQuantity = 3},
        {itemId = "CONTRACT_SCROLL", price = 40, minQuantity = 2, maxQuantity = 5}
    },
    BLACK_MARKET = {
        {itemId = "SKELETON_KEY", price = 200, minQuantity = 1, maxQuantity = 2},
        {itemId = "SMUGGLED_GOODS", price = 150, minQuantity = 1, maxQuantity = 4},
        {itemId = "FORGED_DOCUMENTS", price = 250, minQuantity = 1, maxQuantity = 2},
        {itemId = "POISON_VIAL", price = 175, minQuantity = 1, maxQuantity = 3},
        {itemId = "THIEF_TOOLS", price = 225, minQuantity = 1, maxQuantity = 2}
    }
}

return StoreModule
