local WeaponData = {}
local SoundModule = require(game.ReplicatedStorage.Modules.SoundModule)
local AnimationModule = require(game.ReplicatedStorage.Modules.AnimationModule)

WeaponData = {
	["Fist"] = {
		General = {
            Animation = {
                Category = "FIST"
            }, 
        },

		Attack = {
            Speed = 0.75,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = {
                    Windup = 0.225,
                    Duration = 0.35,

					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
				},

                [2] = {
                    Windup = 0.225,
                    Duration = 0.35,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
				},

                [3] = {
                    Windup = 0.225,
                    Duration = 0.35,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
				},

                [4] = {
					Windup = 0.225,
                    Duration = 0.35,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
				},
			},

            Aerial = {
				Damage = 8,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 5),
				Offset = CFrame.new(0,0,-3),

                Animation = "AERIAL",
                Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
			},

            Lunge = {
				Damage = 8,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 5),
				Offset = CFrame.new(0,0,-3),

                Animation = "LUNGE",
                Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
			},

			Critical = {
				Module = script.Parent.Criticals.Fist,
				Duration = 1,
				Windup = 0.65,
				Speed = 1,
				Cooldown = 5,

				Damage = 16,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 6),
				Offset = CFrame.new(0,0,-4),

                Animation = "CRITICAL",
                Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing.id
			}
		},
	},
}

return WeaponData