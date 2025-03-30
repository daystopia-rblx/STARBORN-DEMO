local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Zone = require(ReplicatedStorage.Services.Object.ZoneService)
}

local Events = {
    ["Client.Zone.Enter"] = {
        handler = function(player, data)
            -- Remote event registration
            return true
        end
    },

    ["Client.Zone.Exit"] = {
        handler = function(player, data)
            -- Remote event registration
            return true
        end
    }
}

local function Initialize()
    for eventName, eventData in pairs(Events) do
        Services.Event:OnServerEvent(eventName, eventData.handler)
    end
end

Initialize()