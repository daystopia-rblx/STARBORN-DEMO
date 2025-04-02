--[[ Animation
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-02
]]
local Camera = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tools = {
    Shake = require(ReplicatedStorage.Modules.Tool.Shake)
}

local DEFAULT_TRANSITION_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local State = {
    tweens = {
        fov = nil,
        roll = nil
    },
    currentRoll = 0,
    targetRoll = 0
}

local function CleanupTween(tweenType: string)
    if State.tweens[tweenType] then
        State.tweens[tweenType]:Cancel()
        State.tweens[tweenType] = nil
    end
end

local CameraShaker = Tools.Shake.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CFrame = camera.CFrame * shakeCFrame
    end
end)
CameraShaker:Start()

local rollConnection = RunService.RenderStepped:Connect(function(deltaTime)
    local camera = workspace.CurrentCamera
    if not camera then return end

    if math.abs(State.currentRoll - State.targetRoll) > 0.001 then
        local alpha = math.clamp(deltaTime * 15, 0, 1)
        State.currentRoll = State.currentRoll + (State.targetRoll - State.currentRoll) * alpha

        local currentCFrame = camera.CFrame
        local pos = currentCFrame.Position
        local lookVector = currentCFrame.LookVector
        camera.CFrame = CFrame.new(pos, pos + lookVector) * CFrame.Angles(0, 0, math.rad(State.currentRoll))
    end
end)

function Camera.FOV(camera: Camera, targetFOV: number, transitionTime: number?)
    if not camera then return end

    CleanupTween("fov")

    local tweenInfo = TweenInfo.new(
        transitionTime or DEFAULT_TRANSITION_INFO.Time,
        DEFAULT_TRANSITION_INFO.EasingStyle,
        DEFAULT_TRANSITION_INFO.EasingDirection
    )

    State.tweens.fov = TweenService:Create(camera, tweenInfo, {
        FieldOfView = targetFOV
    })
    State.tweens.fov:Play()
end

function Camera.Shake(camera: Camera, presetName: string)
    if not camera then return end

    local preset = Tools.Shake.GetPreset(presetName)
    if preset then
        CameraShaker:ShakeOnce(preset)
    end
end

function Camera.ShakeSustain(camera: Camera, presetName: string)
    if not camera then return end

    local preset = Tools.Shake.GetPreset(presetName)
    if preset then
        return CameraShaker:ShakeSustain(preset)
    end
    return nil
end

function Camera.StopShake(camera: Camera, duration: number?)
    if not camera then return end
    CameraShaker:StopSustained(duration)
end

function Camera.ClearShake(camera: Camera, category: string?)
    if not camera then return end
    CameraShaker:ClearShakes(category)
end

function Camera.Tilt(camera: Camera, angle: number, transitionTime: number?)
    if not camera then return end

    CleanupTween("rotation")

    local tweenInfo = TweenInfo.new(
        transitionTime or DEFAULT_TRANSITION_INFO.Time,
        DEFAULT_TRANSITION_INFO.EasingStyle,
        DEFAULT_TRANSITION_INFO.EasingDirection
    )

    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position) * 
        CFrame.fromEulerAnglesXYZ(math.rad(angle), currentCFrame.Rotation.Y, 0)

    State.tweens.rotation = TweenService:Create(camera, tweenInfo, {
        CFrame = targetCFrame
    })
    State.tweens.rotation:Play()
end

function Camera.Pan(camera: Camera, offset: Vector3, transitionTime: number?)
    if not camera then return end

    CleanupTween("rotation")

    local tweenInfo = TweenInfo.new(
        transitionTime or DEFAULT_TRANSITION_INFO.Time,
        DEFAULT_TRANSITION_INFO.EasingStyle,
        DEFAULT_TRANSITION_INFO.EasingDirection
    )

    local currentCFrame = camera.CFrame
    local targetCFrame = currentCFrame * CFrame.new(offset)

    State.tweens.rotation = TweenService:Create(camera, tweenInfo, {
        CFrame = targetCFrame
    })
    State.tweens.rotation:Play()
end

function Camera.Roll(camera: Camera, angle: number, transitionTime: number?)
    if not camera then return end

    State.targetRoll = angle
end

function Camera.Recoil(camera: Camera, kickback: number, recovery: number)
    if not camera then return end

    local preset = Tools.Shake.GetPreset("Gunshot")
    preset.Magnitude = kickback
    preset.FadeOutTime = recovery
    CameraShaker:ShakeOnce(preset)
end

function Camera.Lock(camera: Camera)
    if not camera then return end
    camera.CameraType = Enum.CameraType.Scriptable
end

function Camera.Unlock(camera: Camera)
    if not camera then return end
    camera.CameraType = Enum.CameraType.Custom
end

return Camera