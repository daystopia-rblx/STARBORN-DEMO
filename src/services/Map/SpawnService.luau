--[[ SpawnService
    Manages checkpoint activation, respawning, and associated effects.
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-11
]]
local SpawnService = {}

SpawnService.Dependencies = {
    "Data",
    "Event",
    "Stat",
    "Object"
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
    ["Combat.Death"] = function(self, data)
        if data and data.player then
            task.wait(1)
            data.player:LoadCharacter()
            task.wait(0.1)
            self:RespawnCheckpoint(data.player)
        elseif data and data.entity then
            local player = game:GetService("Players"):GetPlayerFromCharacter(data.entity)
            if player then
                task.wait(1)
                player:LoadCharacter()
                task.wait(0.1)
                self:RespawnCheckpoint(player)
            end
        end
    end,

    ["Data.Init"] = function(self, data)
        if not data or not data.player then return end
        local userId = data.userId
        local player = data.player

        local playerData = Services.Data:GetData(userId, "PlayerData")

        local checkpointInfo = nil
        if playerData and playerData.world and playerData.world.checkpoint and type(playerData.world.checkpoint) == "table" then
            checkpointInfo = playerData.world.checkpoint
        end

        local checkpointId = checkpointInfo and checkpointInfo.id

        if not checkpointId then
            self:RespawnCheckpoint(player)
            return
        end

        local checkpointData = State.activeCheckpoints[checkpointId]

        if checkpointData and checkpointData.instance and checkpointData.instance:IsDescendantOf(game) then
            State.playerCheckpoints[userId] = {
                lastCheckpoint = checkpointData.instance,
                position = checkpointData.position
            }
            self:RespawnCheckpoint(player)
        else
            State.playerCheckpoints[userId] = nil
            self:RespawnCheckpoint(player)
        end
    end,

    [workspace.ChildAdded] = function(self, instance: Instance)
        if instance.Name == "SpawnLocation" and instance:IsA("Model") then
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
    game:GetService("Players").RespawnTime = math.huge

    game:GetService("Players").PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                task.wait()
                player.AutoJumpEnabled = false
            end)
        end)
    end)

    State.defaultSpawn = workspace:FindFirstChild("SpawnLocation", true)
    if not (State.defaultSpawn and State.defaultSpawn:IsA("Model")) then
        warn("No default spawn model found in workspace")
    else
        local hasSpawnPoints = false
        for _, child in State.defaultSpawn:GetDescendants() do
            if child.Name == "Spawn" and (child:IsA("BasePart") or (child:IsA("Model") and child.PrimaryPart)) then
                hasSpawnPoints = true
                break
            end
        end

        if not hasSpawnPoints and not State.defaultSpawn.PrimaryPart then
            warn("Default spawn model has no Spawn parts or PrimaryPart")
        end
    end

    self:RegisterSpawn()
    return true
end

function SpawnService:RegisterSpawn()
    Services.Object:RegisterScanner("TYPE",
        function(instance)
            local checkpointType = instance:GetAttribute("TYPE")
            if checkpointType == "Bonfire" or checkpointType == "Bed" then
                self:RegisterCheckpoint(instance)
            end
        end,
        function(instance)
            local checkpointType = instance:GetAttribute("TYPE")
            if checkpointType == "Bonfire" or checkpointType == "Bed" then
                self:UnregisterCheckpoint(instance)
            end
        end
    )
end

function SpawnService:Cleanup()
    table.clear(State.playerCheckpoints)
    table.clear(State.activeCheckpoints)
end

--[[ Utility Functions ]]
function SpawnService:CheckOccupation(spawnPart: BasePart): boolean
    local characterSize = Vector3.new(4, 6, 4)
    local region = Region3.new(
        spawnPart.Position - (characterSize / 2),
        spawnPart.Position + (characterSize / 2)
    )

    local parts = workspace:GetPartsInPart(spawnPart)
    for _, part in parts do
        if part.Parent and part.Parent:IsA("Model") then
            local player = game:GetService("Players"):GetPlayerFromCharacter(part.Parent)
            if player then
                return true
            end
        end
    end

    return false
end

function SpawnService:GetPosition(model: Instance): Vector3
    if not model then
        return Vector3.new(0, 10, 0)
    end

    local spawnParts = {}
    local occupiedParts = {}

    for _, child in model:GetDescendants() do
        if child.Name == "Spawn" then
            local spawnPart
            if child:IsA("BasePart") then
                spawnPart = child
            elseif child:IsA("Model") and child.PrimaryPart then
                spawnPart = child.PrimaryPart
            end

            if spawnPart then
                if self:CheckOccupation(spawnPart) then
                    table.insert(occupiedParts, spawnPart)
                else
                    table.insert(spawnParts, spawnPart)
                end
            end
        end
    end

    if #spawnParts > 0 then
        local selectedSpawn = spawnParts[math.random(1, #spawnParts)]
        return selectedSpawn.Position
    end

    if #occupiedParts > 0 then
        local selectedSpawn = occupiedParts[math.random(1, #occupiedParts)]
        return selectedSpawn.Position + Vector3.new(0, 3, 0)
    end

    if model:IsA("Model") then
        if model.PrimaryPart then
            return model.PrimaryPart.Position
        else
            return model:GetPivot().Position
        end
    elseif model:IsA("BasePart") then
        return model.Position
    end

    return Vector3.new(0, 10, 0)
end

--[[ Checkpoint Management ]]
function SpawnService:RegisterCheckpoint(checkpoint: Model): boolean
    if not checkpoint:IsA("Model") or not checkpoint:IsDescendantOf(game) then return false end

    local checkpointType = checkpoint:GetAttribute("TYPE")
    if not checkpointType or (checkpointType ~= "Bonfire" and checkpointType ~= "Bed") then return false end

    local spawnLocation = checkpoint:GetAttribute("SPAWN")
    if not spawnLocation then return false end

    local position = self:GetPosition(checkpoint)
    local objectData = Modules.Object.GetObject(checkpointType)
    local healRate = objectData and objectData.defaults.properties.heal_rate or 1.0

    local positionString = tostring(position):gsub("[^%d]", "")
    local checkpointId = checkpointType .. "_" .. spawnLocation .. "_" .. positionString
    State.activeCheckpoints[checkpointId] = {
        instance = checkpoint,
        position = position,
        type = checkpointType,
        location = spawnLocation,
        healRate = healRate
    }

    Services.Event:Fire("Spawn.Checkpoint", {
        checkpoint = checkpoint,
        id = checkpointId,
        position = position,
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
    local userId = player.UserId

    local checkpointType = checkpoint:GetAttribute("TYPE")
    local spawnLocation = checkpoint:GetAttribute("SPAWN")
    if not checkpointType or not spawnLocation then return false end

    local position = checkpoint:GetPivot().Position
    local positionString = tostring(position):gsub("[^%d]", "")
    local checkpointId = checkpointType .. "_" .. spawnLocation .. "_" .. positionString

    if not State.activeCheckpoints[checkpointId] then
        if not self:RegisterCheckpoint(checkpoint) then
             return false
        end
        if not State.activeCheckpoints[checkpointId] then
            return false
        end
    end

    local checkpointData = State.activeCheckpoints[checkpointId]

    State.playerCheckpoints[userId] = {
        lastCheckpoint = checkpoint,
        position = checkpointData.position
    }

    Services.Data:UpdateData(tostring(player.UserId), "PlayerData", function(data)
        data.world = data.world or {}
        data.world.checkpoint = {
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
    local userId = player.UserId
    local checkpointInfo = State.playerCheckpoints[userId]

    local infoString = "nil"
    if checkpointInfo then
        infoString = string.format("{lastCheckpoint=%s, position=%s}",
            checkpointInfo.lastCheckpoint and checkpointInfo.lastCheckpoint.Name or "nil",
            tostring(checkpointInfo.position or "nil"))
    end

    return checkpointInfo
end

function SpawnService:RespawnCheckpoint(player: Player)
    if not player then return false end

    local checkpointData = self:GetCheckpoint(player)
    local spawnPosition = Vector3.new(0, 10, 0) 
    local spawnCheckpoint = nil
    local spawnReason = "Default (Fallback)"

    if not State.defaultSpawn then
        State.defaultSpawn = workspace:FindFirstChild("SpawnLocation", true)
    end

    if State.defaultSpawn then
        spawnPosition = self:GetPosition(State.defaultSpawn)
        spawnReason = "Default Spawn"
    else
    end

    if checkpointData and checkpointData.lastCheckpoint and checkpointData.lastCheckpoint:IsDescendantOf(game) then
        spawnPosition = self:GetPosition(checkpointData.lastCheckpoint)
        spawnCheckpoint = checkpointData.lastCheckpoint
        spawnReason = "Player Checkpoint"
    else
        State.playerCheckpoints[player.UserId] = nil 
    end

    Services.Stat:ModifyStat(player, "HEALTH", {
        operation = "set",
        value = player:GetAttribute("HEALTH_MAX") or 100,
        metadata = { source = "respawn" }
    })

    local character = player.Character
    if character and character.PrimaryPart then
        local targetCFrame = CFrame.new(spawnPosition + Vector3.new(0, 3, 0))
        character:PivotTo(targetCFrame)
    end

    Services.Event:Fire("Spawn.Spawn", {
        player = player,
        checkpoint = spawnCheckpoint,
        position = spawnPosition
    })

    return true
end

return SpawnService
