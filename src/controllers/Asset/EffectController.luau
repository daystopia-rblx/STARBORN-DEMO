local EffectController = {}

EffectController.Dependencies = {
    "Event"
}

local Debris = game:GetService("Debris")
local BloodEngine = require(game.ReplicatedStorage.Assets.Modules.BloodEngine).new()

local Controllers
local Modules

type Info = {
	Loop: boolean?,

	VFX: Attachment?,
	Colour: Color3?,
	Parent: Part?,
	Position: Vector3,
	Time: number?,
	NotAttachment: boolean?,

	SFX: string?,
	Volume: number?,
	RandomPitch: boolean?,
	--Parent:Part?,
	--Time:number?,

	--Colour:Color3?,
	Brightness: number?,
	Radius: number?,
	--Time:number?,
	CFPosition: CFrame?,
	TweenTime: number?,
	TweenTable: LocalizationTable?,

	Amount: number?,
}

function EffectController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

EffectController.Listeners = {
	["Effect.Create"] = function(self, EffectType: string, Info: Info)
		if EffectType == "Character" then
			local Effect = Info.VFX:Clone()
			Effect.Parent = Info.Parent

			if Effect:IsA("Attachment") then
				Effect.Position = Effect.Position + (Info.Position or Vector3.new(0, 0, 0))
			end

			if not Info.Time then
				Info.Time = 1
			end

			if Info.NotAttachment then
				for _, child in ipairs(Effect:GetChildren()) do
					if child:IsA("ParticleEmitter") then
						if Info.Colour then
							child.Color = ColorSequence.new(Info.Colour)
						end
						child.Parent = Info.Parent
						child:Emit(child:GetAttribute("EmitCount"))
						game.Debris:AddItem(child, Info.Time + 1)
					end
					task.delay(Info.Time, function()
						if child:IsA("ParticleEmitter") then
							child.Enabled = false
						end
					end)
				end
				Effect:Destroy()
			else
				for _, v in pairs(Effect:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						if Info.Colour then
							v.Color = ColorSequence.new(Info.Colour)
						end
						v:Emit(v:GetAttribute("EmitCount"))
					end
				end
			end

			Debris:AddItem(Effect, Info.Time)
		elseif EffectType == "Sound" then
			local Sound = Instance.new("Sound")
            Sound.SoundId = Info.SFX
			Sound.Parent = Info.Parent
			Sound.Volume = Info.Volume

			if Info.RandomPitch then
				local Equalizer = Instance.new("EqualizerSoundEffect")
				Equalizer.Parent = Sound
				Equalizer.HighGain = math.random(-5, 5)
				Equalizer.MidGain = math.random(-5, 5)
				Equalizer.LowGain = math.random(-5, 5)
			end

			if not Info.Time then
				Info.Time = 1
			end

			Sound:Play()

			Debris:AddItem(Sound, Info.Time)
		elseif EffectType == "Light" then
			if not Info.Colour then
				Info.Colour = Color3.fromRGB(255, 255, 255)
			end

			if Info.Brightness == nil then
				Info.Brightness = 1
			end

			if Info.Radius == nil then
				Info.Radius = 8
				return
			end

			if not Info.Time then
				Info.Time = 1
			end

			local Attachment
			if not Info.Parent then
				Attachment = Instance.new("Attachment")
				Attachment.Name = "LightAttach"
				Attachment.Parent = workspace.Terrain
				local offset = Vector3.new(0, 0, -2)
				Attachment.CFrame = Info.CFPosition * CFrame.new(offset)
			else
				Attachment = Instance.new("Attachment")
				Attachment.Name = "LightAttach"
				Attachment.Parent = Info.Parent

				Attachment.CFrame = CFrame.new()
			end

			local Light = Instance.new("PointLight")
			Light.Parent = Attachment
			Light.Color = Info.Colour
			Light.Brightness = Info.Brightness
			Light.Range = Info.Radius
			Light.Shadows = true

			Debris:AddItem(Attachment, Info.Time)

			if Info.TweenTime and Info.TweenTable then
				local tweenInfo = TweenInfo.new(Info.TweenTime)
				local tween = game.TweenService:Create(Light, tweenInfo, Info.TweenTable)
				tween:Play()
			end
		elseif EffectType == "Blood" then
			if not Info.Amount then
				Info.Amount = math.random(1, 10)
			end

			BloodEngine:EmitAmount(Info.Parent.Position, nil, Info.Amount)
		end
	end,
}

-- Controllers.Event:FireServer("Effect.Queue", "Blood", {Parent = Player.Character.HumanoidRootPart})

return EffectController
