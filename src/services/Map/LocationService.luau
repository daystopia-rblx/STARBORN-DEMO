--[[ LocationService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local LocationService = {}

--[[ Dependencies ]]
LocationService.Dependencies = {
    "Event",
    "Data",
    "Object",
    "Memory",
    "Time",
    "Crime"
}

--[[ Modules ]]
LocationService.Modules = {
    "Location"
}

--[[ Events ]]
LocationService.Events = {
    Enter = true,
    Exit = true,
    Lock = true,
    Unlock = true,
    Open = true,
    Close = true,
    Trespass = true
}

local Services
local Modules

--[[ State ]]
local State = {
    locations = {}
}

--[[ Event Listeners ]]
LocationService.Listeners = {
    ["Time.Update"] = function(self, data)
        self:UpdateAvailability(data.hour)
    end
}

--[[ Core Functions ]]
function LocationService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function LocationService:Start()
    self:RegisterLocation()
    return true
end

--[[ Location Registration ]]
function LocationService:RegisterLocation()
    Services.Object:RegisterScanner("LOCATION_TYPE",
        function(instance)
            local locationId = Services.Object:GetID(instance)
            if not locationId then return end

            local locationType = instance:GetAttribute("LOCATION_TYPE")
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
                ownerId = instance:GetAttribute("OWNER"),
                ownershipType = instance:GetAttribute("OWNERSHIP"),
                isAutoLockable = isAutoLockable
            }
        end,
        function(instance)
            local locationId = Services.Object:GetID(instance)
            if locationId and State.locations[locationId] then
                State.locations[locationId] = nil
            end
        end
    )
end

--[[ Location Interaction ]]
function LocationService:EnterLocation(player, locationId): (boolean, string?)
    if not player or not locationId then return false, "Invalid parameters" end

    local runtimeData = State.locations[locationId]
    if not runtimeData then return false, "Location runtime data not found" end

    local locationInstance = runtimeData.instance or Services.Object:GetInstance(locationId)
    if not locationInstance then return false, "Location instance not found" end

    local currentHour = Services.Time:GetTime().hour
    local isOpen = Modules.Location.CheckOpen(
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

    local ownerId, ownershipType = self:GetOwner(locationId)
    if ownerId and ownerId ~= player.UserId then
        local playerReputation = Services.Memory:GetReputation(player, ownerId)
        local reputationLevel = Services.Memory:GetReputationLevel(player, ownerId)

        if ownershipType == "PRIVATE" or (ownershipType == "RESTRICTED" and reputationLevel == "HOSTILE" or reputationLevel == "SUSPICIOUS") then
            isTrespassing = true
            trespassReason = "unauthorized"
        end
    end

    if isTrespassing then
        local location = self:GetLocation(locationId)
        Services.Event:Fire("Location.Trespass", {
            player = player,
            locationId = locationId,
            locationType = locationInstance:GetAttribute("LOCATION_TYPE"),
            reason = trespassReason
        })

        if Services.Crime then
            Services.Crime:DetectPlayer(player, {
                id = locationId,
                type = "LOCATION",
                locationType = locationInstance:GetAttribute("LOCATION_TYPE"),
                securityLevel = location.securityLevel,
                factionId = location.factionId,
                ownerId = location.ownerId
            }, nil, "TRESPASSING")
        end
    end

    Services.Event:Fire("Location.Enter", {
        player = player,
        locationId = locationId,
        locationType = locationInstance:GetAttribute("LOCATION_TYPE"),
        isTrespassing = isTrespassing,
        trespassReason = trespassReason
    })

    return true
end

function LocationService:ExitLocation(player, locationId): boolean
    if not player or not locationId then return false end

    Services.Event:Fire("Location.Exit", {
        player = player,
        locationId = locationId
    })

    return true
end

function LocationService:LockLocation(locationId, locked): boolean
    local runtimeData = State.locations[locationId]
    if not runtimeData then return false end

    runtimeData.isLocked = locked

    local locationInstance = runtimeData.instance or Services.Object:GetInstance(locationId)
    if locationInstance then
        locationInstance:SetAttribute("LOCKED", locked)
    end

    local eventName = locked and "Location.Lock" or "Location.Unlock"
    Services.Event:Fire(eventName, {
        locationId = locationId,
        locked = locked
    })

    return true
end

--[[ Location Status ]]
function LocationService:UpdateAvailability(currentHour)
    for locId, location in pairs(State.locations) do
        if location.openHour and location.closeHour then
            local isOpen = Modules.Location.CheckOpen(
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

                        local eventName = isOpen and "Location.Open" or "Location.Close"
                        Services.Event:Fire(eventName, {
                            locationId = locId,
                            locationType = locationInstance:GetAttribute("LOCATION_TYPE"),
                            hour = currentHour
                        })
                    end
                end
            end
        end
    end
end

function LocationService:GetOwner(locationId): (string?, string?)
    local runtimeData = State.locations[locationId]
    if not runtimeData then return nil, nil end

    return runtimeData.ownerId, runtimeData.ownershipType
end

function LocationService:GetLocation(locationId)
    if not locationId then return nil end

    local runtimeData = State.locations[locationId]
    if not runtimeData then return nil end

    local locationInstance = runtimeData.instance or Services.Object:GetInstance(locationId)
    if not locationInstance then return nil end

    local location = {
        id = locationId,
        instance = locationInstance,
        isLocked = runtimeData.isLocked,
        securityLevel = locationInstance:GetAttribute("SECURITY_LEVEL") or 1,
        lockLevel = locationInstance:GetAttribute("LOCK_LEVEL") or 1,
        type = locationInstance:GetAttribute("LOCATION_TYPE"),
        subType = locationInstance:GetAttribute("LOCATION_SUBTYPE"),
        ownerId = runtimeData.ownerId,
        factionId = locationInstance:GetAttribute("FACTION"),
        openHour = runtimeData.openHour,
        closeHour = runtimeData.closeHour
    }

    return location
end

return LocationService