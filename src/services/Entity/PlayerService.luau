--[[ PlayerService
    Core player management system for lifecycle events and state tracking.
    Handles player joining, leaving, respawning, and persistent data synchronization.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-01
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

        player.CharacterAdded:Connect(function(character)
            local healthScript = character:FindFirstChild("Health")
            if healthScript then
                healthScript:Destroy()
            end

            local animateScript = character:FindFirstChild("Animate")
            if animateScript then
                animateScript:Destroy()
            end
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
    return true
end

return PlayerService