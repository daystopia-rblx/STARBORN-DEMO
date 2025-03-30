--[[ SpawnService
    Manages checkpoint activation, respawning, and associated effects.
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-30
]]
local SpawnService = {}

SpawnService.Dependencies = {
    "Data",
    "Event",
    "Stat"
}

SpawnService.Modules = {
    "Object"
}

SpawnService.Events = {
    Checkpoint = { validate = true },
    Spawn = { validate = true }
}

local Services
local Modules
local State = {
    playerCheckpoints = {},
    activeCheckpoints = {},
    defaultSpawn = nil
}

SpawnService.Listeners = {
    ["Player.Join"] = function(self, data)
        if data and data.player then
            task.delay(0.1, function()
                if data.player.Parent then
                    self:RespawnCheckpoint(data.player)
                end
            end)
        end
    end,

    ["Combat.Death"] = function(self, data)
        if data and data.player then
            task.wait(3)
            self:RespawnCheckpoint(data.player)
        end
    end,

    ["Data.Init"] = function(self, data)
        if not data or not data.player then return end

        local playerData = Services.Data:GetData(data.userId, "PlayerData")
        if not playerData or not playerData.checkpoint or not playerData.checkpoint.id then return end

        local checkpointData = State.activeCheckpoints[playerData.checkpoint.id]
        if checkpointData and checkpointData.instance:IsDescendantOf(game) then
            State.playerCheckpoints[data.player.UserId] = {
                lastCheckpoint = checkpointData.instance,
                position = checkpointData.position
            }
            self:RespawnCheckpoint(data.player)
        end
    end,

    [workspace.DescendantAdded] = function(self, instance: Instance)
        if instance:IsA("Model") then
            self:RegisterCheckpoint(instance)
        end
    end,

    [workspace.DescendantRemoving] = function(self, instance: Instance)
        if instance:IsA("Model") then
            self:UnregisterCheckpoint(instance)
        end
    end,

    [workspace.ChildAdded] = function(self, instance: Instance)
        if instance.Name == "Spawn" and instance:IsA("Model") then
            State.defaultSpawn = instance
        end
    end
}

--[[ Core Functions ]]
function SpawnService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function SpawnService:Start()
    State.defaultSpawn = workspace:FindFirstChild("Spawn", true)
    if not (State.defaultSpawn and State.defaultSpawn:IsA("Model")) then
        warn("No default spawn model found in workspace")
    end

    for _, model in workspace:GetDescendants() do
        self:RegisterCheckpoint(model)
    end
    return true
end

function SpawnService:Cleanup()
    table.clear(State.playerCheckpoints)
    table.clear(State.activeCheckpoints)
end

--[[ Checkpoint Management ]]
function SpawnService:RegisterCheckpoint(checkpoint: Model): boolean
    if not checkpoint:IsA("Model") or not checkpoint:IsDescendantOf(game) then return false end

    local checkpointType = checkpoint:GetAttribute("TYPE")
    if not checkpointType or (checkpointType ~= "Bonfire" and checkpointType ~= "Bed") then
        return false
    end

    local spawnLocation = checkpoint:GetAttribute("SPAWN")
    if not spawnLocation then return false end

    local objectData = Modules.Object.GetObject(checkpointType)
    local healRate = objectData and objectData.defaults.properties.heal_rate or 1.0

    local checkpointId = checkpointType .. "_" .. spawnLocation .. "_" .. tostring(checkpoint:GetPivot().Position):gsub("[^%d]", "")
    State.activeCheckpoints[checkpointId] = {
        instance = checkpoint,
        position = checkpoint:GetPivot().Position,
        type = checkpointType,
        location = spawnLocation,
        healRate = healRate
    }

    Services.Event:Fire("Spawn.Checkpoint", {
        checkpoint = checkpoint,
        id = checkpointId,
        position = State.activeCheckpoints[checkpointId].position,
        type = checkpointType,
        location = spawnLocation
    })
    return true
end

function SpawnService:UnregisterCheckpoint(checkpoint: Instance)
    if not checkpoint then return false end
    local checkpointType = checkpoint:GetAttribute("TYPE")
    local spawnLocation = checkpoint:GetAttribute("SPAWN")
    if checkpointType and spawnLocation then
        for id, data in pairs(State.activeCheckpoints) do
            if data.instance == checkpoint then
                State.activeCheckpoints[id] = nil
                break
            end
        end
    end
    return true
end

function SpawnService:ActivateCheckpoint(player: Player, checkpoint: Instance)
    if not (player and checkpoint) then return false end

    local checkpointType = checkpoint:GetAttribute("TYPE")
    local spawnLocation = checkpoint:GetAttribute("SPAWN")
    if not checkpointType or not spawnLocation then return false end

    local checkpointId = checkpointType .. "_" .. spawnLocation
    if not State.activeCheckpoints[checkpointId] then return false end

    local checkpointData = State.activeCheckpoints[checkpointId]

    State.playerCheckpoints[player.UserId] = {
        lastCheckpoint = checkpoint,
        position = checkpointData.position
    }

    Services.Data:UpdateData(tostring(player.UserId), "PlayerData", function(data)
        data.checkpoint = {
            id = checkpointId,
            type = checkpointData.type,
            location = checkpointData.location,
            position = {
                x = checkpointData.position.X,
                y = checkpointData.position.Y,
                z = checkpointData.position.Z
            },
            lastActivated = os.time()
        }
        return data
    end)

    Services.Stat:ModifyStat(player, "HEALTH", {
        operation = "set",
        value = player:GetAttribute("HEALTH_MAX"),
        metadata = { source = "checkpoint_heal" }
    })

    if checkpointData.type == "BED" then
        Services.Stat:ModifyStat(player, "HEALTH_MAX", {
            operation = "multiply",
            value = 1.1,
            metadata = {
                source = "checkpoint_bonus",
                duration = 300
            }
        })
    end

    Services.Event:Fire("Spawn.Checkpoint", {
        player = player,
        checkpoint = checkpoint,
        id = checkpointId,
        position = checkpointData.position,
        type = checkpointData.type
    })

    return true
end

function SpawnService:GetCheckpoint(player: Player)
    if not player then return nil end
    return State.playerCheckpoints[player.UserId]
end

function SpawnService:RespawnCheckpoint(player: Player)
    if not player then return false end

    local checkpointData = self:GetCheckpoint(player)
    local spawnPosition = State.defaultSpawn and State.defaultSpawn:GetPivot().Position or Vector3.new(0, 10, 0)
    local spawnCheckpoint = nil

    if checkpointData and checkpointData.lastCheckpoint:IsDescendantOf(game) then
        spawnPosition = checkpointData.position
        spawnCheckpoint = checkpointData.lastCheckpoint
    else
        State.playerCheckpoints[player.UserId] = nil
    end

    Services.Stat:ModifyStat(player, "HEALTH", {
        operation = "set",
        value = player:GetAttribute("HEALTH_MAX"),
        metadata = { source = "respawn" }
    })

    local character = player.Character
    if character and character.PrimaryPart then
        character:PivotTo(CFrame.new(spawnPosition + Vector3.new(0, 3, 0)))
    end

    Services.Event:Fire("Spawn.Spawn", {
        player = player,
        checkpoint = spawnCheckpoint,
        position = spawnPosition
    })

    return true
end

return SpawnService
