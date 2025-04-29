--[[ SoundModule
    @author @Daystopia
    @version 1.0.4
    @date 2025-04-11
]]
local SoundModule = {}

--[[ Assets ]]
SoundModule.Assets = {
    Sounds = {
        UI = {
            -- Interface Sounds
            ButtonHover = { id = "rbxassetid://80867008495871", volume = 0.5 },
            ButtonClick = { id = "rbxassetid://70922191300105", volume = 0.5 },

            -- Prompt Sounds
            PromptClick = { id = "rbxassetid://1673280232", volume = 0.5 },
            PromptHover = { id = "rbxassetid://408524543", volume = 0.5 },
            PromptError = { id = "rbxassetid://2130284653", volume = 0.5 },
        },

        SFX = {
            -- Player Sounds
            --Equip = { id = "rbxassetid://2706199011", volume = 0.5 },
            --Dash = { id = "rbxassetid://6128977275", volume = 0.5 },
            -- Slide = { id = "rbxassetid://106761812656752", volume = 0.5 },
            --Death = { id = "rbxassetid://6424574135", volume = 0.5 },
            Dodged = { id = "rbxassetid://2239424601", volume = 0.5 },
            Dodge_1 = { id = "rbxassetid://72799891356866", volume = 0.5 },
            Dodge_2 = { id = "rbxassetid://94975097781798", volume = 0.5 },
            Dodge_3 = { id = "rbxassetid://137276306998823", volume = 0.5 },
            Dodge_4 = { id = "rbxassetid://121043909282404", volume = 0.5 },
            Dodge_5 = { id = "rbxassetid://71516916492417", volume = 0.5 },
            Stomp = { id = "rbxassetid://3784888301", volume = 0.5 },

            -- Weapon Sounds
            Critical_Indicator = { id = "rbxassetid://8649690928", volume = 0.5},
            --Blade_Swing = { id = "rbxassetid://6241709963", volume = 0.5 },
            --Critical_Hit = { id = "rbxassetid://13471740561", volume = 0.5 },
            Blunt = { id = "rbxassetid://5501600429", volume = 0.5 },
            Slash = { id = "rbxassetid://7171761940", volume = 0.5 },
            Blocked_Hit = { id = "rbxassetid://4958429431", volume = 0.5 },
            Block_Break = { id = "rbxassetid://4516507682", volume = 0.5 },
            -- Feint = { id = "rbxassetid://6042053626", volume = 0.5 },
            Parry = { id = "rbxassetid://15057101114", volume = 0.5 },

            -- Fist Sounds
            Fist_Swing = { id = "rbxassetid://9114162449", volume = 0.5 },

            -- Weather Sounds
            RainSound = { id = "", volume = 0.5 },
            ThunderstormSound = { id = "", volume = 0.5 },
            SnowSound = { id = "", volume = 0.5 },
            WindSound = { id = "", volume = 0.5 },
            ThunderSoundEffect = { id = "", volume = 0.5 },
            AshfallSound = { id = "", volume = 0.5 },

            -- Footstep Sounds
            Footsteps = {
                 -- Rock Sounds
                Slate = {
                    Slate_1 = { id = "rbxassetid://77266776347837", volume = 0.5 },
                    Slate_2 = { id = "rbxassetid://115490979119535", volume = 0.5 },
                    Slate_3 = { id = "rbxassetid://123246598528856", volume = 0.5 },
                    Slate_4 = { id = "rbxassetid://92805934439539", volume = 0.5 },
                },

                -- Wood Sounds
                Wood = {
                    Wood_1 = { id = "rbxassetid://119848814141273", volume = 0.5 },
                    Wood_2 = { id = "rbxassetid://113861088471133", volume = 0.5 },
                    Wood_3 = { id = "rbxassetid://85883584341347", volume = 0.5 },
                    Wood_4 = { id = "rbxassetid://79930145750801", volume = 0.5 },
                },

                WoodPlanks = {
                    WoodPlanks_1 = { id = "rbxassetid://119848814141273", volume = 0.5 },
                    WoodPlanks_2 = { id = "rbxassetid://113861088471133", volume = 0.5 },
                    WoodPlanks_3 = { id = "rbxassetid://85883584341347", volume = 0.5 },
                    WoodPlanks_4 = { id = "rbxassetid://79930145750801", volume = 0.5 },
                },

                -- Sand Sounds
                Sand = {
                    Sand_1 = { id = "rbxassetid://99235162671829", volume = 0.5 },
                    Sand_2 = { id = "rbxassetid://117426407371432", volume = 0.5 },
                    Sand_3 = { id = "rbxassetid://129983644597147", volume = 0.5 },
                    Sand_4 = { id = "rbxassetid://98797681246298", volume = 0.5 },
                },

                -- Grass Sounds
                Grass = {
                    Grass_1 = { id = "rbxassetid://77586008580648", volume = 0.5 },
                    Grass_2 = { id = "rbxassetid://129766615643769", volume = 0.5 },
                    Grass_3 = { id = "rbxassetid://140259793693469", volume = 0.5 },
                    Grass_4 = { id = "rbxassetid://122040048784334", volume = 0.5 },
                },
            }
        }
    }
}

--[[ Presets ]]
SoundModule.Presets = {
    Sounds = {}
}

local function ProcessSounds(source, target)
    for name, config in pairs(source) do
        if type(config) == "table" then
            if config.id ~= nil then
                target[name] = {
                    id = config.id,
                    volume = config.volume
                }
            else
                target[name] = {}
                ProcessSounds(config, target[name])
            end
        end
    end
end

ProcessSounds(SoundModule.Assets.Sounds, SoundModule.Presets.Sounds)

return SoundModule