local TeleportHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Teleport = require(ReplicatedStorage.Services.Network.TeleportService)
}

TeleportHandler.Events = {
    ["Client.Teleport.Init"] = {
        validate = true,
        handler = function(player, data)
            if not data.placeId then
                return { success = false, error = "No place ID provided" }
            end

            local result = Services.Teleport:TeleportPlayer(player, data.placeId, data.options)
            if not result.success then
                Services.Event:FireTo(player, "Client.Teleport.Fail", {
                    error = result.error,
                    placeId = data.placeId
                })
            end

            return result
        end
    },

    ["Client.Teleport.Success"] = {
        validate = true,
        handler = function(player, data)
            if not data.placeId then
                return { success = false, error = "No place ID provided" }
            end

            Services.Event:FireTo(player, "Client.Teleport.Success", {
                placeId = data.placeId,
                jobId = data.jobId
            })

            return { success = true }
        end
    },

    ["Client.Teleport.Queue"] = {
        validate = true,
        handler = function(player, data)
            if not data.placeId then
                return { success = false, error = "No place ID provided" }
            end

            local success = Services.Teleport:QueueTeleport(player, data.placeId, data.options)
            if success then
                Services.Event:FireTo(player, "Client.Teleport.Queue", {
                    placeId = data.placeId
                })
            end

            return { success = success }
        end
    },

    ["Client.Teleport.Retry"] = {
        validate = true,
        handler = function(player, data)
            if not data.placeId then
                return { success = false, error = "No place ID provided" }
            end

            local result = Services.Teleport:RetryTeleport(
                player,
                data.placeId,
                data.options,
                data.error,
                data.attempt
            )

            if result then
                Services.Event:FireTo(player, "Client.Teleport.Retry", {
                    placeId = data.placeId,
                    attempt = data.attempt
                })
            end

            return { success = result }
        end
    }
}

local function Initialize()
    for eventName, eventData in pairs(TeleportHandler.Events) do
        Services.Event:OnServerEvent(eventName, eventData.handler)
    end
end

Initialize()
