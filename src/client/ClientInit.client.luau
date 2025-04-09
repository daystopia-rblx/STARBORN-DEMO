local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(ReplicatedStorage.Modules.Tool.Promise)

local StartController = require(ReplicatedStorage.Controllers.Network.StartController)

local ClientInit = {}
ClientInit.__index = ClientInit

function ClientInit.New()
    local self = setmetatable({}, ClientInit)
    self._startController = StartController.New()
    return self
end

function ClientInit:Init()
    return Promise.new(function(resolve, reject)
        local startPromise = self._startController:Start()

        startPromise:andThen(function()
            resolve()
        end):onError(function(error)
            reject(error)
        end)
    end)
end

function ClientInit:Cleanup()
    if self._startController then
        self._startController:Cleanup()
    end
end

local client = ClientInit.New()

Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        client:Cleanup()
    end
end)

client:Init():andThen(function()
end):onError(function(error)
    warn("Failed to initialize client:", error)
end)

return client