local CombatService = {
    Animations = {} :: {[string]: AnimationTrack}
}

type Info = {
    Damage: number,
	DamageType: string,
	CombatTags: boolean,
	BlockBreak: boolean,
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

CombatService.Events = {
    Death = { validate = true },
    Damage = { validate = true }
}

local Utility = {
    Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)
}

local Services
local Modules

local WeaponData = require(game.ReplicatedStorage.Modules.Data.Combat.WeaponData)
local SoundModule = require(game.ReplicatedStorage.Modules.SoundModule)

CombatService.Listeners = {
    ["Players.PlayerAdded"] = function(self, player)
        local function onCharacterAdded(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return end

            humanoid.Died:Once(function()
                Services.Event:Fire("Combat.Death", {
                    entity = character,
                    player = player,
                    damage = {
                        amount = 0,
                        type = "ENVIRONMENT",
                        source = "death"
                    }
                })
            end)
        end

        if player.Character then
            local Animator = player.Character:FindFirstChild("Humanoid"):FindFirstChildOfClass("Animator")
            if Animator then
                self.Animations = Utility.Animation.Categories(Animator, {"LOCOMOTION", "ROLL"})
            end
        end

        player.CharacterAdded:Connect(onCharacterAdded)
    end,

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

--[[ Handler ]]
function CombatService:Handler(Attacker: Humanoid, Victim: Humanoid, Info: Info)
    if not Attacker or not Victim or not Info then return end

    if Victim.Health == 0 or Attacker.Health == 0 then return end

    local ATKRoot = Attacker.Parent:FindFirstChild("HumanoidRootPart")
    local VICRoot = Victim.Params:FindFirstChild("HumanoidRootPart")

    if not ATKRoot or not VICRoot then return end

    local Behind = (VICRoot.Position - ATKRoot.Position).Unit:Dot(VICRoot.CFrame.LookVector) >= 0.25

    for Key, Value in pairs(Info) do
        if Key == "Damage" and Value and Victim.Parent:FindFirstChildOfClass("ForceField") == nil then
            if Services.State:CheckSpecific(Victim, {Connection = true}, "Dodging") == true then
                self.Animations["ROLL_CANCEL"].Priority = Enum.AnimationPriority.Action2
                self.Animations["ROLL_CANCEL"]:Play()
                return
            elseif Services.State:CheckSpecific(Victim, {Connection = true}, "Parrying") == true then
                
                return
            elseif Services.State:CheckSpecific(Victim, {Connection = true}, "Blocking") == true then
                self:DamageType(Victim.Parent, Info.DamageType, true)

                local postureChange = Value * 1.25 -- We can add posture scaling here
                Services.Stat:ModifyStat(Victim.Parent, "POSTURE", {
                    operation = "add",
                    value = postureChange,
                })
                
                local currentPosture = Services.Stat:GetStat(Victim.Parent, "POSTURE")
                local postureMax = Modules.Stat.Templates.POSTURE.maxValue

                if currentPosture >= postureMax or Info.BlockBreak == true then
                    -- Handle posture break
                    return
                end
                -- Check

                return
            else
                self:DamageType(Victim.Parent, Info.DamageType)
                -- Stun handle

                -- Ai damage handle Event

                -- Hit animation here

                self:ApplyDamage(Attacker, Victim, Value)
                -- Fire Combat Tag
                return
            end
        end
    end
end

function CombatService:DamageType(Character: model, DamageType: string, Blocking: boolean)
    if Blocking == true then
        -- Get Victim WeaponData
        -- Play Block impact Animation
        local WeaponBlock = false -- For now blocking will appear from arms, will next time reference WeaponData

        if WeaponBlock == true then
            -- Find weapon model/blade, play VFX
        else
            Services.Effect:CreateEffect("Character", {VFX = game.ReplicatedStorage.Asset.Particles.BlockedHit, Parent = Character["Left Arm"], NotAttachment = true})
            Services.Effect:CreateEffect("Character", {VFX = game.ReplicatedStorage.Asset.Particles.BlockedHit, Parent = Character["Right Arm"], NotAttachment = true})
            Services.Effect:CreateEffect("Sound", {SFX = SoundModule.SFX.Blocked_Hit.id, Parent = Character.HumanoidRootPart, Time = 2})
        end
    else
        if not DamageType then return end

        if DamageType == "Slash" then
            Services.Effect:CreateEffect("Blood", {Parent = Character.HumanoidRootPart})
        end
        Services.Effect:CreateEffect("Character", {VFX = game.ReplicatedStorage.Asset.Particles[DamageType], Parent = Character.HumanoidRootPart})
        Services.Effect:CreateEffect("Sound", {SFX = SoundModule.SFX[DamageType].id, Parent = Character.HumanoidRootPart, Time = 2})
    end
end

function CombatService:ApplyDamage(source, target, damageValue)
    if not source or not target then return false end

    local humanoid = target:FindFirstChild("Humanoid")
    if not humanoid then return false end

    if damageValue <= 0 then return false end

    humanoid:TakeDamage(damageValue)

    Services.Event:Fire("Combat.Damage", {
        source = source,
        target = target,
        damage = damageValue
    })

    return true
end

return CombatService
