--[[ Start
    Core component orchestrator that manages lifecycle, dependencies, and hot-reloading.
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-12
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Modules.Tool.Promise)

--[[ Type Definitions ]]
export type ComponentDefinition = {
    Init: (self: any, dependencies: {[string]: any}) -> (),
    Start: ((self: any) -> ())?,
    Update: ((self: any, deltaTime: number) -> ())?,
    Dependencies: {string}?,
    Modules: {[string]: {[string]: string}}?,
    Events: {[string]: boolean|EventDefinition}?,
    Listeners: {[string]: (self: any, ...any) -> any}?,
    UPDATE_RATE: number?,
    [string]: any
}

export type ErrorInfo = {
    component: string,
    method: string,
    error: string,
    timestamp: number,
    stack: string,
}

export type EventDefinition = {
    server: boolean?,
    client: boolean?,
    reliable: boolean?,
    throttle: number?,
    validate: boolean?
}

export type StartComponentConfig = {
    componentType: string,
    pluralType: string,
    componentSuffix: string,
    priorityComponents: {string},
    updateRates: {[string]: number},
    getRootFolder: () -> Instance
}

--[[ Constants ]]
local DEFAULT_UPDATE_RATES = {
    DEFAULT = 1/60,
    LOW = 1/30,
    VERY_LOW = 1/15,
    BACKGROUND = 1/5
}

--[[ Utility Functions ]]
local function PrintError(title: string, componentType: string, failures: {any})
    if not failures or #failures == 0 then return end

    warn("=" .. string.rep("=", 50))
    warn(title .. ":")
    warn(string.rep("-", 50))
    warn("| " .. componentType .. " Name | Error Details |")
    warn(string.rep("-", 50))

    for name, error in pairs(failures) do
        if type(error) == "table" then
            warn(string.format("| %-14s | %s |", name, table.concat(error, ", ")))
        else
            warn(string.format("| %-14s | %s |", name, tostring(error)))
        end
    end
    warn(string.rep("=", 50) .. "\n")
end

local function IsDirectRequireTable(tbl)
    if type(tbl) ~= "table" then return false end

    for _, value in pairs(tbl) do
        if type(value) ~= "string" then
            return true
        end
    end

    return false
end

--[[ Class Definition ]]
local Start = {}
Start.__index = Start

--[[ Core Methods ]]
function Start.New(config: StartComponentConfig)
    local self = setmetatable({
        components = {},
        dependencies = {},
        init = {},
        started = {},
        sorted = nil,
        events = {},
        listeners = {},
        errors = {},
        _isUpdating = false,
        _starting = false,
        _cleaning = false,

        componentType = config.componentType,
        pluralType = config.pluralType,
        componentSuffix = config.componentSuffix,
        priorityComponents = config.priorityComponents,
        updateRates = config.updateRates or DEFAULT_UPDATE_RATES,
        getRootFolder = config.getRootFolder
    }, Start)

    return self
end

function Start:LoadComponents()
    self.components = {}
    local failedToLoad = {}

    local eventComponent = nil
    local rootFolder = self.getRootFolder()
    local eventModulePath = rootFolder.Network:FindFirstChild("Event" .. self.componentSuffix)

    if eventModulePath then
        local success, result = pcall(require, eventModulePath)
        if success then
            eventComponent = result
        else
            failedToLoad["Event"] = "Failed to load: " .. tostring(result)
        end
    end

    if eventComponent then
        self.components.Event = eventComponent
        eventComponent.Name = "Event"
        self:SetupDependencies(eventComponent, true)

        local success, error = self:SafeCall("Event", "Init")
        if not success then
            failedToLoad["Event"] = "Failed to initialize: " .. tostring(error)
            return false, failedToLoad
        end
        self.init.Event = true

        success = self:StartComponent("Event")
        if not success then
            failedToLoad["Event"] = "Failed to start Event " .. self.componentType
            return false, failedToLoad
        end
        self.started.Event = true
    end

    local function recursiveLoad(currentFolder)
        for _, item in ipairs(currentFolder:GetChildren()) do
            if item:IsA("ModuleScript") and item.Name:match(self.componentSuffix .. "$") then
                local name = item.Name:gsub(self.componentSuffix .. "$", "")

                if name == "Event" or name == "Start" then continue end

                local success, result = pcall(require, item)
                if success then
                    self.components[name] = result
                    result.Name = name
                    self:SetupDependencies(result, true)
                else
                    failedToLoad[name] = "Failed to load: " .. tostring(result)
                end
            elseif item:IsA("Folder") then
                recursiveLoad(item)
            end
        end
    end

    recursiveLoad(rootFolder)

    if not next(self.components) then
        failedToLoad["Unknown"] = "No components loaded"
        return false, failedToLoad
    end

    local valid, missingDeps = self:ValidateDependencies()
    if not valid then
        return false, missingDeps
    end

    return true, failedToLoad
end

function Start:SetupDependencies(component, isService)
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
function Start:SortComponents()
    if self.sorted then return self.sorted end

    local sorted, visited = table.create(16), {}

    for _, name in ipairs(self.priorityComponents) do
        if self.components[name] then
            table.insert(sorted, name)
            visited[name] = true
        end
    end

    local function visit(name)
        if visited[name] then return end
        visited[name] = true

        for _, dep in ipairs(self.dependencies[name] or {}) do
            visit(dep)
        end

        table.insert(sorted, name)
    end

    for name in pairs(self.components) do
        if not visited[name] then
            visit(name)
        end
    end

    self.sorted = sorted
    return sorted
end

function Start:ValidateDependencies()
    local missingDependencies = {}

    if self.dependencies["Event"] and #self.dependencies["Event"] > 0 then
        table.insert(missingDependencies, "Event " .. self.componentType .. " cannot have dependencies")
    end

    for name, dependencies in pairs(self.dependencies) do
        if type(dependencies) ~= "table" then
            self.dependencies[name] = {}
            dependencies = {}
        end

        for _, depName in ipairs(dependencies) do
            if not self.components[depName] then
                table.insert(missingDependencies, 
                    string.format("%s '%s' requires missing dependency '%s'",
                    self.componentType, name, depName))
            end
        end
    end

    local function hasCircularDependency(name, visited, stack)
        if not self.dependencies[name] then
            self.dependencies[name] = {}
            return false
        end

        if stack[name] then return true end
        if visited[name] then return false end

        visited[name] = true
        stack[name] = true

        for _, depName in ipairs(self.dependencies[name]) do
            if hasCircularDependency(depName, visited, stack) then
                table.insert(missingDependencies, 
                    string.format("Circular dependency detected involving '%s' and '%s'",
                    name, depName))
                return true
            end
        end

        stack[name] = nil
        return false
    end

    for name in pairs(self.components) do
        if not self.dependencies[name] then
            self.dependencies[name] = {}
        end
        hasCircularDependency(name, {}, {})
    end

    if #missingDependencies > 0 then
        return false, missingDependencies
    end

    return true
end

function Start:GetDependencies(name)
    local dependencies = {}
    for _, depName in ipairs(self.dependencies[name] or {}) do
        dependencies[depName] = self.components[depName]
    end
    return dependencies
end

function Start:GetComponent(name)
    return self.components[name]
end

--[[ Component Lifecycle ]]
function Start:InitComponent(name, initializing)
    if self.init[name] then return true end

    initializing = initializing or {}
    if initializing[name] then
        return false, string.format("Circular initialization detected for %s '%s'", self.componentType, name)
    end
    initializing[name] = true

    if name == "Event" then
        self:RegisterEvents()
    end

    for _, depName in ipairs(self.dependencies[name] or {}) do
        if not self.init[depName] then
            local success, error = self:InitComponent(depName, initializing)
            if not success then
                initializing[name] = nil
                return false, "Failed to initialize dependency " .. depName .. ": " .. error
            end
        end
    end

    self:SetupListeners(name)
    local component = self.components[name]

    local modules = component._modules or {}
    local dependencies = self:GetDependencies(name)
    local paramName = self.componentType == "Service" and "services" or "controllers"

    local success, result = self:SafeCall(name, "Init", dependencies, modules)

    initializing[name] = nil

    if success then
        self.init[name] = true
    end
    return success, result
end

function Start:StartComponent(name, startingStack)
    if self.started[name] then return true end

    startingStack = startingStack or {}
    if startingStack[name] then
        warn(string.format("Circular dependency detected while starting '%s'", name))
        return false
    end
    startingStack[name] = true

    for _, depName in ipairs(self.dependencies[name] or {}) do
        if not self.started[depName] then
            local success = self:StartComponent(depName, startingStack)
            if not success then
                startingStack[name] = nil
                return false
            end
        end
    end

    local component = self.components[name]
    if not component then
        warn(string.format("Component '%s' not found", name))
        startingStack[name] = nil
        return false
    end

    if type(component.Start) ~= "function" then
        self.started[name] = true
        startingStack[name] = nil
        return true
    end

    local success, result = pcall(function()
        return component:Start()
    end)

    if not success then
        warn(string.format("Error starting %s '%s': %s", self.componentType, name, tostring(result)))
        startingStack[name] = nil
        return false
    end

    self.started[name] = true
    startingStack[name] = nil
    return true
end

function Start:InitComponents()
    local sorted = self:SortComponents()
    local failed = {}

    for _, name in ipairs(sorted) do
        local success, error = self:InitComponent(name)
        if not success then
            failed[name] = error
        end
    end

    return next(failed) == nil, failed
end

function Start:StartComponents()
    local failed = {}
    local sorted = self:SortComponents()

    if self.components["Event"] and not self.started["Event"] then
        local success = self:StartComponent("Event")
        if not success then
            failed["Event"] = "Failed to start Event " .. self.componentType
            return failed
        end
    end

    for _, name in ipairs(sorted) do
        if name ~= "Event" and not self.started[name] then
            local success = self:StartComponent(name)
            if not success then
                failed[name] = "Failed to start"
                warn(string.format("%s %s failed to start but continuing...", self.componentType, name))
            end
        end
    end

    return failed
end

function Start:UpdateComponents(dt)
    if self._isUpdating then
        return
    end

    self._isUpdating = true

    local sorted = self:SortComponents()

    for _, name in ipairs(sorted) do
        local component = self.components[name]
        if not self:CanUpdate(name) then continue end

        component._timeSinceLastUpdate = (component._timeSinceLastUpdate or 0) + dt

        local updateRate = component.UPDATE_RATE or self.updateRates.DEFAULT

        if component._timeSinceLastUpdate >= updateRate then
            local success, err = pcall(function()
                self:SafeCall(name, "Update", component._timeSinceLastUpdate)
            end)

            if not success then
                warn("Error updating " .. self.componentType, name, ":", err)
            end

            component._timeSinceLastUpdate = 0
        end
    end

    self._isUpdating = false
end

--[[ Event System ]]
function Start:RegisterEvents()
    local EventComponent = self:GetComponent("Event")
    if not EventComponent then return end

    local DEFAULT_CONFIG = {
        server = true,
        client = true,
        reliable = true
    }

    local eventsToRegister = {}

    for name, component in pairs(self.components) do
        if type(component.Events) ~= "table" then continue end

        for eventName, eventConfig in pairs(component.Events) do
            local serverName = name .. "." .. eventName
            local clientName = "Client." .. name .. "." .. eventName

            local finalConfig
            if type(eventConfig) == "boolean" then
                finalConfig = DEFAULT_CONFIG
            elseif type(eventConfig) == "table" then
                finalConfig = table.clone(DEFAULT_CONFIG)
                for k, v in pairs(eventConfig) do
                    finalConfig[k] = v
                end
            else
                finalConfig = DEFAULT_CONFIG
            end

            if not self.events[serverName] then
                table.insert(eventsToRegister, {
                    name = serverName,
                    config = finalConfig,
                    component = name,
                    eventName = eventName,
                    isClient = false
                })
            end

            if not self.events[clientName] then
                table.insert(eventsToRegister, {
                    name = clientName,
                    config = finalConfig,
                    component = name,
                    eventName = eventName,
                    isClient = true
                })
            end
        end
    end

    for _, eventInfo in ipairs(eventsToRegister) do
        local success = EventComponent:RegisterEvent(eventInfo.name, eventInfo.config)
        if success then
            self.events[eventInfo.name] = {
                component = eventInfo.component,
                name = eventInfo.eventName,
                fullName = eventInfo.name,
                config = eventInfo.config
            }
        end
    end
end

function Start:SetupListeners(name)
    local component = self.components[name]
    if not component then
        warn(string.format("%s '%s' not found when setting up listeners", self.componentType, name))
        return
    end

    if component.Listeners == nil then
        return
    end

    local EventComponent = self:GetComponent("Event")
    if not EventComponent then
        warn("Event " .. self.componentType .. " not found when setting up listeners for:", name)
        return
    end

    local componentListeners = {}
    self.listeners[name] = componentListeners

    for eventName, handler in pairs(component.Listeners) do
        local connection

        if type(eventName) == "string" then
            local servicePath, event = eventName:match("^([^%.]+)%.(.+)$")
            if servicePath and event then
                local success, gameService = pcall(game.GetService, game, servicePath)
                if success and gameService and typeof(gameService[event]) == "RBXScriptSignal" then
                    connection = gameService[event]:Connect(function(...)
                        return handler(component, ...)
                    end)
                else
                    if not EventComponent.events[eventName] then
                        EventComponent:RegisterEvent(eventName, {
                            server = true,
                            client = true,
                            reliable = true
                        })
                    end

                    connection = EventComponent:On(eventName, function(...)
                        return handler(component, ...)
                    end)
                end
            else
                if not EventComponent.events[eventName] then
                    EventComponent:RegisterEvent(eventName, {
                        server = true,
                        client = true,
                        reliable = true
                    })
                end

                connection = EventComponent:On(eventName, function(...)
                    return handler(component, ...)
                end)
            end
        elseif typeof(eventName) == "RBXScriptSignal" then
            connection = eventName:Connect(function(...)
                return handler(component, ...)
            end)
        end

        if connection then
            componentListeners[eventName] = connection
        else
            warn(string.format("[%s] Failed to register listener for event: %s",
                name, tostring(eventName)))
        end
    end
end

--[[ Error Handling ]]
function Start:HandleError(name, methodName, error)
    local errorKey = self.componentType:lower()

    if not self.errors[name] then
        self.errors[name] = {
            [errorKey] = name,
            method = methodName,
            error = error,
            timestamp = os.time(),
            stack = debug.traceback()
        }
        warn(string.format("Error in %s.%s: %s", name, methodName, error))
    end
end

function Start:SafeCall(name, methodName, ...)
    local component = self.components[name]
    if not component then return false, self.componentType .. " not found" end

    if type(component[methodName]) ~= "function" then
        return true
    end

    local success, result = pcall(function(...)
        return component[methodName](component, ...)
    end, ...)

    if not success then
        self:HandleError(name, methodName, result)
        return false, result
    end

    return true, result
end

function Start:CanUpdate(name)
    local component = self.components[name]
    if not component or not component.Update then return false end

    if not self.init[name] or not self.started[name] then
        return false
    end

    for _, depName in ipairs(self.dependencies[name] or {}) do
        if not self.init[depName] or not self.started[depName] then
            return false
        end
    end
    return true
end

--[[ Main Methods ]]
function Start:Start()
    if self._starting then
        return Promise.reject(self.componentType .. " is already starting")
    end
    self._starting = true

    return Promise.new(function(resolve, reject)
        task.spawn(function()
            local loadSuccess, failedToLoad = self:LoadComponents()
            if not loadSuccess then
                PrintError("Failed to Load " .. self.pluralType, self.componentType, failedToLoad)
                self._starting = false
                reject(failedToLoad)
                return
            end

            local validateSuccess, missingDeps = self:ValidateDependencies()
            if not validateSuccess then
                PrintError("Missing Dependencies", self.componentType, missingDeps)
                self._starting = false
                reject(missingDeps)
                return
            end

            pcall(function()
                self:RegisterEvents()
            end)

            local sorted = {}
            pcall(function()
                sorted = self:SortComponents() or {}
            end)

            local initFailures = {}

            for _, name in ipairs(sorted) do
                if name ~= "Event" then
                    pcall(function()
                        local success, error = self:InitComponent(name)
                        if not success then
                            initFailures[name] = error
                        end
                    end)
                end
            end

            if next(initFailures) then
                PrintError(self.pluralType .. " Failed to Initialize", self.componentType, initFailures)
            end

            local startFailures = {}
            for _, name in ipairs(sorted) do
                if name ~= "Event" and not self.started[name] then
                    pcall(function()
                        local success = self:StartComponent(name)
                        if not success then
                            startFailures[name] = "Failed to start"
                        end
                    end)
                end
            end

            if next(startFailures) then
                PrintError(self.pluralType .. " Failed to Start", self.componentType, startFailures)
            end

            pcall(function()
                local EventComponent = self:GetComponent("Event")
                if EventComponent then
                    EventComponent:Fire("Start.Init", {})
                end
            end)

            self._starting = false
            resolve()
        end)
    end)
end

--[[ Cleanup ]]
function Start:Cleanup()
    if self._cleaning then
        return
    end
    self._cleaning = true

    if self.listeners then
        for name, componentListeners in pairs(self.listeners) do
            if type(componentListeners) == "table" then
                for eventName, connection in pairs(componentListeners) do
                    if typeof(connection) == "RBXScriptConnection" then
                        pcall(function()
                            connection:Disconnect()
                        end)
                    end
                end
            end
        end
    end

    if self.sorted and type(self.sorted) == "table" then
        local sortedCopy = table.clone(self.sorted)
        for i = #sortedCopy, 1, -1 do
            local name = sortedCopy[i]
            if self.components and name and self.components[name] then
                local component = self.components[name]
                if component and type(component) == "table" and type(component.Cleanup) == "function" then
                    pcall(function()
                        component.Cleanup(component)
                    end)
                end
            end
        end
    end

    local tables = {
        self.init,
        self.started,
        self.errors,
        self.events,
        self.listeners,
        self.components,
        self.dependencies
    }

    for _, tbl in ipairs(tables) do
        if tbl and type(tbl) == "table" then
            pcall(function()
                table.clear(tbl)
            end)
        end
    end

    self.sorted = nil
    self._cleaning = false
end

return Start