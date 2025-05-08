local CoreService = {}
CoreService.__index = CoreService
CoreService.Instances = {}

type Info = {
	Height: number,
	Radius: number,
	Jump: boolean,
	Range: number,
	AttackRange: number,
	Weapon: string,
	ViewAngle: number,
	Behavior: string,
	Ally: string,
}

CoreService.Dependencies = {
	"Event",
	"Asset",
	"Status",
	"Particle"
}

CoreService.Modules = {
	"Animation",
	"Status",
	"Sound"
}

local Utility = {
	Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)
}

local Services
local Modules

local Debris = game:GetService("Debris")
local PathfindingService = game:GetService("PathfindingService")
local Coordinator = require(script.Parent.CoordinationService)

function CoreService:Init(services, modules)
	Services = services
	Modules = modules
	return true
end

function CoreService.Create(Rig: Model, Info: Info)
	local self = setmetatable({}, CoreService)

	self.Character = Rig
	self.Humanoid = self.Character.Humanoid
	self.HRP = self.Character:FindFirstChild("HumanoidRootPart")

	self.ViewAngle = math.rad(Info.ViewAngle or 180)
	self.Behavior = Info.Behavior or "Passive"
	self.TrackingEndTime = 0

	self.Humanoid:SetAttribute("Behavior", self.Behavior)
	self.Humanoid:SetAttribute("InCombat", false)

	self.AllyGroup = Info.Ally or "Default"
	self.Humanoid:SetAttribute("AllyGroup", self.AllyGroup)

	for _, Gyro in ipairs(self.HRP:GetChildren()) do
		if Gyro:IsA("BodyGyro") then
			Gyro:Destroy()
		end
	end

	self.RotationGyro = Instance.new("BodyGyro")
	self.RotationGyro.MaxTorque = Vector3.new(0, math.huge, 0)
	self.RotationGyro.P = 900000
	self.RotationGyro.CFrame = self.HRP.CFrame
	self.RotationGyro.Parent = self.HRP

	self.Path = PathfindingService:CreatePath({
		AgentHeight = Info.Height or 4,
		AgentRadius = Info.Radius or 4,
		AgentCanJump = Info.Jump or false,
		WaypointSpacing = 12,
	})

	self.Weapon = Info.Weapon or "Fist"
	self.Range = Info.Range or 50
	self.AttackRange = Info.AttackRange or 6
	self.PreferredDistance = self.AttackRange * 0.55
	self.LastAttacker = nil
	self.DamageCooldown = 0

	self.VisualWaypoints = {} 
	CoreService.Instances[Rig] = self

	self:Start()
	return self
end

function CoreService:ClearVisualWaypoints()
	for _, part in ipairs(self.VisualWaypoints) do
		part:Destroy()
	end
	self.VisualWaypoints = {}
end

function CoreService:VisualizeWaypoints()
	self:ClearVisualWaypoints()

	for i, waypoint in ipairs(self.Waypoints) do
		local part = Instance.new("Part")
		part.Size = Vector3.new(1, 1, 1)
		part.Position = waypoint.Position
		part.Anchored = true
		part.CanCollide = false
		part.BrickColor = BrickColor.new("Bright red")
		part.Material = Enum.Material.Neon
		part.Parent = workspace.Debris

		table.insert(self.VisualWaypoints, part)
	end
end

function CoreService:Run()

end

function CoreService:RunStop()

end

function CoreService:ViewCone(targetPosition)
	local forward = self.HRP.CFrame.LookVector
	local toTarget = (targetPosition - self.HRP.Position).Unit
	local angle = math.acos(forward:Dot(toTarget))
	return angle <= self.ViewAngle / 2
end

function CoreService:LineOfSight(target)
	local rayOrigin = self.HRP.Position
	local rayDirection = target.HumanoidRootPart.Position - rayOrigin

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.Character, target}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return raycastResult == nil
end

function CoreService:FindTarget()
	local CurrentTime = tick()

	if self.LastAttacker and self.Humanoid:GetAttribute("InCombat") then
		if self.LastAttacker.Parent and self.LastAttacker.Humanoid.Health > 0 then
			local distance = (self.HRP.Position - self.LastAttacker.HumanoidRootPart.Position).Magnitude
			if distance <= self.Range * 1.5 then
				return self.LastAttacker
			end
		end
	end

	if self.currentTarget and CurrentTime < self.TrackingEndTime then
		local distance = (self.HRP.Position - self.currentTarget.HumanoidRootPart.Position).Magnitude
		if distance <= self.Range and self.currentTarget.Humanoid.Health > 0 then
			return self.currentTarget
		end
	end

	if self.Behavior == "Hostile" or self.Humanoid:GetAttribute("InCombat") then
		local nearestTarget = nil
		local closestDistance = self.Range

		for _, target in pairs(workspace.Entities:GetChildren()) do
			if target:IsA("Model") and target ~= self.Character and target:FindFirstChild("Humanoid") and target:FindFirstChild("HumanoidRootPart") then
				if target.Humanoid.Health > 0 then
					local targetAlly = target.Humanoid:GetAttribute("AllyGroup") or "Default"
					if targetAlly ~= self.AllyGroup then
						local distance = (self.HRP.Position - target.HumanoidRootPart.Position).Magnitude
						if distance <= closestDistance then
							if self:ViewCone(target.HumanoidRootPart.Position) and self:LineOfSight(target) then
								nearestTarget = target
								closestDistance = distance
							end
						end
					end
				end
			end
		end

		if nearestTarget then
			self.TrackingEndTime = CurrentTime + 30
			return nearestTarget
		end
	end

	return nil
end

function CoreService:CheckSlope()
	local RayOrigin = self.HRP.Position
	local RayDirection = Vector3.new(0, -1, 0) * 10

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local RaycastResult = workspace:Raycast(RayOrigin, RayDirection, raycastParams)

	if RaycastResult then
		local normal = RaycastResult.Normal
		local SlopeAngle = math.deg(math.acos(normal:Dot(Vector3.new(0, 1, 0))))
		return SlopeAngle
	end

	return nil
end

function CoreService:CheckLedge()
	local RayOrigin = self.HRP.Position
	local RayDirection = Vector3.new(0, -1, 0) * 4

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local RaycastResult = workspace:Raycast(RayOrigin, RayDirection, raycastParams)

	if not RaycastResult then
		return true
	end

	return false
end

function CoreService:FollowPath(destination)
	local success, errorMessage = pcall(function()
		self.Path:ComputeAsync(self.HumanoidRootPart.Position - Vector3.new(0, self.Character.PrimaryPart.Size.Y / 0.75, 0), destination)
	end)

	local LedgeDetected = self:CheckLedge()
	local SlopeAngle = self:CheckSlope()

	if LedgeDetected then
		--[[if self:InitiateJumpAndClimb() then
			return
		end]]
		self.Humanoid:MoveTo(destination)
		return
	end

	if SlopeAngle and SlopeAngle > 45 then
		--[[if self:InitiateJumpAndClimb() then
			return
		end]]

		local DirectionTarget = (destination - self.HumanoidRootPart.Position).unit
		self.Humanoid:MoveTo(destination)
		return
	end

	if success and self.Path.Status == Enum.PathStatus.Success then
		self.Waypoints = self.Path:GetWaypoints()

		if self.ReachedConnection then
			self.ReachedConnection:Disconnect()
			self.ReachedConnection = nil
		end

		self.ReachedConnection = self.Humanoid.MoveToFinished:Connect(function(reached)
			if reached and self.NextWaypointIndex < #self.Waypoints then
				self.NextWaypointIndex += 1
				local nextWaypoint = self.Waypoints[self.NextWaypointIndex]

				if nextWaypoint.Action == Enum.PathWaypointAction.Jump then
					--[[if try climb then
						return]]
					--[[else]]if self.Humanoid.FloorMaterial.Name ~= "Air" then
						self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
				end

				self.Humanoid:MoveTo(nextWaypoint.Position)
			else
				if self.ReachedConnection then
					self.ReachedConnection:Disconnect()
					self.ReachedConnection = nil
				end
			end
		end)

		self.NextWaypointIndex = 2
		if self.Waypoints and self.Waypoints[self.NextWaypointIndex] then
			self.Humanoid:MoveTo(self.Waypoints[self.NextWaypointIndex].Position)
		end
	else
		--[[if try climb then
			return
		end]]
		self.Humanoid:MoveTo(destination)
	end
end

function CoreService:HandleDamage(victim, attacker)
	if not attacker then return end

	local selfInstance = CoreService.Instances[victim]
	if not selfInstance then return end

	local victimAlly = selfInstance.Humanoid:GetAttribute("AllyGroup")
	local attackerHumanoid = attacker:FindFirstChild("Humanoid")
	local attackerAlly = attackerHumanoid and attackerHumanoid:GetAttribute("AllyGroup")
	if victimAlly and attackerAlly and victimAlly == attackerAlly then
		return
	end

	local currentTime = tick()
	if currentTime < selfInstance.DamageCooldown then return end

	selfInstance.DamageCooldown = currentTime + 1

	if not (attacker:FindFirstChild("Humanoid") and attacker:FindFirstChild("HumanoidRootPart")) then
		return
	end

	selfInstance.LastAttacker = attacker
	selfInstance.Humanoid:SetAttribute("InCombat", true)

	if selfInstance.currentTarget and selfInstance.currentTarget ~= attacker then
		if not (selfInstance.currentTarget:FindFirstChild("HumanoidRootPart")) then
			selfInstance.currentTarget = nil
		else
			local currentDistance = (selfInstance.HumanoidRootPart.Position - selfInstance.currentTarget.HumanoidRootPart.Position).Magnitude
			local attackerDistance = (selfInstance.HumanoidRootPart.Position - attacker.HumanoidRootPart.Position).Magnitude

			if attackerDistance < currentDistance * 0.8 or currentDistance > selfInstance.Range then
				if selfInstance.currentTarget then
					Coordinator:RemoveFromEngagement(selfInstance, selfInstance.currentTarget)
				end

				selfInstance.currentTarget = attacker
				selfInstance.TrackingEndTime = tick() + 30

				Coordinator:RegisterEngagement(selfInstance, attacker)
			end
		end
	elseif not selfInstance.currentTarget then
		selfInstance.currentTarget = attacker
		selfInstance.TrackingEndTime = tick() + 30

		Coordinator:RegisterEngagement(selfInstance, attacker)
	end
end

function CoreService:LookAtTarget(target)
	if not (target and target:FindFirstChild("HumanoidRootPart")) then 
		if self.RotationGyro then
			self.RotationGyro.CFrame = self.HRP.CFrame
		end
		return 
	end

	local targetPos = target.HumanoidRootPart.Position
	local characterPos = self.HRP.Position

	if not (targetPos and characterPos) then return end

	local lookDirection = (Vector3.new(targetPos.X, characterPos.Y, targetPos.Z) - characterPos)

	if lookDirection.Magnitude == 0 then return end

	lookDirection = lookDirection.Unit
	local targetCFrame = CFrame.new(characterPos, characterPos + lookDirection)

	if self.RotationGyro then
		local currentRotation = self.RotationGyro.CFrame.Rotation
		local targetRotation = targetCFrame.Rotation
		local interpolatedRotation = currentRotation:Lerp(targetRotation, 0.2)

		self.RotationGyro.CFrame = CFrame.new(characterPos) * interpolatedRotation
	end
end

function CoreService:CalculateTargetPosition(targetPosition)
	local direction = (targetPosition - self.HRP.Position).Unit
	local distance = (targetPosition - self.HRP.Position).Magnitude

	if distance < self.PreferredDistance then
		return self.HRP.Position - direction * (self.PreferredDistance * 0.5)
	elseif distance > self.AttackRange then
		return targetPosition - direction * (self.PreferredDistance * 1.1)
	else
		return self.HRP.Position
	end
end

function CoreService:CalculateCirclingPosition(targetPosition)
	local currentTime = tick()
	local angle = currentTime * 2
	local radius = self.PreferredDistance * 1.35
	local offsetX = math.cos(angle) * radius
	local offsetZ = math.sin(angle) * radius
	return targetPosition + Vector3.new(offsetX, 0, offsetZ)
end

function CoreService:UpdateRotation(target)
	if not (target and target:FindFirstChild("HumanoidRootPart")) then return end

	local targetPos = target.HumanoidRootPart.Position
	local characterPos = self.HRP.Position
	local lookDirection = (Vector3.new(targetPos.X, characterPos.Y, targetPos.Z) - characterPos)

	if lookDirection.Magnitude == 0 then return end

	lookDirection = lookDirection.Unit
	local targetCFrame = CFrame.new(characterPos, characterPos + lookDirection)

	if self.RotationGyro then
		local interpolationSpeed = 0.4
		local currentRotation = self.RotationGyro.CFrame.Rotation
		local targetRotation = targetCFrame.Rotation
		local interpolatedRotation = currentRotation:Lerp(targetRotation, interpolationSpeed)

		self.RotationGyro.CFrame = CFrame.new(characterPos) * interpolatedRotation
	end
end

function CoreService:Start()
	task.spawn(function()
		while task.wait() do
			if self.Humanoid.Health <= 0 then
				-- Ragdoll
				self:Cleanup()
				break
			end

			self.HRP:SetNetworkOwner(nil)

			if self.Humanoid:GetAttribute("InCombat") and not self.currentTarget then
				if tick() - self.TrackingEndTime > 10 then
					self.Humanoid:SetAttribute("InCombat", false)
					self.LastAttacker = nil
				end
			end

			local target = self:FindTarget()
			if target and target.Humanoid.Health > 0 then
				self:LookAtTarget(target)
				self:UpdateRotation(target)

				if target ~= self.currentTarget then
					if self.currentTarget then
						Coordinator:RemoveFromEngagement(self, self.currentTarget)
					end
					Coordinator:RegisterEngagement(self, target)
					self.currentTarget = target
					self.TrackingEndTime = tick() + 30
				end

				local distance = (self.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude 

				if Coordinator:ShouldEngage(self, target) then
					if distance > self.Range then return end

					if distance <= self.AttackRange then -- Error!!!!
						self:RunStop()
						if self.AiCombat then
							local shouldAttack = Coordinator:ShouldEngage(self, target)
							if shouldAttack then
								self:HandleCombat(target)
							end
						end
					elseif distance > self.AttackRange + 1 then
						local targetPosition = self:CalculateTargetPosition(target.HumanoidRootPart.Position)
						self:FollowPath(targetPosition)
						self:Run()
					end
				else
					local waitPos = Coordinator:GetWaitPosition(self, target)
					if waitPos then
						local distanceToWaitPos = (self.HumanoidRootPart.Position - waitPos).Magnitude
						if distanceToWaitPos > 5 then
							self:FollowPath(waitPos)
							if distanceToWaitPos > self.AttackRange * 2 then
								self:Run()
							else
								self:RunStop()
							end
						else
							self.Humanoid:MoveTo(self.HumanoidRootPart.Position)
							self:RunStop()
						end
					end
				end

				if distance > self.Range * 1.2 then
					if self.ReachedConnection then
						self.ReachedConnection:Disconnect()
						self.ReachedConnection = nil
					end
					self:RunStop()
					Coordinator:RemoveFromEngagement(self, target)
					self.currentTarget = nil
				end
			else
				if self.currentTarget and self.Behavior == "Passive" then
					local currentTargetHealth = self.currentTarget.Humanoid.Health
					if currentTargetHealth <= 0 then
						self.Humanoid:SetAttribute("InCombat", false)
						self.LastAttacker = nil
						self.currentTarget = nil
						self.TrackingEndTime = 0
						Coordinator:RemoveFromEngagement(self, self.currentTarget)
					end
				end
				self:RunStop()
			end
		end
	end)
end

function CoreService:Cleanup()
	for _, Part in ipairs(self.Character:GetDescendants()) do
		if Part:IsA("Part") or Part:IsA("MeshPart") or Part:IsA("Decal") then
			if Part.Name == "RightGrip" or Part.Name == "LeftGrip" or Part.Name == "HumanoidRootPart" then
				continue
			end

			game.TweenService:Create(Part, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 1}):Play()
		end
	end

	if self.ReachedConnection then
		self.ReachedConnection:Disconnect()
		self.ReachedConnection = nil
	end

	if self.RotationGyro then
		self.RotationGyro:Destroy()
		self.RotationGyro = nil
	end

	self:RunStop()
	self:ClearVisualWaypoints()

	Coordinator:RemoveFromAllEngagements(self)
	Coordinator:RemoveFromEngagement(self, game.Players:GetPlayerFromCharacter(self.currentTarget))
	self.currentTarget = nil

	if self.Character then
		self.Character:Destroy()
	end
end

return CoreService