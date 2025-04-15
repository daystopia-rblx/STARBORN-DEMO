--[[ StatController
    Client-side stat system with UI updates and visual feedback.
    Manages health, resonance, stamina, and other player statistics.
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-09
]]
local StatController = {}

local Players = game:GetService("Players")

StatController.Dependencies = {
    "Event"
}

--[[ State ]]
local Controllers
local Modules
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
            resonance = HUD.Center.Mana,
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
            block = HUD.Indicators.Block,
            dash = HUD.Indicators.Roll,
            slide = HUD.Indicators.Roll
        }
    },
    stats = {}
}

for i = 1, 5 do
    State.ui.hotbar.slots[i] = HUD.Hotbar:FindFirstChild("Slot_" .. i)
end

--[[ Events ]]
StatController.Events = {
    Update = true
}

--[[ Listeners ]]
StatController.Listeners = {
    ["Stat.Update"] = function(self, data)
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
            self:UpdateBar(State.ui.center[stat:lower()], value, maxValue)
        elseif State.ui.left[stat:lower()] then
            self:UpdateBar(State.ui.left[stat:lower()], value, maxValue)
        end
    end,

    ["Combat.Attack"] = function(self, response)
        if not response.success then return end
        if not response.data or not response.data.ability then return end

        local ability = response.data.ability:lower()
        local remaining = response.data.remaining
        local duration = response.data.duration

        if State.ui.indicators[ability] then
            self:UpdateCooldown(State.ui.indicators[ability], duration)
        end
    end,

    ["Status.Create"] = function(self, response)
        if not response or not response.state then return end

        local state = response.state:lower()
        local value = response.value

        if value == true then
            if state == "roll" then
                local duration = UPDATE_SETTINGS.COOLDOWN_DURATION

                if State.ui.indicators.roll then
                    self:UpdateCooldown(State.ui.indicators.roll, duration)
                else
                    warn("No indicator found for state:", state)
                end
            end
        end
    end,

    ["Skill.Update"] = function(self, data)
        if not data or not data.slot or not data.skill then return end

        local slot = State.ui.hotbar.slots[data.slot]
        if not slot then return end

        local skillLabel = slot:FindFirstChild("Skill")
        if skillLabel then
            skillLabel.Text = data.skill
        end
    end
}

--[[ Core Functions ]]
function StatController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function StatController:Start()
    for _, bar in pairs(State.ui.center) do
        self:UpdateBar(bar, 100, 100)
    end

    for _, bar in pairs(State.ui.left) do
        self:UpdateBar(bar, 100, 100)
    end

    for _, indicator in pairs(State.ui.indicators) do
        local cooldownBar = indicator:FindFirstChild("Cooldown")
        if cooldownBar then
            cooldownBar.AnchorPoint = Vector2.new(0, 1)
            cooldownBar.Position = UDim2.new(0, 0, 1, 0)
            cooldownBar.Size = UDim2.new(1, 0, 0, 0)
        end
    end

    return true
end

--[[ UI Functions ]]
function StatController:UpdateBar(bar, value, maxValue)
    if not bar or not bar:FindFirstChild("Mask") or not bar.Mask:FindFirstChild("Fill") then return end

    local fillAmount = math.clamp(value / maxValue, 0, 1)
    self:Update({
        instance = bar.Mask.Fill,
        properties = {
            Size = UDim2.new(fillAmount, 0, 1, 0)
        },
        duration = UPDATE_SETTINGS.FILL_DURATION
    })
end

function StatController:UpdateCooldown(indicator, duration)
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

    self:Update({
        instance = cooldownBar,
        properties = {
            Size = UDim2.new(1, 0, 0, 0)
        },
        duration = duration,
        easingStyle = self.Easing.Linear
    })
end

--[[ Utility Functions ]]
function StatController:Update(config)
    local instance = config.instance
    local properties = config.properties
    local duration = config.duration or 0.3
    local easingStyle = config.easingStyle or Enum.EasingStyle.Quad
    local easingDirection = config.easingDirection or Enum.EasingDirection.Out

    if not instance then return end

    local tweenInfo = TweenInfo.new(
        duration,
        easingStyle,
        easingDirection
    )

    local tween = game:GetService("TweenService"):Create(instance, tweenInfo, properties)
    tween:Play()

    return tween
end

StatController.Easing = {
    Linear = Enum.EasingStyle.Linear,
    Quad = Enum.EasingStyle.Quad,
    Cubic = Enum.EasingStyle.Cubic,
    Quart = Enum.EasingStyle.Quart,
    Quint = Enum.EasingStyle.Quint,
    Sine = Enum.EasingStyle.Sine,
    Back = Enum.EasingStyle.Back,
    Elastic = Enum.EasingStyle.Elastic,
    Bounce = Enum.EasingStyle.Bounce
}

--[[ Getters ]]
function StatController:GetStat(statName)
    local stat = State.stats[statName:upper()]
    return stat and stat.value, stat and stat.maxValue
end

return StatController
