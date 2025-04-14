local Sound = {}

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--[[ Dependencies ]]
local Controllers = {
    Event = require(ReplicatedStorage.Controllers.Network.EventController)
}

local Modules = {
    Sound = require(ReplicatedStorage.Modules.SoundModule)
}

--[[ Constants ]]
local POOL_CONFIG = {
    MIN_SIZE = 5,
    MAX_SIZE = 20,
    CATEGORIES = {
        SFX = "SFX",
        UI = "UI",
        MUSIC = "Music",
        AMBIENT = "Ambient"
    }
}

--[[ State ]]
local state = {
    pools = {},
    playing = {},
    runtime = nil,
    monitors = {}
}

--[[ Helper Functions ]]
local function GetSoundFolder(category)
    if not state.runtime then
        state.runtime = Workspace:FindFirstChild("Runtime")
        if not state.runtime then
            state.runtime = Instance.new("Folder")
            state.runtime.Name = "Runtime"
            state.runtime.Parent = Workspace
        end

        local sounds = state.runtime:FindFirstChild("Sounds")
        if not sounds then
            sounds = Instance.new("Folder")
            sounds.Name = "Sounds"
            sounds.Parent = state.runtime
        end
    end

    local categoryFolder = state.runtime:FindFirstChild("Sounds"):FindFirstChild(category)
    if not categoryFolder then
        categoryFolder = Instance.new("Folder")
        categoryFolder.Name = category
        categoryFolder.Parent = state.runtime:FindFirstChild("Sounds")
    end

    return categoryFolder
end

local function GetFromPool(category)
    if not state.pools[category] then
        state.pools[category] = {
            available = {},
            size = 0
        }
    end

    local pool = state.pools[category]

    if #pool.available > 0 then
        local sound = table.remove(pool.available)
        if sound.Parent then
            sound:Stop()
            for _, effect in ipairs(sound:GetChildren()) do
                if effect:IsA("SoundEffect") then
                    effect:Destroy()
                end
            end
        end
        return sound
    end

    if pool.size >= POOL_CONFIG.MAX_SIZE then
        local oldestSound
        local oldestTime = 0
        for sound, data in pairs(state.playing) do
            if data.category == category and sound.TimePosition > oldestTime then
                oldestSound = sound
                oldestTime = sound.TimePosition
            end
        end

        if oldestSound then
            Sound.Stop(oldestSound)
            local sound = Instance.new("Sound")
            pool.size += 1
            return sound
        end
        return nil
    end

    local sound = Instance.new("Sound")
    pool.size += 1
    return sound
end

local function ReturnToPool(sound, category)
    if not state.pools[category] then return end

    local pool = state.pools[category]
    if #pool.available >= POOL_CONFIG.MAX_SIZE then
        sound:Destroy()
        pool.size -= 1
        return
    end

    sound:Stop()
    sound.TimePosition = 0
    sound.Volume = 1
    sound.PlaybackSpeed = 1
    sound.Looped = false

    for _, effect in ipairs(sound:GetChildren()) do
        if effect:IsA("SoundEffect") then
            effect:Destroy()
        end
    end

    if sound.Parent then
        sound.Parent = nil
    end

    table.insert(pool.available, sound)
end

local function AppleEffects(sound, effects)
    if not effects then return end

    if effects.analyzer then
        local analyzer = Instance.new("AudioAnalyzer")
        analyzer.FFTSize = effects.analyzer.FFTSize or 2048
        analyzer.SmoothingTimeConstant = effects.analyzer.SmoothingTimeConstant or 0.8
        analyzer.Parent = sound
    end

    if effects.channelMixer then
        local mixer = Instance.new("AudioChannelMixer")
        mixer.Gain = effects.channelMixer.Gain or {1, 1}
        mixer.Layout = effects.channelMixer.Layout or "Stereo"
        mixer.Parent = sound
    end

    if effects.channelSplitter then
        local splitter = Instance.new("AudioChannelSplitter")
        splitter.Layout = effects.channelSplitter.Layout or "Stereo"
        splitter.Parent = sound
    end

    if effects.compressor then
        local compressor = Instance.new("AudioCompressor")
        compressor.Threshold = effects.compressor.Threshold or -24
        compressor.Knee = effects.compressor.Knee or 30
        compressor.Ratio = effects.compressor.Ratio or 12
        compressor.Attack = effects.compressor.Attack or 0.003
        compressor.Release = effects.compressor.Release or 0.25
        compressor.Parent = sound
    end

    if effects.deviceInput then
        local input = Instance.new("AudioDeviceInput")
        input.Player = effects.deviceInput.Player
        input.Muted = effects.deviceInput.Muted or false
        input.Parent = sound
    end

    if effects.deviceOutput then
        local output = Instance.new("AudioDeviceOutput")
        if effects.deviceOutput.Device then
            output.Device = effects.deviceOutput.Device
        end
        output.Parent = sound
    end

    if effects.emitter then
        local emitter = Instance.new("AudioEmitter")
        if effects.emitter.Position then
            emitter.Position = effects.emitter.Position
        end
        if effects.emitter.Orientation then
            emitter.Orientation = effects.emitter.Orientation
        end
        emitter.Parent = sound
    end

    if effects.fader then
        local fader = Instance.new("AudioFader")
        fader.FadeInTime = effects.fader.FadeInTime or 1
        fader.FadeOutTime = effects.fader.FadeOutTime or 1
        fader.Parent = sound
    end

    if effects.filter then
        local filter = Instance.new("AudioFilter")
        filter.Type = effects.filter.Type or "LowPass"
        filter.Frequency = effects.filter.Frequency or 2000
        filter.Resonance = effects.filter.Resonance or 1
        filter.Parent = sound
    end

    if effects.limiter then
        local limiter = Instance.new("AudioLimiter")
        limiter.Threshold = effects.limiter.Threshold or -3
        limiter.Attack = effects.limiter.Attack or 0.001
        limiter.Release = effects.limiter.Release or 0.1
        limiter.Parent = sound
    end

    if effects.listener then
        local listener = Instance.new("AudioListener")
        if effects.listener.Position then
            listener.Position = effects.listener.Position
        end
        if effects.listener.Orientation then
            listener.Orientation = effects.listener.Orientation
        end
        listener.Parent = sound
    end

    if effects.player then
        local player = Instance.new("AudioPlayer")
        if effects.player.AssetId then
            player.Asset = effects.player.AssetId
        end
        player.Looped = effects.player.Looped or false
        player.PlaybackSpeed = effects.player.PlaybackSpeed or 1
        player.Parent = sound
    end

    if effects.textToSpeech then
        local tts = Instance.new("AudioTextToSpeech")
        tts.Text = effects.textToSpeech.Text or ""
        if effects.textToSpeech.Voice then
            tts.Voice = effects.textToSpeech.Voice
        end
        tts.Parent = sound
    end

    if effects.chorus then
        local chorus = Instance.new("ChorusSoundEffect")
        chorus.Mix = effects.chorus.Mix or 0.5
        chorus.Rate = effects.chorus.Rate or 0.5
        chorus.Depth = effects.chorus.Depth or 0.15
        chorus.Parent = sound
    end

    if effects.distortion then
        local distortion = Instance.new("DistortionSoundEffect")
        distortion.Level = effects.distortion.Level or 0.1
        distortion.Parent = sound
    end

    if effects.echo then
        local echo = Instance.new("EchoSoundEffect")
        echo.Delay = effects.echo.Delay or 1
        echo.Feedback = effects.echo.Feedback or 0.5
        echo.WetLevel = effects.echo.WetLevel or 0
        echo.DryLevel = effects.echo.DryLevel or 0
        echo.Parent = sound
    end

    if effects.equalizer then
        local equalizer = Instance.new("EqualizerSoundEffect")
        equalizer.HighGain = effects.equalizer.HighGain or 0
        equalizer.MidGain = effects.equalizer.MidGain or 0
        equalizer.LowGain = effects.equalizer.LowGain or 0
        equalizer.Parent = sound
    end

    if effects.flange then
        local flange = Instance.new("FlangeSoundEffect")
        flange.Mix = effects.flange.Mix or 0.85
        flange.Depth = effects.flange.Depth or 0.45
        flange.Rate = effects.flange.Rate or 5.0
        flange.Parent = sound
    end

    if effects.pitch then
        local pitch = Instance.new("PitchShiftSoundEffect")
        pitch.Octave = effects.pitch.Octave or 1.0
        pitch.Parent = sound
    end

    if effects.reverb then
        local reverb = Instance.new("ReverbSoundEffect")
        reverb.DecayTime = effects.reverb.DecayTime or 1.5
        reverb.Density = effects.reverb.Density or 1.0
        reverb.Diffusion = effects.reverb.Diffusion or 1.0
        reverb.WetLevel = effects.reverb.WetLevel or 0.0
        reverb.DryLevel = effects.reverb.DryLevel or -6.0
        reverb.Parent = sound
    end

    if effects.tremolo then
        local tremolo = Instance.new("TremoloSoundEffect")
        tremolo.Depth = effects.tremolo.Depth or 1.0
        tremolo.Frequency = effects.tremolo.Frequency or 5.0
        tremolo.Duty = effects.tremolo.Duty or 0.5
        tremolo.Parent = sound
    end
end

--[[ Core Functions ]]
function Sound.Play(soundName: string, parent: Instance?, config: any?)
    parent = parent or workspace
    config = config or {}

    local sounds = Modules.Sound.Assets.Sounds
    local soundData = sounds

    if string.find(soundName, "%.") then
        local path = string.split(soundName, ".")
        for _, key in ipairs(path) do
            if not soundData then return nil end
            soundData = soundData[key]
        end
    else
        local category
        for cat, categoryData in pairs(sounds) do
            if categoryData[soundName] then
                category = cat
                break
            end
        end
        category = category or "UI"

        local soundPath = category .. "." .. soundName
        local path = string.split(soundPath, ".")
        soundData = sounds

        for _, key in ipairs(path) do
            if not soundData then return nil end
            soundData = soundData[key]
        end
    end

    if not soundData then return nil end

    local category = string.split(soundName, ".")[1] or "SFX"
    local sound = GetFromPool(category)
    if not sound then return nil end

    sound.SoundId = soundData.id
    sound.Volume = config.volume or soundData.volume or 1
    sound.PlaybackSpeed = config.speed or 1
    sound.Looped = config.loop or false

    if config.spatial then
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
        sound.RollOffMinDistance = math.min(10, config.distance and config.distance * 0.2 or 10)
        sound.RollOffMaxDistance = config.distance or 100
    else
        sound.RollOffMode = Enum.RollOffMode.Inverse
    end

    AppleEffects(sound, config.effects)

    if config.parent then
        if config.spatial and parent:IsA("Model") then
            sound.Parent = parent.PrimaryPart or parent:FindFirstChild("Root") or parent:FindFirstChildWhichIsA("BasePart") or parent
        else
            sound.Parent = parent
        end
    else
        sound.Parent = GetSoundFolder(category)
    end

    state.playing[sound] = {
        category = category,
        startTime = os.clock()
    }

    sound.Ended:Connect(function()
        if state.playing[sound] then
            state.playing[sound] = nil
            ReturnToPool(sound, category)
        end
    end)

    sound:Play()
    return sound
end

function Sound.Stop(sound: Sound)
    if not sound then return end

    local data = state.playing[sound]
    if not data then return end

    sound:Stop()
    state.playing[sound] = nil
    ReturnToPool(sound, data.category)
end

--[[ Cleanup Function ]]
function Sound.Cleanup(instance: Instance, soundNames: {string})
    if not instance then return end

    for _, sound in ipairs(instance:GetChildren()) do
        if sound:IsA("Sound") then
            for _, name in ipairs(soundNames) do
                if sound.Name:find(name) then
                    sound:Destroy()
                end
            end
        end
    end
end

--[[ Monitor Functions ]]
function Sound.Monitor(instance: Instance, soundNames: {string})
    if not instance then return end

    if state.monitors[instance] then
        state.monitors[instance]:Disconnect()
        state.monitors[instance] = nil
    end
    Sound.Cleanup(instance, soundNames)

    state.monitors[instance] = instance.ChildAdded:Connect(function(child)
        if child:IsA("Sound") then
            for _, name in ipairs(soundNames) do
                if child.Name:find(name) then
                    child:Destroy()
                    break
                end
            end
        end
    end)

    instance.AncestryChanged:Connect(function(_, parent)
        if not parent and state.monitors[instance] then
            state.monitors[instance]:Disconnect()
            state.monitors[instance] = nil
        end
    end)
end

--[[ Button Sounds ]]
function Sound.Button(buttonType: string)
    Sound.Play("Button" .. buttonType)
end

--[[ Quest Sounds ]]
function Sound.Quest(questType: string)
    Sound.Play("Quest" .. questType)
end

--[[ Dialogue Sounds ]]
function Sound.Dialogue(dialogueType: string)
    Sound.Play("Dialogue" .. dialogueType)
end

--[[ Scene Sounds ]]
function Sound.Scene(sceneType: string)
    Sound.Play("Scene" .. sceneType)
end

--[[ Prompt Sounds ]]
function Sound.Prompt(promptType: string)
    Sound.Play("Prompt" .. promptType)
end

--[[ Toggle Sounds ]]
function Sound.Toggle(state: boolean)
    Sound.Play(state and "ToggleOn" or "ToggleOff")
end

--[[ Dropdown Sounds ]]
function Sound.Dropdown(action: string)
    Sound.Play("Dropdown" .. action)
end

--[[ Notification Sounds ]]
function Sound.Notify(type: string)
    Sound.Play("Notify" .. type)
end

--[[ Input Sounds ]]
function Sound.Input(action: string)
    Sound.Play("Input" .. action)
end

--[[ Navigation Sounds ]]
function Sound.Nav(action: string)
    Sound.Play("Nav" .. action)
end

--[[ Action Sounds ]]
function Sound.Action(type: string)
    Sound.Play("Action" .. type)
end

return Sound