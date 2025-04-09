--[[ Input
    @author @Daystopia
    @version 1.0.3
    @date 2025-04-05
]]
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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

local function ValidateAction(action: InputAction): boolean
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

local function BeginInput(input: InputObject, gameProcessed: boolean)
    local inputType = input.UserInputType
    local keyCode = input.KeyCode

    activeInputs[inputType] = true
    if inputType == Enum.UserInputType.Keyboard then
        activeInputs[keyCode] = true
    end

    for configId, config in pairs(clientConfigs) do
        if not config then continue end

        if config.ignoreProcessed and gameProcessed then 
            continue
        end

        if not config.mouseEnabled and (
            inputType == Enum.UserInputType.MouseButton1 or
            inputType == Enum.UserInputType.MouseButton2 or
            inputType == Enum.UserInputType.MouseButton3
        ) then 
            continue
        end

        if not config.keyboardEnabled and inputType == Enum.UserInputType.Keyboard then 
            continue
        end
        if not config.gamepadEnabled and inputType == Enum.UserInputType.Gamepad1 then 
            continue
        end
        if not config.touchEnabled and inputType == Enum.UserInputType.Touch then 
            continue
        end

        if config.actions and type(config.actions) == "table" and #config.actions > 0 then
            for i, action in ipairs(config.actions) do
                if not action then continue end

                local hasMatchingKey = false
                if action.keys and type(action.keys) == "table" then
                    for _, key in ipairs(action.keys) do
                        if key == keyCode or key == inputType then
                            hasMatchingKey = true
                            break
                        end
                    end

                    if hasMatchingKey and ValidateAction(action) then
                        if not action.requiresProcessed or not gameProcessed then
                            action.callback(true)
                        end
                    end
                end
            end
        end
    end
end

local function EndInput(input: InputObject)
    local inputType = input.UserInputType
    local keyCode = input.KeyCode

    activeInputs[inputType] = nil
    if inputType == Enum.UserInputType.Keyboard then
        activeInputs[keyCode] = nil
    end

    for configId, config in pairs(clientConfigs) do
        if config and config.actions and type(config.actions) == "table" and #config.actions > 0 then
            for _, action in ipairs(config.actions) do
                local hasMatchingKey = false
                if action and action.keys and type(action.keys) == "table" then
                    for _, key in ipairs(action.keys) do
                        if key == keyCode or key == inputType then
                            hasMatchingKey = true
                            break
                        end
                    end

                    if hasMatchingKey and ValidateAction(action) then
                        action.callback(false)
                    end
                end
            end
        end
    end
end

--[[ Action/Axis Functions ]]
function Input.CheckActive(action: InputAction): boolean
    if not action or not action.keys or type(action.keys) ~= "table" or #action.keys == 0 then
        return false
    end

    if not action.name then return false end

    if not activeInputs or type(activeInputs) ~= "table" then
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
    if not axis or not axis.keys or type(axis.keys) ~= "table" then
        return
    end

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

    if axis.name then
        currentAxes[axis.name] = value
    end

    if typeof(axis.callback) == "function" then
        axis.callback(value)
    end
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

    if not inputConnections[config.id] then
        inputConnections[config.id] = {}
    end

    clientConfigs[config.id] = config

    if not inputConnections.global then
        inputConnections.global = {}

        table.insert(inputConnections.global, UserInputService.InputBegan:Connect(BeginInput))
        table.insert(inputConnections.global, UserInputService.InputEnded:Connect(EndInput))

        table.insert(inputConnections.global, RunService.RenderStepped:Connect(function()
            for _, axisConfig in pairs(clientConfigs) do
                if axisConfig and axisConfig.axes and type(axisConfig.axes) == "table" and #axisConfig.axes > 0 then
                    for _, axis in ipairs(axisConfig.axes) do
                        if axis and (not axis.condition or axis.condition()) then
                            Input.UpdateAxis(axis)
                        end
                    end
                end
            end
        end))
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

return Input