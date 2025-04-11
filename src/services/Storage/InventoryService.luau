--[[ InventoryService
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-11
]]
local InventoryService = {}

InventoryService.Dependencies = {
    "Data",
    "Event",
    "Stat"
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
function InventoryService:AddItem(entity: any, itemId: string, quantity: number?): (boolean, string?)
    if not (entity and itemId) then return false, "Invalid input" end
    quantity = quantity or 1

    if quantity <= 0 then return false, "Invalid quantity" end

    State.inventories[entity] = State.inventories[entity] or {}
    local inventory = State.inventories[entity]

    local itemTemplate, sourceModule = self:GetTemplate(itemId)
    if not itemTemplate then return false, "Invalid item" end

    inventory[itemId] = (inventory[itemId] or 0) + quantity

    Services.Event:Fire("Inventory.Add", {
        entity = entity,
        itemId = itemId,
        quantity = quantity,
        newTotal = inventory[itemId],
        moduleSource = sourceModule
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

        Services.Event:Fire("Inventory.Use", {
            entity = entity,
            itemId = itemId,
            variant = variant,
            moduleSource = sourceModule,
            effects = effects,
            buffs = buffList
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