--[[ FarmingService
    Manages farming activities including tilling, planting, watering, fertilizing, and harvesting.
    Handles crop growth cycles, soil quality, and tool interactions for the farming system.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local FarmingService = {}

--[[ Dependencies ]]
FarmingService.Dependencies = {
    "Event",
    "Object",
    "Tool",
    "Time",
    "Inventory"
}

--[[ Modules ]]
FarmingService.Modules = {
    "Farm",
    "Action",
    "Zone"
}

--[[ Events ]]
FarmingService.Events = {
    Till = true,
    Plant = true,
    Water = true,
    Fertilize = true,
    Harvest = true,
    Grow = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ State ]]
local state = {
    plots = {},
    crops = {},
    growthTasks = {}
}

--[[ Constants ]]
local GROWTH_CHECK_INTERVAL = 300
local WATER_DECAY_RATE = 0.1
local GROWTH_STAGES = {
    SEED = 1,
    SPROUT = 2,
    GROWING = 3,
    MATURE = 4,
    HARVESTABLE = 5,
    WITHERED = 6
}

local TIME_CONSTANTS = {
    WITHERING_DAYS = 2,
    WATERING_BONUS_DAYS = 1,
    FERTILIZER_BONUS_DAYS = 2
}

--[[ Listeners ]]
FarmingService.Listeners = {
    ["Time.Update"] = function(self, timeData)
        if timeData and timeData.hour ~= nil then
            self:UpdateMoisture()
        end
    end
}

--[[ Core Functions ]]
function FarmingService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function FarmingService:Start()
    task.spawn(function()
        GROWTH_CHECK_INTERVAL = Services.Time:GetCycle() * 0.375

        while true do
            self:CheckCrops()
            task.wait(GROWTH_CHECK_INTERVAL)
        end
    end)
    return true
end

--[[ Getter Functions ]]
function FarmingService:GetPlots(plotId)
    return state.plots[plotId]
end

function FarmingService:GetCrops(cropId)
    return state.crops[cropId]
end

--[[ Crop Management ]]
local function CalculateGrowth(cropTemplate, plotQuality, season)
    local baseTime = cropTemplate.defaults.growthDays
    local qualityMultiplier = 1 - (plotQuality - 1) * 0.1

    local seasonMultiplier = 1
    if cropTemplate.defaults.seasons then
        local currentSeason = season or "spring"
        local isPreferredSeason = false

        for _, preferredSeason in ipairs(cropTemplate.defaults.seasons) do
            if preferredSeason:lower() == currentSeason:lower() then
                isPreferredSeason = true
                break
            end
        end

        seasonMultiplier = isPreferredSeason and 1 or 1.5
    end

    return baseTime * qualityMultiplier * seasonMultiplier
end

local function ScheduleGrowth(cropId, nextUpdateTime)
    if state.growthTasks[cropId] then
        task.cancel(state.growthTasks[cropId])
    end

    state.growthTasks[cropId] = task.delay(nextUpdateTime, function()
        FarmingService:UpdateGrowth(cropId)
        state.growthTasks[cropId] = nil
    end)
end

function FarmingService:UpdateGrowth(cropId)
    local cropData = state.crops[cropId]
    if not cropData then return end

    local plot = state.plots[cropData.plotId]
    if not plot then
        state.crops[cropId] = nil
        return
    end

    local cropTemplate = Modules.Farm.GetCrop(cropData.type)
    if not cropTemplate then
        state.crops[cropId] = nil
        plot.crops[tostring(cropData.position)] = nil
        return
    end

    local currentTime = os.time()
    local lastWateredTime = cropData.lastWatered or cropData.planted
    local cycleDuration = Services.Time:GetCycle()
    local gameTimeSinceWatered = (currentTime - lastWateredTime) / cycleDuration

    if gameTimeSinceWatered > TIME_CONSTANTS.WITHERING_DAYS then
        cropData.stage = GROWTH_STAGES.WITHERED

        Services.Event:Fire("Farm.Grow", {
            cropId = cropId,
            plotId = cropData.plotId,
            position = cropData.position,
            newStage = cropData.stage,
            isWithered = true
        })

        return
    end

    if cropData.stage < GROWTH_STAGES.HARVESTABLE then
        cropData.stage = cropData.stage + 1

        local currentSeason = Services.Time:GetSeason()
        local totalGrowthDays = CalculateGrowth(cropTemplate, plot.quality, currentSeason)
        local nextUpdateTime = (totalGrowthDays * cycleDuration) / (GROWTH_STAGES.HARVESTABLE - 1)

        if cropData.lastWatered and (currentTime - cropData.lastWatered) < TIME_CONSTANTS.WATERING_BONUS_DAYS * cycleDuration then
            nextUpdateTime = nextUpdateTime * 0.8
        end

        if cropData.lastFertilized and (currentTime - cropData.lastFertilized) < TIME_CONSTANTS.FERTILIZER_BONUS_DAYS * cycleDuration then
            nextUpdateTime = nextUpdateTime * 0.7
        end

        if cropData.stage < GROWTH_STAGES.HARVESTABLE then
            ScheduleGrowth(cropId, nextUpdateTime)
        end

        Services.Event:Fire("Farm.Grow", {
            cropId = cropId,
            plotId = cropData.plotId,
            position = cropData.position,
            newStage = cropData.stage,
            nextUpdate = cropData.stage < GROWTH_STAGES.HARVESTABLE and nextUpdateTime or nil
        })
    end
end

function FarmingService:CheckCrops()
    for cropId, cropData in pairs(state.crops) do
        if cropData.stage < GROWTH_STAGES.HARVESTABLE and cropData.stage ~= GROWTH_STAGES.WITHERED then
            self:UpdateGrowth(cropId)
        end
    end
end

function FarmingService:UpdateMoisture()
    local currentTime = os.time()

    for plotId, plotData in pairs(state.plots) do
        local decayAmount = WATER_DECAY_RATE / plotData.moisture
        plotData.moisture = math.max(plotData.moisture - decayAmount, 0.1)
    end
end

--[[ Farming Functions ]]
function FarmingService:TillPlot(playerId, plotId, position, toolId)
    local plot = state.plots[plotId]
    if not plot then
        return false, "Plot not found"
    end

    local posKey = tostring(position)
    if plot.tilled and plot.tilled[posKey] then
        return false, "Plot already tilled"
    end

    local tool = Modules.Farm.GetTool(toolId)
    if not tool or tool.defaults.toolFunction ~= "till" then
        return false, "Invalid tilling tool"
    end

    plot.tilled = plot.tilled or {}

    plot.tilled[posKey] = {
        quality = plot.soilQuality + (tool.defaults.soilQualityBonus or 0),
        tilledAt = os.time()
    }

    Services.Event:Fire("Farm.Till", {
        playerId = playerId,
        plotId = plotId,
        position = position,
        quality = plot.tilled[posKey].quality
    })

    return true
end

function FarmingService:PlantCrop(playerId, plotId, position, seedId)
    local plot = state.plots[plotId]
    if not plot then
        return false, "Plot not found"
    end

    local posKey = tostring(position)
    if not plot.tilled or not plot.tilled[posKey] then
        return false, "Plot not tilled"
    end

    if plot.crops and plot.crops[posKey] then
        return false, "Plot already has a crop"
    end

    local cropTemplate = Modules.Farm.GetCrop(seedId)
    if not cropTemplate then
        return false, "Invalid seed"
    end

    local currentSeason = Services.Time:GetSeason()
    local isValidSeason = false

    if cropTemplate.defaults.seasons then
        for _, season in ipairs(cropTemplate.defaults.seasons) do
            if season:lower() == currentSeason:lower() or season:lower() == "all" then
                isValidSeason = true
                break
            end
        end

        if not isValidSeason then
            return false, "Cannot plant this crop in current season"
        end
    end

    local cropId = plotId .. "_" .. posKey .. "_" .. os.time()

    plot.crops = plot.crops or {}

    local cropData = {
        id = cropId,
        type = seedId,
        plotId = plotId,
        position = position,
        stage = GROWTH_STAGES.SEED,
        planted = os.time(),
        quality = plot.tilled[posKey].quality
    }

    state.crops[cropId] = cropData
    plot.crops[posKey] = cropId

    local growthDays = CalculateGrowth(cropTemplate, plot.tilled[posKey].quality, currentSeason)
    local cycleDuration = Services.Time:GetCycle()
    local nextUpdateTime = (growthDays * cycleDuration) / (GROWTH_STAGES.HARVESTABLE - 1)
    ScheduleGrowth(cropId, nextUpdateTime)

    Services.Event:Fire("Farm.Plant", {
        playerId = playerId,
        plotId = plotId,
        position = position,
        cropId = cropId,
        cropType = seedId,
        nextUpdate = nextUpdateTime
    })

    return true, cropId
end

function FarmingService:WaterCrop(playerId, plotId, position, toolId)
    local plot = state.plots[plotId]
    if not plot then
        return false, "Plot not found"
    end

    local posKey = tostring(position)
    if not plot.crops or not plot.crops[posKey] then
        return false, "No crop to water"
    end

    local tool = Modules.Farm.GetTool(toolId)
    if not tool or tool.defaults.toolFunction ~= "water" then
        return false, "Invalid watering tool"
    end

    local cropId = plot.crops[posKey]
    local cropData = state.crops[cropId]
    if not cropData then
        return false, "Crop data not found"
    end

    if cropData.stage == GROWTH_STAGES.WITHERED then
        return false, "Crop is withered"
    end

    cropData.lastWatered = os.time()
    cropData.waterQuality = tool.defaults.waterQuality or 1

    plot.moisture = math.min((plot.moisture or 1) + tool.defaults.waterQuality, 10)

    if cropData.stage < GROWTH_STAGES.HARVESTABLE then
        local cropTemplate = Modules.Farm.GetCrop(cropData.type)
        if cropTemplate then
            local currentSeason = Services.Time:GetSeason()
            local growthDays = CalculateGrowth(cropTemplate, cropData.quality, currentSeason)
            local cycleDuration = Services.Time:GetCycle()
            local nextUpdateTime = (growthDays * cycleDuration * 0.8) / (GROWTH_STAGES.HARVESTABLE - cropData.stage)
            ScheduleGrowth(cropId, nextUpdateTime)
        end
    end

    Services.Event:Fire("Farm.Water", {
        playerId = playerId,
        plotId = plotId,
        position = position,
        cropId = cropId,
        moisture = plot.moisture
    })

    return true
end

function FarmingService:FertilizeCrop(playerId, plotId, position, fertilizerId)
    local plot = state.plots[plotId]
    if not plot then
        return false, "Plot not found"
    end

    local posKey = tostring(position)
    if not plot.crops or not plot.crops[posKey] then
        return false, "No crop to fertilize"
    end

    local fertilizer = Modules.Farm.GetTool(fertilizerId)
    if not fertilizer or fertilizer.defaults.toolFunction ~= "fertilize" then
        return false, "Invalid fertilizer"
    end

    local cropId = plot.crops[posKey]
    local cropData = state.crops[cropId]
    if not cropData then
        return false, "Crop data not found"
    end

    if cropData.stage == GROWTH_STAGES.WITHERED then
        return false, "Crop is withered"
    end

    cropData.lastFertilized = os.time()
    cropData.fertilizeQuality = (cropData.fertilizeQuality or 0) + fertilizer.defaults.potency
    cropData.growthBonus = (cropData.growthBonus or 0) + fertilizer.defaults.growthBonus
    cropData.yieldBonus = (cropData.yieldBonus or 0) + (fertilizer.defaults.yieldBonus or 0)
    cropData.qualityBonus = (cropData.qualityBonus or 0) + (fertilizer.defaults.qualityBonus or 0)

    plot.tilled[posKey].quality = plot.tilled[posKey].quality + (fertilizer.defaults.potency * 0.1)

    if cropData.stage < GROWTH_STAGES.HARVESTABLE then
        local cropTemplate = Modules.Farm.GetCrop(cropData.type)
        if cropTemplate then
            local currentSeason = Services.Time:GetSeason()
            local growthDays = CalculateGrowth(cropTemplate, cropData.quality, currentSeason)
            local cycleDuration = Services.Time:GetCycle()
            local nextUpdateTime = (growthDays * cycleDuration * 0.7) / (GROWTH_STAGES.HARVESTABLE - cropData.stage)
            ScheduleGrowth(cropId, nextUpdateTime)
        end
    end

    Services.Event:Fire("Farm.Fertilize", {
        playerId = playerId,
        plotId = plotId,
        position = position,
        cropId = cropId,
        fertilizeQuality = cropData.fertilizeQuality
    })

    return true
end

function FarmingService:HarvestCrop(playerId, plotId, position, toolId)
    local plot = state.plots[plotId]
    if not plot then
        return false, "Plot not found"
    end

    local posKey = tostring(position)
    if not plot.crops or not plot.crops[posKey] then
        return false, "No crop to harvest"
    end

    local tool = Modules.Farm.GetTool(toolId)
    if not tool or tool.defaults.toolFunction ~= "harvest" then
        return false, "Invalid harvesting tool"
    end

    local cropId = plot.crops[posKey]
    local cropData = state.crops[cropId]
    if not cropData then
        return false, "Crop data not found"
    end

    if cropData.stage == GROWTH_STAGES.WITHERED then
        state.crops[cropId] = nil
        plot.crops[posKey] = nil

        Services.Event:Fire("Farm.Harvest", {
            playerId = playerId,
            plotId = plotId,
            position = position,
            cropId = cropId,
            isWithered = true,
            yield = {}
        })

        return true, {}
    end

    if cropData.stage < GROWTH_STAGES.HARVESTABLE then
        return false, "Crop not ready for harvest"
    end

    local cropTemplate = Modules.Farm.GetCrop(cropData.type)
    if not cropTemplate then
        return false, "Crop template not found"
    end

    local baseYield = 1
    local qualityMultiplier = 1 + (cropData.quality - 1) * 0.1

    if cropData.growthBonus then
        qualityMultiplier = qualityMultiplier + cropData.growthBonus
    end

    if cropData.yieldBonus then
        qualityMultiplier = qualityMultiplier + cropData.yieldBonus
    end

    local harvestBonus = tool.defaults.harvestBonus or 0
    local totalYield = math.floor(baseYield * qualityMultiplier * (1 + harvestBonus) + 0.5)

    local seedsMin = cropTemplate.defaults.seedsProduced and cropTemplate.defaults.seedsProduced.min or 0
    local seedsMax = cropTemplate.defaults.seedsProduced and cropTemplate.defaults.seedsProduced.max or 0
    local seedsProduced = 0

    if seedsMax > 0 then
        seedsProduced = math.random(seedsMin, seedsMax)
        if cropData.qualityBonus then
            seedsProduced = math.floor(seedsProduced * (1 + cropData.qualityBonus) + 0.5)
        end
    end

    local harvest = {
        type = cropData.type,
        quantity = totalYield,
        quality = cropData.quality + (cropData.qualityBonus or 0),
        seeds = seedsProduced > 0 and {
            type = cropData.type .. "_SEED",
            quantity = seedsProduced
        } or nil
    }

    if state.growthTasks[cropId] then
        task.cancel(state.growthTasks[cropId])
        state.growthTasks[cropId] = nil
    end

    state.crops[cropId] = nil
    plot.crops[posKey] = nil

    if plot.tilled and plot.tilled[posKey] then
        plot.tilled[posKey].quality = math.max(plot.tilled[posKey].quality * 0.9, plot.soilQuality * 0.5)
    end

    Services.Event:Fire("Farm.Harvest", {
        playerId = playerId,
        plotId = plotId,
        position = position,
        cropId = cropId,
        isWithered = false,
        yield = harvest
    })

    return true, harvest
end

return FarmingService
