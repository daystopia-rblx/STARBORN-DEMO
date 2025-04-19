--[[ HarvestingService
    Manages harvesting activities including ore extraction, mining speed calculations, and drop generation.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-18
]]
local HarvestingService = {}

--[[ Dependencies ]]
HarvestingService.Dependencies = {
    "Event",
    "Object",
    "Tool",
    "Time",
    "Inventory",
    "Loot"
}

--[[ Modules ]]
HarvestingService.Modules = {
    "Node",
    "Action",
    "Zone"
}

--[[ Events ]]
HarvestingService.Events = {
    Harvest = true,
    Progress = true,
    Complete = true,
    Respawn = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ State ]]
local state = {
    nodes = {},
    activeHarvesters = {},
    respawnTasks = {}
}

--[[ Constants ]]
local RESPAWN_CHECK_INTERVAL = 60
local DEFAULT_RESPAWN_TIME = 300
local HARVESTING_STAGES = {
    READY = 1,
    PARTIAL = 2,
    DEPLETED = 3
}

--[[ Listeners ]]
HarvestingService.Listeners = {
    ["Time.Update"] = function(self, timeData)
        if timeData and timeData.hour ~= nil then
            self:CheckRespawns()
        end
    end,

    ["Player.Left"] = function(self, player)
        if state.activeHarvesters[player] then
            state.activeHarvesters[player] = nil
        end
    end
}

--[[ Core Functions ]]
function HarvestingService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function HarvestingService:Start()
    self:RegisterNodes()

    task.spawn(function()
        while true do
            self:CheckRespawns()
            task.wait(RESPAWN_CHECK_INTERVAL)
        end
    end)
    return true
end
--[[ Getter Functions ]]
function HarvestingService:GetNode(nodeId)
    return state.nodes[nodeId]
end

function HarvestingService:GetAllNodes()
    return state.nodes
end

--[[ Node Management ]]
function HarvestingService:RegisterNodes()
    Services.Object:RegisterScanner("TYPE",
        function(instance)
            local nodeType = instance:GetAttribute("TYPE")
            if nodeType then
                local nodeTemplate = Modules.Node.GetNode(nodeType)
                if nodeTemplate then
                    local nodeId = instance:GetAttribute("ID") or tostring(instance:GetFullName():gsub("[^%w]", "_"))

                    if state.nodes[nodeId] then return end

                    state.nodes[nodeId] = {
                        id = nodeId,
                        instance = instance,
                        type = nodeType,
                        state = HARVESTING_STAGES.READY,
                        lastHarvested = 0,
                        health = nodeTemplate.defaults.durability or 100,
                        maxHealth = nodeTemplate.defaults.durability or 100
                    }
                else
                     warn("Invalid node type found by scanner:", nodeType, instance:GetFullName())
                end
            end
        end,
        function(instance)
            local nodeId = instance:GetAttribute("ID") or tostring(instance:GetFullName():gsub("[^%w]", "_"))
            if state.respawnTasks[nodeId] then
                task.cancel(state.respawnTasks[nodeId])
                state.respawnTasks[nodeId] = nil
            end
            state.nodes[nodeId] = nil
        end
    )
end

function HarvestingService:CheckRespawns()
    local currentTime = os.time()

    for nodeId, nodeData in pairs(state.nodes) do
        if nodeData.state == HARVESTING_STAGES.DEPLETED then
            local nodeTemplate = Modules.Node.GetNode(nodeData.type)
            local respawnTime = nodeTemplate and nodeTemplate.defaults.respawnTime or DEFAULT_RESPAWN_TIME

            if currentTime - nodeData.lastHarvested >= respawnTime then
                self:RespawnNode(nodeId)
            end
        end
    end
end

function HarvestingService:RespawnNode(nodeId)
    local nodeData = state.nodes[nodeId]
    if not nodeData then return false end

    local nodeTemplate = Modules.Node.GetNode(nodeData.type)
    if not nodeTemplate then return false end

    nodeData.state = HARVESTING_STAGES.READY
    nodeData.health = nodeTemplate.defaults.durability or 100

    local nodeId = Services.Object:GetID(nodeData.instance)
    if nodeId then
        Services.Object:UpdateAttributes(nodeId, {
            HEALTH = nodeData.health,
            STATE = "READY",
            LAST_HARVESTED = nil
        })
    end

    if state.respawnTasks[nodeId] then
        task.cancel(state.respawnTasks[nodeId])
        state.respawnTasks[nodeId] = nil
    end

    Services.Event:Fire("Harvest.Respawn", {
        nodeId = nodeId,
        instance = nodeData.instance
    })

    return true
end

function HarvestingService:ScheduleRespawn(nodeId)
    local nodeData = state.nodes[nodeId]
    if not nodeData then return false end

    local nodeTemplate = Modules.Node.GetNode(nodeData.type)
    if not nodeTemplate then return false end

    local respawnTime = nodeTemplate.defaults.respawnTime or DEFAULT_RESPAWN_TIME

    if state.respawnTasks[nodeId] then
        task.cancel(state.respawnTasks[nodeId])
    end

    state.respawnTasks[nodeId] = task.delay(respawnTime, function()
        self:RespawnNode(nodeId)
        state.respawnTasks[nodeId] = nil
    end)

    return true
end

--[[ Harvesting Functions ]]
function HarvestingService:UpdateHarvest(playerId, nodeId, progress)
    local player = game.Players:GetPlayerByUserId(playerId)
    if not player then
        return false, "Player not found"
    end

    local nodeData = state.nodes[nodeId]
    if not nodeData then
        return false, "Node not found"
    end

    local nodeTemplate = Modules.Node.GetNode(nodeData.type)
    if not nodeTemplate then
        return false, "Node template not found"
    end

    if nodeData.state == HARVESTING_STAGES.DEPLETED then
        return false, "Node already depleted"
    end

    local equippedTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not equippedTool then
        return false, "No tool equipped"
    end

    local toolId = Services.Object:GetID(equippedTool)
    local toolData = equippedTool:GetAttributes()
    if not toolData then
        return false, "Tool data not found"
    end

    local tools = nodeTemplate.tools
    local capabilities = nodeTemplate.capabilities

    if tools and #tools > 0 then
        if not Services.Tool:ValidateTool(player, tools) then
            return false, "Requires proper tool: " .. table.concat(tools, ", ")
        end
    end

    if capabilities and #capabilities > 0 then
        if not Services.Tool:ValidateCapability(player, capabilities) then
            return false, "Requires tool with capability: " .. table.concat(capabilities, ", ")
        end
    end

    local toolPower = toolData.POWER or 1
    local nodeHardness = nodeTemplate.defaults.hardness or 1
    local damageAmount = toolPower * progress * (1 / nodeHardness)

    nodeData.health = math.max(0, nodeData.health - damageAmount)

    local nodeId = Services.Object:GetID(nodeData.instance)
    if nodeId then
        Services.Object:UpdateAttributes(nodeId, {
            HEALTH = nodeData.health
        })
    end

    if nodeData.health <= nodeData.maxHealth * 0.5 and nodeData.state == HARVESTING_STAGES.READY then
        nodeData.state = HARVESTING_STAGES.PARTIAL

        if nodeId then
            Services.Object:UpdateAttributes(nodeId, {
                STATE = "PARTIAL"
            })
        end
    end

    if nodeData.health <= 0 then
        self:CompleteHarvest(playerId, nodeId, toolId)
        return true
    end

    Services.Event:Fire("Harvest.Progress", {
        playerId = playerId,
        nodeId = nodeId,
        health = nodeData.health,
        maxHealth = nodeData.maxHealth,
        state = nodeData.state
    })

    return true
end

function HarvestingService:CompleteHarvest(playerId, nodeId, toolId)
    local player = game.Players:GetPlayerByUserId(playerId)
    if not player then
        return false, "Player not found"
    end

    local nodeData = state.nodes[nodeId]
    if not nodeData then
        return false, "Node not found"
    end

    local nodeTemplate = Modules.Node.GetNode(nodeData.type)
    if not nodeTemplate then
        return false, "Node template not found"
    end

    local toolObject = toolId and Services.Object:GetInstance(toolId)
    local toolData = toolObject and toolObject:GetAttributes() or {}

    local lootTier = (nodeTemplate.defaults and nodeTemplate.defaults.tier) or "low"

    local lootItem = Services.Loot:GenerateLoot("node", nodeData.type, lootTier)
    local drops = {}

    if lootItem then
        local bonusYield = toolData.YIELD_BONUS or 0
        local finalQuantity = math.floor((lootItem.quantity or 1) * (1 + bonusYield) + 0.5)

        if finalQuantity > 0 then
            lootItem.quantity = finalQuantity
            table.insert(drops, lootItem)
        end
    end

    nodeData.state = HARVESTING_STAGES.DEPLETED
    nodeData.health = 0
    nodeData.lastHarvested = os.time()

    local nodeId = Services.Object:GetID(nodeData.instance)
    if nodeId then
        Services.Object:UpdateAttributes(nodeId, {
            HEALTH = 0,
            STATE = "DEPLETED",
            LAST_HARVESTED = nodeData.lastHarvested
        })
    end

    self:ScheduleRespawn(nodeId)

    if state.activeHarvesters[player] then
        state.activeHarvesters[player] = nil
    end

    Services.Event:Fire("Harvest.Complete", {
        playerId = playerId,
        nodeId = nodeId,
        drops = drops
    })

    return true, drops
end

return HarvestingService