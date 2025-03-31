local MovementHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Movement = require(ReplicatedStorage.Services.Entity.MovementService)
}

--[[ Event Handlers ]]
MovementHandler.Events = {
    ["Client.Movement.Execute"] = {
        validate = true,
        handler = function(player, data)
            local originalType = data.type
            if data.type then
                data.type = string.upper(data.type)
            end

            local response = {
                success = false,
                type = originalType,
                data = data
            }

            local success, error = Services.Movement:ExecuteMovement(data.type, player, data)
            response.success = success
            response.error = error

            Services.Event:FireTo(player, "Client.Movement.Execute", response)
            return response
        end
    },

    ["Client.Movement.Camera"] = {
        validate = true,
        handler = function(player, shouldLock)
            local response = {
                success = true,
                type = "camera",
                locked = shouldLock
            }

            Services.Event:FireTo(player, "Client.Movement.Camera", shouldLock)
            return response
        end
    }
}

--[[ Initialize ]]
local function Initialize()
    for eventName, eventData in pairs(MovementHandler.Events) do
        Services.Event:OnServerEvent(eventName, eventData.handler)
    end
end

Initialize()