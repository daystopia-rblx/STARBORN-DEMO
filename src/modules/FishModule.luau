--[[ FishModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local FishModule = {}

function FishModule.GetFish(name: string)
    name = name:upper()
    if FishModule.Templates[name] then return FishModule.Templates[name] end
    for _, category in pairs(FishModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

function FishModule.GetRod(name: string)
    name = name:upper()
    if FishModule.Rods[name] then return FishModule.Rods[name] end
    return nil
end

function FishModule.GetSpot(name: string)
    name = name:upper()
    if FishModule.Spots[name] then return FishModule.Spots[name] end
    return nil
end

function FishModule.ValidateRod(rodId: string, spotId: string): boolean
    local rod = FishModule.GetRod(rodId)
    if not rod then return false end

    local spot = FishModule.GetSpot(spotId)
    if not spot then return true end

    if spot.defaults.specialRod and spot.defaults.specialRod ~= rodId then
        return false
    end

    if spot.defaults.requiresBoat and not rod.defaults.canUseFromBoat then
        return false
    end

    return true
end

--[[ Categories ]]
FishModule.Categories = {
    COMMON_FISH = "Common Fish",
    UNCOMMON_FISH = "Uncommon Fish",
    RARE_FISH = "Rare Fish",
    LEGENDARY_FISH = "Legendary Fish",
    FISHING_RODS = "Fishing Rods",
    FISHING_SPOTS = "Fishing Spots"
}

--[[ Rarities ]]
FishModule.Rarities = {
    COMMON = "common",
    UNCOMMON = "uncommon",
    RARE = "rare",
    LEGENDARY = "legendary"
}

--[[ Location Types ]]
FishModule.LocationTypes = {
    STANDARD = "standard",
    HIDDEN = "hidden",
    SPECIAL = "special",
    DEEP_SEA = "deep_sea"
}

--[[ Category Groups ]]
FishModule.CategoryGroups = {
    COMMON_FISH = {
        "SILVERSCALE",
        "SUNFIN",
        "RIVERTROUT",
        "PONDEEL"
    },
    UNCOMMON_FISH = {
        "GLIMMERSCALE",
        "AZUREWRASSE",
        "LUMINOUSREAM",
        "AMBERPERCH"
    },
    RARE_FISH = {
        "OPALSHINE",
        "JADESCALE",
        "STORMRIDER",
        "GOLDENRAY"
    },
    LEGENDARY_FISH = {
        "CRYSTALFIN",
        "TWILIGHTWHISPER",
        "DEEPWATCHER",
        "EMBERCOIL"
    },
    FISHING_RODS = {
        "APPRENTICE_ROD",
        "ANGLER_ROD",
        "EXPERT_ROD",
        "DEEPSEA_ROD"
    },
    FISHING_SPOTS = {
        "STANDARD_SPOTS",
        "HIDDEN_SPOTS",
        "SPECIAL_SPOTS",
        "DEEP_SPOTS"
    }
}

--[[ Templates ]]
FishModule.Templates = {
    COMMON_FISH = {
        SILVERSCALE = {
            defaults = {
                rarity = FishModule.Rarities.COMMON,
                value = 5,
                cookable = true,
                cookResult = "GRILLED_SILVERSCALE",
                tool = "food",
                duration = 30,
                useTime = 1.2,
                effects = { health = 3, stamina = 2 },
                materials = { scales = 1, meat = 2 }
            },
            variants = {
                standard = { name = "Silverscale", description = "A common fish found in most rivers" },
                spotted = { name = "Spotted Silverscale", description = "A variant with distinctive spotted pattern" }
            }
        },

        SUNFIN = {
            defaults = {
                rarity = FishModule.Rarities.COMMON,
                value = 3,
                cookable = true,
                cookResult = "GRILLED_SUNFIN",
                tool = "food",
                duration = 25,
                useTime = 1.0,
                effects = { health = 2, stamina = 2 },
                materials = { scales = 1, meat = 1 }
            },
            variants = {
                standard = { name = "Sunfin", description = "A small golden fish that thrives in shallow waters" }
            }
        },

        RIVERTROUT = {
            defaults = {
                rarity = FishModule.Rarities.COMMON,
                value = 7,
                cookable = true,
                cookResult = "GRILLED_TROUT",
                tool = "food",
                duration = 35,
                useTime = 1.3,
                effects = { health = 4, stamina = 3 },
                materials = { scales = 2, fins = 1, meat = 2 }
            },
            variants = {
                standard = { name = "River Trout", description = "A common trout with speckled skin" },
                brook = { name = "Brook Trout", description = "A smaller variant found in cold streams" }
            }
        },

        PONDEEL = {
            defaults = {
                rarity = FishModule.Rarities.COMMON,
                value = 8,
                cookable = true,
                cookResult = "GRILLED_EEL",
                tool = "food",
                duration = 40,
                useTime = 1.5,
                effects = { health = 5, stamina = 2 },
                materials = { skin = 1, meat = 3 }
            },
            variants = {
                standard = { name = "Pond Eel", description = "A slippery eel found in marshlands" },
                river = { name = "River Eel", description = "A variant adapted to flowing water" }
            }
        }
    },

    UNCOMMON_FISH = {
        GLIMMERSCALE = {
            defaults = {
                rarity = FishModule.Rarities.UNCOMMON,
                value = 15,
                cookable = true,
                cookResult = "MOONLIGHT_FILLET",
                tool = "food",
                duration = 60,
                useTime = 1.5,
                effects = { health = 7, stamina = 5, intelligence = 1 },
                materials = { scales = 3, fins = 1, meat = 3, moonessence = 1 }
            },
            variants = {
                standard = { name = "Glimmerscale", description = "A silvery fish that reflects moonlight beautifully" },
                full = { name = "Full Moon Glimmerscale", description = "Only appears during the full moon phase" }
            }
        },

        AZUREWRASSE = {
            defaults = {
                rarity = FishModule.Rarities.UNCOMMON,
                value = 18,
                cookable = true,
                cookResult = "AZURE_FILLET",
                tool = "food",
                duration = 65,
                useTime = 1.6,
                effects = { health = 8, stamina = 6 },
                materials = { scales = 4, meat = 5 }
            },
            variants = {
                standard = { name = "Azure Wrasse", description = "A substantial fish with a brilliant blue hue" },
                golden = { name = "Golden Azure Wrasse", description = "A rare variant with golden accents among the blue" }
            }
        },

        LUMINOUSREAM = {
            defaults = {
                rarity = FishModule.Rarities.UNCOMMON,
                value = 20,
                cookable = true,
                cookResult = "GLOWING_SOUP",
                tool = "food",
                duration = 70,
                useTime = 1.7,
                effects = { health = 8, stamina = 7, magic = 5 },
                materials = { scales = 3, fins = 2, meat = 4, lightessence = 2 }
            },
            variants = {
                standard = { name = "Luminous Bream", description = "A fish with bioluminescent patterns that glow in darkness" },
                deep = { name = "Deep Luminous Bream", description = "A variant found in deeper waters with brighter glow patterns" }
            }
        },

        AMBERPERCH = {
            defaults = {
                rarity = FishModule.Rarities.UNCOMMON,
                value = 22,
                cookable = true,
                cookResult = "AMBER_STEW",
                tool = "food",
                duration = 75,
                useTime = 1.8,
                effects = { health = 9, stamina = 8, strength = 1 },
                materials = { scales = 5, fins = 1, meat = 6 }
            },
            variants = {
                standard = { name = "Amber Perch", description = "A fish with striking amber coloration" },
                fire = { name = "Fire Amber Perch", description = "A variant with deeper red tones, found in volcanic lakes" }
            }
        }
    },

    RARE_FISH = {
        OPALSHINE = {
            defaults = {
                rarity = FishModule.Rarities.RARE,
                value = 45,
                cookable = true,
                cookResult = "CHARGED_FILLET",
                tool = "food",
                duration = 120,
                useTime = 2.0,
                effects = { health = 15, stamina = 12, magic = 10 },
                materials = { scales = 5, fins = 3, meat = 6, stormessence = 2 }
            },
            variants = {
                standard = { name = "Opalshine", description = "A fish that generates small electrical charges" },
                storm = { name = "Storm Opalshine", description = "Found during thunderstorms, produces stronger electrical charges" }
            }
        },


        JADESCALE = {
            defaults = {
                rarity = FishModule.Rarities.RARE,
                value = 50,
                cookable = true,
                cookResult = "ROYAL_FEAST",
                tool = "food",
                duration = 150,
                useTime = 2.5,
                effects = { health = 20, stamina = 15, strength = 3 },
                materials = { scales = 6, fins = 2, meat = 8 }
            },
            variants = {
                standard = { name = "Jadescale", description = "A majestic fish with jade-like scales" },
                crowned = { name = "Crowned Jadescale", description = "A variant with a distinctive crown-like dorsal fin" }
            }
        },


        STORMRIDER = {
            defaults = {
                rarity = FishModule.Rarities.RARE,
                value = 55,
                cookable = true,
                cookResult = "LIGHTNING_STEW",
                tool = "food",
                duration = 180,
                useTime = 2.2,
                effects = { health = 18, stamina = 16, lightning_resist = 15 },
                materials = { scales = 5, fins = 4, meat = 7, stormessence = 3 }
            },
            variants = {
                standard = { name = "Stormrider", description = "A fish that follows storm fronts and lightning strikes" }
            }
        },

        GOLDENRAY = {
            defaults = {
                rarity = FishModule.Rarities.RARE,
                value = 60,
                cookable = true,
                cookResult = "SUNLIGHT_SOUP",
                tool = "food",
                duration = 200, 
                useTime = 2.3,
                effects = { health = 22, stamina = 18, fire_resist = 15 },
                materials = { goldscales = 4, fins = 3, meat = 7, sunessence = 2 }
            },
            variants = {
                standard = { name = "Golden Ray", description = "A rare fish with scales that shine like pure gold" }
            }
        }
    },

    LEGENDARY_FISH = {
        CRYSTALFIN = {
            defaults = {
                rarity = FishModule.Rarities.LEGENDARY,
                value = 200,
                cookable = true,
                cookResult = "CRYSTAL_ELIXIR",
                tool = "food",
                duration = 300,
                useTime = 3.0,
                effects = { health = 30, stamina = 25, magic = 15, intelligence = 5 },
                materials = { crystalscales = 6, fins = 4, meat = 8, crystalessence = 3 }
            },
            variants = {
                standard = { name = "Crystalfin", description = "A fish with crystalline fins that refract light like prisms" }
            }
        },

        TWILIGHTWHISPER = {
            defaults = {
                rarity = FishModule.Rarities.LEGENDARY,
                value = 250,
                cookable = true,
                cookResult = "TWILIGHT_FEAST",
                tool = "food",
                duration = 400,
                useTime = 3.5,
                effects = { health = 35, stamina = 30, magic = 20, health_regen = 3 },
                materials = { shadowscales = 7, fins = 5, meat = 10, voidessence = 4 }
            },
            variants = {
                standard = { name = "Twilight Whisper", description = "A mysterious fish that can only be caught during the transition between day and night" }
            }
        },

        DEEPWATCHER = {
            defaults = {
                rarity = FishModule.Rarities.LEGENDARY,
                value = 300,
                cookable = true,
                cookResult = "ABYSSAL_STEW",
                tool = "food",
                duration = 500,
                useTime = 4.0,
                effects = { health = 40, stamina = 35, strength = 10, water_breathing = 300 },
                materials = { abyssalscales = 8, fins = 6, meat = 12, abyssalessence = 5 }
            },
            variants = {
                standard = { name = "Deep Watcher", description = "A massive fish from the deepest ocean trenches with glowing eyes adapted to darkness" }
            }
        },

        EMBERCOIL = {
            defaults = {
                rarity = FishModule.Rarities.LEGENDARY,
                value = 350,
                cookable = true,
                cookResult = "DRAGON_SOUP",
                tool = "food",
                duration = 600,
                useTime = 4.5,
                effects = { health = 50, stamina = 45, strength = 15, fire_resist = 40 },
                materials = { emberscales = 10, fins = 6, meat = 15, dragonessence = 2 }
            },
            variants = {
                standard = { name = "Ember Coil", description = "A serpentine fish with scales that burn like embers, rumored to be related to dragons" }
            }
        }
    }
}

--[[ Fishing Rods ]]
FishModule.Rods = {
    APPRENTICE_ROD = {
        defaults = {
            power = 1,
            range = 20,
            rarity = FishModule.Rarities.COMMON,
            canUseFromBoat = false,
            durability = 100,
            catchRate = {
                [FishModule.Rarities.COMMON] = 0.6,
                [FishModule.Rarities.UNCOMMON] = 0.3,
                [FishModule.Rarities.RARE] = 0.08,
                [FishModule.Rarities.LEGENDARY] = 0.02
            }
        },
        variants = {
            standard = { name = "Apprentice Fishing Rod", description = "A basic fishing rod for beginners" }
        }
    },

    ANGLER_ROD = {
        defaults = {
            power = 2,
            range = 30,
            rarity = FishModule.Rarities.UNCOMMON,
            canUseFromBoat = true,
            durability = 150,
            catchRate = {
                [FishModule.Rarities.COMMON] = 0.4,
                [FishModule.Rarities.UNCOMMON] = 0.4,
                [FishModule.Rarities.RARE] = 0.15,
                [FishModule.Rarities.LEGENDARY] = 0.05
            }
        },
        variants = {
            standard = { name = "Angler's Rod", description = "A quality fishing rod for experienced fishers" }
        }
    },

    EXPERT_ROD = {
        defaults = {
            power = 3,
            range = 40,
            rarity = FishModule.Rarities.RARE,
            canUseFromBoat = true,
            durability = 200,
            catchRate = {
                [FishModule.Rarities.COMMON] = 0.2,
                [FishModule.Rarities.UNCOMMON] = 0.4,
                [FishModule.Rarities.RARE] = 0.3,
                [FishModule.Rarities.LEGENDARY] = 0.1
            }
        },
        variants = {
            standard = { name = "Expert Fishing Rod", description = "A professional-grade fishing rod for master anglers" }
        }
    },

    DEEPSEA_ROD = {
        defaults = {
            power = 4,
            range = 60,
            rarity = FishModule.Rarities.LEGENDARY,
            canUseFromBoat = true,
            durability = 300,
            catchRate = {
                [FishModule.Rarities.COMMON] = 0.1,
                [FishModule.Rarities.UNCOMMON] = 0.2,
                [FishModule.Rarities.RARE] = 0.4,
                [FishModule.Rarities.LEGENDARY] = 0.3
            }
        },
        variants = {
            standard = { name = "Deep Sea Rod", description = "A specialized rod designed for the deepest waters and largest catches" }
        }
    }
}

--[[ Fishing Spots ]]
FishModule.Spots = {
    RIVERBANK = {
        defaults = {
            position = Vector3.new(100, 5, 200), radius = 10, type = FishModule.LocationTypes.STANDARD,
            fishPool = {
                {id = "SILVERSCALE", weight = 300, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "SUNFIN", weight = 300, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "RIVERTROUT", weight = 200, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "PONDEEL", weight = 150, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "GLIMMERSCALE", weight = 40, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "AZUREWRASSE", weight = 10, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Riverbank", description = "A calm spot along the river" },
            rapids = { name = "River Rapids", description = "A more challenging spot with flowing water" }
        }
    },

    LAKESHORE = {
        defaults = {
            position = Vector3.new(300, 5, 400), radius = 15, type = FishModule.LocationTypes.STANDARD,
            fishPool = {
                {id = "SILVERSCALE", weight = 250, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "RIVERTROUT", weight = 250, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "PONDEEL", weight = 200, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "GLIMMERSCALE", weight = 150, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "AZUREWRASSE", weight = 100, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "LUMINOUSREAM", weight = 50, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Lake Shore", description = "The edge of a large lake" },
            rocky = { name = "Rocky Shore", description = "A rocky area of the lake with deeper water" }
        }
    },

    HIDDENCOVE = {
        defaults = {
            position = Vector3.new(500, 5, 700), radius = 8, type = FishModule.LocationTypes.HIDDEN,
            fishPool = {
                {id = "RIVERTROUT", weight = 100, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
                {id = "GLIMMERSCALE", weight = 250, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "LUMINOUSREAM", weight = 250, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "AMBERPERCH", weight = 200, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "OPALSHINE", weight = 150, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "JADESCALE", weight = 50, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Hidden Cove", description = "A secluded cove with clear waters" }
        }
    },

    CRYSTALPOOL = {
        defaults = {
            position = Vector3.new(800, 10, 600), radius = 6, type = FishModule.LocationTypes.HIDDEN,
            fishPool = {
                {id = "LUMINOUSREAM", weight = 300, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "AMBERPERCH", weight = 300, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "GOLDENRAY", weight = 300, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "STORMRIDER", weight = 90, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "TWILIGHTWHISPER", weight = 10, rarity = FishModule.Rarities.LEGENDARY, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Crystal Pool", description = "A pool with unusually clear water that sparkles in the light" }
        }
    },

    STORMBASIN = {
        defaults = {
            position = Vector3.new(400, 5, 900), radius = 12, type = FishModule.LocationTypes.SPECIAL,
            weatherRestriction = { Thunderstorm = true, Rain = true, Cloudy = false, Clear = false },
            fishPool = {
                {id = "OPALSHINE", weight = 400, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "STORMRIDER", weight = 300, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "JADESCALE", weight = 200, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "DEEPWATCHER", weight = 100, rarity = FishModule.Rarities.LEGENDARY, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Storm Basin", description = "A basin that attracts unusual fish during storms" }
        }
    },

    MOONLIGHTBAY = {
        defaults = {
            position = Vector3.new(1000, 5, 1000), radius = 20, type = FishModule.LocationTypes.SPECIAL,
            timeRestriction = { start = 20, finish = 4 },
            fishPool = {
                {id = "GLIMMERSCALE", weight = 300, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "LUMINOUSREAM", weight = 300, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}},
                {id = "STORMRIDER", weight = 250, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "CRYSTALFIN", weight = 150, rarity = FishModule.Rarities.LEGENDARY, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Moonlight Bay", description = "A bay where rare fish appear under the moonlight" }
        }
    },

    ABYSSALTRENCH = {
        defaults = {
            position = Vector3.new(1500, -100, 1500), radius = 30, type = FishModule.LocationTypes.DEEP_SEA,
            requiresBoat = true, specialRod = "DEEPSEA_ROD",
            fishPool = {
                {id = "OPALSHINE", weight = 200, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "STORMRIDER", weight = 300, rarity = FishModule.Rarities.RARE, quantity = {min = 1, max = 1}},
                {id = "EMBERCOIL", weight = 300, rarity = FishModule.Rarities.LEGENDARY, quantity = {min = 1, max = 1}},
                {id = "DEEPWATCHER", weight = 200, rarity = FishModule.Rarities.LEGENDARY, quantity = {min = 1, max = 1}}
            }
        },
        variants = {
            standard = { name = "Abyssal Trench", description = "A deep underwater trench where legendary creatures lurk" }
        }
    }
}

FishModule.DefaultPool = {
    {id = "SILVERSCALE", weight = 400, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
    {id = "SUNFIN", weight = 300, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
    {id = "RIVERTROUT", weight = 200, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
    {id = "PONDEEL", weight = 80, rarity = FishModule.Rarities.COMMON, quantity = {min = 1, max = 1}},
    {id = "GLIMMERSCALE", weight = 20, rarity = FishModule.Rarities.UNCOMMON, quantity = {min = 1, max = 1}}
}

return FishModule