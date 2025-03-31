--[[ MovementClient
    @author @Daystopia
    @version 1.1.0
    @date 2025-03-31
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
    State = require(ReplicatedStorage.Modules.StateModule)
}

local Utility = {
    Sound = require(script.Parent.Utility.Sound)
}

--[[ Types ]]
type CameraState = {
    lastUpdate: number,
    isLocked: boolean,
    previousCameraType: Enum.CameraType?
}

--[[ Constants ]]
local CONTROL_BINDINGS = {
    {action = "Jump", key = Enum.KeyCode.Space, description = "Jump"},
    {action = "Run", key = Enum.KeyCode.W, description = "Run", doubleTap = true},
    {action = "Roll", key = Enum.KeyCode.Q, description = "Roll"},
    {action = "Crouch", key = Enum.KeyCode.C, description = "Crouch"},
    {action = "Slide", key = Enum.KeyCode.LeftControl, description = "Slide"}
}

local CAMERA_SETTINGS = {
    FOV = 70,
    ZOOM = 10,
    TRANSITION_TIME = 0.3
}

local DEBOUNCE_TIMES = {
    crouch = 0.3,
    dash = 0.5,
    roll = 0.8,
    slide = 1.0,
    vault = 0.5
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Animations = {}

--[[ State ]]
local State = {
    camera = {
        lastUpdate = 0,
        isLocked = false,
    } :: CameraState,
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
        isLedgeVaulting = false,
        isRolling = false,
        isSwimming = false,
        isUnderwater = false,
        isFalling = false,
        isStunned = false,
        isDashing = false,
        isLedgeHolding = false,
        isClimbing = false,
        isSitting = false,
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

local IKConnections = {}

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

    local directions = {
        rootPart.CFrame.LookVector * 2,
        rootPart.CFrame.RightVector * 2,
        -rootPart.CFrame.RightVector * 2
    }

    for _, direction in pairs(directions) do
        local ray = workspace:Raycast(rootPart.Position, direction, raycastParams)
        if ray and ray.Instance then
            return true
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
        print("DetectVault: Not in running/moving state, current state:", humanoid:GetState().Name)
        return false
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = true

    -- Debug visualization of raycast
    local rayOrigin = rootPart.Position + Vector3.new(0, 0, 0)
    local rayDirection = rootPart.CFrame.LookVector * 2.5

    -- Visualize the raycast (debug)
    local rayVisualization = Instance.new("Part")
    rayVisualization.Anchored = true
    rayVisualization.CanCollide = false
    rayVisualization.Size = Vector3.new(0.2, 0.2, rayDirection.Magnitude)
    rayVisualization.CFrame = CFrame.lookAt(rayOrigin, rayOrigin + rayDirection)
    rayVisualization.Color = Color3.fromRGB(255, 0, 0)
    rayVisualization.Transparency = 0.5
    rayVisualization.Parent = workspace
    game:GetService("Debris"):AddItem(rayVisualization, 1)

    -- Check for obstacle in front at waist height
    local frontCheck = workspace:Raycast(
        rayOrigin,
        rayDirection,
        raycastParams
    )

    if not frontCheck then 
        print("DetectVault: No obstacle in front. Ray from:", rayOrigin, "in direction:", rayDirection)
        return false 
    end
    print("DetectVault: Found obstacle at height:", frontCheck.Position.Y - rootPart.Position.Y, "Distance:", (frontCheck.Position - rayOrigin).Magnitude)
    print("DetectVault: Obstacle instance:", frontCheck.Instance:GetFullName())

    -- Check if there's space above the obstacle
    local aboveCheck = workspace:Raycast(
        frontCheck.Position + Vector3.new(0, 2, 0),
        rootPart.CFrame.LookVector * 2,
        raycastParams
    )

    if aboveCheck then
        print("DetectVault: No space above obstacle")
        return false
    end
    print("DetectVault: Found space above obstacle")

    -- Check if there's ground on the other side to land on
    local landingCheck = workspace:Raycast(
        frontCheck.Position + Vector3.new(0, 2, 0) + (rootPart.CFrame.LookVector * 3),
        Vector3.new(0, -4, 0),
        raycastParams
    )

    if not landingCheck then
        print("DetectVault: No landing spot found")
        return false
    end
    print("DetectVault: Found landing spot at height:", landingCheck.Position.Y)

    print("DetectVault: All conditions met, can vault!")
    return true
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
    end
end

--[[ Movement Handlers ]]
local MovementHandlers
MovementHandlers = {
    Run = function(enabled)
        if enabled then
            local currentTime = os.clock()
            if currentTime - State.movement.lastWTap < 0.3 then
                State.movement.isRunning = true
                State.movement.isWalking = false
                PlayAnimation("SPRINT")
                return { type = "run", enabled = true }
            end
            State.movement.lastWTap = currentTime
            State.movement.isWalking = true
            PlayAnimation("WALK")
            return { type = "walk", enabled = true }
        else
            State.movement.isRunning = false
            State.movement.isWalking = true
            StopAnimation("SPRINT")
            PlayAnimation("WALK")
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
        local direction = State.movement.currentDirection
        if direction == "left" then
            PlayAnimation("ROLL_LEFT")
        elseif direction == "right" then
            PlayAnimation("ROLL_RIGHT")
        elseif direction == "back" then
            PlayAnimation("ROLL_BACK")
        else
            PlayAnimation("ROLL_FORWARD")
        end

        return { type = "roll" }
    end,
    Crouch = function(enabled)
        if not ValidateAction("crouch") then return nil end
        SetDebounce("crouch")

        State.movement.isCrouching = enabled
        if enabled then
            PlayAnimation("CROUCH_IDLE")
        else
            StopAnimation("CROUCH_IDLE")
            PlayAnimation("IDLE")
        end
        return { type = "crouch", enabled = enabled }
    end,
    Slide = function()
        if not ValidateAction("slide") then return nil end
        SetDebounce("slide")

        if not State.movement.isRunning then
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
        State.movement.isWallClimbing = true
        PlayAnimation("WALL_CLIMB")
        return { type = "wall_climb" }
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
        if DetectWall() then
            CancelCrouch()
            State.movement.isClimbing = true
            PlayAnimation("WALL_HOLD")
            return { type = "climb" }
        end
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
        if not ValidateAction("vault") then 
            print("Vault: Failed debounce check")
            return nil 
        end
        SetDebounce("vault")

        if DetectVault() then
            print("Vault: Starting vault execution")
            State.movement.isVaulting = true
            PlayAnimation("VAULT")
            Utility.Sound.Play("SFX.Dash")
            return { type = "vault" }
        end
        print("Vault: Detection check failed")
        return nil
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
        State.movement.isCrouching = enabled
        if enabled then
            PlayAnimation("CROUCH_WALK")
        else
            StopAnimation("CROUCH_WALK")
            PlayAnimation("WALK")
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
        Character:SetAttribute("IsRagdoll", enabled)
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
    end,
    Slide = function()
        State.movement.isSliding = false
        StopAnimation("SLIDE")
    end,
    Dash = function()
        State.movement.isDashing = false
        State.movement.isWalking = false
        StopAnimation("AIR_DASH")
        StopAnimation("WALK")
        PlayAnimation("IDLE")
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
        State.movement.isLedgeVaulting = false
        StopAnimation("VAULT")
    end,
    Run = function()
        State.movement.isRunning = false
        State.movement.isWalking = true
        StopAnimation("SPRINT")
    end,
    Ragdoll = function()
        State.movement.isRagdoll = false
        Character:SetAttribute("IsRagdoll", false)
        StopAnimation("RAGDOLL")
    end
}

local function CanMove()
    return not (
        State.movement.isRolling or
        State.movement.isDashing or
        State.movement.isSliding or
        State.movement.isWallRunning or
        State.movement.isWallClimbing or
        State.movement.isSwinging or
        State.movement.isLedgeVaulting or
        State.movement.isLedgeHolding or
        State.movement.isClimbing or
        State.movement.isSitting or
        State.movement.isStunned or
        State.movement.isRagdoll
    )
end

local function ExecuteMovement(actionName, inputState, inputObject)
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return Enum.ContextActionResult.Pass end

    if actionName == "Move" then
        if not CanMove() then
            return Enum.ContextActionResult.Sink
        end

        local moveDirection = Vector3.zero
        local isMoving = false

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += Vector3.new(0, 0, -1)
            State.movement.currentDirection = "forward"
            isMoving = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection += Vector3.new(0, 0, 1)
            State.movement.currentDirection = "back"
            isMoving = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection += Vector3.new(-1, 0, 0)
            State.movement.currentDirection = "left"
            isMoving = true
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += Vector3.new(1, 0, 0)
            State.movement.currentDirection = "right"
            isMoving = true
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        if isMoving and not State.movement.isDashing then
            if State.movement.isRunning then
                PlayAnimation("SPRINT")
            else
                if not State.movement.isWalking then
                    State.movement.isWalking = true
                    PlayAnimation("WALK")
                    Services.Event:FireServer("Client.Movement.Execute", { type = "walk", enabled = true })
                end
            end
        else
            if State.movement.isRunning then
                State.movement.isRunning = false
                Services.Event:FireServer("Client.Movement.Execute", { type = "run", enabled = false })
            end
            if State.movement.isWalking then
                State.movement.isWalking = false
                Services.Event:FireServer("Client.Movement.Execute", { type = "walk", enabled = false })
            end
            if not State.movement.isDashing then
                StopAnimation("WALK")
                StopAnimation("SPRINT")
                PlayAnimation("IDLE")
                Services.Event:FireServer("Client.Movement.Execute", { type = "idle", enabled = true })
            end
        end

        Services.Event:FireServer("Client.Movement.Execute", {
            type = "move",
            direction = moveDirection
        })
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

                if impactStrength > 0.1 then
                    local data = {
                        type = "land",
                        impact = impactStrength
                    }
                    Services.Event:FireServer("Client.Movement.Execute", data)

                    if impactStrength > 0.5 then
                        PlayAnimation("LAND_LARGE")
                    else
                        PlayAnimation("LAND_SMALL")
                    end
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

            Humanoid.Died:Connect(function()
                for name, track in pairs(Animations) do
                    if track and track.IsPlaying then
                        track:Stop()
                    end
                end

                CleanupKeybindings()

                Character:SetAttribute("IsRagdoll", true)
                PlayAnimation("RAGDOLL")

                local torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
                if torso then
                    torso:ApplyImpulse(torso.CFrame.LookVector * 100)
                end

                if workspace.CurrentCamera then
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                    LocalPlayer.CameraMinZoomDistance = 0
                    LocalPlayer.CameraMaxZoomDistance = CAMERA_SETTINGS.ZOOM
                end

                for key, _ in pairs(State.movement) do
                    if type(State.movement[key]) == "boolean" then
                        State.movement[key] = false
                    end
                end
            end)

            Humanoid.CameraOffset = Vector3.new(0, 0, 0)
            Humanoid.UseJumpPower = true

            SetupKeybindings()

            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = CAMERA_SETTINGS.FOV
            end
        end
    },

    ["Character.Removing"] = {
        handler = function(char)
            if State.camera.updateConnection then
                State.camera.updateConnection:Disconnect()
                State.camera.updateConnection = nil
            end

            CleanupKeybindings()
        end
    },

    ["Client.Movement.Execute"] = {
        handler = function(response)
            if not response then return end

            if response.type then
                response.type = string.lower(response.type)
            end

            if not response.success then
                warn("Movement failed:", response.error)
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
    end)

    Character:GetAttributeChangedSignal("IsRagdoll"):Connect(function()
        local isRagdoll = Character:GetAttribute("IsRagdoll")
        if isRagdoll then
            PlayAnimation("RAGDOLL")
        else
            StopAnimation("RAGDOLL")
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