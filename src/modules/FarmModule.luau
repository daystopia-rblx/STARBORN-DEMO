--[[ FarmModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local FarmModule = {}

function FarmModule.GetCrop(name: string)
    name = name:upper()
    if FarmModule.Templates[name] then return FarmModule.Templates[name] end
    for _, category in pairs(FarmModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

function FarmModule.GetTool(name: string)
    name = name:upper()
    if FarmModule.Tools[name] then return FarmModule.Tools[name] end
    return nil
end

function FarmModule.GetPlot(name: string)
    name = name:upper()
    if FarmModule.Plots[name] then return FarmModule.Plots[name] end
    return nil
end

function FarmModule.ValidateTool(toolId: string, cropId: string): boolean
    local tool = FarmModule.GetTool(toolId)
    if not tool then return false end

    local crop = FarmModule.GetCrop(cropId)
    if not crop then return true end

    if crop.defaults.specialTool and crop.defaults.specialTool ~= toolId then
        return false
    end

    return true
end

--[[ Categories ]]
FarmModule.Categories = {
    FAST_CROPS = "Fast Crops",
    MEDIUM_CROPS = "Medium Crops",
    SLOW_CROPS = "Slow Crops",
    SPECIAL_CROPS = "Special Crops",
    FARMING_TOOLS = "Farming Tools",
    FARM_PLOTS = "Farm Plots"
}

--[[ Growth Speeds ]]
FarmModule.GrowthSpeeds = {
    FAST = "fast",
    MEDIUM = "medium",
    SLOW = "slow",
    SPECIAL = "special"
}

--[[ Location Types ]]
FarmModule.LocationTypes = {
    HOME = "home",
    COMMUNITY = "community",
    PREMIUM = "premium",
    SPECIAL = "special",
    WILD = "wild"
}

--[[ Crop Seasons ]]
FarmModule.Seasons = {
    SPRING = "spring",
    SUMMER = "summer",
    FALL = "fall",
    WINTER = "winter",
    ALL = "all"
}

--[[ Category Groups ]]
FarmModule.CategoryGroups = {
    FAST_CROPS = {
        "LETTUCE"
    },
    FARMING_TOOLS = {
        "HOE",
        "WATERING_CAN",
        "SCYTHE",
        "FERTILIZER"
    },
    FARM_PLOTS = {
        "HOME_PLOTS"
    }
}

--[[ Templates ]]
FarmModule.Templates = {
    FAST_CROPS = {
        LETTUCE = {
            defaults = {
                growthSpeed = FarmModule.GrowthSpeeds.FAST, value = 5, waterNeeds = 1, growthDays = 1, seedsProduced = {min = 0, max = 2},
                seasons = {FarmModule.Seasons.SPRING, FarmModule.Seasons.FALL}, effects = {health = 2}, materials = {leaf = 1}
            },
            variants = {
                standard = {name = "Lettuce", description = "A leafy green vegetable that grows quickly"}
            }
        }
    }
}

--[[ Farming Tools ]]
FarmModule.Tools = {
    BASIC_SOW = {
        defaults = {power = 1, durability = 100, range = 1, soilQualityBonus = 0, workSpeed = 1, toolFunction = "till"},
        variants = {standard = {name = "Basic Sow", description = "A simple tool for preparing soil"}}
    },
    BASIC_WATERING_CAN = {
        defaults = {capacity = 5, range = 1, durability = 100, waterQuality = 1, refillSpeed = 1, toolFunction = "water"},
        variants = {standard = {name = "Basic Watering Can", description = "A simple can for watering crops"}}
    },
    BASIC_SCYTHE = {
        defaults = {power = 1, durability = 100, range = 1, harvestBonus = 0, workSpeed = 1, toolFunction = "harvest"},
        variants = {standard = {name = "Basic Scythe", description = "A simple scythe for harvesting crops"}}
    },
    BASIC_FERTILIZER = {
        defaults = {potency = 1, range = 1, growthBonus = 0.1, yieldBonus = 0, qualityBonus = 0, toolFunction = "fertilize"},
        variants = {standard = {name = "Basic Fertilizer", description = "A simple fertilizer that slightly speeds crop growth"}}
    }
}

--[[ Farm Plots ]]
FarmModule.Plots = {
    HOME_GARDEN = {
        defaults = {type = FarmModule.LocationTypes.HOME, soilQuality = 1, waterRetention = 1, growthMultiplier = 1, maxCrops = 9},
        variants = {standard = {name = "Home Garden", description = "A small plot of land near your home for growing crops"}}
    }
}

return FarmModule