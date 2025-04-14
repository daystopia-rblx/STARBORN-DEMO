--[[ TradeService
    Centralizes ownership management and facilitates transfers between entities.
    Handles ownership types, permissions, and trade requests.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-14
]]
local TradeService = {}

--[[ Dependencies ]]
TradeService.Dependencies = {
    "Event",
    "Data",
    "Object",
    "Memory"
}

--[[ Events ]]
TradeService.Events = {
    Trade = true,
    Transfer = true
}

--[[ Services ]]
local Services

--[[ Ownership Types ]]
TradeService.OwnershipTypes = {
    PRIVATE = "PRIVATE",
    PUBLIC = "PUBLIC",
    RESTRICTED = "RESTRICTED",
    FACTION = "FACTION",
    TEMPORARY = "TEMPORARY"
}

--[[ State Management ]]
local State = {
    ownership = {},
    tradeRequests = {},
    pendingTransfers = {}
}

--[[ Core Functions ]]
function TradeService:Init(services)
    Services = services
    return true
end

function TradeService:Start()
    self:RegisterOwnership()
    return true
end

function TradeService:Cleanup()
    table.clear(State.ownership)
    table.clear(State.tradeRequests)
    table.clear(State.pendingTransfers)
end

--[[ Ownership Registration ]]
function TradeService:RegisterOwnership()
    Services.Object:RegisterScanner("OWNER",
        function(instance)
            local instanceId = Services.Object:GetID(instance)
            if not instanceId then return end

            local ownerId = instance:GetAttribute("OWNER")
            if not ownerId then return end

            local ownershipType = instance:GetAttribute("OWNERSHIP") or self.OwnershipTypes.PRIVATE

            State.ownership[instanceId] = {
                ownerId = ownerId,
                ownershipType = ownershipType,
                instance = instance,
                timestamp = os.time()
            }
        end,
        function(instance)
            local instanceId = Services.Object:GetID(instance)
            if instanceId and State.ownership[instanceId] then
                State.ownership[instanceId] = nil
            end
        end
    )
end

--[[ Ownership Functions ]]
function TradeService:GetOwner(instanceId): (string?, string?)
    if not instanceId then return nil, nil end

    local ownerData = State.ownership[instanceId]
    if not ownerData then
        local instance = Services.Object:GetInstance(instanceId)
        if instance then
            local ownerId = instance:GetAttribute("OWNER")
            local ownershipType = instance:GetAttribute("OWNERSHIP") or self.OwnershipTypes.PRIVATE

            if ownerId then
                State.ownership[instanceId] = {
                    ownerId = ownerId,
                    ownershipType = ownershipType,
                    instance = instance,
                    timestamp = os.time()
                }

                return ownerId, ownershipType
            end
        end
        return nil, nil
    end

    return ownerData.ownerId, ownerData.ownershipType
end

function TradeService:SetOwner(instanceId, ownerId, ownershipType)
    if not instanceId then return false end

    ownershipType = ownershipType or self.OwnershipTypes.PRIVATE

    local instance = Services.Object:GetInstance(instanceId)
    if not instance then return false end

    instance:SetAttribute("OWNER", ownerId)
    instance:SetAttribute("OWNERSHIP", ownershipType)

    State.ownership[instanceId] = {
        ownerId = ownerId,
        ownershipType = ownershipType,
        instance = instance,
        timestamp = os.time()
    }

    Services.Event:Fire("Trade.Transfer", {
        instanceId = instanceId,
        previousOwnerId = nil,
        newOwnerId = ownerId,
        ownershipType = ownershipType,
        instance = instance
    })

    return true
end

function TradeService:TransferOwnership(instanceId, newOwnerId, ownershipType): boolean
    if not (instanceId and newOwnerId) then return false end

    local currentOwnerId, currentOwnershipType = self:GetOwner(instanceId)
    if not currentOwnerId then return false end

    ownershipType = ownershipType or currentOwnershipType

    local success = self:SetOwner(instanceId, newOwnerId, ownershipType)
    if not success then return false end

    Services.Event:Fire("Trade.Transfer", {
        instanceId = instanceId,
        previousOwnerId = currentOwnerId,
        newOwnerId = newOwnerId,
        ownershipType = ownershipType
    })

    return true
end

function TradeService:GetOwned(ownerId, instanceType): {string}
    if not ownerId then return {} end

    local ownedInstances = {}

    for id, ownerData in pairs(State.ownership) do
        if ownerData.ownerId == ownerId then
            if not instanceType or
               (ownerData.instance and ownerData.instance:GetAttribute("TYPE") == instanceType) then
                table.insert(ownedInstances, id)
            end
        end
    end

    return ownedInstances
end

--[[ Trade Functions ]]
function TradeService:RequestTransfer(sourceId, targetId, instanceId, price): string
    if not (sourceId and targetId and instanceId) then return nil end

    local ownerId = self:GetOwner(instanceId)
    if ownerId ~= sourceId then return nil end

    local requestId = Services.Object:GenerateGUID()

    State.tradeRequests[requestId] = {
        sourceId = sourceId,
        targetId = targetId,
        instanceId = instanceId,
        price = price or 0,
        timestamp = os.time(),
        status = "PENDING"
    }

    Services.Event:Fire("Trade.Trade", {
        requestId = requestId,
        sourceId = sourceId,
        targetId = targetId,
        instanceId = instanceId,
        price = price
    })

    return requestId
end

function TradeService:AcceptRequest(requestId): boolean
    local request = State.tradeRequests[requestId]
    if not request or request.status ~= "PENDING" then return false end

    local success = self:TransferOwnership(request.instanceId, request.targetId)
    if not success then return false end

    request.status = "COMPLETED"
    request.completedAt = os.time()

    Services.Event:Fire("Trade.Trade", {
        requestId = requestId,
        sourceId = request.sourceId,
        targetId = request.targetId,
        instanceId = request.instanceId,
        price = request.price
    })

    return true
end

function TradeService:RejectRequest(requestId, reason): boolean
    local request = State.tradeRequests[requestId]
    if not request or request.status ~= "PENDING" then return false end

    request.status = "REJECTED"
    request.rejectedAt = os.time()
    request.rejectReason = reason

    Services.Event:Fire("Trade.Trade", {
        requestId = requestId,
        sourceId = request.sourceId,
        targetId = request.targetId,
        instanceId = request.instanceId,
        reason = reason
    })

    return true
end

function TradeService:GetRequests(entityId): {[string]: any}
    if not entityId then return {} end

    local pendingRequests = {}

    for id, request in pairs(State.tradeRequests) do
        if request.status == "PENDING" and
           (request.sourceId == entityId or request.targetId == entityId) then
            pendingRequests[id] = request
        end
    end

    return pendingRequests
end

return TradeService