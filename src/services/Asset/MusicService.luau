--[[ MusicService
    Dynamic music system with smooth transitions and layered playback.
    Manages background music, crossfading, and region-based music changes.
    @author @Daystopia
    @version 1.0.3
    @date 2025-04-01
]]
local MusicService = {}

--[[ Dependencies ]]
MusicService.Dependencies = {
    "Audio",
    "Asset"
}

MusicService.Modules = {
    "Music"
}

--[[ Events ]]
MusicService.Events = {
    Play = true,
    Stop = true,
    State = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Constants ]]
local CONSTANTS = {
    DEFAULT_VOLUME = 0.5,
    DEFAULT_SPEED = 1,
    FADE_TIME = 0.3,
    CATEGORY = "Music"
}

--[[ State ]]
local state = {
    currentMusic = nil,
    currentPlaylist = nil,
    isPlaying = false,
    activeLayers = {},
    currentState = nil,
    shuffledTracks = {}
}

--[[ Core Functions ]]
function MusicService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function MusicService:Cleanup()
    self:StopPlaylist()
end

--[[ Music Functions ]]
function MusicService:PlayMusic(parent, id, options)
    options = options or {}

    if state.currentMusic then
        Services.Audio:StopSound(state.currentMusic, CONSTANTS.FADE_TIME)
    end

    local config = {
        id = id,
        volume = options.volume or CONSTANTS.DEFAULT_VOLUME,
        speed = options.speed or CONSTANTS.DEFAULT_SPEED,
        loop = true,
        category = CONSTANTS.CATEGORY,
        fadeIn = CONSTANTS.FADE_TIME,
        effects = options.effects
    }

    local music = Services.Audio:PlaySound(parent, config)
    if music then
        state.currentMusic = music
        Services.Event:Fire("Music.Play", id)
    end

    return music
end

--[[ Playlist Functions ]]
function MusicService:StartPlaylist(playlistName, parent, options)
    options = options or {}

    local playlist = Modules.Music.Playlists[playlistName]
    if not playlist then return end

    self:StopPlaylist()

    state.currentPlaylist = playlistName
    state.isPlaying = true
    state.currentState = nil
    state.activeLayers = {}

    if playlist.dynamic then
        local firstTrack = playlist.tracks[1]
        if firstTrack then
            self:PlayState(firstTrack, parent, options)
        end
    else
        local tracks = Modules.Music:GetTracks(playlistName)
        if #tracks > 0 then
            state.shuffledTracks = playlist.shuffle and self:ShuffleTracks(tracks) or tracks
            self:PlayMusic(parent, state.shuffledTracks[1].id, {
                volume = playlist.defaultVolume or state.shuffledTracks[1].volume,
                effects = playlist.effects
            })

            if not playlist.loop then
                self:NextTrack(parent, playlist)
            end
        end
    end
end

function MusicService:StopPlaylist(instant)
    if not state.currentPlaylist then return end

    for _, layer in pairs(state.activeLayers) do
        Services.Audio:StopSound(layer, instant and 0 or CONSTANTS.FADE_TIME)
    end

    if state.currentMusic then
        Services.Audio:StopSound(state.currentMusic, instant and 0 or CONSTANTS.FADE_TIME)
    end

    state.currentMusic = nil
    state.currentPlaylist = nil
    state.isPlaying = false
    state.activeLayers = {}
    state.currentState = nil
    state.shuffledTracks = {}

    Services.Event:Fire("Music.Stop")
end

function MusicService:PlayState(trackPath, parent, options)
    options = options or {}

    local playlist = Modules.Music.Playlists[state.currentPlaylist]
    if not playlist then return end

    local track = Modules.Music:GetPath(trackPath)
    if not track then return end

    if state.currentState and state.currentState ~= trackPath then
        for _, layer in pairs(state.activeLayers) do
            Services.Audio:StopSound(layer, CONSTANTS.FADE_TIME)
        end
    end

    state.currentState = trackPath

    if track.layers then
        state.activeLayers = {}
        for _, layer in ipairs(track.layers) do
            local layerSound = Services.Audio:PlaySound(parent, {
                id = layer.id,
                volume = options.volume or playlist.defaultVolume or layer.volume,
                speed = options.speed or CONSTANTS.DEFAULT_SPEED,
                loop = track.loop,
                category = CONSTANTS.CATEGORY,
                fadeIn = CONSTANTS.FADE_TIME,
                effects = options.effects
            })

            if layerSound then
                state.activeLayers[layer.id] = layerSound

                if not track.loop then
                    local connection
                    connection = layerSound.Ended:Connect(function()
                        connection:Disconnect()
                        self:CompleteTrack(track, layer.id)
                    end)
                end
            end
        end
    else
        self:PlayMusic(parent, track.id, {
            volume = options.volume or playlist.defaultVolume or track.volume,
            effects = options.effects
        })
    end

    Services.Event:Fire("Music.State", trackPath, track.tag)
end

--[[ Track Functions ]]
function MusicService:ShuffleTracks(tracks)
    local shuffled = table.clone(tracks)
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

function MusicService:NextTrack(parent, playlist)
    if not state.currentMusic then return end

    local connection
    connection = state.currentMusic.Ended:Connect(function()
        connection:Disconnect()

        if not state.isPlaying then return end

        local currentIndex
        for i, track in ipairs(state.shuffledTracks) do
            if track.id == state.currentMusic.SoundId then
                currentIndex = i
                break
            end
        end

        if currentIndex then
            local nextIndex = currentIndex % #state.shuffledTracks + 1
            local nextTrack = state.shuffledTracks[nextIndex]
            if nextTrack then
                self:PlayMusic(parent, nextTrack.id, {
                    volume = playlist.defaultVolume or nextTrack.volume,
                    effects = playlist.effects
                })

                self:NextTrack(parent, playlist)
            end
        end
    end)
end

function MusicService:CompleteTrack(track, layerId)
    if not track.strict then return end

    state.activeLayers[layerId] = nil

    if next(state.activeLayers) == nil then
        local playlist = Modules.Music.Playlists[state.currentPlaylist]
        if not playlist then return end

        local currentIndex
        for i, trackPath in ipairs(playlist.tracks) do
            if trackPath == state.currentState then
                currentIndex = i
                break
            end
        end

        if currentIndex then
            local nextIndex = currentIndex % #playlist.tracks + 1
            local nextTrack = playlist.tracks[nextIndex]
            if nextTrack then
                self:PlayState(nextTrack)
            end
        end
    end
end

return MusicService