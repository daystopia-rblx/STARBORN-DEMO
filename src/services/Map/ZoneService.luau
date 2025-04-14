--[[ ZoneService
    Dynamic zone management system with region-based triggers and behaviors.
    Handles zone detection, transitions, overlapping regions, and custom zone attributes.
    @author @Daystopia
    @version 1.0.3
    @date 2025-04-14
]]
local ZoneService = {}

ZoneService.Dependencies = {
    "Event",
    "Data",
    "Object",
    "Memory",
    "Time",
    "Trade"
}

ZoneService.Events = {
    Enter = true,
    Exit = true,
    Change = true,
    Lock = true,
    Unlock = true,
    Open = true,
    Close = true,
    Trespass = true
}

ZoneService.Modules = {
    "Zone"
}

local Services
local Modules

--[[ State Management ]]--
local State = {
    zones = {},
    players = {},
    active = {},
    check = {},
    connection = {},
    locations = {}
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
    end,

    ["Time.Update"] = function(self, data)
        self:UpdateAvailability(data.hour)
    end,

    ["Trade.Transfer"] = function(self, data)
        local locationId = data.instanceId
        local newOwnerId = data.newOwnerId
        local ownershipType = data.ownershipType

        if State.locations[locationId] then
            local locationInstance = State.locations[locationId].instance or Services.Object:GetInstance(locationId)
            if locationInstance then
                locationInstance:SetAttribute("OWNER", newOwnerId)
                if ownershipType then
                    locationInstance:SetAttribute("OWNERSHIP", ownershipType)
                end
            end
        end
    end
}

--[[ Core Methods ]]--
function ZoneService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function ZoneService:Start()
    game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateZones()
    end)

    self:RegisterZone()
    self:RegisterLocation()
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

function ZoneService:RegisterLocation()
    Services.Object:RegisterScanner("TYPE",
        function(instance)
            local locationId = Services.Object:GetID(instance)
            if not locationId then return end

            local locationType = instance:GetAttribute("TYPE")
            if not locationType then return end

            local openHour = instance:GetAttribute("OPEN_HOUR")
            local closeHour = instance:GetAttribute("CLOSE_HOUR")
            local isAutoLockable = true

            if openHour == 0 and closeHour == 24 then
                isAutoLockable = false
            end

            State.locations[locationId] = {
                instance = instance,
                isLocked = instance:GetAttribute("LOCKED") or false,
                openHour = openHour,
                closeHour = closeHour,
                storeId = instance:GetAttribute("ID"),
                isAutoLockable = isAutoLockable
            }

            local ownerId = instance:GetAttribute("OWNER")
            local ownershipType = instance:GetAttribute("OWNERSHIP")

            if ownerId then
                Services.Trade:SetOwner(locationId, ownerId, ownershipType)
            end
        end,
        function(instance)
            local locationId = Services.Object:GetID(instance)
            if locationId and State.locations[locationId] then
                State.locations[locationId] = nil
            end
        end
    )
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
    table.clear(State.locations)
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

--[[ Location Interaction ]]--
function ZoneService:EnterLocation(player, locationId): (boolean, string?)
    if not player or not locationId then return false, "Invalid parameters" end

    local runtimeData = State.locations[locationId]
    if not runtimeData then return false, "Location runtime data not found" end

    local locationInstance = runtimeData.instance or Services.Object:GetInstance(locationId)
    if not locationInstance then return false, "Location instance not found" end

    local currentHour = Services.Time:GetTime().hour
    local isOpen = Modules.Zone.CheckOpen(
        {hours = {open = runtimeData.openHour, close = runtimeData.closeHour}},
        currentHour
    )

    local isTrespassing = false
    local trespassReason = nil

    if runtimeData.isLocked then
        isTrespassing = true
        trespassReason = "locked"
        return false, "Location is locked"
    end

    if not isOpen then
        isTrespassing = true
        trespassReason = "closed"
    end

    local ownerId, ownershipType = Services.Trade:GetOwner(locationId)
    if ownerId and ownerId ~= player.UserId then
        local canAccess, accessReason = Services.Trade:CanAccess(player.UserId, locationId)

        if not canAccess then
            isTrespassing = true
            trespassReason = accessReason or "unauthorized"
        end
    end

    if isTrespassing then
        local location = self:GetLocation(locationId)
        Services.Event:Fire("Zone.Trespass", {
            player = player,
            locationId = locationId,
            locationType = locationInstance:GetAttribute("TYPE"),
            reason = trespassReason,
            securityLevel = location.securityLevel,
            factionId = location.factionId,
            ownerId = ownerId
        })
    end

    Services.Event:Fire("Zone.Enter", {
        player = player,
        locationId = locationId,
        locationType = locationInstance:GetAttribute("TYPE"),
        isTrespassing = isTrespassing,
        trespassReason = trespassReason
    })

    return true
end

function ZoneService:ExitLocation(player, locationId): boolean
    if not player or not locationId then return false end

    Services.Event:Fire("Zone.Exit", {
        player = player,
        locationId = locationId
    })

    return true
end

function ZoneService:LockLocation(locationId, locked): boolean
    local runtimeData = State.locations[locationId]
    if not runtimeData then return false end

    runtimeData.isLocked = locked

    local locationInstance = runtimeData.instance or Services.Object:GetInstance(locationId)
    if locationInstance then
        locationInstance:SetAttribute("LOCKED", locked)
    end

    local eventName = locked and "Zone.Lock" or "Zone.Unlock"
    Services.Event:Fire(eventName, {
        locationId = locationId,
        locked = locked
    })

    return true
end

function ZoneService:UpdateAvailability(currentHour)
    for locId, location in pairs(State.locations) do
        if location.openHour and location.closeHour then
            local isOpen = Modules.Zone.CheckOpen(
                {hours = {open = location.openHour, close = location.closeHour}},
                currentHour
            )

            local locationInstance = location.instance or Services.Object:GetInstance(locId)
            if locationInstance then
                local previousState = locationInstance:GetAttribute("OPEN")
                locationInstance:SetAttribute("OPEN", isOpen)

                if previousState ~= isOpen and previousState ~= nil then
                    if location.isAutoLockable then
                        self:LockLocation(locId, not isOpen)

                        local eventName = isOpen and "Zone.Open" or "Zone.Close"
                        Services.Event:Fire(eventName, {
                            locationId = locId,
                            locationType = locationInstance:GetAttribute("TYPE"),
                            hour = currentHour
                        })
                    end
                end
            end
        end
    end
end

function ZoneService:GetLocation(locationId)
    if not locationId then return nil end

    local runtimeData = State.locations[locationId]
    if not runtimeData then return nil end

    local locationInstance = runtimeData.instance or Services.Object:GetInstance(locationId)
    if not locationInstance then return nil end

    local ownerId, ownershipType = Services.Trade:GetOwner(locationId)

    local location = {
        id = locationId,
        instance = locationInstance,
        isLocked = runtimeData.isLocked,
        securityLevel = locationInstance:GetAttribute("SECURITY_LEVEL") or 1,
        lockLevel = locationInstance:GetAttribute("LOCK_LEVEL") or 1,
        type = locationInstance:GetAttribute("TYPE"),
        subType = locationInstance:GetAttribute("LOCATION_SUBTYPE"),
        ownerId = ownerId,
        ownershipType = ownershipType,
        factionId = locationInstance:GetAttribute("FACTION"),
        openHour = runtimeData.openHour,
        closeHour = runtimeData.closeHour
    }

    return location
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
    if not State.check[player.UserId] then
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