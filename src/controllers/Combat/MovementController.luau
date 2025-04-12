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

    Animations = {} :: {[string]: AnimationTrack}
}

MovementController.Dependencies = {
    "Event"
}

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local StatusController = require(game.ReplicatedStorage.Controllers.Status.StatusController)
local Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)

--[[ State ]]
local Controllers
local Modules

--[[ Core Functions ]]
function MovementController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    
    local Player = Players.LocalPlayer
    Player.CharacterAdded:Connect(function(character)
        local Animator = character:WaitForChild("Humanoid"):FindFirstChildOfClass("Animator")
        if Animator then
            self.Animations = Animation.Categories(Animator, {"LOCOMOTION", "ROLL"})
        end
    end)
    
    if Player.Character then
        local Animator = Player.Character:FindFirstChild("Humanoid"):FindFirstChildOfClass("Animator")
        if Animator then
            self.Animations = Animation.Categories(Animator, {"LOCOMOTION", "ROLL"})
        end
    end
    
    return true
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

    if not StatusController:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running"}}) and Active == true then
        Humanoid.WalkSpeed = 32
        self.Animations["LOCOMOTION_SPRINT"].Priority = Enum.AnimationPriority.Action2
        self.Animations["LOCOMOTION_SPRINT"]:Play()
        Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Running", {Set = true})

    elseif Active ~= true then
        if StatusController:CheckSpecific(Humanoid, {Connection = true}, "Running") then
			self.Debounce = true
			task.delay(0.25, function()
				self.Debounce = false
			end)
		end	

        Humanoid.WalkSpeed = 16
        Animation.Stop(self.Animations, "LOCOMOTION", "SPRINT")
        Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Running", {Set = false})
    end
end

--[[ Dodging ]]

function MovementController:getVel(HRP)
	return Vector3.new(1, 0, 1) * HRP.Velocity
end

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

    Animation.Stop(self.Animations, "ROLL", "FORWARD")
    Animation.Stop(self.Animations, "ROLL", "BACK")
    Animation.Stop(self.Animations, "ROLL", "LEFT")
    Animation.Stop(self.Animations, "ROLL", "RIGHT")

    self.Animations["ROLL_CANCEL"].Priority = Enum.AnimationPriority.Action2
    self.Animations["ROLL_CANCEL"]:Play()
	
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
	if StatusController:CheckStatus(Humanoid, {Connection = true, Exclude = {"Running"}}) == true then return end
	
	local velocity = self:getVel(HRP)
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
    Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Dodging", {Set = true})
    Controllers.Event:FireServer("Velocity.Create", Character)

	local dashVelocity = Instance.new("BodyVelocity")
	dashVelocity.MaxForce = Vector3.new(30000, 0, 30000)
	dashVelocity.Parent = HRP
	Debris:AddItem(dashVelocity, 0.35)

	self.DashVelocity = dashVelocity
    local Dash = "ROLL_"..dashIdentity

    self.Animations[Dash].Priority = Enum.AnimationPriority.Action3
    self.Animations[Dash]:Play()

    -- Play sound
    -- Make Velocity Service

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
            Controllers.Event:FireServer("Status.Create", Humanoid, "Movement", "Dodging", {Set = false})
			self.Dodging = false
			self.DashIdentity = nil
		end)
		
		task.delay(1.5, function()
			self.Cooldown = false
		end)
	end
end

return MovementController