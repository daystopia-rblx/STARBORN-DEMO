--[[ PlayerService
    Core player management system for lifecycle events and state tracking.
    Handles player joining, leaving, respawning, and persistent data synchronization.
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-05
]]

local PlayerService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = {
    Animation = require(ReplicatedStorage.Modules.AnimationModule),
}

PlayerService.Dependencies = {
    "Event"
}

PlayerService.Events = {
    Join = {
        validate = true,
        schema = {
            userId = "userId",
            player = "playerInstance"
        }
    },
    Left = {
        validate = true,
        schema = {
            userId = "userId",
            player = "playerInstance"
        }
    }
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

            --[[ Animate script is quite useful
            local animateScript = character:FindFirstChild("Animate")
            if animateScript then
                animateScript:Destroy()
            end
            ]]

            local animateScript = character:FindFirstChild("Animate")
            animateScript.idle.Animation1.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.IDLE.id
            animateScript.idle.Animation2.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.IDLE_2.id
            animateScript.walk.WalkAnim.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.WALK.id
            animateScript.jump.JumpAnim.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.JUMP.id
            animateScript.fall.FallAnim.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.FALL.id

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