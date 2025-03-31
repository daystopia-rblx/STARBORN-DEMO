--[[ ObjectModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-03-31
]]
local ObjectModule = {}

function ObjectModule.GetObject(name: string)
    name = name:upper()

    if ObjectModule.Templates[name] then
        return ObjectModule.Templates[name]
    end

    for _, category in pairs(ObjectModule.Templates) do
        if category[name] then
            return category[name]
        end
    end

    return nil
end

ObjectModule.Categories = {
    FURNITURE = "Furniture",
    WEAPONS = "Weapons",
    CHECKPOINTS = "Checkpoints"
}

ObjectModule.CategoryGroups = {
    FURNITURE = {
        "SEATING"
    },
    WEAPONS = {
        "LIGHT_WEAPONS",
        "MEDIUM_WEAPONS",
        "HEAVY_WEAPONS"
    },
    CHECKPOINTS = {
        "BONFIRE",
        "BED"
    }
}

ObjectModule.Templates = {
    SEATING = {
        CHAIR = {
            defaults = { properties = { interaction = "seat" } },
            variants = {
                wooden = { name = "Wooden Chair", prefix = "Wooden", price = 10.00, description = "A basic wooden chair" },
            }
        }
    },

    LIGHT_WEAPONS = {
        FISTS = {
            defaults = { tool = "fists" },
            variants = {
                basic = { name = "Fighting Stance", description = "Basic hand-to-hand combat stance" }
            }
        },
        DAGGER = {
            defaults = { tool = "dagger" },
            variants = {
                iron = { name = "Iron Dagger", description = "Quick and deadly iron dagger" }
            }
        },
        GUN = {
            defaults = { tool = "gun" },
            variants = {
                pistol = { name = "Standard Pistol", description = "Reliable sidearm" }
            }
        },
        RAPIER = {
            defaults = { tool = "rapier" },
            variants = {
                steel = { name = "Steel Rapier", description = "Elegant thrusting sword" }
            }
        },
        NUNCHUCKS = {
            defaults = { tool = "nunchucks" },
            variants = {
                wooden = { name = "Wooden Nunchucks", description = "Traditional training weapon" }
            }
        },
        BOW = {
            defaults = { tool = "bow" },
            variants = {
                hunting = { name = "Hunting Bow", description = "Standard hunting bow" }
            }
        }
    },

    MEDIUM_WEAPONS = {
        LONGSWORD = {
            defaults = { tool = "longsword" },
            variants = {
                iron = { name = "Iron Longsword", description = "Versatile iron sword" }
            }
        },
        SPEAR = {
            defaults = { tool = "spear" },
            variants = {
                wooden = { name = "Wooden Spear", description = "Basic thrusting spear" }
            }
        },
        KATANA = {
            defaults = { tool = "katana" },
            variants = {
                steel = { name = "Steel Katana", description = "Sharp curved blade" }
            }
        },
        RIFLE = {
            defaults = { tool = "rifle" },
            variants = {
                hunting = { name = "Hunting Rifle", description = "Standard hunting rifle" }
            }
        },
        TRIDENT = {
            defaults = { tool = "trident" },
            variants = {
                iron = { name = "Iron Trident", description = "Three-pronged weapon" }
            }
        }
    },

    HEAVY_WEAPONS = {
        GREATAXE = {
            defaults = { tool = "greataxe" },
            variants = {
                iron = { name = "Iron Greataxe", description = "Heavy crushing weapon" }
            }
        },
        GREATSWORD = {
            defaults = { tool = "greatsword" },
            variants = {
                iron = { name = "Iron Greatsword", description = "Massive iron blade" }
            }
        },
        SCYTHE = {
            defaults = { tool = "scythe" },
            variants = {
                iron = { name = "Iron Scythe", description = "Curved harvesting blade" }
            }
        }
    },

    BONFIRE = {
        defaults = { properties = { interaction = "rest", checkpoint = true, heal_rate = 1.0 } },
        variants = {
            standard = { name = "Bonfire", description = "A place of respite. Rest here to restore health and set your spawn point." }
        }
    },
    BED = {
        defaults = { properties = { interaction = "rest", checkpoint = true, heal_rate = 1.5 } },
        variants = {
            standard = { name = "Bed", description = "A modest bed for resting. Rest here to restore health and set your spawn point." }
        }
    }
}

return ObjectModule