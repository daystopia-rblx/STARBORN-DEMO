--[[ MovementClient
    @author @Daystopia
    @version 1.1.1
    @date 2025-04-01
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
}

local Tools = {
    Spring = require(ReplicatedStorage.Modules.Tool.Spring)
}

local Utility = {
    Sound = require(script.Parent.Utility.Sound),
    Controller = require(script.Parent.Utility.Controller)
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
    FOV = 70,
    ZOOM = 10,
    TRANSITION_TIME = 0.3,
    MOTION_BLUR = {
        ENABLED = false,
        INTENSITY = 20,
        SMOOTHING = 0.5
    },
    RUN_FOV = 90
}

local UI_SETTINGS = {
    EMOTE_MENU = {
        FADE_DURATION = 0.3,
        DISPLAY_ORDER = 999998
    }
}

local DEBOUNCE_TIMES = {
    crouch = 0.15,
    dash = 0.5,
    roll = 0.8,
    slide = 1.0,
    vault = 0.5
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

local VALID_EMOTES = {
    "CHALLENGE",
    "HYSTERICAL",
    "MEDITATE",
    "MOCKING",
    "WEEPING"
}

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
        }
    }
}

--[[ Animation Functions ]]
local function LoadAnimation(animationName)
    local animationData = Modules.Animation.Assets.Animations[animationName]
    if not animationData or animationData.id == "" then return nil end

    local animation = Instance.new("Animation")
    animation.AnimationId = animationData.id
    local track = Animator:LoadAnimation(animation)
    track.Priority = animationData.priority
    track.Looped = animationData.looped
    return track
end

local function PlayAnimation(animationName)
    if Animations[animationName] then
        Animations[animationName]:Play()
    else
        warn("Attempted to play non-existent animation:", animationName)
    end
end

local function StopAnimation(animationName)
    if Animations[animationName] then
        Animations[animationName]:Stop()
    end
end

local function InitializeAnimations()
    for animationName in pairs(Modules.Animation.Assets.Animations) do
        Animations[animationName] = LoadAnimation(animationName)
    end
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

    PlayAnimation("IDLE")
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
    local camera = workspace.CurrentCamera
    if not camera then return end

    if not State.camera.isLocked then
        State.camera.previousCameraType = camera.CameraType
        camera.CameraType = Enum.CameraType.Scriptable
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        State.camera.isLocked = true
    end
end

local function UnlockCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end

    if State.camera.isLocked then
        camera.CameraType = State.camera.previousCameraType or Enum.CameraType.Custom
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
        StopAnimation("CROUCH_IDLE")
        StopAnimation("CROUCH_WALK")
        PlayAnimation("IDLE")
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
            if currentTime - State.movement.lastWTap < 0.3 then
                State.movement.isRunning = true
                State.movement.isWalking = false
                StopAnimation("WALK")
                PlayAnimation("SPRINT")
                return { type = "run", enabled = true }
            end
            State.movement.lastWTap = currentTime
            State.movement.isWalking = true
            StopAnimation("SPRINT")
            PlayAnimation("WALK")
            return { type = "walk", enabled = true }
        else
            State.movement.isRunning = false
            State.movement.isWalking = true
            StopAnimation("SPRINT")
            if not State.movement.isCrouching then
                PlayAnimation("WALK")
            end
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

        if direction == "left" then
            PlayAnimation("ROLL_LEFT")
        elseif direction == "right" then
            PlayAnimation("ROLL_RIGHT")
        elseif direction == "backward" then
            PlayAnimation("ROLL_BACK")
        else
            PlayAnimation("ROLL_FORWARD")
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
            StopAnimation("WALK")
            StopAnimation("SPRINT")
            StopAnimation("IDLE")

            if State.movement.isWalking or State.movement.isRunning then
                PlayAnimation("CROUCH_WALK")
            else
                PlayAnimation("CROUCH_IDLE")
            end
        else
            StopAnimation("CROUCH_IDLE")
            StopAnimation("CROUCH_WALK")

            if State.movement.isWalking then
                PlayAnimation("WALK")
            elseif State.movement.isRunning then
                PlayAnimation("SPRINT")
            else
                PlayAnimation("IDLE")
            end
        end
        return { type = "crouch", enabled = enabled }
    end,
    Slide = function()
        if not ValidateAction("slide") then return nil end
        SetDebounce("slide")

        local humanoid = Character:FindFirstChild("Humanoid")
        if not humanoid then return nil end

        if not State.movement.isRunning or humanoid:GetState() ~= Enum.HumanoidStateType.Running then
            return nil
        end

        State.movement.isSliding = true
        PlayAnimation("SLIDE")
        return { type = "slide" }
    end,
    WallRun = function()
        State.movement.isWallRunning = true
        local direction = State.movement.currentDirection
        if direction == "left" then
            PlayAnimation("WALL_RUN_LEFT")
        else
            PlayAnimation("WALL_RUN_RIGHT")
        end
        return { type = "wall_run" }
    end,
    WallClimb = function()
        if DetectWall() then
            CancelCrouch()
            State.movement.isClimbing = true
            PlayAnimation("WALL_HOLD")
            return { type = "wall_climb" }
        end
    end,
    Swing = function()
        if DetectSwing() then
            State.movement.isSwinging = true
            PlayAnimation("SWING")
            return { type = "swing" }
        end
        return nil
    end,
    Hang = function()
        if DetectLedge() then
            State.movement.isLedgeHolding = true
            PlayAnimation("LEDGE_HOLD")
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
            PlayAnimation("SIT")
        else
            StopAnimation("SIT")
            PlayAnimation("IDLE")
        end
        return { type = "sit", enabled = enabled }
    end,
    Vault = function()
        if not ValidateAction("vault") then return nil end
        SetDebounce("vault")

        local vaultInfo = DetectVault()
        if not vaultInfo or not vaultInfo.success then return nil end

        State.movement.isVaulting = true
        PlayAnimation("VAULT")
        Utility.Sound.Play("SFX.Dash")

        local humanoid = Character:FindFirstChild("Humanoid")
        local rootPart = Character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart then
            local originalWalkSpeed = humanoid.WalkSpeed
            local originalJumpPower = humanoid.JumpPower
            local originalAutoRotate = humanoid.AutoRotate

            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false

            local targetPosition = vaultInfo.landingPosition + Vector3.new(0, humanoid.HipHeight, 0)
            local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = game:GetService("TweenService"):Create(rootPart, tweenInfo, {
                CFrame = CFrame.new(targetPosition, targetPosition + rootPart.CFrame.LookVector)
            })

            local function cleanup()
                if humanoid then
                    humanoid.WalkSpeed = originalWalkSpeed
                    humanoid.JumpPower = originalJumpPower
                    humanoid.AutoRotate = originalAutoRotate
                end

                State.movement.isVaulting = false
                State.movement.isWalking = false
                StopAnimation("VAULT")
                PlayAnimation("IDLE")
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
            PlayAnimation("SWIM")
        else
            StopAnimation("SWIM")
            PlayAnimation("IDLE")
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

        StopAnimation("WALK")
        StopAnimation("SPRINT")
        StopAnimation("JUMP")
        StopAnimation("FALL")
        StopAnimation("IDLE")

        PlayAnimation("AIR_DASH")
        Utility.Sound.Play("SFX.Dash")
        return { type = "dash", direction = State.movement.currentDirection }
    end,
    Jump = function(enabled)
        if enabled then
            CancelCrouch()
            State.movement.isJumping = true
            PlayAnimation("JUMP")
            return { type = "jump" }
        end
        return nil
    end,
    Fall = function()
        State.movement.isFalling = true
        PlayAnimation("FALL")
        return { type = "fall" }
    end,
    CrouchWalk = function(enabled)
        State.movement.isCrouchWalking = enabled
        if enabled then
            StopAnimation("WALK")
            StopAnimation("SPRINT")
            StopAnimation("CROUCH_IDLE")
            PlayAnimation("CROUCH_WALK")
        else
            StopAnimation("CROUCH_WALK")
            if State.movement.isWalking then
                PlayAnimation("WALK")
            elseif State.movement.isRunning then
                PlayAnimation("SPRINT")
            else
                PlayAnimation("CROUCH_IDLE")
            end
        end
        return { type = "crouch_walk", enabled = enabled }
    end,
    Land = function(impactStrength)
        if impactStrength > 0.5 then
            PlayAnimation("LAND_LARGE")
        else
            PlayAnimation("LAND_SMALL")
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
        StopAnimation("ROLL_FORWARD")
        StopAnimation("ROLL_BACK")
        StopAnimation("ROLL_LEFT")
        StopAnimation("ROLL_RIGHT")
        PlayAnimation("LAND_SMALL")

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
        StopAnimation("SLIDE")
        PlayAnimation("LAND_SMALL")
    end,
    Dash = function()
        State.movement.isDashing = false
        State.movement.isWalking = false
        StopAnimation("AIR_DASH")
        StopAnimation("WALK")
        PlayAnimation("LAND_SMALL")
        task.delay(0.2, function()
            PlayAnimation("IDLE")
        end)
    end,
    WallRun = function()
        State.movement.isWallRunning = false
        StopAnimation("WALL_RUN_LEFT")
        StopAnimation("WALL_RUN_RIGHT")
    end,
    WallClimb = function()
        State.movement.isWallClimbing = false
        StopAnimation("WALL_CLIMB")
    end,
    Swing = function()
        State.movement.isSwinging = false
        StopAnimation("SWING")
    end,
    Hang = function()
        State.movement.isLedgeHolding = false
        StopAnimation("LEDGE_HOLD")
    end,
    Climb = function()
        State.movement.isClimbing = false
        StopAnimation("WALL_HOLD")
    end,
    Sit = function()
        State.movement.isSitting = false
        StopAnimation("SIT")
    end,
    Vault = function()
        State.movement.isVaulting = false
        StopAnimation("VAULT")
        PlayAnimation("LAND_SMALL")
        task.delay(0.2, function()
            PlayAnimation("IDLE")
        end)
    end,
    Run = function()
        State.movement.isRunning = false
        State.movement.isWalking = true
        StopAnimation("SPRINT")
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
        for _, emoteName in ipairs(VALID_EMOTES) do
            if Modules.Animation.Assets.Animations[emoteName] then
                local button = CreateEmote(emoteName)
                button.Position = UDim2.new(0, 5, 0, yOffset)
                button.Parent = scrollFrame
                button.BackgroundTransparency = 1
                button.TextTransparency = 1
                yOffset = yOffset + 45
            end
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

CreateEmote = function(emoteName)
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
        if not Animations[emoteName] then
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

        PlayAnimation(emoteName)
        ToggleEmotes(false)
    end)

    return button
end

local function ExecuteMovement(actionName, inputState, inputObject)
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return Enum.ContextActionResult.Pass end

    if actionName == "Move" then
        for _, emoteName in ipairs(VALID_EMOTES) do
            if Animations[emoteName] and Animations[emoteName].IsPlaying then
                StopAnimation(emoteName)
                PlayAnimation("IDLE")
                break
            end
        end

        if not CanMove() then
            humanoid:Move(Vector3.zero)
            return Enum.ContextActionResult.Sink
        end

        if inputState == Enum.UserInputState.Begin then
            if not State.movement.isWalking and not State.movement.isRunning then
                State.movement.isWalking = true
                if State.movement.isCrouching then
                    PlayAnimation("CROUCH_WALK")
                else
                    PlayAnimation("WALK")
                end
            end
        elseif inputState == Enum.UserInputState.End then
            local isAnyMovementKeyDown =
                UserInputService:IsKeyDown(Enum.KeyCode.W) or
                UserInputService:IsKeyDown(Enum.KeyCode.A) or
                UserInputService:IsKeyDown(Enum.KeyCode.S) or
                UserInputService:IsKeyDown(Enum.KeyCode.D)

            if not isAnyMovementKeyDown then
                State.movement.isWalking = false
                State.movement.isRunning = false
                StopAnimation("WALK")
                StopAnimation("SPRINT")
                StopAnimation("CROUCH_WALK")
                if State.movement.isCrouching then
                    PlayAnimation("CROUCH_IDLE")
                else
                    PlayAnimation("IDLE")
                end
                Services.Event:FireServer("Client.Movement.Execute", { type = "idle", enabled = true })
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
                        PlayAnimation("LAND_LARGE")
                    else
                        PlayAnimation("LAND_SMALL")
                    end
                elseif impactStrength > 0.1 then
                    PlayAnimation("LAND_SMALL")
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

            PlayAnimation("IDLE")
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
                        PlayAnimation("JUMP")
                    end
                elseif new == Enum.HumanoidStateType.Freefall then
                    if not State.movement.isRolling and not State.movement.isDashing then
                        State.movement.isJumping = false
                        State.movement.isFalling = true
                        StopAnimation("JUMP")
                        PlayAnimation("FALL")
                    end
                elseif new == Enum.HumanoidStateType.Landed then
                    State.movement.isFalling = false
                    StopAnimation("FALL")

                    if State.movement.isDashing then
                        State.movement.isDashing = false
                        StopAnimation("AIR_DASH")
                    end

                    if not State.movement.isRolling and not State.movement.isDashing then
                        local impactStrength = math.clamp(
                            math.abs(State.movement.lastVerticalVelocity) / math.abs(State.movement.maxSafeVelocity),
                            0,
                            1
                        )

                        if impactStrength > 0.5 then
                            PlayAnimation("LAND_LARGE")
                        else
                            PlayAnimation("LAND_SMALL")
                        end
                    end
                elseif new == Enum.HumanoidStateType.Running then
                    if old == Enum.HumanoidStateType.Landed then
                        task.delay(0.3, function()
                            if not State.movement.isRolling and not State.movement.isDashing and
                               not State.movement.isSliding and not State.movement.isWallRunning then
                                StopAnimation("LAND_LARGE")
                                StopAnimation("LAND_SMALL")

                                if State.movement.isRunning then
                                    PlayAnimation("SPRINT")
                                elseif State.movement.isWalking then
                                    PlayAnimation("WALK")
                                else
                                    PlayAnimation("IDLE")
                                end
                            end
                        end)
                    elseif not State.movement.isRolling and not State.movement.isDashing and
                           not State.movement.isSliding and not State.movement.isWallRunning then
                        if State.movement.isRunning then
                            PlayAnimation("SPRINT")
                        elseif State.movement.isWalking then
                            PlayAnimation("WALK")
                        else
                            PlayAnimation("IDLE")
                        end
                    end
                elseif new == Enum.HumanoidStateType.Swimming then
                    State.movement.isFalling = false
                    StopAnimation("FALL")
                    PlayAnimation("SWIM")
                elseif new == Enum.HumanoidStateType.Dead then
                    State.movement.isFalling = false
                    StopAnimation("FALL")
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
                    StopAnimation("WALL_HOLD")
                    PlayAnimation("IDLE")
                end
            end
        end
    end)

    Character:GetAttributeChangedSignal("IsRagdoll"):Connect(function()
        local isRagdoll = Character:GetAttribute("IsRagdoll")
        if isRagdoll then
        else
            PlayAnimation("IDLE")
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