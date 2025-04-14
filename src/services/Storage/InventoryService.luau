--[[ InventoryService
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-14
]]
local InventoryService = {}

InventoryService.Dependencies = {
    "Data",
    "Event",
    "Stat",
    "Object",
    "Trade"
}

InventoryService.Modules = {
    "Object",
    "Weapon",
    "Equipment",
    "Craft",
    "Food"
}

InventoryService.Events = {
    Equip = { validate = true },
    Unequip = { validate = true },
    Add = { validate = true },
    Remove = { validate = true }
}

local Services
local Modules

local State = {
    equipment = setmetatable({}, { __mode = "k" }),
    inventories = setmetatable({}, { __mode = "k" })
}

InventoryService.Listeners = {
    ["Trade.Transfer"] = function(self, data)
        local instanceId = data.instanceId
        local newOwnerId = data.newOwnerId

        for entity, inventory in pairs(State.inventories) do
            if inventory[instanceId] then
                inventory[instanceId].metadata = inventory[instanceId].metadata or {}
                inventory[instanceId].metadata.lastTransfer = os.time()
                break
            end
        end
    end
}

--[[ Core Functions ]]
function InventoryService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function InventoryService:Start()
    return true
end

function InventoryService:Cleanup()
    table.clear(State.equipment)
    table.clear(State.inventories)
end

--[[ Utility Functions ]]
function InventoryService:GetTemplate(itemId: string): (any?, string?)
    if not itemId then return nil, nil end

    local itemTemplate = nil
    local sourceModule = nil

    for moduleName, moduleObj in pairs(Modules) do
        if moduleObj.Templates and moduleObj.Templates[itemId] then
            itemTemplate = moduleObj.Templates[itemId]
            sourceModule = moduleName
            break
        elseif moduleObj.Templates then
            for _, category in pairs(moduleObj.Templates) do
                if type(category) == "table" and category[itemId] then
                    itemTemplate = category[itemId]
                    sourceModule = moduleName
                    break
                end
            end
            if itemTemplate then break end
        end

        local getterFn = moduleObj["Get" .. moduleName]
        if type(getterFn) == "function" then
            local result = getterFn(itemId)
            if result then
                itemTemplate = result
                sourceModule = moduleName
                break
            end
        end
    end

    return itemTemplate, sourceModule
end

--[[ Inventory Functions ]]
function InventoryService:AddItem(entity: any, itemId: string, quantity: number?, owner: any?, metadata: {[string]: any}?): (boolean, string?)
    if not (entity and itemId) then return false, "Invalid input" end
    quantity = quantity or 1

    if quantity <= 0 then return false, "Invalid quantity" end

    State.inventories[entity] = State.inventories[entity] or {}
    local inventory = State.inventories[entity]

    local itemTemplate, sourceModule = self:GetTemplate(itemId)
    if not itemTemplate then return false, "Invalid item" end

    if not inventory[itemId] then
        inventory[itemId] = {
            quantity = quantity,
            metadata = metadata or {}
        }
    else
        inventory[itemId].quantity += quantity
        if metadata then
            inventory[itemId].metadata = inventory[itemId].metadata or {}
            for k, v in pairs(metadata) do
                if inventory[itemId].metadata[k] == nil then
                    inventory[itemId].metadata[k] = v
                end
            end
        end
    end

    if type(entity) == "userdata" and entity:IsA("Player") and owner then
        local ownerId = type(owner) == "userdata" and owner:IsA("Player") and owner.UserId or owner
        Services.Trade:SetOwner(itemId, ownerId, "PRIVATE")
    end

    local ownerId = Services.Trade:GetOwner(itemId)

    Services.Event:Fire("Inventory.Add", {
        entity = entity,
        itemId = itemId,
        quantity = quantity,
        newTotal = inventory[itemId].quantity,
        moduleSource = sourceModule,
        owner = ownerId,
        metadata = inventory[itemId].metadata
    })

    return true
end

function InventoryService:RemoveItem(entity: any, itemId: string, quantity: number?): (boolean, string?)
    if not (entity and itemId) then return false, "Invalid input" end
    quantity = quantity or 1

    if quantity <= 0 then return false, "Invalid quantity" end

    local inventory = State.inventories[entity]
    if not inventory then return false, "No inventory found" end

    local itemData = inventory[itemId]
    if not itemData then return false, "Item not found" end

    local currentQuantity = itemData.quantity
    if currentQuantity < quantity then return false, "Insufficient quantity" end

    itemData.quantity = currentQuantity - quantity
    local remainingMetadata = itemData.metadata

    local ownerId = Services.Trade:GetOwner(itemId)

    if itemData.quantity <= 0 then
        inventory[itemId] = nil
    end

    Services.Event:Fire("Inventory.Remove", {
        entity = entity,
        itemId = itemId,
        quantity = quantity,
        newTotal = itemData.quantity > 0 and itemData.quantity or 0,
        owner = ownerId,
        metadata = remainingMetadata
    })

    return true
end

function InventoryService:GetItem(entity: any, itemId: string, quantity: number?): boolean
    if not (entity and itemId) then return false end
    quantity = quantity or 1

    local inventory = State.inventories[entity]
    if not inventory or not inventory[itemId] then return false end

    return (inventory[itemId].quantity or 0) >= quantity
end

function InventoryService:GetInventory(entity: any): {[string]: any}
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

function InventoryService:UseItem(entity: any, itemId: string, variant: string?): (boolean, string?)
    if not (entity and itemId) then return false, "Invalid input" end

    if not self:GetItem(entity, itemId, 1) then
        return false, "Item not in inventory"
    end

    local itemTemplate, sourceModule = self:GetTemplate(itemId)
    if not itemTemplate then return false, "Invalid item" end

    local variantData = nil
    local defaults = {}

    if itemTemplate.defaults then
        defaults = itemTemplate.defaults
        if variant and itemTemplate.variants and itemTemplate.variants[variant] then
            variantData = itemTemplate.variants[variant]
        end
    end

    local success = false
    local effects = {}
    local buffList = {}

    if defaults.statEffects then
        for stat, value in pairs(defaults.statEffects) do
            local finalValue = value
            if variantData and variantData.statEffects and variantData.statEffects[stat] then
                finalValue = variantData.statEffects[stat]
            end

            local statKey = stat:upper()
            local duration = defaults.duration
            if variantData and variantData.duration then
                duration = variantData.duration
            end

            local isInstantEffect = not duration or duration <= 0

            if isInstantEffect then
                Services.Stat:ModifyStat(entity, statKey, {
                    operation = "add",
                    value = finalValue,
                    metadata = {
                        source = "item_use",
                        item = itemId,
                        variant = variant
                    }
                })

                table.insert(effects, {
                    stat = statKey,
                    value = finalValue,
                    type = "instant"
                })
                success = true
            else
                if entity.UserId then
                    local buffId = itemId .. "_" .. statKey
                    local multiplier = 1 + (finalValue / 100)

                    Services.Stat:ApplyBuff(tostring(entity.UserId), statKey, multiplier, buffId, duration)

                    table.insert(effects, {
                        stat = statKey,
                        value = finalValue,
                        duration = duration,
                        type = "buff"
                    })

                    table.insert(buffList, {
                        id = buffId,
                        stat = statKey,
                        multiplier = multiplier,
                        duration = duration
                    })
                    success = true
                end
            end
        end
    elseif itemTemplate.onUse and type(itemTemplate.onUse) == "function" then
        local useSuccess, result = pcall(itemTemplate.onUse, entity)
        if useSuccess then
            effects = result
            success = true
        else
            return false, "Error using item"
        end
    elseif itemTemplate.effects then
        for effectType, effectData in pairs(itemTemplate.effects) do
            if effectType == "stats" then
                for stat, value in pairs(effectData) do
                    Services.Stat:ModifyStat(entity, stat, {
                        operation = effectData.operation or "add",
                        value = value,
                        metadata = {
                            source = "item_use",
                            item = itemId
                        }
                    })

                    table.insert(effects, {
                        stat = stat,
                        value = value,
                        operation = effectData.operation or "add"
                    })
                    success = true
                end
            end
        end
    elseif itemTemplate.usable then
        success = true
        effects = { message = "Item used" }
    else
        return false, "Item cannot be used"
    end

    if success then
        self:RemoveItem(entity, itemId, 1)

        local ownerId = Services.Trade:GetOwner(itemId)

        Services.Event:Fire("Inventory.Use", {
            entity = entity,
            itemId = itemId,
            variant = variant,
            moduleSource = sourceModule,
            effects = effects,
            buffs = buffList,
            owner = ownerId
        })
    end

    return success, { effects = effects, buffs = buffList }
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

    local ownerId = Services.Trade:GetOwner(itemId)

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
        slot = slot,
        owner = ownerId
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

    local ownerId = Services.Trade:GetOwner(item.id)

    Services.Event:Fire("Inventory.Unequip", {
        entity = entity,
        item = item,
        slot = slot,
        owner = ownerId
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