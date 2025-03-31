--[[ InventoryService
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local InventoryService = {}

InventoryService.Dependencies = {
    "Data",
    "Event",
    "Stat"
}

InventoryService.Modules = {
    "Equipment"
}

InventoryService.Events = {
    Equip = { validate = true },
    Unequip = { validate = true },
    Add = { validate = true },
    Remove = { validate = true }
}

local Services
local Modules

--[[ State Management ]]
local State = {
    equipment = setmetatable({}, { __mode = "k" }),
    inventories = setmetatable({}, { __mode = "k" })
}

--[[ Core Functions ]]
function InventoryService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function InventoryService:Cleanup()
    table.clear(State.equipment)
    table.clear(State.inventories)
end

--[[ Inventory Functions ]]
function InventoryService:AddItem(entity: any, itemId: string, quantity: number?): (boolean, string?)
    if not (entity and itemId) then return false, "Invalid input" end
    quantity = quantity or 1

    if quantity <= 0 then return false, "Invalid quantity" end

    State.inventories[entity] = State.inventories[entity] or {}
    local inventory = State.inventories[entity]

    local template = Modules.Equipment.Templates[itemId]
    if not template then return false, "Invalid item" end

    inventory[itemId] = (inventory[itemId] or 0) + quantity

    Services.Event:Fire("Inventory.Add", {
        entity = entity,
        itemId = itemId,
        quantity = quantity,
        newTotal = inventory[itemId]
    })

    return true
end

function InventoryService:RemoveItem(entity: any, itemId: string, quantity: number?): (boolean, string?)
    if not (entity and itemId) then return false, "Invalid input" end
    quantity = quantity or 1

    if quantity <= 0 then return false, "Invalid quantity" end

    local inventory = State.inventories[entity]
    if not inventory then return false, "No inventory found" end

    local currentQuantity = inventory[itemId]
    if not currentQuantity then return false, "Item not found" end

    if currentQuantity < quantity then return false, "Insufficient quantity" end

    inventory[itemId] = currentQuantity - quantity
    if inventory[itemId] <= 0 then
        inventory[itemId] = nil
    end

    Services.Event:Fire("Inventory.Remove", {
        entity = entity,
        itemId = itemId,
        quantity = quantity,
        newTotal = inventory[itemId]
    })

    return true
end

function InventoryService:GetItem(entity: any, itemId: string, quantity: number?): boolean
    if not (entity and itemId) then return false end
    quantity = quantity or 1

    local inventory = State.inventories[entity]
    if not inventory then return false end

    return (inventory[itemId] or 0) >= quantity
end

function InventoryService:GetInventory(entity: any): {[string]: number}
    if not entity then return {} end
    return State.inventories[entity] or {}
end

function InventoryService:ClearInventory(entity: any): boolean
    if not entity then return false end

    if State.inventories[entity] then
        table.clear(State.inventories[entity])
        State.inventories[entity] = nil
        return true
    end

    return false
end

--[[ Equipment Functions ]]
function InventoryService:EquipItem(entity: any, itemId: string, slot: string): (boolean, any?)
    if not (entity and itemId and slot) then return false, "Invalid input" end

    local template = Modules.Equipment.Templates[itemId]
    if not template then return false, "Invalid item" end

    if template.slot ~= slot then return false, "Invalid slot" end

    if template.requirements then
        if template.requirements.level and entity:GetAttribute("LEVEL") < template.requirements.level then
            return false, "Level requirement not met"
        end

        if template.requirements.stats then
            for stat, required in pairs(template.requirements.stats) do
                if (entity:GetAttribute(stat) or 0) < required then
                    return false, "Stat requirements not met"
                end
            end
        end
    end

    local currentItems = State.equipment[entity] or {}
    if currentItems[slot] then
        self:UnequipItem(entity, slot)
    end

    local item = table.clone(template)
    item.owner = entity
    item.equipped = true

    if item.stats then
        for stat, value in pairs(item.stats) do
            Services.Stat:ModifyStat(entity, stat, {
                operation = "add",
                value = value,
                metadata = {
                    source = "equipment",
                    item = itemId
                }
            })
        end
    end

    State.equipment[entity] = State.equipment[entity] or {}
    State.equipment[entity][slot] = item

    Services.Event:Fire("Inventory.Equip", {
        entity = entity,
        item = item,
        slot = slot
    })

    return true, item
end

function InventoryService:UnequipItem(entity: any, slot: string): boolean
    if not (entity and slot) then return false end

    local items = State.equipment[entity]
    if not items then return false end

    local item = items[slot]
    if not item then return false end

    if item.stats then
        for stat, value in pairs(item.stats) do
            Services.Stat:ModifyStat(entity, stat, {
                operation = "subtract",
                value = value,
                metadata = {
                    source = "equipment_remove",
                    item = item.id
                }
            })
        end
    end

    items[slot] = nil
    if not next(items) then
        State.equipment[entity] = nil
    end

    Services.Event:Fire("Inventory.Unequip", {
        entity = entity,
        item = item,
        slot = slot
    })

    return true
end

function InventoryService:GetEquip(entity: any, slot: string): any?
    local items = State.equipment[entity]
    if not items then return nil end
    return items[slot]
end

function InventoryService:GetEquipment(entity: any): {[string]: any}
    return State.equipment[entity] or {}
end

return InventoryService