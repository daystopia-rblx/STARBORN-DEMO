--[[ WeatherService
    @author Daystopia
    @version 1.0.0
    @updated 2025-04-10
]]
local WeatherService = {}

--[[ Dependencies ]]
WeatherService.Dependencies = {
    "Event",
    "Audio"
}

--[[ Events ]]
WeatherService.Events = {
    Update = true
}

--[[ Constants ]]
WeatherService.CONSTANTS = {
    TYPES = {
        CLEAR = "Clear",
        SUNNY = "Sunny",
        CLOUDY = "Cloudy",
        RAIN = "Rain",
        THUNDERSTORM = "Thunderstorm",
        SNOW = "Snow",
        FOG = "Fog",
        WINDY = "Windy",
        ASHFALL = "Ashfall"
    },
    DEFAULT_TRANSITION_TIME = 10,
    PARTICLE_EFFECTS = {
        CLEAR = {},
        SUNNY = { "SunRaysEmitter", "WindEmitter" },
        CLOUDY = { "WindEmitter" },
        RAIN = { "RainEmitter", "SplashEmitter", "WindEmitter" },
        THUNDERSTORM = { "RainEmitter", "SplashEmitter", "LightningEmitter", "WindEmitter" },
        SNOW = { "SnowEmitter", "WindEmitter" },
        FOG = { "FogEmitter", "WindEmitter" },
        WINDY = { "WindEmitter" },
        ASHFALL = { "AshEmitter", "WindEmitter" }
    }
}

--[[ Types ]]
type WeatherCondition = {
    type: string,
    intensity: number
}

type WeatherTransition = {
    from: WeatherCondition,
    to: WeatherCondition,
    progress: number,
    duration: number,
    startTime: number
}

--[[ Services & Modules ]]
local Services
local Modules
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:WaitForChild("Terrain")

--[[ State ]]
local state = {
    currentWeather = { type = WeatherService.CONSTANTS.TYPES.CLEAR, intensity = 0 } :: WeatherCondition,
    transition = nil :: WeatherTransition?,
    activeParticles = {} :: {[string]: Instance},
    activeSounds = {} :: {[string]: any}
}

--[[ Private Functions ]]
local function lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

local function StopSounds()
    for name, handle in pairs(state.activeSounds) do
        state.activeSounds[name] = nil
    end
    table.clear(state.activeSounds)
end

local function StopParticles()
    for name, emitter in pairs(state.activeParticles) do
        if emitter and emitter:IsA("ParticleEmitter") then
            emitter.Enabled = false
        end
    end
    table.clear(state.activeParticles)
end

local function StartSounds(weatherType: string, intensity: number)
    StopSounds()

    local soundMapping = {
        [WeatherService.CONSTANTS.TYPES.RAIN] = "RainSound",
        [WeatherService.CONSTANTS.TYPES.THUNDERSTORM] = "ThunderstormSound",
        [WeatherService.CONSTANTS.TYPES.SNOW] = "SnowSound",
        [WeatherService.CONSTANTS.TYPES.WINDY] = "WindSound"
    }

    if weatherType == WeatherService.CONSTANTS.TYPES.WINDY or intensity > 0.5 then
        local windSoundName = soundMapping[WeatherService.CONSTANTS.TYPES.WINDY]
        if windSoundName and not state.activeSounds[WeatherService.CONSTANTS.TYPES.WINDY] then
            state.activeSounds[WeatherService.CONSTANTS.TYPES.WINDY] = Services.Audio:PlaySound(Workspace, "SFX." .. windSoundName, { Looped = true, Volume = intensity })
        end
    end

    local soundName = soundMapping[weatherType]
    if soundName then
        state.activeSounds[weatherType] = Services.Audio:PlaySound(Workspace, "SFX." .. soundName, { Looped = true, Volume = intensity })
    end

    if weatherType == WeatherService.CONSTANTS.TYPES.THUNDERSTORM and not state.activeSounds["Thunder"] then
        state.activeSounds["Thunder"] = Services.Audio:PlaySound(Workspace, "SFX.ThunderSoundEffect", { Looped = true, Volume = intensity })
    end
end

local function StartParticles(weatherType: string, intensity: number)
    StopParticles()

    local validWeatherType = weatherType
    if type(weatherType) ~= "string" then
        validWeatherType = WeatherService.CONSTANTS.TYPES.CLEAR
    end

    local effectConfig = WeatherService.CONSTANTS.PARTICLE_EFFECTS[validWeatherType]
    if not effectConfig then
        return
    end

    if #effectConfig == 0 then
        return
    end

    local world = Workspace:FindFirstChild("World")
    if not world then
        return
    end

    local shouldEnableWind = intensity > 0.5

    for _, emitterName in ipairs(effectConfig) do
        local emitter = world:FindFirstChild(emitterName, true)
        if emitter and emitter:IsA("ParticleEmitter") then
            if emitterName == "WindEmitter" then
                emitter.Enabled = shouldEnableWind
            else
                emitter.Enabled = true
            end
            state.activeParticles[emitterName] = emitter
        end
    end
end

local function LerpCondition(from: WeatherCondition, to: WeatherCondition, alpha: number): WeatherCondition
    return {
        type = alpha < 0.5 and from.type or to.type,
        intensity = lerp(from.intensity, to.intensity, alpha)
    }
end

local function UpdateAtmosphere(condition: WeatherCondition)
    local atmosphere = Lighting:FindFirstChild("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "Atmosphere"
    atmosphere.Parent = Lighting

    local density = 0.3
    local haze = 0.1
    local color = Color3.fromRGB(255, 255, 255)
    local decay = Color3.fromRGB(90, 90, 90)
    local glare = 0

    local intensity = condition.intensity

    if condition.type == WeatherService.CONSTANTS.TYPES.CLEAR or condition.type == WeatherService.CONSTANTS.TYPES.SUNNY then
        density = lerp(0.3, 0.1, intensity)
        haze = lerp(0.1, 0.0, intensity)
        glare = lerp(0, 0.3, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.CLOUDY then
        density = lerp(0.3, 0.5, intensity)
        haze = lerp(0.1, 0.6, intensity)
        color = Color3.fromRGB(200, 200, 200):Lerp(Color3.fromRGB(150, 150, 155), intensity)
        decay = Color3.fromRGB(120, 120, 120):Lerp(Color3.fromRGB(80, 80, 85), intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.RAIN then
        density = lerp(0.3, 0.6, intensity)
        haze = lerp(0.1, 0.7, intensity)
        color = Color3.fromRGB(180, 180, 185):Lerp(Color3.fromRGB(100, 100, 110), intensity)
        decay = Color3.fromRGB(100, 100, 105):Lerp(Color3.fromRGB(50, 50, 55), intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.THUNDERSTORM then
        density = lerp(0.4, 0.8, intensity)
        haze = lerp(0.2, 0.9, intensity)
        color = Color3.fromRGB(120, 120, 130):Lerp(Color3.fromRGB(60, 60, 70), intensity)
        decay = Color3.fromRGB(80, 80, 90):Lerp(Color3.fromRGB(30, 30, 40), intensity)
        glare = lerp(0, 0.1, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.SNOW then
        density = lerp(0.3, 0.6, intensity)
        haze = lerp(0.1, 0.7, intensity)
        color = Color3.fromRGB(220, 220, 230):Lerp(Color3.fromRGB(190, 190, 200), intensity)
        decay = Color3.fromRGB(150, 150, 160):Lerp(Color3.fromRGB(120, 120, 130), intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.FOG then
        density = lerp(0.3, 0.95, intensity)
        haze = lerp(0.1, 0.9, intensity)
        color = Color3.fromRGB(200, 200, 200):Lerp(Color3.fromRGB(170, 170, 170), intensity)
        decay = Color3.fromRGB(180, 180, 180):Lerp(Color3.fromRGB(150, 150, 150), intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.ASHFALL then
        density = lerp(0.3, 0.7, intensity)
        haze = lerp(0.1, 0.8, intensity)
        color = Color3.fromRGB(150, 140, 130):Lerp(Color3.fromRGB(100, 90, 80), intensity)
        decay = Color3.fromRGB(100, 95, 90):Lerp(Color3.fromRGB(60, 55, 50), intensity)
        glare = lerp(0, 0.1, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.WINDY then
        density = lerp(0.3, 0.35, intensity)
        haze = lerp(0.1, 0.15, intensity)
    end

    atmosphere.Density = density
    atmosphere.Haze = haze
    atmosphere.Color = color
    atmosphere.Decay = decay
    atmosphere.Glare = glare
end

local function UpdateClouds(condition: WeatherCondition)
    local clouds = Terrain:FindFirstChild("Clouds") or Instance.new("Clouds")
    clouds.Name = "Clouds"
    clouds.Parent = Terrain

    local cover = 0
    local density = 0

    local intensity = condition.intensity

    if condition.type == WeatherService.CONSTANTS.TYPES.CLEAR then
        cover = 0
        density = 0
    elseif condition.type == WeatherService.CONSTANTS.TYPES.SUNNY then
        cover = lerp(0, 0.2, intensity)
        density = lerp(0, 0.1, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.CLOUDY then
        cover = lerp(0.2, 1.0, intensity)
        density = lerp(0.1, 0.7, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.RAIN or condition.type == WeatherService.CONSTANTS.TYPES.THUNDERSTORM or condition.type == WeatherService.CONSTANTS.TYPES.SNOW then
        cover = lerp(0.5, 1.0, intensity)
        density = lerp(0.4, 0.8, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.FOG then
        cover = lerp(0.1, 0.5, intensity)
        density = lerp(0.1, 0.3, intensity)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.ASHFALL then
        cover = lerp(0.2, 0.8, intensity)
        density = lerp(0.1, 0.6, intensity)
         clouds.Color = Color3.fromRGB(100, 90, 80)
    elseif condition.type == WeatherService.CONSTANTS.TYPES.WINDY then
         cover = lerp(0.1, 0.4, intensity)
         density = lerp(0.05, 0.2, intensity)
    end

    clouds.Cover = cover
    clouds.Density = density
    clouds.Enabled = cover > 0 or density > 0

    if condition.type ~= WeatherService.CONSTANTS.TYPES.ASHFALL then
         clouds.Color = Color3.fromRGB(255, 255, 255)
    end
     if condition.type == WeatherService.CONSTANTS.TYPES.THUNDERSTORM then
        clouds.Color = Color3.fromRGB(80, 80, 90):Lerp(Color3.fromRGB(40, 40, 50), intensity)
     end
end

local function UpdateWeather()
    local currentCondition = state.currentWeather

    if state.transition then
        local now = os.time()
        local alpha = math.clamp((now - state.transition.startTime) / state.transition.duration, 0, 1)

        currentCondition = LerpCondition(
            state.transition.from,
            state.transition.to,
            alpha
        )

        if alpha >= 1 then
            state.currentWeather = state.transition.to
            state.transition = nil
            StartParticles(state.currentWeather.type, state.currentWeather.intensity)
            StartSounds(state.currentWeather.type, state.currentWeather.intensity)
            Services.Event:Fire("Weather.Update", state.currentWeather)
        else
            Services.Event:Fire("Weather.Update", currentCondition)
        end
    else
        StartParticles(state.currentWeather.type, state.currentWeather.intensity)
        StartSounds(state.currentWeather.type, state.currentWeather.intensity)
    end

    UpdateAtmosphere(currentCondition)
    UpdateClouds(currentCondition)
end

--[[ Core Functions ]]
function WeatherService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function WeatherService:Start()
    StartParticles(state.currentWeather.type, state.currentWeather.intensity)
    StartSounds(state.currentWeather.type, state.currentWeather.intensity)
    Services.Event:Fire("Weather.Update", state.currentWeather)

    RunService.Heartbeat:Connect(function()
        UpdateWeather()
    end)

    return true
end

function WeatherService:Cleanup()
    StopParticles()
    StopSounds()
end

--[[ Weather Functions ]]
function WeatherService:SetWeather(weatherTypeName: string, intensity: number?, transitionTime: number?): boolean
    local upperType = weatherTypeName:upper()
    local targetType = nil

    for key, value in pairs(WeatherService.CONSTANTS.TYPES) do
        if key == upperType or value:upper() == upperType then
            targetType = value
            break
        end
    end

    if not targetType then
        warn("Invalid weather type:", weatherTypeName)
        return false
    end

    local targetIntensity = math.clamp(intensity or 0.5, 0, 1)
    local duration = transitionTime or WeatherService.CONSTANTS.DEFAULT_TRANSITION_TIME

    if state.currentWeather.type == targetType and state.currentWeather.intensity == targetIntensity then
        return true
    end

    state.transition = {
        from = table.clone(state.currentWeather),
        to = { type = targetType, intensity = targetIntensity },
        progress = 0,
        duration = duration,
        startTime = os.time()
    }

    StopParticles()
    StopSounds()

    return true
end

--[[ Getter Functions ]]
function WeatherService:GetWeather(): WeatherCondition
    if state.transition then
        return state.transition.to
    end
    return state.currentWeather
end

return WeatherService