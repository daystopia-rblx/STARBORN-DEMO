--[[ PlayerService
    Core player management system for lifecycle events and state tracking.
    Handles player joining, leaving, respawning, and persistent data synchronization.
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-05
]]

local PlayerService = {}

PlayerService.Dependencies = {
    "Event"
}

PlayerService.Events = {
    Join = true,
    Left = true
}

local Services

PlayerService.Listeners = {
    ["Players.PlayerAdded"] = function(_, player)
        Services.Event:Fire("Player.Join", {
            userId = player.UserId,
            player = player
        })

        player.DevEnableMouseLock = false
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse

        player.CharacterAdded:Connect(function(character)
            local healthScript = character:FindFirstChild("Health")
            if healthScript then
                healthScript:Destroy()
            end

            local animateScript = character:FindFirstChild("Animate")
            if animateScript then
                animateScript:Destroy()
            end

            player.DevEnableMouseLock = false
        end)
    end,

    ["Players.PlayerRemoving"] = function(_, player)
        Services.Event:Fire("Player.Left", {
            userId = player.UserId,
            player = player
        })
    end
}

function PlayerService:Init(services)
    Services = services

    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        player.DevEnableMouseLock = false
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse
    end

    return true
end

return PlayerService