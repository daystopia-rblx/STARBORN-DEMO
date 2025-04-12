--[[ ZoneService
    Dynamic zone management system with region-based triggers and behaviors.
    Handles zone detection, transitions, overlapping regions, and custom zone attributes.
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-11
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
    zones = {},
    players = {},
    active = {},
    check = {},
    connection = {},
    tick = {}
}

--[[ Constants ]]--
local CHECK_INTERVAL = 0.1
local DEFAULT_ZONE = "Default"
local DEBUG = true

--[[ Event Listeners ]]--
ZoneService.Listeners = {
    ["Player.Join"] = function(self, data)
        if not data.player then return end
        local player = data.player
        local userId = player.UserId

        State.players[userId] = {}
        player:SetAttribute("ZONE", DEFAULT_ZONE)

        local function CleanupZones()
            local currentZones = State.players[userId]
            if not currentZones then return end

            for zoneId, _ in pairs(currentZones) do
                local zoneData = State.zones[zoneId]
                if zoneData then
                    self.ZoneEvents.Exit(self, player, zoneData.instance, zoneData)
                end
            end

            if not next(State.players[userId]) then
                player:SetAttribute("ZONE", DEFAULT_ZONE)
            end
        end

        if not State.connection[userId] then
            State.connection[userId] = {}
        end

        State.connection[userId].removing = player.CharacterRemoving:Connect(CleanupZones)
        State.connection[userId].added = player.CharacterAdded:Connect(CleanupZones)
    end,

    ["Player.Left"] = function(self, data)
        if not data.player then return end
        local userId = data.player.UserId

        if State.connection[userId] then
            for _, connection in pairs(State.connection[userId]) do
                connection:Disconnect()
            end
            State.connection[userId] = nil
        end

        State.players[userId] = nil
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

    self:RegisterZone()
    return true
end

function ZoneService:RegisterZone(zoneId, attributes)
    if not zoneId then
        Services.Object:RegisterScanner("ZONE",
            function(instance)
                if not (instance:IsA("Model") or instance:IsA("BasePart")) then
                    return
                end

                local zoneId = Services.Object:GetID(instance)
                if not zoneId then return end

                local attributes = {
                    instance = instance,
                    name = instance:GetAttribute("NAME") or instance.Name,
                    zone = instance:GetAttribute("ZONE"),
                    attributes = {}
                }

                for name, value in pairs(instance:GetAttributes()) do
                    attributes.attributes[name] = value
                end

                self:RegisterZone(zoneId, attributes)
            end,
            function(instance)
                if not (instance:IsA("Model") or instance:IsA("BasePart")) then
                    return
                end

                local zoneId = Services.Object:GetID(instance)
                if zoneId and State.zones[zoneId] then
                    State.zones[zoneId] = nil
                    State.active[zoneId] = nil
                end
            end
        )
        return
    end

    if not attributes.instance then return end
    if not attributes.zone then return end

    State.zones[zoneId] = attributes

    if not State.active[zoneId] then
        State.active[zoneId] = true
    end
end

function ZoneService:Cleanup()
    if State.connection then
        for _, connection in pairs(State.connection) do
            connection:Disconnect()
        end
        table.clear(State.connection)
    end

    table.clear(State.players)
    table.clear(State.zones)
    table.clear(State.active)
    table.clear(State.check)
end

--[[ Zone Management ]]--
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

        for zoneId, zoneData in pairs(State.zones) do
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

            if DEBUG and game:GetService("RunService"):IsStudio() then
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

            local players = State.players[player.UserId]
            local currentlyInZone = players and players[zoneId] or false

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
    return State.players[player.UserId] or {}
end

function ZoneService:GetRoot(player)
    if not player then return end

    local character = player.Character
    if not character then
        if not State.connection then
            State.connection = {}
        end

        if not State.connection[player.UserId] then
            State.connection[player.UserId] = player.CharacterAdded:Connect(function(char)
                if State.connection[player.UserId] then
                    State.connection[player.UserId]:Disconnect()
                    State.connection[player.UserId] = nil
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
    if not State.tick[player.UserId] then
        State.check[player.UserId] = now
        return true
    end
    if now - State.check[player.UserId] < CHECK_INTERVAL then
        return false
    end
    State.check[player.UserId] = now
    return true
end

--[[ Zone Events ]]--
ZoneService.ZoneEvents = {
    Enter = function(self, player, zoneInstance, attributes)
        local userId = player.UserId
        if not State.players[userId] then
            State.players[userId] = {}
        end

        local zoneId = Services.Object:GetID(zoneInstance)
        if not zoneId or State.players[userId][zoneId] then
            return
        end

        State.players[userId][zoneId] = true

        local success, err = pcall(function()
            for attr, value in pairs(attributes.attributes) do
                player:SetAttribute(attr, value)
            end

            Services.Event:Fire("Zone.Enter", {
                player = player,
                zoneId = zoneId,
                zoneName = attributes.name,
                zone = attributes.zone,
                attributes = attributes.attributes
            })

            Services.Event:FireTo(player, "Zone.Enter", {
                zoneId = zoneId,
                zoneName = attributes.name,
                zone = attributes.zone,
                attributes = attributes.attributes
            })
        end)

        if not success then
            warn(err)
            State.players[userId][zoneId] = nil
        end
    end,

    Exit = function(self, player, zoneInstance, attributes)
        local userId = player.UserId
        if not State.players[userId] then return end

        local zoneId = Services.Object:GetID(zoneInstance)
        if not zoneId or not State.players[userId][zoneId] then return end

        local success, err = pcall(function()
            for attr, _ in pairs(attributes.attributes) do
                player:SetAttribute(attr, nil)
            end

            Services.Event:Fire("Zone.Exit", {
                player = player,
                zoneId = zoneId,
                zoneName = attributes.name,
                zone = attributes.zone,
                attributes = attributes.attributes
            })

            Services.Event:FireTo(player, "Zone.Exit", {
                zoneId = zoneId,
                zoneName = attributes.name,
                zone = attributes.zone,
                attributes = attributes.attributes
            })
        end)

        if not success then
            warn(err)
        end

        State.players[userId][zoneId] = nil

        if not next(State.players[userId]) then
             player:SetAttribute("ZONE", DEFAULT_ZONE)
             Services.Event:Fire("Zone.Change", { player = player, zone = DEFAULT_ZONE })
             Services.Event:FireTo(player, "Zone.Change", { zone = DEFAULT_ZONE })
        end
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