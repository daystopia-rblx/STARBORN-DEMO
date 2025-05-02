--[[ CombatController
    Core player combat (Local)
    @author @NantesF
    @version 1.0.2
    @date 2025-04-30
]]

local CombatController = {
    isLockedOn = false,
    currentTarget = nil,
    originalCameraType = nil,
    zoomFactor = 5,
    smoothnessValue = 0.05,
    shoulderTransition = 0,
    shoulderTransitionSpeed = 1,
    lastMovementDirection = Vector3.new(0, 0, 0),
    shoulderOffset = 4
}

CombatController.Dependencies = {
    "Event",
    "Status",
}

CombatController.Modules = {
    "Animation",
    "Sound"
}

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = game.Workspace.CurrentCamera
local Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)

--[[ State ]]
local Controllers
local Modules

--[[ Core Functions ]]
function CombatController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    self:Start()
    return true
end

function CombatController:SetUpGyro(HRP)
    if self.Gyro then self.Gyro:Destroy() end
    self.Gyro = Instance.new("BodyGyro")
    self.Gyro.MaxTorque = Vector3.new(0,1,0) * 1e6
    self.Gyro.D = 100
    self.Gyro.P = 10000
    self.Gyro.Parent = HRP
end

function CombatController:StopLockOn()
    if self.Gyro then self.Gyro:Destroy(); self.Gyro = nil end
    if self.originalCameraType then Camera.CameraType = self.originalCameraType end

    self.isLockedOn = false
    self.currentTarget = nil
    self.shoulderTransition = 0
    local player = Players.LocalPlayer
    local char = player.Character

    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.CameraOffset = Vector3.new(0,0,0)
    end
end

function CombatController:DetermineShoulderTransition(HRP, dt)
    local vel = HRP.Velocity
    local move = Vector3.new(vel.X,0,vel.Z)

    if move.Magnitude > 0.5 then
        local camRight = Camera.CFrame.RightVector
        local dot = camRight:Dot(move.Unit)
        local targetVal = self.shoulderTransition
        if dot > 0.3 then
            targetVal = 1
        elseif dot < -0.3 then
            targetVal = -1
        end

        local t = math.clamp(self.shoulderTransitionSpeed * dt, 0, 1)
        self.shoulderTransition = self.shoulderTransition + (targetVal - self.shoulderTransition) * t
    end
end

function CombatController:LockOn(target, dt)
    if not target then self:StopLockOn(); return end
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return end
    local HRP = char:FindFirstChild("HumanoidRootPart")
    local Hum = char:FindFirstChild("Humanoid")
    if not HRP or not Hum then return end

    if not self.isLockedOn then
        self.originalCameraType = Camera.CameraType
        Camera.CameraType = Enum.CameraType.Scriptable
        self.isLockedOn = true
        self.currentTarget = target
    end

    self:SetUpGyro(HRP)
    self.Gyro.CFrame = CFrame.new(HRP.Position, target.HumanoidRootPart.Position)

    self:DetermineShoulderTransition(HRP, dt)

    local targetPos = target.HumanoidRootPart.Position
    local playerPos = HRP.Position
    local dir = (playerPos - targetPos).Unit
    local right = Vector3.new(0,1,0):Cross(dir).Unit
    local backOffset = dir * self.zoomFactor
    local sideOffset = right * self.shoulderOffset * self.shoulderTransition

    local camPos = playerPos + backOffset + Vector3.new(0 , 5, 0) + sideOffset
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, targetPos), self.smoothnessValue)
end

function CombatController:HandleMouseWheel()
    UserInputService.InputChanged:Connect(function(input)
        if not self.isLockedOn then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.zoomFactor = math.clamp(self.zoomFactor - input.Position.Z,3,15)
        end
    end)
end

function CombatController:Start()
    local player = Players.LocalPlayer
    repeat task.wait() until player.Character and player.Character.Parent
    self:HandleMouseWheel()

    RunService.RenderStepped:Connect(function(dt)
        local char = player.Character
        if not char then return end
        local Hum = char:FindFirstChild("Humanoid")
        if not Hum then return end
        local equipped = Controllers.Status:CheckSpecific(Hum,{Connection=true},"Equipped")
        if equipped then
            local tgt = workspace.Entities.Attack
            self:LockOn(tgt, dt)
        elseif self.isLockedOn then
            self:StopLockOn()
        end
    end)
end

return CombatController
