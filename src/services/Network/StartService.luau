--[[ StartService
    Core service orchestrator that manages service lifecycle, dependencies, and hot-reloading.
    Handles service initialization, startup sequencing, and real-time updates with error recovery.
    @author @Daystopia
    @version 1.0.5
    @date 2025-04-09
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Start = require(ReplicatedStorage.Modules.Core.Start)

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

local StartService = {}
StartService.__index = StartService

--[[ Core Methods ]]
function StartService.New()
    local component = Start.New({
        componentType = "Service",
        pluralType = "Services",
        componentSuffix = "Service",
        priorityComponents = PRIORITY_SERVICES,
        updateRates = UPDATE_RATES,
        getRootFolder = function()
            return game:GetService("ServerScriptService").Services
        end
    })

    local self = setmetatable({
        _component = component
    }, StartService)

    return self
end

--[[ Forwarding Methods ]]
function StartService:LoadServices()
    return self._component:LoadComponents()
end

function StartService:SetupDependencies(...)
    return self._component:SetupDependencies(...)
end

function StartService:SortServices()
    return self._component:SortComponents()
end

function StartService:ValidateDependencies()
    return self._component:ValidateDependencies()
end

function StartService:GetDependencies(...)
    return self._component:GetDependencies(...)
end

function StartService:GetService(...)
    return self._component:GetComponent(...)
end

function StartService:InitService(...)
    return self._component:InitComponent(...)
end

function StartService:StartService(...)
    return self._component:StartComponent(...)
end

function StartService:InitServices()
    return self._component:InitComponents()
end

function StartService:StartServices()
    return self._component:StartComponents()
end

function StartService:UpdateServices(...)
    return self._component:UpdateComponents(...)
end

function StartService:RegisterEvents()
    return self._component:RegisterEvents()
end

function StartService:SetupListeners(...)
    return self._component:SetupListeners(...)
end

function StartService:HandleError(...)
    return self._component:HandleError(...)
end

function StartService:SafeCall(...)
    return self._component:SafeCall(...)
end

function StartService:CanUpdate(...)
    return self._component:CanUpdate(...)
end

function StartService:Start()
    return self._component:Start()
end

function StartService:Cleanup()
    return self._component:Cleanup()
end

return StartService