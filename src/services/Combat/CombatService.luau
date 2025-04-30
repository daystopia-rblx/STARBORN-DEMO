local CombatService = {
    HitCounts = {},
    OriginalSpeed = {}
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
    "Status",
    "Stat",
    "Hitbox",
    "Particle"
}

CombatService.Modules = {
    "Animation",
    "Status",
    "Stat",
    "Sound"
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
local Debris = game:GetService("Debris")

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
        local Data = WeaponData["Fist"]

        local EquipKey = string.upper(Weapon)
	    Utility.Animation:Play(Modules.Animation.Assets.Animations.WEAPONS[EquipKey].EQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Equip")

        self:Equip(Humanoid, Weapon, Data)
    end,

    ["Combat.Unequip"] = function(self, Player: Player)
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped"}}) == true then return end

        -- Figure out how to get player Weapon from Data
        local Weapon = "Fist"
        local Data = WeaponData["Fist"]

        local UnequipKey = string.upper(Weapon)
	    Utility.Animation:Play(Modules.Animation.Assets.Animations.WEAPONS[UnequipKey].UNEQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Unequip")
        Utility.Animation:Stop(Humanoid, "Idle")

        self:Unequip(Humanoid, Weapon, Data)
    end,

    ["Combat.Attack"] = function(self, Player: Player)
        local Character = Player.Character
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        -- Figure out how to get player Weapon from Data
        local Data = WeaponData["Fist"]

        if Services.Status:CheckSpecific(Character.Humanoid, {Connection = true}, "Equipped") then
            if Humanoid.FloorMaterial == Enum.Material.Air then
                self:Aerial(Character, Humanoid, Root, Data)
            else
                self:Attack(Character, Humanoid, Root, Data)
            end
        end
    end,

    ["Combat.Critical"] = function(self, Player: Player)
        local Character = Player.Character
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        if Services.Status:CheckSpecific(Character.Humanoid, {Connection = true}, "Equipped") then

            -- Figure out how to get player Weapon from Data
            local Data = WeaponData["Fist"]

            self:Critical(Character, Humanoid, Root, Data)
        end
    end,

    ["Combat.Stomp"] = function(self, Player: Player)
        local Character = Player.Character
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        self:Stomp(Character, Humanoid, Root)
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
            local Data = WeaponData["Fist"]

            self:ParryStart(Humanoid, Weapon, Data)
        else
            -- Default to fist parrying (so you can parry without equipping)
            local Weapon = "Fist"
            local Data = WeaponData["Fist"]

            self:ParryStart(Humanoid, Weapon, Data)
        end
    end,
}

function CombatService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

--[[ Trail ]]
function CombatService:Trail(Character, Duration)
    for _, trail in ipairs(Character:GetDescendants()) do
        if trail:IsA("Trail") and ((trail:GetAttribute("GripTrail") == true)) then
            trail.Enabled = true
            task.delay(Duration, function()
                trail.Enabled = false
            end)
        end
    end
end

--[[ Equipping ]]
function CombatService:Equip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    local IdleKey = string.upper(Weapon)
    Utility.Animation:Play(Modules.Animation.Assets.Animations.WEAPONS[IdleKey].IDLE.id, Humanoid, 1, Enum.AnimationPriority.Idle, "Idle")

    Services.Status:CreateStatus(Humanoid, "Combat", "Equipped", {Set = true})
end

function CombatService:Unequip(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    Services.Status:CreateStatus(Humanoid, "Combat", "Equipped", {Set = false})
end

--[[ Attacking ]]
function CombatService:Attack(Character: Model, Humanoid: Humanoid, Root: BasePart, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Running"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}, "Attack") == true then return end

    local Count = Humanoid.Combat:GetAttribute("ComboCount")
    Utility.Animation:Stop(Humanoid, "Attack")
    Services.Status:CreateStatus(Humanoid, "Combat", "Attacking", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Combo[Count].Duration}) 

    local function Checker()
        local cancelled = false

        task.spawn(function()
            while Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") do
                if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed", "Parried") then
                    cancelled = true
                    Utility.Animation:Stop(Humanoid, "Attack")
                    Humanoid.Combat:SetAttribute("ComboCount", 1)
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

    Utility.Animation:Play(Data.Attack.Combo[Count].Animation.id, Humanoid, Data.Attack.Speed, Enum.AnimationPriority.Action3, "Attack")
    self:Trail(Character, Data.Attack.Combo[Count].Duration)

    local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character}

    task.wait(Data.Attack.Combo[Count].Windup)

    if not Interrupted() and not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed") then
        Services.Particle:CreateParticle({effectType = "SOUND", sfx = Data.Attack.Combo[Count].Swing, parent = Root, duration = 2, volume = 0.5})
        local Hitbox = Services.Hitbox:Create(Root.CFrame, Data.Attack.Combo[Count].Hitbox, Params)
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

-- [[ Critical ]]
function CombatService:Critical(Character: Model, Humanoid: Humanoid, Root: BasePart, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Running"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}, "Critical") == true then return end

    Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Critical_Indicator.id, parent = Root, duration = 5, volume = 0.75})

    -- Temp stuff
    Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.CriticalIndicator.Attachment, parent = Root, duration = 5})
    Services.Particle:CreateParticle({effectType = "LIGHT", colour = Color3.fromRGB(255, 0, 0), brightness = 3, radius = 5, parent = Root, cfPosition = Root.CFrame, duration = 4, tweenTime = 3, tweenTable = {Brightness = 0, Range = 0}})


    local WeaponCritical = require(Data.Attack.Critical.Module)
    WeaponCritical:Critical(Character, Humanoid, Root, Data)
end

--[[ Aerial ]]
function CombatService:Aerial(Character: Model, Humanoid: Humanoid, Root: BasePart, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Running"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}, "Aerial") == true then return end

    Utility.Animation:Stop(Humanoid, "Stomp")   
    Services.Status:CreateStatus(Humanoid, "Combat", "Attacking", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Aerial.Duration}) 
    Services.Status:CreateStatus(Humanoid, "Cooldown", "Aerial", {Set = true, SetTo = false, Timed = true, Time = Data.Attack.Cooldown})

    local function Checker()
        local cancelled = false

        task.spawn(function()
            while Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") do
                if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed", "Parried") then
                    cancelled = true
                    Utility.Animation:Stop(Humanoid, "Aerial")
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

    Utility.Animation:Play(Data.Attack.Aerial.Animation.id, Humanoid, Data.Attack.Speed, Enum.AnimationPriority.Action4, "Aerial")
    self:Trail(Character, Data.Attack.Aerial.Duration)

    local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character}

    local AerialVel = Instance.new("BodyVelocity")
	AerialVel.Name = "AerialVelocity"
	Debris:AddItem(AerialVel, 0.2)

	AerialVel.P = 3e3
	AerialVel.MaxForce = Vector3.new(50000,50000,50000)
	AerialVel.Velocity = (Root.CFrame.LookVector * 50) + (Root.CFrame.UpVector * -20)

	AerialVel.Parent = Root

    task.wait(Data.Attack.Aerial.Windup)

    if not Interrupted() and not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed") then
        Services.Particle:CreateParticle({effectType = "SOUND", sfx = Data.Attack.Aerial.Swing, parent = Root, duration = 2, volume = 0.5})
        local Hitbox = Services.Hitbox:Create(Root.CFrame, Data.Attack.Aerial.Hitbox, Params)
        Hitbox:WeldTo(Root)
        Hitbox:SetConfig({
            Offset = Data.Attack.Aerial.Offset
        })

        local CombatConfig = {
			DamageType = Data.Attack.Aerial.DamageType,
			Damage = Data.Attack.Aerial.Damage,
		}

        Hitbox:OnHit(function(Char, Hum, Rot)
            self:Handler(Humanoid, Hum, CombatConfig)
        end)

        Hitbox:Run(0.15)
    end
end

--[[ Stomp ]]
function CombatService:Stomp(Character: Model, Humanoid: Humanoid, Root: BasePart)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Running"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}, "Stomp") == true then return end

    local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Character}

    if not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Stunned", "Dazed") then
        local Hitbox = Services.Hitbox:Create(Root.CFrame, Vector3.new(5, 3, 5), Params)
        Hitbox:WeldTo(Root)
        Hitbox:SetConfig({
            Offset = CFrame.new(0, -3, 0)
        })

        local CombatConfig = {
			DamageType = "Blunt",
			Damage = 5,
		}

        Hitbox:OnHit(function(Char, Hum, Rot)
            self:Handler(Humanoid, Hum, CombatConfig)
            self:StompAttack(Character, Humanoid, Root, Char)
        end)

        Hitbox:Run(0.15)
    end
end

function CombatService:StompAttack(Character: Model, Humanoid: Humanoid, Root: BasePart, Victim: Model)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Running"}}) == true then return end
    if Services.Status:CheckCooldowns(Humanoid, {Connection = true}, "Stomp") == true then return end

    Services.Status:CreateStatus(Humanoid, "Combat", "Attacking", {Set = true, SetTo = false, Timed = true, Time = 0.25}) 
    Services.Status:CreateStatus(Humanoid, "Cooldown", "Stomp", {Set = true, SetTo = false, Timed = true, Time = 3})
    Utility.Animation:Play(Modules.Animation.Assets.Animations.COMBAT.STOMP.id, Humanoid, 1.35, Enum.AnimationPriority.Action3, "Stomp")

	local StompVel = Instance.new("BodyVelocity")
	StompVel.Name = "StompVelocity"
	Debris:AddItem(StompVel, 0.3)

	StompVel.P = 3e3
	StompVel.MaxForce = Vector3.new(30000, 30000, 30000)
	StompVel.Velocity = (Root.CFrame.LookVector * -35) + (Root.CFrame.UpVector * 15)

	StompVel.Parent = Root

    Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Stomp.id, parent = Root, duration = 2, volume = 0.5})
    Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.HeadStomp.Attachment, parent = Victim.Head})
end

--[[ Blocking & Parrying ]]
function CombatService:ParryStart(Humanoid: Humanoid, Weapon: string, Data: WeaponData)
    if Services.Status:CheckStatus(Humanoid, {Connection = true, Exclude = {"Equipped", "Stunned", "Parried", "Sprinting"}}) == true then return end
    if Humanoid.Health <= 0 then return end

    local origin = self.OriginalSpeed[Humanoid]
    if not origin then
        origin = Humanoid.Parent:GetAttribute("SPEED") or 16
        self.OriginalSpeed[Humanoid] = origin
    end

    task.spawn(function()
        while task.wait() do
            if Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Blocking") then
                Humanoid.WalkSpeed = origin / 2
            else
                Humanoid.WalkSpeed = origin
            end
        end
    end)

    Utility.Animation:Stop(Humanoid, "Pain")

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

    Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Parry.Attachment, parent = Victim.Parent.HumanoidRootPart, position = Vector3.new(0, 0, -2)})
    Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Parry.id, parent = Victim.Parent.HumanoidRootPart, duration = 2, volume = 0.5})
    Utility.Animation:Play(Modules.Animation.Assets.Animations.COMBAT.PARRY_1.id, Attacker, 1, Enum.AnimationPriority.Action3, "Parried")

    Utility.Animation:Stop(Victim, "Block")
    Utility.Animation:Stop(Victim, "Parry")
    Services.Status:CreateStatus(Victim, "Combat", "Blocking", {Set = false})
    Utility.Animation:Play(VICWeapon.General.Parry.ParryImpact.id, Victim, 1, Enum.AnimationPriority.Action2, "ParryImpact")

    Services.Particle:CreateParticle({effectType = "LIGHT", colour = Color3.fromRGB(255, 255, 127), brightness = 3, radius = 5, parent = Victim.Parent.HumanoidRootPart, cfPosition = Victim.Parent.HumanoidRootPart.CFrame, duration = 2, tweenTime = 1.5, tweenTable = {Brightness = 0, Range = 0}})
end

function CombatService:PostureCheck(Victim: Humanoid, Attacker: Humanoid, Damage: number, Type: string, BlockBreak: boolean)
    if not Victim or not Attacker then return end

    local victimPosture = Services.Stat:GetStat(Victim.Parent, "POSTURE")
    local attackerPosture = Services.Stat:GetStat(Attacker.Parent, "POSTURE")
    local maxPosture = Modules.Stat.Templates.POSTURE.maxValue

    if BlockBreak or victimPosture >= maxPosture then
        Services.Status:CreateStatus(Victim, "Combat", "Dazed", {Set = true, SetTo = false, Timed = true, Time = Modules.Stat.Constants.COMBAT.POSTURE_RECOVERY_DELAY})
        self:MovementHandler(Victim, "Dazed")

        Services.Status:CreateStatus(Victim, "Combat", "Blocking", {Set = false})
        Services.Status:CreateStatus(Victim, "Combat", "Parrying", {Set = false})
        Utility.Animation:Stop(Victim, "Block")
        Utility.Animation:Stop(Victim, "Parry")

        Utility.Animation:Play(Modules.Animation.Assets.Animations.COMBAT.DAZE_LOOP.id, Victim, 1, Enum.AnimationPriority.Action3, "Dazed")
        Utility.Animation:Play(Modules.Animation.Assets.Animations.COMBAT.DAZE_START.id, Victim, 1, Enum.AnimationPriority.Action3, "DazeStart")
        Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Block_Break.id, parent = Victim.Parent.HumanoidRootPart, duration = 2, volume = 0.5})
        Services.Particle:PlayParticle("Combat", "Blood", Victim.Parent.HumanoidRootPart, 10)

        Services.Stat:ModifyStat(Victim.Parent, "POSTURE", {
            operation = "set",
            value = 0,
        })

        Services.Stat:ModifyStat(Attacker.Parent, "POSTURE", {
            operation = "add",
            value = Modules.Stat.Constants.COMBAT.POSTURE_BREAK_REWARD,
        })
    end
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
	        Utility.Animation:Play(Modules.Animation.Assets.Animations.ROLL.CANCEL.id, Victim, 1.15, Enum.AnimationPriority.Action4, "DodgeCancel")
            Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Dodged.Attachment, parent = VICRoot, notAttachment = true})
            Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Dodged.id, parent = VICRoot, duration = 2, volume = 0.5})
            return
        end

        if Services.Status:CheckSpecific(Victim, {Connection = true}, "Parrying") == true then
            Services.Status:CreateStatus(Attacker, "Combat", "Parried", {Set = true, SetTo = false, Timed = true, Time = 0.75})
            self:MovementHandler(Attacker, "Parried")
            self:Parried(Victim, Attacker, Value, Info)
            return
        end

        if Key == "Damage" and Value and Services.Status:CheckSpecific(Victim, {Connection = true}, "Blocking") == true then
            self:DamageType(Victim.Parent, Info.DamageType, true)

            local postureDamageMultiplier = Modules.Stat.Constants.COMBAT.POSTURE_DAMAGE_MULTIPLIER
            local postureChange = Value * postureDamageMultiplier

            Services.Stat:ModifyStat(Victim.Parent, "POSTURE", {
                operation = "add",
                value = postureChange,
            })

            self:PostureCheck(Victim, Attacker, postureChange, Info.DamageType, Info.BlockBreak)
            return
        end

        if Key == "Damage" and Value then
            self:DamageType(Victim.Parent, Info.DamageType)
            Services.Status:CreateStatus(Victim, "Combat", "Stunned", {Set = true, SetTo = false, Timed = true, Time = 0.5})

            -- Ai damage handle Event

            local prevCount = self.HitCounts[Victim] or 0
            local newCount = (prevCount % 3) + 1
            self.HitCounts[Victim] = newCount
        
            local Pain = "PAIN_" .. tostring(newCount)
            local Anim = Modules.Animation.Assets.Animations.STATUS[Pain].id
            Utility.Animation:Stop(Victim, "Pain")
            Utility.Animation:Play(Anim, Victim, 1.25, Enum.AnimationPriority.Action3, "Pain")

            self:MovementHandler(Victim,"Stunned")
            self:ApplyDamage(Attacker, Victim, Value)
            -- Fire Combat Tag
            return
        end
    end
end

function CombatService:DamageType(Character: Model, DamageType: string, Blocking: boolean)
    if Blocking == true then

        local VICWeapon = WeaponData["Fist"] -- Create get humanoid weapon data func
        local WeaponBlock = VICWeapon.General.WeaponBlock -- For now blocking will appear from arms, will next time reference WeaponData

        Utility.Animation:Play(VICWeapon.General.Block.BlockImpact.id, Character.Humanoid, 1, Enum.AnimationPriority.Action3, "BlockImpact")

        if WeaponBlock == true then
            -- Find weapon model/blade, play VFX
        else
            Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Block.FistBlock.Attachment, parent = Character["Left Arm"], duration = 2, notAttachment = true})
            Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Block.FistBlock.Attachment, parent = Character["Right Arm"], duration = 2, notAttachment = true})
            Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Blocked_Hit.id, parent = Character.HumanoidRootPart, duration = 2, volume = 0.5})
        end
    else
        if not DamageType then return end

        if DamageType == "Slash" then
            Services.Particle:PlayParticle("Combat", "Blood", Character.HumanoidRootPart, 10)
        end

        Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles[DamageType].Attachment, parent = Character.HumanoidRootPart, duration = 2, volume = 0.5})
        Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX[DamageType].id, parent = Character.HumanoidRootPart, duration = 2, volume = 0.5})
    end
end

function CombatService:MovementHandler(Humanoid: Humanoid, StunType: string)
    local Priority = {
        Dazed   = 3,
        Stunned = 2,
        Parried = 1,
    }

    if not Priority[StunType] then
        return
    end

    for otherType, pr in pairs(Priority) do
        if pr > Priority[StunType]
           and Services.Status:CheckSpecific(Humanoid, { Connection = true }, otherType) then
            return
        end
    end

    local origin = self.OriginalSpeed[Humanoid]
    if not origin then
        origin = Humanoid.Parent:GetAttribute("SPEED") or 16
        self.OriginalSpeed[Humanoid] = origin
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

        repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, { Connection = true }, StunType)

        if StunType == "Dazed" or StunType == "Stunned" then
            Utility.Animation:Stop(Humanoid, StunType)
            Humanoid.WalkSpeed = origin
            self.OriginalSpeed[Humanoid] = nil
        end

        Humanoid.JumpPower = 50
    end)
end

function CombatService:ApplyDamage(source, target, damageValue)
    if not source or not target then return false end

    local humanoid = target:FindFirstChild("Humanoid")
    if not humanoid then return false end

    if damageValue <= 0 then return false end

    Services.Stat:ModifyStat(target, "HEALTH", {
        operation = "subtract",
        value = damageValue,
        metadata = {
            source = source,
            type = "combat"
        }
    })

    Services.Event:Fire("Combat.Damage", {
        source = source,
        target = target,
        damage = damageValue
    })

    return true
end

return CombatService
