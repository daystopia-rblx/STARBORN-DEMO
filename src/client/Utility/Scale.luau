local Scale = {}

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local DEFAULT_CONFIG = {
    minScale = 0.2,
    maxScale = 1.0,
    baseResolution = Vector2.new(1920, 1080)
}

local activeConfig = table.clone(DEFAULT_CONFIG)
local lastViewportSize = Camera.ViewportSize
local lastScale = 1

local function CalculateScale(): number
    local viewportSize = Camera.ViewportSize
    if viewportSize == lastViewportSize then
        return lastScale
    end

    local baseRes = activeConfig.baseResolution
    local scale = math.min(
        viewportSize.X / baseRes.X,
        viewportSize.Y / baseRes.Y
    )

    lastViewportSize = viewportSize
    lastScale = math.clamp(scale, activeConfig.minScale, activeConfig.maxScale)
    return lastScale
end

function Scale.GetScale(): number
    return CalculateScale()
end

function Scale.Apply(gui: GuiObject)
    if not gui then return end

    if type(gui) == "table" then
        gui = gui.frame
        if not (gui and typeof(gui) == "Instance" and gui:IsA("GuiObject")) then
            return
        end
    end

    if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then
        return
    end

    local uiScale = gui:FindFirstChild("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = gui
    end

    uiScale.Scale = CalculateScale()
end

function Scale.AutoScale(gui: GuiObject): () -> ()
    if not gui then return function() end end

    if type(gui) == "table" then
        gui = gui.frame
        if not (gui and typeof(gui) == "Instance" and gui:IsA("GuiObject")) then
            return function() end
        end
    end

    if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then
        return function() end
    end

    Scale.Apply(gui)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not gui.Parent then
            connection:Disconnect()
            return
        end
        Scale.Apply(gui)
    end)

    return function()
        connection:Disconnect()
    end
end

return Scale