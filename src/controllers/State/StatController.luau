--[[ StatController
    Client-side stat system with UI updates and visual feedback.
    Manages health and aether bars.
    @author @Daystopia
    @version 1.0.3
    @date 2025-05-08
]]
local StatController = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

StatController.Dependencies = {
    "Event"
}

local Controllers
local Modules
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")

local UPDATE_SETTINGS = {
    FILL_DURATION = 0.2
}

local State = {
    ui = {
        health = HUD.Health,
        aether = HUD.Aether
    },
    stats = {}
}

StatController.Events = {
    Update = true
}

StatController.Listeners = {
    ["Stat.Update"] = function(self, data)
        if not data or not data.stat then return end

        local stat = data.stat:upper()
        local value = data.value

        local existingStat = State.stats[stat]
        local maxValue = data.maxValue or (existingStat and existingStat.maxValue) or value

        if data.metadata and data.metadata.type == "decay" then
            return
        end

        State.stats[stat] = {
            value = value,
            maxValue = maxValue
        }

        if stat == "HEALTH" then
            self:UpdateBar(State.ui.health, value, maxValue)
        elseif stat == "AETHER" then
            self:UpdateBar(State.ui.aether, value, maxValue)
        end
    end
}

function StatController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function StatController:Start()
    if State.ui.health and State.ui.health.Fill and State.ui.health.Fill:FindFirstChild("Mask") then
        State.ui.health.Fill.Mask.AnchorPoint = Vector2.new(1, 0)
        State.ui.health.Fill.Mask.Position = UDim2.new(1, 0, 0, 0)
        State.ui.health.Fill.Mask.Size = UDim2.new(0, 0, 1, 0)
    end

    if State.ui.aether and State.ui.aether.Fill and State.ui.aether.Fill:FindFirstChild("Mask") then
        State.ui.aether.Fill.Mask.AnchorPoint = Vector2.new(1, 0)
        State.ui.aether.Fill.Mask.Position = UDim2.new(1, 0, 0, 0)
        State.ui.aether.Fill.Mask.Size = UDim2.new(0, 0, 1, 0)
    end

    task.delay(0.3, function()
        self:UpdateBar(State.ui.health, 100, 100)
        self:UpdateBar(State.ui.aether, 100, 100)
    end)

    return true
end

function StatController:UpdateBar(bar, value, maxValue)
    if not bar or not bar:FindFirstChild("Fill") or not bar.Fill:FindFirstChild("Mask") then return end

    if maxValue == 0 then maxValue = 1 end
    local fillAmount = math.clamp(value / maxValue, 0, 1)

    local tweenInfo = TweenInfo.new(
        UPDATE_SETTINGS.FILL_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(
        bar.Fill.Mask,
        tweenInfo,
        {Size = UDim2.new(fillAmount, 0, 1, 0)}
    )

    tween:Play()

    return tween
end

function StatController:GetStat(statName)
    local stat = State.stats[statName:upper()]
    return stat and stat.value, stat and stat.maxValue
end

return StatController