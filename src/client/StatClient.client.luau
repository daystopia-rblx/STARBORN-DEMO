--[[ StatClient
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-01
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Utility = {
    Controller = require(script.Parent.Utility.Controller)
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

--[[ Constants ]]
local UPDATE_SETTINGS = {
    FILL_DURATION = 0.2,
    COOLDOWN_DURATION = 0.5
}

--[[ State ]]
local State = {
    ui = {
        center = {
            health = HUD.Center.Health,
            mana = HUD.Center.Mana,
            posture = HUD.Center.Posture,
            blood = HUD.Center.Blood
        },
        hotbar = {
            slots = {}
        },
        left = {
            thirst = HUD.Left.Thirst,
            hunger = HUD.Left.Hunger
        },
        indicators = {
            roll = HUD.Indicators.Roll,
            parry = HUD.Indicators.Parry,
            feint = HUD.Indicators.Feint,
            tempo = HUD.Indicators.Tempo,
            block = HUD.Indicators.Block
        }
    },
    stats = {}
}

for i = 1, 5 do
    State.ui.hotbar.slots[i] = HUD.Hotbar:FindFirstChild("Slot_" .. i)
end

--[[ Utility Functions ]]
local function UpdateBar(bar, value, maxValue)
    if not bar or not bar:FindFirstChild("Mask") or not bar.Mask:FindFirstChild("Fill") then return end

    local fillAmount = math.clamp(value / maxValue, 0, 1)
    Utility.Controller.Update({
        instance = bar.Mask.Fill,
        properties = {
            Size = UDim2.new(fillAmount, 0, 1, 0)
        },
        duration = UPDATE_SETTINGS.FILL_DURATION
    })
end

local function UpdateCooldown(indicator, remaining, duration)
    if not indicator or not indicator:FindFirstChild("Cooldown") then return end

    local fillAmount = math.clamp(1 - (remaining / duration), 0, 1)
    Utility.Controller.Update({
        instance = indicator.Cooldown,
        properties = {
            Size = UDim2.new(1, 0, fillAmount, 0)
        },
        duration = UPDATE_SETTINGS.COOLDOWN_DURATION
    })
end

--[[ Events ]]
local Events = {
    ["Stat.Update"] = {
        handler = function(data)
            if not data or not data.stat then return end

            local stat = data.stat:upper()
            local value = data.value
            local maxValue = data.maxValue or value

            if data.metadata and data.metadata.type == "decay" then
                return
            end

            State.stats[stat] = {
                value = value,
                maxValue = maxValue
            }

            if State.ui.center[stat:lower()] then
                UpdateBar(State.ui.center[stat:lower()], value, maxValue)
            elseif State.ui.left[stat:lower()] then
                UpdateBar(State.ui.left[stat:lower()], value, maxValue)
            end
        end
    },

    ["Combat.Cooldown"] = {
        handler = function(data)
            if not data or not data.ability then return end

            print("Received cooldown data:", data)

            local ability = data.ability:lower()
            local remaining = data.remaining
            local duration = data.duration

            print(string.format("Processing cooldown for ability: %s (%.1f/%.1f)", ability, remaining, duration))

            if State.ui.indicators[ability] then
                print("Updating UI indicator for ability:", ability)
                UpdateCooldown(State.ui.indicators[ability], remaining, duration)
            else
                print("No UI indicator found for ability:", ability)
            end
        end
    },

    ["Skill.Update"] = {
        handler = function(data)
            if not data or not data.slot or not data.skill then return end

            local slot = State.ui.hotbar.slots[data.slot]
            if not slot then return end

            local skillLabel = slot:FindFirstChild("Skill")
            if skillLabel then
                skillLabel.Text = data.skill
            end
        end
    }
}

--[[ Initialization ]]
local function Initialize()
    for eventName, event in pairs(Events) do
        Services.Event:OnClientEvent(eventName, event.handler)
    end

    for _, bar in pairs(State.ui.center) do
        UpdateBar(bar, 100, 100)
    end
    for _, bar in pairs(State.ui.left) do
        UpdateBar(bar, 100, 100)
    end
    for _, indicator in pairs(State.ui.indicators) do
        if indicator:FindFirstChild("Cooldown") then
            UpdateCooldown(indicator, 0, 0)
        end
    end
end

Initialize()
