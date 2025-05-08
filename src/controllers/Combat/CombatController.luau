--[[ CombatController
    Core player combat (Local)
    @author @NantesF
    @version 1.0.5
    @date 2025-05-08
]]

local CombatController = {
    LockOnWanted = false :: boolean,
    isLockedOn = false :: boolean,
    currentTarget = nil,
    originalCameraType = nil,
    zoomFactor = 5 :: number,
    smoothnessValue = 0.05 :: number,
    shoulderTransition = 0 :: number,
    shoulderTransitionSpeed = 1 :: number,
    lastMovementDirection = Vector3.new(0, 0, 0) :: Vector3,
    shoulderOffset = 4 :: number,
    targetRange = 100 ::number,
    switchTargetCooldown = 0.5 :: number,
    lastSwitchTime = 0 :: number,
    lineOfSightLostTime = 0 :: number,
    lineOfSightGracePeriod = 1 :: number
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

function CombatController:SetUpGyro(HRP: BasePart)
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
    self.lineOfSightLostTime = 0
    local player = Players.LocalPlayer
    local char = player.Character

    UserInputService.MouseIconEnabled = true

    if self.LockOnIcon then
        self.LockOnIcon:Destroy()
        self.LockOnIcon = nil
        self.HighLight:Destroy()
        self.HighLight = nil
    end

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

function CombatController:GetCameraPositionWithCollision(playerPos: Vector3, targetPos: Vector3, cameraOffset: Vector3)
    local direction = (cameraOffset).Unit
    local distance = cameraOffset.Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
    
    local rayResult = workspace:Raycast(playerPos, direction * distance, raycastParams)
    
    if rayResult then
        local hitDistance = (rayResult.Position - playerPos).Magnitude - 0.5
        return playerPos + direction * math.min(distance, hitDistance)
    else
        return playerPos + cameraOffset
    end
end

function CombatController:LockOn(target: Model, dt)
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
    local heightOffset = Vector3.new(0, 5, 0)
    
    local totalOffset = backOffset + heightOffset + sideOffset
    
    local camPos = self:GetCameraPositionWithCollision(playerPos, targetPos, totalOffset)
    
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, targetPos), self.smoothnessValue)
    UserInputService.MouseIconEnabled = false

    if not self.LockOnIcon then
        self.LockOnIcon = game.ReplicatedStorage.Assets.Particles.LockOn:Clone()
        self.LockOnIcon.Parent = target.HumanoidRootPart
        self.HighLight = game.ReplicatedStorage.Assets.Particles.LockOnHighlight:Clone()
        self.HighLight.Parent = target
    end
end

function CombatController:HandleMouseWheel()
    UserInputService.InputChanged:Connect(function(input)
        if not self.isLockedOn then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.zoomFactor = math.clamp(self.zoomFactor - input.Position.Z,3,15)
        end
    end)
end

function CombatController:SetState()
    if self.LockOnWanted == true then
        self.LockOnWanted = false
    else
        self.LockOnWanted = true
    end
end

function CombatController:HasLineOfSight(origin, target)
    local direction = (target.Position - origin.Position)
    local distance = direction.Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character, target.Parent, workspace.Debris:GetDescendants(), workspace.Entities:GetDescendants()}
    
    local result = workspace:Raycast(origin.Position, direction, raycastParams)
    
    if not result then
        return true
    end
    
    if result and result.Distance > distance * 0.95 then
        return true
    end
    
    return false
end

function CombatController:GetValidTargets()
    local validTargets = {}
    
    if not workspace:FindFirstChild("Entities") then
        return validTargets
    end
    
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return validTargets end
    local HRP = char:FindFirstChild("HumanoidRootPart")
    if not HRP then return validTargets end
    
    local function processTarget(entity)
        if entity == char then return end
        
        local targetHRP = entity:FindFirstChild("HumanoidRootPart")
        local targetHum = entity:FindFirstChild("Humanoid")
        
        if targetHRP and targetHum then
            local distance = (HRP.Position - targetHRP.Position).Magnitude
            
            if distance <= self.targetRange then
                if self:HasLineOfSight(HRP, targetHRP) then
                    table.insert(validTargets, {
                        entity = entity,
                        distance = distance
                    })
                end
            end
        end
    end
    
    for _, entity in pairs(workspace.Entities:GetChildren()) do
        if entity:IsA("Model") then
            processTarget(entity)
        end
    end

    table.sort(validTargets, function(a, b)
        return a.distance < b.distance
    end)
    
    return validTargets
end

function CombatController:GetTargetsWithAngles()
    local validTargets = self:GetValidTargets()
    local targetsWithAngles = {}
    
    if #validTargets == 0 then
        return targetsWithAngles
    end
    
    local cameraLook = Camera.CFrame.LookVector
    local cameraRight = Camera.CFrame.RightVector
    local cameraPosition = Camera.CFrame.Position
    
    for _, targetInfo in ipairs(validTargets) do
        local targetHRP = targetInfo.entity:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            local dirToTarget = (targetHRP.Position - cameraPosition).Unit
            
            local rightDot = cameraRight:Dot(dirToTarget)
            
            table.insert(targetsWithAngles, {
                entity = targetInfo.entity,
                distance = targetInfo.distance,
                rightAngle = rightDot
            })
        end
    end
    
    return targetsWithAngles
end

function CombatController:SwitchTarget()
    if not self.isLockedOn or not self.LockOnWanted then
        return
    end
    
    local now = tick()
    if (now - self.lastSwitchTime) < self.switchTargetCooldown then
        return
    end
    
    local validTargets = self:GetValidTargets()
    if #validTargets <= 1 then
        return
    end
    
    local currentIndex = 1
    for i, targetInfo in ipairs(validTargets) do
        if targetInfo.entity == self.currentTarget then
            currentIndex = i
            break
        end
    end
    
    local newIndex = (currentIndex % #validTargets) + 1
    
    local newTarget = validTargets[newIndex].entity
    
    if newTarget then
        self.currentTarget = newTarget
        self.lastSwitchTime = now
        
        if self.LockOnIcon then
            self.LockOnIcon:Destroy()
            self.LockOnIcon = nil
            self.HighLight:Destroy()
            self.HighLight = nil
            
            self.LockOnIcon = game.ReplicatedStorage.Assets.Particles.LockOn:Clone()
            self.LockOnIcon.Parent = newTarget.HumanoidRootPart
            self.HighLight = game.ReplicatedStorage.Assets.Particles.LockOnHighlight:Clone()
            self.HighLight.Parent = newTarget
        end
    end
end

function CombatController:GetTargetEntity()
    local validTargets = self:GetValidTargets()
    
    if #validTargets == 0 then
        return nil
    end
    
    if not self.currentTarget then
        return validTargets[1].entity
    end
    
    for i, targetInfo in ipairs(validTargets) do
        if targetInfo.entity == self.currentTarget then
            return self.currentTarget
        end
    end
    
    return validTargets[1].entity
end

function CombatController:MonitorTargets()
    RunService.Heartbeat:Connect(function(dt)
        if not self.isLockedOn or not self.LockOnWanted then return end
        
        local player = Players.LocalPlayer
        local char = player.Character
        if not char then return end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        if not HRP then return end
        
        local targetLost = false
        
        if not self.currentTarget or 
           not self.currentTarget:FindFirstChild("HumanoidRootPart") or
           (self.currentTarget.HumanoidRootPart.Position - HRP.Position).Magnitude > self.targetRange then
            targetLost = true
        else
            if not self:HasLineOfSight(HRP, self.currentTarget.HumanoidRootPart) then
                if self.lineOfSightLostTime == 0 then
                    self.lineOfSightLostTime = tick()
                elseif (tick() - self.lineOfSightLostTime) > self.lineOfSightGracePeriod then
                    targetLost = true
                end
            else
                self.lineOfSightLostTime = 0
            end
        end
        
        if targetLost then
            local validTargets = self:GetValidTargets()
            if #validTargets > 0 then
                local closestTarget = validTargets[1].entity
                
                if closestTarget and closestTarget ~= self.currentTarget then
                    self.currentTarget = closestTarget
                    self.lastSwitchTime = tick()
                    self.lineOfSightLostTime = 0

                    if self.LockOnIcon then
                        self.LockOnIcon:Destroy()
                        self.LockOnIcon = nil
                        self.HighLight:Destroy()
                        self.HighLight = nil
                        
                        self.LockOnIcon = game.ReplicatedStorage.Assets.Particles.LockOn:Clone()
                        self.LockOnIcon.Parent = closestTarget.HumanoidRootPart
                        self.HighLight = game.ReplicatedStorage.Assets.Particles.LockOnHighlight:Clone()
                        self.HighLight.Parent = closestTarget
                    end
                end
            else
                self:StopLockOn()
            end
        end
    end)
end

function CombatController:Start()
    local player = Players.LocalPlayer
    repeat task.wait() until player.Character and player.Character.Parent
    
    self:HandleMouseWheel()
    self:MonitorTargets()

    RunService.RenderStepped:Connect(function(dt)
        local char = player.Character
        if not char then return end
        local Hum = char:FindFirstChild("Humanoid")
        if not Hum then return end
        local equipped = Controllers.Status:CheckSpecific(Hum,{Connection=true},"Equipped")
        
        if equipped and self.LockOnWanted then
            local tgt = self.currentTarget or self:GetTargetEntity()
            
            if not tgt then
                if self.isLockedOn then
                    self:StopLockOn()
                end
                return
            end
            
            self.currentTarget = tgt
            self:LockOn(tgt, dt)
        elseif self.isLockedOn then
            self:StopLockOn()
        end
    end)
end

return CombatController