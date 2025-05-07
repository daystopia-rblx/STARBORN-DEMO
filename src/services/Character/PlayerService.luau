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

        player.DevEnableMouseLock = true
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse

        player.CharacterAdded:Connect(function(character)
            character.Parent = workspace.Entities

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
            
            PlayerService:ProvideHair(player)
            PlayerService:SetupGrips(character)

            local animateScript = character:FindFirstChild("Animate")
            animateScript.idle.Animation1.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.IDLE.id
            animateScript.idle.Animation2.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.IDLE_2.id
            animateScript.walk.WalkAnim.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.WALK.id
            animateScript.jump.JumpAnim.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.JUMP.id
            animateScript.fall.FallAnim.AnimationId = Modules.Animation.Assets.Animations.LOCOMOTION.FALL.id

            player.DevEnableMouseLock = true
        end)
    end,

    ["Players.PlayerRemoving"] = function(_, player)
        Services.Event:Fire("Player.Left", {
            userId = player.UserId,
            player = player
        })
    end
}

--[[ Character Functions ]]
function PlayerService:SetupGrips(Character)
    local LeftGrip = ReplicatedStorage.Assets.Grips.Grip:Clone()
    LeftGrip.Name = "LeftGrip"
    LeftGrip.Parent = Character

    local RightGrip = ReplicatedStorage.Assets.Grips.Grip:Clone()
    RightGrip.Name = "RightGrip"
    RightGrip.Parent = Character

    local WeldLeft = Instance.new("Motor6D", Character:FindFirstChild("LeftGrip"))
    WeldLeft.Name = "LeftGrip"
    WeldLeft.Part0 = Character:FindFirstChild("Left Arm")
    WeldLeft.Part1 = LeftGrip
    WeldLeft.C0 = CFrame.new(0, -1, 0)

    local WeldRight = Instance.new("Motor6D", Character:FindFirstChild("RightGrip"))
    WeldRight.Name = "RightGrip"
    WeldRight.Part0 = Character:FindFirstChild("Right Arm")
    WeldRight.Part1 = RightGrip
    WeldRight.C0 = CFrame.new(0, -1, 0)
end 

function PlayerService:ProvideHair(Player)
	local humanoidDescription = game.Players:GetHumanoidDescriptionFromUserId(Player.UserId)
	if humanoidDescription then
		for _, assetId in ipairs(humanoidDescription.HairAccessory:split(",")) do
			local hair = game:GetService("InsertService"):LoadAsset(tonumber(assetId))
			if hair then
				for _, item in ipairs(hair:GetChildren()) do
					if item:IsA("Accessory") then
						item.Parent = Player.Character
						local handle = item:FindFirstChild("Handle")
						--[[if handle and handle:IsA("BasePart") then
							local mesh = handle:FindFirstChildOfClass("SpecialMesh") or handle:FindFirstChildOfClass("Mesh")
							if mesh then
								mesh.VertexColor = Vector3.new(hairColor.R, hairColor.G, hairColor.B)
							end
							handle.Color = hairColor
						end]]
					end
				end
			end
		end
	end
end

function PlayerService:Init(services)
    Services = services

    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        player.DevEnableMouseLock = true
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.KeyboardMouse
    end

    return true
end

return PlayerService