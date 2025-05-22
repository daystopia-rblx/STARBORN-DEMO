local WeaponService = {}

WeaponService.Dependencies = {
    "Event",
    "Asset",
    "Status",
    "Stat",
    "Particle",
    "Data"
}

WeaponService.Modules = {
    "Animation",
    "Status",
    "Stat",
    "Sound"
}
local Utility = {
    Animation = require(game.ReplicatedStorage.Modules.Utility.Animation)
}

local Services
local Modules

local WeaponData = require(game.ReplicatedStorage.Modules.Data.Combat.WeaponData)

function WeaponService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

-- [[ Equip ]]
function WeaponService:EquipMotor6D(Part0, Weapon)
	local Motor6D = Instance.new("Motor6D")
	Motor6D.Parent = Part0
	Motor6D.Part0 = Part0
	Motor6D.Part1 = Weapon
	Motor6D.Name = "ActiveMotor6D"
end

function WeaponService:EquipWeld(Character, Weapon)
	for _, Weld in ipairs(Character:GetChildren()) do
		if Weld.Name == "ActiveWeld" or (Weld.Name == Weapon) then
			Weld:Destroy()
		end
	end
end

function WeaponService:SheathWeld(Part0, Weapon, Data)
	local Weld = Instance.new("Weld")
	Weld.Parent = Part0
	Weld.Part0 = Part0
	Weld.Part1 = Weapon.Grip
	Weld.C0 = CFrame.new(Data.Position) * CFrame.Angles(
		math.rad(Data.Orientation.X),
		math.rad(Data.Orientation.Y),
		math.rad(Data.Orientation.Z)
	)
	Weld.Name = "ActiveWeld"
end

local function Deletethislater(Weapon)
	task.delay(0.05, function()
		for _, Part in ipairs(Weapon:GetDescendants()) do	
			if Part:IsA("BasePart") and Part.Transparency < 1 then
				Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Equip.Attachment, parent = Part, notAttachment = true})
			end
		end
	end)
end

function WeaponService:EquipStart(Character, Humanoid, Data)
	repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") or not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical")

	--[[if Data.General.Equip and Anim ~= false then -- Removed the Anim boolean for now
        Utility.Animation:Play(Modules.Animation.Assets.Animations.WEAPONS[EquipKey].EQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Equip")

        if Data.General.Equip.EquipSound then
            Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Critical_Indicator.id, parent = Character.HumanoidRootPart, duration = 5, volume = 0.75})
        end
        
		task.wait(Data.General.Equip.Timing)
	end]]
	
	if Data.General.Equip.Summon == true then -- Delete later
        local EquipSummon = Utility.Animation:Play(Data.General.Equip.Equip.id, Humanoid, 2.5, Enum.AnimationPriority.Action, "Equip")

		EquipSummon.Stopped:Wait()
 		Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Summon.id, parent = Character.HumanoidRootPart, duration = 2, volume = 0.5})
		Utility.Animation:Play(Data.General.Equip.Equip2.id, Humanoid, 1.25, Enum.AnimationPriority.Action, "Equip")
	end

	if Data.General.Model and Data.General.Model.Sheath then
		for _, item in ipairs(Character:GetChildren()) do
			if item.Name == Data.General.Model.Sheath.Sheath.Name then
				item:Destroy()

				local Sheath = Data.General.Model.Sheath.Unsheath:Clone()
				Sheath.Parent = Character

				for _, Location in ipairs(Character:GetChildren()) do
					if Location.Name == Data.General.Model.Sheath.Parent then
						self:SheathWeld(Location, Sheath, Data.General.Model.Sheath)
					end
				end
			end
		end

		if Data.General.Model.Right then
			local Weapon = Data.General.Model.Right.Weapon:Clone()
			Weapon.Parent = Character.RightGrip
			self:EquipMotor6D(Character.RightGrip, Weapon.Grip)
		end
	else
		if Data.General.Model and Data.General.Model.Right then
			self:EquipWeld(Character, Data.General.Model.Right.Weapon.Name)
			local Weapon = Data.General.Model.Right.Weapon:Clone()
			Weapon.Parent = Character.RightGrip
			Deletethislater(Weapon)
			self:EquipMotor6D(Character.RightGrip, Weapon.Grip)
		end

		if Data.General.Model and Data.General.Model.Left then
			self:EquipWeld(Character, Data.General.Model.Left.Weapon.Name)
			local Weapon = Data.General.Model.Left.Weapon:Clone()
			Weapon.Parent = Character.LeftGrip
			Deletethislater(Weapon)
			self:EquipMotor6D(Character.LeftGrip, Weapon.Grip)
		end
	end
end

-- [[ Unequipping ]]
function WeaponService:UnequipWeld(Part0, Weapon, Data)
	local Weld = Instance.new("Weld")
	Weld.Parent = Part0
	Weld.Part0 = Part0
	Weld.Part1 = Weapon.Grip
	Weld.C0 = CFrame.new(Data.Position) * 
		CFrame.fromOrientation(
			math.rad(Data.Orientation.X),
			math.rad(Data.Orientation.Y),
			math.rad(Data.Orientation.Z)
		)

	Weld.Name = "ActiveWeld"
	Weapon:SetAttribute("WeldWeapon", true)
end

function WeaponService:UnequipMotor6D(Character, Weapon)
	for _, Motor in ipairs(Character.RightGrip:GetChildren()) do
		if Motor.Name == "ActiveMotor6D" or Motor.Name == Weapon then
			Motor:Destroy()
		end
	end
	for _, Motor in ipairs(Character.LeftGrip:GetChildren()) do
		if Motor.Name == "ActiveMotor6D" or Motor.Name == Weapon then
			Motor:Destroy()
		end
	end
end

function WeaponService:UnequipStart(Character, Humanoid, Data)
	repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") or not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical")
	
	--[[if Data.General.Equip and Anim ~= false then
		Knit.GetService("EffectService"):playAnimation(Data.General.Equip.Unequip.AnimationId, Character.Humanoid, Data.General.Equip.Speed, Enum.AnimationPriority.Action2, "Unequip")
		if Data.General.Equip.UnequipSound then
			Knit.GetService("EffectService"):playVFX("Sound", {SFX = Data.General.Equip.UnequipSound, Parent = Character.HumanoidRootPart, Time = 2})
		end
		task.wait(Data.General.Equip.Timing)
	end]]

	if Data.General.Equip.Summon == true then -- Delete later
		local track = Utility.Animation:Play(Data.General.Equip.Unequip.id, Humanoid, 1, Enum.AnimationPriority.Action, "Unequip")
    	repeat local name = track.KeyframeReached:Wait() until name == "Unequip"
		Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Summon.id, parent = Character.HumanoidRootPart, duration = 2, volume = 0.5})
	end

	if Data.General.Model and Data.General.Model.Sheath then
		for _, item in ipairs(Character:GetChildren()) do
			if item.Name == Data.General.Model.Right.Weapon.Name then
				item:Destroy()
			end
			
			if item.Name == Data.General.Model.Sheath.Unsheath.Name then
				item:Destroy()
			end
		end

		local SheathWeapon = Data.General.Model.Sheath.Sheath:Clone()
		SheathWeapon.Parent = Character

		for _, Location in ipairs(Character:GetChildren()) do
			if Location.Name == Data.General.Model.Sheath.Parent then
				self:UnequipWeld(Location, SheathWeapon, Data.General.Model.Sheath)
			end
		end
		
		if Data.General.Model and Data.General.Model.Right then
			self:UnequipMotor6D(Character, Data.General.Model.Right.Weapon.Name)
		end
		if Data.General.Model and Data.General.Model.Left then
			self:UnequipMotor6D(Character, Data.General.Model.Left.Weapon.Name)
		end
	else
		if Data.General.Model and Data.General.Model.Right then
			self:UnequipMotor6D(Character, Data.General.Model.Right.Weapon.Name)
			local Weapon = Data.General.Model.Right.Weapon:Clone()
			Weapon.Parent = Character
			Deletethislater(Weapon)
			for _, Location in ipairs(Character:GetChildren()) do
				if Location.Name == Data.General.Model.Right.Parent then
					self:UnequipWeld(Location, Weapon, Data.General.Model.Right)
				end
			end
		end
		
		if Data.General.Model and Data.General.Model.Left then
			self:UnequipMotor6D(Character, Data.General.Model.Left.Weapon.Name)
			local Weapon = Data.General.Model.Left.Weapon:Clone()
			Weapon.Parent = Character
			Deletethislater(Weapon)
			for _, Location in ipairs(Character:GetChildren()) do
				if Location.Name == Data.General.Model.Left.Parent then
					self:UnequipWeld(Location, Weapon, Data.General.Model.Left)
				end
			end
		end
	end
end

return WeaponService