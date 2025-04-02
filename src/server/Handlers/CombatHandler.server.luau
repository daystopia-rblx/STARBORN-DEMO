local CombatHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Combat = require(ReplicatedStorage.Services.Combat.CombatService)
}

--[[ Event Handlers ]]
CombatHandler.Events = {
    ["Client.Combat.Attack"] = {
        validate = true,
        handler = function(player, data)
            if not data then
                return {
                    success = false,
                    error = "Invalid combat data"
                }
            end

            local response = {
                success = false,
                data = data
            }

            local success, error = Services.Combat:ExecuteCombat(player, data)
            response.success = success
            response.error = error

            Services.Event:FireTo(player, "Client.Combat.Attack", response)
            return response
        end
    }
}

--[[ Initialize ]]
local function Initialize()
    for eventName, eventData in pairs(CombatHandler.Events) do
        Services.Event:OnServerEvent(eventName, eventData.handler)
    end
end

Initialize()