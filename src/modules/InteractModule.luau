--[[ InteractModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local InteractModule = {}

--[[ Types ]]
type InteractionContext = {
    id: string,
    instance: Instance,
    player: Player,
    [string]: any
}

--[[ Interaction Types ]]
InteractModule.Types = {
    SEAT = "seat",
    REST = "rest"
}

--[[ Base Templates ]]
InteractModule.Templates = {
    [InteractModule.Types.SEAT] = {
        prompt = "Sit",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(170, 85, 255),
        hold = 0.5,
        distance = 8,
        style = "billboard",
        click = false,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.REST] = {
        prompt = "Rest",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(255, 156, 66),
        hold = 1.0,
        distance = 8,
        style = "billboard",
        click = false,
        maxDistance = 7,
        visible = true
    }
}

return InteractModule