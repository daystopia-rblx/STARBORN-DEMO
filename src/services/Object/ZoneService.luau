--[[ ZoneService
    Dynamic zone management system with region-based triggers and behaviors.
    Handles zone detection, transitions, overlapping regions, and custom zone attributes.
    @author @Daystopia
    @version 1.0.1
    @date 2025-02-11
]]
local ZoneService = {}

ZoneService.Dependencies = {
    "Event",
    "Data",
    "Object"
}

ZoneService.Events = {
    Enter = true,
    Exit = true,
    Change = true
}

local Services

--[[ State Management ]]--
local State = {
    playerZones = {},
    zoneCache = {},
    activeZones = {},
    lastCheck = {},
    characterConnection = {}
}

--[[ Constants ]]--
local CHECK_INTERVAL = 0.1
local DEFAULT_ZONE = "Neutral"

--[[ Event Listeners ]]--
ZoneService.Listeners = {
    ["Object.Update"] = function(self, data)
        if not data.instance or (data.attributes and data.attributes.type ~= "ZONE") then
            return
        end

        local zoneType = data.attributes and data.attributes.type or data.instance:GetAttribute("TYPE")
        if zoneType and zoneType:upper() ~= "ZONE" then
            return
        end

        local attributes = {
            instance = data.instance,
            name = data.instance:GetAttribute("NAME"),
            type = data.instance:GetAttribute("TYPE") or "Zone",
            attributes = {}
        }

        for _, attr in pairs(data.instance:GetAttributes()) do
            if type(attr) == "string" then
                attributes.attributes[attr] = data.instance:GetAttribute(attr)
            end
        end

        if data.attributes then
            for key, value in pairs(data.attributes) do
                if type(key) == "string" then
                    attributes.attributes[key] = value
                end
            end
        end

        self:RegisterZone(data.id, attributes)
    end,

    ["Player.Join"] = function(self, data)
        if not data.player then return end
        local player = data.player
        local userId = player.UserId

        State.playerZones[userId] = {}
        player:SetAttribute("ZONE", DEFAULT_ZONE)

        local function cleanupCharacterZones()
            local currentZones = State.playerZones[userId]
            if not currentZones then return end

            for zoneId, _ in pairs(currentZones) do
                local zoneData = State.zoneCache[zoneId]
                if zoneData then
                    self.ZoneEvents.Exit(self, player, zoneData.instance, zoneData)
                end
            end

            if not next(State.playerZones[userId]) then
                player:SetAttribute("ZONE", DEFAULT_ZONE)
            end
        end

        if not State.characterConnection[userId] then
            State.characterConnection[userId] = {}
        end

        State.characterConnection[userId].removing = player.CharacterRemoving:Connect(cleanupCharacterZones)
        State.characterConnection[userId].added = player.CharacterAdded:Connect(cleanupCharacterZones)
    end,

    ["Player.Left"] = function(self, data)
        if not data.player then return end
        local userId = data.player.UserId

        if State.characterConnection[userId] then
            for _, connection in pairs(State.characterConnection[userId]) do
                connection:Disconnect()
            end
            State.characterConnection[userId] = nil
        end

        State.playerZones[userId] = nil
    end
}

--[[ Core Methods ]]--
function ZoneService:Init(services)
    Services = services
    return true
end

function ZoneService:Start()
    game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateZones()
    end)

    local zones = Services.Object:SearchObjects(function(variant)
        return variant.type == "ZONE" and variant
    end)
    if zones then
        if zones.instance then
            self:RegisterZone(Services.Object:GetID(zones.instance), {
                instance = zones.instance,
                name = zones.instance:GetAttribute("NAME"),
                zoneType = zones.instance:GetAttribute("ZONE_TYPE") or "Safe"
            })
        end
    end
    return true
end

function ZoneService:Cleanup()
    if State.characterConnection then
        for _, connection in pairs(State.characterConnection) do
            connection:Disconnect()
        end
        table.clear(State.characterConnection)
    end

    table.clear(State.playerZones)
    table.clear(State.zoneCache)
    table.clear(State.activeZones)
    table.clear(State.lastCheck)
end

--[[ Zone Management ]]--
function ZoneService:RegisterZone(zoneId, attributes)
    if not attributes.instance then return end

    State.zoneCache[zoneId] = attributes

    if not State.activeZones[zoneId] then
        State.activeZones[zoneId] = true
    end
end

function ZoneService:UpdateZones()
    local players = game.Players:GetPlayers()

    for _, player in ipairs(players) do
        if not self:CheckPlayer(player) then
            continue
        end

        local rootPart = self:GetRoot(player)
        if not rootPart then
            continue
        end

        local characterSize = Vector3.new(4, 5, 4)
        local position = rootPart.Position

        for zoneId, zoneData in pairs(State.zoneCache) do
            if not zoneData.instance then
                continue
            end

            local zonePart
            if zoneData.instance:IsA("Model") then
                zonePart = zoneData.instance.PrimaryPart or zoneData.instance:FindFirstChild("ZonePart") or zoneData.instance:FindFirstChildWhichIsA("BasePart")
                if not zonePart then
                    warn("Zone model has no valid part to check against:", zoneData.instance:GetFullName())
                    continue
                end
            else
                zonePart = zoneData.instance
            end

            if not zonePart:IsA("BasePart") then
                warn("Zone part is not a BasePart:", zonePart:GetFullName())
                continue
            end

            local cf = zonePart.CFrame
            local size = zonePart.Size
            local buffer = math.min(0.1, math.min(size.X, size.Y, size.Z) * 0.1)
            local inZone = false

            local relative = cf:PointToObjectSpace(position)
            inZone = math.abs(relative.X) <= (size.X/2 + buffer)
                and math.abs(relative.Y) <= (size.Y/2 + buffer)
                and math.abs(relative.Z) <= (size.Z/2 + buffer)

            if not inZone then
                for x = -1, 1, 2 do
                    for y = -1, 1, 2 do
                        for z = -1, 1, 2 do
                            local corner = position + Vector3.new(
                                x * characterSize.X/4,
                                y * characterSize.Y/4,
                                z * characterSize.Z/4
                            )
                            relative = cf:PointToObjectSpace(corner)
                            if math.abs(relative.X) <= (size.X/2 + buffer)
                                and math.abs(relative.Y) <= (size.Y/2 + buffer)
                                and math.abs(relative.Z) <= (size.Z/2 + buffer) then
                                inZone = true
                                break
                            end
                        end
                        if inZone then break end
                    end
                    if inZone then break end
                end
            end

            if game:GetService("RunService"):IsStudio() then
                local debugPart = zonePart:FindFirstChild("DebugBounds")
                if not debugPart then
                    debugPart = Instance.new("Part")
                    debugPart.Name = "DebugBounds"
                    debugPart.Anchored = true
                    debugPart.CanCollide = false
                    debugPart.Transparency = 0.8
                    debugPart.Material = Enum.Material.Neon
                    debugPart.Parent = zonePart
                end
                debugPart.Size = size + Vector3.new(buffer * 2, buffer * 2, buffer * 2)
                debugPart.CFrame = cf
                debugPart.Color = inZone and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            end

            local playerZones = State.playerZones[player.UserId]
            local currentlyInZone = playerZones and playerZones[zoneId] or false

            if inZone and not currentlyInZone then
                self.ZoneEvents.Enter(self, player, zoneData.instance, zoneData)
            elseif not inZone and currentlyInZone then
                self.ZoneEvents.Exit(self, player, zoneData.instance, zoneData)
            end
        end
    end
end

--[[ Helper Methods ]]--
function ZoneService:GetZones(player)
    if not player then return {} end
    return State.playerZones[player.UserId] or {}
end

function ZoneService:GetRoot(player)
    if not player then return end

    local character = player.Character
    if not character then
        if not State.characterConnection then
            State.characterConnection = {}
        end

        if not State.characterConnection[player.UserId] then
            State.characterConnection[player.UserId] = player.CharacterAdded:Connect(function(char)
                if State.characterConnection[player.UserId] then
                    State.characterConnection[player.UserId]:Disconnect()
                    State.characterConnection[player.UserId] = nil
                end
            end)
        end
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    return rootPart
end

function ZoneService:CheckPlayer(player)
    if not player then return false end
    local now = tick()
    if not State.lastCheck[player.UserId] then
        State.lastCheck[player.UserId] = now
        return true
    end
    if now - State.lastCheck[player.UserId] < CHECK_INTERVAL then
        return false
    end
    State.lastCheck[player.UserId] = now
    return true
end

--[[ Zone Events ]]--
ZoneService.ZoneEvents = {
    Enter = function(self, player, zoneInstance, attributes)
        local userId = player.UserId
        if not State.playerZones[userId] then
            State.playerZones[userId] = {}
        end

        local zoneId = Services.Object:GetID(zoneInstance)
        if not zoneId or State.playerZones[userId][zoneId] then
            return
        end

        State.playerZones[userId][zoneId] = true

        local success, err = pcall(function()
            for attr, value in pairs(attributes.attributes) do
                player:SetAttribute(attr, value)
            end

            Services.Event:Fire("Zone.Enter", {
                player = player,
                zoneId = zoneId,
                zoneName = attributes.name,
                zoneType = attributes.type,
                attributes = attributes.attributes
            })

            Services.Event:FireTo(player, "Client.Zone.Enter", {
                zoneId = zoneId,
                zoneName = attributes.name,
                zoneType = attributes.type,
                attributes = attributes.attributes
            })
        end)

        if not success then
            warn(err)
            State.playerZones[userId][zoneId] = nil
        end
    end,

    Exit = function(self, player, zoneInstance, attributes)
        local userId = player.UserId
        if not State.playerZones[userId] then return end

        local zoneId = Services.Object:GetID(zoneInstance)
        if not zoneId or not State.playerZones[userId][zoneId] then return end

        local success, err = pcall(function()
            for attr, _ in pairs(attributes.attributes) do
                player:SetAttribute(attr, nil)
            end

            Services.Event:Fire("Zone.Exit", {
                player = player,
                zoneId = zoneId,
                zoneName = attributes.name,
                zoneType = attributes.type,
                attributes = attributes.attributes
            })

            Services.Event:FireTo(player, "Client.Zone.Exit", {
                zoneId = zoneId,
                zoneName = attributes.name,
                zoneType = attributes.type,
                attributes = attributes.attributes
            })
        end)

        if not success then
            warn(err)
        end

        State.playerZones[userId][zoneId] = nil
    end
}

--[[ Zone Handlers ]]--
ZoneService.ZoneHandlers = {
    Default = {
        Enter = function(player, zoneData)
        end,
        Exit = function(player, zoneData)
        end
    }
}

return ZoneService