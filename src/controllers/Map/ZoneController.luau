--[[ ZoneController
    Client-side zone system with region visualization and state management.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-09
]]
local ZoneController = {}

ZoneController.Dependencies = {
    "Event"
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = {
    Component = require(ReplicatedStorage.Modules.Utility.Component)
}

--[[ State ]]
local Controllers
local Modules
local State = {
    currentZone = nil
}

--[[ Events ]]
ZoneController.Events = {
    Enter = true,
    Exit = true
}

--[[ Listeners ]]
ZoneController.Listeners = {
    ["Zone.Enter"] = function(self, data)
        State.currentZone = data.zoneName
        Utility.Component.CreateNotification({
            title = "Entering Area",
            message = data.zoneName or "Unknown Area",
            duration = 3,
            type = "info"
        })
    end,

    ["Zone.Exit"] = function(self, data)
        if State.currentZone == data.zoneName then
            State.currentZone = nil
        end
    end
}

--[[ Core Functions ]]
function ZoneController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function ZoneController:Start()
    return true
end

--[[ State Functions ]]
function ZoneController:GetCurrentZone()
    return State.currentZone
end

return ZoneController