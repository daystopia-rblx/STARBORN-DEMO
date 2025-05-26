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
local CombatService = require(game.ServerScriptService.Services.Combat.CombatService)
local WeaponModels = game.ReplicatedStorage.Assets.Weapons
local Players = game:GetService("Players")

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
			print(Weld)
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

function WeaponService:AssembleWeapon(Character, Humanoid, Data, Profile)
    if Data.General.Unique then return end

    local Model = Instance.new("Model")
    Model.Name = Data.General.Name or "CustomWeapon"

    local GripPart

    local handConfig = Data.General.Model.Right or Data.General.Model.Left
    if handConfig and handConfig.Weapon then
        for _, key in ipairs(handConfig.Weapon) do
            local partInfo = Profile.inventory.weapon.parts[key]
            local modelName = partInfo.Model
            local materialName = partInfo.Material
            local colorString = partInfo.Colour or partInfo.Color

            for _, template in ipairs(WeaponModels:GetDescendants()) do
                if template:IsA("Model") and template.Name == modelName then
                    local clone = template:Clone()
                    clone.Parent = Model

                    if materialName then
                        local matTemplate = template:FindFirstChild(materialName, true)
                        if matTemplate and matTemplate:IsA("SurfaceAppearance") then
                            for _, subPart in ipairs(clone:GetDescendants()) do
                                if subPart:IsA("MeshPart") then
                                    local matClone = matTemplate:Clone()
                                    matClone.Parent = subPart
                                end
                            end
                        end
                    end

					if colorString then
                        local r, g, b = colorString:match("(%d+),%s*(%d+),%s*(%d+)")
                        if r and g and b then
                            local color3 = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                            for _, subPart in ipairs(clone:GetDescendants()) do
                                if subPart:IsA("MeshPart") or subPart:IsA("SurfaceAppearance") then
                                    subPart.Color = color3
								end
                            end
                        end
                    end

                    for _, child in ipairs(clone:GetChildren()) do
                        child.Parent = Model
                    end
                    clone:Destroy()
                    break
                end
            end
        end

        for _, part in ipairs(Model:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == "Grip" then
                GripPart = part
                break
            end
        end
        Model.PrimaryPart = GripPart

        for _, joint in ipairs(Model:GetDescendants()) do
            if joint:IsA("BasePart") and joint.Name == "Joint" then
                local weld = Instance.new("Weld")
                weld.Part0 = GripPart
                weld.Part1 = joint
                weld.C1 = CFrame.Angles(0, math.rad(180), math.rad(90))
                weld.Parent = GripPart
            end
        end
    end

    return Model
end

function WeaponService:SummonVFX(Weapon)
	task.delay(0.05, function()
		for _, Part in ipairs(Weapon:GetDescendants()) do	
			if Part:IsA("BasePart") and Part.Transparency < 1 then
				Services.Particle:CreateParticle({effectType = "CHARACTER", vfx = game.ReplicatedStorage.Assets.Particles.Equip.Attachment, parent = Part, notAttachment = true})
			end
		end
	end)
end

function WeaponService:EquipStart(Character, Humanoid, Data, ...)
	repeat task.wait() until not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Attacking") or not Services.Status:CheckSpecific(Humanoid, {Connection = true}, "Critical")

	--[[if Data.General.Equip and Anim ~= false then -- Removed the Anim boolean for now
        Utility.Animation:Play(Modules.Animation.Assets.Animations.WEAPONS[EquipKey].EQUIP.id, Humanoid, 1, Enum.AnimationPriority.Action, "Equip")

        if Data.General.Equip.EquipSound then
            Services.Particle:CreateParticle({effectType = "SOUND", sfx = Modules.Sound.Assets.Sounds.SFX.Critical_Indicator.id, parent = Character.HumanoidRootPart, duration = 5, volume = 0.75})
        end
        
		task.wait(Data.General.Equip.Timing)
	end]]

	local Weapon
	if Data.General.Model and Data.General.Model.Right then
		Weapon = Data.General.Model.Right.Weapon
	end

	if Data.General.Model and Data.General.Model.Left then
		Weapon = Data.General.Model.Left.Weapon
	end

    local Player = Players:GetPlayerFromCharacter(Character)

    if Player then
        local Profile = Services.Data:GetData(Player.UserId, "PlayerData")
		if not Data.General.Unique then
			Weapon = self:AssembleWeapon(Character, Humanoid, Data, Profile)
		end
    end
	
	if Data.General.Equip.Summon == true then
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
			local WeaponClone = Weapon:Clone()
			WeaponClone.Parent = Character.RightGrip
			self:EquipMotor6D(Character.RightGrip, WeaponClone.Grip)
		end
	else
		if Data.General.Model and Data.General.Model.Right then
			local WeaponClone = Weapon:Clone()
			WeaponClone.Parent = Character.RightGrip
			self:EquipWeld(Character, WeaponClone.Name)
			self:EquipMotor6D(Character.RightGrip, WeaponClone.Grip)
			self:SummonVFX(WeaponClone)
		end

		if Data.General.Model and Data.General.Model.Left then
			local WeaponClone = Weapon:Clone()
			WeaponClone.Parent = Character.LeftGrip
			self:EquipWeld(Character, WeaponClone.Name)
			self:EquipMotor6D(Character.LeftGrip, WeaponClone.Grip)
			self:SummonVFX(WeaponClone)
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
	
	local Weapon
	if Data.General.Model and Data.General.Model.Right then
		Weapon = Data.General.Model.Right.Weapon
	end

	if Data.General.Model and Data.General.Model.Left then
		Weapon = Data.General.Model.Left.Weapon
	end

    local Player = Players:GetPlayerFromCharacter(Character)

    if Player then
        local Profile = Services.Data:GetData(Player.UserId, "PlayerData")
		if not Data.General.Unique then
			Weapon = self:AssembleWeapon(Character, Humanoid, Data, Profile)
		end
    end
	
	if Data.General.Equip.Summon == true then
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
			self:UnequipMotor6D(Character, Weapon.Name)
		end
		if Data.General.Model and Data.General.Model.Left then
			self:UnequipMotor6D(Character, Weapon.Name)
		end
	else
		if Data.General.Model and Data.General.Model.Right then
			self:UnequipMotor6D(Character, Weapon.Name)
			local WeaponClone = Weapon:Clone()
			WeaponClone.Parent = Character
			self:SummonVFX(WeaponClone)
			for _, Location in ipairs(Character:GetChildren()) do
				if Location.Name == Data.General.Model.Right.Parent then
					self:UnequipWeld(Location, WeaponClone, Data.General.Model.Right)
				end
			end
		end
		
		if Data.General.Model and Data.General.Model.Left then
			self:UnequipMotor6D(Character, Weapon.Name)
			local WeaponClone = Weapon:Clone()
			WeaponClone.Parent = Character
			self:SummonVFX(WeaponClone)
			for _, Location in ipairs(Character:GetChildren()) do
				if Location.Name == Data.General.Model.Left.Parent then
					self:UnequipWeld(Location, WeaponClone, Data.General.Model.Left)
				end
			end
		end
	end
end

--[[ Switch ]]
function WeaponService:Switch(Player, Character, Humanoid, Change)
	local NewData = WeaponData[Change]

    local CurrentWeapon = Services.Data:GetData(Player.UserId, "PlayerData").inventory.weapon.type
    local CurrentData = WeaponData[CurrentWeapon]

	CombatService:Unequip(Character, Humanoid, Change, NewData)

	task.delay(0.25, function()
		for _, Models in pairs(Character:GetDescendants()) do
			if Models:GetAttribute("WeldWeapon") then
				Models:Destroy()
			end
		end

		Services.Data:UpdateData(Player.UserId, "PlayerData", function(data)
			data.inventory = data.inventory or {}
			data.inventory.weapon = data.inventory.weapon or {}
			data.inventory.weapon.type = Change

			return data
		end)
	end)
end

return WeaponService