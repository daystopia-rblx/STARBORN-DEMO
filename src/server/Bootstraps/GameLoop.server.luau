local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameLoop = {}

--[[ Utility Functions ]]
local function SafeRequire(modulePath)
    local success, result = pcall(require, modulePath)
    if not success then
        warn("Failed to require module at path: " .. tostring(modulePath))
        warn("Error: " .. tostring(result))
        return nil
    end
    return result
end

local function PrintError(title: string, failures: {any})
    if not failures or #failures == 0 then return end

    warn("=" .. string.rep("=", 50))
    warn(title .. ":")
    warn(string.rep("-", 50))
    warn("| Service Name | Missing Dependencies |")
    warn(string.rep("-", 50))

    for serviceName, deps in pairs(failures) do
        if type(deps) == "table" then
            warn(string.format("| %-12s | %s |", serviceName, table.concat(deps, ", ")))
        else
            warn(string.format("| %-12s | %s |", serviceName, tostring(deps)))
        end
    end
    warn(string.rep("=", 50) .. "\n")
end

local StartService = SafeRequire(ReplicatedStorage.Services.Network.StartService)

if not StartService then
    error("Failed to load start service.")
end

local StartService = StartService.New()

--[[ Core Methods ]]
function GameLoop.Init()
    local loadSuccess, failedToLoad = StartService:LoadServices()
    if not loadSuccess then
        PrintError("Services Failed to Load", failedToLoad)
    end

    local initSuccess, failedInit = StartService:InitServices()
    if initSuccess == false then
        local failures = {}
        for _, failure in ipairs(failedInit) do
            failures[failure.name] = failure.error
        end
        PrintError("Services Failed to Initialize", failures)
    end

    local failedStart = StartService:StartServices()
    if failedStart and #failedStart > 0 then
        local failures = {}
        for _, failure in ipairs(failedStart) do
            failures[failure.name] = failure.error
        end
        PrintError("Services Failed to Start", failures)
    end

    local updateServices = StartService.UpdateServices
    RunService.Heartbeat:Connect(function(dt)
        updateServices(StartService, dt)
    end)
end

function GameLoop.Cleanup()
    if StartService then
        local cleanup = StartService.Cleanup
        if cleanup then
            cleanup(StartService)
        end
    end
end

GameLoop.Init()

game:BindToClose(GameLoop.Cleanup)