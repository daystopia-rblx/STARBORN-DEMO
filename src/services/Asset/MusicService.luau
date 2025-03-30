--[[ MusicService
    Dynamic music system with smooth transitions and layered playback.
    Manages background music, crossfading, and region-based music changes.
    @author @Daystopia
    @version 1.0.2
    @date 2025-03-30
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
    Stop = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Constants ]]
local CONSTANTS = {
    DEFAULT_VOLUME = 0.5,
    DEFAULT_SPEED = 1,
    FADE_TIME = 0.3,
    PLAYLIST_TRANSITION_TIME = 2,
    CATEGORY = "Music"
}

--[[ State ]]
local state = {
    currentMusic = nil,
    lastPlayed = nil,
    currentPlaylist = nil,
    playlistIndex = 1,
    isPlaying = false,
    shuffledTracks = {}
}

--[[ Core Functions ]]
function MusicService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function MusicService:Cleanup()
    if state.currentMusic then
        Services.Audio:StopSound(state.currentMusic, CONSTANTS.FADE_TIME)
    end

    state.currentMusic = nil
    state.lastPlayed = nil
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
        state.lastPlayed = id
        Services.Event:Fire("Music.Play", id)
    end

    return music
end

function MusicService:StopMusic(instant)
    if not state.currentMusic then return end

    Services.Audio:StopSound(state.currentMusic, instant and 0 or CONSTANTS.FADE_TIME)
    state.currentMusic = nil
    Services.Event:Fire("Music.Stop")
end

--[[ Playlist Functions ]]
function MusicService:StartPlaylist(playlistName, parent, options)
    options = options or {}

    local playlist = Modules.Music.Playlists[playlistName]
    if not playlist then return end

    self:StopPlaylist()

    local tracks = Modules.Music:GetTracks(playlistName)
    state.shuffledTracks = playlist.shuffle and self:ShuffleTracks(tracks) or tracks

    state.currentPlaylist = playlistName
    state.playlistIndex = 1
    state.isPlaying = true

    local firstTrack = state.shuffledTracks[1]
    if firstTrack then
        self:PlayMusic(parent, firstTrack.id, {
            volume = options.volume or playlist.defaultVolume or firstTrack.volume,
            effects = playlist.effects
        })
    end

    self:NextTrack(parent)
end

function MusicService:StopPlaylist(instant)
    if not state.currentPlaylist then return end

    state.isPlaying = false
    state.currentPlaylist = nil
    state.playlistIndex = 1
    state.shuffledTracks = {}

    self:StopMusic(instant)
end

function MusicService:ShuffleTracks(tracks)
    local shuffled = table.clone(tracks)
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

function MusicService:NextTrack(parent)
    if not state.isPlaying or not state.currentPlaylist then return end

    local playlist = Modules.Music.Playlists[state.currentPlaylist]
    if not playlist then return end

    if state.currentMusic then
        local connection
        connection = state.currentMusic.Ended:Connect(function()
            connection:Disconnect()

            state.playlistIndex = state.playlistIndex % #state.shuffledTracks + 1

            local nextTrack = state.shuffledTracks[state.playlistIndex]
            if nextTrack and state.isPlaying then
                self:PlayMusic(parent, nextTrack.id, {
                    volume = playlist.defaultVolume or nextTrack.volume,
                    effects = playlist.effects
                })

                self:NextTrack(parent)
            end
        end)
    end
end

function MusicService:GetPlaylist()
    if not state.currentPlaylist then return nil end

    return {
        name = state.currentPlaylist,
        currentTrack = state.shuffledTracks[state.playlistIndex],
        isPlaying = state.isPlaying
    }
end

return MusicService