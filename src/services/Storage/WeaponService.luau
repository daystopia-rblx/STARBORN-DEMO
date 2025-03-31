--[[ WeaponService
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local WeaponService = {}

WeaponService.Dependencies = {
    "Data",
    "Event"
}

WeaponService.Modules = {
    "Weapon"
}

WeaponService.Events = {

}

local Services
local Modules

--[[ State Management ]]
local State = {
}

--[[ Core Functions ]]
function WeaponService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function WeaponService:Cleanup()
end

return WeaponService
