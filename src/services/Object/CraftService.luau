--[[ CraftService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local CraftService = {}

--[[ Dependencies ]]
CraftService.Dependencies = {
    "Event",
    "Data",
    "Stat",
    "Inventory",
    "Object",
    "Interact"
}

CraftService.Modules = {
    "Craft",
    "Recipe"
}

--[[ Events ]]
CraftService.Events = {
    Discover = { validate = true },
    Start = { validate = true },
    Complete = { validate = true },
    Fail = { validate = true },
    Cancel = { validate = true },
    Progress = { validate = true }
}

--[[ Types ]]
type CraftingSession = {
    id: string,
    playerId: string,
    recipeId: string,
    stationId: string,
    stationType: string,
    startTime: number,
    endTime: number,
    materials: {[string]: number},
    progress: number,
    complete: boolean,
    successful: boolean,
    result: any?
}

--[[ Constants ]]
local DISCOVERY_XP = {
    DEFAULT = 5,
    EXPLORATION = 25,
    QUEST = 15,
    NPC = 10,
    EXPERIMENTATION = 50
}

--[[ State ]]
local Services
local Modules
local State = {
    playerDiscoveries = {},
    craftingSessions = {},
    activeSessions = {},
    stations = {}
}

--[[ Event Listeners ]]
CraftService.Listeners = {
    ["Data.Init"] = function(self, data)
        if not data or not data.userId or not data.player then return end

        local userId = data.userId
        local playerData = data.data.PlayerData

        if playerData and playerData.crafting and playerData.crafting.discoveries then
            State.playerDiscoveries[userId] = {}

            for recipeId, discovered in pairs(playerData.crafting.discoveries) do
                if discovered then
                    State.playerDiscoveries[userId][recipeId] = true
                end
            end
        else
            State.playerDiscoveries[userId] = {}
            for _, recipeId in ipairs(Modules.Recipe.GetDefaultRecipes()) do
                State.playerDiscoveries[userId][recipeId] = true
            end
        end
    end,

    ["Player.Left"] = function(self, data)
        if not data or not data.userId then return end

        local userId = data.userId

        if State.activeSessions[userId] then
            local sessionId = State.activeSessions[userId]
            self:CancelCrafting(userId, sessionId)
        end
    end
}

--[[ Core Functions ]]
function CraftService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function CraftService:Start()
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:UpdateSessions(dt)
    end)
    return true
end

--[[ Utility Functions ]]
function CraftService:GetSuccess(skillLevel, craftType)
    local baseRate = Modules.Stat.Constants.CRAFT.BASE_SUCCESS_RATE
    local bonus = skillLevel * Modules.Stat.Constants.CRAFT.SKILL_SUCCESS_BONUS
    return math.min(baseRate + bonus, Modules.Stat.Constants.CRAFT.MAX_SUCCESS_RATE)
end

function CraftService:GetMaterial(skillLevel)
    local baseReturn = Modules.Stat.Constants.CRAFT.BASE_MATERIAL_RETURN
    local bonus = skillLevel * Modules.Stat.Constants.CRAFT.SKILL_RETURN_BONUS
    return baseReturn + bonus
end

function CraftService:GetProgress(level)
    local baseValue = Modules.Stat.Constants.PROGRESSION.BASE_PROGRESS
    local multiplier = Modules.Stat.Constants.PROGRESSION.GROWTH_RATE
    return math.floor(baseValue * (level ^ multiplier))
end

--[[ Recipe Functions ]]
function CraftService:GetRecipes(userId, stationType)
    if not userId or not stationType then return {} end

    local availableRecipes = {}
    local discoveries = State.playerDiscoveries[userId] or {}

    for recipeId, recipe in pairs(Modules.Recipe.Recipes) do
        if discoveries[recipeId] then
            if Modules.Recipe.CanCraft(recipeId, stationType) then
                table.insert(availableRecipes, {
                    id = recipeId,
                    name = recipe.name,
                    tier = recipe.tier,
                    materials = recipe.materials,
                    timeRequired = recipe.timeRequired
                })
            end
        end
    end

    return availableRecipes
end

--[[ Discovery Functions ]]
function CraftService:DiscoverRecipe(userId, recipeId, source)
    if not userId or not recipeId then return false end

    local recipe = Modules.Recipe.GetRecipe(recipeId)
    if not recipe then return false end

    if State.playerDiscoveries[userId] and State.playerDiscoveries[userId][recipeId] then 
        return true
    end

    if not State.playerDiscoveries[userId] then
        State.playerDiscoveries[userId] = {}
    end

    State.playerDiscoveries[userId][recipeId] = true

    local discoveryMethod = recipe.discoveryMethod or "DEFAULT"
    local xpAwarded = DISCOVERY_XP[discoveryMethod] or DISCOVERY_XP.DEFAULT

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if player then
        if recipe.craftType then
            Services.Stat:AddProgress(player, xpAwarded * 2, recipe.craftType .. "_SKILL")
        end

        Services.Stat:AddProgress(player, xpAwarded)
    end

    Services.Event:Fire("Craft.Discover", {
        userId = userId,
        recipeId = recipeId,
        recipeName = recipe.name,
        source = source,
        discoveryMethod = discoveryMethod,
        xpAwarded = xpAwarded
    })
    return true
end

function CraftService:CheckDiscovery(userId, recipeId)
    if not userId or not recipeId then return false end

    return State.playerDiscoveries[userId] and State.playerDiscoveries[userId][recipeId] == true
end

function CraftService:GetDiscovery(userId)
    if not userId then return {} end

    local discoveries = {}
    if State.playerDiscoveries[userId] then
        for recipeId, discovered in pairs(State.playerDiscoveries[userId]) do
            if discovered then
                table.insert(discoveries, recipeId)
            end
        end
    end

    return discoveries
end

--[[ Skill Functions ]]
function CraftService:GetLevel(player, craftType)
    if not player or not craftType then return 1 end

    local skillLevel = Services.Stat:GetStat(player, craftType .. "_SKILL") or 1
    return skillLevel
end

function CraftService:CheckSkill(player, recipeId)
    if not player or not recipeId then return false end

    local recipe = Modules.Recipe.GetRecipe(recipeId)
    if not recipe then return false end

    local skillRequired = recipe.skillRequired or 1
    local craftType = recipe.craftType
    local skillLevel = self:GetLevel(player, craftType)

    return skillLevel >= skillRequired, skillLevel, skillRequired
end

--[[ Crafting Functions ]]
function CraftService:StartCrafting(player, recipeId, stationId)
    if not player or not recipeId or not stationId then return false, "Invalid parameters" end

    local userId = tostring(player.UserId)

    if State.activeSessions[userId] then
        return false, "Already crafting"
    end

    local recipe = Modules.Recipe.GetRecipe(recipeId)
    if not recipe then
        return false, "Recipe not found"
    end

    if not self:CheckDiscovery(userId, recipeId) then
        return false, "Recipe not discovered"
    end

    local station = State.stations[stationId]
    if not station then
        return false, "Station not found"
    end

    if not Modules.Recipe.ValidateStation(recipeId, station.type) then
        return false, "Cannot craft this item at this station"
    end

    local inventory = Services.Inventory:GetInventory(userId)
    local hasRequiredMaterials, missingMaterials = Modules.Recipe.CheckMaterials(recipeId, inventory)

    if not hasRequiredMaterials then
        return false, "Missing required materials", missingMaterials
    end

    local hasSkill, currentSkill, requiredSkill = self:CheckSkill(player, recipeId)
    if not hasSkill then
        return false, "Insufficient skill level. Required: " .. requiredSkill .. ", Current: " .. currentSkill, {
            currentSkill = currentSkill,
            requiredSkill = requiredSkill
        }
    end

    local materialsUsed = {}

    for materialId, amount in pairs(recipe.materials.core) do
        Services.Inventory:RemoveItem(player, materialId, amount)
        materialsUsed[materialId] = amount
    end

    if recipe.materials.modifiers then
        for materialId, amount in pairs(recipe.materials.modifiers) do
            Services.Inventory:RemoveItem(player, materialId, amount)
            materialsUsed[materialId] = amount
        end
    end

    if recipe.materials.catalysts then
        for materialId, amount in pairs(recipe.materials.catalysts) do
            Services.Inventory:RemoveItem(player, materialId, amount)
            materialsUsed[materialId] = amount
        end
    end

    local sessionId = Services.Data:GenerateId("UUID")
    local currentTime = os.time()
    local endTime = currentTime + recipe.timeRequired

    local session = {
        id = sessionId,
        playerId = userId,
        recipeId = recipeId,
        stationId = stationId,
        stationType = station.type,
        startTime = currentTime,
        endTime = endTime,
        materials = materialsUsed,
        progress = 0,
        complete = false,
        successful = false
    }

    State.craftingSessions[sessionId] = session
    State.activeSessions[userId] = sessionId

    Services.Event:Fire("Craft.Start", {
        sessionId = sessionId,
        playerId = userId,
        recipeId = recipeId,
        recipeName = recipe.name,
        stationId = stationId,
        stationType = station.type,
        materials = materialsUsed,
        duration = recipe.timeRequired
    })
    return true, sessionId
end

function CraftService:CompleteCrafting(sessionId)
    local session = State.craftingSessions[sessionId]
    if not session or session.complete then return false end

    local recipe = Modules.Recipe.GetRecipe(session.recipeId)
    if not recipe then return false end

    local player = game.Players:GetPlayerByUserId(tonumber(session.playerId))
    if not player then return false end

    session.complete = true
    session.progress = 1

    local skillLevel = self:GetLevel(player, recipe.craftType)

    local baseSuccessRate = recipe.successRate or Modules.Stat.Constants.CRAFT.BASE_SUCCESS_RATE
    local successRate = self:GetSuccess(skillLevel, recipe.craftType)

    if recipe.difficulty then
        local difficultyModifier = 1 - (recipe.difficulty * 0.1)
        successRate = successRate * difficultyModifier
    end

    successRate = math.min(successRate, Modules.Stat.Constants.CRAFT.MAX_SUCCESS_RATE)

    local roll = math.random()
    local success = roll <= successRate
    session.successful = success

    if success then
        Services.Inventory:AddItem(player, recipe.result.itemId, recipe.result.quantity, recipe.result.modifiers)

        local difficultyBonus = recipe.difficulty and (1 + recipe.difficulty * 0.2) or 1
        local expGained = math.floor(recipe.timeRequired * Modules.Stat.Constants.CRAFT.SKILL_PROGRESS_MULTIPLIER * difficultyBonus)

        Services.Stat:AddProgress(player, expGained, recipe.craftType .. "_SKILL")

        Services.Stat:AddProgress(player, math.floor(expGained * 0.25))

        Services.Event:Fire("Craft.Complete", {
            sessionId = sessionId,
            playerId = session.playerId,
            recipeId = session.recipeId,
            recipeName = recipe.name,
            itemId = recipe.result.itemId,
            quantity = recipe.result.quantity,
            success = true,
            expGained = expGained,
            skillLevel = skillLevel
        })
    else
        local returnRate = self:GetMaterial(skillLevel)

        for materialId, amount in pairs(session.materials) do
            local returnAmount = math.floor(amount * returnRate)
            if returnAmount > 0 then
                Services.Inventory:AddItem(player, materialId, returnAmount)
            end
        end

        local failureExpGained = math.floor(recipe.timeRequired * 0.5)
        Services.Stat:AddProgress(player, failureExpGained, recipe.craftType .. "_SKILL")

        Services.Stat:AddProgress(player, math.floor(failureExpGained * 0.25))

        Services.Event:Fire("Craft.Fail", {
            sessionId = sessionId,
            playerId = session.playerId,
            recipeId = session.recipeId,
            recipeName = recipe.name,
            returnRate = returnRate,
            expGained = failureExpGained,
            skillLevel = skillLevel
        })
    end

    State.activeSessions[session.playerId] = nil
    return true
end

function CraftService:CancelCrafting(userId, sessionId)
    if not userId or not sessionId then return false end

    local session = State.craftingSessions[sessionId]
    if not session or session.complete then return false end

    if session.playerId ~= userId then return false end

    session.complete = true
    session.successful = false

    local returnRate = math.max(0.75 - session.progress, 0.25)

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if player then
        for materialId, amount in pairs(session.materials) do
            local returnAmount = math.floor(amount * returnRate)
            if returnAmount > 0 then
                Services.Inventory:AddItem(player, materialId, returnAmount)
            end
        end

        Services.Event:FireTo(player, "Craft.Cancel", {
            sessionId = sessionId,
            recipeId = session.recipeId,
            returnRate = returnRate
        })
    end

    State.activeSessions[userId] = nil

    return true
end

--[[ Session Functions ]]
function CraftService:UpdateSessions(dt)
    local currentTime = os.time()
    local sessionsToComplete = {}

    for sessionId, session in pairs(State.craftingSessions) do
        if not session.complete then
            local elapsedTime = currentTime - session.startTime
            local totalDuration = session.endTime - session.startTime

            if totalDuration <= 0 then
                totalDuration = 1
            end

            local progress = math.min(elapsedTime / totalDuration, 1)
            session.progress = progress

            if currentTime >= session.endTime then
                table.insert(sessionsToComplete, sessionId)
            elseif math.floor(progress * 10) > math.floor(session.progress * 10) then
                Services.Event:Fire("Craft.Progress", {
                    sessionId = sessionId,
                    playerId = session.playerId,
                    progress = progress
                })
            end
        end
    end

    for _, sessionId in ipairs(sessionsToComplete) do
        self:CompleteCrafting(sessionId)
    end
end

function CraftService:GetSession(userId)
    if not userId then return nil end

    local sessionId = State.activeSessions[userId]
    if not sessionId then return nil end

    return State.craftingSessions[sessionId]
end

--[[ Experiment Functions ]]
function CraftService:ExperimentMaterials(player, materials, stationId)
    if not player or not materials or not stationId then return false end

    local userId = tostring(player.UserId)
    local station = State.stations[stationId]

    if not station then return false, "Station not found" end

    local potentialRecipes = {}

    for recipeId, recipe in pairs(Modules.Recipe.Recipes) do
        if Modules.Recipe.CanCraft(recipeId, station.type) then
            local matches = true

            for materialId, requiredAmount in pairs(recipe.materials.core) do
                local providedAmount = materials[materialId] or 0
                if providedAmount < requiredAmount then
                    matches = false
                    break
                end
            end

            if matches and recipe.materials.modifiers then
                for materialId, requiredAmount in pairs(recipe.materials.modifiers) do
                    local providedAmount = materials[materialId] or 0
                    if providedAmount < requiredAmount then
                        matches = false
                        break
                    end
                end
            end

            if matches and not self:CheckDiscovery(userId, recipeId) then
                table.insert(potentialRecipes, {
                    id = recipeId,
                    discoveryMethod = recipe.discoveryMethod
                })
            end
        end
    end

    if #potentialRecipes == 0 then
        return false, "No matching recipes found for these materials"
    end

    local selectedRecipe
    local experimentationRecipes = {}

    for _, recipe in ipairs(potentialRecipes) do
        if recipe.discoveryMethod == "EXPERIMENTATION" then
            table.insert(experimentationRecipes, recipe)
        end
    end

    if #experimentationRecipes > 0 then
        selectedRecipe = experimentationRecipes[math.random(#experimentationRecipes)]
    else
        selectedRecipe = potentialRecipes[math.random(#potentialRecipes)]
    end

    self:DiscoverRecipe(userId, selectedRecipe.id, "EXPERIMENTATION")

    for materialId, amount in pairs(materials) do
        Services.Inventory:RemoveItem(player, materialId, amount)
    end

    return true, selectedRecipe.id
end

return CraftService