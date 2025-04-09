--[[ TeleportController
    Client-side teleportation system with loading screens and transitions.
    Manages teleport animations, progress indicators, and server transitions.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-09
]]
local TeleportController = {}

TeleportController.Dependencies = {
    "Event"
}

--[[ Modules ]]
local Controllers
local Modules

--[[ State ]]
local State = {
    activeScreen = nil,
    loadingScreens = {},
    isLoading = false
}

--[[ Events ]]
TeleportController.Events = {
    Init = true,
    Success = true,
    Fail = true,
    Queue = true,
    Retry = true
}

--[[ Listeners ]]
TeleportController.Listeners = {
    ["Teleport.Init"] = function(self, data)
        if State.isLoading then return end
        State.isLoading = true

        local config = data.config or {}
        local screen = self:CreateLoadingScreen(config)
        State.activeScreen = screen

        self:AnimateLoadingScreen(screen, true)
        Modules.Utility.Sound.Play("Teleport")
    end,

    ["Teleport.Success"] = function(self, data)
        if not State.activeScreen then return end
        State.isLoading = false

        self:AnimateLoadingScreen(State.activeScreen, false)
        task.wait(0.5)

        if State.activeScreen and State.activeScreen.gui then
            State.activeScreen.gui:Destroy()
        end
        State.activeScreen = nil
    end,

    ["Teleport.Fail"] = function(self, data)
        if not State.activeScreen then return end
        State.isLoading = false

        State.activeScreen.message.Text = data.error or "Teleport failed"
        task.wait(2)

        self:AnimateLoadingScreen(State.activeScreen, false)
        task.wait(0.5)

        if State.activeScreen and State.activeScreen.gui then
            State.activeScreen.gui:Destroy()
        end
        State.activeScreen = nil
    end,

    ["Teleport.Queue"] = function(self, data)
        if not State.activeScreen then return end
        State.activeScreen.message.Text = "Waiting in queue..."
    end,

    ["Teleport.Retry"] = function(self, data)
        if not State.activeScreen then return end
        State.activeScreen.message.Text = string.format("Retrying... (Attempt %d)", data.attempt)
    end
}

--[[ Core Functions ]]
function TeleportController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

--[[ State Functions ]]
function TeleportController:IsLoading()
    return State.isLoading
end

function TeleportController:GetActiveScreen()
    return State.activeScreen
end

--[[ Interface Functions ]]
function TeleportController:CreateLoadingScreen(config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportLoadingScreen"
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = game.Players.LocalPlayer.PlayerGui

    local background = Modules.Utility.Component.CreateFrame({
        Name = "Background",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        BackgroundTransparency = 1,
        Parent = screenGui
    })

    local container = Modules.Utility.Component.CreateFrame({
        Name = "Container",
        Size = UDim2.fromOffset(400, 200),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = background
    })

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromOffset(80, 80)
    icon.Position = UDim2.new(0.5, 0, 0.5, -30)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = config.icon or ""
    icon.Parent = container

    local message = Modules.Utility.Component.CreateLabel({
        Name = "Message",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -60),
        Text = config.message or "Teleporting...",
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.new(1, 1, 1),
        TextTransparency = 1,
        Parent = container
    })

    local dots = Modules.Utility.Component.CreateLabel({
        Name = "Dots",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -30),
        Text = "...",
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.new(1, 1, 1),
        TextTransparency = 1,
        Parent = container
    })

    return {
        gui = screenGui,
        background = background,
        container = container,
        icon = icon,
        message = message,
        dots = dots,
        config = config
    }
end

function TeleportController:AnimateLoadingScreen(screen, showing)
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local transparency = if showing then 0 else 1

    Modules.Utility.Controller.Update({
        instance = screen.background,
        properties = { BackgroundTransparency = transparency },
        duration = 0.5,
        easingStyle = Enum.EasingStyle.Quad
    })

    Modules.Utility.Controller.Update({
        instance = screen.message,
        properties = { TextTransparency = transparency },
        duration = 0.5,
        easingStyle = Enum.EasingStyle.Quad
    })

    Modules.Utility.Controller.Update({
        instance = screen.dots,
        properties = { TextTransparency = transparency },
        duration = 0.5,
        easingStyle = Enum.EasingStyle.Quad
    })

    if showing then
        local rotationTween = game:GetService("TweenService"):Create(screen.icon, TweenInfo.new(
            2,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out,
            -1
        ), {
            Rotation = 360
        })
        rotationTween:Play()

        local dotSequence = {".", "..", "..."}
        local dotIndex = 1
        local lastUpdate = os.clock()
        screen.dotAnimation = game:GetService("RunService").Heartbeat:Connect(function()
            if not screen.gui.Parent then
                screen.dotAnimation:Disconnect()
                return
            end

            local now = os.clock()
            if now - lastUpdate >= 0.5 then
                screen.dots.Text = dotSequence[dotIndex]
                dotIndex = (dotIndex % #dotSequence) + 1
                lastUpdate = now
            end
        end)
    else
        if screen.dotAnimation then
            screen.dotAnimation:Disconnect()
            screen.dotAnimation = nil
        end
    end
end

return TeleportController