--[[ MovementModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local MovementModule = {}

--[[ Dependencies ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[[ Constants ]]
MovementModule.Constants = {
    DASH = {
        SPEED = 50,
        PARTICLE_DURATION = 5,
        PARTICLE_EMIT_COUNT = 23
    }
}

--[[ Types ]]
type DashDirection = "forward" | "backward" | "left" | "right" | "forward_left" | "forward_right" | "backward_left" | "backward_right"

--[[ Visual Handlers ]]
MovementModule.Visuals = {
    Dash = function(character: Model, direction: DashDirection)
        local rootPart = character.PrimaryPart
        if not rootPart then return end

        local dashParticle = ReplicatedStorage.Assets.Particles:FindFirstChild("Dash")
        if not dashParticle then
            warn("Dash particle effect not found")
            return
        end

        local particle = dashParticle:Clone()
        particle.Parent = workspace

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}

        local connection = RunService.RenderStepped:Connect(function()
            local raycast = workspace:Raycast(rootPart.Position, Vector3.new(0, -4, 0), params)
            if raycast and raycast.Position then
                particle.Position = raycast.Position + Vector3.new(0, 0.8, 0)
                particle.Rotation = Vector3.new(0, rootPart.Rotation.Y, 0)
            end
        end)

        task.delay(0.2, function()
            particle.normal.Rate = 0
            local dirParticle = particle:FindFirstChild("impulse_"..direction:sub(1, 1))
            if dirParticle then
                dirParticle:Emit(MovementModule.Constants.DASH.PARTICLE_EMIT_COUNT)
            end
        end)

        task.delay(MovementModule.Constants.DASH.PARTICLE_DURATION, function()
            connection:Disconnect()
            particle:Destroy()
        end)
    end
}

--[[ Handlers ]]
MovementModule.Handlers = {
    Dash = {
        Execute = function(self, character: Model, data: {direction: string})
            local rootPart = character.PrimaryPart
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot dash while ragdolled"
            end

            if not rootPart then
                return nil, "Invalid character or missing primary part"
            end

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
            bodyVelocity.Parent = rootPart
            bodyVelocity.Name = "dash_force"

            local dashVector = Vector3.zero
            if data.direction == "forward" then
                dashVector = rootPart.CFrame.LookVector
            elseif data.direction == "backward" then
                dashVector = -rootPart.CFrame.LookVector
            elseif data.direction == "left" then
                dashVector = -rootPart.CFrame.RightVector
            elseif data.direction == "right" then
                dashVector = rootPart.CFrame.RightVector
            else
                dashVector = rootPart.CFrame.LookVector
            end

            if RunService:IsClient() then
                MovementModule.Visuals.Dash(character, data.direction)
            end

            bodyVelocity.Velocity = dashVector * MovementModule.Constants.DASH.SPEED

            local connection
            if RunService:IsClient() then
                connection = RunService.RenderStepped:Connect(function()
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity.Velocity = dashVector * MovementModule.Constants.DASH.SPEED
                    end
                end)
            end

            local cleanupTask = task.delay(0.3, function()
                if connection then
                    connection:Disconnect()
                end
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity:Destroy()
                end
            end)

            return {
                cleanup = function()
                    if cleanupTask then
                        task.cancel(cleanupTask)
                    end
                    if connection then
                        connection:Disconnect()
                    end
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                    end
                end
            }
        end
    },
    Run = {
        Execute = function(self, character: Model, enabled: boolean)
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot run while ragdolled"
            end

            if not character then
                return nil, "Invalid character"
            end

            if enabled then
                humanoid.WalkSpeed = 26
            else
                humanoid.WalkSpeed = 16
            end

            return {
                cleanup = function()
                    humanoid.WalkSpeed = 16
                end
            }
        end
    },
    Walk = {
        Execute = function(self, character: Model, enabled: boolean)
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot walk while ragdolled"
            end

            if not character then
                return nil, "Invalid character"
            end

            humanoid.WalkSpeed = 16

            return {
                cleanup = function()
                    humanoid.WalkSpeed = 16
                end
            }
        end
    },
    Idle = {
        Execute = function(self, character: Model, enabled: boolean)
            local humanoid = character:FindFirstChild("Humanoid")

            if not character then
                return nil, "Invalid character"
            end

            return {
                cleanup = function()
                end
            }
        end
    },
    Roll = {
        Execute = function(self, character: Model)
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid.FloorMaterial == Enum.Material.Air then
                return nil, "Cannot roll in the air"
            end

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot roll while ragdolled"
            end

            if not character or not character.PrimaryPart then
                return nil, "Invalid character or missing primary part"
            end

            local rootPart = character.PrimaryPart
            if not rootPart then return end

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.Velocity = rootPart.CFrame.LookVector * 30
            bodyVelocity.Parent = rootPart
            bodyVelocity.Name = "roll_force"

            local cleanupTask = task.delay(0.8, function()
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity:Destroy()
                end
            end)

            return {
                cleanup = function()
                    if cleanupTask then
                        task.cancel(cleanupTask)
                    end
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                    end
                end
            }
        end
    },
    Jump = {
        Execute = function(self, character: Model)
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot jump while ragdolled"
            end

            if not character then
                return nil, "Invalid character"
            end

            if humanoid.FloorMaterial == Enum.Material.Air then
                return nil, "Already in the air"
            end

            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

            return {
                cleanup = function()
                end
            }
        end
    },
    Land = {
        Execute = function(self, character: Model, data: {[string]: any}?)
            local humanoid = character:FindFirstChild("Humanoid")

            if not character then
                return nil, "Invalid character"
            end

            local impactStrength = data and data.impact or 0

            if impactStrength > 0.7 then
                if humanoid then
                    humanoid.Health = humanoid.Health - (impactStrength * 10)
                end

                return {
                    cleanup = function()
                    end
                }
            elseif impactStrength > 0.3 then
                return {
                    cleanup = function()
                    end
                }
            else
                return {
                    cleanup = function()
                    end
                }
            end
        end
    },
    Crouch = {
        Execute = function(self, character, data)
            -- Crouch implementation
        end
    },
    Slide = {
        Execute = function(self, character: Model)
            local humanoid = character:FindFirstChild("Humanoid")

            if humanoid.FloorMaterial == Enum.Material.Air then
                return nil, "Cannot slide in the air"
            end

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot slide while ragdolled"
            end

            if not character or not character.PrimaryPart then
                return nil, "Invalid character or missing primary part"
            end

            local rootPart = character.PrimaryPart
            if not rootPart then return end

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.Velocity = rootPart.CFrame.LookVector * 55
            bodyVelocity.Parent = rootPart
            bodyVelocity.Name = "slide_force"

            return {
                cleanup = function()
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                    end
                end
            }
        end
    },
    WallRun = {
        Execute = function(self, character, data)
            -- Wall run implementation
        end
    },
    WallClimb = {
        Execute = function(self, character, data)
            -- Wall climb implementation
        end
    },
    Swing = {
        Execute = function(self, character: Model)
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character.PrimaryPart

            if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                return nil, "Cannot swing while ragdolled"
            end

            local rope = Instance.new("RopeConstraint")
            rope.Length = 10
            rope.Thickness = 0.2
            rope.Attachment0 = rootPart:FindFirstChild("SwingAttachment") or Instance.new("Attachment", rootPart)
            rope.Attachment1 = workspace.SwingPoints:FindFirstChild("NearestSwingPoint")
            rope.Parent = character

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
            bodyVelocity.Velocity = rootPart.CFrame.LookVector * 15
            bodyVelocity.Parent = rootPart

            return {
                cleanup = function()
                    rope:Destroy()
                    bodyVelocity:Destroy()
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            }
        end
    },
    Hang = {
        Execute = function(self, character: Model)
            local rootPart = character.PrimaryPart
            if not rootPart then return end

            rootPart.Anchored = true
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.AutoRotate = false
                humanoid:ChangeState(Enum.HumanoidStateType.Seated)
            end

            return {
                cleanup = function()
                    if rootPart then
                        rootPart.Anchored = false
                    end
                    if humanoid then
                        humanoid.AutoRotate = true
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            }
        end
    },
    Carry = {
        Execute = function(self, character: Model, target: Model)
            local humanoid = character:FindFirstChild("Humanoid")
            local targetHumanoid = target:FindFirstChild("Humanoid")

            if not humanoid or not targetHumanoid then return end

            local weld = Instance.new("Weld")
            weld.Part0 = character.PrimaryPart
            weld.Part1 = target.PrimaryPart
            weld.C0 = CFrame.new(0, 0, -2)
            weld.Parent = target
            target:SetAttribute("Carried", true)

            return {
                cleanup = function()
                    weld:Destroy()
                    target:SetAttribute("Carried", false)
                end
            }
        end
    },
    Grip = {
        Execute = function(self, character: Model, target: Model)
            local humanoid = character:FindFirstChild("Humanoid")
            local targetHumanoid = target:FindFirstChild("Humanoid")

            if not humanoid or not targetHumanoid then return end

            target:SetAttribute("GRIPPED", true)

            return {
                cleanup = function()
                    target:SetAttribute("GRIPPED", false)
                end
            }
        end
    },
    Climb = {
        Execute = function(self, character: Model)
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character.PrimaryPart
            if not humanoid or not rootPart then return end

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
            bodyVelocity.Velocity = Vector3.zero
            bodyVelocity.Parent = rootPart
            bodyVelocity.Name = "climb_force"

            humanoid.AutoRotate = false

            return {
                cleanup = function()
                    if bodyVelocity then
                        bodyVelocity:Destroy()
                    end
                    humanoid.AutoRotate = true
                end
            }
        end
    },
    Vault = {
        Execute = function(self, character: Model)
            local rootPart = character.PrimaryPart
            local humanoid = character:FindFirstChild("Humanoid")
            if not rootPart or not humanoid then return end

            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.RespectCanCollide = true

            local frontCheck = workspace:Raycast(
                rootPart.Position + Vector3.new(0, 0.5, 0),
                rootPart.CFrame.LookVector * 2.5,
                raycastParams
            )

            if not frontCheck then return end

            local obstacle = frontCheck.Instance
            local obstacleSize = obstacle.Size
            local obstaclePos = obstacle.Position

            local landingPos = Vector3.new(
                obstaclePos.X,
                obstaclePos.Y + (obstacleSize.Y/2) + 3,
                obstaclePos.Z
            )

            landingPos = landingPos + (rootPart.CFrame.LookVector * (obstacleSize.Z/2 + 1))

            local startPos = rootPart.Position
            local startRot = rootPart.CFrame.Rotation

            rootPart.Anchored = true

            local startTime = os.clock()
            local duration = 0.3

            local connection
            if RunService:IsClient() then
                connection = RunService.RenderStepped:Connect(function()
                    local alpha = math.min((os.clock() - startTime) / duration, 1)
                    if alpha < 1 then
                        local progress = math.sin(alpha * math.pi/2)
                        local newPos = startPos:Lerp(landingPos, progress)
                        local arcHeight = math.sin(progress * math.pi) * 1
                        newPos = newPos + Vector3.new(0, arcHeight, 0)
                        rootPart.CFrame = CFrame.new(newPos) * startRot
                    end
                end)
            end

            local cleanupTask = task.delay(duration, function()
                if connection then
                    connection:Disconnect()
                end
                rootPart.Anchored = false
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end)

            return {
                cleanup = function()
                    if cleanupTask then
                        task.cancel(cleanupTask)
                    end
                    if connection then
                        connection:Disconnect()
                    end
                    rootPart.Anchored = false
                    humanoid.WalkSpeed = 16
                    humanoid.JumpPower = 50
                end
            }
        end
    },
    Ragdoll = {
        Execute = function(self, character: Model, enabled: boolean)
            if not character then
                return nil, "Invalid character"
            end

            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then
                return nil, "No humanoid found"
            end

            if enabled and humanoid:GetState() == Enum.HumanoidStateType.Dead then
                return nil, "Cannot ragdoll when dead"
            end

            if enabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                if torso then
                    torso:ApplyImpulse(torso.CFrame.LookVector * 75)
                end
            else
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end

            return {
                cleanup = function()
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            }
        end
    }
}

return MovementModule