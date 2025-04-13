local EffectService = {}

EffectService.Dependencies = {
    "Event"
}

local Services
local Modules

function EffectService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

EffectService.Listeners = {
	["Effect.Queue"] = function(self, Player: Player, EffectType: string, Info: Info)
        self:CreateEffect(EffectType, Info)
    end,
}

function EffectService:CreateEffect(EffectType: string, Info: Info)
    Services.Event:Fire("Effect.Create", EffectType, Info)
end

return EffectService
