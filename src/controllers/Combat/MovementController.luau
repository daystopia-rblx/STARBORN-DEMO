--[[ MovementController
    Core player movement (Local)
    @author @NantesF
    @version 1.0.0
    @date 2025-04-08
]]

local MovementController = {
    --[[ Constraints ]]
    TapTime = 0.3 :: number,
    LastPress = 0 :: number,
    Debounce = false :: boolean,

    Dodging = false :: boolean,
    Cooldown = false :: boolean,
    DashVelocity = nil :: BodyVelocity,
    DashIdentity = nil :: string,

    FadeDuration = 1.5,
    MaxDescent = 20,
    WallrunSpeed = 40,
    WallDistance = 1.5,
    FrontDistance = 2,
    
    HorizontalForce = 40,
    VerticalForce = 30,

    Hang = true,
    ClimbCount = 0,
}

MovementController.Dependencies = {
    "Event",
    "Status",
}

MovementController.Modules = {
    "Animation",
    "Sound"
}

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)

--[[ State ]]
local Controllers
local Modules

--[[ Core Functions ]]
function MovementController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
	self:ListenForDeath()
    return true
end

function MovementController:ListenForDeath()
    local Player = Players.LocalPlayer

    if self.Connection then
        self.Connection:Disconnect()
    end

    self.Connection = Player.CharacterAdded:Connect(function(Character)
        local HRP = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:WaitForChild("Humanoid")

        self.ClimbCount = 0
        self:Footsteps()
        self:WallRun()
    end)

    if Player.Character then
        self.ClimbCount = 0
        self:Footsteps()
        self:WallRun()
    end
end

--[[ Footsteps ]]
function MovementController:Footsteps()
    local Player = Players.LocalPlayer
    repeat task.wait() until Player.Character and Player.Character.Parent
    local Character = Player.Character
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local Humanoid = Character:WaitForChild("Humanoid")
    local Animator = Humanoid:WaitForChild("Animator")

    local walkConnections = {}
    local runConnections = {}
    local wallRunConnections = {}

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Character, game.Debris:GetDescendants()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local lastMaterials = {
        LeftFoot = "Slate",
        RightFoot = "Slate"
    }

    local function GetFloorMaterial(footPart)
        local origin = footPart.Position
        local direction = Vector3.new(0, -1.5, 0)
        
        local rayResult = workspace:Raycast(origin, direction, rayParams)
        
        if rayResult and rayResult.Material then
            lastMaterials[footPart.Name] = rayResult.Material.Name
            return rayResult.Material.Name
        else
            return lastMaterials[footPart.Name] or "Slate"
        end
    end

    local function PlaySurfaceSound(stepEvent, footPart)
        if Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Dodging") then return end
        
        local surfaceMaterial = GetFloorMaterial(footPart)
        local materialName = surfaceMaterial
        
        if Modules.Sound.Assets.Sounds.SFX.Footsteps[materialName] == nil then
            materialName = "Slate"
        end

        local Sound = tostring(materialName.."_"..math.random(1, 4))
        Controllers.Event:FireServer("Particle.Create", {
            effectType = "SOUND", 
            sfx = Modules.Sound.Assets.Sounds.SFX.Footsteps[materialName][Sound].id, 
            parent = footPart, 
            duration = 2, 
            volume = 0.5
        })
    end

    local function handleAnimations()
        for _, conn in pairs(walkConnections) do conn:Disconnect() end
        for _, conn in pairs(runConnections) do conn:Disconnect() end
        for _, conn in pairs(wallRunConnections) do conn:Disconnect() end

        walkConnections = {}
        runConnections = {}
        wallRunConnections = {}

        local tracks = Animator:GetPlayingAnimationTracks()

        local isRunning = Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Running")
        local isWallRunning = Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Wallrunning")

        for _, track in ipairs(tracks) do
            if isRunning and not isWallRunning and track.Name == "Run" then
                    runConnections[track] = track.KeyframeReached:Connect(function(stepEvent)
                        if Character:FindFirstChild(stepEvent) then
                            PlaySurfaceSound(stepEvent, Character[stepEvent])
                        end
                    end)
                    
                elseif not isRunning and not isWallRunning and track.Name == "WalkAnim" then
                    walkConnections[track] = track.KeyframeReached:Connect(function(stepEvent)
                        if Character:FindFirstChild(stepEvent) then
                            PlaySurfaceSound(stepEvent, Character[stepEvent])
                        end
                    end)
                    
                elseif isWallRunning and track.Name == "Wallrun" then
                    wallRunConnections[track] = track.KeyframeReached:Connect(function(stepEvent)
                        if not self.CurrentWallSide or not Character:FindFirstChild(stepEvent) then return end
                        
                        local sideParams = RaycastParams.new()
                        sideParams.FilterType = Enum.RaycastFilterType.Exclude
                        sideParams.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants()}
                        
                        local rayDirection
                        if self.CurrentWallSide == "left" then
                            rayDirection = -HRP.CFrame.RightVector
                        elseif self.CurrentWallSide == "right" then
                            rayDirection = HRP.CFrame.RightVector
                        else
                            return
                        end
                        
                        local wallHit = workspace:Raycast(HRP.Position, rayDirection * 1.5, sideParams)
                        local materialName
                        
                        if wallHit and wallHit.Material then
                            materialName = wallHit.Material.Name
                            lastMaterials[stepEvent] = materialName
                        else
                            materialName = lastMaterials[stepEvent] or "Slate"
                        end
                        
                        if Modules.Sound.Assets.Sounds.SFX.Footsteps[materialName] == nil then
                            materialName = "Slate"
                        end
                        
                        local footPart = Character[stepEvent]
                        local Sound = tostring(materialName.."_"..math.random(1, 4))
                        
                        Controllers.Event:FireServer("Particle.Create", {
                            effectType = "SOUND", 
                            sfx = Modules.Sound.Assets.Sounds.SFX.Footsteps[materialName][Sound].id, 
                            parent = footPart, 
                            duration = 2, 
                            volume = 0.5
                        })
                    end)
                end
        end
    end

    task.spawn(function()
        while task.wait() do
            handleAnimations()
        end
    end)
end

--[[ Running ]]
function MovementController:HandlePressed()
    if self.Debounce then return end
    local CurrentTime = tick()
    if CurrentTime - self.LastPress <= self.TapTime then
        self:ToggleRun(true)
    end
    self.LastPress = CurrentTime
end

function MovementController:ToggleRun(Active: boolean)
    local Player = Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")

    task.spawn(function()
        while task.wait() do
            if Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking", "Critical", "Parrying", "Blocking") then
                self:ToggleRun(false)
                break
            end
        end
    end)

    if not Controllers.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) and Active == true then
        Humanoid.WalkSpeed = Character:GetAttribute("SPEED") * 2
        local AnimationTrack = Animation:Play(Modules.Animation.Assets.Animations.LOCOMOTION.SPRINT.id, Humanoid, 1, Enum.AnimationPriority.Action, "Run")
        Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Running", {Set = true})

        self.StateChangedConnection = Humanoid.StateChanged:Connect(function(_, newState)
            if AnimationTrack then
                if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
                    AnimationTrack:AdjustSpeed(0.25)
                elseif newState == Enum.HumanoidStateType.Running then
                    AnimationTrack:AdjustSpeed(1)
                end
            end
        end)

    elseif Active ~= true then
        if Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Running") then
            self.Debounce = true
            task.delay(0.25, function()
                self.Debounce = false
            end)
        end

        if self.StateChangedConnection then
            self.StateChangedConnection:Disconnect()
            self.StateChangedConnection = nil
        end

        Humanoid.WalkSpeed = Character:GetAttribute("SPEED")
        Animation:Stop(Humanoid, "Run")
        Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Running", {Set = false})
    end
end

--[[ Dodging ]]
function MovementController:CurrentlyDodging()
	return self.Dodging
end

function MovementController:CancelDodge()
    local Player = Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChild("Humanoid")

	if not self.Dodging then return end

	if self.DashVelocity and self.DashVelocity.Parent then
		self.DashVelocity:Destroy()
		self.DashVelocity = nil
	end

    Animation:Stop(Humanoid, "Dodge")
	Animation:Play(Modules.Animation.Assets.Animations.ROLL.CANCEL.id, Humanoid, 1.15, Enum.AnimationPriority.Action3, "DodgeCancel")

	task.wait(0.1)

    Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Dodging", {Set = false})

	self.Dodging = false
	self.DashIdentity = nil
    self.Cooldown = true

	task.delay(1.5, function()
		self.Cooldown = false
	end)
end

function MovementController:StartDodge()
    local Player = game.Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end

    if self.Dodging or self.Cooldown then return end
    if Controllers.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) then return end
    if Controllers.Status:CheckCooldowns(Humanoid, {Connection = true}, "Dodge") then return end

    local state = Humanoid:GetState()
    local isAir = state == Enum.HumanoidStateType.Freefall

    local flatVel = Vector3.new(HRP.Velocity.X, 0, HRP.Velocity.Z)
    local dashIdentity
    if flatVel.Magnitude < 0.1 and not isAir then
        dashIdentity = "BACK"
    elseif flatVel.Magnitude < 0.1 and isAir then
        dashIdentity = "FORWARD"
    else
        local vUnit = flatVel.Unit
        local forwardDot = HRP.CFrame.LookVector:Dot(vUnit)
        local rightDot   = HRP.CFrame.RightVector:Dot(vUnit)
        dashIdentity = rightDot < -0.7 and "LEFT"
            or rightDot >  0.7 and "RIGHT"
            or forwardDot < -0.5 and "BACK"
            or "FORWARD"
    end

    self.DashIdentity = dashIdentity
    self.Dodging = true
    self.Cooldown = true

    Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Dodging", {Set = true, Timed = true, Time = 0.2})
    Controllers.Event:FireServer("Status.Create", Humanoid, "Cooldown", "Dodge", {Set = true, Timed = true, Time = 1.5})
    Controllers.Event:FireServer("Velocity.Create", Character)

    local dashVelocity = Instance.new("BodyVelocity")
    dashVelocity.MaxForce = Vector3.new(3e4, 3e4, 3e4)
    dashVelocity.Parent = HRP
    Debris:AddItem(dashVelocity, 0.35)
    self.DashVelocity = dashVelocity

    Animation:Play(Modules.Animation.Assets.Animations.ROLL[dashIdentity].id, Humanoid, 1, Enum.AnimationPriority.Action3, "Dodge")
    local sfx = "Dodge_" .. tostring(math.random(1, 3))
    Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[sfx].id, parent = HRP, duration = 2, volume = 0.75})

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {Character}

    local startTime = tick()
    repeat
        task.wait()
        if not self.Dodging then break end

        local dirVec
        if dashIdentity == "FORWARD" and isAir then
            dirVec = workspace.CurrentCamera.CFrame.LookVector
        else
            local baseDir = (dashIdentity == "LEFT" or dashIdentity == "RIGHT") and HRP.CFrame.RightVector or HRP.CFrame.LookVector
            local inv = (dashIdentity == "LEFT" or dashIdentity == "BACK") and -1 or 1
            dirVec = baseDir * inv
        end

        local obstructed = workspace:Raycast(HRP.Position, dirVec * 3, rayParams)
        if not obstructed then
            dashVelocity.Velocity = dirVec * 50
        end
    until tick() - startTime >= 0.25

    if self.DashVelocity and self.DashVelocity.Parent then
        self.DashVelocity:Destroy()
        self.DashVelocity = nil
    end

    task.delay(0.2, function()
        self.Dodging = false
        self.DashIdentity = nil
    end)
    
    task.delay(1.5, function()
        self.Cooldown = false
    end)
end

--[[ Wall-running ]]
function MovementController:HoldingKey(Active: boolean)
	self.WallRunKey = Active
end

function MovementController:WallRun()
    local Player = Players.LocalPlayer
    local Character = Player.Character
    if not Character then return end
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local Humanoid = Character:WaitForChild("Humanoid")

    self.WallRunCount = 0

    self:ResetWallRunState(Humanoid)

    self.WallRunConnection = RunService.Heartbeat:Connect(function(dt)
        self:HandleWallRunLogic(dt, HRP, Humanoid, Character)
    end)
end

function MovementController:ResetWallRunState(Humanoid)
    self.WallRunTime = 0
    self.Wallrunning = false
    self.WasWallrunning = false
    self.CurrentWallSide = nil
    Humanoid.AutoRotate = true
    Animation:Stop(Humanoid, "Wallrun")

    if self.WallRunBV then 
        self.WallRunBV:Destroy() 
        self.WallRunBV = nil
    end

    if self.WallRunConnection then
        self.WallRunConnection:Disconnect()
    end
    
    if self.WallLeapConnection then
        self.WallLeapConnection:Disconnect()
        self.WallLeapConnection = nil
    end
end

function MovementController:HandleWallRunLogic(dt, HRP, Humanoid, Character, leapHorizontalForce, leapVerticalForce, leapDuration)
    if Humanoid.FloorMaterial ~= Enum.Material.Air and self.WallRunCount > 0 then
        self.WallRunCount = 0
    end

    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        self:StopWallRun(Humanoid)
        return
    end
    
    local frontHit = self:CheckFrontCollision(HRP, Character)
    if frontHit then
        self:StopWallRun(Humanoid)
        return
    end

    if self.WallRunKey and not frontHit then
        local hitSide, sideName, part = self:DetectWallRunSurface(HRP, Character)
        if hitSide then
            self:PerformWallRun(dt, HRP, Humanoid, sideName, part)
            return
        end
    end
    
    if self.Wallrunning or self.WasWallrunning then
        if self.Wallrunning and not self.WallRunKey then
            local hitSide, sideName = self:DetectWallRunSurface(HRP, Character)
            self:PerformWallLeap(HRP, Humanoid, sideName)
        else
            self:StopWallRun(Humanoid)
        end
    end
end

function MovementController:CheckFrontCollision(HRP, Character)
    local frontParams = RaycastParams.new()
    frontParams.FilterType = Enum.RaycastFilterType.Exclude
    frontParams.FilterDescendantsInstances = {Character}
    
    return workspace:Raycast(HRP.Position, HRP.CFrame.LookVector * self.FrontDistance, frontParams)
end

function MovementController:DetectWallRunSurface(HRP, Character)
    local sideParams = RaycastParams.new()
    sideParams.FilterType = Enum.RaycastFilterType.Exclude
    sideParams.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants()}

    local function isValidWall(part)
        if not part or not part:IsA("BasePart") then return false end
        if part.Transparency >= 1 then return false end
        if not part.CanCollide then return false end
        if part:GetAttribute("NoClimb") == true then return false end
        return true
    end

    local function isParallelToWall(normal, lookVector)
        local rightVector = HRP.CFrame.RightVector
        local alignment = math.abs(normal:Dot(rightVector))
        return alignment > 0.75
    end

    local leftRay = workspace:Raycast(HRP.Position, -HRP.CFrame.RightVector * self.WallDistance, sideParams)
    if leftRay and isValidWall(leftRay.Instance) and isParallelToWall(leftRay.Normal, HRP.CFrame.LookVector) then
        self.CurrentWallSide = "left"
        return leftRay, "LEFT", leftRay.Instance
    end

    local rightRay = workspace:Raycast(HRP.Position, HRP.CFrame.RightVector * self.WallDistance, sideParams)
    if rightRay and isValidWall(rightRay.Instance) and isParallelToWall(rightRay.Normal, HRP.CFrame.LookVector) then
        self.CurrentWallSide = "right"
        return rightRay, "RIGHT", rightRay.Instance
    end

    return nil, nil
end

function MovementController:PerformWallRun(dt, HRP, Humanoid, sideName, part)
    if self.WallRunCooldown and not self.Wallrunning then return end
    if (not self.Wallrunning) and self.WallRunCount >= 2 then return end

    if Controllers.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running", "Equipped", "Wallrunning"}}) then return end

    if not self.Wallrunning then
        self.WallRunCount = self.WallRunCount + 1
        self.WallRunTime = 0
        self.InitialBoostPhase = true
    else
        self.WallRunTime = self.WallRunTime + dt
    end

    Animation:Stop(Humanoid, "Dodge")
    Animation:Stop(Humanoid, "DodgeCancel")

    if not self.WallRunAnim then
        local WallAnim = "RUN_"..tostring(sideName)
        self.WallRunAnim = Animation:Play(Modules.Animation.Assets.Animations.WALL[WallAnim].id, Humanoid, 1, Enum.AnimationPriority.Action2, "Wallrun")
    end

    Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Wallrunning", {Set = true}) 
    Controllers.Event:FireServer("Velocity.Create", HRP.Parent)

    self.Wallrunning = true
    Humanoid.AutoRotate = false
    if not self.WallRunGyro then
        local wallNormal = part.CFrame.LookVector
        local targetYaw = math.atan2(-wallNormal.Z, wallNormal.X) + math.pi/2
        local gyro = Instance.new("BodyGyro")
        gyro.P = 2000
        gyro.D = 50000
        gyro.MaxTorque = Vector3.new(0,math.huge,0)
        gyro.CFrame = CFrame.Angles(0, targetYaw, 0)
        gyro.Parent = HRP
        self.WallRunGyro = gyro
    end
    
    local verticalVelocity = 0
    
    if self.InitialBoostPhase and self.WallRunTime < 0.3 then
        local boostProgress = self.WallRunTime / 0.3
        verticalVelocity = 15 * (1 - boostProgress)
    else
        self.InitialBoostPhase = false
        local descentProgress = math.clamp((self.WallRunTime - 0.3) / self.FadeDuration, 0, 1)
        verticalVelocity = -self.MaxDescent * descentProgress
    end

    if self.WallRunBV then
        self.WallRunBV:Destroy()
    end

    self.WallRunBV = Instance.new("BodyVelocity")
    self.WallRunBV.MaxForce = Vector3.new(3e4, 3e4, 3e4)
    self.WallRunBV.Velocity = HRP.CFrame.LookVector * self.WallrunSpeed + Vector3.new(0, verticalVelocity, 0)
    self.WallRunBV.Parent = HRP
    
    self.WasWallrunning = true
    self.WallRunCooldown = true

    if self.WasWallrunning then
        task.delay(0.15, function()
            self.WallRunCooldown = false
        end)
    end
end

function MovementController:PerformWallLeap(HRP, Humanoid, sideName)
    self:StopWallRun(Humanoid)

    local LeapAnim = "LEAP_"..tostring(sideName)
    Animation:Play(Modules.Animation.Assets.Animations.WALL[LeapAnim].id, Humanoid, 1, Enum.AnimationPriority.Action2, "Leap")
    Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Leaping", {Set = true}) 

    local Leap = "Dodge_"..tostring(math.random(1,3))
	Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[Leap].id, parent = HRP, duration = 2, volume = 0.75})

    local leapDirection = HRP.CFrame.LookVector
    
    local sideForce = Vector3.new(0, 0, 0)
    if self.CurrentWallSide == "left" then
        sideForce = HRP.CFrame.RightVector * (self.HorizontalForce * 0.5)
    elseif self.CurrentWallSide == "right" then
        sideForce = -HRP.CFrame.RightVector * (self.HorizontalForce * 0.5)
    end
    
    self.WallLeapBV = Instance.new("BodyVelocity")
    self.WallLeapBV.MaxForce = Vector3.new(3e4, 3e4, 3e4)
    self.WallLeapBV.Velocity = (leapDirection * self.HorizontalForce) + sideForce + Vector3.new(0, self.VerticalForce, 0)
    self.WallLeapBV.Parent = HRP
    Debris:AddItem(self.WallLeapBV, 0.15)

    task.delay(0.15, function()
        Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Leaping", {Set = false}) 
    end)
end

function MovementController:StopWallRun(Humanoid)
    Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Wallrunning", {Set = false}) 
    Animation:Stop(Humanoid, "Wallrun")
    self.WallRunAnim = nil
    self.Wallrunning = false
    self.WasWallrunning = false
    Humanoid.AutoRotate = true

    if self.WallRunGyro then 
        self.WallRunGyro:Destroy() 
        self.WallRunGyro = nil
    end    

    if self.WallRunBV then
        self.WallRunBV:Destroy()
        self.WallRunBV = nil
    end
end

--[[ Wall Climbing ]]
function MovementController:DetectLedge()
	local Player = Players.LocalPlayer
	local Character = Player.Character
	if not Character then return end
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local Humanoid = Character:WaitForChild("Humanoid")

    if Controllers.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) then return end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants()}

	local function Check(ledge)
		local PartCheck = workspace:Raycast(ledge.Position + Vector3.new(0, -1, 0) + ledge.LookVector * 1, ledge.UpVector * 3, rayParams)
		if PartCheck == nil then
			return true
		else
			return false
		end
	end

    if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		local hangCheck = workspace:Raycast(HRP.CFrame.Position, HRP.CFrame.LookVector * 5, rayParams)

		if hangCheck and hangCheck.Instance and not hangCheck.Instance:GetAttribute("NoClimb") then
			local localPos = hangCheck.Instance.CFrame:PointToObjectSpace(hangCheck.Position)
			local localLedgePos = Vector3.new(localPos.X, hangCheck.Instance.Size.Y/2, localPos.Z)
			local ledgePos = hangCheck.Instance.CFrame:PointToWorldSpace(localLedgePos)
			local ledgeOffset = CFrame.lookAt(ledgePos, ledgePos - hangCheck.Normal)

			local magnitude = (ledgePos - Character.Head.Position).Magnitude
			if magnitude < 3 then
				if Check(ledgeOffset) then
                    Animation:Play(Modules.Animation.Assets.Animations.WALL.LEDGE.id, Humanoid, 1.25, Enum.AnimationPriority.Action4, "Ledge")

                    local ClimbVel = Instance.new("BodyVelocity")
                    ClimbVel.Name = "ClimbVelocity"
                    ClimbVel.P = 3e3
                    ClimbVel.MaxForce = Vector3.new(50000, 50000, 50000)
                    ClimbVel.Velocity = (HRP.CFrame.UpVector * 10)
                    ClimbVel.Parent = HRP
                    Debris:AddItem(ClimbVel, 0.05)

                    task.delay(0.1, function()
                        local LedgeVel = Instance.new("BodyVelocity")
                        LedgeVel.Name = "LedgeVelocity"
                        Debris:AddItem(LedgeVel, 0.2)

                        LedgeVel.P = 3e3
                        LedgeVel.MaxForce = Vector3.new(50000,50000,50000)
                        LedgeVel.Velocity = (HRP.CFrame.LookVector * 10) + (HRP.CFrame.UpVector * 30)

                        LedgeVel.Parent = HRP

                        local Climb = "Climb_"..tostring(math.random(1,3))
                        Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[Climb].id, parent = HRP, duration = 2, volume = 0.25})
                    end)
                    return true
				end
			end
		end
	end

    return false
end

function MovementController:Climb()
    local Player = Players.LocalPlayer
	local Character = Player.Character
	if not Character then return end
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local Humanoid = Character:WaitForChild("Humanoid")

    if self:DetectLedge() == true then return end

    local function WallCheck(Character, HRP)
        if not HRP then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants()}
        local directions = {HRP.CFrame.LookVector}
    
        for _, direction in ipairs(directions) do
            local result = workspace:Raycast(HRP.Position, direction * 3, params)
            if result and result.Instance.Transparency ~= 1 and not result.Instance:GetAttribute("NoClimb") then
                return true
            end
        end
        return false
    end

    if Humanoid.FloorMaterial == Enum.Material.Air and WallCheck(Character, HRP) and self.ClimbCount < 2 then
        if Controllers.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) then return end
        if Controllers.Status:CheckCooldowns(Humanoid, {Connection = true, "Climb"}) then return end

		self.ClimbCount = self.ClimbCount + 1
		Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Climbing", {Set = true}) 

        local ClimbVel = Instance.new("BodyVelocity")
        ClimbVel.Name = "ClimbVelocity"
        ClimbVel.P = 3e3
        ClimbVel.MaxForce = Vector3.new(50000, 50000, 50000)
        ClimbVel.Velocity = (HRP.CFrame.UpVector * 10)
        ClimbVel.Parent = HRP
        Debris:AddItem(ClimbVel, 0.2)
        
        if self.ClimbCount == 1 then
            Animation:Play(Modules.Animation.Assets.Animations.WALL.CLIMB_1.id, Humanoid, 1, Enum.AnimationPriority.Action4, "Climb")
        elseif self.ClimbCount == 2 then
            Animation:Play(Modules.Animation.Assets.Animations.WALL.CLIMB_2.id, Humanoid, 1, Enum.AnimationPriority.Action4, "Climb")
        end

        task.delay(0.25, function()
            local ClimbVel = Instance.new("BodyVelocity")
            ClimbVel.Name = "ClimbVelocity"
            ClimbVel.P = 3e3
            ClimbVel.MaxForce = Vector3.new(50000, 50000, 50000)
            ClimbVel.Velocity = (HRP.CFrame.UpVector * 45)
            ClimbVel.Parent = HRP
            Debris:AddItem(ClimbVel, 0.2)

            local Climb = "Climb_"..tostring(math.random(1,3))
            Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[Climb].id, parent = HRP, duration = 2, volume = 0.25})

            if self.ClimbCount >= 2 then
                Controllers.Event:FireServer("Status.Create", Humanoid, "Cooldown", "Climb", {Set = true}) 
            end

            task.delay(0.3, function()
                Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Climbing", {Set = false}) 

                local function Grounded()
                    if Humanoid.FloorMaterial ~= Enum.Material.Air then
                        self.ClimbCount = 0
                        if Controllers.Status:CheckCooldowns(Humanoid, {Connection = true, "Climb"}) then
                            Controllers.Event:FireServer("Status.Create", Humanoid, "Cooldown", "Climb", {Set = false}) 
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

return MovementController