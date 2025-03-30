local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Data = require(ReplicatedStorage.Services.Network.DataService)
}

local Events = {
    ["Player.Join"] = {
        handler = function()
            -- No action needed
        end
    },

    ["Player.Left"] = {
        handler = function()
            -- No action needed
        end
    }
}

local function Initialize()
    for eventName, event in pairs(Events) do
        Services.Event:OnServerEvent(eventName, event.handler)
    end
end

Initialize()