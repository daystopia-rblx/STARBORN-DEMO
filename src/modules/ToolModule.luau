--[[ ToolModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local ToolModule = {}

--[[ Types ]]
type ToolContext = {
    id: string,
    tool: Tool,
    player: Player,
    [string]: any
}

--[[ Tool Types ]]
ToolModule.Types = {
    FISHING_ROD = "fishing_rod"
}

--[[ Tool Properties ]]
ToolModule.Properties = {
    CanBeDropped = false,
    Enabled = true,
    ManualActivationOnly = false,
    RequiresHandle = true,
    ToolTip = "",
    AutoPickup = false,

    cursors = {
        default = "",
        hover = "",
        invalid = "",
        active = ""
    },

    inputs = {
        primary = {
            type = "MouseButton1",
            usageType = "single", -- "single", "continuous", "charge", "toggle"
            cooldown = 0.1,
            holdDuration = 0,
            stateOnActivate = "",
            stateOnDeactivate = "",
            requiresState = {},
            preventInStates = {}
        },
        secondary = {
            type = "MouseButton2",
            usageType = "single",
            cooldown = 0.1,
            holdDuration = 0,
            stateOnActivate = "",
            stateOnDeactivate = "",
            requiresState = {},
            preventInStates = {}
        },
        tertiary = {
            type = "MouseButton3",
            usageType = "single",
            cooldown = 0.1,
            holdDuration = 0,
            stateOnActivate = "",
            stateOnDeactivate = "",
            requiresState = {},
            preventInStates = {}
        }
    },

    stateConfig = {
        initialState = "INACTIVE",
        transitions = {},
        onEnterState = {},
        onExitState = {},
        preventInputInStates = {},
    },

    animations = {
        idle = "",
        equip = "",
        unequip = "",
        activate = "",
        deactivate = "",
        states = {}
    },

    sounds = {
        equip = "",
        unequip = "",
        activate = "",
        deactivate = "",
        states = {}
    },

    dataSchema = {},
    defaultData = {},
}

--[[ Tool Templates ]]
ToolModule.Templates = {
    [ToolModule.Types.FISHING_ROD] = {
        ToolTip = "Left click to cast, hold to reel",
        inputs = {
            primary = {
                type = "MouseButton1",
                usageType = "charge",
                cooldown = 0.1,
                holdDuration = 2,
                description = "Hold to charge cast power",
                stateOnActivate = "CHARGING",
                stateOnDeactivate = "CASTING",
                preventInStates = {"FISHING", "REELING"}
            },
            secondary = {
                type = "MouseButton2",
                usageType = "continuous",
                cooldown = 0.1,
                description = "Hold to reel",
                stateOnActivate = "REELING",
                stateOnDeactivate = "FISHING",
                requiresState = {"FISHING"}
            }
        },
        distance = 50,
        stateConfig = {
            initialState = "INACTIVE",
            transitions = {
                INACTIVE = {"CHARGING"},
                CHARGING = {"CASTING", "INACTIVE"},
                CASTING = {"FISHING"},
                FISHING = {"REELING", "INACTIVE"},
                REELING = {"FISHING", "INACTIVE"}
            }
        }
    },
}

--[[ Utility Functions ]]
function ToolModule:GetTemplate(toolType: string): {[string]: any}
    local normalizedToolType = toolType:gsub(" ", "_"):lower()

    local template = self.Templates[normalizedToolType]

    if not template then
        for typeName, typeValue in pairs(self.Types) do
            if typeValue:lower() == normalizedToolType or typeName:lower() == normalizedToolType then
                template = self.Templates[typeValue]
                break
            end
        end
    end

    if not template then
        warn("No template found for tool type:", toolType)
        return {}
    end

    local mergedTemplate = table.clone(self.Properties)
    for key, value in pairs(template) do
        if type(value) == "table" and type(mergedTemplate[key]) == "table" then
            for subKey, subValue in pairs(value) do
                mergedTemplate[key][subKey] = subValue
            end
        else
            mergedTemplate[key] = value
        end
    end

    return mergedTemplate
end

return ToolModule