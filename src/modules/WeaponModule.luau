--[[ WeaponModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local WeaponModule = {}

--[[ Types ]]
export type WeaponData = {
    id: string,
    type: string
}

WeaponModule.Constants = {
    TYPES = {
        -- Light Weapons
        FISTS = "FISTS",
        DAGGER = "DAGGER",
        GUN = "GUN",
        RAPIER = "RAPIER",
        NUNCHUCKS = "NUNCHUCKS",
        BOW = "BOW",

        -- Medium Weapons
        LONGSWORD = "LONGSWORD",
        SPEAR = "SPEAR",
        KATANA = "KATANA",
        RIFLE = "RIFLE",
        TRIDENT = "TRIDENT",

        -- Heavy Weapons
        GREATAXE = "GREATAXE",
        GREATSWORD = "GREATSWORD",
        SCYTHE = "SCYTHE"
    },

    CATEGORIES = {
        LIGHT = "LIGHT",
        MEDIUM = "MEDIUM",
        HEAVY = "HEAVY"
    }
}

WeaponModule.Templates = {

}

return WeaponModule