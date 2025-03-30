--[[ PlayerClient
    Client-side player management with character customization and state tracking.
    Handles player UI, animations, and real-time state synchronization.
    @author @Daystopia
    @version 1.0.2
    @date 2025-02-26
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}
local Utility = {
    Controller = require(script.Parent.Utility.Controller),
    Input = require(script.Parent.Utility.Input),
    Sound = require(script.Parent.Utility.Sound)
}

local Events = {
    ["Player.Join"] = {
        handler = function(data)
            -- No action needed
        end
    },

    ["Player.Left"] = {
        handler = function(data)
            -- No action needed
        end
    }
}

--[[ Input Handling ]]
local function SetupInput()
    Utility.Input.HandleInput({
        id = "Player",
        actions = {
            {},
        },
        keyboardEnabled = true,
        mouseEnabled = true,
        ignoreProcessed = false,
        requireGameFocus = true
    })
end

local function DisableDefault()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end

local function Initialize()
    for eventName, handler in pairs(Events) do
        Services.Event:OnClientEvent(eventName, handler.handler)
    end

    task.spawn(SetupInput)
    task.spawn(DisableDefault)
end

Initialize()