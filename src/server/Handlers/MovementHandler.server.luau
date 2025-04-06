--[[ MovementHandler
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-05
]]
local MovementHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Dependencies ]]
local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Movement = require(ReplicatedStorage.Services.Character.MovementService)
}

--[[ Events ]]
local Events = {
    ["Movement.State"] = {
        handler = function(player, data)
            if not player or not data or not data.state or data.value == nil then
                return {
                    success = false,
                    error = "Invalid state data"
                }
            end

            local character = player.Character
            if not character then
                return {
                    success = false,
                    error = "Character not found"
                }
            end

            local success = Services.Movement:SetState(character, data.state, data.value)

            Services.Event:Fire("Movement.State", {
                character = character,
                state = data.state,
                value = data.value
            })

            return {
                success = success
            }
        end
    }
}

--[[ Initialization ]]
function MovementHandler:Initialize()
    for eventName, eventData in pairs(Events) do
        Services.Event:OnServerEvent(eventName, eventData.handler)
    end
end

MovementHandler:Initialize()

return MovementHandler