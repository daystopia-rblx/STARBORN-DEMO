--[[ StatClient
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-02
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

local function UpdateCooldown(indicator, duration)
    if not indicator then
        return
    end

    local cooldownBar = indicator:FindFirstChild("Cooldown")
    if not cooldownBar then
        return
    end

    cooldownBar.AnchorPoint = Vector2.new(0, 1)
    cooldownBar.Position = UDim2.new(0, 0, 1, 0)
    cooldownBar.Size = UDim2.new(1, 0, 1, 0)

    Utility.Controller.Update({
        instance = cooldownBar,
        properties = {
            Size = UDim2.new(1, 0, 0, 0)
        },
        duration = duration,
        easingStyle = Utility.Controller.Easing.Linear
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

    ["Client.Combat.Attack"] = {
        handler = function(response)
            if not response.success then return end
            if not response.data or not response.data.ability then return end

            local ability = response.data.ability:lower()
            local remaining = response.data.remaining
            local duration = response.data.duration

            if State.ui.indicators[ability] then
                UpdateCooldown(State.ui.indicators[ability], duration)
            end
        end
    },

    ["Client.Movement.Execute"] = {
        handler = function(response)
            if not response.success then return end
            if not response.data or not response.data.ability then return end

            local ability = response.data.ability:lower()
            local remaining = response.data.remaining
            local duration = response.data.duration

            if State.ui.indicators[ability] then
                UpdateCooldown(State.ui.indicators[ability], duration)
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
        local cooldownBar = indicator:FindFirstChild("Cooldown")
        if cooldownBar then
            cooldownBar.AnchorPoint = Vector2.new(0, 1)
            cooldownBar.Position = UDim2.new(0, 0, 1, 0)
            cooldownBar.Size = UDim2.new(1, 0, 0, 0)
        end
    end
end

Initialize()
