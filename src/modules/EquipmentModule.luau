--[[ EquipmentModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local EquipmentModule = {}

--[[ Types ]]
export type EquipmentData = {
    id: string,
    type: string,
    slot: string
}

EquipmentModule.Constants = {
    TYPES = {
        LIGHT_ARMOR = "LIGHT_ARMOR",
        MEDIUM_ARMOR = "MEDIUM_ARMOR",
        HEAVY_ARMOR = "HEAVY_ARMOR",
        ACCESSORY = "ACCESSORY",
        TRINKET = "TRINKET"
    },

    SLOTS = {
        HEAD = "HEAD",
        CHEST = "CHEST",
        LEGS = "LEGS",
        FEET = "FEET",
        HANDS = "HANDS",
        RING = "RING",
        NECKLACE = "NECKLACE",
        BELT = "BELT"
    }
}

EquipmentModule.Templates = {

}

return EquipmentModule