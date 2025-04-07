--[[ Debug
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-07
]]
local Debug = {}
Debug.__index = Debug

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bezier = require(ReplicatedStorage.Modules.Tool.Bezier)

local CollectionService = game:GetService("CollectionService")

-- Types
export type DebugConfig = {
    ENABLED: boolean,
    RATE_LIMIT: number,
    [string]: {
        ENABLED: boolean,
        [string]: any
    }
}

export type MarkerStyle = {
    Shape: "Sphere" | "Cross",
    Size: number,
    Color: Color3,
    Transparency: number,
    Duration: number,
    Pulse: boolean
}

local DEFAULT_MARKER_STYLE: MarkerStyle = {
    Shape = "Sphere",
    Size = 0.5,
    Color = Color3.fromRGB(255, 0, 0),
    Transparency = 0.3,
    Duration = 3,
    Pulse = false
}

function Debug.new(config: DebugConfig)
    local self = setmetatable({
        config = config,
        lastPrintTimes = {},
        messageCount = {},
        activeSequences = {},
        visualizations = {}
    }, Debug)

    return self
end

local function SetupPart(part: BasePart, style: MarkerStyle)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Color = style.Color
    part.Material = Enum.Material.Neon
    part.Transparency = style.Transparency
    CollectionService:AddTag(part, "DebugVisualization")
end

function Debug:CreateCross(position: Vector3, style: MarkerStyle)
    local size = style.Size
    local parts = {}

    local directions = {
        {Vector3.new(1, 0, 0), Vector3.new(0, 0, 0)},
        {Vector3.new(0, 1, 0), Vector3.new(0, 0, math.pi/2)},
        {Vector3.new(0, 0, 1), Vector3.new(0, math.pi/2, 0)}
    }

    for _, dir in ipairs(directions) do
        local part = Instance.new("Part")
        SetupPart(part, style)
        part.Size = Vector3.new(size * 1.5, size * 0.1, size * 0.1)
        part.CFrame = CFrame.new(position) * CFrame.Angles(dir[2].X, dir[2].Y, dir[2].Z)
        part.Parent = workspace
        table.insert(parts, part)
    end

    return parts
end

function Debug:CreateSphere(position: Vector3, style: MarkerStyle)
    local part = Instance.new("Part")
    SetupPart(part, style)
    part.Size = Vector3.new(style.Size, style.Size, style.Size)
    part.Position = position
    part.Shape = Enum.PartType.Ball
    part.Parent = workspace

    return {part}
end

function Debug:Point(position: Vector3, styleOrColor: MarkerStyle | Color3, size: number?)
    if not self.config.ENABLED then return end

    local finalStyle = table.clone(DEFAULT_MARKER_STYLE)

    if typeof(styleOrColor) == "Color3" then
        finalStyle.Color = styleOrColor
        if size then
            finalStyle.Size = size
        end
    elseif typeof(styleOrColor) == "table" then
        for k, v in pairs(styleOrColor) do
            finalStyle[k] = v
        end
    end

    local parts
    if finalStyle.Shape == "Cross" then
        parts = self:CreateCross(position, finalStyle)
    else
        parts = self:CreateSphere(position, finalStyle)
    end

    if finalStyle.Pulse then
        for _, part in ipairs(parts) do
            task.spawn(function()
                local startTime = os.clock()
                while os.clock() - startTime < finalStyle.Duration do
                    local alpha = (1 + math.sin(os.clock() * 8)) / 2
                    part.Transparency = finalStyle.Transparency + (0.7 * alpha)
                    task.wait()
                end
            end)
        end
    end

    table.insert(self.visualizations, {
        parts = parts,
        cleanupTime = os.clock() + finalStyle.Duration
    })

    self:CleanupVisualizations()
    return parts
end

function Debug:Path(points: {Vector3}, color: Color3?)
    if not self.config.ENABLED then return end

    color = color or Color3.fromRGB(255, 255, 0)

    local curve = Bezier.new(table.unpack(points))

    local segments = 20
    local lastPoint = nil
    local parts = {}

    for i = 0, segments do
        local t = i/segments
        local position = curve:CalculatePositionAt(t)

        if lastPoint then
            local direction = (position - lastPoint)
            local distance = direction.Magnitude
            local midpoint = lastPoint + direction * 0.5

            local part = Instance.new("Part")
            SetupPart(part, {
                Shape = "Sphere",
                Size = 0.2,
                Color = color,
                Transparency = 0.5,
                Duration = 3,
                Pulse = false
            })
            part.Size = Vector3.new(0.2, 0.2, distance)
            part.CFrame = CFrame.lookAt(midpoint, position) * CFrame.Angles(0, math.pi/2, 0)
            part.Parent = workspace

            table.insert(parts, part)
        end

        lastPoint = position
    end

    table.insert(self.visualizations, {
        parts = parts,
        cleanupTime = os.clock() + 3
    })

    self:CleanupVisualizations()
    return parts
end

function Debug:CleanupVisualizations()
    local currentTime = os.clock()
    local i = 1

    while i <= #self.visualizations do
        local viz = self.visualizations[i]
        if currentTime >= viz.cleanupTime then
            if viz.parts then
                for _, part in ipairs(viz.parts) do
                    part:Destroy()
                end
            end
            table.remove(self.visualizations, i)
        else
            i += 1
        end
    end
end

--[[ Print Functions ]]
function Debug:Print(category: string, subcategory: string, ...)
    if not self.config.ENABLED then return end
    if not self.config[category] or not self.config[category].ENABLED then return end
    if subcategory and not self.config[category][subcategory] then return end

    local key = category .. ":" .. (subcategory or "")
    local currentTime = os.clock()
    local message = ({...})[1]

    if message and type(message) == "string" and message:match("^=== .* DEBUG ===$") then
        if self.lastPrintTimes[key] and currentTime - self.lastPrintTimes[key] < self.config.RATE_LIMIT then
            self.messageCount[key] = (self.messageCount[key] or 0) + 1
            return
        end
        self.lastPrintTimes[key] = currentTime
        self.messageCount[key] = 0
        self.activeSequences[key] = true

    elseif message and type(message) == "string" and message:match("^===================+$") then
        self.activeSequences[key] = false
        if self.messageCount[key] and self.messageCount[key] > 0 then
            return
        end
        return

    elseif not self.activeSequences[key] then
        return
    end

    local args = {...}
    local formattedMessage = ""
    for i, arg in ipairs(args) do
        if typeof(arg) == "Vector3" then
            formattedMessage = formattedMessage .. string.format("%.2f, %.2f, %.2f", arg.X, arg.Y, arg.Z)
        else
            formattedMessage = formattedMessage .. tostring(arg)
        end
        if i < #args then
            formattedMessage = formattedMessage .. " "
        end
    end

    print(string.format("[DEBUG:%s%s] %s", category, subcategory and (":" .. subcategory) or "", formattedMessage))
end

return Debug