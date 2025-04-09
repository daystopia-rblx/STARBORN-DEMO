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