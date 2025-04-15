local CombatService = {}

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
local AnimationModule = require(game.ReplicatedStorage.Modules.AnimationModule)
local HitboxService = require(script.Parent.HitboxService)
local EffectService = require(game.ServerScriptService.Services.Asset.EffectService)
local StatService = require(game.ServerScriptService.Services.State.StatService)
local StatModule = require(game.ReplicatedStorage.Modules.StatModule)

CombatService.Listeners = {
    ["Players.PlayerAdded"] = function(self, player: Player)
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

        player.CharacterAdded:Connect(onCharacterAdded)
    end,

    ["Combat.Equip"] = function(self, Player: Player)
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped"}}) == true then return end

        -- Figure out how to get player Weapon from Data
        local Weapon = "Fist"
        local Data = WeaponData[Weapon]

        local EquipKey = string.upper(Weapon)
	    Utility.Animation:Play(AnimationModule.Assets.Animations.WEAPONS[EquipKey].EQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Equip")

        self:Equip(Humanoid, Weapon, Data)
    end,

    ["Combat.Unequip"] = function(self, Player: Player)
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped"}}) == true then return end

        -- Figure out how to get player Weapon from Data
        local Weapon = "Fist"
        local Data = WeaponData[Weapon]

        local UnequipKey = string.upper(Weapon)
	    Utility.Animation:Play(AnimationModule.Assets.Animations.WEAPONS[UnequipKey].UNEQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Unequip")
        Utility.Animation:Stop(Humanoid, "Idle")

        self:Unequip(Humanoid, Weapon, Data)
    end,

    ["Combat.Attack"] = function(self, Player: Player)
        local Character = Player.Character
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        -- Figure out how to get player Weapon from Data
        local Weapon = "Fist"
        local Data = WeaponData[Weapon]

        self:Attack(Character, Humanoid, Root, Data)
    end,
    
    ["Combat.Parry"] = function(self, Player: Player, Active: boolean)
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        if Active == false then
            self:ParryStop(Humanoid)
            return
        end
        
        if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Equipped") then
            -- Figure out how to get player Weapon from Data
            local Weapon = "Fist"
            local Data = WeaponData[Weapon]

            self:ParryStart(Humanoid, Weapon, Data)
        else
            -- Default to fist parrying (so you can parry without equipping)
            local Weapon = "Fist"
            local Data = WeaponData[Weapon]

            self:ParryStart(Humanoid, Weapon, Data)
        end
    end,
}

function CombatService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

--[[ Equipping ]]
function CombatService:Equip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    local IdleKey = string.upper(Weapon)
    Utility.Animation:Play(AnimationModule.Assets.Animations.WEAPONS[IdleKey].IDLE.id, Humanoid, 1, Enum.AnimationPriority.Idle, "Idle")

    Services.Status:CreateStatus(Humanoid, "Combat", "Equipped", {Set = true})
end

function CombatService:Unequip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    Services.Status:CreateStatus(Humanoid, "Combat", "Equipped", {Set = false})
end

--[[ Attacking ]]
function CombatService:Attack(Character: Model, Humanoid: Humanoid, Root: BasePart, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}) == true then return end

    local function Checker()
        local cancelled = false

        task.spawn(function()
            while Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") do 
                if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed", "Parried") then
                    cancelled = true
                    break
                end
                task.wait()
            end
        end)

        return function()
            return cancelled
        end
    end

    local Interrupted = Checker()

    local Count = Humanoid.Combat:GetAttribute("ComboCount")
    Utility.Animation:Stop(Humanoid, "Attack")
    Services.Status:CreateStatus(Humanoid, "Combat", "Attacking", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Combo[Count].Duration}) 
    
    if Count >= Data.Attack.ComboMax then
        Humanoid.Combat:SetAttribute("ComboCount", 1)
        Services.Status:CreateStatus(Humanoid, "Cooldown", "Attack", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Cooldown})
    else
        local CurrentTime = tick()
        Humanoid.Combat:SetAttribute("LastAttackTime", CurrentTime)
		Humanoid.Combat:SetAttribute("ComboCount", Count + 1)

        task.delay(Data.Attack.Combo[Count].Duration * 3, function()
			if tick() - Humanoid.Combat:GetAttribute("LastAttackTime") >= Data.Attack.Combo[Count].Duration * 3 then
				Humanoid.Combat:SetAttribute("ComboCount", 1)
			end
		end)
    end

    Utility.Animation:Play(Data.Attack.Combo[Count].Animation.id, Humanoid, Data.Attack.Speed, Enum.AnimationPriority.Action2, "Attack")

    local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character}

    task.wait(Data.Attack.Combo[Count].Windup)

    if not Interrupted() and not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed") then
        EffectService:CreateEffect("Sound", {SFX = Data.Attack.Combo[Count].Swing, Parent = Character.HumanoidRootPart, Time = 2, Volume = 1})
        local Hitbox = HitboxService:Create(Root.CFrame, Data.Attack.Combo[Count].Hitbox, Params)
        Hitbox:WeldTo(Root)
        Hitbox:SetConfig({
            Offset = Data.Attack.Combo[Count].Offset
        })

        local CombatConfig = {
			DamageType = Data.Attack.Combo[Count].DamageType,
			Damage = Data.Attack.Combo[Count].Damage,
		}

        Hitbox:OnHit(function(Char, Hum, Rot)
            self:Handler(Humanoid, Hum, CombatConfig)
        end)

        Hitbox:Run(0.15)
    end
end

--[[ Blocking & Parrying ]]
function CombatService:ParryStart(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Stunned", "Parried", "Sprinting"}}) == true then return end
    if Humanoid.Health <= 0 then return end

    local function HandleParryToBlock(Humanoid: Humanoid, StartTime: number)
        task.spawn(function()
            while Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Parrying") == true do task.wait()
                if tick() - StartTime >= 0.35 then
                    Services.Status:CreateStatus(Humanoid, "Combat", "Blocking", {Set = true}) 
                    break
                end
            end
            Services.Status:CreateStatus(Humanoid, "Combat", "Parrying", {Set = false}) 
        end)
    end

    if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Parried") then
        local CurrentTime = tick()
        Humanoid.Combat:SetAttribute("LastParryTime", CurrentTime)
        Services.Status:CreateStatus(Humanoid, "Combat", "Parrying", {Set = true}) 
        HandleParryToBlock(Humanoid, CurrentTime)

        Utility.Animation:Play(Data.General.Parry.ParryStart.id, Humanoid, 1, Enum.AnimationPriority.Action2, "Parry")
        Utility.Animation:Play(Data.General.Block.BlockHold.id, Humanoid, 1, Enum.AnimationPriority.Action, "Block")

    elseif Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned") then
        Services.Status:CreateStatus(Humanoid, "Combat", "Blocking", {Set = true})

        Utility.Animation:Play(Data.General.Block.BlockHold.id, Humanoid, 1, Enum.AnimationPriority.Action, "Block")
    else
        local LastParry = Humanoid.Combat:GetAttribute("LastParryTime") or 0
        local CurrentTime = tick()

        if CurrentTime - LastParry < 1 then
            Services.Status:CreateStatus(Humanoid, "Combat", "Blocking", {Set = true})

            Utility.Animation:Play(Data.General.Block.BlockHold.id, Humanoid, 1, Enum.AnimationPriority.Action, "Block")
            return
        end

        Humanoid.Combat:SetAttribute("LastParryTime", CurrentTime)
        Services.Status:CreateStatus(Humanoid, "Combat", "Parrying", {Set = true}) 
        HandleParryToBlock(Humanoid, CurrentTime)

        Utility.Animation:Play(Data.General.Parry.ParryStart.id, Humanoid, 1, Enum.AnimationPriority.Action2, "Parry")
        Utility.Animation:Play(Data.General.Block.BlockHold.id, Humanoid, 1, Enum.AnimationPriority.Action, "Block")
    end
end 

function CombatService:ParryStop(Humanoid: Humanoid)
    repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Parrying")

    if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned") then
        task.delay(0.1, function()
            Services.Status:CreateStatus(Humanoid, "Combat", "Blocking", {Set = false})
            Utility.Animation:Stop(Humanoid, "Block")
        end)
    else
        Services.Status:CreateStatus(Humanoid, "Combat", "Blocking", {Set = false})
        Utility.Animation:Stop(Humanoid, "Block")   
    end
end

function CombatService:Parried(Victim: Humanoid, Attacker: Humanoid, Value: number, Info: Info)
    if not Victim or not Attacker then return end

	local ATKWeapon = WeaponData["Fist"] -- Create get humanoid weapon data func
	local VICWeapon = WeaponData["Fist"] -- Create get humanoid weapon data func

    EffectService:CreateEffect("Character", {VFX = game.ReplicatedStorage.Assets.Particles.Parry.Attachment, Parent = Victim.Parent.HumanoidRootPart, Position = Vector3.new(0, 0, -2)})
    EffectService:CreateEffect("Sound", {SFX = SoundModule.Assets.Sounds.SFX.Parry.id, Parent = Victim.Parent.HumanoidRootPart, Time = 2, Volume = 0.5})
    Utility.Animation:Play(AnimationModule.Assets.Animations.COMBAT.PARRY_1.id, Attacker, 1, Enum.AnimationPriority.Action3, "Parried")

    Utility.Animation:Stop(Victim, "Block")
    Utility.Animation:Stop(Victim, "Parry")
    Services.Status:CreateStatus(Victim, "Combat", "Blocking", {Set = false})
    Utility.Animation:Play(VICWeapon.General.Parry.ParryImpact.id, Victim, 1, Enum.AnimationPriority.Action3, "ParryImpact")

    EffectService:CreateEffect("Light", {Colour = Color3.fromRGB(255, 255, 127), Brightness = 3, Radius = 5, CFPosition = Victim.Parent.HumanoidRootPart.CFrame, Time = 2, TweenTime = 1.5, TweenTable = {Brightness = 0, Range = 0}})
end

function CombatService:PostureCheck(Victim: Humanoid, Attacker: Humanoid, Damage: number, Type: string, BlockBreak: boolean)
    -- get posture and max posture @val </3
end

--[[ Handler ]]
function CombatService:Handler(Attacker: Humanoid, Victim: Humanoid, Info: Info)
    if not Attacker or not Victim or not Info then return end

    if Victim.Health == 0 or Attacker.Health == 0 then return end

    local ATKRoot = Attacker.Parent:FindFirstChild("HumanoidRootPart")
    local VICRoot = Victim.Parent:FindFirstChild("HumanoidRootPart")

    if not ATKRoot or not VICRoot then return end

    local Behind = (VICRoot.Position - ATKRoot.Position).Unit:Dot(VICRoot.CFrame.LookVector) >= 0.25

    for Key, Value in pairs(Info) do
        if Victim.Parent:FindFirstChildOfClass("ForceField") ~= nil then return end

        if Services.Status:CheckSpecific(Victim, {Connection = true}, "Dodging") == true then
            Utility.Animation:Stop(Victim, "Dodge")
	        Utility.Animation:Play(AnimationModule.Assets.Animations.ROLL.CANCEL.id, Victim, 1, Enum.AnimationPriority.Action3, "DodgeCancel")
            EffectService:CreateEffect("Sound", {SFX = SoundModule.Assets.Sounds.SFX.Dodged.id, Parent = VICRoot, Time = 2, Volume = 0.5})
            return
        end

        if Services.Status:CheckSpecific(Victim, {Connection = true}, "Parrying") == true then
            Services.Status:CreateStatus(Attacker, "Combat", "Parried", {Set = true, SetTo = false, Timed = true, Time = 0.75}) 
            self:Parried(Victim, Attacker, Value, Info)
            return
        end

        if Key == "Damage" and Value and Services.Status:CheckSpecific(Victim, {Connection = true}, "Blocking") == true then
            self:DamageType(Victim.Parent, Info.DamageType, true)

            local postureChange = Value * 1.25 -- We can add posture scaling here
            StatService:ModifyStat(Victim.Parent, "POSTURE", {
                operation = "add",
                value = postureChange,
            })
            
            local currentPosture = StatService:GetStat(Victim.Parent, "POSTURE")
            local postureMax = StatModule.Templates.POSTURE.maxValue

            if currentPosture >= postureMax or Info.BlockBreak == true then
                -- Handle posture break
                return
            end
            -- Check

            return
        end

        if Key == "Damage" and Value then
            self:DamageType(Victim.Parent, Info.DamageType)
            Services.Status:CreateStatus(Victim, "Combat", "Stunned", {Set = true, SetTo = false, Timed = true, Time = 0.5}) 

            -- Ai damage handle Event
                
            local Pain = "PAIN_"..tostring(math.random(1, 2))
            Utility.Animation:Play(AnimationModule.Assets.Animations.STATUS[Pain].id, Victim, 2, Enum.AnimationPriority.Action2, "Pain")

            self:ApplyDamage(Attacker, Victim, Value)
            -- Fire Combat Tag
            return
        end
    end
end

function CombatService:DamageType(Character: Model, DamageType: string, Blocking: boolean)
    if Blocking == true then 
        -- Get Victim WeaponData
        -- Play Block impact Animation
        local WeaponBlock = false -- For now blocking will appear from arms, will next time reference WeaponData

        if WeaponBlock == true then
            -- Find weapon model/blade, play VFX
        else
            EffectService:CreateEffect("Character", {VFX = game.ReplicatedStorage.Assets.Particles.BlockedHit.Attachment, Parent = Character.HumanoidRootPart})
            EffectService:CreateEffect("Sound", {SFX = SoundModule.Assets.Sounds.SFX.Blocked_Hit.id, Parent = Character.HumanoidRootPart, Time = 2, Volume = 0.5})
        end
    else
        if not DamageType then return end

        if DamageType == "Slash" then
            EffectService:CreateEffect("Blood", {Parent = Character.HumanoidRootPart})
        end

        EffectService:CreateEffect("Character", {VFX = game.ReplicatedStorage.Assets.Particles[DamageType].Attachment, Parent = Character.HumanoidRootPart})
        EffectService:CreateEffect("Sound", {SFX = SoundModule.Assets.Sounds.SFX[DamageType].id, Parent = Character.HumanoidRootPart, Time = 2, Volume = 0.5})
    end
end

function CombatService:MovementHandler(Humanoid: Humanoid, StunType: string)
    local Priority = {
        Dazed = 3,
        Stunned = 2,
        Parried = 1
    }

    if not Priority[StunType] then
        return
    end

    local canApplyStun = true
    for stunName, priority in pairs(Priority) do
        if Services.Status:CheckSpecific(Humanoid, {Connection = true}, stunName) == true and 
            Priority[stunName] > Priority[StunType] then
            canApplyStun = false
            break
        end
    end

    if not canApplyStun then
        return
    end

    task.spawn(function()
        if StunType == "Dazed" then
            Humanoid.WalkSpeed = 0
            Humanoid.JumpPower = 0
        elseif StunType == "Stunned" then
            Humanoid.WalkSpeed = 10
            Humanoid.JumpPower = 0
        elseif StunType == "Parried" then
            Humanoid.JumpPower = 0
        end

        repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, StunType)

        if StunType == "Dazed" or StunType == "Stunned" then
            Humanoid.WalkSpeed = Humanoid.Parent:GetAttribute("SPEED")
        end

        if StunType == "Dazed" or StunType == "Stunned" or StunType == "Parried" then
            Humanoid.JumpPower = 50
        end
    end)
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
