local WeaponData = {}
local SoundModule = require(game.ReplicatedStorage.Modules.SoundModule)
local AnimationModule = require(game.ReplicatedStorage.Modules.AnimationModule)

WeaponData = {
	--[[ Unique Weaponry ]]
	["Fist"] = {
		General = {
			Fist = true,
			Unique = true,
			WeaponBlock = false,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.FIST.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.FIST.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.FIST.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.FIST.BLOCK_IMPACT
			},

			Equip = {
				Equip = AnimationModule.Assets.Animations.WEAPONS.FIST.EQUIP.id,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.FIST.UNEQUIP.id,
				Idle = AnimationModule.Assets.Animations.WEAPONS.FIST.IDLE.id
			},
        },

		Attack = {
            Speed =  1,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.3,
                    Duration = 0.45,

					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing1.id
				},

                [2] = {
                    Windup = 0.25,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing2.id
				},

                [3] = {
                    Windup = 0.25,
                    Duration = 0.55,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing3.id
				},

                [4] = {
                    Windup = 0.25,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Blunt",
					Hitbox = Vector3.new(5, 6, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.3,
				Duration = 0.45,

				Damage = 8,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 5),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Fist.FistService,
				Duration = 1.25,
				Windup = 0.7,
				Speed = 1,
				Cooldown = 5,

				Damage = 16,
				DamageType = "Blunt",
				Hitbox = Vector3.new(5, 6, 6),
				Offset = CFrame.new(0,0,-4),

				Animation = AnimationModule.Assets.Animations.WEAPONS.FIST.CRITICAL,
                Swing = SoundModule.Assets.Sounds.SFX.Fist_Swing1.id,
				Stomp = SoundModule.Assets.Sounds.SFX.Fist_Stomp.id
			}
		},
	},

	["Starter Sword"] = {
		General = {
			WeaponBlock = true,
			Unique = true,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.SWORD.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.SWORD.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.SWORD.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.SWORD.BLOCK_IMPACT
			},

			Equip = {
				Summon = true,
				Equip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_1,
				Equip2 = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_2,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.UNEQUIP,
				Idle = AnimationModule.Assets.Animations.WEAPONS.SWORD.IDLE.id
			},

			Model = {
				Right = {
					Weapon = game.ReplicatedStorage.Assets.Weapons.Unique.StarterSword,

					Parent = "Torso",
					Position = Vector3.new(-1, -0.75, -1.25),
					Orientation = Vector3.new(-20, -180, -180)
				}
			}
        },

		Attack = {
            Speed =  0.85,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.3,
                    Duration = 0.5,

					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(9, 5, 8),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},

                [2] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(9, 5, 8),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id
				},

                [3] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(6, 5, 9),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id
				},

                [4] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(8, 5, 7),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.3,
				Duration = 0.5,

				Damage = 8,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 11),
				Offset = CFrame.new(0,0,-5),

				Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Sword.SwordService,
				Duration = 1.25,
				Windup = 0.55,
				Speed = 0.95,
				Cooldown = 6,

				Damage = 16,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 8),
				Offset = CFrame.new(0,0,-4),

				Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.CRITICAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id,
			}
		},
	},

	["Starter Axe"] = {
		General = {
			WeaponBlock = true,
			Unique = true,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.AXE.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.AXE.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.AXE.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.AXE.BLOCK_IMPACT
			},

			Equip = {
				Summon = true,
				Equip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_1,
				Equip2 = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_2,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.UNEQUIP,
				Idle = AnimationModule.Assets.Animations.WEAPONS.AXE.IDLE.id
			},

			Model = {
				Right = {
					Weapon = game.ReplicatedStorage.Assets.Weapons.Unique.StarterAxe,

					Parent = "Torso",
					Position = Vector3.new(-1, -1, -0.5),
					Orientation = Vector3.new(-25, 180, 0)
				}
			}
        },

		Attack = {
            Speed =  0.9,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.55,
                    Duration = 0.8,

					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(9, 5, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.AXE.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},

                [2] = {
                    Windup = 0.25,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(9, 5, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.AXE.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id
				},

                [3] = {
                    Windup = 0.4,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(7, 5, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.AXE.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id
				},

                [4] = {
                    Windup = 0.5,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 6),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.AXE.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.3,
				Duration = 0.5,

				Damage = 8,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 6, 5),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.AXE.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Sword.SwordService,
				Duration = 1.3,
				Windup = 0.5,
				Speed = 0.8,
				Cooldown = 6,

				Damage = 16,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 6),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.AXE.CRITICAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id,
			}
		},
	},

	["Starter Dagger"] = {
		General = {
			WeaponBlock = true,
			Unique = true,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.DAGGER.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.DAGGER.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.DAGGER.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.DAGGER.BLOCK_IMPACT
			},

			Equip = {
				Summon = true,
				Equip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_1,
				Equip2 = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_2,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.UNEQUIP,
				Idle = AnimationModule.Assets.Animations.WEAPONS.DAGGER.IDLE.id
			},

			Model = {
				Right = {
					Weapon = game.ReplicatedStorage.Assets.Weapons.Unique.StarterDagger,

					Parent = "Torso",
					Position = Vector3.new(-1, -0.75, -1),
					Orientation = Vector3.new(-35, -180, -180)
				}
			}
        },

		Attack = {
            Speed =  0.925,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.3,
                    Duration = 0.45,

					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(7, 5, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},

                [2] = {
                    Windup = 0.25,
                    Duration = 0.35,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(4, 5, 7),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id
				},

                [3] = {
                    Windup = 0.3,
                    Duration = 0.4,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 6),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id
				},

                [4] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 6),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.35,
				Duration = 0.6,

				Damage = 8,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 11),
				Offset = CFrame.new(0,0,-5),

				Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Dagger.DaggerService,
				Duration = 1.25,
				Windup = 0.6,
				Speed = 0.95,
				Cooldown = 6,

				Damage = 16,
				DamageType = "Slash",
				Hitbox = Vector3.new(8, 5, 6),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.CRITICAL,
                Swing_1 = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id,
				Swing_2 = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id,
				Swing_3 = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id,
			}
		},
	},

	--[[ Blacksmith Weaponry ]]
	["Spear"] = {
		General = {
			WeaponBlock = true,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.SPEAR.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.SPEAR.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.SPEAR.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.SPEAR.BLOCK_IMPACT
			},

			Equip = {
				Summon = true,
				Equip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_1,
				Equip2 = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_2,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.UNEQUIP,
				Idle = AnimationModule.Assets.Animations.WEAPONS.SPEAR.IDLE.id
			},

			Model = {
				Right = {
					Weapon = { --game.ReplicatedStorage.Assets.Weapons.Unique.TestSpear,
						"SPR_BLADE",
						"SPR_GRIP",
						"SPR_GUARD",
						"SPR_POLE",
						"SPR_POMMEL"
					},

					Parent = "Torso",
					Position = Vector3.new(0.5, 0.25, 0.5),
					Orientation = Vector3.new(-25, 90, 90)
				}
			}
        },

		Attack = {
            Speed =  0.9,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.35,
                    Duration = 0.45,

					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 10),
					Offset = CFrame.new(0, 0, -5),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SPEAR.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},

                [2] = {
                    Windup = 0.35,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 10),
					Offset = CFrame.new(0, 0, -5),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SPEAR.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id
				},

                [3] = {
                    Windup = 0.3,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 9),
					Offset = CFrame.new(0, 0, -5),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SPEAR.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id
				},

                [4] = {
                    Windup = 0.3,
                    Duration = 0.45,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 10),
					Offset = CFrame.new(0, 0, -5),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SPEAR.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.3,
				Duration = 0.35,

				Damage = 8,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 11),
				Offset = CFrame.new(0,0,-5),

				Animation = AnimationModule.Assets.Animations.WEAPONS.SPEAR.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Spear.SpearService,
				Duration = 1.25,
				Windup = 0.55,
				Speed = 0.95,
				Cooldown = 6,

				Damage = 16,
				DamageType = "Slash",
				Hitbox = Vector3.new(11, 5, 9),
				Offset = CFrame.new(0,0,-5),

				Animation = AnimationModule.Assets.Animations.WEAPONS.SPEAR.CRITICAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id,
			}
		},
	},

	["Sword"] = {
		General = {
			WeaponBlock = true,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.SWORD.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.SWORD.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.SWORD.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.SWORD.BLOCK_IMPACT
			},

			Equip = {
				Summon = true,
				Equip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_1,
				Equip2 = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_2,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.UNEQUIP,
				Idle = AnimationModule.Assets.Animations.WEAPONS.SWORD.IDLE.id
			},

			Model = {
				Right = {
					Weapon = { --game.ReplicatedStorage.Assets.Weapons.Unique.TestSpear,
						"SWRD_BLADE",
						"SWRD_GUARD",
						"SWRD_HANDLE",
						"SWRD_POMMEL"
					},

					Parent = "Torso",
					Position = Vector3.new(-1, -0.75, -1.25),
					Orientation = Vector3.new(-20, -180, -180)
				}
			}
        },

		Attack = {
            Speed =  0.85,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.3,
                    Duration = 0.5,

					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(9, 5, 8),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},

                [2] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(9, 5, 8),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id
				},

                [3] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(6, 5, 9),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id
				},

                [4] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(8, 5, 7),
					Offset = CFrame.new(0, 0, -4),

					Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.3,
				Duration = 0.5,

				Damage = 8,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 11),
				Offset = CFrame.new(0,0,-5),

				Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Sword.SwordService,
				Duration = 1.25,
				Windup = 0.55,
				Speed = 0.95,
				Cooldown = 6,

				Damage = 16,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 8),
				Offset = CFrame.new(0,0,-4),

				Animation = AnimationModule.Assets.Animations.WEAPONS.SWORD.CRITICAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id,
			}
		},
	},

	["Dagger"] = {
		General = {
			WeaponBlock = true,

			Parry = {
				ParryStart = AnimationModule.Assets.Animations.WEAPONS.DAGGER.PARRY_START,
				ParryImpact = AnimationModule.Assets.Animations.WEAPONS.DAGGER.PARRY
			},

			Block = {
				BlockHold = AnimationModule.Assets.Animations.WEAPONS.DAGGER.BLOCK_POSE,
				BlockImpact = AnimationModule.Assets.Animations.WEAPONS.DAGGER.BLOCK_IMPACT
			},

			Equip = {
				Summon = true,
				Equip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_1,
				Equip2 = AnimationModule.Assets.Animations.WEAPONS.EQUIP.EQUIP_2,
				Unequip = AnimationModule.Assets.Animations.WEAPONS.EQUIP.UNEQUIP,
				Idle = AnimationModule.Assets.Animations.WEAPONS.DAGGER.IDLE.id
			},

			Model = {
				Right = {
					Weapon = { --game.ReplicatedStorage.Assets.Weapons.Unique.TestSpear,
						"DGR_BLADE",
						"DGR_GUARD",
						"DGR_HANDLE",
						"DGR_POMMEL"
					},

					Parent = "Torso",
					Position = Vector3.new(-1, -0.75, -1),
					Orientation = Vector3.new(-35, -180, -180)
				}
			}
        },

		Attack = {
            Speed =  0.925,
            Cooldown = 1.5,
            ComboMax = 4,

			Combo = {
				[1] = { 
                    Windup = 0.3,
                    Duration = 0.45,

					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(7, 5, 5),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_1,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},

                [2] = {
                    Windup = 0.25,
                    Duration = 0.35,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(4, 5, 7),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_2,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id
				},

                [3] = {
                    Windup = 0.3,
                    Duration = 0.4,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 6),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_3,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id
				},

                [4] = {
                    Windup = 0.3,
                    Duration = 0.5,
                    
					Damage = 8,
					DamageType = "Slash",
					Hitbox = Vector3.new(5, 5, 6),
					Offset = CFrame.new(0, 0, -3),

					Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.SWING_4,
                    Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
				},
			},

            Aerial = {
				Windup = 0.35,
				Duration = 0.6,

				Damage = 8,
				DamageType = "Slash",
				Hitbox = Vector3.new(5, 5, 11),
				Offset = CFrame.new(0,0,-5),

				Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.AERIAL,
                Swing = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id
			},

			Critical = {
				Module = game.ServerScriptService.Services.Combat.Criticals.Dagger.DaggerService,
				Duration = 1.25,
				Windup = 0.6,
				Speed = 0.95,
				Cooldown = 6,

				Damage = 16,
				DamageType = "Slash",
				Hitbox = Vector3.new(8, 5, 6),
				Offset = CFrame.new(0,0,-3),

				Animation = AnimationModule.Assets.Animations.WEAPONS.DAGGER.CRITICAL,
                Swing_1 = SoundModule.Assets.Sounds.SFX.Blade_Swing1.id,
				Swing_2 = SoundModule.Assets.Sounds.SFX.Blade_Swing2.id,
				Swing_3 = SoundModule.Assets.Sounds.SFX.Blade_Swing3.id,
			}
		},
	},
}

return WeaponData