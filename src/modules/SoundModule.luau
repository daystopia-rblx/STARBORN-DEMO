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

            -- Weapon Sounds
            Fist_Swing = { id = "rbxassetid://99449642314896", volume = 0.5 },
            Blade_Swing = { id = "rbxassetid://6241709963", volume = 0.5 },
            Critical_Hit = { id = "rbxassetid://13471740561", volume = 0.5 },
            Blunt = { id = "rbxassetid://5501600429", volume = 0.5 },
            Slash = { id = "rbxassetid://935843979", volume = 0.5 },
            -- Blocked_Hit = { id = "rbxassetid://122584254608380", volume = 0.5 },
            -- Block_Break = { id = "rbxassetid://126201620527102", volume = 0.5 },
            -- Feint = { id = "rbxassetid://6042053626", volume = 0.5 },
            -- Parry_1 = { id = "rbxassetid://95722991827031", volume = 0.5 },
            -- Parry_2 = { id = "rbxassetid://132886449936911", volume = 0.5 },
            -- Parry_3 = { id = "rbxassetid://77250810798467", volume = 0.5 },

            -- Weather Sounds
            RainSound = { id = "", volume = 0.5 },
            ThunderstormSound = { id = "", volume = 0.5 },
            SnowSound = { id = "", volume = 0.5 },
            WindSound = { id = "", volume = 0.5 },
            ThunderSoundEffect = { id = "", volume = 0.5 },
            AshfallSound = { id = "", volume = 0.5 },

            -- Footstep Sounds
            Footsteps = {
                Brick = { id = "rbxassetid://178190837", volume = 0.3 },
                Climb = { id = "rbxassetid://145180175", volume = 0.3 },
                Cobblestone = { id = "rbxassetid://178190837", volume = 0.3 },
                Concrete = { id = "rbxassetid://277067660", volume = 0.3 },
                CorrodedMetal = { id = "rbxassetid://177940974", volume = 0.3 },
                DiamondPlate = { id = "rbxassetid://177940974", volume = 0.3 },
                Fabric = { id = "rbxassetid://133705377", volume = 0.3 },
                Foil = { id = "rbxassetid://178190837", volume = 0.3 },
                ForceField = { id = "rbxassetid://329997777", volume = 0.3 },
                Glass = { id = "rbxassetid://178190837", volume = 0.3 },
                Granite = { id = "rbxassetid://178054124", volume = 0.3 },
                Grass = { id = "rbxassetid://177940963", volume = 0.3 },
                Ice = { id = "rbxassetid://178190837", volume = 0.3 },
                Marble = { id = "rbxassetid://178190837", volume = 0.3 },
                Metal = { id = "rbxassetid://177940974", volume = 0.3 },
                Neon = { id = "rbxassetid://177940974", volume = 0.3 },
                Pebble = { id = "rbxassetid://178190837", volume = 0.3 },
                Plastic = { id = "rbxassetid://177940974", volume = 0.3 },
                Sand = { id = "rbxassetid://212011266", volume = 0.3 },
                Slate = { id = "rbxassetid://178054124", volume = 0.3 },
                SmoothPlastic = { id = "rbxassetid://178190837", volume = 0.3 },
                Snow = { id = "rbxassetid://212011266", volume = 0.3 },
                Wood = { id = "rbxassetid://177940988", volume = 0.3 },
                WoodPlanks = { id = "rbxassetid://211987063", volume = 0.3 },
                Air = { id = "rbxassetid://5113213873", volume = 0.3 }
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