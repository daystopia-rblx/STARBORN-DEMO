--[[ InteractModule
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-14
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
    TALK = "talk",
    SEAT = "seat",
    REST = "rest",
    PICKUP = "pickup",
    STEAL = "steal",
    CRAFT = "craft",
    CONSUME = "consume",
    LOCKPICK = "lockpick",
    OPEN = "open",
    FISH = "fish"
}

--[[ Base Templates ]]
InteractModule.Templates = {
    [InteractModule.Types.TALK] = {
        prompt = "Talk",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(85, 170, 255),
        hold = 0.3,
        distance = 8,
        style = "billboard",
        lineOfSight = false,
        offset = {
            prompt = Vector3.new(0, 0, 0),
            tooltip = Vector3.new(0, 3, 0)
        },
        click = false,
        maxDistance = 7,
        visible = true
    },

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
    },

    [InteractModule.Types.PICKUP] = {
        prompt = "Pickup",
        key = "F",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(85, 170, 255),
        hold = false,
        distance = 8,
        style = "billboard",
        click = false,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.STEAL] = {
        prompt = "Steal",
        key = "F",
        gamepadKey = "ButtonY",
        color = Color3.fromRGB(255, 85, 85),
        highlightColor = Color3.fromRGB(255, 85, 85),
        hold = 0.5,
        distance = 8,
        style = "billboard",
        lineOfSight = false,
        click = false,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.CRAFT] = {
        prompt = "Craft",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(220, 155, 40),
        hold = 0.5,
        distance = 8,
        style = "billboard",
        lineOfSight = true,
        click = false,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.CONSUME] = {
        prompt = "Consume",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(95, 210, 110),
        hold = 0.3,
        distance = 8,
        style = "billboard",
        lineOfSight = false,
        click = true,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.LOCKPICK] = {
        prompt = "Lockpick",
        key = "F",
        gamepadKey = "ButtonY",
        color = Color3.fromRGB(240, 200, 60),
        highlightColor = Color3.fromRGB(240, 200, 60),
        hold = 1.5,
        distance = 8,
        style = "billboard",
        lineOfSight = true,
        click = false,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.OPEN] = {
        prompt = "Open",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(85, 170, 255),
        hold = 0.3,
        distance = 8,
        style = "billboard",
        lineOfSight = true,
        click = false,
        maxDistance = 7,
        visible = true
    },

    [InteractModule.Types.FISH] = {
        prompt = "Fish",
        key = "E",
        gamepadKey = "ButtonX",
        color = Color3.fromRGB(60, 170, 255),
        hold = 0.5,
        distance = 10,
        style = "billboard",
        lineOfSight = true,
        click = false,
        maxDistance = 8,
        visible = true
    }
}

return InteractModule