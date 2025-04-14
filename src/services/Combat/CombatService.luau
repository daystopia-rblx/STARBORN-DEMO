local CombatService = {
    Animations = {} :: {[string]: AnimationTrack}
}

CombatService.Dependencies = {
    "Event",
    "Asset",
    "Status"
}

CombatService.Modules = {
    "Animation",
    "Status"
}

local Utility = {
    Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)
}

local Services
local Modules

local WeaponData = require(game.ReplicatedStorage.Modules.Data.Combat.WeaponData)

CombatService.Listeners = {
    ["Combat.Equip"] = function(self, Player: Player)
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        -- Figure out how to get player Weapon from Data
        local Weapon = "Fist"
        local Data = WeaponData[Weapon]

        if Character then
            local Animator = Character:FindFirstChild("Humanoid"):FindFirstChildOfClass("Animator")
            if Animator then
                local Keys = Modules.Animation.Assets.Animations.WEAPONS[string.upper(Weapon)]
                self.Animations = Utility.Animation.Category(Animator, Keys, "WEAPONS_"..string.upper(Weapon))
            end
        end

        local EquipKey = "WEAPONS_"..string.upper(Weapon).."_EQUIP"
        if self.Animations[EquipKey] then
            self.Animations[EquipKey]:Play()
        end

        self:Equip(Humanoid, Weapon, Data)
    end,

    ["Combat.Unequip"] = function(self, Player: Player)
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        -- Figure out how to get player Weapon from Data
        local Weapon = "Fist"
        local Data = WeaponData[Weapon]

        local UnequipKey = "WEAPONS_"..string.upper(Weapon).."_UNEQUIP"
        if self.Animations[UnequipKey] then
            self.Animations[UnequipKey]:Play()
        end

        local IdleKey = "WEAPONS_"..string.upper(Weapon).."_IDLE"
        if self.Animations[IdleKey] then
            self.Animations[IdleKey]:Stop()
        end

        self:Unequip(Humanoid, Weapon, Data)
    end,
}

function CombatService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

--[[ Equipping ]]
function CombatService:Equip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    local IdleKey = "WEAPONS_"..string.upper(Weapon).."_IDLE"
    if self.Animations[IdleKey] then
        self.Animations[IdleKey].Priority = Enum.AnimationPriority.Idle
        self.Animations[IdleKey]:Play()
    end

    Services.Status:CreateStatus(Humanoid, "Combat", "Equipped", {Set = true})
end

function CombatService:Unequip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    -- Stopping logic moved to the listener function above
    Services.Status:CreateStatus(Humanoid, "Combat", "Equipped", {Set = false})
end

--[[ Attacking ]]

return CombatService
