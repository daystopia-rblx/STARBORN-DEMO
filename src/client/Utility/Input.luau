--[[ Input
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-03
]]
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Services.Network.DataService)

local Input = {}

--[[ Input Types ]]
export type InputAction = {
    name: string,
    keys: {Enum.KeyCode | Enum.UserInputType},
    callback: (state: boolean, ...any) -> (),
    condition: (() -> boolean)?,
    throttle: number?,
    lastTrigger: number?,
    requiresProcessed: boolean?,
    requiresGameFocus: boolean?
}

export type InputAxis = {
    name: string,
    keys: {[Enum.KeyCode | Enum.UserInputType]: number},
    callback: (value: number) -> (),
    deadzone: number?,
    condition: (() -> boolean)?,
    smooth: boolean?,
    smoothValue: number?
}

export type InputConfig = {
    id: string,
    actions: {InputAction}?,
    axes: {InputAxis}?,
    mouseSensitivity: number?,
    mouseEnabled: boolean?,
    keyboardEnabled: boolean?,
    gamepadEnabled: boolean?,
    touchEnabled: boolean?,
    requireGameFocus: boolean?,
    ignoreProcessed: boolean?
}

--[[ State Variables ]]
local activeInputs = {}
local currentAxes = {}
local lastAxisValues = {}
local inputConnections = {}
local clientConfigs = {}
local keybinds = {}
local defaultKeybinds = {}

--[[ Action/Axis Functions ]]
function Input.CheckActive(action: InputAction): boolean
    if not action or not action.keys then
        return false
    end

    for input, _ in pairs(activeInputs) do
        for _, key in ipairs(action.keys) do
            if input == key then
                return true
            end
        end
    end
    return false
end

function Input.ValidateAction(action: InputAction): boolean
    if action.condition and not action.condition() then
        return false
    end

    if action.throttle then
        local now = os.clock()
        if action.lastTrigger and (now - action.lastTrigger) < action.throttle then
            return false
        end
        action.lastTrigger = now
    end

    return true
end

function Input.CreateAction(name: string, keys: {any}, callback: (boolean) -> (), options: {[string]: any}?): InputAction
    options = options or {}

    if not keybinds[name] then
        keybinds[name] = table.clone(keys)
    end

    local actionKeys = keybinds[name] or keys

    return {
        name = name,
        keys = actionKeys,
        callback = callback,
        condition = options.condition,
        throttle = options.throttle,
        lastTrigger = nil,
        requiresProcessed = options.requiresProcessed,
        requiresGameFocus = options.requiresGameFocus
    }
end

function Input.CreateAxis(name: string, keys: {[any]: number}, callback: (number) -> (), options: {[string]: any}?): InputAxis
    options = options or {}

    return {
        name = name,
        keys = keys,
        callback = callback,
        deadzone = options.deadzone,
        condition = options.condition,
        smooth = options.smooth,
        smoothValue = options.smoothValue
    }
end

function Input.UpdateAxis(axis: InputAxis)
    local value = 0
    for input, scale in pairs(axis.keys) do
        if activeInputs[input] then
            value += scale
        end
    end

    if axis.deadzone and math.abs(value) < axis.deadzone then
        return
    end

    if axis.smooth then
        local lastValue = lastAxisValues[axis.name] or 0
        value = lastValue + (value - lastValue) * (axis.smoothValue or 0.5)
        lastAxisValues[axis.name] = value
    end

    currentAxes[axis.name] = value
    axis.callback(value)
end

--[[ Input Management ]]
function Input.HandleInput(config: InputConfig)
    if not config.id then
        config.id = "default"
    end

    if inputConnections[config.id] then
        for _, connection in pairs(inputConnections[config.id]) do
            connection:Disconnect()
        end
    end

    inputConnections[config.id] = {}
    clientConfigs[config.id] = config

    local function handleInputBegan(input: InputObject, gameProcessed: boolean)
        if config.ignoreProcessed and gameProcessed then return end

        local inputType = input.UserInputType
        local keyCode = input.KeyCode

        if not config.mouseEnabled and (
            inputType == Enum.UserInputType.MouseButton1 or
            inputType == Enum.UserInputType.MouseButton2 or
            inputType == Enum.UserInputType.MouseButton3
        ) then return end

        if not config.keyboardEnabled and inputType == Enum.UserInputType.Keyboard then return end
        if not config.gamepadEnabled and inputType == Enum.UserInputType.Gamepad1 then return end
        if not config.touchEnabled and inputType == Enum.UserInputType.Touch then return end

        activeInputs[inputType] = true
        if inputType == Enum.UserInputType.Keyboard then
            activeInputs[keyCode] = true
        end

        if config.actions then
            for _, action in ipairs(config.actions) do
                if (not action.requiresProcessed or not gameProcessed) and
                   Input.CheckActive(action) and Input.ValidateAction(action) then
                    action.callback(true)
                end
            end
        end
    end

    local function handleInputEnded(input: InputObject)
        local inputType = input.UserInputType
        local keyCode = input.KeyCode

        activeInputs[inputType] = nil
        if inputType == Enum.UserInputType.Keyboard then
            activeInputs[keyCode] = nil
        end

        if config.actions then
            for _, action in ipairs(config.actions) do
                if Input.CheckActive(action) and Input.ValidateAction(action) then
                    action.callback(false)
                end
            end
        end
    end

    local function updateAxes()
        if config.axes then
            for _, axis in ipairs(config.axes) do
                if not axis.condition or axis.condition() then
                    Input.UpdateAxis(axis)
                end
            end
        end
    end

    table.insert(inputConnections[config.id], UserInputService.InputBegan:Connect(handleInputBegan))
    table.insert(inputConnections[config.id], UserInputService.InputEnded:Connect(handleInputEnded))
    if config.axes then
        table.insert(inputConnections[config.id], RunService.RenderStepped:Connect(updateAxes))
    end

    return {
        Disconnect = function()
            for _, connection in pairs(inputConnections[config.id]) do
                connection:Disconnect()
            end
            inputConnections[config.id] = nil
            clientConfigs[config.id] = nil
        end,

        GetActiveInputs = function()
            return activeInputs
        end,

        GetCurrentAxis = function(axisName)
            return currentAxes[axisName]
        end
    }
end

function Input.CleanupAllInputs()
    for id, connections in pairs(inputConnections) do
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
        inputConnections[id] = nil
        clientConfigs[id] = nil
    end

    table.clear(activeInputs)
    table.clear(currentAxes)
    table.clear(lastAxisValues)
end

--[[ Keybind Management ]]
function Input.ImportKeybinds(actionKeybinds: {[string]: {Enum.KeyCode | Enum.UserInputType}})
    for action, keys in pairs(actionKeybinds) do
        if not defaultKeybinds[action] then
            defaultKeybinds[action] = table.clone(keys)
        end
        keybinds[action] = table.clone(keys)
    end
end

function Input.SetKeybind(action: string, keys: {Enum.KeyCode | Enum.UserInputType})
    keybinds[action] = table.clone(keys)

    if not Input.CheckDefault(action) then
        Input.SaveKeybinds()
    end

    for _, config in pairs(clientConfigs) do
        if config.actions then
            for _, actionObj in ipairs(config.actions) do
                if actionObj.name == action then
                    actionObj.keys = keys
                end
            end
        end
    end

    return true
end

function Input.GetKeybind(action: string): {Enum.KeyCode | Enum.UserInputType}?
    return keybinds[action]
end

function Input.GetAllKeybinds(): {[string]: {Enum.KeyCode | Enum.UserInputType}}
    return table.clone(keybinds)
end

function Input.ResetKeybind(action: string): boolean
    local default = defaultKeybinds[action]
    if default then
        Input.SetKeybind(action, default)
        Input.SaveKeybinds()
        return true
    end
    return false
end

function Input.ResetAllKeybinds()
    keybinds = table.clone(defaultKeybinds)
    Input.SaveKeybinds()

    for _, config in pairs(clientConfigs) do
        if config.actions then
            for _, action in ipairs(config.actions) do
                local default = defaultKeybinds[action.name]
                if default then
                    action.keys = default
                end
            end
        end
    end
end

function Input.CheckDefault(action: string): boolean
    local current = keybinds[action]
    local default = defaultKeybinds[action]

    if not current or not default then return true end
    if #current ~= #default then return false end

    for i, key in ipairs(current) do
        if key ~= default[i] then
            return false
        end
    end

    return true
end

--[[ Keybind Functions ]]
function Input.SerializeKeybinds(): {[string]: {string}}
    local serialized = {}

    for action, keys in pairs(keybinds) do
        if not Input.CheckDefault(action) then
            serialized[action] = {}
            for i, key in ipairs(keys) do
                if typeof(key) == "EnumItem" then
                    if key.EnumType == Enum.KeyCode then
                        table.insert(serialized[action], "KeyCode:" .. key.Name)
                    elseif key.EnumType == Enum.UserInputType then
                        table.insert(serialized[action], "UserInputType:" .. key.Name)
                    end
                end
            end
        end
    end

    return serialized
end

function Input.DeserializeKeybinds(data: {[string]: {string}})
    if not data then return end

    for action, serializedKeys in pairs(data) do
        local keys = {}
        for _, serialized in ipairs(serializedKeys) do
            local enumType, enumName = string.match(serialized, "(.+):(.+)")
            if enumType == "KeyCode" then
                local keyCode = Enum.KeyCode[enumName]
                if keyCode then
                    table.insert(keys, keyCode)
                end
            elseif enumType == "UserInputType" then
                local inputType = Enum.UserInputType[enumName]
                if inputType then
                    table.insert(keys, inputType)
                end
            end
        end

        if #keys > 0 then
            Input.SetKeybind(action, keys)
        end
    end
end

function Input.SaveKeybinds()
    local player = game.Players.LocalPlayer
    if not player then return end

    local serialized = Input.SerializeKeybinds()
    local playerData = DataService:GetData(tostring(player.UserId), "PlayerData")

    if playerData and playerData.settings then
        playerData.settings.keybinds = serialized
        DataService:SetData(tostring(player.UserId), playerData, "PlayerData")
    end
end

function Input.LoadKeybinds()
    local player = game.Players.LocalPlayer
    if not player then return end

    local playerData = DataService:GetData(tostring(player.UserId), "PlayerData")
    if playerData and playerData.settings and playerData.settings.keybinds then
        Input.DeserializeKeybinds(playerData.settings.keybinds)
    end
end

return Input