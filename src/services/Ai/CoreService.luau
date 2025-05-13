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
	WalkSpeed: number,
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
local ChatService = game:GetService("Chat")
local WeaponData = require(game.ReplicatedStorage.Modules.Data.Combat.WeaponData)
local CombatService = require(game.ServerScriptService.Services.Combat.CombatService)
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
	self.WalkSpeed = Info.WalkSpeed or 16

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
		WaypointSpacing = 20,
	})

	self.ClimbCount = 0

	self.Weapon = Info.Weapon or "Fist"
	self.Range = Info.Range or 100
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
	if not self.Running and not Services.Status:CheckStatus(self.Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) then
		self.Running = true
        self.Humanoid.WalkSpeed = self.WalkSpeed * 2
        local AnimationTrack = Utility.Animation:Play(Modules.Animation.Assets.Animations.LOCOMOTION.SPRINT.id, self.Humanoid, 1, Enum.AnimationPriority.Action, "Run")
		Services.Status:CreateStatus(self.Humanoid, "Movement", "Running", {Set = true})

        self.StateChangedConnection = self.Humanoid.StateChanged:Connect(function(_, newState)
            if AnimationTrack then
                if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
                    AnimationTrack:AdjustSpeed(0.25)
                elseif newState == Enum.HumanoidStateType.Running then
                    AnimationTrack:AdjustSpeed(1)
                end
            end
        end)
	end
end

function CoreService:RunStop()
	if Services.Status:CheckSpecific(self.Humanoid, {Connection = true}, "Running") then
		self.Debounce = true
		task.delay(0.25, function()
			self.Debounce = false
		end)
	end

	if self.StateChangedConnection then
		self.StateChangedConnection:Disconnect()
		self.StateChangedConnection = nil
	end

	self.Running = false
	self.Humanoid.WalkSpeed = self.WalkSpeed
	Utility.Animation:Stop(self.Humanoid, "Run")
	Services.Status:CreateStatus(self.Humanoid, "Movement", "Running", {Set = false})
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
	local RayDirection = Vector3.new(0, -1, 0) * 10

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local RaycastResult = workspace:Raycast(RayOrigin, RayDirection, raycastParams)

	if not RaycastResult then
		return true
	end

	return false
end

function CoreService:Climb()
    local function WallCheck(Character, HRP)
        if not HRP then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants()}
        local directions = {
            HRP.CFrame.LookVector,
            -HRP.CFrame.RightVector,
            HRP.CFrame.RightVector,
            -HRP.CFrame.LookVector * 0.5
        }
        
        for _, direction in ipairs(directions) do
            local result = workspace:Raycast(HRP.Position, direction * 3, params)
            if result and result.Instance.Transparency ~= 1 and not result.Instance:GetAttribute("NoClimb") then
                return true
            end
        end
        return false
    end

    if WallCheck(self.Character, self.HRP) and self.ClimbCount < 2 then
        if Services.Status:CheckStatus(self.Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) then return end
        if Services.Status:CheckCooldowns(self.Humanoid, {Connection = true, "Climb"}) then return end

		self.ClimbCount = self.ClimbCount + 1
		Services.Status:CreateStatus(self.Humanoid, "Movement", "Climbing", {Set = true})

        local ClimbVel = Instance.new("BodyVelocity")
        ClimbVel.Name = "ClimbVelocity"
        ClimbVel.P = 3e3
        ClimbVel.MaxForce = Vector3.new(50000, 50000, 50000)
        ClimbVel.Velocity = (self.HRP.CFrame.UpVector * 10)
        ClimbVel.Parent = self.HRP
        Debris:AddItem(ClimbVel, 0.2)
        
        if self.ClimbCount == 1 then
            Utility.Animation:Play(Modules.Animation.Assets.Animations.WALL.CLIMB_1.id, self.Humanoid, 1, Enum.AnimationPriority.Action4, "Climb")
        elseif self.ClimbCount == 2 then
            Utility.Animation:Play(Modules.Animation.Assets.Animations.WALL.CLIMB_2.id, self.Humanoid, 1, Enum.AnimationPriority.Action4, "Climb")
        end

        task.delay(0.25, function()
            local ClimbVel = Instance.new("BodyVelocity")
            ClimbVel.Name = "ClimbVelocity"
            ClimbVel.P = 3e3
            ClimbVel.MaxForce = Vector3.new(50000, 50000, 50000)
            ClimbVel.Velocity = (self.HRP.CFrame.UpVector * 55)
            ClimbVel.Parent = self.HRP
            Debris:AddItem(ClimbVel, 0.2)

            local Climb = "Climb_"..tostring(math.random(1,3))
			Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[Climb].id, parent = self.HRP, duration = 2, volume = 0.25})

            if self.ClimbCount >= 2 then
				Services.Status:CreateStatus(self.Humanoid, "Cooldown", "Climb", {Set = true})
            end

            task.delay(0.3, function()
				Services.Status:CreateStatus(self.Humanoid, "Movement", "Climbing", {Set = false})

                local function Grounded()
                    if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
                        self.ClimbCount = 0
                        if Services.Status:CheckCooldowns(self.Humanoid, {Connection = true, "Climb"}) then
							Services.Status:CreateStatus(self.Humanoid, "Cooldown", "Climb", {Set = false})
                        end
                        return true
                    end
                    return false
                end

                while not Grounded() do
                    task.wait()
                end
            end)
        end)
    end
end

function CoreService:FollowPath(destination)
	local success, errorMessage = pcall(function()
		self.Path:ComputeAsync(self.HRP.Position - Vector3.new(0, self.Character.PrimaryPart.Size.Y / 0.75, 0), destination)
	end)

	local LedgeDetected = self:CheckLedge()
	local SlopeAngle = self:CheckSlope()

	if LedgeDetected then
		if self:Climb() then
			return
		end

		self.Humanoid:MoveTo(destination)
		return
	end

	if SlopeAngle and SlopeAngle > 45 then
		if self:Climb() then
			return
		end

		local DirectionTarget = (destination - self.HRP.Position).unit
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
					if self:Climb() then
						return
					elseif self.Humanoid.FloorMaterial.Name ~= "Air" then
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
		if self:Climb() then
			return
		end

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

function CoreService:HandleCombat(target, distance)
	local Data = WeaponData[self.Weapon]
	
	local Speech = {
		"You dare challenge me?",
		"This won't end well for you.",
		"I've seen stronger winds than you.",
		"Prepare yourself!",
		"You're no match for me!"
	}

	if not Services.Status:CheckSpecific(self.Humanoid, {Connection = true}, "Equipped") then
		CombatService:Equip(self.Humanoid, self.Weapon, Data)

		local randomIndex = math.random(1, #Speech)
		local Message = Speech[randomIndex]
		ChatService:Chat(self.Character.Head, Message, Enum.ChatColor.White)

	elseif Services.Status:CheckSpecific(self.Humanoid, {Connection = true}, "Equipped") and distance <= self.AttackRange then
		if Services.Status:CheckSpecific(target.Humanoid, {Connection = true}, "Attacking", "Critical") then
			local Chance = 0.55
			if math.random() < Chance then
				CombatService:ParryStart(self.Humanoid, self.Weapon, Data)
				repeat task.wait() until not Services.Status:CheckSpecific(target.Humanoid, {Connection = true}, "Attacking")
				CombatService:ParryStop(self.Humanoid)
				return
			end
		end

		CombatService:Attack(self.Character, self.Humanoid, self.HRP, Data)

		local Random = math.random()

		if Random < 0.25 then
			CombatService:Critical(self.Character, self.Humanoid, self.HRP, Data)
		elseif Random < 0.40 then
			CombatService:Stomp(self.Character, self.Humanoid, self.HRP, {Ai = true})

			task.delay(0.55, function()
				repeat task.wait() until not Services.Status:CheckSpecific(self.Humanoid, {Connection = true}, "Attacking")
				if self.Humanoid.FloorMaterial ~= Enum.Material.Air then return end
				CombatService:Aerial(self.Character, self.Humanoid, self.HRP, Data)
			end)
		end
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

				local distance = (self.HRP.Position - target.HumanoidRootPart.Position).Magnitude 

				if Coordinator:ShouldEngage(self, target) then
					self:HandleCombat(target, distance)
					
					if distance <= self.AttackRange then
						self:RunStop()
					elseif distance > self.AttackRange + 1 then
						local targetPosition = self:CalculateTargetPosition(target.HumanoidRootPart.Position)
						self:FollowPath(targetPosition)
						self:Run()
					end
				else
					local waitPos = Coordinator:GetWaitPosition(self, target)
					if waitPos then
						local distanceToWaitPos = (self.HRP.Position - waitPos).Magnitude
						if distanceToWaitPos > 5 then
							self:FollowPath(waitPos)
							if distanceToWaitPos > self.AttackRange * 2 then
								self:Run()
							else
								self:RunStop()
							end
						else
							self.Humanoid:MoveTo(self.HRP.Position)
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
				Coordinator:RemoveFromAllEngagements(self)
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