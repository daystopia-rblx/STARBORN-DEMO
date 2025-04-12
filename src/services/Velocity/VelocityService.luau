local VelocityService = {}

local StatusService = require(game.ServerScriptService.Services.Status.StatusService)

VelocityService.Events = {
    Create = { validate = true },
}

VelocityService.Listeners = {
    ["Velocity.Create"] = function(self, Player: Player, Character: Model)
        if not Character then return end

        self:MomentumTrail(Character)
    end,
}

function VelocityService:MomentumTrail(Character: Model)
	local Parts = {
		Character:FindFirstChild("Right Arm"),
		Character:FindFirstChild("Right Leg"),
		Character:FindFirstChild("Left Arm"),
		Character:FindFirstChild("Left Leg")
	}

	local Humanoid = Character:FindFirstChild("Humanoid")
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then return end

	for _, part in ipairs(Parts) do
		if part and part.Transparency < 1 then
			if part:FindFirstChild("A1") or part:FindFirstChild("A2") or part:FindFirstChild("MomentumTrail") then
				return
			end

			local A1 = Instance.new("Attachment")
			A1.Name = "A1"
			A1.Parent = part
			A1.CFrame = CFrame.new(0, 0, 0)

			local A2 = Instance.new("Attachment")
			A2.Name = "A2"
			A2.Parent = part
			A2.CFrame = CFrame.new(0, -2, 0)

			local Trail = game.ReplicatedStorage.Assets.Particles.SpeedTrails.Trail:Clone()
			Trail.Name = "MomentumTrail"
			Trail.Parent = part
			Trail.Attachment0 = A1
			Trail.Attachment1 = A2

			task.spawn(function()
				while StatusService:CheckSpecific(Humanoid, {Connection = true}, "Running") == true do
					task.wait()
				end

				local fadeOutTween = game.TweenService:Create(Trail, TweenInfo.new(2), {Lifetime = 0})
				fadeOutTween:Play()

				fadeOutTween.Completed:Connect(function()
					if A1 then A1:Destroy() end
					if A2 then A2:Destroy() end
					if Trail then Trail:Destroy() end
				end)
			end)
		end
	end
end

return VelocityService