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
        Execute = function(self, character: Model, data: {direction: string}?)
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

            local rollDirection = rootPart.CFrame.LookVector
            if data and data.direction then
                if data.direction == "backward" then
                    rollDirection = -rootPart.CFrame.LookVector
                elseif data.direction == "left" then
                    rollDirection = -rootPart.CFrame.RightVector
                elseif data.direction == "right" then
                    rollDirection = rootPart.CFrame.RightVector
                end
            end

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.Velocity = rollDirection * 30
            bodyVelocity.Parent = rootPart
            bodyVelocity.Name = "roll_force"

            local cleanupTask = task.delay(0.6, function()
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
            bodyVelocity.Velocity = rootPart.CFrame.LookVector * 30
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
        Execute = function(self, character: Model, data)
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character.PrimaryPart
            if not humanoid or not rootPart then return end

            humanoid.WalkSpeed = 0

            local moveDirection = Vector3.zero
            if data and data.direction then
                if data.direction == "up" then
                    moveDirection = Vector3.new(0, 1, 0)
                elseif data.direction == "down" then
                    moveDirection = Vector3.new(0, -1, 0)
                elseif data.direction == "left" then
                    moveDirection = -rootPart.CFrame.RightVector
                elseif data.direction == "right" then
                    moveDirection = rootPart.CFrame.RightVector
                end
            end

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
            bodyVelocity.Velocity = moveDirection * 16
            bodyVelocity.Parent = rootPart
            bodyVelocity.Name = "climb_force"

            humanoid.AutoRotate = false

            return {
                cleanup = function()
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity:Destroy()
                    end
                    humanoid.AutoRotate = true
                    humanoid.WalkSpeed = 16
                end
            }
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
            if not rootPart or not humanoid then
                return nil, "Missing rootPart or humanoid"
            end

            humanoid:Move(Vector3.zero)
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0

            local cleanupTask = task.delay(0.3, function()
                if humanoid then
                    humanoid.WalkSpeed = 16
                    humanoid.JumpPower = 50
                    humanoid:Move(Vector3.zero)
                end
            end)

            return {
                cleanup = function()
                    if cleanupTask then
                        task.cancel(cleanupTask)
                    end
                    if humanoid then
                        humanoid.WalkSpeed = 16
                        humanoid.JumpPower = 50
                        humanoid:Move(Vector3.zero)
                    end
                end
            }
        end
    },
    Ragdoll = {
        Execute = function(self, character: Model, enabled: boolean, data: {type: string?}?)
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

            local attachmentCFrames = {
                ["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
                ["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
                ["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
                ["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
                ["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
            }

            local ragdollInstanceNames = {
                ["RagdollAttachment"] = true,
                ["RagdollConstraint"] = true,
                ["ColliderPart"] = true,
            }

            if enabled then
                character:SetAttribute("RAGDOLL", true)
                character:SetAttribute("RAGDOLL_TYPE", data and data.type or "explode")

                humanoid.AutoRotate = false

                local function createColliderPart(part: BasePart)
                    if not part then return end
                    local rp = Instance.new("Part")
                    rp.Name = "ColliderPart"
                    rp.Size = part.Size/1.7
                    rp.Massless = true
                    rp.CFrame = part.CFrame
                    rp.Transparency = 1

                    local wc = Instance.new("WeldConstraint")
                    wc.Part0 = rp
                    wc.Part1 = part

                    wc.Parent = rp
                    rp.Parent = part
                end

                for _, motor: Motor6D in pairs(character:GetDescendants()) do
                    if motor:IsA("Motor6D") then
                        if not attachmentCFrames[motor.Name] then continue end
                        motor.Enabled = false

                        local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
                        a0.CFrame = attachmentCFrames[motor.Name][1]
                        a1.CFrame = attachmentCFrames[motor.Name][2]

                        a0.Name = "RagdollAttachment"
                        a1.Name = "RagdollAttachment"

                        createColliderPart(motor.Part1)

                        local b = Instance.new("BallSocketConstraint")
                        b.Attachment0 = a0
                        b.Attachment1 = a1
                        b.Name = "RagdollConstraint"
                        
                        b.Radius = 0.15
                        b.LimitsEnabled = true
                        b.TwistLimitsEnabled = false
                        b.MaxFrictionTorque = 0
                        b.Restitution = 0
                        b.UpperAngle = 90
                        b.TwistLowerAngle = -45
                        b.TwistUpperAngle = 45

                        if motor.Name == "Neck" then
                            b.TwistLimitsEnabled = true
                            b.UpperAngle = 45
                            b.TwistLowerAngle = -70
                            b.TwistUpperAngle = 70
                        end

                        a0.Parent = motor.Part0
                        a1.Parent = motor.Part1
                        b.Parent = motor.Parent
                    end
                end

                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                if torso then
                    local randomDirection = Vector3.new(
                        math.random(-1, 1),
                        math.random(0, 0.5),
                        math.random(-1, 1)
                    ).Unit
                    torso:ApplyImpulse(randomDirection * 25)
                end
            else
                character:SetAttribute("RAGDOLL", false)
                character:SetAttribute("RAGDOLL_TYPE", nil)

                humanoid.AutoRotate = true

                for _, instance in pairs(character:GetDescendants()) do
                    if ragdollInstanceNames[instance.Name] then
                        instance:Destroy()
                    end

                    if instance:IsA("Motor6D") then
                        instance.Enabled = true
                    end
                end
            end

            return {
                cleanup = function()
                    character:SetAttribute("RAGDOLL", false)
                    character:SetAttribute("RAGDOLL_TYPE", nil)

                    humanoid.AutoRotate = true

                    for _, instance in pairs(character:GetDescendants()) do
                        if ragdollInstanceNames[instance.Name] then
                            instance:Destroy()
                        end

                        if instance:IsA("Motor6D") then
                            instance.Enabled = true
                        end
                    end
                end
            }
        end
    },
    Sit = {
        Execute = function(self, character: Model, enabled: boolean)
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return nil, "No humanoid found" end

            if enabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Seated)
            else
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end

            return {
                cleanup = function()
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            }
        end
    }
}

return MovementModule