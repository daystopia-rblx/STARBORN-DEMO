local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService),
    Tool = require(ReplicatedStorage.Services.Object.ToolService)
}

local Events = {
    ["Client.Tool.Equip"] = {
        handler = function(player, data)
            if not (player and data and data.tool) then return end
            return Services.Tool:EquipTool(player, data.tool)
        end
    },

    ["Client.Tool.Unequip"] = {
        handler = function(player, data)
            if not (player and data and data.tool) then return end
            return Services.Tool:UnequipTool(player, data.tool)
        end
    },

    ["Client.Tool.Activate"] = {
        handler = function(player, data)
            if not (player and data and data.tool) then return end
            return Services.Tool:ActivateTool(player, data.tool, data.inputType, data.data)
        end
    },

    ["Client.Tool.Deactivate"] = {
        handler = function(player, data)
            if not (player and data and data.tool) then return end
            return Services.Tool:DeactivateTool(player, data.tool, data.inputType, data.data)
        end
    }
}

local function Initialize()
    for eventName, eventData in pairs(Events) do
        Services.Event:OnServerEvent(eventName, eventData.handler)
    end
end

Initialize()