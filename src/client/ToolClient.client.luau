--[[ ToolClient
    Client-side tool system with input handling and visual feedback.
    Manages tool animations, effects, keybinds, and interaction states.
    @author @Daystopia
    @version 1.0.0
    @date 2025-02-26
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Modules = {
    Tool = require(ReplicatedStorage.Modules.ToolModule)
}

local Utility = {
    Animation = require(script.Parent.Utility.Animation),
    Sound = require(script.Parent.Utility.Sound)
}

--[[ Types ]]
type ToolContext = {
    tool: Tool,
    player: Player,
    inputType: Enum.UserInputType?,
    template: any,
    [string]: any
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local ActiveTools = {} :: {[Tool]: ToolContext}

--[[ Tool State ]]
local ToolState = {
    charging = {} :: {[Tool]: {inputType: string, startTime: number, data: any}},
    toggled = {} :: {[Tool]: {[string]: boolean}},
    holding = {} :: {[Tool]: {[string]: boolean}}
}

--[[ Tool Events ]]
local ToolEvents

--[[ Tool Events ]]
ToolEvents = {
    Equipped = function(tool: Tool, mouse)
        if not tool then return end

        local template = tool:GetAttribute("TOOL_TYPE") and Modules.Tool.Templates[tool:GetAttribute("TOOL_TYPE"):lower()]
        if not template then return end

        if template.cursors and template.cursors.default then
            if mouse then
                mouse.Icon = template.cursors.default
            end
        end

        ToolState.toggled[tool] = {}
        ToolState.holding[tool] = {}
        ToolState.charging[tool] = nil

        ActiveTools[tool] = {
            tool = tool,
            player = LocalPlayer,
            mouse = mouse,
            equipped = true,
            template = template,
            currentCursor = template.cursors and template.cursors.default or ""
        }

        local function handleInput(input: InputObject, gameProcessed: boolean, inputConfig: any)
            if gameProcessed then return end
            if not ActiveTools[tool] or not ActiveTools[tool].equipped then return end
            if not inputConfig then return end

            if input.UserInputType == Enum.UserInputType[inputConfig.type] then
                if inputConfig.usageType == "toggle" then
                    ToolState.toggled[tool][inputConfig.type] = not ToolState.toggled[tool][inputConfig.type]
                    if ToolState.toggled[tool][inputConfig.type] then
                        ToolEvents.Activated(tool, inputConfig.type)
                    else
                        ToolEvents.Deactivated(tool, inputConfig.type)
                    end
                elseif inputConfig.usageType == "continuous" then
                    ToolState.holding[tool][inputConfig.type] = true
                    ToolEvents.Activated(tool, inputConfig.type)
                elseif inputConfig.usageType == "single" then
                    ToolEvents.Activated(tool, inputConfig.type)
                elseif inputConfig.usageType == "charge" then
                    ToolState.charging[tool] = {
                        inputType = inputConfig.type,
                        startTime = os.clock()
                    }
                    ToolEvents.Activated(tool, inputConfig.type)
                end
            end
        end

        local function handleInputEnd(input: InputObject, gameProcessed: boolean, inputConfig: any)
            if gameProcessed then return end
            if not ActiveTools[tool] or not ActiveTools[tool].equipped then return end
            if not inputConfig then return end

            if input.UserInputType == Enum.UserInputType[inputConfig.type] then
                if inputConfig.usageType == "continuous" then
                    ToolState.holding[tool][inputConfig.type] = false
                    ToolEvents.Deactivated(tool, inputConfig.type)
                elseif inputConfig.usageType == "charge" then
                    local charging = ToolState.charging[tool]
                    if charging and charging.inputType == inputConfig.type then
                        local chargeTime = os.clock() - charging.startTime
                        if chargeTime >= (inputConfig.holdDuration or 0) then
                            ToolEvents.Deactivated(tool, inputConfig.type, {chargeTime = chargeTime})
                        end
                        ToolState.charging[tool] = nil
                    end
                end
            end
        end

        local connections = {}

        if template.inputs then
            for inputName, inputConfig in pairs(template.inputs) do
                table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    handleInput(input, gameProcessed, inputConfig)
                end))

                table.insert(connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
                    handleInputEnd(input, gameProcessed, inputConfig)
                end))
            end
        end

        ActiveTools[tool].connections = connections

        Services.Event:FireServer("Client.Tool.Equip", {
            tool = tool,
            player = LocalPlayer
        })
    end,

    Unequipped = function(tool: Tool)
        if not tool then return end

        if ActiveTools[tool] and ActiveTools[tool].connections then
            for _, connection in ipairs(ActiveTools[tool].connections) do
                connection:Disconnect()
            end
        end

        ToolState.toggled[tool] = {}
        ToolState.holding[tool] = {}
        ToolState.charging[tool] = nil

        if ActiveTools[tool] then
            ActiveTools[tool].equipped = false
            ActiveTools[tool] = nil
        end

        Services.Event:FireServer("Client.Tool.Unequip", {
            tool = tool,
            player = LocalPlayer
        })
    end,

    Activated = function(tool: Tool, inputType: string?, data: {[string]: any}?)
        if not tool then return end

        local template = tool:GetAttribute("TOOL_TYPE") and Modules.Tool.Templates[tool:GetAttribute("TOOL_TYPE"):lower()]
        if not template then return end

        if template.distance then
            local character = LocalPlayer.Character
            if not character then return end

            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

            local toolHandle = tool:FindFirstChild("Handle")
            if not toolHandle then return end

            if (toolHandle.Position - humanoidRootPart.Position).Magnitude > template.distance then
                Utility.Sound.Prompt("Error")
                return
            end
        end

        if ActiveTools[tool] then
            ActiveTools[tool].lastActivation = os.clock()
        end

        Services.Event:FireServer("Client.Tool.Activate", {
            tool = tool,
            player = LocalPlayer,
            inputType = inputType,
            data = data
        })
    end,

    Deactivated = function(tool: Tool, inputType: string?, data: {[string]: any}?)
        if not tool then return end

        if ActiveTools[tool] then
            ActiveTools[tool].lastDeactivation = os.clock()
        end

        Services.Event:FireServer("Client.Tool.Deactivate", {
            tool = tool,
            player = LocalPlayer,
            inputType = inputType,
            data = data
        })
    end
}

--[[ Tool Setup ]]
local function SetupTool(tool: Tool)
    if not tool:IsA("Tool") then return end

    tool.Equipped:Connect(function(mouse)
        ToolEvents.Equipped(tool, mouse)
    end)

    tool.Unequipped:Connect(function()
        ToolEvents.Unequipped(tool)
    end)

    tool.Activated:Connect(function()
        ToolEvents.Activated(tool)
    end)

    tool.Deactivated:Connect(function()
        ToolEvents.Deactivated(tool)
    end)

    if not tool.RequiresHandle then
        tool.RequiresHandle = true
    end

    local animations = tool:FindFirstChild("Animations")
    if animations then
        for _, animation in ipairs(animations:GetChildren()) do
            if animation:IsA("Animation") then
                game:GetService("ContentProvider"):PreloadAsync({animation})
            end
        end
    end
end

--[[ Events ]]
local Events = {
    ["Tool.Create"] = {
        handler = function(data)
            local tool = data.tool
            if not tool then return end
            SetupTool(tool)
        end
    }
}

--[[ Initialization ]]
local function Initialize()
    for eventName, event in pairs(Events) do
        Services.Event:Connect(eventName, event.handler)
    end

    local function setupTools(parent)
        for _, item in ipairs(parent:GetChildren()) do
            if item:IsA("Tool") then
                SetupTool(item)
            end
        end
    end

    setupTools(LocalPlayer:WaitForChild("Backpack"))
    if LocalPlayer.Character then
        setupTools(LocalPlayer.Character)
    end

    LocalPlayer.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            SetupTool(child)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                SetupTool(child)
            end
        end)
    end)
end

Initialize()