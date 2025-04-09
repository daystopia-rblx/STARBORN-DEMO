--[[ PlayerController
    Client-side player management with character customization and state tracking.
    Handles player UI, animations, and real-time state synchronization.
    @author @Daystopia
    @version 1.0.4
    @date 2025-04-09
]]
local PlayerController = {}

local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

PlayerController.Dependencies = {
    "Event"
}

--[[ State ]]
local Controllers
local Modules
local Utility = {
    Input = require(ReplicatedStorage.Modules.Utility.Input),
}

--[[ Events ]]
PlayerController.Events = {
    Join = true,
    Left = true
}

--[[ Listeners ]]
PlayerController.Listeners = {
    ["Player.Join"] = function(self, data)
        -- No action needed
    end,

    ["Player.Left"] = function(self, data)
        -- No action needed
    end
}

--[[ Core Functions ]]
function PlayerController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function PlayerController:Start()
    self:SetupInput()
    self:DisableDefault()
    return true
end

--[[ Player Functions ]]
function PlayerController:SetupInput()
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

function PlayerController:DisableDefault()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

    local function DisableReset()
        local success, error = pcall(function()
            StarterGui:SetCore('ResetButtonCallback', false)
        end)
        return success
    end

    task.spawn(function()
        local attempts = 0
        local maxAttempts = 20

        while attempts < maxAttempts do
            if DisableReset() then
                break
            end
            attempts += 1
            task.wait(0.5)
        end
    end)
end

return PlayerController