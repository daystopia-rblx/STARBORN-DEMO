--[[ SkillService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-01
]]
local SkillService = {}

SkillService.Dependencies = {
    "Data",
    "Event"
}

SkillService.Modules = {
}

SkillService.Events = {
}

local Services
local Modules

--[[ Core Functions ]]
function SkillService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function SkillService:Cleanup()
end

return SkillService