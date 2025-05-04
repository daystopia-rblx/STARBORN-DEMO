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
	self:Footsteps()
	self:WallRun()
    return true
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

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local function RunSound(stepEvent: string)
		if Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Dodging") then return end

		local Floor = Humanoid.FloorMaterial.Name
		if Floor == "Air" then return end

		if Modules.Sound.Assets.Sounds.SFX.Footsteps[Floor] == nil then
			Floor = "Slate"
		end

		local Sound = tostring(Floor.."_"..math.random(1, 4))
		Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Footsteps[Floor][Sound].id, parent = Character[stepEvent], duration = 2, volume = 0.5})
	end

    local function handleAnimations()
        for _, conn in pairs(walkConnections) do conn:Disconnect() end
        for _, conn in pairs(runConnections) do conn:Disconnect() end

        walkConnections = {}
        runConnections = {}

        local tracks = Animator:GetPlayingAnimationTracks()

        local isRunning = Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Running")

        for _, track in ipairs(tracks) do
            if isRunning and track.Name == "Run" then
                runConnections[track] = track.KeyframeReached:Connect(function(stepEvent)
					RunSound(stepEvent)
				end)

            elseif not isRunning and track.Name == "WalkAnim" then
                walkConnections[track] = track.KeyframeReached:Connect(function(stepEvent)
					RunSound(stepEvent)
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
	local Character = Player.Character
	local Humanoid = Character.Humanoid
	local HRP = Character.HumanoidRootPart

	if self.Dodging or self.Cooldown then return end
	if Controllers.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running", "Equipped"}}) == true then return end
	if Controllers.Status:CheckCooldowns(Humanoid, {Connection = true}, "Dodge") == true then return end

	local velocity = Vector3.new(1, 0, 1) * HRP.Velocity
	local dashIdentity

	if velocity.Magnitude < 0.1 then
		dashIdentity = "BACK"
	else
		local velocityUnit = velocity.Unit
		local forwardDot = HRP.CFrame.LookVector:Dot(velocityUnit)
		local horizontalDot = HRP.CFrame.RightVector:Dot(velocityUnit)
		dashIdentity = horizontalDot < -0.7 and "LEFT"
			or horizontalDot > 0.7 and "RIGHT"
			or forwardDot < -0.5 and "BACK"
			or forwardDot > 0.5 and "FORWARD"
	end

	if not dashIdentity then return end
	self.DashIdentity = dashIdentity

	self.Dodging = true
	self.Cooldown = true

	Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Dodging", {Set = true, SetTo = false, Timed = true, Time = 0.2}) 
	Controllers.Event:FireServer("Status.Create", Humanoid, "Cooldown", "Dodge", {Set = true, SetTo = false, Timed = true, Time = 1.5})
    Controllers.Event:FireServer("Velocity.Create", Character)

	local dashVelocity = Instance.new("BodyVelocity")	
	dashVelocity.MaxForce = Vector3.new(30000, 30000, 30000)
	dashVelocity.Parent = HRP
	Debris:AddItem(dashVelocity, 0.35)

	self.DashVelocity = dashVelocity

	Animation:Play(Modules.Animation.Assets.Animations.ROLL[dashIdentity].id, Humanoid, 1, Enum.AnimationPriority.Action4, "Dodge")

	local Dodge = "Dodge_"..tostring(math.random(1,3))
	Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[Dodge].id, parent = HRP, duration = 2, volume = 0.75})

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {Character}
	local Obstructed = nil
	local startTick = tick()

	repeat task.wait()
		if not self.Dodging then break end

		local dashDirection = HRP.CFrame.RightVector
		local Inverse = 1
		if dashIdentity == "FORWARD" or dashIdentity == "BACK" then
			dashDirection = HRP.CFrame.LookVector
		end
		if dashIdentity == "BACK" or dashIdentity == "LEFT" then
			Inverse = -1
		end
		Obstructed = workspace:Raycast(HRP.Position, (dashDirection * Inverse) * 3, rayParams)
		if not Obstructed then
			dashVelocity.Velocity = dashDirection * ((50 * Inverse))
		end
	until tick() - startTick >= 0.25 or Obstructed

	if self.DashVelocity and self.DashVelocity.Parent then
		self.DashVelocity:Destroy()
		self.DashVelocity = nil
	end

	if self.Dodging then
		task.delay(0.2, function()
			self.Dodging = false
			self.DashIdentity = nil
		end)

		task.delay(1.5, function()
			self.Cooldown = false
		end)
	end
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

    local FADE_DURATION = 1.5
    local MAX_DESCENT = 20
    local WALLRUN_SPEED = 40
    local WALL_DETECTION_DISTANCE = 1.5
    local FRONT_DETECTION_DISTANCE = 2

    self:ResetWallRunState(Humanoid)

    self.WallRunConnection = RunService.Heartbeat:Connect(function(dt)
        self:HandleWallRunLogic(dt, HRP, Humanoid, Character, FADE_DURATION, MAX_DESCENT, WALLRUN_SPEED, WALL_DETECTION_DISTANCE, FRONT_DETECTION_DISTANCE)
    end)
end

function MovementController:ResetWallRunState(Humanoid)
    self.WallRunTime = 0
    self.Wallrunning = false
    self.WasWallrunning = false
    Humanoid.AutoRotate = true
    Animation:Stop(Humanoid, "Wallrun")

    if self.WallRunBV then 
        self.WallRunBV:Destroy() 
        self.WallRunBV = nil
    end

    if self.WallRunConnection then
        self.WallRunConnection:Disconnect()
    end
end

function MovementController:HandleWallRunLogic(dt, HRP, Humanoid, Character, fadeDuration, maxDescent, wallrunSpeed, wallDetectionDistance, frontDetectionDistance)
    if Humanoid.FloorMaterial ~= Enum.Material.Air then
        self:StopWallRun(Humanoid)
        return
    end
    
    local frontHit = self:CheckFrontCollision(HRP, Character, frontDetectionDistance)
    if frontHit then
        self:StopWallRun(Humanoid)
        return
    end
    
    if self.WallRunKey and not frontHit then
        local hitSide, sideName = self:DetectWallRunSurface(HRP, Character, wallDetectionDistance)
        
        if hitSide then
            self:PerformWallRun(dt, HRP, Humanoid, fadeDuration, maxDescent, wallrunSpeed, sideName)
            return
        end
    end
    
    if self.Wallrunning or self.WasWallrunning then
        self:StopWallRun(Humanoid)
    end
end

function MovementController:CheckFrontCollision(HRP, Character, distance)
    local frontParams = RaycastParams.new()
    frontParams.FilterType = Enum.RaycastFilterType.Exclude
    frontParams.FilterDescendantsInstances = {Character}
    
    return workspace:Raycast(HRP.Position, HRP.CFrame.LookVector * distance, frontParams)
end

function MovementController:DetectWallRunSurface(HRP, Character, distance)
    local sideParams = RaycastParams.new()
    sideParams.FilterType = Enum.RaycastFilterType.Exclude
    sideParams.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants()}

    local RUN_LEFT  = workspace:Raycast(HRP.Position, -HRP.CFrame.RightVector * distance, sideParams)
    local RUN_RIGHT = workspace:Raycast(HRP.Position,  HRP.CFrame.RightVector * distance, sideParams)

    if RUN_LEFT then
        return RUN_LEFT, "RUN_LEFT"
    elseif RUN_RIGHT then
        return RUN_RIGHT, "RUN_RIGHT"
    end
    
    return nil, nil
end

function MovementController:PerformWallRun(dt, HRP, Humanoid, fadeDuration, maxDescent, wallrunSpeed, sideName)
    if not self.Wallrunning then
        self.WallRunTime = 0
    else
        self.WallRunTime = self.WallRunTime + dt
    end
    
    if not self.Anim then
        self.Anim = Animation:Play(Modules.Animation.Assets.Animations.WALL[sideName].id, Humanoid, 1, Enum.AnimationPriority.Action4, "Wallrun")
    end

    self.Wallrunning = true
    Humanoid.AutoRotate = false

    local t = math.clamp((self.WallRunTime) / fadeDuration, 0, 1)
    local descentSpeed = maxDescent * t

    if self.WallRunBV then
        self.WallRunBV:Destroy()
    end

    self.WallRunBV = Instance.new("BodyVelocity")
    self.WallRunBV.MaxForce = Vector3.new(3e4, 3e4, 3e4)
    self.WallRunBV.Velocity = HRP.CFrame.LookVector * wallrunSpeed + Vector3.new(0, -descentSpeed, 0)
    self.WallRunBV.Parent = HRP
    
    self.WasWallrunning = true
end

function MovementController:StopWallRun(Humanoid)
    Animation:Stop(Humanoid, "Wallrun")
    self.Anim = nil
    self.Wallrunning = false
    self.WasWallrunning = false
    Humanoid.AutoRotate = true
    
    if self.WallRunBV then
        self.WallRunBV:Destroy()
        self.WallRunBV = nil
    end
end

return MovementController