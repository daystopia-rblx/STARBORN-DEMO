--[[ CombatClient
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-01
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Utility = {
    Controller = require(script.Parent.Utility.Controller),
    Sound = require(script.Parent.Utility.Sound)
}

--[[ Constants ]]
local UI_SETTINGS = {
    DEATH_SCREEN = {
        HOVER_DURATION = 1,
        FADE_DURATION = 0.6,
        BACKGROUND_DURATION = 3,
        HOVER_SIZE = UDim2.new(0.263, 0, 0.416, 0),
        HOVER_POSITION = UDim2.new(0.368, 0, 0.292, 0),
        DISPLAY_ORDER = 999999
    }
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CombatGui = PlayerGui:WaitForChild("CombatGui")

CombatGui.DisplayOrder = UI_SETTINGS.DEATH_SCREEN.DISPLAY_ORDER

--[[ State ]]
local State = {
    ui = {
        deathScreen = {
            enabled = false,
            frame = CombatGui:WaitForChild("Background"),
            hover = CombatGui:WaitForChild("DeathOverlay"),
            d1 = CombatGui:WaitForChild("d1"),
            d2 = CombatGui:WaitForChild("d2"),
            textLabel = CombatGui:WaitForChild("DeathLabel"),
            imageLabel = CombatGui:WaitForChild("DeathImage")
        }
    }
}

--[[ Interface Functions ]]
local function CreateDeath()
    local ui = State.ui.deathScreen
    if not ui.enabled then
        ui.enabled = true

        Utility.Sound.Play("SFX.Death")

        ui.d1.Visible = true
        ui.d2.Visible = true
        ui.hover.Visible = true

        Utility.Controller.Update({
            instance = ui.imageLabel,
            properties = { ImageTransparency = 0 },
            duration = UI_SETTINGS.DEATH_SCREEN.FADE_DURATION
        })

        Utility.Controller.Update({
            instance = ui.textLabel,
            properties = { TextTransparency = 0 },
            duration = UI_SETTINGS.DEATH_SCREEN.FADE_DURATION
        })

        task.wait(0.2)

        local hoverTween = Utility.Controller.Update({
            instance = ui.hover,
            properties = {
                Size = UI_SETTINGS.DEATH_SCREEN.HOVER_SIZE,
                Position = UI_SETTINGS.DEATH_SCREEN.HOVER_POSITION,
                ImageTransparency = 1
            },
            duration = UI_SETTINGS.DEATH_SCREEN.HOVER_DURATION,
            easingStyle = Enum.EasingStyle.Cubic,
            onComplete = function()
                task.wait(1.7)

                Utility.Controller.Update({
                    instance = ui.frame,
                    properties = { BackgroundTransparency = 0 },
                    duration = UI_SETTINGS.DEATH_SCREEN.BACKGROUND_DURATION
                })

                Utility.Controller.Update({
                    instance = ui.textLabel,
                    properties = { TextTransparency = 1 },
                    duration = UI_SETTINGS.DEATH_SCREEN.FADE_DURATION
                })

                task.wait(1.3)

                Utility.Controller.Update({
                    instance = ui.imageLabel,
                    properties = { ImageTransparency = 1 },
                    duration = UI_SETTINGS.DEATH_SCREEN.FADE_DURATION
                })
            end
        })
    end
end

--[[ Events ]]
local Events = {
    ["Combat.Death"] = {
        handler = function(data)
            CreateDeath()
        end
    }
}

--[[ Initialization ]]
local function Initialize()
    for eventName, handler in pairs(Events) do
        Services.Event:OnClientEvent(eventName, handler.handler)
    end
end

Initialize()