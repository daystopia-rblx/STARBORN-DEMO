--[[ EquipmentService
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local EquipmentService = {}

EquipmentService.Dependencies = {
    "Data",
    "Event"
}

EquipmentService.Modules = {
    "Equipment"
}

EquipmentService.Events = {
}

local Services
local Modules

--[[ Core Functions ]]
function EquipmentService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function EquipmentService:Cleanup()
end

return EquipmentService