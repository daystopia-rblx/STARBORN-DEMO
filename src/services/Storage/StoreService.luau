--[[ StoreService
    Manages store functionalities, inventories, and commerce mechanics.
    Handles store types, dynamic inventories, and buying/selling operations.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-11
]]
local StoreService = {}

--[[ Dependencies ]]
StoreService.Dependencies = {
    "Event",
    "Object",
    "Data",
    "Economy",
    "Inventory",
    "Location",
    "Time"
}

--[[ Modules ]]
StoreService.Modules = {
    "Object",
    "Location",
    "Store"
}

--[[ Events ]]
StoreService.Events = {
    Purchase = true,
    Sell = true,
    Restock = true,
    Browse = true
}

--[[ Types ]]
type StoreInventory = {
    storeId: string,
    items: {[string]: {
        itemId: string,
        price: number,
        quantity: number,
        discount: number?,
        metadata: {[string]: any}?
    }},
    lastRestockedDay: number,
    nextRestockDay: number
}

local Services
local Modules

--[[ State ]]
local State = {
    stores = {},
    inventories = {}
}

--[[ Event Listeners ]]
StoreService.Listeners = {
    ["Location.Open"] = function(self, data)
        self:OpenStore(data.locationId, data.locationType)
    end,

    ["Location.Close"] = function(self, data)
        self:CloseStore(data.locationId, data.locationType)
    end,

    ["Time.Update"] = function(self, data)
        self:CheckRestocks(data.hour)
    end
}

--[[ Core Functions ]]
function StoreService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function StoreService:Start()
    self:RegisterStore()
    return true
end

--[[ Store Registration ]]
function StoreService:RegisterStore()
    Services.Object:RegisterScanner("STORE_TYPE",
        function(instance)
            local storeId = Services.Object:GetID(instance)
            if not storeId then return end

            local storeType = instance:GetAttribute("STORE_TYPE")
            if not storeType then return end

            local locationId = instance:GetAttribute("LOCATION_ID")
            local merchantId = instance:GetAttribute("MERCHANT_ID")

            State.stores[storeId] = {
                instance = instance,
                storeType = storeType,
                locationId = locationId,
                merchantId = merchantId,
                name = instance:GetAttribute("NAME") or "Store",
                isGuildLocked = instance:GetAttribute("GUILD_LOCKED") or false,
                requiredGuild = instance:GetAttribute("REQUIRED_GUILD"),
                minReputation = instance:GetAttribute("MIN_REPUTATION") or 0
            }

            if not State.inventories[storeId] then
                self:GenerateInventory(storeId)
            end
        end,
        function(instance)
            local storeId = Services.Object:GetID(instance)
            if storeId and State.stores[storeId] then
                State.stores[storeId] = nil
            end
        end
    )
end

function StoreService:OpenStore(locationId, locationType)
    for storeId, store in pairs(State.stores) do
        if store.locationId == locationId then
            if not State.inventories[storeId] then
                self:GenerateInventory(storeId)
            end
        end
    end
end

function StoreService:CloseStore(locationId, locationType)
    for storeId, store in pairs(State.stores) do
        if store.locationId == locationId then
            local inventory = State.inventories[storeId]
            if inventory then
                Services.Event:Fire("Store.Close", {
                    storeId = storeId,
                    storeType = store.storeType,
                    locationId = locationId
                })
            end
        end
    end
end

--[[ Inventory Management ]]
function StoreService:GenerateInventory(storeId)
    local store = State.stores[storeId]
    if not store then return end

    local storeType = store.storeType
    local currentGameDay = Services.Time:GetStart()
    local restockInterval = Modules.Store:GetRestock(storeType)

    local inventory = {
        storeId = storeId,
        items = {},
        lastRestockedDay = currentGameDay,
        nextRestockDay = currentGameDay + restockInterval
    }

    local storeItems = Modules.Store:GetItems(storeType)
    for _, itemData in ipairs(storeItems) do
        local quantity = math.random(itemData.minQuantity or 1, itemData.maxQuantity or 5)

        local basePrice = itemData.price
        local variance = math.random(-10, 10) / 100
        local finalPrice = math.max(1, math.floor(basePrice * (1 + variance)))

        inventory.items[itemData.itemId] = {
            itemId = itemData.itemId,
            price = finalPrice,
            quantity = quantity,
            discount = itemData.discount,
            metadata = itemData.metadata
        }
    end

    State.inventories[storeId] = inventory

    Services.Event:Fire("Store.Restock", {
        storeId = storeId,
        storeType = storeType,
        itemCount = table.getn(inventory.items)
    })

    return inventory
end

function StoreService:CheckRestocks(currentHour)
    local currentGameDay = Services.Time:GetStart()

    for storeId, inventory in pairs(State.inventories) do
        if inventory.nextRestockDay <= currentGameDay then
            self:GenerateInventory(storeId)
        end
    end
end

--[[ Store Operations ]]
function StoreService:BrowseStore(playerId, storeId)
    local store = State.stores[storeId]
    if not store then
        return false, "Store not found"
    end

    local inventory = State.inventories[storeId]
    if not inventory then
        return false, "Inventory not found"
    end

    if store.locationId then
        local locationData = Services.Location:GetOwner(store.locationId)
        local locationInstance = Services.Object:GetInstance(store.locationId)

        if locationInstance and not locationInstance:GetAttribute("OPEN") then
            return false, "Store is closed"
        end
    end

    if store.isGuildLocked and store.requiredGuild then
        local playerGuild = Services.Data:GetData(playerId, "PlayerData", "guild", "affiliation")
        if playerGuild ~= store.requiredGuild then
            return false, "Guild membership required"
        end

        local reputation = Services.Data:GetData(playerId, "PlayerData", "guild", "reputation") or 0
        if reputation < store.minReputation then
            return false, "Insufficient guild reputation"
        end
    end

    Services.Event:Fire("Store.Browse", {
        playerId = playerId,
        storeId = storeId,
        storeType = store.storeType,
        inventory = inventory
    })

    return true, inventory
end

function StoreService:PurchaseItem(playerId, storeId, itemId, quantity)
    quantity = quantity or 1

    if quantity <= 0 then
        return false, "Invalid quantity"
    end

    local store = State.stores[storeId]
    if not store then
        return false, "Store not found"
    end

    local inventory = State.inventories[storeId]
    if not inventory then
        return false, "Inventory not found"
    end

    local item = inventory.items[itemId]
    if not item then
        return false, "Item not available"
    end

    if item.quantity < quantity then
        return false, "Not enough stock"
    end

    local totalCost = item.price * quantity
    if item.discount then
        totalCost = math.floor(totalCost * (1 - (item.discount / 100)))
    end

    local success, error = Services.Economy:RemoveCurrency(playerId, totalCost, {
        type = "store_purchase",
        storeId = storeId,
        itemId = itemId,
        quantity = quantity
    })

    if not success then
        return false, error or "Insufficient funds"
    end

    success = Services.Inventory:AddItem(playerId, itemId, quantity)
    if not success then
        Services.Economy:AddCurrency(playerId, totalCost, {
            type = "purchase_refund",
            storeId = storeId,
            itemId = itemId,
            quantity = quantity
        })
        return false, "Failed to add item to inventory"
    end

    item.quantity = item.quantity - quantity
    if item.quantity <= 0 then
        inventory.items[itemId] = nil
    end

    if store.merchantId then
        Services.Economy:AddCurrency(store.merchantId, math.floor(totalCost * 0.8), {
            type = "merchant_sale",
            storeId = storeId,
            itemId = itemId,
            quantity = quantity
        })
    end

    Services.Event:Fire("Store.Purchase", {
        playerId = playerId,
        storeId = storeId,
        storeType = store.storeType,
        itemId = itemId,
        quantity = quantity,
        cost = totalCost
    })

    return true, {
        itemId = itemId,
        quantity = quantity,
        cost = totalCost
    }
end

function StoreService:SellItem(playerId, storeId, itemId, quantity)
    quantity = quantity or 1

    if quantity <= 0 then
        return false, "Invalid quantity"
    end

    local store = State.stores[storeId]
    if not store then
        return false, "Store not found"
    end

    if store.storeType:upper() == "GUILD" or store.storeType:upper() == "BLOOD" then
        return false, "This store doesn't buy items"
    end

    if not Services.Inventory:GetItem(playerId, itemId, quantity) then
        return false, "You don't have enough of this item"
    end

    local baseValue = 10
    local itemInstance = Services.Object:GetInstance(itemId)

    if itemInstance then
        baseValue = itemInstance:GetAttribute("VALUE") or 10
    end

    local sellValue = math.floor(baseValue * 0.5 * quantity)

    local success = Services.Inventory:RemoveItem(playerId, itemId, quantity)
    if not success then
        return false, "Failed to remove item from inventory"
    end

    Services.Economy:AddCurrency(playerId, sellValue, {
        type = "item_sold",
        storeId = storeId,
        itemId = itemId,
        quantity = quantity
    })

    Services.Event:Fire("Store.Sell", {
        playerId = playerId,
        storeId = storeId,
        storeType = store.storeType,
        itemId = itemId,
        quantity = quantity,
        value = sellValue
    })

    return true, {
        itemId = itemId,
        quantity = quantity,
        value = sellValue
    }
end

return StoreService
