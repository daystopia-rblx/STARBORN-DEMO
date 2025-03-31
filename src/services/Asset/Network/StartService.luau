--[[ StartService
    Core service orchestrator that manages service lifecycle, dependencies, and hot-reloading.
    Handles service initialization, startup sequencing, and real-time updates with error recovery.
    @author @Daystopia
    @version 1.0.4
    @date 2025-01-09
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Type Definitions ]]
type ServiceDefinition = {
    Init: (self: any, dependencies: {[string]: any}) -> (),
    Start: ((self: any) -> ())?,
    Update: ((self: any, deltaTime: number) -> ())?,
    Dependencies: {string}?,
    Events: {[string]: boolean|EventDefinition}?,
    Listeners: {[string]: (self: any, ...any) -> any}?,
    UPDATE_RATE: number?
}

type ErrorInfo = {
    service: string,
    method: string,
    error: string,
    timestamp: number,
    stack: string,
}

type EventDefinition = {
    server: boolean?,
    client: boolean?,
    reliable: boolean?,
    throttle: number?,
    validate: boolean?
}

--[[ Constants ]]
local UPDATE_RATES = {
    DEFAULT = 1/60,
    LOW = 1/30,
    VERY_LOW = 1/15,
    BACKGROUND = 1/5
}

local PRIORITY_SERVICES = table.freeze({
    "Event",
    "Data",
    "Asset"
})

local StartService = {
    services = {},
    dependencies = {},
    init = {},
    started = {},
    sorted = nil,
    events = {},
    listeners = {},
    errors = {}
}
StartService.__index = StartService

--[[ Core Methods ]]
function StartService.New()
    return setmetatable({
        services = {},
        dependencies = {},
        init = {},
        started = {},
        sorted = nil,
        events = {},
        listeners = {},
        errors = {},
    }, StartService)
end

function StartService:LoadComponents(folder, suffix)
    local components = {}
    local suffixPattern = "Service$"

    local function recursiveLoad(currentFolder)
        for _, item in ipairs(currentFolder:GetChildren()) do
            if item.Name:match(suffixPattern) then
                local name = item.Name:gsub(suffixPattern, "")

                local result
                if item:IsA("ModuleScript") then
                    local success, moduleResult = pcall(require, item)
                    if success then
                        result = moduleResult
                    else
                        warn("Failed to load module:", name, moduleResult)
                    end
                end

                if type(result) == "table" then
                    components[name] = result
                end
            elseif item:IsA("Folder") then
                recursiveLoad(item)
            end
        end
    end

    recursiveLoad(folder)
    return components
end

--[[ Service Management ]]
function StartService:LoadServices()
    self.services = {}

    local networkServices = self:LoadComponents(ReplicatedStorage.Services.Network, "Service")
    local eventService = networkServices.Event
    if not eventService then
        return false, {"Event service not found"}
    end

    self.services.Event = eventService
    eventService.Name = "Event"
    self:SetupDependencies(eventService, true)

    local success, error = self:SafeCall("Event", "Init")
    if not success then
        warn("Failed to initialize Event service:", error)
        return false, {"Failed to initialize Event service: " .. tostring(error)}
    end
    self.init.Event = true

    success, error = self:SafeCall("Event", "Start")
    if not success then
        warn("Failed to start Event service:", error)
        return false, {"Failed to start Event service: " .. tostring(error)}
    end
    self.started.Event = true

    local otherServices = self:LoadComponents(ReplicatedStorage.Services, "Service")
    for name, service in pairs(otherServices) do
        if name ~= "Event" then
            service.Name = name
            self.services[name] = service
            self:SetupDependencies(service, true)
        end
    end

    if not next(self.services) then
        return false, {"No services loaded"}
    end

    return self:ValidateDependencies()
end

function StartService:SetupDependencies(component, isService)
    if isService then
        local name = component.Name
        self.dependencies[name] = component.Dependencies or {}
    end

    if component.Modules then
        local modules = {}
        for _, moduleName in ipairs(component.Modules) do
            local success, result = pcall(function()
                return require(ReplicatedStorage.Modules:FindFirstChild(moduleName .. "Module", true))
            end)

            if success then
                modules[moduleName] = result
            else
                warn(string.format("Failed to load module: %s", moduleName))
            end
        end
        component._modules = modules
    end
end

--[[ Dependency Management ]]
function StartService:SortServices()
    if self.sorted then return self.sorted end

    local sorted, visited = table.create(16), {}

    for _, name in ipairs(PRIORITY_SERVICES) do
        if self.services[name] then
            table.insert(sorted, name)
            visited[name] = true
        end
    end

    local function visit(name)
        if visited[name] then return end
        visited[name] = true

        for _, dep in ipairs(self.dependencies[name]) do
            visit(dep)
        end

        table.insert(sorted, name)
    end

    for name in pairs(self.services) do
        if not visited[name] then
            visit(name)
        end
    end

    self.sorted = sorted
    return sorted
end

function StartService:ValidateDependencies()
    local missingDependencies = table.create(8)

    if self.dependencies["Event"] and #self.dependencies["Event"] > 0 then
        table.insert(missingDependencies, "Event service cannot have dependencies")
    end

    for serviceName, dependencies in pairs(self.dependencies) do
        if type(dependencies) ~= "table" then
            self.dependencies[serviceName] = {}
            dependencies = {}
        end

        for _, depName in ipairs(dependencies) do
            if not self.services[depName] then
                table.insert(missingDependencies, 
                    string.format("Service '%s' requires missing dependency '%s'", 
                    serviceName, depName))
            end
        end
    end

    local function hasCircularDependency(serviceName, visited, stack)
        if not self.dependencies[serviceName] then
            self.dependencies[serviceName] = {}
            return false
        end

        if stack[serviceName] then return true end
        if visited[serviceName] then return false end

        visited[serviceName] = true
        stack[serviceName] = true

        for _, depName in ipairs(self.dependencies[serviceName]) do
            if hasCircularDependency(depName, visited, stack) then
                table.insert(missingDependencies, 
                    string.format("Circular dependency detected involving '%s' and '%s'",
                    serviceName, depName))
                return true
            end
        end

        stack[serviceName] = nil
        return false
    end

    for serviceName in pairs(self.services) do
        if not self.dependencies[serviceName] then
            self.dependencies[serviceName] = {}
        end
        hasCircularDependency(serviceName, {}, {})
    end

    if #missingDependencies > 0 then
        return false, missingDependencies
    end

    return true
end

function StartService:GetDependencies(serviceName)
    local dependencies = {}
    for _, depName in ipairs(self.dependencies[serviceName]) do
        dependencies[depName] = self.services[depName]
    end
    return dependencies
end

function StartService:GetService(name)
    return self.services[name]
end

--[[ Service Lifecycle ]]
function StartService:InitService(serviceName, initializing)
    if self.init[serviceName] then return true end

    initializing = initializing or {}
    if initializing[serviceName] then
        return false, string.format("Circular initialization detected for service '%s'", serviceName)
    end
    initializing[serviceName] = true

    if serviceName == "Event" then
        self:RegisterEvents()
    end

    for _, depName in ipairs(self.dependencies[serviceName]) do
        if not self.init[depName] then
            local success, error = self:InitService(depName, initializing)
            if not success then
                initializing[serviceName] = nil
                return false, "Failed to initialize dependency " .. depName .. ": " .. error
            end
        end
    end

    self:SetupListeners(serviceName)
    local service = self.services[serviceName]

    local modules = service._modules
    if service.Modules and not modules then
        warn(string.format("Service '%s' has Modules defined but no _modules table initialized", serviceName))
        modules = {}
    end

    local success, result = self:SafeCall(serviceName, "Init", self:GetDependencies(serviceName), modules)

    initializing[serviceName] = nil

    if success then
        self.init[serviceName] = true
    end
    return success, result
end

function StartService:StartService(serviceName, startingStack)
    if self.started[serviceName] then return true end

    startingStack = startingStack or {}
    if startingStack[serviceName] then
        warn(string.format("Circular dependency detected while starting '%s'", serviceName))
        return false
    end
    startingStack[serviceName] = true

    for _, depName in ipairs(self.dependencies[serviceName] or {}) do
        if not self.started[depName] then
            local success = self:StartService(depName, startingStack)
            if not success then
                startingStack[serviceName] = nil
                return false
            end
        end
    end

    local service = self.services[serviceName]
    if type(service.Start) ~= "function" then
        self.started[serviceName] = true
        startingStack[serviceName] = nil
        return true
    end

    local success, _ = self:SafeCall(serviceName, "Start")
    if success then
        self.started[serviceName] = true
    end

    startingStack[serviceName] = nil
    return success
end

function StartService:InitServices()
    local sorted = self:SortServices()
    local failed = table.create(4)

    for _, name in ipairs(sorted) do
        local success, error = self:InitService(name)
        if not success then
            table.insert(failed, {name = name, error = error})
        end
    end

    return #failed == 0, failed
end

function StartService:StartServices()
    local failed = table.create(4)
    local sorted = self:SortServices()

    if self.services["Event"] and not self.started["Event"] then
        local success = self:StartService("Event")
        if not success then
            table.insert(failed, {name = "Event", error = "Failed to start Event service"})
            return failed
        end
    end

    for _, name in ipairs(sorted) do
        if name ~= "Event" and not self.started[name] then
            local success = self:StartService(name)
            if not success then
                table.insert(failed, {name = name, error = "Failed to start"})
                warn(string.format("Service %s failed to start but continuing...", name))
            end
        end
    end

    return failed
end

function StartService:UpdateServices(dt)
    local sorted = self:SortServices()

    for _, name in ipairs(sorted) do
        local service = self.services[name]
        if not self:CanUpdate(name) then continue end

        service._timeSinceLastUpdate = (service._timeSinceLastUpdate or 0) + dt

        local updateRate = service.UPDATE_RATE or UPDATE_RATES.DEFAULT

        if service._timeSinceLastUpdate >= updateRate then
            self:SafeCall(name, "Update", service._timeSinceLastUpdate)
            service._timeSinceLastUpdate = 0
        end
    end
end

--[[ Event System ]]
function StartService:RegisterEvents()
    local EventService = self:GetService("Event")
    if not EventService then return end

    local DEFAULT_CONFIG = {
        server = true,
        client = true,
        reliable = true
    }

    for serviceName, service in pairs(self.services) do
        if type(service.Events) == "table" then
            for eventName, eventConfig in pairs(service.Events) do
                local serverName = serviceName .. "." .. eventName
                local clientName = "Client." .. serviceName .. "." .. eventName

                local finalConfig
                if type(eventConfig) == "boolean" then
                    finalConfig = table.clone(DEFAULT_CONFIG)
                elseif type(eventConfig) == "table" then
                    finalConfig = table.clone(DEFAULT_CONFIG)
                    for k, v in pairs(eventConfig) do
                        finalConfig[k] = v
                    end
                else
                    finalConfig = table.clone(DEFAULT_CONFIG)
                end

                if not self.events[serverName] then
                    EventService:RegisterEvent(serverName, finalConfig)
                    self.events[serverName] = {
                        service = serviceName,
                        name = eventName,
                        fullName = serverName,
                        config = finalConfig
                    }
                end

                if not self.events[clientName] then
                    EventService:RegisterEvent(clientName, finalConfig)
                    self.events[clientName] = {
                        service = serviceName,
                        name = eventName,
                        fullName = clientName,
                        config = finalConfig
                    }
                end
            end
        end
    end
end

function StartService:SetupListeners(serviceName)
    local service = self.services[serviceName]
    if not service then
        warn(string.format("Service '%s' not found when setting up listeners", serviceName))
        return
    end

    if service.Listeners == nil then
        -- print(string.format("Service '%s' has no Listeners table defined", serviceName))
        return
    end

    local EventService = self:GetService("Event")
    if not EventService then
        warn("Event Service not found when setting up listeners for:", serviceName)
        return
    end

    local serviceListeners = {}
    self.listeners[serviceName] = serviceListeners

    for eventName, handler in pairs(service.Listeners) do
        local connection

        if type(eventName) == "string" then
            local servicePath, event = eventName:match("^([^%.]+)%.(.+)$")
            if servicePath and event then
                local success, gameService = pcall(game.GetService, game, servicePath)
                if success and gameService and typeof(gameService[event]) == "RBXScriptSignal" then
                    connection = gameService[event]:Connect(function(...)
                        return handler(service, ...)
                    end)
                else
                    if not EventService.events[eventName] then
                        EventService:RegisterEvent(eventName, {
                            server = true,
                            client = true,
                            reliable = true
                        })
                    end

                    connection = EventService:On(eventName, function(...)
                        return handler(service, ...)
                    end)
                end
            else
                if not EventService.events[eventName] then
                    EventService:RegisterEvent(eventName, {
                        server = true,
                        client = true,
                        reliable = true
                    })
                end

                connection = EventService:On(eventName, function(...)
                    return handler(service, ...)
                end)
            end
        elseif typeof(eventName) == "RBXScriptSignal" then
            connection = eventName:Connect(function(...)
                return handler(service, ...)
            end)
        end

        if connection then
            serviceListeners[eventName] = connection
        else
            warn(string.format("[%s] Failed to register listener for event: %s",
                serviceName, tostring(eventName)))
        end
    end
end

--[[ Error Handling ]]
function StartService:HandleError(serviceName, methodName, error)
    if not self.errors[serviceName] then
        self.errors[serviceName] = {
            service = serviceName,
            method = methodName,
            error = error,
            timestamp = os.time(),
            stack = debug.traceback()
        }
        warn(string.format("Error in %s.%s: %s", serviceName, methodName, error))
    end
end

function StartService:SafeCall(serviceName, methodName, ...)
    local service = self.services[serviceName]
    if not service then return false, "Service not found" end

    if type(service[methodName]) ~= "function" then
        return true
    end

    local success, result = pcall(function(...)
        return service[methodName](service, ...)
    end, ...)

    if not success then
        self:HandleError(serviceName, methodName, result)
        return false, result
    end

    return true, result
end

function StartService:CanUpdate(serviceName)
    local service = self.services[serviceName]
    if not service or not service.Update then return false end

    if not self.init[serviceName] or not self.started[serviceName] then
        return false
    end

    for _, depName in ipairs(self.dependencies[serviceName] or {}) do
        if not self.init[depName] or not self.started[depName] then
            return false
        end
    end
    return true
end

--[[ Cleanup ]]
function StartService:Cleanup()
    if self.listeners then
        for _, serviceListeners in pairs(self.listeners) do
            if type(serviceListeners) == "table" then
                for _, connection in ipairs(serviceListeners) do
                    connection.Disconnect(connection)
                end
            end
        end
    end

    if self.sorted then
        for i = #self.sorted, 1, -1 do
            local service = self.services[self.sorted[i]]
            if service and service.Cleanup then
                self:SafeCall(self.sorted[i], "Cleanup")
            end
        end
    end

    local tables = {
        self.init,
        self.started,
        self.errors,
        self.events,
        self.listeners,
        self.services,
        self.dependencies
    }

    for _, tbl in ipairs(tables) do
        if tbl then table.clear(tbl) end
    end

    self.sorted = nil
end

return StartService