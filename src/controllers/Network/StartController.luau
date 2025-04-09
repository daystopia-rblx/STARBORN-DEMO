--[[ StartController
    Core controller orchestrator that manages controller lifecycle, dependencies, and hot-reloading.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-09
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Start = require(ReplicatedStorage.Modules.Core.Start)

--[[ Type Definitions ]]
type ControllerDefinition = {
    Init: (self: any, dependencies: {[string]: any}) -> (),
    Start: ((self: any) -> ())?,
    Update: ((self: any, deltaTime: number) -> ())?,
    Dependencies: {string}?,
    Events: {[string]: boolean|EventDefinition}?,
    Listeners: {[string]: (self: any, ...any) -> any}?,
    UPDATE_RATE: number?
}

type ErrorInfo = {
    controller: string,
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

local PRIORITY_CONTROLLERS = table.freeze({
    "Event"
})

local StartController = {}
StartController.__index = StartController

--[[ Core Methods ]]
function StartController.New()
    local component = Start.New({
        componentType = "Controller",
        pluralType = "Controllers",
        componentSuffix = "Controller",
        priorityComponents = PRIORITY_CONTROLLERS,
        updateRates = UPDATE_RATES,
        getRootFolder = function()
            return ReplicatedStorage.Controllers
        end
    })

    local self = setmetatable({
        _component = component
    }, StartController)

    return self
end

--[[ Forwarding Methods ]]
function StartController:LoadControllers()
    return self._component:LoadComponents()
end

function StartController:SetupDependencies(...)
    return self._component:SetupDependencies(...)
end

function StartController:SortControllers()
    return self._component:SortComponents()
end

function StartController:ValidateDependencies()
    return self._component:ValidateDependencies()
end

function StartController:GetDependencies(...)
    return self._component:GetDependencies(...)
end

function StartController:GetController(...)
    return self._component:GetComponent(...)
end

function StartController:InitController(...)
    return self._component:InitComponent(...)
end

function StartController:StartController(...)
    return self._component:Start(...)
end

function StartController:UpdateControllers(...)
    return self._component:UpdateComponents(...)
end

function StartController:CanUpdate(...)
    return self._component:CanUpdate(...)
end

function StartController:RegisterEvents()
    return self._component:RegisterEvents()
end

function StartController:SetupListeners(...)
    return self._component:SetupListeners(...)
end

function StartController:HandleError(...)
    return self._component:HandleError(...)
end

function StartController:SafeCall(...)
    return self._component:SafeCall(...)
end

function StartController:Start()
    return self._component:Start()
end

function StartController:Cleanup()
    return self._component:Cleanup()
end

return StartController