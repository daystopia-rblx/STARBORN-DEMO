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
local Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)

--[[ State ]]
local Controllers
local Modules

--[[ Core Functions ]]
function MovementController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
	self:Footsteps()
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
		Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Footsteps[Floor][Sound].id, parent = Character[stepEvent], duration = 2, volume = 0.15})
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
		Animation:Play(Modules.Animation.Assets.Animations.LOCOMOTION.SPRINT.id, Humanoid, 1, Enum.AnimationPriority.Action, "Run")
        Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Running", {Set = true})

    elseif Active ~= true then
        if Controllers.Status:CheckSpecific(Humanoid, {Connection = true}, "Running") then
			self.Debounce = true
			task.delay(0.25, function()
				self.Debounce = false
			end)
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
	Animation:Play(Modules.Animation.Assets.Animations.ROLL.CANCEL.id, Humanoid, 1, Enum.AnimationPriority.Action3, "DodgeCancel")

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
	dashVelocity.MaxForce = Vector3.new(30000, 0, 30000)
	dashVelocity.Parent = HRP
	Debris:AddItem(dashVelocity, 0.35)

	self.DashVelocity = dashVelocity

	Animation:Play(Modules.Animation.Assets.Animations.ROLL[dashIdentity].id, Humanoid, 1.25, Enum.AnimationPriority.Action4, "Dodge")

	local Dodge = "Dodge_"..tostring(math.random(1,3))
	Controllers.Event:FireServer("Particle.Create", {effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[Dodge].id, parent = HRP, duration = 2, volume = 0.35})

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
			dashVelocity.Velocity = dashDirection * ((60 * Inverse))
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

--[[ Vaulting ]]
function MovementController:StartVault()
	local Player = game.Players.LocalPlayer
	local Character = Player.Character
	local Humanoid = Character.Humanoid
	local HRP = Character.HumanoidRootPart

	local Params = RaycastParams.new()
	Params.RespectCanCollide = true
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character, workspace.Entities:GetDescendants(), }

	if Humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	local VaultCastHead = workspace:Raycast(Character.Head.CFrame.Position + Vector3.new(0, -0.5, -0.5), HRP.CFrame.LookVector * 5, Params)
	local VaultCast = workspace:Raycast(HRP.CFrame.Position + Vector3.new(0, -0.5, 0), HRP.CFrame.LookVector * 4, Params)

	if VaultCastHead then
		return
	end

	if not VaultCast or not VaultCast.Instance or VaultCast.Instance.Transparency == 1 or VaultCast.Instance:IsDescendantOf(workspace.Entities) or VaultCast.Instance:IsDescendantOf(workspace.Debris) then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		return
	end

	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	VaultCast.Instance.CanCollide = false -- Might not do this

	Animation:Play(Modules.Animation.Assets.Animations.SPECIAL.VAULT.id, Humanoid, 1.5, Enum.AnimationPriority.Action2, "Vault")
	Controllers.Event:FireServer("Particle.Create", {effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Vault.Attachment, parent = HRP})

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	bodyVelocity.Velocity = HRP.CFrame.LookVector * 45
	bodyVelocity.P = 5000
	bodyVelocity.Parent = HRP
	Debris:AddItem(bodyVelocity, 0.2)

	task.delay(0.2, function()
		VaultCast.Instance.CanCollide = true
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end)
end

return MovementController