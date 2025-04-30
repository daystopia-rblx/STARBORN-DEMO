local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Promise = require(ReplicatedStorage.Modules.Tool.Promise)
local KinematicCore = require(game.ReplicatedStorage.Assets.Imports.KinematicCore).Init()

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
        end):catch(function(error)
            print("Start failed with error:", error)
            if type(error) == "table" then
                for k, v in pairs(error) do
                    print("  - " .. tostring(k) .. ":", tostring(v))
                end
            end
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
end):catch(function(error)
    warn("Failed to initialize client:", error)
    if type(error) == "table" then
        for k, v in pairs(error) do
            warn("  - " .. tostring(k) .. ":", tostring(v))
        end
    end
end)

return client