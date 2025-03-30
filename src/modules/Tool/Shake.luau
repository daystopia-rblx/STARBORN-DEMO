--[[ Shake
    Advanced camera shake system with configurable presets and real-time control.
    Handles shake intensity, frequency, decay, and compound effects.
    @author @Daystopia
    @version 1.0.1
    @date 2025-02-12
]]
local Shake = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--[[ Types ]]
export type ShakeConfig = {
    -- Core Parameters
    Category: string?,
    Magnitude: number,
    Roughness: number,
    FadeInTime: number?,
    FadeOutTime: number?,

    -- Influence
    PositionInfluence: Vector3?,
    RotationInfluence: Vector3?,
    FOVInfluence: number?,

    -- Advanced Control
    Sustain: boolean?,
    MaxDistance: number?,
    Falloff: number?,
    DirectionalBias: Vector3?,
    Trauma: number?,
    Recovery: number?,
    TimeScale: number?,

    -- Visual Effects
    ChromaticAberration: number?,
    RadialBlur: number?,
    DistortionEffect: number?,
    MotionBlur: number?,
    Vignette: number?,
    ColorShift: Color3?,
    ColorShiftIntensity: number?,
    Saturation: number?,
    Brightness: number?,

    -- Events
    OnStart: (() -> ())?,
    OnUpdate: ((number) -> ())?,
    OnEnd: (() -> ())?
}

export type ShakeInstance = {
    Magnitude: number,
    Roughness: number,
    PositionInfluence: Vector3,
    RotationInfluence: Vector3,
    FOVInfluence: number,
    DeleteOnInactive: boolean,
    _shakeInstance: true,
    StartFadeOut: (self: ShakeInstance, fadeOutTime: number) -> (),
    StartFadeIn: (self: ShakeInstance, fadeInTime: number?) -> (),
    GetState: (self: ShakeInstance) -> string,
    AddTrauma: (self: ShakeInstance, amount: number) -> (),
    SetTrauma: (self: ShakeInstance, value: number) -> ()
}

--[[ Constants ]]
local DEFAULT_POSITION_INFLUENCE = Vector3.new(0.15, 0.15, 0.15)
local DEFAULT_ROTATION_INFLUENCE = Vector3.new(1, 1, 1)
local VECTOR3_ZERO = Vector3.new()

local ShakeState = {
    FadingIn = "FadingIn",
    FadingOut = "FadingOut",
    Sustained = "Sustained",
    Inactive = "Inactive",
    Paused = "Paused"
}

local ShakeCategory = {
    None = "None",
    Combat = "Combat",
    Environment = "Environment",
    Status = "Status",
    Cinematic = "Cinematic",
    Vehicle = "Vehicle",
    UI = "UI"
}

--[[ Profile Tags ]]
local PROFILE_TAGS = {
    MAIN = "ShakeUpdate",
    INSTANCE_UPDATE = "ShakeInstanceUpdate",
    CLEANUP = "ShakeCleanup",
    TRANSFORM = "ShakeTransform",
    EFFECTS = "ShakeEffects"
}

--[[ Presets ]]
local ShakePresets = {
    Bump = {
        Category = ShakeCategory.Combat,
        Magnitude = 2.5,
        Roughness = 4,
        FadeInTime = 0.1,
        FadeOutTime = 0.75,
        PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
        RotationInfluence = Vector3.new(1, 1, 1)
    },

    Bump2 = {
        Magnitude = 1.25,
        Roughness = 2,
        FadeInTime = 0.05,
        FadeOutTime = 0.375,
        PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
        RotationInfluence = Vector3.new(0.5, 0.5, 0.5)
    },

    Bump3 = {
        Magnitude = 5,
        Roughness = 8,
        FadeInTime = 0.2,
        FadeOutTime = 1.5,
        PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
        RotationInfluence = Vector3.new(2, 2, 2)
    },

    BumpSoft = {
        Magnitude = 0.833,
        Roughness = 1.333,
        FadeInTime = 0.033,
        FadeOutTime = 0.25,
        PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
        RotationInfluence = Vector3.new(0.2, 0.2, 0.2)
    },

    Explosion = {
        Category = ShakeCategory.Combat,
        Magnitude = 5,
        Roughness = 10,
        FadeInTime = 0,
        FadeOutTime = 1.5,
        PositionInfluence = Vector3.new(0.25, 0.25, 0.25),
        RotationInfluence = Vector3.new(4, 1, 1)
    },

    Earthquake = {
        Category = ShakeCategory.Environment,
        Magnitude = 0.6,
        Roughness = 3.5,
        FadeInTime = 2,
        FadeOutTime = 10,
        PositionInfluence = Vector3.new(0.25, 0.25, 0.25),
        RotationInfluence = Vector3.new(1, 1, 4)
    },

    BadTrip = {
        Category = ShakeCategory.Status,
        Magnitude = 10,
        Roughness = 0.15,
        FadeInTime = 5,
        FadeOutTime = 10,
        PositionInfluence = Vector3.new(0, 0, 0.15),
        RotationInfluence = Vector3.new(2, 1, 4)
    },

    HandheldCamera = {
        Category = ShakeCategory.Cinematic,
        Magnitude = 1,
        Roughness = 0.25,
        FadeInTime = 5,
        FadeOutTime = 10,
        PositionInfluence = Vector3.new(0, 0, 0),
        RotationInfluence = Vector3.new(1, 0.5, 0.5)
    },

    Vibration = {
        Magnitude = 0.4,
        Roughness = 20,
        FadeInTime = 2,
        FadeOutTime = 2,
        PositionInfluence = Vector3.new(0, 0.15, 0),
        RotationInfluence = Vector3.new(1.25, 0, 4)
    },

    RoughDriving = {
        Category = ShakeCategory.Vehicle,
        Magnitude = 1,
        Roughness = 2,
        FadeInTime = 1,
        FadeOutTime = 1,
        PositionInfluence = Vector3.new(0, 0, 0),
        RotationInfluence = Vector3.new(1, 1, 1)
    },

    HeavyVehicle = {
        Magnitude = 1.5,
        Roughness = 1.5,
        FadeInTime = 0.5,
        FadeOutTime = 0.5,
        PositionInfluence = Vector3.new(0.1, 0.2, 0.1),
        RotationInfluence = Vector3.new(0.5, 0.3, 0.5)
    },

    FastVehicle = {
        Magnitude = 0.6,
        Roughness = 4,
        FadeInTime = 0.3,
        FadeOutTime = 0.3,
        PositionInfluence = Vector3.new(0.05, 0.1, 0.05),
        RotationInfluence = Vector3.new(0.3, 0.2, 0.3)
    },

    Impact = {
        Magnitude = 3,
        Roughness = 6,
        FadeInTime = 0,
        FadeOutTime = 0.5,
        PositionInfluence = Vector3.new(0.2, 0.2, 0.2),
        RotationInfluence = Vector3.new(2, 0.5, 0.5)
    },

    LightImpact = {
        Magnitude = 1.5,
        Roughness = 4,
        FadeInTime = 0,
        FadeOutTime = 0.3,
        PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
        RotationInfluence = Vector3.new(1, 0.25, 0.25)
    },

    HeavyImpact = {
        Magnitude = 5,
        Roughness = 8,
        FadeInTime = 0,
        FadeOutTime = 0.8,
        PositionInfluence = Vector3.new(0.3, 0.3, 0.3),
        RotationInfluence = Vector3.new(3, 1, 1)
    },

    Sprint = {
        Magnitude = 0.3,
        Roughness = 10,
        FadeInTime = 0.2,
        FadeOutTime = 0.2,
        PositionInfluence = Vector3.new(0, 0.1, 0),
        RotationInfluence = Vector3.new(0.5, 0, 0.5)
    },

    Landing = {
        Magnitude = 2,
        Roughness = 5,
        FadeInTime = 0,
        FadeOutTime = 0.4,
        PositionInfluence = Vector3.new(0, 0.3, 0),
        RotationInfluence = Vector3.new(1.5, 0, 0)
    },

    Dizzy = {
        Magnitude = 1.5,
        Roughness = 0.2,
        FadeInTime = 3,
        FadeOutTime = 3,
        PositionInfluence = Vector3.new(0.1, 0.1, 0.1),
        RotationInfluence = Vector3.new(1, 1, 1)
    },

    Heartbeat = {
        Magnitude = 1,
        Roughness = 0.5,
        FadeInTime = 0.2,
        FadeOutTime = 0.4,
        PositionInfluence = Vector3.new(0, 0.1, 0),
        RotationInfluence = Vector3.new(0.2, 0, 0)
    },

    Underwater = {
        Magnitude = 0.3,
        Roughness = 0.1,
        FadeInTime = 1,
        FadeOutTime = 1,
        PositionInfluence = Vector3.new(0.1, 0.1, 0.1),
        RotationInfluence = Vector3.new(0.2, 0.2, 0.2)
    },

    Sword = {
        Magnitude = 1.2,
        Roughness = 8,
        FadeInTime = 0,
        FadeOutTime = 0.2,
        PositionInfluence = Vector3.new(0.1, 0.1, 0.2),
        RotationInfluence = Vector3.new(1, 0.5, 0.5)
    },

    Gunshot = {
        Magnitude = 0.8,
        Roughness = 15,
        FadeInTime = 0,
        FadeOutTime = 0.15,
        PositionInfluence = Vector3.new(0.05, 0.05, 0.2),
        RotationInfluence = Vector3.new(0.5, 0.25, 0.25)
    },

    Wind = {
        Magnitude = 0.4,
        Roughness = 0.3,
        FadeInTime = 2,
        FadeOutTime = 2,
        PositionInfluence = Vector3.new(0.1, 0.05, 0.1),
        RotationInfluence = Vector3.new(0.3, 0.1, 0.3)
    },

    Storm = {
        Magnitude = 0.8,
        Roughness = 0.5,
        FadeInTime = 3,
        FadeOutTime = 3,
        PositionInfluence = Vector3.new(0.15, 0.1, 0.15),
        RotationInfluence = Vector3.new(0.5, 0.2, 0.5)
    },

    Stun = {
        Magnitude = 2,
        Roughness = 0.4,
        FadeInTime = 0.1,
        FadeOutTime = 0.5,
        PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
        RotationInfluence = Vector3.new(1.5, 1.5, 1.5)
    },

    Poison = {
        Magnitude = 0.5,
        Roughness = 0.3,
        FadeInTime = 1,
        FadeOutTime = 1,
        PositionInfluence = Vector3.new(0.05, 0.05, 0.05),
        RotationInfluence = Vector3.new(0.3, 0.3, 0.3)
    },

    -- Psychological Effects
    Paranoia = {
        Magnitude = 0.3,
        Roughness = 0.2,
        FadeInTime = 2,
        FadeOutTime = 2,
        PositionInfluence = Vector3.new(0.05, 0.05, 0.05),
        RotationInfluence = Vector3.new(0.8, 0.8, 0.8),
        ChromaticAberration = 0.3,
        Vignette = 0.4,
        Sustain = true
    },

    Hallucination = {
        Magnitude = 0.4,
        Roughness = 0.15,
        FadeInTime = 3,
        FadeOutTime = 3,
        PositionInfluence = Vector3.new(0.1, 0.1, 0.1),
        RotationInfluence = Vector3.new(0.5, 0.5, 0.5),
        DistortionEffect = 0.3,
        ColorShift = Color3.new(1.1, 0.9, 1.1),
        ColorShiftIntensity = 0.4,
        Sustain = true
    },

    Nightmare = {
        Magnitude = 1.2,
        Roughness = 0.8,
        FadeInTime = 0.5,
        FadeOutTime = 1,
        PositionInfluence = Vector3.new(0.2, 0.2, 0.2),
        RotationInfluence = Vector3.new(2, 2, 2),
        DistortionEffect = 0.6,
        Vignette = 0.8,
        ChromaticAberration = 0.5
    },

    -- Environmental Effects
    HeatWave = {
        Magnitude = 0.2,
        Roughness = 0.1,
        FadeInTime = 2,
        FadeOutTime = 2,
        PositionInfluence = Vector3.new(0, 0.1, 0),
        RotationInfluence = Vector3.new(0.1, 0.1, 0.1),
        DistortionEffect = 0.2,
        Brightness = 0.2,
        Sustain = true
    },

    UnderwaterPressure = {
        Magnitude = 0.4,
        Roughness = 0.2,
        FadeInTime = 3,
        FadeOutTime = 3,
        PositionInfluence = Vector3.new(0.1, 0.15, 0.1),
        RotationInfluence = Vector3.new(0.3, 0.3, 0.3),
        Vignette = 0.5,
        RadialBlur = 0.3,
        FOVInfluence = -5,
        Sustain = true
    },

    ZeroGravity = {
        Magnitude = 0.5,
        Roughness = 0.15,
        FadeInTime = 2,
        FadeOutTime = 2,
        PositionInfluence = Vector3.new(0.2, 0.2, 0.2),
        RotationInfluence = Vector3.new(1.5, 1.5, 1.5),
        Recovery = 0.2,
        TimeScale = 0.5,
        Sustain = true
    },

    -- Status Effects
    Intoxicated = {
        Magnitude = 0.6,
        Roughness = 0.2,
        FadeInTime = 4,
        FadeOutTime = 4,
        PositionInfluence = Vector3.new(0.1, 0.1, 0.1),
        RotationInfluence = Vector3.new(1, 1, 1),
        ColorShift = Color3.new(1.1, 0.9, 1.1),
        ColorShiftIntensity = 0.3,
        RadialBlur = 0.2,
        Sustain = true
    },

    Exhaustion = {
        Magnitude = 0.3,
        Roughness = 0.15,
        FadeInTime = 3,
        FadeOutTime = 3,
        PositionInfluence = Vector3.new(0.05, 0.1, 0.05),
        RotationInfluence = Vector3.new(0.4, 0.4, 0.4),
        Brightness = -0.2,
        DistortionEffect = 0.2,
        Sustain = true
    },

    Adrenaline = {
        Magnitude = 0.4,
        Roughness = 1.5,
        FadeInTime = 0.2,
        FadeOutTime = 0.5,
        PositionInfluence = Vector3.new(0.1, 0.1, 0.1),
        RotationInfluence = Vector3.new(0.5, 0.5, 0.5),
        FOVInfluence = 10,
        Saturation = 0.3,
        TimeScale = 1.2
    },

    -- Impact Effects
    SonicBoom = {
        Magnitude = 2,
        Roughness = 15,
        FadeInTime = 0,
        FadeOutTime = 0.4,
        PositionInfluence = Vector3.new(0, 0, 0.3),
        RotationInfluence = Vector3.new(0.2, 0.2, 0.2),
        FOVInfluence = -15,
        RadialBlur = 0.6,
        ChromaticAberration = 0.5
    },

    TimeStop = {
        Magnitude = 3,
        Roughness = 20,
        FadeInTime = 0,
        FadeOutTime = 0.3,
        PositionInfluence = Vector3.new(0.2, 0.2, 0.2),
        RotationInfluence = Vector3.new(1, 1, 1),
        ChromaticAberration = 0.8,
        Saturation = -0.5,
        TimeScale = 0.1
    },

    RealityBreak = {
        Magnitude = 4,
        Roughness = 10,
        FadeInTime = 0,
        FadeOutTime = 0.6,
        PositionInfluence = Vector3.new(0.3, 0.3, 0.3),
        RotationInfluence = Vector3.new(3, 3, 3),
        DistortionEffect = 0.8,
        ChromaticAberration = 0.7,
        ColorShift = Color3.new(1.2, 0.8, 1.2),
        ColorShiftIntensity = 0.6
    }
}

--[[ Post-Processing Effects ]]
local function createPostProcessingEffects()
    local effects = {
        chromaticAberration = Instance.new("ColorCorrectionEffect"),
        radialBlur = Instance.new("BlurEffect"),
        motionBlur = Instance.new("BlurEffect"),
        distortion = Instance.new("DepthOfFieldEffect"),
        vignette = Instance.new("ColorCorrectionEffect"),
        colorShift = Instance.new("ColorCorrectionEffect")
    }

    -- Shake Chromatic Aberration
    effects.chromaticAberration.Enabled = false
    effects.chromaticAberration.TintColor = Color3.new(1, 0.9, 1)
    effects.chromaticAberration.Name = "ShakeChromatic"
    effects.chromaticAberration.Parent = workspace.CurrentCamera

    -- Shake Radial Blur
    effects.radialBlur.Enabled = false
    effects.radialBlur.Size = 0
    effects.radialBlur.Name = "ShakeRadialBlur"
    effects.radialBlur.Parent = workspace.CurrentCamera

    -- Motion Blur
    effects.motionBlur.Enabled = false
    effects.motionBlur.Size = 0
    effects.motionBlur.Name = "ShakeMotionBlur"
    effects.motionBlur.Parent = workspace.CurrentCamera

    -- Distortion
    effects.distortion.Enabled = false
    effects.distortion.FarIntensity = 0
    effects.distortion.NearIntensity = 0
    effects.distortion.Name = "ShakeDistortion"
    effects.distortion.Parent = workspace.CurrentCamera

    -- Vignette
    effects.vignette.Enabled = false
    effects.vignette.TintColor = Color3.new(0, 0, 0)
    effects.vignette.Name = "ShakeVignette"
    effects.vignette.Parent = workspace.CurrentCamera

    -- Color Shift
    effects.colorShift.Enabled = false
    effects.colorShift.Name = "ShakeColorShift"
    effects.colorShift.Parent = workspace.CurrentCamera

    return effects
end

--[[ Utilities ]]
local function createShakeInstance(config: ShakeConfig): ShakeInstance
    local self = {
        Magnitude = config.Magnitude,
        Roughness = config.Roughness,
        PositionInfluence = config.PositionInfluence or DEFAULT_POSITION_INFLUENCE,
        RotationInfluence = config.RotationInfluence or DEFAULT_ROTATION_INFLUENCE,
        FOVInfluence = config.FOVInfluence or 0,
        DeleteOnInactive = true,

        MaxDistance = config.MaxDistance,
        Falloff = config.Falloff or 1,
        DirectionalBias = config.DirectionalBias or Vector3.new(1, 1, 1),
        Trauma = config.Trauma or 1,
        Recovery = config.Recovery or 0.5,
        TimeScale = config.TimeScale or 1,
        ChromaticAberration = config.ChromaticAberration or 0,
        RadialBlur = config.RadialBlur or 0,
        DistortionEffect = config.DistortionEffect or 0,
        MotionBlur = config.MotionBlur or 0,
        Vignette = config.Vignette or 0,
        ColorShift = config.ColorShift or Color3.new(1, 1, 1),
        ColorShiftIntensity = config.ColorShiftIntensity or 0,
        Saturation = config.Saturation or 0,
        Brightness = config.Brightness or 0,

        _roughMod = 1,
        _magnMod = 1,
        _fadeOutDuration = config.FadeOutTime or 0,
        _fadeInDuration = config.FadeInTime or 0,
        _sustain = config.Sustain or (config.FadeInTime and config.FadeInTime > 0),
        _currentFadeTime = (config.FadeInTime and config.FadeInTime > 0) and 0 or 1,
        _tick = Random.new():NextNumber(-100, 100),
        _sourcePosition = workspace.CurrentCamera.CFrame.Position,
        _shakeInstance = true,
        _lastTrauma = 0,

        OnStart = config.OnStart,
        OnUpdate = config.OnUpdate,
        OnEnd = config.OnEnd
    }

    function self:UpdateTrauma(dt: number)
        if self.Trauma > 0 then
            if self.Recovery > 0 then
                self.Trauma = math.clamp(self.Trauma - (self.Recovery * dt), 0, 1)
            end

            self._magnMod = self.Trauma * self.Trauma

            self._roughMod = 0.5 + (self.Trauma * 0.5)

            if math.abs(self._lastTrauma - self.Trauma) > 0.05 and self.OnUpdate then
                self.OnUpdate(self.Trauma)
                self._lastTrauma = self.Trauma
            end
        end
    end

    function self:UpdateShake(dt: number): (Vector3, number)
        local tick = self._tick
        local roughness = self.Roughness * self._roughMod * self.TimeScale
        local currentFadeTime = self._currentFadeTime
        local fadeInDuration = self._fadeInDuration
        local sustain = self._sustain

        self:UpdateTrauma(dt)

        local noise1 = math.noise(tick, 0) * self.DirectionalBias.X
        local noise2 = math.noise(0, tick) * self.DirectionalBias.Y
        local noise3 = math.noise(tick, tick) * self.DirectionalBias.Z

        local offset = Vector3.new(noise1, noise2, noise3) * 0.5

        if fadeInDuration > 0 and sustain then
            if currentFadeTime < 1 then
                self._currentFadeTime = currentFadeTime + dt / fadeInDuration
            elseif self._fadeOutDuration > 0 then
                self._sustain = false
                sustain = false
            end
        end

        if not sustain then
            self._currentFadeTime = currentFadeTime - dt / self._fadeOutDuration
        end

        local intensity = 1
        if self.MaxDistance then
            local distance = (workspace.CurrentCamera.CFrame.Position - self._sourcePosition).Magnitude
            if distance >= self.MaxDistance then
                intensity = 0
            else
                intensity = (1 - (distance/self.MaxDistance)^self.Falloff)
            end
        end

        self._tick = tick + dt * roughness * (sustain and 1 or currentFadeTime)

        if self.OnUpdate then
            self.OnUpdate(currentFadeTime * intensity)
        end

        local fovDelta = offset.Y * self.FOVInfluence * self.Magnitude * self._magnMod * currentFadeTime * intensity

        return offset * self.Magnitude * self._magnMod * currentFadeTime * intensity, fovDelta
    end

    function self:SetTrauma(value: number)
        self.Trauma = math.clamp(value, 0, 1)
        self._magnMod = self.Trauma * self.Trauma
        if self.OnUpdate then
            self.OnUpdate(self.Trauma)
        end
    end

    function self:AddTrauma(value: number)
        self:SetTrauma(self.Trauma + value)
    end

    function self:StartFadeOut(fadeOutTime: number)
        if fadeOutTime == 0 then
            self._currentFadeTime = 0
        end
        self._fadeOutDuration = fadeOutTime
        self._fadeInDuration = 0
        self._sustain = false
    end

    function self:StartFadeIn(fadeInTime: number?)
        if fadeInTime == 0 then
            self._currentFadeTime = 1
        end
        self._fadeInDuration = fadeInTime or self._fadeInDuration
        self._fadeOutDuration = 0
        self._sustain = true
    end

    function self:GetState(): string
        local currentFadeTime = self._currentFadeTime
        local sustain = self._sustain
        local fadeInDuration = self._fadeInDuration

        if currentFadeTime < 1 and sustain and fadeInDuration > 0 then
            return ShakeState.FadingIn
        elseif not sustain and currentFadeTime > 0 then
            return ShakeState.FadingOut
        elseif currentFadeTime > 0 or sustain then
            return ShakeState.Sustained
        else
            return ShakeState.Inactive
        end
    end

    if self.OnStart then
        self.OnStart()
    end

    return self
end

-- Constructor
function Shake.new(renderPriority: number, callback: (CFrame) -> ())
    local self = {
        _running = false,
        _paused = false,
        _renderName = "CameraShaker",
        _renderPriority = renderPriority,
        _posAddShake = VECTOR3_ZERO,
        _rotAddShake = VECTOR3_ZERO,
        _shakeInstances = {},
        _removeInstances = {},
        _pausedStates = {},
        _callback = callback,
        _effects = createPostProcessingEffects(),
        _baseFieldOfView = workspace.CurrentCamera.FieldOfView,
        _lastUpdateTime = 0
    }

    function self:Start()
        if self._running then return end
        self._running = true
        self._lastUpdateTime = os.clock()

        RunService:BindToRenderStep(self._renderName, self._renderPriority, function(dt)
            if Players.LocalPlayer:GetAttribute("SHAKE") ~= true or self._paused then
                return
            end
            debug.profilebegin(PROFILE_TAGS.MAIN)
            self._callback(self:Update(dt))
            debug.profileend()
        end)
    end

    function self:Stop()
        if not self._running then return end
        RunService:UnbindFromRenderStep(self._renderName)

        for _, effect in pairs(self._effects) do
            effect:Destroy()
        end

        workspace.CurrentCamera.FieldOfView = self._baseFieldOfView
        self._running = false
    end

    function self:Update(dt: number): CFrame
        local posAddShake = VECTOR3_ZERO
        local rotAddShake = VECTOR3_ZERO
        local fovAddShake = 0
        local totalIntensity = 0
        local instances = self._shakeInstances
        local removeInstances = self._removeInstances

        debug.profilebegin(PROFILE_TAGS.INSTANCE_UPDATE)
        for i = 1, #instances do
            local instance = instances[i]
            local state = instance:GetState()

            if state == ShakeState.Inactive and instance.DeleteOnInactive then
                table.insert(removeInstances, i)
            elseif state ~= ShakeState.Inactive then
                local shake, fovDelta = instance:UpdateShake(dt)
                posAddShake += shake * instance.PositionInfluence
                rotAddShake += shake * instance.RotationInfluence
                fovAddShake += fovDelta
                totalIntensity += instance._currentFadeTime
            end
        end
        debug.profileend()

        debug.profilebegin(PROFILE_TAGS.CLEANUP)
        for i = #removeInstances, 1, -1 do
            local instIndex = removeInstances[i]
            local instance = instances[instIndex]
            if instance.OnEnd then
                instance.OnEnd()
            end
            table.remove(instances, instIndex)
            removeInstances[i] = nil
        end
        debug.profileend()

        debug.profilebegin(PROFILE_TAGS.EFFECTS)
        local maxChromatic = 0
        local maxBlur = 0
        local maxMotionBlur = 0
        local maxDistortion = 0
        local maxVignette = 0
        local maxColorShift = 0
        local maxSaturation = 0
        local maxBrightness = 0
        local colorShiftColor = Color3.new(1, 1, 1)

        for _, instance in instances do
            if instance:GetState() ~= ShakeState.Inactive then
                local intensity = instance._currentFadeTime
                maxChromatic = math.max(maxChromatic, instance.ChromaticAberration * intensity)
                maxBlur = math.max(maxBlur, instance.RadialBlur * intensity)
                maxMotionBlur = math.max(maxMotionBlur, instance.MotionBlur * intensity)
                maxDistortion = math.max(maxDistortion, instance.DistortionEffect * intensity)
                maxVignette = math.max(maxVignette, instance.Vignette * intensity)
                maxColorShift = math.max(maxColorShift, instance.ColorShiftIntensity * intensity)
                maxSaturation = math.max(maxSaturation, instance.Saturation * intensity)
                maxBrightness = math.max(maxBrightness, instance.Brightness * intensity)

                if instance.ColorShiftIntensity * intensity > 0 then
                    colorShiftColor = colorShiftColor:Lerp(instance.ColorShift, instance.ColorShiftIntensity * intensity)
                end
            end
        end

        if maxChromatic > 0 then
            self._effects.chromaticAberration.Enabled = true
            self._effects.chromaticAberration.Saturation = -maxChromatic
            self._effects.chromaticAberration.Contrast = maxChromatic
        else
            self._effects.chromaticAberration.Enabled = false
        end

        if maxBlur > 0 then
            self._effects.radialBlur.Enabled = true
            self._effects.radialBlur.Size = maxBlur * 24
        else
            self._effects.radialBlur.Enabled = false
        end

        if maxMotionBlur > 0 then
            self._effects.motionBlur.Enabled = true
            self._effects.motionBlur.Size = maxMotionBlur * 12
        else
            self._effects.motionBlur.Enabled = false
        end

        if maxDistortion > 0 then
            self._effects.distortion.Enabled = true
            self._effects.distortion.FarIntensity = maxDistortion
            self._effects.distortion.NearIntensity = maxDistortion * 0.5
        else
            self._effects.distortion.Enabled = false
        end

        if maxVignette > 0 then
            self._effects.vignette.Enabled = true
            self._effects.vignette.Brightness = -maxVignette * 0.5
            self._effects.vignette.Contrast = maxVignette
        else
            self._effects.vignette.Enabled = false
        end

        if maxColorShift > 0 then
            self._effects.colorShift.Enabled = true
            self._effects.colorShift.TintColor = colorShiftColor
            self._effects.colorShift.Saturation = maxSaturation
            self._effects.colorShift.Brightness = maxBrightness
        else
            self._effects.colorShift.Enabled = false
        end
        debug.profileend()

        debug.profilebegin(PROFILE_TAGS.TRANSFORM)
        local rotY = math.rad(rotAddShake.Y)
        local rotX = math.rad(rotAddShake.X)
        local rotZ = math.rad(rotAddShake.Z)

        if fovAddShake ~= 0 then
            workspace.CurrentCamera.FieldOfView = self._baseFieldOfView + fovAddShake
        end

        local result = CFrame.new(posAddShake) *
            CFrame.Angles(0, rotY, 0) *
            CFrame.Angles(rotX, 0, rotZ)
        debug.profileend()

        return result
    end

    function self:ClearShakes(category: string?)
        local instances = self._shakeInstances
        for i = #instances, 1, -1 do
            local instance = instances[i]
            if not category or instance.Category == category then
                if instance.OnEnd then
                    instance.OnEnd()
                end
                table.remove(instances, i)
            end
        end
    end

    function self:ShakeOnce(config: ShakeConfig): ShakeInstance
        if config.Category and config.Category ~= ShakeCategory.None then
            self:ClearShakes(config.Category)
        end

        local instance = createShakeInstance(config)
        table.insert(self._shakeInstances, instance)
        return instance
    end

    function self:ShakeSustain(config: ShakeConfig): ShakeInstance
        if config.Category and config.Category ~= ShakeCategory.None then
            self:ClearShakes(config.Category)
        end

        local instance = createShakeInstance(config)
        instance:StartFadeIn(config.FadeInTime)
        table.insert(self._shakeInstances, instance)
        return instance
    end

    function self:StopSustained(duration: number?)
        for _, instance in self._shakeInstances do
            if instance._fadeOutDuration == 0 then
                instance:StartFadeOut(duration or instance._fadeInDuration)
            end
        end
    end

    function self:Pause()
        if self._paused then return end

        self._paused = true
        self._pausedStates = {}

        for i, instance in ipairs(self._shakeInstances) do
            self._pausedStates[i] = {
                currentFadeTime = instance._currentFadeTime,
                tick = instance._tick,
                trauma = instance.Trauma,
                state = instance:GetState()
            }
        end

        workspace.CurrentCamera.FieldOfView = self._baseFieldOfView

        for _, effect in pairs(self._effects) do
            effect.Enabled = false
        end

        self._lastUpdateTime = os.clock()
    end

    function self:Resume()
        if not self._paused then return end

        self._paused = false

        local currentTime = os.clock()
        local pauseDuration = currentTime - self._lastUpdateTime
        self._lastUpdateTime = currentTime

        for i, instance in ipairs(self._shakeInstances) do
            local pausedState = self._pausedStates[i]
            if pausedState then
                instance._currentFadeTime = pausedState.currentFadeTime
                instance._tick = pausedState.tick
                instance.Trauma = pausedState.trauma

                if instance._sustain and pausedState.state == ShakeState.FadingIn then
                    instance._fadeInDuration += pauseDuration
                elseif not instance._sustain and pausedState.state == ShakeState.FadingOut then
                    instance._fadeOutDuration += pauseDuration
                end
            end
        end

        self._pausedStates = {}
    end

    function self:IsPaused(): boolean
        return self._paused
    end

    function self:TogglePause(): boolean
        if self._paused then
            self:Resume()
        else
            self:Pause()
        end
        return self._paused
    end

    return self
end

function Shake.GetPreset(presetName: string): ShakeConfig
    local preset = ShakePresets[presetName]
    if not preset then
        error(string.format('No shake preset found with name "%s"', presetName))
    end
    return table.clone(preset)
end

return Shake