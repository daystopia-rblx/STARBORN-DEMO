local Sound = {}

--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Dependencies ]]
local Services = {
    Audio = require(ReplicatedStorage.Services.Asset.AudioService)
}

local Modules = {
    Sound = require(ReplicatedStorage.Modules.SoundModule)
}

--[[ Core Functions ]]
function Sound.Play(soundName: string, parent: Instance?)
    parent = parent or workspace

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

    local category = "UI"
    if string.find(soundName, "%.") then
        category = string.split(soundName, ".")[1]
    end

    local config = {
        id = soundData.id,
        volume = soundData.volume,
        category = category,
        spatial = parent ~= workspace
    }

    return Services.Audio:PlaySound(parent, config)
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