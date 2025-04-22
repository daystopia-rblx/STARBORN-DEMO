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
            Equip = { id = "rbxassetid://2706199011", volume = 0.5 },
            Dash = { id = "rbxassetid://6128977275", volume = 0.5 },
            -- Slide = { id = "rbxassetid://106761812656752", volume = 0.5 },
            Death = { id = "rbxassetid://6424574135", volume = 0.5 },
            Dodged = { id = "rbxassetid://6300588705", volume = 0.5 },
            Dodge_1 = { id = "rbxassetid://87129714918446", volume = 0.5 },
            Dodge_2 = { id = "rbxassetid://128542000862016", volume = 0.5 },
            Dodge_3 = { id = "rbxassetid://135660444133774", volume = 0.5 },
            Stomp = { id = "rbxassetid://3784888301", volume = 0.5 },

            -- Weapon Sounds
            Critical_Indicator = { id = "rbxassetid://8649690928", volume = 0.5},
            Blade_Swing = { id = "rbxassetid://6241709963", volume = 0.5 },
            Critical_Hit = { id = "rbxassetid://13471740561", volume = 0.5 },
            Blunt = { id = "rbxassetid://5501600429", volume = 0.5 },
            Slash = { id = "rbxassetid://935843979", volume = 0.5 },
            Blocked_Hit = { id = "rbxassetid://4958429431", volume = 0.5 },
            Block_Break = { id = "rbxassetid://4516507682", volume = 0.5 },
            -- Feint = { id = "rbxassetid://6042053626", volume = 0.5 },
            Parry = { id = "rbxassetid://15057101114", volume = 0.5 },

            -- Fist Sounds
            Swing_1 = { id = "rbxassetid://100585648620385", volume = 0.5 },
            Swing_2 = { id = "rbxassetid://102311297724844", volume = 0.5 },
            Swing_3 = { id = "rbxassetid://78434445989096", volume = 0.5 },
            Swing_4 = { id = "rbxassetid://137521196315412", volume = 0.5 },
            Fist_Stomp = { id = "rbxassetid://113561434533124", volume = 0.5},

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
                    Slate_1 = { id = "rbxassetid://74474626894858", volume = 0.5 },
                    Slate_2 = { id = "rbxassetid://75353944635768", volume = 0.5 },
                    Slate_3 = { id = "rbxassetid://124989661719768", volume = 0.5 },
                    Slate_4 = { id = "rbxassetid://78572928885821", volume = 0.5 },
                },

                -- Wood Sounds
                Wood = {
                    Wood_1 = { id = "rbxassetid://109144036561008", volume = 0.5 },
                    Wood_2 = { id = "rbxassetid://135840855435388", volume = 0.5 },
                    Wood_3 = { id = "rbxassetid://91792623097365", volume = 0.5 },
                    Wood_4 = { id = "rbxassetid://132901965058520", volume = 0.5 },
                },

                WoodPlanks = {
                    WoodPlanks_1 = { id = "rbxassetid://109144036561008", volume = 0.5 },
                    WoodPlanks_2 = { id = "rbxassetid://135840855435388", volume = 0.5 },
                    WoodPlanks_3 = { id = "rbxassetid://91792623097365", volume = 0.5 },
                    WoodPlanks_4 = { id = "rbxassetid://132901965058520", volume = 0.5 },
                },

                -- Grass Sounds
                Grass = {
                    Grass_1 = { id = "rbxassetid://71254262451490", volume = 0.5 },
                    Grass_2 = { id = "rbxassetid://89109150507709", volume = 0.5 },
                    Grass_3 = { id = "rbxassetid://126121969971381", volume = 0.5 },
                    Grass_4 = { id = "rbxassetid://139779904313432", volume = 0.5 },
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