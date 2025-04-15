--[[ ToolController
    Client-side tool system with input handling and visual feedback.
    Manages tool animations, effects, keybinds, and interaction states.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-09
]]
local ToolController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

ToolController.Dependencies = {
    "Event"
}

--[[ State ]]
local Controllers
local Modules
local Utility = {
    Animation = require(ReplicatedStorage.Modules.Utility.Animation),
    Sound = require(ReplicatedStorage.Modules.Utility.Sound)
}
local LocalPlayer = Players.LocalPlayer
local State = {
    activeTools = {},
    charging = {},
    toggled = {},
    holding = {}
}

--[[ Events ]]
ToolController.Events = {
    Equipped = true,
    Unequipped = true,
    Activated = true,
    Deactivated = true
}

--[[ Listeners ]]
ToolController.Listeners = {
    ["Tool.Create"] = function(self, data)
        local tool = data.tool
        if not tool then return end
        self:SetupTool(tool)
    end
}

--[[ Core Functions ]]
function ToolController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

function ToolController:Start()
    local function setupTools(parent)
        for _, item in ipairs(parent:GetChildren()) do
            if item:IsA("Tool") then
                self:SetupTool(item)
            end
        end
    end

    setupTools(LocalPlayer:WaitForChild("Backpack"))
    if LocalPlayer.Character then
        setupTools(LocalPlayer.Character)
    end

    LocalPlayer.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            self:SetupTool(child)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                self:SetupTool(child)
            end
        end)
    end)

    return true
end

--[[ Tool Functions ]]
function ToolController:SetupTool(tool)
    if not tool:IsA("Tool") then return end

    tool.Equipped:Connect(function(mouse)
        self:OnEquipped(tool, mouse)
    end)

    tool.Unequipped:Connect(function()
        self:OnUnequipped(tool)
    end)

    tool.Activated:Connect(function()
        self:OnActivated(tool)
    end)

    tool.Deactivated:Connect(function()
        self:OnDeactivated(tool)
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

function ToolController:OnEquipped(tool, mouse)
    if not tool then return end

    local template = tool:GetAttribute("TOOL_TYPE") and Modules.Tool.Templates[tool:GetAttribute("TOOL_TYPE"):lower()]
    if not template then return end

    if template.cursors and template.cursors.default then
        if mouse then
            mouse.Icon = template.cursors.default
        end
    end

    State.toggled[tool] = {}
    State.holding[tool] = {}
    State.charging[tool] = nil

    State.activeTools[tool] = {
        tool = tool,
        player = LocalPlayer,
        mouse = mouse,
        equipped = true,
        template = template,
        currentCursor = template.cursors and template.cursors.default or ""
    }

    local connections = {}

    if template.inputs then
        for inputName, inputConfig in pairs(template.inputs) do
            table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                self:HandleInput(tool, input, gameProcessed, inputConfig)
            end))

            table.insert(connections, UserInputService.InputEnded:Connect(function(input, gameProcessed)
                self:HandleInputEnd(tool, input, gameProcessed, inputConfig)
            end))
        end
    end

    State.activeTools[tool].connections = connections

    Controllers.Event:FireServer("Tool.Equip", {
        tool = tool,
        player = LocalPlayer
    })
end

function ToolController:OnUnequipped(tool)
    if not tool then return end

    if State.activeTools[tool] and State.activeTools[tool].connections then
        for _, connection in ipairs(State.activeTools[tool].connections) do
            connection:Disconnect()
        end
    end

    State.toggled[tool] = {}
    State.holding[tool] = {}
    State.charging[tool] = nil

    if State.activeTools[tool] then
        State.activeTools[tool].equipped = false
        State.activeTools[tool] = nil
    end

    Controllers.Event:FireServer("Tool.Unequip", {
        tool = tool,
        player = LocalPlayer
    })
end

function ToolController:OnActivated(tool, inputType, data)
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

    if State.activeTools[tool] then
        State.activeTools[tool].lastActivation = os.clock()
    end

    Controllers.Event:FireServer("Tool.Activate", {
        tool = tool,
        player = LocalPlayer,
        inputType = inputType,
        data = data
    })
end

function ToolController:OnDeactivated(tool, inputType, data)
    if not tool then return end

    if State.activeTools[tool] then
        State.activeTools[tool].lastDeactivation = os.clock()
    end

    Controllers.Event:FireServer("Tool.Deactivate", {
        tool = tool,
        player = LocalPlayer,
        inputType = inputType,
        data = data
    })
end

function ToolController:HandleInput(tool, input, gameProcessed, inputConfig)
    if gameProcessed then return end
    if not State.activeTools[tool] or not State.activeTools[tool].equipped then return end
    if not inputConfig then return end

    if input.UserInputType == Enum.UserInputType[inputConfig.type] then
        if inputConfig.usageType == "toggle" then
            State.toggled[tool][inputConfig.type] = not State.toggled[tool][inputConfig.type]
            if State.toggled[tool][inputConfig.type] then
                self:OnActivated(tool, inputConfig.type)
            else
                self:OnDeactivated(tool, inputConfig.type)
            end
        elseif inputConfig.usageType == "continuous" then
            State.holding[tool][inputConfig.type] = true
            self:OnActivated(tool, inputConfig.type)
        elseif inputConfig.usageType == "single" then
            self:OnActivated(tool, inputConfig.type)
        elseif inputConfig.usageType == "charge" then
            State.charging[tool] = {
                inputType = inputConfig.type,
                startTime = os.clock()
            }
            self:OnActivated(tool, inputConfig.type)
        end
    end
end

function ToolController:HandleInputEnd(tool, input, gameProcessed, inputConfig)
    if gameProcessed then return end
    if not State.activeTools[tool] or not State.activeTools[tool].equipped then return end
    if not inputConfig then return end

    if input.UserInputType == Enum.UserInputType[inputConfig.type] then
        if inputConfig.usageType == "continuous" then
            State.holding[tool][inputConfig.type] = false
            self:OnDeactivated(tool, inputConfig.type)
        elseif inputConfig.usageType == "charge" then
            local charging = State.charging[tool]
            if charging and charging.inputType == inputConfig.type then
                local chargeTime = os.clock() - charging.startTime
                if chargeTime >= (inputConfig.holdDuration or 0) then
                    self:OnDeactivated(tool, inputConfig.type, {chargeTime = chargeTime})
                end
                State.charging[tool] = nil
            end
        end
    end
end

function ToolController:GetActiveTool()
    local character = LocalPlayer.Character
    if not character then return nil end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return nil end

    return State.activeTools[tool] and tool or nil
end

return ToolController