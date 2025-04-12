--[[ Event
    Core event system that provides a common foundation for event handling.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-12
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--[[ Type Definitions ]]
export type EventConfig = {
    server: boolean?,
    client: boolean?,
    reliable: boolean?,
    throttle: number?,
    validate: boolean?,
    schema: {[string]: string|{type: string, validator: (any) -> boolean}}?,
    local_only: boolean?
}

export type EventDefinition = {
    name: string,
    remote: boolean,
    bindable: BindableEvent,
    remoteEvent: RemoteEvent?,
    config: EventConfig,
    connections: {[string]: RBXScriptConnection}
}

export type FunctionDefinition = {
    name: string,
    remote: RemoteFunction?,
    callback: ((player: Player, ...any) -> ...any)?
}

--[[ Constants ]]
local IGNORED_LOGS = {
    ["Heartbeat"] = true,
    ["PreRender"] = true,
    ["PostRender"] = true,
    ["PreSimulation"] = true,
    ["PostSimulation"] = true,
    ["PreAnimation"] = true,
    ["PostAnimation"] = true,
    ["SteppedUpdate"] = true
}

local DEFAULT_EVENT_CONFIG = {
    server = true,
    client = true,
    reliable = true,
    local_only = false
}

--[[ Built-in Validators ]]
local Validators = {
    -- Basic Types
    string = function(value) return type(value) == "string" end,
    number = function(value) return type(value) == "number" end,
    boolean = function(value) return type(value) == "boolean" end,
    table = function(value) return type(value) == "table" end,
    ["function"] = function(value) return type(value) == "function" end,

    -- Roblox Types
    Instance = function(value) return typeof(value) == "Instance" end,
    Vector3 = function(value) return typeof(value) == "Vector3" end,
    CFrame = function(value) return typeof(value) == "CFrame" end,
    Color3 = function(value) return typeof(value) == "Color3" end,

    -- Numbers
    int = function(value) return type(value) == "number" and value % 1 == 0 end,
    positiveNumber = function(value) return type(value) == "number" and value > 0 end,
    negativeNumber = function(value) return type(value) == "number" and value < 0 end,
    nonNegativeNumber = function(value) return type(value) == "number" and value >= 0 end,

    -- Game Specific
    userId = function(value) return type(value) == "number" and value > 0 end,
    playerInstance = function(value) return typeof(value) == "Instance" and value:IsA("Player") end,

    -- Strings
    nonEmptyString = function(value) return type(value) == "string" and #value > 0 end,
    alphanumeric = function(value)
        return type(value) == "string" and not not value:match("^[%w_]+$")
    end,

    -- Tables
    nonEmptyTable = function(value) return type(value) == "table" and next(value) ~= nil end,
    array = function(value)
        if type(value) ~= "table" then return false end
        local length = #value
        return length > 0 and length == (function()
            local count = 0
            for _ in pairs(value) do count += 1 end
            return count
        end)()
    end
}

--[[ Validation Functions ]]
local function ValidateData(data, schema, eventName)
    if type(data) ~= "table" then
        return false, "Expected table, got " .. type(data)
    end

    for field, validator in pairs(schema) do
        local value = data[field]
        if value == nil then
            return false, string.format("Missing required field '%s' in event %s", field, eventName)
        end

        local validatorType = type(validator)
        local success = false

        if validatorType == "string" then
            local validatorFn = Validators[validator]
            if not validatorFn then
                warn(string.format("Unknown validator '%s' for field '%s' in event %s", validator, field, eventName))
                continue
            end
            success = validatorFn(value)
        elseif validatorType == "table" then
            if validator.type then
                local typeValidator = Validators[validator.type]
                success = typeValidator and typeValidator(value)
                if success and validator.validator then
                    success = validator.validator(value)
                end
            end
        elseif validatorType == "function" then
            success = validator(value)
        end

        if not success then
            return false, string.format("Validation failed for field '%s' in event %s", field, eventName)
        end
    end

    return true
end

--[[ Helper Functions ]]
local function GetCaller()
    local stackTrace = debug.traceback()
    local lines = string.split(stackTrace, "\n")

    local caller = "unknown"
    for i = 1, #lines do
        local line = lines[i]:gsub("%s+", "")

        if line == "" or line:find("Event%.") or line:find("GetCaller") then
            continue
        end

        local patterns = {
            "([^:]+%.lua[au]*):%d+",
            "Script'([^']+)',%s*Line%s*(%d+)",
            "([%w%p]+):%s*(%d+)",
        }

        for _, pattern in ipairs(patterns) do
            local filePath, lineNum
            if pattern:find("Script") then
                filePath, lineNum = line:match(pattern)
            else
                filePath = line:match(pattern)
                lineNum = line:match(":(%d+)")
            end

            if filePath and lineNum then
                filePath = filePath:gsub("^%s*", ""):gsub("%s*$", "")
                filePath = filePath:gsub("^game%.", "")

                caller = string.format("%s:%s", filePath, lineNum)
                return caller
            end
        end
    end

    for i = 1, #lines do
        local line = lines[i]:gsub("%s+", "")
        if line ~= "" and not line:find("Event%.") and not line:find("GetCaller") then
            return string.format("unknown (%s)", line:sub(1, 100))
        end
    end

    return caller
end

local function CreateEventsFolder()
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end
    return eventsFolder
end

local function CreateFunctionsFolder()
    local functionsFolder = ReplicatedStorage:FindFirstChild("Functions")
    if not functionsFolder then
        functionsFolder = Instance.new("Folder")
        functionsFolder.Name = "Functions"
        functionsFolder.Parent = ReplicatedStorage
    end
    return functionsFolder
end

--[[ Event Class ]]
local Event = {}
Event.__index = Event

function Event.New(config)
    local self = setmetatable({
        events = {},
        functions = {},
        connections = {},
        remoteEvents = {},
        remoteFunctions = {},
        warnedEvents = {},
        eventConfigs = {},
        validators = table.clone(Validators),
        isServer = RunService:IsServer(),
        config = config or {},
        pendingEvents = {},
        pendingFunctions = {}
    }, Event)

    self.eventsFolder = CreateEventsFolder()
    self.functionsFolder = CreateFunctionsFolder()
    self:Init()

    return self
end

function Event:Init()
    if self.isServer then
        return
    end

    self.eventsFolder.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") then
            self.remoteEvents[child.Name] = child
            self:SetupRemoteEvent(child)

            if self.pendingEvents[child.Name] then
                for _, callback in ipairs(self.pendingEvents[child.Name]) do
                    task.spawn(callback, child)
                end
                self.pendingEvents[child.Name] = nil
            end
        end
    end)

    for _, remoteEvent in ipairs(self.eventsFolder:GetChildren()) do
        if remoteEvent:IsA("RemoteEvent") then
            self.remoteEvents[remoteEvent.Name] = remoteEvent
            self:SetupRemoteEvent(remoteEvent)
        end
    end

    self.functionsFolder.ChildAdded:Connect(function(child)
        if child:IsA("RemoteFunction") then
            self.remoteFunctions[child.Name] = child

            if self.pendingFunctions[child.Name] then
                for _, callback in ipairs(self.pendingFunctions[child.Name]) do
                    task.spawn(callback, child)
                end
                self.pendingFunctions[child.Name] = nil
            end
        end
    end)

    for _, remoteFunction in ipairs(self.functionsFolder:GetChildren()) do
        if remoteFunction:IsA("RemoteFunction") then
            self.remoteFunctions[remoteFunction.Name] = remoteFunction
        end
    end

    return true
end

function Event:SetupRemoteEvent(remoteEvent)
    if self.isServer then return end

    local eventName = remoteEvent.Name
    if not self.connections[eventName] then
        self.connections[eventName] = remoteEvent.OnClientEvent:Connect(function(...)
            self:FireListeners(eventName, ...)
        end)
    end
end

function Event:AddValidator(name, validator)
    if type(validator) ~= "function" then
        warn("Validator must be a function")
        return
    end
    self.validators[name] = validator
end

function Event:RegisterEvent(eventName, config)
    if type(eventName) ~= "string" then
        warn("Attempted to register invalid event name:", eventName, "at", GetCaller())
        return nil
    end

    if self.events[eventName] then
        return self.events[eventName]
    end

    local finalConfig = table.clone(DEFAULT_EVENT_CONFIG)
    if type(config) == "table" then
        for k, v in pairs(config) do
            finalConfig[k] = v
        end
    elseif type(config) == "boolean" then
        finalConfig.server = config
        finalConfig.client = config
    end

    if finalConfig.validate and finalConfig.schema then
        local originalEvent = self.events[eventName]
        if originalEvent then
            local originalBindable = originalEvent.bindable
            local newBindable = Instance.new("BindableEvent")
            originalEvent.bindable = newBindable

            newBindable.Event:Connect(function(...)
                local args = table.pack(...)
                local data = args[args.n]

                if ValidateData(data, finalConfig.schema, eventName) then
                    originalBindable:Fire(...)
                else
                    warn(string.format("Event %s validation failed", eventName))
                end
            end)
        end
    end

    self.eventConfigs[eventName] = finalConfig

    local isRemote = finalConfig.server or finalConfig.client
    if finalConfig.local_only then
        isRemote = false
    end

    local remoteEvent

    if isRemote then
        if self.isServer then
            remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = self.eventsFolder

            remoteEvent.OnServerEvent:Connect(function(player, ...)
                self.events[eventName].bindable:Fire(player, ...)
            end)
        else
            remoteEvent = self.remoteEvents[eventName]
            if not remoteEvent then
                remoteEvent = self.eventsFolder:FindFirstChild(eventName)
                if remoteEvent then
                    self.remoteEvents[eventName] = remoteEvent
                    self:SetupRemoteEvent(remoteEvent)
                end
            end
        end
    end

    self.events[eventName] = {
        name = eventName,
        remote = isRemote,
        bindable = Instance.new("BindableEvent"),
        remoteEvent = remoteEvent,
        config = finalConfig,
        connections = {}
    }

    return self.events[eventName]
end

--[[ Remote Functions ]]
function Event:RegisterFunction(functionName)
    if type(functionName) ~= "string" then
        warn("Attempted to register invalid function name:", functionName)
        return
    end

    if not self.isServer then
        warn("RegisterFunction can only be called on the server")
        return
    end

    if self.functions[functionName] then
        return self.functions[functionName]
    end

    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = functionName
    remoteFunction.Parent = self.functionsFolder

    self.functions[functionName] = {
        name = functionName,
        remote = remoteFunction,
        callback = nil
    }

    return self.functions[functionName]
end

function Event:SetCallback(functionName, callback)
    if not self.isServer then
        warn("SetCallback can only be called on the server")
        return
    end

    if type(callback) ~= "function" then
        warn("Callback must be a function")
        return
    end

    if not self.functions[functionName] then
        self:RegisterFunction(functionName)
    end

    local func = self.functions[functionName]
    func.callback = callback
    func.remote.OnServerInvoke = function(player, ...)
        return callback(player, ...)
    end
end

function Event:InvokeServer(functionName, ...)
    if self.isServer then
        warn("InvokeServer can only be called on the client")
        return nil
    end

    local args = {...}

    local remoteFunction = self.remoteFunctions[functionName]
    if remoteFunction then
        local success, result = pcall(function()
            return remoteFunction:InvokeServer(unpack(args))
        end)

        if not success then
            warn("Failed to invoke server function:", functionName, result)
            return nil
        end
        return result
    end

    remoteFunction = self.functionsFolder:FindFirstChild(functionName)
    if remoteFunction then
        self.remoteFunctions[functionName] = remoteFunction
        local success, result = pcall(function()
            return remoteFunction:InvokeServer(unpack(args))
        end)

        if not success then
            warn("Failed to invoke server function:", functionName, result)
            return nil
        end
        return result
    end

    if not self.pendingFunctions[functionName] then
        self.pendingFunctions[functionName] = {}
    end

    local result
    local resultReady = false

    local handleFunction = function(fn)
        local success, fnResult = pcall(function()
            return fn:InvokeServer(unpack(args))
        end)

        if success then
            result = fnResult
        else
            warn("Failed to invoke server function:", functionName, fnResult)
        end
        resultReady = true
    end

    table.insert(self.pendingFunctions[functionName], handleFunction)

    task.delay(0.5, function()
        if not resultReady then
            resultReady = true
            warn("Timed out waiting for RemoteFunction:", functionName)
        end
    end)

    while not resultReady do
        task.wait()
    end

    return result
end

--[[ Event Listening ]]
function Event:On(eventName, callback)
    if not self.events[eventName] then
        self:RegisterEvent(eventName)
    end
    return self.events[eventName].bindable.Event:Connect(callback)
end

function Event:Once(eventName, callback)
    if not self.events[eventName] then
        self:RegisterEvent(eventName)
    end
    return self.events[eventName].bindable.Event:Once(callback)
end

function Event:OnServerEvent(eventName, callback)
    if not self.isServer then
        warn("OnServerEvent can only be called on the server")
        return
    end

    if not self.events[eventName] then
        self:RegisterEvent(eventName, true)
    end

    local event = self.events[eventName]
    if not event.remote then
        warn("Attempted to listen to server events on non-remote event:", eventName)
        return
    end

    return event.remoteEvent.OnServerEvent:Connect(function(...)
        callback(...)
    end)
end

function Event:OnClientEvent(eventName, callback)
    if self.isServer then
        warn("OnClientEvent can only be called on the client")
        return
    end

    return self:On(eventName, callback)
end

function Event:FireListeners(eventName, ...)
    local event = self.events[eventName]
    if not event then return end

    local args = {...}
    event.bindable:Fire(unpack(args))
end

--[[ Event Firing ]]
function Event:Fire(eventName, ...)
    if type(eventName) ~= "string" then
        if not self.warnedEvents["invalid_type"] then
            warn("Attempted to fire event with invalid name type:", type(eventName))
            self.warnedEvents["invalid_type"] = true
        end
        return
    end

    local event = self.events[eventName]
    if not event then
        event = self:RegisterEvent(eventName)
    end

    if event.config.local_only then
        self:FireListeners(eventName, ...)
        return
    end

    if self.isServer then
        local args = {...}
        if event.remote then
            if #args > 0 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                local player = table.remove(args, 1)
                event.remoteEvent:FireClient(player, unpack(args))
            else
                event.remoteEvent:FireAllClients(...)
            end
        end
    else
        self:FireServer(eventName, ...)
    end

    event.bindable:Fire(...)
end

function Event:FireTo(player, eventName, ...)
    if not self.isServer then
        warn("FireTo can only be called on the server")
        return
    end

    if not self.events[eventName] then
        self:RegisterEvent(eventName, {
            server = true,
            client = true
        })
    end

    local event = self.events[eventName]
    if not event.remote then
        warn("Attempted to fire non-remote event to client:", eventName)
        return
    end

    local args = {...}
    local success, err = pcall(function()
        event.remoteEvent:FireClient(player, unpack(args))
    end)

    if not success then
        warn("Failed to fire event:", eventName, err)
    end
end

function Event:FireAllExcept(excludedPlayer, eventName, ...)
    if not self.isServer then
        warn("FireAllExcept can only be called on the server")
        return
    end

    if not self.events[eventName] then
        self:RegisterEvent(eventName, {
            server = true,
            client = true
        })
    end

    local event = self.events[eventName]
    if not event.remote then
        warn("Attempted to fire non-remote event to clients:", eventName)
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= excludedPlayer then
            event.remoteEvent:FireClient(player, ...)
        end
    end
end

function Event:FireServer(eventName, ...)
    if self.isServer then
        warn("FireServer can only be called on the client")
        return
    end

    if type(eventName) ~= "string" then
        warn("Invalid event name type:", type(eventName))
        return
    end

    local event = self.events[eventName]
    if event and event.config.local_only then
        warn("Attempted to fire local-only event to server:", eventName)
        return
    end

    local args = {...}

    local remoteEvent = self.remoteEvents[eventName]
    if remoteEvent then
        local success, err = pcall(function()
            remoteEvent:FireServer(unpack(args))
        end)

        if not success then
            warn("Failed to fire server event:", eventName, err)
        end
        return
    end

    remoteEvent = self.eventsFolder:FindFirstChild(eventName)
    if remoteEvent then
        self.remoteEvents[eventName] = remoteEvent
        local success, err = pcall(function()
            remoteEvent:FireServer(unpack(args))
        end)

        if not success then
            warn("Failed to fire server event:", eventName, err)
        end
        return
    end

    if not self.pendingEvents[eventName] then
        self.pendingEvents[eventName] = {}
    end

    local handleEvent = function(evt)
        local success, err = pcall(function()
            evt:FireServer(unpack(args))
        end)

        if not success then
            warn("Failed to fire server event:", eventName, err)
        end
    end

    table.insert(self.pendingEvents[eventName], handleEvent)

    task.delay(0.5, function()
        if self.pendingEvents[eventName] then
            warn("Timed out waiting for RemoteEvent:", eventName)
            self.pendingEvents[eventName] = nil
        end
    end)
end

function Event:Cleanup()
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    for _, event in pairs(self.events) do
        if event.bindable then
            event.bindable:Destroy()
        end
        if event.remoteEvent and self.isServer then
            event.remoteEvent:Destroy()
        end
    end

    for _, func in pairs(self.functions) do
        if func.remote and self.isServer then
            func.remote:Destroy()
        end
    end

    table.clear(self.connections)
    table.clear(self.events)
    table.clear(self.remoteEvents)
    table.clear(self.functions)
    table.clear(self.remoteFunctions)
    table.clear(self.warnedEvents)
    table.clear(self.eventConfigs)
    table.clear(self.pendingEvents)
    table.clear(self.pendingFunctions)
end

Event.Connect = Event.On
Event.FireClient = Event.FireTo
Event.Disconnect = function(connection) connection:Disconnect() end

return Event
