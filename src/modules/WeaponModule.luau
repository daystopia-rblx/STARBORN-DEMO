--[[ WeaponModule
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-11
]]
local WeaponModule = {}

function WeaponModule.GetWeapon(name: string)
    name = name:upper()
    if WeaponModule.Templates[name] then return WeaponModule.Templates[name] end
    for _, category in pairs(WeaponModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

WeaponModule.Categories = {
    LIGHT_WEAPONS = "Light Weapons",
    MEDIUM_WEAPONS = "Medium Weapons",
    HEAVY_WEAPONS = "Heavy Weapons"
}

WeaponModule.CategoryGroups = {
    LIGHT_WEAPONS = {
        "FISTS",
        "DAGGER",
        "GUN",
        "RAPIER",
        "NUNCHUCKS",
        "BOW"
    },
    MEDIUM_WEAPONS = {
        "LONGSWORD",
        "SPEAR",
        "KATANA",
        "RIFLE",
        "TRIDENT"
    },
    HEAVY_WEAPONS = {
        "GREATAXE",
        "GREATSWORD",
        "SCYTHE"
    }
}

WeaponModule.Templates = {
    LIGHT_WEAPONS = {
        FISTS = {
            defaults = {
                tool = "fists", damage = 5, speed = 1.5,
                hitboxes = {
                    { name = "jab", damage = 5, range = 3, angle = 45 },
                    { name = "cross", damage = 7, range = 3.5, angle = 30 },
                    { name = "hook", damage = 6, range = 3.2, angle = 60 },
                    { name = "uppercut", damage = 8, range = 2.8, angle = 20 }
                }
            },
            variants = {
                basic = { name = "Fighting Stance", description = "Basic hand-to-hand combat stance" },
                leather = { name = "Leather Gloves", description = "Basic leather fighting gloves" }
            }
        },
        DAGGER = {
            defaults = {
                tool = "dagger", damage = 8, speed = 1.8,
                hitboxes = {
                    { name = "stab", damage = 8, range = 2.5, angle = 15 },
                    { name = "slash", damage = 6, range = 2.8, angle = 45 },
                    { name = "backstab", damage = 12, range = 2, angle = 10 }
                }
            },
            variants = {
                iron = { name = "Iron Dagger", description = "Quick and deadly iron dagger" },
                steel = { name = "Steel Dagger", description = "Superior quality steel dagger", damage = 10 },
                ceremonial = { name = "Ceremonial Dagger", description = "An ornate dagger used in religious ceremonies", damage = 10, rarity = "UNCOMMON", hitboxes = {
                    { name = "ritual", damage = 14, range = 2, angle = 10 }
                }}
            }
        },
        GUN = {
            defaults = {
                tool = "gun", damage = 15, speed = 1.2,
                hitboxes = {
                    { name = "shot", damage = 15, range = 50, angle = 5 }
                }
            },
            variants = {
                pistol = { name = "Standard Pistol", description = "Reliable sidearm" }
            }
        },
        RAPIER = {
            defaults = {
                tool = "rapier", damage = 10, speed = 1.6,
                hitboxes = {
                    { name = "thrust", damage = 10, range = 4, angle = 10 },
                    { name = "feint", damage = 8, range = 3.5, angle = 20 },
                    { name = "lunge", damage = 12, range = 5, angle = 5 }
                }
            },
            variants = {
                steel = { name = "Steel Rapier", description = "Elegant thrusting sword" }
            }
        },
        NUNCHUCKS = {
            defaults = {
                tool = "nunchucks", damage = 7, speed = 1.9,
                hitboxes = {
                    { name = "swing", damage = 7, range = 3.5, angle = 90 },
                    { name = "spin", damage = 6, range = 4, angle = 360 },
                    { name = "combo", damage = 8, range = 3, angle = 120 }
                }
            },
            variants = {
                wooden = { name = "Wooden Nunchucks", description = "Traditional training weapon" }
            }
        },
        BOW = {
            defaults = {
                tool = "bow", damage = 12, speed = 1.0,
                hitboxes = {
                    { name = "arrow", damage = 12, range = 40, angle = 3 }
                }
            },
            variants = {
                hunting = { name = "Hunting Bow", description = "Standard hunting bow" }
            }
        }
    },

    MEDIUM_WEAPONS = {
        LONGSWORD = {
            defaults = {
                tool = "longsword", damage = 15, speed = 1.2,
                hitboxes = {
                    { name = "slash", damage = 15, range = 4.5, angle = 60 },
                    { name = "overhead", damage = 18, range = 4, angle = 30 },
                    { name = "thrust", damage = 12, range = 5, angle = 15 }
                }
            },
            variants = {
                iron = { name = "Iron Longsword", description = "Versatile iron sword" },
                steel = { name = "Steel Longsword", description = "Superior quality steel sword", damage = 18 }
            }
        },
        SPEAR = {
            defaults = {
                tool = "spear", damage = 14, speed = 1.3,
                hitboxes = {
                    { name = "thrust", damage = 14, range = 6, angle = 10 },
                    { name = "sweep", damage = 10, range = 4, angle = 90 },
                    { name = "overhead", damage = 16, range = 5, angle = 20 }
                }
            },
            variants = {
                wooden = { name = "Wooden Spear", description = "Basic thrusting spear" }
            }
        },
        KATANA = {
            defaults = {
                tool = "katana", damage = 16, speed = 1.4,
                hitboxes = {
                    { name = "slash", damage = 16, range = 4, angle = 70 },
                    { name = "draw", damage = 20, range = 3.5, angle = 40 },
                    { name = "combo", damage = 14, range = 4.2, angle = 90 }
                }
            },
            variants = {
                steel = { name = "Steel Katana", description = "Sharp curved blade" }
            }
        },
        RIFLE = {
            defaults = {
                tool = "rifle", damage = 20, speed = 0.8,
                hitboxes = {
                    { name = "shot", damage = 20, range = 60, angle = 3 }
                }
            },
            variants = {
                hunting = { name = "Hunting Rifle", description = "Standard hunting rifle" }
            }
        },
        TRIDENT = {
            defaults = {
                tool = "trident", damage = 13, speed = 1.1,
                hitboxes = {
                    { name = "thrust", damage = 13, range = 5, angle = 15 },
                    { name = "sweep", damage = 10, range = 4.5, angle = 80 },
                    { name = "combo", damage = 15, range = 4, angle = 60 }
                }
            },
            variants = {
                iron = { name = "Iron Trident", description = "Three-pronged weapon" }
            }
        }
    },

    HEAVY_WEAPONS = {
        GREATAXE = {
            defaults = {
                tool = "greataxe", damage = 25, speed = 0.7,
                hitboxes = {
                    { name = "chop", damage = 25, range = 4, angle = 45 },
                    { name = "sweep", damage = 20, range = 5, angle = 90 },
                    { name = "overhead", damage = 30, range = 3.5, angle = 30 }
                }
            },
            variants = {
                iron = { name = "Iron Greataxe", description = "Heavy crushing weapon" }
            }
        },
        GREATSWORD = {
            defaults = {
                tool = "greatsword", damage = 22, speed = 0.8,
                hitboxes = {
                    { name = "slash", damage = 22, range = 5, angle = 70 },
                    { name = "overhead", damage = 25, range = 4, angle = 40 },
                    { name = "spin", damage = 20, range = 5.5, angle = 360 }
                }
            },
            variants = {
                iron = { name = "Iron Greatsword", description = "Massive iron blade" }
            }
        },
        SCYTHE = {
            defaults = {
                tool = "scythe", damage = 20, speed = 0.9,
                hitboxes = {
                    { name = "slash", damage = 20, range = 5.5, angle = 80 },
                    { name = "sweep", damage = 18, range = 6, angle = 120 },
                    { name = "combo", damage = 22, range = 5, angle = 100 }
                }
            },
            variants = {
                iron = { name = "Iron Scythe", description = "Curved harvesting blade" }
            }
        }
    }
}

return WeaponModule