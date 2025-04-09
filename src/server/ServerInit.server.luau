local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Promise = require(ReplicatedStorage.Modules.Tool.Promise)

local StartService = require(ServerScriptService.Services.Network.StartService)

local ServerInit = {}
ServerInit.__index = ServerInit

function ServerInit.New()
    local self = setmetatable({}, ServerInit)
    self._startService = StartService.New()
    return self
end

function ServerInit:Init()
    return Promise.new(function(resolve, reject)
        local startPromise = self._startService:Start()

        startPromise:andThen(function()
            RunService.Heartbeat:Connect(function(dt)
                if self._startService then
                    self._startService:UpdateServices(dt)
                end
            end)
            resolve()
        end):onError(function(error)
            reject(error)
        end)
    end)
end

function ServerInit:Cleanup()
    if self._startService then
        self._startService:Cleanup()
        self._startService = nil
    end
end

local server = ServerInit.New()

game:BindToClose(function()
    server:Cleanup()
end)

server:Init():andThen(function()
    -- print("Server initialized successfully")
end):onError(function(error)
    warn("Failed to initialize server:", error)
end)

return server