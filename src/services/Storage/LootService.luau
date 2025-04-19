--[[ LootService
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-18
]]
local LootService = {}

--[[ Dependencies ]]
LootService.Dependencies = {
    "Data",
    "Event"
}

--[[ Modules ]]
LootService.Modules = {
    "Person",
    "Loot"
}

--[[ Types ]]
type LootItem = {
    id: string,
    value: number,
    quantity: number?,
    rarity: string?,
    metadata: {[string]: any}?
}

--[[ State ]]
local Services
local Modules

--[[ Core Functions ]]
function LootService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function LootService:Start()
    return true
end

--[[ Loot Generation Functions ]]
function LootService:GenerateLocation(templateId: string, tier: string): LootItem?
    if not templateId or not tier then return nil end

    return self:GenerateLoot("location", templateId, tier)
end

function LootService:GenerateEntity(personType: string, variant: string?): LootItem?
    if not personType then return nil end

    return self:GenerateLoot("entity", personType, "low", 1, variant)
end

function LootService:GenerateContainer(containerType: string, tier: string, count: number): {LootItem}
    if not containerType or not tier then return {} end

    count = count or 1
    local results = {}

    for i = 1, count do
        if math.random() > 0.3 or i == 1 then
            local lootItem = self:GenerateLoot("container", containerType, tier)
            if lootItem then
                table.insert(results, lootItem)
            end
        end
    end

    return results
end

function LootService:GenerateQuest(questId: string, tier: string): {LootItem}
    return self:GenerateLoot("quest", questId, tier)
end

function LootService:GenerateLoot(sourceType: string, sourceId: string, tier: string?, count: number?, variant: string?): LootItem?
    if not sourceType or not sourceId then return nil end

    sourceId = sourceId:upper()
    tier = tier and tier:lower() or "low"
    count = count or 1

    local selectedItem
    local lootTable = Modules.Loot:GetTable(sourceType, sourceId, tier, variant)
    if not lootTable or #lootTable == 0 then
        return nil
    end

    if sourceType:upper() == "ENTITY" or sourceType:upper() == "NODE" then
        selectedItem = Modules.Loot:SelectItem(lootTable)
        if not selectedItem then return nil end

        local quantity = Modules.Loot:GetQuantity(selectedItem) 
        return {
            id = selectedItem.item,
            value = selectedItem.value or 0,
            quantity = quantity,
            rarity = selectedItem.rarity or "COMMON",
            metadata = {
                source = sourceType,
                sourceId = sourceId,
                tier = tier,
                variant = variant
            }
        }
    else
        local itemId = lootTable[math.random(1, #lootTable)]
        if not itemId then return nil end

        local rarityOptions = Modules.Loot:GetRarity(tier)
        local rarity = rarityOptions[math.random(1, #rarityOptions)]

        local valueRange = Modules.Loot:GetValue(rarity)
        local value = math.random(valueRange.min, valueRange.max)

        local quantity = Modules.Loot:GetQuantity(itemId)

        selectedItem = {
            id = itemId.id or itemId,
            value = value,
            rarity = rarity,
            quantity = quantity
        }
    end

    return {
        id = selectedItem.id,
        value = selectedItem.value or 0,
        quantity = selectedItem.quantity or 1,
        rarity = selectedItem.rarity or "COMMON",
        metadata = {
            source = sourceType,
            sourceId = sourceId,
            tier = tier,
            variant = variant
        }
    }
end

return LootService