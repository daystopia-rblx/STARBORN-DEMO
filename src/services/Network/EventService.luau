--[[ EventService
    Core networking system for bidirectional server-client communication with validation.
    Handles event registration, remote functions, throttling, and connection management.
    @author @Daystopia
    @version 1.0.3
    @date 2025-02-12
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[[ Type Definitions ]]
export type EventConfig = {
    server: boolean?,
    client: boolean?,
    reliable: boolean?,
    throttle: number?,
    validate: boolean?,
    schema: {[string]: string|{type: string, validator: (any) -> boolean}}?
}

export type EventDefinition = {
    name: string,
    remote: boolean,
    bindable: BindableEvent,
    remoteEvent: RemoteEvent?,
    config: EventConfig,
    connections: {[string]: RBXScriptConnection}
}

local EventService = {
    events = {},
    functions = {},
    connections = {},
    warnedEvents = {},
    eventConfigs = {},
    validators = {}
}

--[[ Constants ]]
local DEBUG = false

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

local EVENT_CONFIG = {
    server = true,
    client = true,
    reliable = true
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

EventService.validators = Validators

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

function EventService:AddValidator(name, validator)
    if type(validator) ~= "function" then
        warn("Validator must be a function")
        return
    end
    self.validators[name] = validator
end

--[[ Helper Functions ]]
local function GetCaller()
    local stackTrace = debug.traceback()
    local lines = string.split(stackTrace, "\n")

    if DEBUG then
        print("Stack trace:")
        for i, line in ipairs(lines) do
            print(i, line)
        end
    end

    local caller = "unknown"
    for i = 1, #lines do
        local line = lines[i]:gsub("%s+", "")

        if line == "" or line:find("EventService") or line:find("GetCaller") then
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

                if DEBUG then
                    print("Found caller:", caller, "from line:", line)
                end

                return caller
            end
        end
    end

    for i = 1, #lines do
        local line = lines[i]:gsub("%s+", "")
        if line ~= "" and not line:find("EventService") and not line:find("GetCaller") then
            return string.format("unknown (%s)", line:sub(1, 100))
        end
    end

    return caller
end

local function CreateFolder()
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end
    return eventsFolder
end

--[[ Core Methods ]]
function EventService:Init()
    if not self.events then
        self.events = {}
    end
    if not self.connections then
        self.connections = {}
    end
    return true
end

function EventService:Cleanup()
    for _, event in pairs(self.events) do
        if event.bindable then
            event.bindable:Destroy()
        end
        if event.remoteEvent then
            event.remoteEvent:Destroy()
        end
    end

    for _, func in pairs(self.functions) do
        if func.remote then
            func.remote:Destroy()
        end
    end

    table.clear(self.events)
    table.clear(self.functions)
    table.clear(self.connections)
    table.clear(self.warnedEvents)
end

--[[ Event Registration ]]
function EventService:RegisterEvent(eventName: string, config: EventConfig?)
    if type(eventName) ~= "string" then
        warn("Attempted to register invalid event name:", eventName, "at", GetCaller())
        return
    end

    local finalConfig = table.clone(EVENT_CONFIG)
    if type(config) == "table" then
        for k, v in pairs(config) do
            finalConfig[k] = v
        end
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

    if self.events[eventName] then
        if DEBUG and not IGNORED_LOGS[eventName] then
            print("Event already registered:", eventName)
        end
        return
    end

    local isRemote = finalConfig.server or finalConfig.client

    self.events[eventName] = {
        name = eventName,
        remote = isRemote,
        bindable = Instance.new("BindableEvent"),
        remoteEvent = isRemote and Instance.new("RemoteEvent") or nil,
        config = finalConfig,
        connections = {}
    }

    if isRemote then
        local eventFolder = CreateFolder()
        local remoteEvent = self.events[eventName].remoteEvent
        remoteEvent.Name = eventName
        remoteEvent.Parent = eventFolder
    end

    if DEBUG and not IGNORED_LOGS[eventName] then
        print("Registered event:", eventName, "with config:", finalConfig)
    end
end

--[[ Event Listening ]]
function EventService:On(eventName, callback)
    if not self.events[eventName] then
        self:RegisterEvent(eventName)
    end
    return self.events[eventName].bindable.Event:Connect(callback)
end

function EventService:Once(eventName, callback)
    if not self.events[eventName] then
        self:RegisterEvent(eventName)
    end
    return self.events[eventName].bindable.Event:Once(callback)
end

function EventService:OnServerEvent(eventName, callback)
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

function EventService:OnClientEvent(eventName, callback)
    if type(eventName) ~= "string" then
        warn("Attempted to listen to client event with invalid name type:", type(eventName))
        return
    end

    if not self.events[eventName] then
        self:RegisterEvent(eventName, true)
    end

    local eventFolder = CreateFolder()
    local remoteEvent = eventFolder:WaitForChild(eventName, 5)
    if not remoteEvent then
        warn("Failed to find RemoteEvent:", eventName)
        return
    end

    local connection = remoteEvent.OnClientEvent:Connect(function(...)
        callback(...)
    end)

    return connection
end

--[[ Event Firing ]]
function EventService:Fire(eventName, ...)
    if type(eventName) ~= "string" then
        if not self.warnedEvents["invalid_type"] then
            warn("Attempted to fire event with invalid name type:", type(eventName))
            self.warnedEvents["invalid_type"] = true
        end
        return
    end

    if DEBUG and not IGNORED_LOGS[eventName] then
        print("Firing event:", eventName)
    end

    if not self.events[eventName] then
        self:RegisterEvent(eventName)
    end

    local event = self.events[eventName]
    if event.remote then
        if RunService:IsServer() then
            event.remoteEvent:FireAllClients(...)
        else
            event.bindable:Fire(...)
            return
        end
    end
    event.bindable:Fire(...)
end

function EventService:FireTo(player, eventName, ...)
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

function EventService:FireAllExcept(excludedPlayer, eventName, ...)
    if self.events[eventName] and self.events[eventName].remote then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= excludedPlayer then
                self.events[eventName].remoteEvent:FireClient(player, ...)
            end
        end
    end
end

function EventService:FireServer(eventName, ...)
    if type(eventName) ~= "string" then
        warn("Attempted to fire server event with invalid name type:", type(eventName))
        return
    end

    if not self.events[eventName] then
        self:RegisterEvent(eventName, true)
    end

    local event = self.events[eventName]
    if not event.remote then
        warn("Attempted to fire non-remote event:", eventName)
        return
    end

    local eventFolder = CreateFolder()
    local remoteEvent = eventFolder:FindFirstChild(eventName)
    if not remoteEvent then
        warn("RemoteEvent not found:", eventName)
        return
    end

    local args = {...}
    local success, err = pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)

    if not success then
        warn("Failed to fire server event:", eventName, err)
    end
end

EventService.Connect = EventService.On
EventService.FireClient = EventService.FireTo
EventService.Disconnect = function(connection) connection:Disconnect() end

--[[ Remote Function Management ]]
function EventService:RegisterFunction(functionName)
    if type(functionName) ~= "string" then
        warn("Attempted to register invalid function name:", functionName, "at", GetCaller())
        return
    end

    if self.functions[functionName] then
        if DEBUG then
            print("Function already registered:", functionName)
        end
        return
    end

    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = functionName
    remoteFunction.Parent = script

    self.functions[functionName] = {
        name = functionName,
        remote = remoteFunction,
        callback = nil
    }

    if DEBUG then
        print("Registered remote function:", functionName)
    end
end

function EventService:SetCallback(functionName, callback)
    if not self.functions[functionName] then
        self:RegisterFunction(functionName)
    end

    local func = self.functions[functionName]
    func.callback = callback
    func.remote.OnServerInvoke = function(player, ...)
        return callback(player, ...)
    end
end

function EventService:InvokeServer(functionName, ...)
    if not self.functions[functionName] then
        self:RegisterFunction(functionName)
    end

    local func = self.functions[functionName]
    if not func.remote then
        warn("Remote function not found:", functionName)
        return nil
    end

    local args = {...}
    local success, result = pcall(function()
        return func.remote:InvokeServer(unpack(args))
    end)

    if not success then
        warn("Failed to invoke server function:", functionName, result)
        return nil
    end

    return result
end

return EventService