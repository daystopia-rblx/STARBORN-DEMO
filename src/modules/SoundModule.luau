
--[[ SoundModule
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-02
]]
local SoundModule = {}

--[[ Assets ]]
SoundModule.Assets = {
    Sounds = {
        UI = {
            -- Prompt Sounds
            PromptClick = { id = "rbxassetid://1673280232", volume = 0.5 },
            PromptHover = { id = "rbxassetid://408524543", volume = 0.5 },
            PromptError = { id = "rbxassetid://2130284653", volume = 0.5 },
        },
        SFX = {
            -- Player Sounds
            Equip = { id = "rbxassetid://2706199011", volume = 0.5 },
            Dash = { id = "rbxassetid://6128977275", volume = 0.5 },
            Slide = { id = "rbxassetid://106761812656752", volume = 0.5 },
            Death = { id = "rbxassetid://6424574135", volume = 0.5 },

            -- Weapon Sounds
            Critical_Hit = { id = "rbxassetid://13471740561", volume = 0.5 },
            Blunt_Hit = { id = "rbxassetid://8278630896", volume = 0.5 },
            Slash_Hit = { id = "rbxassetid://935843979", volume = 0.5 },
            Blocked_Hit = { id = "rbxassetid://122584254608380", volume = 0.5 },
            Block_Break = { id = "rbxassetid://126201620527102", volume = 0.5 },
            Feint = { id = "rbxassetid://6042053626", volume = 0.5 },
            Parry_1 = { id = "rbxassetid://95722991827031", volume = 0.5 },
            Parry_2 = { id = "rbxassetid://132886449936911", volume = 0.5 },
            Parry_3 = { id = "rbxassetid://77250810798467", volume = 0.5 },
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