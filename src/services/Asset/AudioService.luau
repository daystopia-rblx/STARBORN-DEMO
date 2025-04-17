--[[ AudioService
    Advanced audio system with pooling, spatial audio, and category management.
    Handles sound playback, effects, and optimized resource utilization.
    @author @Daystopia
    @version 1.0.5
    @date 2025-03-22
]]
local AudioService = {}

--[[ Dependencies ]]
AudioService.Dependencies = {
    "Event",
    "Asset"
}

--[[ Modules ]]
AudioService.Modules = {
    "Sound"
}

--[[ Events ]]
AudioService.Events = {
    Play = true,
    Stop = true,
    Pause = true,
    Resume = true
}

--[[ Services & Modules ]]
local Services
local Modules
local Workspace = game:GetService("Workspace")

--[[ Constants ]]
local CONSTANTS = {
    DEFAULT_VOLUME = 0.5,
    DEFAULT_SPEED = 1,
    FADE_TIME = 0.3,
    MAX_DISTANCE = 100,
    POOL_SIZE = {
        MIN = 5,
        MAX = 20
    },
    CATEGORIES = {
        SFX = "SFX",
        AMBIENT = "Ambient",
        UI = "UI",
        MUSIC = "Music"
    },
    VOLUME_MULTIPLIERS = {
        MASTER = 1,
        SFX = 1,
        AMBIENT = 1,
        UI = 1,
        MUSIC = 1
    },
    MAX_RETRIES = 3,
    RETRY_DELAY = 1
}

--[[ Types ]]
type SoundConfig = {
    preset: string?,
    id: string?,
    volume: number?,
    speed: number?,
    loop: boolean?,
    spatial: boolean?,
    distance: number?,
    category: string?,
    parent: boolean?,
    audio: boolean?,
    effects: {
        analyzer: {
            FFTSize: number?,
            SmoothingTimeConstant: number?
        }?,
        channelMixer: {
            Gain: {number}?,
            Layout: string?
        }?,
        channelSplitter: {
            Layout: string?
        }?,
        chorus: {
            Mix: number?,
            Rate: number?,
            Depth: number?
        }?,
        compressor: {
            Threshold: number?,
            Knee: number?,
            Ratio: number?,
            Attack: number?,
            Release: number?
        }?,
        deviceInput: {
            Player: Instance?,
            Muted: boolean?
        }?,
        deviceOutput: {
            Device: string?
        }?,
        distortion: {
            Level: number?
        }?,
        echo: {
            Delay: number?,
            Feedback: number?,
            WetLevel: number?,
            DryLevel: number?
        }?,
        emitter: {
            Position: Vector3?,
            Orientation: Vector3?
        }?,
        equalizer: {
            HighGain: number?,
            MidGain: number?,
            LowGain: number?
        }?,
        fader: {
            FadeInTime: number?,
            FadeOutTime: number?
        }?,
        filter: {
            Type: string?,
            Frequency: number?,
            Resonance: number?
        }?,
        flange: {
            Mix: number?,
            Depth: number?,
            Rate: number?
        }?,
        limiter: {
            Threshold: number?,
            Attack: number?,
            Release: number?
        }?,
        listener: {
            Position: Vector3?,
            Orientation: Vector3?
        }?,
        pitch: {
            Octave: number?
        }?,
        player: {
            AssetId: string?,
            Looped: boolean?,
            PlaybackSpeed: number?
        }?,
        reverb: {
            DecayTime: number?,
            Density: number?,
            Diffusion: number?,
            WetLevel: number?,
            DryLevel: number?
        }?,
        textToSpeech: {
            Text: string?,
            Voice: string?
        }?,
        tremolo: {
            Depth: number?,
            Frequency: number?,
            Duty: number?
        }?
    }?
}

type SoundPath = {string}

--[[ State ]]
local state = {
    playing = {},
    pools = {},
    paused = {},
    timePositions = {}
}

--[[ Core Functions ]]
function AudioService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function AudioService:Cleanup()
    for sound in pairs(state.playing) do
        sound:Stop()
        sound:Destroy()
    end

    for sound in pairs(state.paused) do
        sound:Stop()
        sound:Destroy()
    end

    for _, pool in pairs(state.pools) do
        for _, sound in ipairs(pool.available) do
            sound:Destroy()
        end
    end

    table.clear(state.playing)
    table.clear(state.paused)
    table.clear(state.timePositions)
    table.clear(state.pools)
end

--[[ Helper Functions ]]
local function ReleaseSound(sound, category)
    local pool = state.pools[category]
    if not pool then return end

    if sound.IsPlaying then
        sound:Stop()
    end

    if sound.Parent then
        sound.TimePosition = 0
        sound.Parent = nil
    end

    if #pool.available < CONSTANTS.POOL_SIZE.MAX then
        sound.Volume = CONSTANTS.DEFAULT_VOLUME
        sound.PlaybackSpeed = CONSTANTS.DEFAULT_SPEED
        sound.Looped = false
        sound.RollOffMode = Enum.RollOffMode.Inverse
        table.insert(pool.available, sound)
    else
        sound:Destroy()
        pool.size -= 1
    end
end

local function GetSound(config)
    local category = config.category or CONSTANTS.CATEGORIES.SFX
    local pool = state.pools[category]

    if not pool then
        pool = {
            available = table.create(CONSTANTS.POOL_SIZE.MIN),
            size = 0
        }
        state.pools[category] = pool
    end

    local sound
    if #pool.available > 0 then
        sound = table.remove(pool.available)
        if sound and sound.Parent then
            sound:Stop()
            sound.TimePosition = 0
            sound.Parent = nil

            for _, effect in ipairs(sound:GetChildren()) do
                if effect:IsA("SoundEffect") then
                    effect:Destroy()
                end
            end
        end
    end

    if not sound or not sound.IsA or not sound:IsA("Sound") then
        if pool.size >= CONSTANTS.POOL_SIZE.MAX then
            return nil
        end

        local success, result = pcall(function()
            if config.preset then
                local presetData = Services.Asset:GetAsset("Sounds", config.preset, "Sound")
                if not presetData then return nil end
                return presetData.instance:Clone()
            else
                return Instance.new("Sound")
            end
        end)

        if not success or not result then
            warn("Failed to create sound:", result)
            return nil
        end

        sound = result
        pool.size += 1
    end

    local success, err = pcall(function()
        if config.id then
            sound.SoundId = config.id
            pcall(function()
                sound:LoadAsync()
            end)
        end

        sound.Volume = config.volume or CONSTANTS.DEFAULT_VOLUME
        sound.PlaybackSpeed = config.speed or CONSTANTS.DEFAULT_SPEED
        sound.Looped = config.loop or false
        sound.TimePosition = 0

        if config.spatial then
            sound.RollOffMode = Enum.RollOffMode.InverseTapered
            sound.RollOffMinDistance = math.min(10, config.distance and config.distance * 0.2 or 10)
            sound.RollOffMaxDistance = config.distance or CONSTANTS.MAX_DISTANCE
        else
            sound.RollOffMode = Enum.RollOffMode.Inverse
        end

        if config.audio then
            if config.effects.analyzer then
                local analyzer = Instance.new("AudioAnalyzer")
                analyzer.FFTSize = config.effects.analyzer.FFTSize or 2048
                analyzer.SmoothingTimeConstant = config.effects.analyzer.SmoothingTimeConstant or 0.8
                analyzer.Parent = sound
            end

            if config.effects.channelMixer then
                local mixer = Instance.new("AudioChannelMixer")
                mixer.Gain = config.effects.channelMixer.Gain or {1, 1}
                mixer.Layout = config.effects.channelMixer.Layout or "Stereo"
                mixer.Parent = sound
            end

            if config.effects.channelSplitter then
                local splitter = Instance.new("AudioChannelSplitter")
                splitter.Layout = config.effects.channelSplitter.Layout or "Stereo"
                splitter.Parent = sound
            end

            if config.effects.compressor then
                local compressor = Instance.new("AudioCompressor")
                compressor.Threshold = config.effects.compressor.Threshold or -24
                compressor.Knee = config.effects.compressor.Knee or 30
                compressor.Ratio = config.effects.compressor.Ratio or 12
                compressor.Attack = config.effects.compressor.Attack or 0.003
                compressor.Release = config.effects.compressor.Release or 0.25
                compressor.Parent = sound
            end

            if config.effects.deviceInput then
                local input = Instance.new("AudioDeviceInput")
                input.Player = config.effects.deviceInput.Player
                input.Muted = config.effects.deviceInput.Muted or false
                input.Parent = sound
            end

            if config.effects.deviceOutput then
                local output = Instance.new("AudioDeviceOutput")
                if config.effects.deviceOutput.Device then
                    output.Device = config.effects.deviceOutput.Device
                end
                output.Parent = sound
            end

            if config.effects.emitter then
                local emitter = Instance.new("AudioEmitter")
                if config.effects.emitter.Position then
                    emitter.Position = config.effects.emitter.Position
                end
                if config.effects.emitter.Orientation then
                    emitter.Orientation = config.effects.emitter.Orientation
                end
                emitter.Parent = sound
            end

            if config.effects.fader then
                local fader = Instance.new("AudioFader")
                fader.FadeInTime = config.effects.fader.FadeInTime or 1
                fader.FadeOutTime = config.effects.fader.FadeOutTime or 1
                fader.Parent = sound
            end

            if config.effects.filter then
                local filter = Instance.new("AudioFilter")
                filter.Type = config.effects.filter.Type or "LowPass"
                filter.Frequency = config.effects.filter.Frequency or 2000
                filter.Resonance = config.effects.filter.Resonance or 1
                filter.Parent = sound
            end

            if config.effects.limiter then
                local limiter = Instance.new("AudioLimiter")
                limiter.Threshold = config.effects.limiter.Threshold or -3
                limiter.Attack = config.effects.limiter.Attack or 0.001
                limiter.Release = config.effects.limiter.Release or 0.1
                limiter.Parent = sound
            end

            if config.effects.listener then
                local listener = Instance.new("AudioListener")
                if config.effects.listener.Position then
                    listener.Position = config.effects.listener.Position
                end
                if config.effects.listener.Orientation then
                    listener.Orientation = config.effects.listener.Orientation
                end
                listener.Parent = sound
            end

            if config.effects.player then
                local player = Instance.new("AudioPlayer")
                if config.effects.player.AssetId then
                    player.Asset = config.effects.player.AssetId
                end
                player.Looped = config.effects.player.Looped or false
                player.PlaybackSpeed = config.effects.player.PlaybackSpeed or 1
                player.Parent = sound
            end

            if config.effects.textToSpeech then
                local tts = Instance.new("AudioTextToSpeech")
                tts.Text = config.effects.textToSpeech.Text or ""
                if config.effects.textToSpeech.Voice then
                    tts.Voice = config.effects.textToSpeech.Voice
                end
                tts.Parent = sound
            end
        end

        if config.effects then
            for _, effect in ipairs(sound:GetChildren()) do
                if effect:IsA("SoundEffect") then
                    effect:Destroy()
                end
            end

            if config.effects.chorus then
                local chorus = Instance.new("ChorusSoundEffect")
                chorus.Mix = config.effects.chorus.Mix or 0.5
                chorus.Rate = config.effects.chorus.Rate or 0.5
                chorus.Depth = config.effects.chorus.Depth or 0.15
                chorus.Parent = sound
            end

            if config.effects.distortion then
                local distortion = Instance.new("DistortionSoundEffect")
                distortion.Level = config.effects.distortion.Level or 0.1
                distortion.Parent = sound
            end

            if config.effects.echo then
                local echo = Instance.new("EchoSoundEffect")
                echo.Delay = config.effects.echo.Delay or 1
                echo.Feedback = config.effects.echo.Feedback or 0.5
                echo.WetLevel = config.effects.echo.WetLevel or 0
                echo.DryLevel = config.effects.echo.DryLevel or 0
                echo.Parent = sound
            end

            if config.effects.equalizer then
                local equalizer = Instance.new("EqualizerSoundEffect")
                equalizer.HighGain = config.effects.equalizer.HighGain or 0
                equalizer.MidGain = config.effects.equalizer.MidGain or 0
                equalizer.LowGain = config.effects.equalizer.LowGain or 0
                equalizer.Parent = sound
            end

            if config.effects.flange then
                local flange = Instance.new("FlangeSoundEffect")
                flange.Mix = config.effects.flange.Mix or 0.85
                flange.Depth = config.effects.flange.Depth or 0.45
                flange.Rate = config.effects.flange.Rate or 5.0
                flange.Parent = sound
            end

            if config.effects.pitch then
                local pitch = Instance.new("PitchShiftSoundEffect")
                pitch.Octave = config.effects.pitch.Octave or 1.0
                pitch.Parent = sound
            end

            if config.effects.reverb then
                local reverb = Instance.new("ReverbSoundEffect")
                reverb.DecayTime = config.effects.reverb.DecayTime or 1.5
                reverb.Density = config.effects.reverb.Density or 1.0
                reverb.Diffusion = config.effects.reverb.Diffusion or 1.0
                reverb.WetLevel = config.effects.reverb.WetLevel or 0.0
                reverb.DryLevel = config.effects.reverb.DryLevel or -6.0
                reverb.Parent = sound
            end

            if config.effects.tremolo then
                local tremolo = Instance.new("TremoloSoundEffect")
                tremolo.Depth = config.effects.tremolo.Depth or 1.0
                tremolo.Frequency = config.effects.tremolo.Frequency or 5.0
                tremolo.Duty = config.effects.tremolo.Duty or 0.5
                tremolo.Parent = sound
            end
        end

        return true
    end)

    if not success then
        warn("Failed to configure sound:", err)
        ReleaseSound(sound, category)
        return nil
    end

    return sound
end

local function GetFolder(category: string): Folder
    local runtime = Workspace:FindFirstChild("Runtime")
    if not runtime then
        runtime = Instance.new("Folder")
        runtime.Name = "Runtime"
        runtime.Parent = Workspace
    end

    local sounds = runtime:FindFirstChild("Sounds")
    if not sounds then
        sounds = Instance.new("Folder")
        sounds.Name = "Sounds"
        sounds.Parent = runtime
    end

    local categoryFolder = sounds:FindFirstChild(category)
    if not categoryFolder then
        categoryFolder = Instance.new("Folder")
        categoryFolder.Name = category
        categoryFolder.Parent = sounds
    end

    return categoryFolder
end

--[[ Control Functions ]]
function AudioService:PlaySound(parent: Instance, soundPath: SoundPath | string | SoundConfig, config: SoundConfig?)
    if not parent then return end

    local finalConfig
    if type(soundPath) == "table" and (soundPath.id or soundPath.preset) then
        finalConfig = soundPath
    else
        local path = if type(soundPath) == "string" then string.split(soundPath, ".") else soundPath
        local soundData = Modules.Sound.Assets.Sounds
        for _, key in path do
            if not soundData then return end
            soundData = soundData[key]
        end
        if not soundData then return end

        finalConfig = {
            id = soundData.id,
            volume = soundData.volume,
            category = path[1] or CONSTANTS.CATEGORIES.SFX,
            parent = true
        }

        if config then
            for k, v in config do
                finalConfig[k] = v
            end
        end
    end

    if finalConfig.randomPitch then
        finalConfig.effects = finalConfig.effects or {}
        finalConfig.effects.equalizer = {
            HighGain = math.random(-5, 5),
            MidGain = math.random(-5, 5),
            LowGain = math.random(-5, 5)
        }
    end

    local repeatCount = finalConfig.repeatCount or 1
    if repeatCount < 1 then repeatCount = 1 end

    local sound = GetSound(finalConfig)
    if not sound then
        local category = finalConfig.category or CONSTANTS.CATEGORIES.SFX
        local oldestSound
        local oldestTime = math.huge

        for playingSound, soundCategory in pairs(state.playing) do
            if soundCategory == category and playingSound.TimePosition > oldestTime then
                oldestSound = playingSound
                oldestTime = playingSound.TimePosition
            end
        end

        if oldestSound then
            self:StopSound(oldestSound)
            sound = GetSound(finalConfig)
        end
    end
    if not sound then return end

    local category = finalConfig.category or CONSTANTS.CATEGORIES.SFX
    if finalConfig.parent then
        if finalConfig.spatial and parent:IsA("Model") then
            sound.Parent = parent.PrimaryPart or parent:FindFirstChild("Root") or parent:FindFirstChildWhichIsA("BasePart") or parent
        else
            sound.Parent = parent
        end
    else
        local categoryFolder = GetFolder(category)
        sound.Parent = categoryFolder
    end

    state.playing[sound] = category

    local playCount = 0
    local connection
    local function repeatSound()
        playCount += 1
        if playCount < repeatCount then
            sound.TimePosition = 0
            sound:Play()
        else
            connection:Disconnect()
            if state.playing[sound] then
                state.playing[sound] = nil
                ReleaseSound(sound, category)
            end
        end
    end

    connection = sound.Ended:Connect(repeatSound)

    if finalConfig.fadeIn then
        sound.Volume = 0
        sound:Play()
        game:GetService("TweenService"):Create(
            sound,
            TweenInfo.new(finalConfig.fadeIn),
            {Volume = finalConfig.volume or CONSTANTS.DEFAULT_VOLUME}
        ):Play()
    else
        sound:Play()
    end

    if Services and Services.Event then
        Services.Event:Fire("Audio.Play", sound.Name, category)
    end

    if sound then
        sound:SetAttribute("BaseVolume", sound.Volume)
        local categoryMultiplier = CONSTANTS.VOLUME_MULTIPLIERS[category] or 1
        local masterMultiplier = CONSTANTS.VOLUME_MULTIPLIERS.MASTER or 1
        sound.Volume = sound.Volume * categoryMultiplier * masterMultiplier
    end

    return sound
end

function AudioService:PauseSound(sound: Sound)
    if not sound or not state.playing[sound] then return end

    local category = state.playing[sound]
    state.paused[sound] = category
    state.timePositions[sound] = sound.TimePosition
    sound:Pause()

    if Services and Services.Event then
        Services.Event:Fire("Audio.Pause", sound.Name, category)
    end
end

function AudioService:ResumeSound(sound: Sound)

    local category = state.paused[sound]
    state.paused[sound] = nil

    if state.timePositions[sound] then
        sound.TimePosition = state.timePositions[sound]
        state.timePositions[sound] = nil
    end

    sound:Resume()

    if Services and Services.Event then
        Services.Event:Fire("Audio.Resume", sound.Name, category)
    end
end

function AudioService:StopSound(sound, fadeTime)
    if not sound then return end

    local category = state.playing[sound]
    if category then
        if fadeTime and fadeTime > 0 then
            local baseVolume = sound:GetAttribute("BaseVolume") or sound.Volume
            game:GetService("TweenService"):Create(
                sound,
                TweenInfo.new(fadeTime),
                {Volume = 0}
            ):Play()

            task.delay(fadeTime, function()
                if state.playing[sound] then
                    sound:Stop()
                    state.playing[sound] = nil
                    ReleaseSound(sound, category)
                end
            end)
        else
            sound:Stop()
            state.playing[sound] = nil
            ReleaseSound(sound, category)
        end

        if Services and Services.Event then
            Services.Event:Fire("Audio.Stop", sound.Name, category)
        end
    end
end

function AudioService:PauseCategory(category: string)
    for sound, soundCategory in pairs(state.playing) do
        if soundCategory == category and not state.paused[sound] then
            self:PauseSound(sound)
        end
    end
end

function AudioService:ResumeCategory(category: string)
    for sound, soundCategory in pairs(state.paused) do
        if soundCategory == category then
            self:ResumeSound(sound)
        end
    end
end

function AudioService:StopCategory(category)
    for sound, soundCategory in pairs(state.playing) do
        if soundCategory == category then
            self:StopSound(sound)
        end
    end
end

return AudioService