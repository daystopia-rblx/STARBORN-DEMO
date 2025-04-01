--[[ MusicModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local MusicModule = {}

--[[ Assets ]]
MusicModule.Assets = {
    Music = {
        -- Background Music
        Background = {
            Ambient = { id = "", volume = 0.3 }
        },
        -- Menu Music
        Menu = {
            Main = { id = "rbxassetid://77198630224489", volume = 0.4 }
        },
        -- Dynamic Songs
        Dynamic = {
            Conbat = {
                Intro = {
                    layers = {
                        { id = "rbxassetid://76981835616483", volume = 1 },
                        { id = "rbxassetid://108531401694427", volume = 1 }
                    },
                    tag = "INTRO",
                    loop = false,
                    strict = true
                },
                IntroLoop = {
                    layers = {
                        { id = "rbxassetid://96714951838451", volume = 1 },
                        { id = "rbxassetid://122358701394913", volume = 1 }
                    },
                    tag = "INTRO_LOOP",
                    loop = true,
                    strict = true
                },
                Transition = {
                    layers = {
                        { id = "rbxassetid://81652112796628", volume = 1 }
                    },
                    tag = "TRANSITION",
                    loop = false,
                    strict = true
                },
                Main = {
                    layers = {
                        { id = "rbxassetid://70703650960120", volume = 1 }
                    },
                    tag = "MAIN",
                    loop = true,
                    strict = false
                }
            }
        }
    }
}

--[[ Playlists ]]
MusicModule.Playlists = {
    MainGame = {
        name = "Main Game Playlist",
        tracks = {
            "Background.Ambient"
        },
        shuffle = true,
        crossfade = true,
        defaultVolume = 0.4
    },
    MenuLoop = {
        name = "Menu Music Loop",
        tracks = {
            "Menu.Main"
        },
        shuffle = false,
        crossfade = true,
        defaultVolume = 0.35
    },
    Combat = {
        name = "Combat Dynamic Theme",
        tracks = {
            "Dynamic.Combat.Intro",
            "Dynamic.Combat.IntroLoop",
            "Dynamic.Combat.Transition",
            "Dynamic.Combat.Main"
        },
        shuffle = false,
        crossfade = true,
        defaultVolume = 0.5,
        dynamic = true
    }
}

--[[ Presets ]]
MusicModule.Presets = {
    Music = {}
}

--[[ Utility Functions ]]
local function ProcessMusic(source, target)
    for name, config in pairs(source) do
        if type(config) == "table" then
            if config.id ~= nil then
                target[name] = {
                    id = config.id,
                    volume = config.volume
                }
            else
                target[name] = {}
                ProcessMusic(config, target[name])
            end
        end
    end
end

function MusicModule:GetPath(path)
    local current = self.Assets.Music
    for segment in path:gmatch("[^%.]+") do
        if current[segment] then
            current = current[segment]
        else
            return nil
        end
    end
    return current
end

function MusicModule:GetTracks(playlistName)
    local playlist = self.Playlists[playlistName]
    if not playlist then return {} end

    local tracks = {}
    for _, trackPath in ipairs(playlist.tracks) do
        local track = self:GetPath(trackPath)
        if track then
            table.insert(tracks, {
                id = track.id,
                volume = track.volume,
                path = trackPath
            })
        end
    end
    return tracks
end

ProcessMusic(MusicModule.Assets.Music, MusicModule.Presets.Music)

return MusicModule