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

function WeaponService:SheathWeld(Part0, Weapon, WeaponData)
	local Weld = Instance.new("Weld")
	Weld.Parent = Part0
	Weld.Part0 = Part0
	Weld.Part1 = Weapon.Grip
	Weld.C0 = CFrame.new(WeaponData.Position) * CFrame.Angles(
		math.rad(WeaponData.Orientation.X),
		math.rad(WeaponData.Orientation.Y),
		math.rad(WeaponData.Orientation.Z)
	)
	Weld.Name = "ActiveWeld"
end

function WeaponService:EquipStart(Character, Humanoid, WeaponData)
	repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") or not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical")

	--[[if WeaponData.General.Equip and Anim ~= false then -- Removed the Anim boolean for now
        Utility.Animation:Play(Modules.Animation.Assets.Animations.WEAPONS[EquipKey].EQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Equip")

        if WeaponData.General.Equip.EquipSound then
            Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Critical_Indicator.id, parent = Character.HumanoidRootPart, duration = 5, volume = 0.75})
        end
        
		task.wait(WeaponData.General.Equip.Timing)
	end]]

	if WeaponData.General.Model and WeaponData.General.Model.Sheath then
		for _, item in ipairs(Character:GetChildren()) do
			if item.Name == WeaponData.General.Model.Sheath.Sheath.Name then
				item:Destroy()

				local Sheath = WeaponData.General.Model.Sheath.Unsheath:Clone()
				Sheath.Parent = Character

				for _, Location in ipairs(Character:GetChildren()) do
					if Location.Name == WeaponData.General.Model.Sheath.Parent then
						self:SheathWeld(Location, Sheath, WeaponData.General.Model.Sheath)
					end
				end
			end
		end

		if WeaponData.General.Model.Right then
			local Weapon = WeaponData.General.Model.Right.Weapon:Clone()
			Weapon.Parent = Character.RightGrip
			self:EquipMotor6D(Character.RightGrip, Weapon.Grip)
		end
	else
		if WeaponData.General.Model and WeaponData.General.Model.Right then
			self:EquipWeld(Character, WeaponData.General.Model.Right.Weapon.Name)
			local Weapon = WeaponData.General.Model.Right.Weapon:Clone()
			Weapon.Parent = Character.RightGrip
			self:EquipMotor6D(Character.RightGrip, Weapon.Grip)
		end
		if WeaponData.General.Model and WeaponData.General.Model.Left then
			self:EquipWeld(Character, WeaponData.General.Model.Left.Weapon.Name)
			local Weapon = WeaponData.General.Model.Left.Weapon:Clone()
			Weapon.Parent = Character.LeftGrip
			self:EquipMotor6D(Character.LeftGrip, Weapon.Grip)
		end
	end
end

-- [[ Unequipping ]]

function WeaponService:UnequipWeld(Part0, Weapon, WeaponData)
	local Weld = Instance.new("Weld")
	Weld.Parent = Part0
	Weld.Part0 = Part0
	Weld.Part1 = Weapon.Grip
	Weld.C0 = CFrame.new(WeaponData.Position) * 
		CFrame.fromOrientation(
			math.rad(WeaponData.Orientation.X),
			math.rad(WeaponData.Orientation.Y),
			math.rad(WeaponData.Orientation.Z)
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

function WeaponService:UnequipStart(Character, Humanoid, WeaponData)
	repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") or not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical")
	
	--[[if WeaponData.General.Equip and Anim ~= false then
		Knit.GetService("EffectService"):playAnimation(WeaponData.General.Equip.Unequip.AnimationId, Character.Humanoid, WeaponData.General.Equip.Speed, Enum.AnimationPriority.Action2, "Unequip")
		if WeaponData.General.Equip.UnequipSound then
			Knit.GetService("EffectService"):playVFX("Sound", {SFX = WeaponData.General.Equip.UnequipSound, Parent = Character.HumanoidRootPart, Time = 2})
		end
		task.wait(WeaponData.General.Equip.Timing)
	end]]

	if WeaponData.General.Model and WeaponData.General.Model.Sheath then
		for _, item in ipairs(Character:GetChildren()) do
			if item.Name == WeaponData.General.Model.Right.Weapon.Name then
				item:Destroy()
			end
			
			if item.Name == WeaponData.General.Model.Sheath.Unsheath.Name then
				item:Destroy()
			end
		end

		local SheathWeapon = WeaponData.General.Model.Sheath.Sheath:Clone()
		SheathWeapon.Parent = Character

		for _, Location in ipairs(Character:GetChildren()) do
			if Location.Name == WeaponData.General.Model.Sheath.Parent then
				self:UnequipWeld(Location, SheathWeapon, WeaponData.General.Model.Sheath)
			end
		end
		
		if WeaponData.General.Model and WeaponData.General.Model.Right then
			self:UnequipMotor6D(Character, WeaponData.General.Model.Right.Weapon.Name)
		end
		if WeaponData.General.Model and WeaponData.General.Model.Left then
			self:UnequipMotor6D(Character, WeaponData.General.Model.Left.Weapon.Name)
		end
	else
		if WeaponData.General.Model and WeaponData.General.Model.Right then
			self:UnequipMotor6D(Character, WeaponData.General.Model.Right.Weapon.Name)
			local Weapon = WeaponData.General.Model.Right.Weapon:Clone()
			Weapon.Parent = Character
			for _, Location in ipairs(Character:GetChildren()) do
				if Location.Name == WeaponData.General.Model.Right.Parent then
					self:UnequipWeld(Location, Weapon, WeaponData.General.Model.Right)
				end
			end
		end
		
		if WeaponData.General.Model and WeaponData.General.Model.Left then
			self:UnequipMotor6D(Character, WeaponData.General.Model.Left.Weapon.Name)
			local Weapon = WeaponData.General.Model.Left.Weapon:Clone()
			Weapon.Parent = Character
			for _, Location in ipairs(Character:GetChildren()) do
				if Location.Name == WeaponData.General.Model.Left.Parent then
					self:UnequipWeld(Location, Weapon, WeaponData.General.Model.Left)
				end
			end
		end
	end
end

return WeaponService