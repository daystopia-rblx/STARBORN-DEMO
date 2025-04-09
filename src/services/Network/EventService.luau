--[[ EventService
    Core networking system for bidirectional server-client communication with validation.
    Handles event registration, remote functions, throttling, and connection management.
    @author @Daystopia
    @version 1.0.4
    @date 2025-04-09
]]
local EventService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Event = require(ReplicatedStorage.Modules.Core.Event)

--[[ Type Definitions ]]
export type EventConfig = Event.EventConfig
export type EventDefinition = Event.EventDefinition
export type FunctionDefinition = Event.FunctionDefinition

--[[ State ]]
EventService._isInitialized = false
EventService._warnedInitialization = false

--[[ Utility Functions ]]
local function CheckInitialized()
    if not EventService._isInitialized and not EventService._warnedInitialization then
        EventService._warnedInitialization = true
        warn("Attempted to use EventService before initialization")
        print("Call stack:", debug.traceback())
        return false
    end
    return EventService._isInitialized
end

--[[ Core Functions ]]
function EventService:Init()
    self._eventSystem = Event.New({
        debug = false
    })

    self.events = self._eventSystem.events
    self.functions = self._eventSystem.functions
    self.connections = self._eventSystem.connections
    self.warnedEvents = self._eventSystem.warnedEvents
    self.eventConfigs = self._eventSystem.eventConfigs
    self.validators = self._eventSystem.validators

    self._isInitialized = true
    return true
end

function EventService:Cleanup()
    if self._eventSystem then
        self._eventSystem:Cleanup()
    end
    self._isInitialized = false
    self._warnedInitialization = false
end

--[[ Event Registration ]]
function EventService:RegisterEvent(eventName, config)
    if not CheckInitialized() then return nil end
    return self._eventSystem:RegisterEvent(eventName, config)
end

--[[ Event Listening ]]
function EventService:On(eventName, callback)
    if not CheckInitialized() then return {Disconnect = function() end} end
    return self._eventSystem:On(eventName, callback)
end

function EventService:Once(eventName, callback)
    if not CheckInitialized() then return {Disconnect = function() end} end
    return self._eventSystem:Once(eventName, callback)
end

function EventService:OnServerEvent(eventName, callback)
    if not RunService:IsServer() then
        warn("OnServerEvent can only be called on the server")
        return
    end

    if not CheckInitialized() then return {Disconnect = function() end} end
    return self._eventSystem:OnServerEvent(eventName, callback)
end

function EventService:OnClientEvent(eventName, callback)
    if RunService:IsServer() then
        warn("OnClientEvent can only be called on the client")
        return
    end

    if not CheckInitialized() then return {Disconnect = function() end} end
    return self._eventSystem:OnClientEvent(eventName, callback)
end

--[[ Event Firing ]]
function EventService:Fire(eventName, ...)
    if not CheckInitialized() then return end
    return self._eventSystem:Fire(eventName, ...)
end

function EventService:FireTo(player, eventName, ...)
    if not RunService:IsServer() then
        warn("FireTo can only be called on the server")
        return
    end

    if not CheckInitialized() then return end
    return self._eventSystem:FireTo(player, eventName, ...)
end

function EventService:FireAllExcept(excludedPlayer, eventName, ...)
    if not RunService:IsServer() then
        warn("FireAllExcept can only be called on the server")
        return
    end

    if not CheckInitialized() then return end
    return self._eventSystem:FireAllExcept(excludedPlayer, eventName, ...)
end

function EventService:FireServer(eventName, ...)
    if RunService:IsServer() then
        warn("FireServer can only be called on the client")
        return
    end

    if not CheckInitialized() then return end
    return self._eventSystem:FireServer(eventName, ...)
end

--[[ Remote Function Management ]]
function EventService:RegisterFunction(functionName)
    if not RunService:IsServer() then
        warn("RegisterFunction can only be called on the server")
        return
    end

    if not CheckInitialized() then return end
    return self._eventSystem:RegisterFunction(functionName)
end

function EventService:SetCallback(functionName, callback)
    if not RunService:IsServer() then
        warn("SetCallback can only be called on the server")
        return
    end

    if not CheckInitialized() then return end
    return self._eventSystem:SetCallback(functionName, callback)
end

function EventService:InvokeServer(functionName, ...)
    if RunService:IsServer() then
        warn("InvokeServer can only be called on the client")
        return nil
    end

    if not CheckInitialized() then return nil end
    return self._eventSystem:InvokeServer(functionName, ...)
end

--[[ Aliases ]]
EventService.Connect = EventService.On
EventService.FireClient = EventService.FireTo
EventService.Disconnect = function(connection) if connection then connection:Disconnect() end end

return EventService