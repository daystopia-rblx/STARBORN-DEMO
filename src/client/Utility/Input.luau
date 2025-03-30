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

export type CameraConfig = {
    camera: Camera,
    sensitivity: {
        x: number?,
        y: number?,
        aim: number?,
        normal: number?
    }?,
    limits: {
        minY: number?,
        maxY: number?,
        minX: number?,
        maxX: number?
    }?,
    smoothing: {
        enabled: boolean?,
        speed: number?
    }?,
    shake: {
        trauma: number?,
        decay: number?,
        frequency: number?,
        amplitude: number?
    }?,
    recoil: {
        pattern: {Vector2}?,
        index: number?,
        strength: number?,
        recovery: number?,
        smoothing: number?
    }?
}

--[[ State ]]
local activeInputs = {}
local currentAxes = {}
local lastAxisValues = {}
local inputConnections = {}
local clientConfigs = {}

--[[ Helper Functions ]]
local function isInputActive(action: InputAction): boolean
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

local function canTriggerAction(action: InputAction): boolean
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

local function updateAxis(axis: InputAxis)
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

--[[ Core Functions ]]
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
                   isInputActive(action) and canTriggerAction(action) then
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
                if isInputActive(action) and canTriggerAction(action) then
                    action.callback(false)
                end
            end
        end
    end

    local function updateAxes()
        if config.axes then
            for _, axis in ipairs(config.axes) do
                if not axis.condition or axis.condition() then
                    updateAxis(axis)
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
        end
    }
end

--[[ Camera Control ]]
function Input.CreateCameraController(config: CameraConfig)
    local camera = config.camera
    local currentRotation = Vector2.new()
    local targetRotation = Vector2.new()
    local currentShakeOffset = Vector3.new()
    local trauma = 0

    local function updateCamera(deltaTime: number)
        if config.smoothing and config.smoothing.enabled then
            currentRotation = currentRotation:Lerp(
                targetRotation,
                (config.smoothing.speed or 0.2) * deltaTime
            )
        else
            currentRotation = targetRotation
        end

        if config.limits then
            currentRotation = Vector2.new(
                math.clamp(currentRotation.X, config.limits.minX or -math.huge, config.limits.maxX or math.huge),
                math.clamp(currentRotation.Y, config.limits.minY or -math.huge, config.limits.maxY or math.huge)
            )
        end

        local cf = CFrame.new(camera.CFrame.Position) *
            CFrame.Angles(
                math.rad(currentRotation.Y),
                math.rad(currentRotation.X),
                0
            )

        if config.shake and trauma > 0 then
            trauma = math.max(0, trauma - (config.shake.decay or 1) * deltaTime)

            local shake = trauma * trauma
            local freq = config.shake.frequency or 1
            local amp = config.shake.amplitude or 1
            local time = os.clock()

            currentShakeOffset = Vector3.new(
                math.noise(time * freq) * shake * amp,
                math.noise(time * freq + 100) * shake * amp,
                0
            )

            cf *= CFrame.new(currentShakeOffset)
        end

        camera.CFrame = cf
    end

    local connection = RunService.RenderStepped:Connect(updateCamera)

    return {
        AddRotation = function(delta: Vector2)
            local sens = config.sensitivity or {}
            targetRotation += Vector2.new(
                delta.X * (sens.x or 1),
                delta.Y * (sens.y or 1)
            )
        end,

        SetRotation = function(rotation: Vector2)
            targetRotation = rotation
        end,

        AddTrauma = function(amount: number)
            if config.shake then
                trauma = math.min(1, trauma + amount)
            end
        end,

        Cleanup = function()
            connection:Disconnect()
        end
    }
end

return Input