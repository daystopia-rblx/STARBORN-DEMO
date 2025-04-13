local CombatService = {
    Animations = {} :: {[string]: AnimationTrack}
}

local WeaponData = require(game.ReplicatedStorage.Modules.Data.Combat.WeaponData)
local StatusService = require(game.ServerScriptService.Services.Status.StatusService)
local Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)
local AnimationModule = require(game.ReplicatedStorage.Modules.AnimationModule)

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
                local Keys = AnimationModule.Assets.Animations.WEAPONS[string.upper(Weapon)]
                self.Animations = Animation.Category(Animator, Keys, "WEAPONS_"..string.upper(Weapon))
            end
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

        if Character then
            local Animator = Character:FindFirstChild("Humanoid"):FindFirstChildOfClass("Animator")
            if Animator then
                local Keys = AnimationModule.Assets.Animations.WEAPONS[string.upper(Weapon)]
                self.Animations = Animation.Category(Animator, Keys, "WEAPONS_"..string.upper(Weapon))
            end
        end

        self:Unequip(Humanoid, Weapon, Data)
    end,
}

function CombatService:Init()
    return true
end

--[[ Equipping ]]
function CombatService:Equip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    local EquipKey = "WEAPONS_"..string.upper(Weapon).."_EQUIP"
    self.Animations[EquipKey].Priority = Enum.AnimationPriority.Action2
    self.Animations[EquipKey]:Play()

    local IdleKey = "WEAPONS_"..string.upper(Weapon).."_IDLE"
    self.Animations[IdleKey].Priority = Enum.AnimationPriority.Idle
    self.Animations[IdleKey]:Play()

    StatusService:CreateStatus(Humanoid, "Combat", "Equipped", {Set = true})
end

function CombatService:Unequip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    local EquipKey = "WEAPONS_"..string.upper(Weapon).."_UNEQUIP"
    self.Animations[EquipKey].Priority = Enum.AnimationPriority.Action2
    self.Animations[EquipKey]:Play()

    Animation.Stop(self.Animations, "WEAPONS_FIST", "IDLE") -- IM ABOUT TO CRASH OUT IT ISNT STOPPING

    StatusService:CreateStatus(Humanoid, "Combat", "Equipped", {Set = false})
end

--[[ Attacking ]]

return CombatService
