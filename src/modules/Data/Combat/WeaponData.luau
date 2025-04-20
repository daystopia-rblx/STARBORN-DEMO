local WeaponData = {}
local SoundModule = require(game.ReplicatedStorage.Modules.SoundModule)
local AnimationModule = require(game.ReplicatedStorage.Modules.AnimationModule)

WeaponData = {
	["Fist"] = {
		General = {
			WeaponBlock = false,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.FIST.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.FIST.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.FIST.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.FIST.BLOCK_IMPACT
			},
        },

		Attack = {
            Speed =  0.85,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.35,
                    Duration = 0.45,

					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Swing_1.id
				},

                [2] = {
                    Windup = 0.3,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Swing_2.id
				},

                [3] = {
                    Windup = 0.3,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Swing_3.id
				},

                [4] = {
                    Windup = 0.25,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Swing_4.id
				},
			},

            Aerial = {
				Windup = 0.225,
				Duration = 0.35,

				Damage = 8,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 5),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Swing_1.id
			},

            Lunge = {
				Windup = 0.4,
				Duration = 0.6,

				Damage = 8,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 5),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.LUNGE,
                Swing = SoundModule.Assets.Sounds.SFX.Swing_1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Fist.FistService,
				Duration = 1.25,
				Windup = 0.65,
				Speed = 1.25,
				Cooldown = 5,

				Damage = 16,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 6),
				Offset = CFrame.new(0,0,-4),

				Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.CRITICAL,
                Swing = SoundModule.Assets.Sounds.SFX.Swing_1.id,
				Stomp = SoundModule.Assets.Sounds.SFX.Fist_Stomp.id
			}
		},
	},
}

return WeaponData