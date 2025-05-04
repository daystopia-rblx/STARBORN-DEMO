local HitboxService = {}

local RunService = game:GetService("RunService")

function HitboxService:Init()
    return true
end

function HitboxService:Create(cf: CFrame, size: Vector3, params: RaycastParams, coffset: CFrame)
	local HitboxPart = Instance.new("Part")
	HitboxPart.BrickColor = BrickColor.new("Really red")
	HitboxPart.Material = Enum.Material.ForceField
	HitboxPart.Name = "HitboxVision"
	HitboxPart.CFrame = cf
	HitboxPart.Size = size
	HitboxPart.Anchored = true
	HitboxPart.CanCollide = false
	HitboxPart.CastShadow = false
	HitboxPart.Transparency = 1
	HitboxPart.Parent = workspace.Debris

    local Hitbox = {
		Part = HitboxPart,
		CFrame = cf,
		Size = size,
		Params = params,
		Config = {
			Active = false,
			Visible = false,
			Debounces = true,
			Offset = coffset and coffset or CFrame.new(0,0,-3),
		}
	}

	Hitbox.Debounces = {}
	self.Hit = function() end

	function Hitbox:WeldTo(part)
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if part and part.Parent then
				self.Part.CFrame = part.CFrame * self.Config.Offset
			end

			if self.Config.Active then
				local hits = workspace:GetPartBoundsInBox(self.Part.CFrame, self.Part.Size, self.Params)
				for _, hitPart in ipairs(hits) do
					local character = hitPart.Parent
					if character then
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						local rootPart = character:FindFirstChild("HumanoidRootPart")
						local FF = character:FindFirstChildOfClass("ForceField")

						if humanoid and rootPart and (not self.Config.Debounces or self.Debounces[humanoid] == nil) then
							if self.Config.IgnoreForcefield or FF == nil then
								if self.Config.Debounces then
									self.Debounces[humanoid] = true
								end

								self.Hit(character, humanoid, rootPart)
							end
						end
					end
				end
			else
				connection:Disconnect()
			end
		end)
    end

    function Hitbox:OnHit(fn)
		self.Hit = function(Character, Humanoid, Root)
			fn(Character, Humanoid, Root)
		end
	end

	function Hitbox:Run(duration)
		self.Config.Active = true	

		task.delay(duration, function()
			self.Config.Active = false
			self.Part:Destroy()
			self.Debounces = {}
		end)
	end

	function Hitbox:SetConfig(config)
		for key, value in pairs(config) do
			self.Config[key] = value
		end
		
		--[[if RunService:IsStudio() then
			self.Part.Transparency = 0.5
		end]]
	end

	return Hitbox
end

return HitboxService