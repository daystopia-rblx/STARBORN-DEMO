--[[ MovementClient
    @author @Daystopia
    @version 1.1.2
    @date 2025-04-02
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Modules = {
    Animation = require(ReplicatedStorage.Modules.AnimationModule),
    Movement = require(ReplicatedStorage.Modules.MovementModule),
    State = require(ReplicatedStorage.Modules.StateModule),
    Stat = require(ReplicatedStorage.Modules.StatModule),
}

local Tools = {
    Spring = require(ReplicatedStorage.Modules.Tool.Spring)
}

local Utility = {
    Sound = require(script.Parent.Utility.Sound),
    Controller = require(script.Parent.Utility.Controller),
    Animation = require(script.Parent.Utility.Animation),
    Camera = require(script.Parent.Utility.Camera),
    Particle = require(script.Parent.Utility.Particle)
}

--[[ Types ]]
type CameraState = {
    lastUpdate: number,
    isLocked: boolean,
    isShiftLocked: boolean,
    shiftLockOffset: Vector3,
    previousCameraType: Enum.CameraType?
}

--[[ Constants ]]
local CONTROL_BINDINGS = {
    {action = "Jump", key = Enum.KeyCode.Space, description = "Jump"},
    {action = "Run", key = Enum.KeyCode.W, description = "Run", doubleTap = true},
    {action = "Roll", key = Enum.KeyCode.Q, description = "Roll"},
    {action = "Crouch", key = Enum.KeyCode.C, description = "Crouch"},
    {action = "Slide", key = Enum.KeyCode.LeftControl, description = "Slide"},
    {action = "Emotes", key = Enum.KeyCode.T, description = "Emotes"},
    {action = "Ragdoll", key = Enum.KeyCode.R, description = "Ragdoll"}
}

local CAMERA_SETTINGS = {
    FOV = Modules.Stat.Constants.MOVEMENT.WALK_CAMERA_FOV,
    ZOOM = 10,
    TRANSITION_TIME = 0.3,
    MOTION_BLUR = {
        ENABLED = Modules.Stat.Constants.MOVEMENT.SPRINT_CAMERA_MOTION_BLUR,
        INTENSITY = Modules.Stat.Constants.MOVEMENT.SPRINT_CAMERA_MOTION_BLUR_AMOUNT,
        SMOOTHING = 0.5
    },
    RUN_FOV = Modules.Stat.Constants.MOVEMENT.SPRINT_CAMERA_FOV
}

local UI_SETTINGS = {
    EMOTE_MENU = {
        FADE_DURATION = 0.3,
        DISPLAY_ORDER = 999998
    }
}

local DEBOUNCE_TIMES = {
    crouch = Modules.Stat.Constants.MOVEMENT.CROUCH_SMOOTH_TIME,
    dash = Modules.Stat.Constants.MOVEMENT.ROLL_DURATION_Z,
    roll = Modules.Stat.Constants.MOVEMENT.ROLL_COOLDOWN_Z,
    slide = Modules.Stat.Constants.MOVEMENT.SLIDE_COOLDOWN,
    vault = Modules.Stat.Constants.MOVEMENT.WALL_CLIMB_LEDGE_DURATION
}

local CURSOR_CONFIG = {
    ENABLED = true,
    DEFAULT_CURSOR = "",
    OVERRIDE_DEFAULT = true
}

local SHIFT_LOCK_CONFIG = {
    CHARACTER_SMOOTH_ROTATION = true,
    CHARACTER_ROTATION_SPEED = 3,
    CAMERA_TRANSITION_IN_SPEED = 10,
    CAMERA_TRANSITION_OUT_SPEED = 14,
    LOCKED_CAMERA_OFFSET = Vector3.new(1.75, 0.25, 0),
    LOCKED_MOUSE_ICON = "http://www.roblox.com/asset/?id=7347416154",
    TRANSITION_SPRING_DAMPER = 0.7
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local EmoteGui = PlayerGui:WaitForChild("EmoteGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Animations = {}

EmoteGui.DisplayOrder = UI_SETTINGS.EMOTE_MENU.DISPLAY_ORDER
EmoteGui:WaitForChild("Background").Visible = false
EmoteGui:WaitForChild("Background").ImageTransparency = 1

--[[ State ]]
local State = {
    camera = {
        lastUpdate = 0,
        isLocked = false,
        isShiftLocked = false,
        shiftLockOffset = Vector3.new(0, 0, 0),
        previousCameraType = nil,
        shiftLockConnection = nil,
        camOffsetSpring = Tools.Spring.new(Vector3.new(0, 0, 0)),
        lastLookVector = Vector3.new(0, 0, 0),
        motionBlurEffect = nil
    },
    ui = {
        emoteMenu = {
            enabled = false,
            frame = EmoteGui:WaitForChild("Background"),
            scrollFrame = EmoteGui:WaitForChild("Background"):WaitForChild("ScrollingFrame"),
            isOpen = false
        }
    },
    movement = {
        currentDirection = "forward",
        isRunning = false,
        isWalking = false,
        isJumping = false,
        isCrouching = false,
        isCrouchWalking = false,
        isSliding = false,
        isWallRunning = false,
        isWallClimbing = false,
        isSwinging = false,
        isVaulting = false,
        isRolling = false,
        isSwimming = false,
        isUnderwater = false,
        isFalling = false,
        isStunned = false,
        isDashing = false,
        isLedgeHolding = false,
        isClimbing = false,
        isSitting = false,
        isRagdoll = false,
        ragdollStartTime = 0,
        ragdollDuration = 0,
        lastVerticalVelocity = 0,
        maxSafeVelocity = -20,
        lastGroundedTime = 0,
        lastWTap = 0,
        debounce = {
            crouch = 0,
            dash = 0,
            roll = 0,
            slide = 0,
            vault = 0
        },
        effects = {
            run = nil,
            runCleanup = nil,
            slide = nil,
            slideCleanup = nil,
            speedTrails = {},
            speedTrailsCleanup = {}
        }
    }
}

--[[ Animation Functions ]]
local function PlayAnimation(category: string, name: string?)
    Utility.Animation.Play(Animations, category, name, Modules.Animation.Assets.Animations)
end

local function StopAnimation(category: string, name: string?)
    Utility.Animation.Stop(Animations, category, name, Modules.Animation.Assets.Animations)
end

local function InitializeAnimations()
    local categories = {
        "LOCOMOTION",
        "ROLL",
        "SPECIAL",
        "LANDING",
        "WALL",
        "LEDGE",
        "STATUS",
        "CARRY",
        "COMBAT",
        "EMOTES"
    }

    Animations = Utility.Animation.Categories(Animator, categories, Modules.Animation.Assets.Animations)
end

--[[ Ragdoll Functions ]]
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

local mainParts = {
    "Torso", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    "Head"
}

local function createColliderPart(part: BasePart)
    if not part then return end
    local rp = Instance.new("Part")
    rp.Name = "ColliderPart"
    rp.Size = part.Size/1.7
    rp.Massless = true
    rp.CFrame = part.CFrame
    rp.Transparency = 1
    rp.Anchored = false
    rp.CanCollide = true

    local wc = Instance.new("WeldConstraint")
    wc.Part0 = rp
    wc.Part1 = part

    wc.Parent = rp
    rp.Parent = part
end

local function SetupRagdoll(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = false
    humanoid.AutoRotate = false

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if table.find(mainParts, part.Name) then
                part.Anchored = false
                part.CanCollide = true
            else
                part.CanCollide = false
            end
        end
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

            if table.find(mainParts, motor.Part1.Name) then
                createColliderPart(motor.Part1)
            end

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
        torso:ApplyImpulse(torso.CFrame.LookVector * 100)
    end

    humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
end

local function RecoverRagdoll(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    for _, instance in pairs(character:GetDescendants()) do
        if ragdollInstanceNames[instance.Name] then
            instance:Destroy()
        end

        if instance:IsA("Motor6D") then
            instance.Enabled = true
        end
    end

    humanoid.AutoRotate = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

local function CancelRagdoll(character)
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    State.movement.isRagdoll = false
    State.movement.ragdollStartTime = 0
    State.movement.ragdollDuration = 0
    character:SetAttribute("RAGDOLL", false)

    RecoverRagdoll(character)

    humanoid.AutoRotate = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

    PlayAnimation("LOCOMOTION", "IDLE")
end

local function ApplyRagdoll(character, duration)
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    State.movement.isRagdoll = true
    State.movement.ragdollStartTime = os.clock()
    State.movement.ragdollDuration = duration or 0
    character:SetAttribute("RAGDOLL", true)

    if State.camera.isShiftLocked then
        State.camera.isShiftLocked = false
        State.camera.shiftLockOffset = Vector3.new(0, 0, 0)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        local mouse = LocalPlayer:GetMouse()
        mouse.Icon = CURSOR_CONFIG.ENABLED and CURSOR_CONFIG.OVERRIDE_DEFAULT and CURSOR_CONFIG.DEFAULT_CURSOR or ""
    end

    SetupRagdoll(character)

    if duration and duration > 0 then
        task.delay(duration, function()
            if State.movement.isRagdoll then
                CancelRagdoll(character)
            end
        end)
    end
end

--[[ Camera Functions ]]
local function LockCamera()
    if not State.camera.isLocked then
        State.camera.previousCameraType = workspace.CurrentCamera.CameraType
        Utility.Camera.Lock(workspace.CurrentCamera)
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        State.camera.isLocked = true
    end
end

local function UnlockCamera()
    if State.camera.isLocked then
        Utility.Camera.Unlock(workspace.CurrentCamera)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        State.camera.isLocked = false
    end
end

--[[ Shift Lock Functions ]]
local function UpdateShift()
    if State.camera.isShiftLocked then
        State.camera.camOffsetSpring.Speed = SHIFT_LOCK_CONFIG.CAMERA_TRANSITION_IN_SPEED
        State.camera.camOffsetSpring.Target = SHIFT_LOCK_CONFIG.LOCKED_CAMERA_OFFSET
    else
        State.camera.camOffsetSpring.Speed = SHIFT_LOCK_CONFIG.CAMERA_TRANSITION_OUT_SPEED
        State.camera.camOffsetSpring.Target = Vector3.new(0, 0, 0)
    end

    State.camera.shiftLockOffset = State.camera.camOffsetSpring.Position
end

local function ApplyCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local humanoid = Character:FindFirstChild("Humanoid")
    local head = Character:FindFirstChild("Head")
    if not humanoid or not head then return end

    local distance = (head.Position - camera.CFrame.Position).Magnitude
    if distance > 1 then
        local offset = State.camera.shiftLockOffset
        if offset.Magnitude > 0.01 then
            camera.CFrame = camera.CFrame * CFrame.new(offset)
        end

        if State.camera.isShiftLocked and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end
end

local function ToggleShift()
    local humanoid = Character:FindFirstChild("Humanoid")
    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then return end

    if State.movement.isRagdoll and not State.camera.isShiftLocked then
        return
    end

    State.camera.isShiftLocked = not State.camera.isShiftLocked

    if not State.camera.isShiftLocked then
        State.camera.shiftLockOffset = Vector3.new(0, 0, 0)
    end

    UserInputService.MouseBehavior = State.camera.isShiftLocked and
        Enum.MouseBehavior.LockCenter or
        Enum.MouseBehavior.Default

    local mouse = LocalPlayer:GetMouse()
    if State.camera.isShiftLocked then
        mouse.Icon = SHIFT_LOCK_CONFIG.LOCKED_MOUSE_ICON
    else
        mouse.Icon = CURSOR_CONFIG.ENABLED and CURSOR_CONFIG.OVERRIDE_DEFAULT and CURSOR_CONFIG.DEFAULT_CURSOR or ""
    end

    if humanoid then
        humanoid.AutoRotate = not State.camera.isShiftLocked
        if State.camera.isShiftLocked then
            local camera = workspace.CurrentCamera
            if camera then
                local _, targetYaw, _ = camera.CFrame:ToOrientation()
                local currentCFrame = rootPart.CFrame
                local _, currentYaw, _ = currentCFrame:ToOrientation()

                local angleDiff = targetYaw - currentYaw
                while angleDiff > math.pi do
                    angleDiff = angleDiff - (2 * math.pi)
                end
                while angleDiff < -math.pi do
                    angleDiff = angleDiff + (2 * math.pi)
                end

                local tweenInfo = TweenInfo.new(
                    0.4,
                    Enum.EasingStyle.Cubic,
                    Enum.EasingDirection.Out
                )

                local targetCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, targetYaw, 0)
                local tween = game:GetService("TweenService"):Create(rootPart, tweenInfo, {
                    CFrame = targetCFrame
                })
                tween:Play()
            end
        end
    end
end

--[[ Detection Functions ]]
local function DetectLedge()
    if not Character then return false end

    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return false end

    if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and
       humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        return false
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local ray = workspace:Raycast(
        rootPart.Position,
        rootPart.CFrame.LookVector * 5,
        raycastParams
    )

    if ray and ray.Instance then
        local aboveCheck = workspace:Raycast(
            ray.Position + Vector3.new(0, 1, 0),
            Vector3.new(0, 3, 0),
            raycastParams
        )

        if not aboveCheck then
            return true
        end
    end

    return false
end

local function DetectWall()
    if not Character then return false end

    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = true

    local checkHeights = {0, 2, 4}
    local checkDistance = 2.5

    for _, heightOffset in ipairs(checkHeights) do
        local startPos = rootPart.Position + Vector3.new(0, heightOffset, 0)
        local directions = {
            rootPart.CFrame.LookVector * checkDistance,
            rootPart.CFrame.RightVector * checkDistance,
            -rootPart.CFrame.RightVector * checkDistance
        }

        for _, direction in pairs(directions) do
            local ray = workspace:Raycast(startPos, direction, raycastParams)
            if ray and ray.Instance and ray.Instance.CanCollide then
                return true
            end
        end
    end

    return false
end

local function DetectVault()
    if not Character then return false end

    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return false end

    if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
        return false
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = true

    local rayOrigin = rootPart.Position + Vector3.new(0, humanoid.HipHeight * 0.25, 0)
    local rayDirection = rootPart.CFrame.LookVector * 2.5

    local frontCheck = workspace:Raycast(
        rayOrigin,
        rayDirection,
        raycastParams
    )

    if not frontCheck then
        return false
    end

    local obstacleDistance = (frontCheck.Position - rayOrigin).Magnitude
    if obstacleDistance < 0.5 then
        return false
    end

    local obstacleHeight = frontCheck.Position.Y - rootPart.Position.Y
    if obstacleHeight > 3.5 then
        return false
    end

    local aboveCheck = workspace:Raycast(
        frontCheck.Position + Vector3.new(0, 2, 0),
        rootPart.CFrame.LookVector * 2,
        raycastParams
    )

    if aboveCheck then
        return false
    end

    local function CheckLanding(offset)
        local baseOffset = math.max(1.5, obstacleDistance + 1)
        local checkPosition = frontCheck.Position + Vector3.new(0, 2, 0) + (rootPart.CFrame.LookVector * (baseOffset + offset))

        local landingCheck = workspace:Raycast(
            checkPosition,
            Vector3.new(0, -4, 0),
            raycastParams
        )
        return landingCheck
    end

    local landingCheck = nil
    for offset = 0, 1.0, 0.25 do
        landingCheck = CheckLanding(offset)
        if landingCheck then
            break
        end
    end

    if not landingCheck then
        return false
    end

    return {
        success = true,
        landingPosition = landingCheck.Position,
        obstacleDistance = obstacleDistance
    }
end

local function DetectSwing()
    if not Character then return false end

    local rootPart = Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local ray = workspace:Raycast(
        rootPart.Position,
        Vector3.new(0, 10, 0),
        raycastParams
    )

    return ray and ray.Instance and ray.Instance:FindFirstChild("SwingPoint")
end

--[[ Input Handling ]]
local function ValidateAction(actionName)
    local currentTime = os.clock()
    return currentTime - State.movement.debounce[actionName] > DEBOUNCE_TIMES[actionName]
end

local function SetDebounce(actionName)
    State.movement.debounce[actionName] = os.clock()
end

local function CancelCrouch()
    if State.movement.isCrouching then
        State.movement.isCrouching = false
        StopAnimation("LOCOMOTION", "WALK")
        StopAnimation("LOCOMOTION", "SPRINT")
        PlayAnimation("LOCOMOTION", "IDLE")
        Services.Event:FireServer("Client.Movement.Execute", { type = "crouch", enabled = false })

        local humanoid = Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

--[[ Movement Handlers ]]
local MovementHandlers
MovementHandlers = {
    Run = function(enabled)
        if enabled then
            if State.movement.isCrouching then return nil end

            local currentTime = os.clock()
            if currentTime - State.movement.lastWTap < Modules.Stat.Constants.MOVEMENT.SPRINT_DOUBLE_TAP_DELAY then
                State.movement.isRunning = true
                State.movement.isWalking = false
                StopAnimation("LOCOMOTION", "SPRINT")
                PlayAnimation("LOCOMOTION", "SPRINT")

                if not State.movement.effects.run then
                    local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
                    if torso then
                        local effect, cleanup = Utility.Particle.Play("Run", torso, {
                            continuous = true,
                            weld = true,
                            offset = CFrame.new(0, 0, 0)
                        })
                        State.movement.effects.run = effect
                        State.movement.effects.runCleanup = cleanup
                    end

                    local limbs = {
                        ["Left Arm"] = Character:FindFirstChild("LeftUpperArm") or Character:FindFirstChild("Left Arm"),
                        ["Right Arm"] = Character:FindFirstChild("RightUpperArm") or Character:FindFirstChild("Right Arm"),
                        ["Left Leg"] = Character:FindFirstChild("LeftUpperLeg") or Character:FindFirstChild("Left Leg"),
                        ["Right Leg"] = Character:FindFirstChild("RightUpperLeg") or Character:FindFirstChild("Right Leg")
                    }

                    for limbName, limbPart in pairs(limbs) do
                        if limbPart then
                            local effect, cleanup = Utility.Particle.Play("Speed Trails", limbPart, {
                                continuous = true,
                                weld = true,
                                target = limbName
                            })
                            if effect then
                                State.movement.effects.speedTrails[limbName] = effect
                                State.movement.effects.speedTrailsCleanup[limbName] = cleanup
                            end
                        end
                    end
                end

                Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.RUN_FOV, CAMERA_SETTINGS.TRANSITION_TIME)

                return { type = "run", enabled = true }
            end
            State.movement.lastWTap = currentTime
            State.movement.isWalking = true
            StopAnimation("LOCOMOTION", "SPRINT")
            PlayAnimation("LOCOMOTION", "WALK")
            return { type = "walk", enabled = true }
        else
            State.movement.isRunning = false
            State.movement.isWalking = true
            StopAnimation("LOCOMOTION", "SPRINT")
            if not State.movement.isCrouching then
                PlayAnimation("LOCOMOTION", "WALK")
            end

            if State.movement.effects.runCleanup then
                State.movement.effects.runCleanup()
                State.movement.effects.run = nil
                State.movement.effects.runCleanup = nil
            end

            for limbName, cleanup in pairs(State.movement.effects.speedTrailsCleanup) do
                cleanup()
                State.movement.effects.speedTrails[limbName] = nil
                State.movement.effects.speedTrailsCleanup[limbName] = nil
            end

            Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV, CAMERA_SETTINGS.TRANSITION_TIME)

            return { type = "walk", enabled = true }
        end
    end,
    Roll = function()
        if not ValidateAction("roll") then return nil end

        local humanoid = Character:FindFirstChild("Humanoid")
        if not humanoid then return nil end

        CancelCrouch()

        if humanoid.FloorMaterial == Enum.Material.Air then
            return MovementHandlers.Dash()
        end

        SetDebounce("roll")
        State.movement.isRolling = true

        local direction = "forward"
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = "backward"
        elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = "left"
        elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = "right"
        end

        if direction == "backward" then
            direction = "back"
        end

        Utility.Particle.Play("Dodge", Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso"))

        if direction == "left" then
            PlayAnimation("ROLL", "LEFT")
        elseif direction == "right" then
            PlayAnimation("ROLL", "RIGHT")
        elseif direction == "backward" then
            PlayAnimation("ROLL", "BACK")
        else
            PlayAnimation("ROLL", "FORWARD")
        end

        return { type = "roll", direction = direction }
    end,
    Crouch = function(enabled)
        if not ValidateAction("crouch") then return nil end
        SetDebounce("crouch")

        if enabled and State.movement.isCrouching then
            enabled = false
        end

        State.movement.isCrouching = enabled
        if enabled then
            StopAnimation("LOCOMOTION", "WALK")
            StopAnimation("LOCOMOTION", "SPRINT")
            StopAnimation("LOCOMOTION", "IDLE")

            if State.movement.isWalking or State.movement.isRunning then
                PlayAnimation("LOCOMOTION", "CROUCH_WALK")
            else
                PlayAnimation("LOCOMOTION", "CROUCH_IDLE")
            end
        else
            StopAnimation("LOCOMOTION", "CROUCH_IDLE")
            StopAnimation("LOCOMOTION", "CROUCH_WALK")

            if State.movement.isWalking then
                PlayAnimation("LOCOMOTION", "WALK")
            elseif State.movement.isRunning then
                PlayAnimation("LOCOMOTION", "SPRINT")
            else
                PlayAnimation("LOCOMOTION", "IDLE")
            end
        end
        return { type = "crouch", enabled = enabled }
    end,
    Slide = function()
        if not ValidateAction("slide") then return nil end
        SetDebounce("slide")

        local humanoid = Character:FindFirstChild("Humanoid")
        local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
        if not humanoid or not torso then return nil end

        if not State.movement.isRunning or humanoid:GetState() ~= Enum.HumanoidStateType.Running then
            return nil
        end

        State.movement.isSliding = true
        PlayAnimation("SPECIAL", "SLIDE")

        if not State.movement.effects.slide then
            local effect, cleanup = Utility.Particle.Play("Slide", torso, {
                continuous = true,
                weld = true,
                offset = CFrame.new(0, -2.5, 0) * CFrame.new(torso.CFrame.LookVector)
            })
            State.movement.effects.slide = effect
            State.movement.effects.slideCleanup = cleanup
        end

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV + 10, Modules.Stat.Constants.MOVEMENT.SLIDE_SMOOTH_TIME)

        return { type = "slide" }
    end,
    WallRun = function()
        State.movement.isWallRunning = true
        local direction = State.movement.currentDirection

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV + 15, 0.3)

        if direction == "left" then
            PlayAnimation("WALL", "RUN_LEFT")
        else
            PlayAnimation("WALL", "RUN_RIGHT")
        end
        return { type = "wall_run" }
    end,
    WallClimb = function()
        if DetectWall() then
            CancelCrouch()
            State.movement.isClimbing = true
            PlayAnimation("WALL", "HOLD")
            return { type = "wall_climb" }
        end
    end,
    Swing = function()
        if DetectSwing() then
            State.movement.isSwinging = true
            PlayAnimation("LEDGE", "HOLD")
            return { type = "swing" }
        end
        return nil
    end,
    Hang = function()
        if DetectLedge() then
            State.movement.isLedgeHolding = true
            PlayAnimation("LEDGE", "HOLD")
            return { type = "hang" }
        end
        return nil
    end,
    Climb = function()
        return nil
    end,
    Sit = function(enabled)
        State.movement.isSitting = enabled
        if enabled then
            PlayAnimation("LOCOMOTION", "SIT")
        else
            StopAnimation("LOCOMOTION", "SIT")
            PlayAnimation("LOCOMOTION", "IDLE")
        end
        return { type = "sit", enabled = enabled }
    end,
    Vault = function()
        if not ValidateAction("vault") then return nil end
        SetDebounce("vault")

        local vaultInfo = DetectVault()
        if not vaultInfo or not vaultInfo.success then return nil end

        State.movement.isVaulting = true
        PlayAnimation("SPECIAL", "VAULT")
        Utility.Sound.Play("SFX.Dash")

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV + 5, Modules.Stat.Constants.MOVEMENT.SLIDE_SMOOTH_TIME)

        local humanoid = Character:FindFirstChild("Humanoid")
        local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
        if humanoid and torso then
            local originalWalkSpeed = humanoid.WalkSpeed
            local originalJumpPower = humanoid.JumpPower
            local originalAutoRotate = humanoid.AutoRotate

            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false

            local targetPosition = vaultInfo.landingPosition + Vector3.new(0, humanoid.HipHeight, 0)
            local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = game:GetService("TweenService"):Create(torso, tweenInfo, {
                CFrame = CFrame.new(targetPosition, targetPosition + torso.CFrame.LookVector)
            })

            local function cleanup()
                if humanoid then
                    humanoid.WalkSpeed = originalWalkSpeed
                    humanoid.JumpPower = originalJumpPower
                    humanoid.AutoRotate = originalAutoRotate
                end

                State.movement.isVaulting = false
                State.movement.isWalking = false
                StopAnimation("SPECIAL", "VAULT")
                PlayAnimation("LOCOMOTION", "IDLE")
                Services.Event:FireServer("Client.Movement.Execute", { type = "idle", enabled = true })
            end

            tween:Play()
            tween.Completed:Connect(cleanup)
            task.delay(1, function()
                if State.movement.isVaulting then
                    cleanup()
                end
            end)
        end

        return {
            type = "vault",
            landingPosition = vaultInfo.landingPosition
        }
    end,
    Swim = function(enabled)
        State.movement.isSwimming = enabled
        if enabled then
            PlayAnimation("LOCOMOTION", "SWIM")
        else
            StopAnimation("LOCOMOTION", "SWIM")
            PlayAnimation("LOCOMOTION", "IDLE")
        end
        return { type = "swim", enabled = enabled }
    end,
    Dash = function()
        if not ValidateAction("dash") then return nil end
        SetDebounce("dash")

        CancelCrouch()

        local rootPart = Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return nil end

        State.movement.isDashing = true
        State.movement.isWalking = false
        State.movement.isRunning = false

        StopAnimation("LOCOMOTION", "WALK")
        StopAnimation("LOCOMOTION", "SPRINT")
        StopAnimation("LOCOMOTION", "JUMP")
        StopAnimation("LOCOMOTION", "FALL")
        StopAnimation("LOCOMOTION", "IDLE")

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV + 20, 0.1)
        PlayAnimation("SPECIAL", "AIR_DASH")
        Utility.Sound.Play("SFX.Dash")
        return { type = "dash", direction = State.movement.currentDirection }
    end,
    Jump = function(enabled)
        if enabled then
            CancelCrouch()
            State.movement.isJumping = true
            PlayAnimation("LOCOMOTION", "JUMP")
            return { type = "jump" }
        end
        return nil
    end,
    Fall = function()
        State.movement.isFalling = true
        PlayAnimation("LOCOMOTION", "FALL")
        return { type = "fall" }
    end,
    CrouchWalk = function(enabled)
        State.movement.isCrouchWalking = enabled
        if enabled then
            StopAnimation("LOCOMOTION", "WALK")
            StopAnimation("LOCOMOTION", "SPRINT")
            StopAnimation("LOCOMOTION", "CROUCH_IDLE")
            PlayAnimation("LOCOMOTION", "CROUCH_WALK")
        else
            StopAnimation("LOCOMOTION", "CROUCH_WALK")
            if State.movement.isWalking then
                PlayAnimation("LOCOMOTION", "WALK")
            elseif State.movement.isRunning then
                PlayAnimation("LOCOMOTION", "SPRINT")
            else
                PlayAnimation("LOCOMOTION", "CROUCH_IDLE")
            end
        end
        return { type = "crouch_walk", enabled = enabled }
    end,
    Land = function(impactStrength)
        if impactStrength > 0.5 then
            Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV - 5, 0.2)
            PlayAnimation("LANDING", "LARGE")
        else
            Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV, 0.1)
            PlayAnimation("LANDING", "SMALL")
        end
        return { type = "land", impact = impactStrength }
    end,
    Ragdoll = function(enabled)
        if not Character then return nil end

        if enabled == State.movement.isRagdoll then return nil end

        if enabled then
            local stateTemplate = Modules.State.Templates["RAGDOLL"]
            ApplyRagdoll(Character, stateTemplate.duration)
        else
            CancelRagdoll(Character)
        end
        State.movement.isRagdoll = enabled
        return { type = "ragdoll", enabled = enabled }
    end
}
local MOVEMENT_HANDLERS = MovementHandlers

local MOVEMENT_CLEANUP = {
    Roll = function()
        State.movement.isRolling = false
        StopAnimation("ROLL", "FORWARD")
        StopAnimation("ROLL", "BACK")
        StopAnimation("ROLL", "LEFT")
        StopAnimation("ROLL", "RIGHT")
        PlayAnimation("LANDING", "SMALL")

        local rootPart = Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local rollForce = rootPart:FindFirstChild("roll_force")
            if rollForce then
                rollForce:Destroy()
            end
        end

        State.movement.isStunned = false
        State.movement.isWalking = false
        State.movement.isRunning = false

        local humanoid = Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.AutoRotate = true
        end
    end,
    Slide = function()
        State.movement.isSliding = false
        StopAnimation("SPECIAL", "SLIDE")
        PlayAnimation("LANDING", "SMALL")

        if State.movement.effects.slideCleanup then
            State.movement.effects.slideCleanup()
            State.movement.effects.slide = nil
            State.movement.effects.slideCleanup = nil
        end

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV, Modules.Stat.Constants.MOVEMENT.SLIDE_SMOOTH_TIME)
        Utility.Camera.StopShake(workspace.CurrentCamera)
    end,
    Dash = function()
        State.movement.isDashing = false
        State.movement.isWalking = false
        StopAnimation("SPECIAL", "AIR_DASH")
        StopAnimation("LOCOMOTION", "WALK")
        PlayAnimation("LANDING", "SMALL")

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV, 0.2)
        task.delay(0.2, function()
            PlayAnimation("LOCOMOTION", "IDLE")
        end)
    end,
    WallRun = function()
        State.movement.isWallRunning = false
        StopAnimation("WALL", "RUN_LEFT")
        StopAnimation("WALL", "RUN_RIGHT")

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV, 0.3)
        Utility.Camera.StopShake(workspace.CurrentCamera)
    end,
    WallClimb = function()
        State.movement.isWallClimbing = false
        StopAnimation("WALL", "HOLD")
    end,
    Swing = function()
        State.movement.isSwinging = false
        StopAnimation("LEDGE", "HOLD")
    end,
    Hang = function()
        State.movement.isLedgeHolding = false
        StopAnimation("LEDGE", "HOLD")
    end,
    Climb = function()
        State.movement.isClimbing = false
        StopAnimation("WALL", "HOLD")
    end,
    Sit = function()
        State.movement.isSitting = false
        StopAnimation("LOCOMOTION", "SIT")
    end,
    Vault = function()
        State.movement.isVaulting = false
        StopAnimation("SPECIAL", "VAULT")
        PlayAnimation("LANDING", "SMALL")

        Utility.Camera.FOV(workspace.CurrentCamera, CAMERA_SETTINGS.FOV, Modules.Stat.Constants.MOVEMENT.SLIDE_SMOOTH_TIME)
        task.delay(0.2, function()
            PlayAnimation("LOCOMOTION", "IDLE")
        end)
    end,
    Run = function()
        State.movement.isRunning = false
        State.movement.isWalking = true
        StopAnimation("LOCOMOTION", "SPRINT")
    end,
    Ragdoll = function()
        State.movement.isRagdoll = false
        if Character then
            Character:SetAttribute("RAGDOLL", false)
        end
    end
}

local function CanMove()
    if State.movement.isRagdoll then
        return false
    end

    return not (
        State.movement.isRolling or
        State.movement.isDashing or
        State.movement.isSliding or
        State.movement.isWallRunning or
        State.movement.isWallClimbing or
        State.movement.isSwinging or
        State.movement.isVaulting or
        State.movement.isLedgeHolding or
        State.movement.isClimbing or
        State.movement.isSitting or
        State.movement.isStunned
    )
end

--[[ Emote Functions ]]
local function ToggleEmotes(show)
    if not State.ui.emoteMenu.frame then return end

    local ui = State.ui.emoteMenu
    if show ~= nil then
        ui.isOpen = show
    else
        ui.isOpen = not ui.isOpen
    end

    if ui.isOpen then
        State.movement.isStunned = true
        ui.frame.Visible = true
        local scrollFrame = State.ui.emoteMenu.scrollFrame

        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local yOffset = 5
        for emoteName, data in pairs(Modules.Animation.Assets.Animations.EMOTES) do
            local button = CreateEmote("EMOTES", emoteName)
            button.Position = UDim2.new(0, 5, 0, yOffset)
            button.Parent = scrollFrame
            button.BackgroundTransparency = 1
            button.TextTransparency = 1
            yOffset = yOffset + 45
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

        Utility.Controller.Update({
            instance = ui.frame,
            properties = { ImageTransparency = 0 },
            duration = UI_SETTINGS.EMOTE_MENU.FADE_DURATION
        })

        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                Utility.Controller.Update({
                    instance = child,
                    properties = {
                        BackgroundTransparency = 0.5,
                        TextTransparency = 0
                    },
                    duration = UI_SETTINGS.EMOTE_MENU.FADE_DURATION
                })
            end
        end
    else
        State.movement.isStunned = false

        local scrollFrame = State.ui.emoteMenu.scrollFrame
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then
                Utility.Controller.Update({
                    instance = child,
                    properties = {
                        BackgroundTransparency = 1,
                        TextTransparency = 1
                    },
                    duration = UI_SETTINGS.EMOTE_MENU.FADE_DURATION
                })
            end
        end

        Utility.Controller.Update({
            instance = ui.frame,
            properties = { ImageTransparency = 1 },
            duration = UI_SETTINGS.EMOTE_MENU.FADE_DURATION,
            onComplete = function()
                ui.frame.Visible = false
                for _, child in pairs(scrollFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
            end
        })
    end
end

function CreateEmote(category: string, emoteName: string)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
    button.BackgroundTransparency = 0.5
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.Font = Enum.Font.Antique
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 18
    button.Text = emoteName:gsub("_", " ")
    button.AutoButtonColor = true

    button.MouseButton1Click:Connect(function()
        local animKey = category .. "_" .. emoteName
        if not Animations[animKey] then
            local originalColor = button.BackgroundColor3
            button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            task.delay(0.2, function()
                button.BackgroundColor3 = originalColor
                task.delay(0.1, function()
                    ToggleEmotes(false)
                end)
            end)
            return
        end

        PlayAnimation(category, emoteName)
        ToggleEmotes(false)
    end)

    return button
end

local function ExecuteMovement(actionName, inputState, inputObject)
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return Enum.ContextActionResult.Pass end

    if actionName == "Move" then
        for emoteName, _ in pairs(Modules.Animation.Assets.Animations.EMOTES) do
            local animKey = "EMOTES_" .. emoteName
            if Animations[animKey] and Animations[animKey].IsPlaying then
                StopAnimation("EMOTES", emoteName)
                PlayAnimation("LOCOMOTION", "IDLE")
                break
            end
        end

        if not CanMove() then
            humanoid:Move(Vector3.zero)
            return Enum.ContextActionResult.Sink
        end

        if inputState == Enum.UserInputState.Begin then
            if State.movement.isSwimming then
                StopAnimation("LOCOMOTION", "SWIM_IDLE")
                PlayAnimation("LOCOMOTION", "SWIM")
            elseif not State.movement.isWalking and not State.movement.isRunning then
                State.movement.isWalking = true
                if State.movement.isCrouching then
                    PlayAnimation("LOCOMOTION", "CROUCH_WALK")
                else
                    PlayAnimation("LOCOMOTION", "WALK")
                end
            end
        elseif inputState == Enum.UserInputState.End then
            local isAnyMovementKeyDown =
                UserInputService:IsKeyDown(Enum.KeyCode.W) or
                UserInputService:IsKeyDown(Enum.KeyCode.A) or
                UserInputService:IsKeyDown(Enum.KeyCode.S) or
                UserInputService:IsKeyDown(Enum.KeyCode.D)

            if not isAnyMovementKeyDown then
                if State.movement.isSwimming then
                    StopAnimation("LOCOMOTION", "SWIM")
                    PlayAnimation("LOCOMOTION", "SWIM_IDLE")
                else
                    State.movement.isWalking = false
                    State.movement.isRunning = false
                    StopAnimation("LOCOMOTION", "WALK")
                    StopAnimation("LOCOMOTION", "SPRINT")
                    StopAnimation("LOCOMOTION", "CROUCH_WALK")
                    if State.movement.isCrouching then
                        PlayAnimation("LOCOMOTION", "CROUCH_IDLE")
                    else
                        PlayAnimation("LOCOMOTION", "IDLE")
                    end
                    Services.Event:FireServer("Client.Movement.Execute", { type = "idle", enabled = true })
                end
            end
            return Enum.ContextActionResult.Pass
        end

        local camera = workspace.CurrentCamera
        if camera then
            local lookVector = camera.CFrame.LookVector
            local moveDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

            if moveDirection.Magnitude > 0 then
                Services.Event:FireServer("Client.Movement.Execute", {
                    type = "move",
                    direction = moveDirection
                })
            end
        end
        return Enum.ContextActionResult.Pass
    end

    if actionName == "Roll" or actionName == "Slide" or actionName == "Dash" then
        if inputState == Enum.UserInputState.Begin then
            if not CanMove() then
                return Enum.ContextActionResult.Sink
            end
            local handler = MOVEMENT_HANDLERS[actionName]
            if handler then
                local data = handler()
                if data then
                    data.ability = actionName:lower()
                    data.remaining = DEBOUNCE_TIMES[actionName:lower()]
                    data.duration = DEBOUNCE_TIMES[actionName:lower()]
                    Services.Event:FireServer("Client.Movement.Execute", data)
                end
            end
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "Emotes" then
        if inputState == Enum.UserInputState.Begin then
            ToggleEmotes()
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "Ragdoll" then
        if inputState == Enum.UserInputState.Begin then
            local handler = MOVEMENT_HANDLERS[actionName]
            if handler then
                if not State.movement.isRagdoll then
                    local data = handler(true)
                    if data then
                        Services.Event:FireServer("Client.Movement.Execute", data)
                    end
                end
            end
        end
        return Enum.ContextActionResult.Sink
    end

    local stateType = actionName:upper()
    local stateTemplate = Modules.State.Templates[stateType]
    if not stateTemplate then return Enum.ContextActionResult.Pass end

    local handler = MOVEMENT_HANDLERS[actionName]
    if not handler then return Enum.ContextActionResult.Pass end

    local data
    if inputState == Enum.UserInputState.Begin then
        data = handler(true)
    elseif inputState == Enum.UserInputState.End then
        data = handler(false)
        local cleanup = MOVEMENT_CLEANUP[actionName]
        if cleanup then cleanup() end
    end

    if data then
        Services.Event:FireServer("Client.Movement.Execute", data)
    end

    return Enum.ContextActionResult.Pass
end

local function TrackVelocity()
    local velocityConnection

    local function SetupConnection()
        if velocityConnection then
            velocityConnection:Disconnect()
            velocityConnection = nil
        end

        if not Character then return end

        local humanoid = Character:FindFirstChild("Humanoid")
        local rootPart = Character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end

        velocityConnection = RunService.Heartbeat:Connect(function()
            local currentVelocity = rootPart.AssemblyLinearVelocity.Y
            local wasInAir = os.clock() - State.movement.lastGroundedTime > 0.1

            if wasInAir and humanoid:GetState() == Enum.HumanoidStateType.Running then
                local impactStrength = math.clamp(
                    math.abs(State.movement.lastVerticalVelocity) / math.abs(State.movement.maxSafeVelocity),
                    0,
                    1
                )

                if impactStrength > 0.3 then
                    local data = {
                        type = "land",
                        impact = impactStrength - 0.3
                    }
                    Services.Event:FireServer("Client.Movement.Execute", data)

                    if impactStrength > 0.5 then
                        PlayAnimation("LANDING", "LARGE")
                    else
                        PlayAnimation("LANDING", "SMALL")
                    end
                elseif impactStrength > 0.1 then
                    PlayAnimation("LANDING", "SMALL")
                end

                State.movement.lastGroundedTime = os.clock()
            end

            if humanoid:GetState() == Enum.HumanoidStateType.Running then
                State.movement.lastGroundedTime = os.clock()
            end

            State.movement.lastVerticalVelocity = currentVelocity
        end)
    end

    SetupConnection()

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter
        SetupConnection()
    end)
end

local function SetupKeybindings()
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            return Enum.ContextActionResult.Sink
        end
    end)

    ContextActionService:BindAction(
        "DisableZoomIn",
        function() return Enum.ContextActionResult.Sink end,
        false,
        Enum.KeyCode.I
    )

    ContextActionService:BindAction(
        "DisableZoomOut",
        function() return Enum.ContextActionResult.Sink end,
        false,
        Enum.KeyCode.O
    )

    ContextActionService:BindAction(
        "Move",
        ExecuteMovement,
        false,
        Enum.KeyCode.W,
        Enum.KeyCode.A,
        Enum.KeyCode.S,
        Enum.KeyCode.D
    )

    for _, binding in ipairs(CONTROL_BINDINGS) do
        if binding.gamepadKey then
            ContextActionService:BindAction(
                binding.action,
                ExecuteMovement,
                false,
                binding.key,
                binding.gamepadKey
            )
        else
            ContextActionService:BindAction(
                binding.action,
                ExecuteMovement,
                false,
                binding.key
            )
        end
    end
end

local function CleanupKeybindings()
    for _, binding in ipairs(CONTROL_BINDINGS) do
        ContextActionService:UnbindAction(binding.action)
    end
end

--[[ Events ]]
local Events = {
    ["Character.Added"] = {
        handler = function(newCharacter)
            Character = newCharacter

            for key, _ in pairs(State.movement) do
                if type(State.movement[key]) == "boolean" then
                    State.movement[key] = false
                end
            end

            State.camera.isLocked = false
            State.camera.camOffsetSpring.Damper = SHIFT_LOCK_CONFIG.TRANSITION_SPRING_DAMPER

            for name, track in pairs(Animations) do
                if track and track.IsPlaying then
                    track:Stop()
                end
            end

            Humanoid = Character:WaitForChild("Humanoid")
            Animator = Humanoid:WaitForChild("Animator")
            Animations = {}
            InitializeAnimations()

            PlayAnimation("LOCOMOTION", "IDLE")
            Services.Event:FireServer("Client.Movement.Execute", { type = "idle", enabled = true })

            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = CAMERA_SETTINGS.FOV
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                LocalPlayer.CameraMinZoomDistance = 0
                LocalPlayer.CameraMaxZoomDistance = CAMERA_SETTINGS.ZOOM
            end

            UserInputService.MouseIconEnabled = true

            if not Humanoid then
                warn("No humanoid found in new character")
                return
            end

            Humanoid.StateChanged:Connect(function(old, new)
                if new == Enum.HumanoidStateType.Seated then
                    State.movement.isSitting = true
                    Services.Event:FireServer("Client.Movement.Execute", { type = "sit", enabled = true })
                elseif State.movement.isSitting and new == Enum.HumanoidStateType.Running then
                    State.movement.isSitting = false
                    Services.Event:FireServer("Client.Movement.Execute", { type = "sit", enabled = false })
                    return
                end

                if new == Enum.HumanoidStateType.Jumping then
                    if State.movement.isRolling then
                        MOVEMENT_CLEANUP.Roll()
                        Services.Event:FireServer("Client.Movement.Execute", { type = "roll", enabled = false })
                    end

                    if not State.movement.isDashing then
                        State.movement.isJumping = true
                        State.movement.isFalling = false
                        PlayAnimation("LOCOMOTION", "JUMP")
                    end
                elseif new == Enum.HumanoidStateType.Freefall then
                    if not State.movement.isRolling and not State.movement.isDashing then
                        State.movement.isJumping = false
                        State.movement.isFalling = true
                        StopAnimation("LOCOMOTION", "JUMP")
                        PlayAnimation("LOCOMOTION", "FALL")
                    end
                elseif new == Enum.HumanoidStateType.Landed then
                    State.movement.isFalling = false
                    StopAnimation("LOCOMOTION", "FALL")

                    if State.movement.isDashing then
                        State.movement.isDashing = false
                        StopAnimation("SPECIAL", "AIR_DASH")
                    end

                    if not State.movement.isRolling and not State.movement.isDashing then
                        local impactStrength = math.clamp(
                            math.abs(State.movement.lastVerticalVelocity) / math.abs(State.movement.maxSafeVelocity),
                            0,
                            1
                        )

                        if impactStrength > 0.5 then
                            PlayAnimation("LANDING", "LARGE")
                        else
                            PlayAnimation("LANDING", "SMALL")
                        end
                    end
                elseif new == Enum.HumanoidStateType.Running then
                    if old == Enum.HumanoidStateType.Landed then
                        task.delay(0.3, function()
                            if not State.movement.isRolling and not State.movement.isDashing and
                               not State.movement.isSliding and not State.movement.isWallRunning then
                                StopAnimation("LANDING", "LARGE")
                                StopAnimation("LANDING", "SMALL")

                                if State.movement.isRunning then
                                    PlayAnimation("LOCOMOTION", "SPRINT")
                                elseif State.movement.isWalking then
                                    PlayAnimation("LOCOMOTION", "WALK")
                                else
                                    PlayAnimation("LOCOMOTION", "IDLE")
                                end
                            end
                        end)
                    elseif not State.movement.isRolling and not State.movement.isDashing and
                           not State.movement.isSliding and not State.movement.isWallRunning then
                        if State.movement.isRunning then
                            PlayAnimation("LOCOMOTION", "SPRINT")
                        elseif State.movement.isWalking then
                            PlayAnimation("LOCOMOTION", "WALK")
                        else
                            PlayAnimation("LOCOMOTION", "IDLE")
                        end
                    end
                elseif new == Enum.HumanoidStateType.Swimming then
                    State.movement.isFalling = false
                    State.movement.isSwimming = true
                    StopAnimation("LOCOMOTION", "FALL")

                    local isMoving = Character:FindFirstChild("Humanoid") and Character.Humanoid.MoveDirection.Magnitude > 0
                    if isMoving then
                        StopAnimation("LOCOMOTION", "SWIM_IDLE")
                        PlayAnimation("LOCOMOTION", "SWIM")
                    else
                        StopAnimation("LOCOMOTION", "SWIM")
                        PlayAnimation("LOCOMOTION", "SWIM_IDLE")
                    end

                    Services.Event:FireServer("Client.Movement.Execute", { type = "swim", enabled = true })
                elseif old == Enum.HumanoidStateType.Swimming and new ~= Enum.HumanoidStateType.Swimming then
                    State.movement.isSwimming = false
                    StopAnimation("LOCOMOTION", "SWIM")
                    StopAnimation("LOCOMOTION", "SWIM_IDLE")
                    PlayAnimation("LOCOMOTION", "IDLE")
                    Services.Event:FireServer("Client.Movement.Execute", { type = "swim", enabled = false })
                elseif new == Enum.HumanoidStateType.Dead then
                    State.movement.isFalling = false
                    StopAnimation("LOCOMOTION", "FALL")
                end
            end)

            Humanoid.Died:Connect(function()
                for name, track in pairs(Animations) do
                    if track and track.IsPlaying then
                        track:Stop()
                    end
                end

                CleanupKeybindings()

                if State.camera.shiftLockConnection then
                    State.camera.shiftLockConnection:Disconnect()
                    State.camera.shiftLockConnection = nil
                end

                if State.camera.motionBlurEffect then
                    State.camera.motionBlurEffect:Destroy()
                    State.camera.motionBlurEffect = nil
                end

                Character:SetAttribute("RAGDOLL", true)

                local torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
                if torso then
                    torso:ApplyImpulse(torso.CFrame.LookVector * 100)
                end

                if workspace.CurrentCamera then
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                    LocalPlayer.CameraMinZoomDistance = 0
                    LocalPlayer.CameraMaxZoomDistance = CAMERA_SETTINGS.ZOOM
                    workspace.CurrentCamera.FieldOfView = CAMERA_SETTINGS.FOV
                end

                State.camera.isShiftLocked = false
                State.camera.shiftLockOffset = Vector3.new(0, 0, 0)
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                local mouse = LocalPlayer:GetMouse()
                mouse.Icon = CURSOR_CONFIG.ENABLED and CURSOR_CONFIG.OVERRIDE_DEFAULT and CURSOR_CONFIG.DEFAULT_CURSOR or ""

                for key, _ in pairs(State.movement) do
                    if type(State.movement[key]) == "boolean" then
                        State.movement[key] = false
                    end
                end
            end)

            Humanoid.CameraOffset = Vector3.new(0, 0, 0)
            Humanoid.UseJumpPower = true

            SetupKeybindings()

            State.camera.isShiftLocked = false
            State.camera.shiftLockOffset = Vector3.new(0, 0, 0)
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            local mouse = LocalPlayer:GetMouse()
            mouse.Icon = CURSOR_CONFIG.ENABLED and CURSOR_CONFIG.OVERRIDE_DEFAULT and CURSOR_CONFIG.DEFAULT_CURSOR or ""

            if State.camera.shiftLockConnection then
                State.camera.shiftLockConnection:Disconnect()
                State.camera.shiftLockConnection = nil
            end

            if workspace.CurrentCamera then
                local rootPart = Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local humanoid = Character:FindFirstChild("Humanoid")
                    local hipHeight = humanoid and humanoid.HipHeight or 2
                    local cameraPos = rootPart.Position + Vector3.new(0, hipHeight + 1, 5)
                    local cameraLook = rootPart.Position + Vector3.new(0, hipHeight, 0)
                    workspace.CurrentCamera.CFrame = CFrame.new(cameraPos, cameraLook)
                end
            end

            State.camera.shiftLockConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end

                if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                    ToggleShift()
                end
            end)

            RunService.RenderStepped:Connect(function(delta)
                if not Character then return end

                local humanoid = Character:FindFirstChild("Humanoid")
                local rootPart = Character:FindFirstChild("HumanoidRootPart")
                if not humanoid or not rootPart then return end

                UpdateShift()
                ApplyCamera()

                local camera = workspace.CurrentCamera
                if not camera then return end

                if CAMERA_SETTINGS.MOTION_BLUR.ENABLED then
                    if not State.camera.motionBlurEffect then
                        State.camera.motionBlurEffect = Instance.new("BlurEffect")
                        State.camera.motionBlurEffect.Parent = camera
                    end

                    local currentLookVector = camera.CFrame.LookVector
                    local magnitude = (currentLookVector - State.camera.lastLookVector).Magnitude

                    local targetBlur = math.abs(magnitude) * CAMERA_SETTINGS.MOTION_BLUR.INTENSITY
                    local currentBlur = State.camera.motionBlurEffect.Size
                    local newBlur = currentBlur + (targetBlur - currentBlur) * CAMERA_SETTINGS.MOTION_BLUR.SMOOTHING

                    State.camera.motionBlurEffect.Size = newBlur
                    State.camera.lastLookVector = currentLookVector
                elseif State.camera.motionBlurEffect then
                    State.camera.motionBlurEffect:Destroy()
                    State.camera.motionBlurEffect = nil
                end

                local neck = Character:FindFirstChild("Torso") and Character.Torso:FindFirstChild("Neck") or
                             Character:FindFirstChild("UpperTorso") and Character.UpperTorso:FindFirstChild("Neck")
                if not neck then return end

                local cameraDirection = rootPart.CFrame:ToObjectSpace(camera.CFrame).LookVector.Unit
                local neckC0 = neck.C0

                local horizontalAngle = math.clamp(-math.asin(cameraDirection.X), -math.pi/2, math.pi/2)
                local verticalAngle = math.clamp(-math.pi/2 + math.asin(cameraDirection.Y), -math.pi/2, math.pi/2)

                local newNeckC0
                if cameraDirection.Z > 0 then
                    newNeckC0 = CFrame.new(neckC0.Position) *
                                CFrame.Angles(0, horizontalAngle, 0) *
                                CFrame.Angles(math.pi - verticalAngle, 0, math.pi)
                else
                    newNeckC0 = CFrame.new(neckC0.Position) *
                                CFrame.Angles(0, horizontalAngle, 0) *
                                CFrame.Angles(verticalAngle, 0, math.pi)
                end

                neck.C0 = neck.C0:Lerp(newNeckC0, delta * 10)

                if State.camera.isShiftLocked and not humanoid.Sit then
                    local _, targetYaw, _ = camera.CFrame:ToOrientation()
                    local currentCFrame = rootPart.CFrame
                    local _, currentYaw, _ = currentCFrame:ToOrientation()

                    local angleDiff = targetYaw - currentYaw
                    while angleDiff > math.pi do
                        angleDiff = angleDiff - (2 * math.pi)
                    end
                    while angleDiff < -math.pi do
                        angleDiff = angleDiff + (2 * math.pi)
                    end

                    local newYaw = currentYaw + (angleDiff * delta * 5 * SHIFT_LOCK_CONFIG.CHARACTER_ROTATION_SPEED)

                    local newCFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, newYaw, 0)

                    if SHIFT_LOCK_CONFIG.CHARACTER_SMOOTH_ROTATION then
                        rootPart.CFrame = currentCFrame:Lerp(newCFrame, delta * 5 * SHIFT_LOCK_CONFIG.CHARACTER_ROTATION_SPEED)
                    else
                        rootPart.CFrame = newCFrame
                    end
                end
            end)

            newCharacter:GetAttributeChangedSignal("RAGDOLL"):Connect(function()
                local isRagdoll = newCharacter:GetAttribute("RAGDOLL")
                local duration = newCharacter:GetAttribute("RAGDOLL_DURATION")

                if isRagdoll then
                    ApplyRagdoll(newCharacter, duration)
                else
                    CancelRagdoll(newCharacter)
                end
            end)

            if Humanoid then
                Humanoid.StateChanged:Connect(function(oldState, newState)
                    if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll then
                        ApplyRagdoll(newCharacter)
                    elseif oldState == Enum.HumanoidStateType.FallingDown or oldState == Enum.HumanoidStateType.Ragdoll then
                        CancelRagdoll(newCharacter)
                    end
                end)
            end
        end
    },

    ["Character.Removing"] = {
        handler = function(char)
            if State.camera.updateConnection then
                State.camera.updateConnection:Disconnect()
                State.camera.updateConnection = nil
            end

            if State.camera.motionBlurEffect then
                State.camera.motionBlurEffect:Destroy()
                State.camera.motionBlurEffect = nil
            end

            CleanupKeybindings()

            if State.movement.isRagdoll then
                CancelRagdoll(char)
            end
        end
    },

    ["Client.Movement.Execute"] = {
        handler = function(response)
            if not response then return end

            if response.type then
                response.type = string.lower(response.type)
            end

            if not response.success then
                warn(string.format(
                    "Movement failed: %s, Received type: %s",
                    response.error or "Unknown error",
                    response.type or "None"
                ))
                if response.type then
                    local cleanup = MOVEMENT_CLEANUP[response.type:sub(1,1):upper() .. response.type:sub(2)]
                    if cleanup then
                        cleanup()
                    end
                end
                return
            end

            if response.type == "move" then
                if response.data and response.data.direction then
                    Humanoid:Move(response.data.direction, true)
                end
                return
            end

            local movementTypes = {
                roll = DEBOUNCE_TIMES.roll,
                slide = DEBOUNCE_TIMES.slide,
                dash = DEBOUNCE_TIMES.dash
            }

            local duration = movementTypes[response.type]
            if duration then
                task.delay(duration, function()
                    local cleanup = MOVEMENT_CLEANUP[response.type == "dash" and "Dash" or response.type:sub(1,1):upper() .. response.type:sub(2)]
                    if cleanup then
                        cleanup()
                    end
                end)
            end
        end
    },

    ["Client.Movement.Camera"] = {
        handler = function(lock)
            if lock then
                LockCamera()
            else
                UnlockCamera()
            end
        end
    }
}

--[[ Initialization ]]
local function Initialize()
    InitializeAnimations()
    TrackVelocity()

    if CURSOR_CONFIG.ENABLED and CURSOR_CONFIG.OVERRIDE_DEFAULT then
        local mouse = LocalPlayer:GetMouse()
        mouse.Icon = CURSOR_CONFIG.DEFAULT_CURSOR
    end

    RunService.Heartbeat:Connect(function()
        if not Character then return end

        local humanoid = Character:FindFirstChild("Humanoid")
        if not humanoid then return end

        if CanMove() and (State.movement.isWalking or State.movement.isRunning) then
            if DetectVault() then
                local data = MOVEMENT_HANDLERS.Vault()
                if data then
                    Services.Event:FireServer("Client.Movement.Execute", data)
                end
            end
        end

        if CanMove() then
            if DetectWall() then
                local data = MOVEMENT_HANDLERS.Climb()
                if data and data.direction ~= "none" then
                    Services.Event:FireServer("Client.Movement.Execute", data)
                end
            else
                if State.movement.isClimbing then
                    State.movement.isClimbing = false
                    StopAnimation("WALL", "HOLD")
                    PlayAnimation("LOCOMOTION", "IDLE")
                end
            end
        end
    end)

    for eventName, handler in pairs(Events) do
        if eventName == "Character.Added" then
            LocalPlayer.CharacterAdded:Connect(handler.handler)
            if Character then
                handler.handler(Character)
            end
        elseif eventName == "Character.Removing" then
            LocalPlayer.CharacterRemoving:Connect(handler.handler)
        else
            Services.Event:OnClientEvent(eventName, handler.handler)
        end
    end

    SetupKeybindings()
end

Initialize()