--[[ ZoneClient
    Client-side zone system with region visualization and state management.
    Handles zone transitions, effects, UI overlays, and attribute updates.
    @author @Daystopia
    @version 1.0.0
    @date 2025-02-06
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local LocalPlayer = Players.LocalPlayer

local State = {
    currentZone = nil
}

local Events = {
    ["Client.Zone.Enter"] = {
        handler = function(data)
            State.currentZone = data.zoneName
        end
    },

    ["Client.Zone.Exit"] = {
        handler = function(data)
            if State.currentZone == data.zoneName then
                State.currentZone = nil
            end
        end
    }
}

local function Initialize()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end

    for eventName, handler in pairs(Events) do
        Services.Event:OnClientEvent(eventName, handler.handler)
    end
end

Initialize()