--[[ ObjectService
    Core object management system for dynamic instance tracking and attribute handling.
    Provides centralized registration, caching, and property management for game objects.
    @author @Daystopia
    @version 1.0.6
    @date 2025-03-12
]]
local ObjectService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--[[ Dependencies ]]
ObjectService.Dependencies = {
    "Event",
    "Data"
}

--[[ Modules ]]
ObjectService.Modules = {
    "Object"
}

--[[ Events ]]
ObjectService.Events = {
    Register = true,
    Unregister = true,
    Update = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Types ]]
type ObjectAttributes = {
    name: string,
    category: string,
    [string]: any
}

--[[ State ]]
local state = {
    registeredObjects = {} :: {[string]: ObjectAttributes},
    instanceCache = {} :: {[Instance]: string}
}

--[[ Core Functions ]]
function ObjectService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function ObjectService:Start()
    self:RegisterObjects()
    self:ApplyAttributes()
    return true
end

--[[ Instance Tracking ]]
function ObjectService:GetInstance(id: string): Instance?
    local object = state.registeredObjects[id]
    return object and object.instance
end

function ObjectService:GetID(instance: Instance): string?
    return state.instanceCache[instance]
end

--[[ Utility Functions ]]
local function capitalize(str: string): string
    return str:gsub("_", " "):gsub("%S+", function(word)
        return word:sub(1,1):upper() .. word:sub(2):lower()
    end)
end

local function normalize(str: string): string
    return str:lower()
        :gsub("'s", "s")
        :gsub("'", "")
        :gsub("ies$", "y")
        :gsub("oes$", "o")
        :gsub("ves$", "f")
        :gsub("i$", "us")
        :gsub("ae$", "a")
        :gsub("s$", "")
        :gsub("&", "and")
        :gsub("%-", "")
        :gsub("[^%w]", "_")
        :gsub("_+", "_")
        :gsub("^_", "")
        :gsub("_$", "")
end

local function attribute(value: any): boolean
    local valueType = typeof(value)
    return valueType == "string" or
           valueType == "number" or
           valueType == "boolean" or
           valueType == "Vector3" or
           valueType == "Vector2" or
           valueType == "CFrame" or
           valueType == "Color3" or
           valueType == "BrickColor" or
           valueType == "UDim" or
           valueType == "UDim2" or
           valueType == "Ray" or
           valueType == "Faces" or
           valueType == "Axes" or
           valueType == "NumberRange" or
           valueType == "Rect" or
           valueType == "ColorSequence" or
           valueType == "NumberSequence" or
           valueType == "EnumItem"
end

local function convert(value: any): (any, boolean)
    if attribute(value) then
        if typeof(value) == "string" then
            return capitalize(value), true
        end
        return value, true
    end

    local valueType = typeof(value)
    if valueType == "table" then
        if #value > 0 then
            local isStringArray = true
            local convertedValues = {}
            for _, v in ipairs(value) do
                if typeof(v) ~= "string" then
                    isStringArray = false
                    break
                end
                convertedValues[#convertedValues + 1] = capitalize(v)
            end

            if isStringArray then
                return table.concat(convertedValues, ", "), true
            end

            local displayValues = {}
            for _, v in ipairs(value) do
                if typeof(v) == "string" then
                    displayValues[#displayValues + 1] = capitalize(v)
                elseif typeof(v) == "table" and v.name then
                    displayValues[#displayValues + 1] = capitalize(v.name)
                else
                    displayValues[#displayValues + 1] = tostring(v)
                end
            end
            return table.concat(displayValues, ", "), true
        elseif value.name then
            return capitalize(value.name), true
        end
        return HttpService:JSONEncode(value), true
    end

    if valueType == "function" or valueType == "thread" or valueType == "userdata" then
        return nil, false
    end

    if valueType == "string" then
        return capitalize(tostring(value)), true
    end
    return tostring(value), true
end

local function flatten(tbl: {[string]: any}, prefix: string?): {[string]: any}
    local result = {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            if #value > 0 then
                result[string.upper(key)] = value
            else
                for subKey, subValue in pairs(value) do
                    if type(subValue) == "table" and not (#subValue > 0) then
                        for deepKey, deepValue in pairs(subValue) do
                            result[string.upper(subKey) .. "_" .. string.upper(deepKey)] = deepValue
                        end
                    else
                        result[string.upper(subKey)] = subValue
                    end
                end
            end
        else
            result[string.upper(key)] = value
        end
    end
    return result
end

local function set(instance: Instance, key: string, value: any)
    if type(value) == "table" and not (#value > 0) then
        local flattened = flatten(value)
        for flatKey, flatValue in pairs(flattened) do
            local convertedValue, success = convert(flatValue)
            if success and convertedValue ~= nil then
                instance:SetAttribute(flatKey, convertedValue)
            end
        end
    else
        local convertedValue, success = convert(value)
        if success and convertedValue ~= nil then
            instance:SetAttribute(string.upper(key), convertedValue)
        else
            warn(string.format(
                "Failed to set attribute %q on %s: Unsupported type %s",
                key,
                instance:GetFullName(),
                typeof(value)
            ))
        end
    end
end

--[[ Registration Functions ]]
function ObjectService:RegisterObjects()
    for _, module in Modules do
        if not module then continue end

        local categoryGroups = module.CategoryGroups or {}
        local categoryToGroup = {}

        for group, categories in categoryGroups do
            for _, category in categories do
                categoryToGroup[category] = group
                categoryToGroup[category:upper()] = group
            end
        end

        for tableName, dataTable in module do
            if type(dataTable) ~= "table" then continue end

            for categoryName, category in dataTable do
                if type(category) ~= "table" then continue end

                local parentCategory = categoryToGroup[categoryName]

                if category.variants then
                    for variantName, variant in category.variants do
                        variant.variant = variantName
                        variant.type = categoryName
                        variant.category = parentCategory or categoryName
                        self:RegisterObject(parentCategory or categoryName, variant)
                    end
                    continue
                end

                for itemName, item in category do
                    if type(item) ~= "table" then continue end
                    item.name = item.name or itemName
                    item.type = categoryName
                    item.category = parentCategory or categoryName
                    self:RegisterObject(parentCategory or categoryName, item)
                end
            end
        end
    end
end

function ObjectService:RegisterObject(
    category: string,
    attributes: {[string]: any}
): boolean
    if not attributes.name then return false end

    local id = HttpService:GenerateGUID(false)
    while state.registeredObjects[id] do
        id = HttpService:GenerateGUID(false)
    end

    state.registeredObjects[id] = attributes
    Services.Event:Fire("Object.Register", {id = id, attributes = attributes})
    return true
end

function ObjectService:UnregisterObject(id: string): boolean
    local attributes = state.registeredObjects[id]
    if not attributes then return false end

    state.registeredObjects[id] = nil
    Services.Event:Fire("Object.Unregister", {id = id, attributes = attributes})
    return true
end

--[[ Attribute Management ]]
function ObjectService:FindMatch(instanceName: string): (ObjectAttributes?, string?)
    instanceName = normalize(instanceName):lower()
    local noUnderscores = instanceName:gsub("_", "")

    local function processVariant(variant, object, variantName)
        local variantObject = table.clone(variant)
        variantObject.variant = variantName
        variantObject.name = variant.name or object.name
        variantObject.category = object.category
        variantObject.type = object.type

        if object.defaults then
            for key, value in pairs(object.defaults) do
                if type(value) == "table" then
                    variantObject[key] = variantObject[key] or {}
                    for subKey, subValue in pairs(value) do
                        if type(subValue) == "table" then
                            variantObject[key][subKey] = variantObject[key][subKey] or {}
                            for deepKey, deepValue in pairs(subValue) do
                                if variantObject[key][subKey][deepKey] == nil then
                                    variantObject[key][subKey][deepKey] = deepValue
                                end
                            end
                        else
                            if variantObject[key][subKey] == nil then
                                variantObject[key][subKey] = subValue
                            end
                        end
                    end
                else
                    if variantObject[key] == nil then
                        variantObject[key] = value
                    end
                end
            end
        end

        if variant.properties then
            variantObject.properties = variantObject.properties or {}
            for key, value in pairs(variant.properties) do
                if type(value) == "table" and type(variantObject.properties[key]) == "table" then
                    for subKey, subValue in pairs(value) do
                        variantObject.properties[key][subKey] = subValue
                    end
                else
                    variantObject.properties[key] = value
                end
            end
        end

        local newId = HttpService:GenerateGUID(false)
        while state.registeredObjects[newId] do
            newId = HttpService:GenerateGUID(false)
        end

        state.registeredObjects[newId] = variantObject

        Services.Event:Fire("Object.Register", {
            id = newId,
            attributes = variantObject
        })

        return variantObject, newId
    end

    for id, object in state.registeredObjects do
        if object.variants then
            for variantName, variant in object.variants do
                local variantFullName = normalize(variant.name):lower()
                if variantFullName == instanceName or variantFullName == noUnderscores then
                    return processVariant(variant, object, variantName)
                end
            end
        end
    end

    for id, object in state.registeredObjects do
        local objectName = normalize(object.name):lower()
        if objectName == instanceName or objectName == noUnderscores then
            if object.variants then
                for variantName, variant in object.variants do
                    return processVariant(variant, object, variantName)
                end
            end

            if object.properties then
                local flatObject = table.clone(object)
                for key, value in pairs(flatObject.properties) do
                    flatObject[key] = value
                end
                flatObject.properties = nil
                local newId = HttpService:GenerateGUID(false)
                state.registeredObjects[newId] = flatObject
                return flatObject, newId
            end

            local newId = HttpService:GenerateGUID(false)
            state.registeredObjects[newId] = object
            return object, newId
        end
    end

    for id, object in state.registeredObjects do
        if object.variants then
            for variantName, variant in object.variants do
                local normalizedVariant = normalize(variantName)
                if normalizedVariant == instanceName then
                    return processVariant(variant, object, variantName)
                end
            end
        end
    end

    for id, object in state.registeredObjects do
        local objectName = normalize(object.name)
        if objectName == instanceName then
            local newId = HttpService:GenerateGUID(false)
            state.registeredObjects[newId] = object
            return object, newId
        end
    end

    for moduleName, module in Modules do
        if not module or typeof(module.FindMatch) ~= "function" then continue end

        local object = module.FindMatch(instanceName)
        if object then
            if object.variants then
                for variantName, variant in object.variants do
                    return processVariant(variant, object, variantName)
                end
            end
            return self:RegisterObject(
                object.category or moduleName,
                object
            )
        end
    end

    return nil
end

function ObjectService:ApplyAttributes()
    local function applyAttributes(instance: Instance)
        if not (instance:IsA("Model") or instance:IsA("Tool")) then return end

        local hitbox = instance:FindFirstChild("Hitbox")
        if hitbox then
            if hitbox:IsA("Model") then
                for _, part in hitbox:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            elseif hitbox:IsA("BasePart") then
                hitbox.CanCollide = false
            end
        end

        local targetInstances = {instance}

        if instance:IsA("Model") and instance.Parent and instance.Parent:IsA("Tool") then
            table.insert(targetInstances, instance.Parent)
        end

        if instance:IsA("Tool") then
            local model = instance:FindFirstChildWhichIsA("Model")
            if model then
                table.insert(targetInstances, model)
            end
        end

        if instance:IsDescendantOf(workspace) then
            if Players:GetPlayerFromCharacter(instance:FindFirstAncestorOfClass("Model")) then return end

            local parent = instance.Parent
            while parent and parent ~= workspace do
                if parent:IsA("Model") or parent:IsA("Tool") then return end
                parent = parent.Parent
            end
        end

        local object, id
        object, id = self:FindMatch(normalize(instance.Name))

        if not object and instance:IsA("Tool") then
            local model = instance:FindFirstChildWhichIsA("Model")
            if model then
                object, id = self:FindMatch(normalize(model.Name))
            end
        end

        if not object and instance:IsA("Model") and instance.Parent and instance.Parent:IsA("Tool") then
            object, id = self:FindMatch(normalize(instance.Parent.Name))
        end

        if not object then
            -- warn("No match found for:", instance.Name)
            return
        end

        for _, target in ipairs(targetInstances) do
            set(target, "ID", id)
            set(target, "NAME", capitalize(object.name))
            set(target, "CATEGORY", capitalize(object.category))
            if object.type then
                set(target, "TYPE", capitalize(object.type))
            end

            if object.properties and object.properties.interaction then
                if not target:GetAttribute("STATE") then
                    set(target, "STATE", "INACTIVE")
                end
            end

            for key, value in object do
                if key == "name" or key == "category" or key == "variants" or key == "type" then continue end
                if key == "properties" then
                    for propKey, propValue in pairs(value) do
                        if propKey == "components" then continue end
                        set(target, string.upper(propKey), propValue)
                    end
                    continue
                end
                set(target, key, value)
            end

            if object.variant then
                set(target, "VARIANT", capitalize(object.variant))
            end

            if object.properties and object.properties.components then
                for componentName, componentData in pairs(object.properties.components) do
                    local normalizedName = normalize(componentName)
                    local componentPart

                    componentPart = target:FindFirstChild(componentName)

                    if not componentPart then
                        for _, child in target:GetChildren() do
                            if normalize(child.Name) == normalizedName then
                                componentPart = child
                                break
                            end
                        end
                    end

                    if componentPart then
                        if componentData.interaction and not componentPart:GetAttribute("STATE") then
                            set(componentPart, "STATE", "INACTIVE")
                        end

                        for key, value in pairs(componentData) do
                            set(componentPart, key:upper(), value)
                        end
                        set(componentPart, "NAME", capitalize(componentData.name or componentName))
                    end
                end
            end

            local registeredObject = state.registeredObjects[id]
            if registeredObject then
                registeredObject.instance = target
                state.instanceCache[target] = id

                target.Destroying:Connect(function()
                    state.instanceCache[target] = nil
                    registeredObject.instance = nil
                end)
            end

            local attributes = {}
            for _, attrName in pairs(target:GetAttributes()) do
                if type(attrName) == "string" then
                    local value = target:GetAttribute(attrName)
                    if value ~= nil then
                        attributes[attrName] = value
                    end
                end
            end

            local humanoid = target:FindFirstChild("Humanoid")
            if humanoid and humanoid:IsA("Humanoid") then
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

                local showName = target:GetAttribute("SHOW_NAME")
                local showHealth = target:GetAttribute("SHOW_HEALTH")

                if showName then
                    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
                    humanoid.NameDisplayDistance = target:GetAttribute("NAME_DISTANCE") or 100
                end

                if showHealth then
                    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                    humanoid.HealthDisplayDistance = target:GetAttribute("HEALTH_DISTANCE") or 100
                end
            end

            Services.Event:Fire("Object.Update", {
                id = id,
                instance = target,
                attributes = attributes
            })
        end
    end

    local locations = {Workspace, ReplicatedStorage}
    for _, service in locations do
        task.spawn(function()
            for _, instance in service:GetDescendants() do
                local success, err = pcall(function()
                    applyAttributes(instance)
                end)
                if not success then
                    warn(string.format(
                        "Failed to apply attributes to %s: %s",
                        instance:GetFullName(),
                        err
                    ))
                end
            end
        end)
        service.DescendantAdded:Connect(function(instance)
            local success, err = pcall(function()
                applyAttributes(instance)
            end)
            if not success then
                warn(string.format(
                    "Failed to apply attributes to %s: %s",
                    instance:GetFullName(),
                    err
                ))
            end
        end)
    end
end

function ObjectService:UpdateAttributes(
    id: string,
    attributes: {[string]: any}
): boolean
    local object = state.registeredObjects[id]
    if not object then return false end

    for key, value in attributes do
        object[key] = value
    end
    Services.Event:Fire("Object.Update", {id = id, attributes = attributes})

    if object.instance then
        local instance = object.instance
        for key, value in attributes do
            if value == nil then continue end

            instance:SetAttribute(
                string.upper(key),
                type(value) == "table" and #value > 0
                    and table.concat(value, ", ")
                    or value
            )
        end
    end

    return true
end

--[[ Getter Functions ]]
function ObjectService:SearchObjects(matcher: (variant: {any}, itemName: string?, categoryName: string?, variantKey: string?) -> (any))
    local function processVariant(variant)
        if type(variant) ~= "table" then return variant end

        local template = table.clone(variant)
        if template.properties then
            table.move(template.properties, 1, #template.properties, #template + 1, template)
        end
        return template
    end

    local function checkVariants(variants, itemName, categoryName)
        for variantKey, variant in variants do
            local result = matcher(variant, itemName, categoryName, variantKey)
            if result then return processVariant(result) end
        end
    end

    for _, module in Modules do
        if not module or not module.Templates then continue end

        for categoryName, category in module.Templates do
            if type(category) ~= "table" then continue end

            for subCategoryName, subCategory in category do
                if type(subCategory) ~= "table" then continue end

                if subCategory.variants then
                    local result = checkVariants(subCategory.variants, subCategoryName, categoryName)
                    if result then return result end
                    continue
                end

                for itemName, item in subCategory do
                    if type(item) == "table" and item.variants then
                        local result = checkVariants(item.variants, itemName, categoryName)
                        if result then return result end
                    end
                end
            end
        end
    end

    return nil
end

function ObjectService:GetName(name: string): {any}?
    local searchName = normalize(name)
    return self:SearchObjects(function(variant)
        return normalize(variant.name) == searchName and variant
    end)
end

function ObjectService:GetType(name: string): string?
    local searchName = normalize(name)
    return self:SearchObjects(function(variant, itemName)
        return normalize(variant.name) == searchName and itemName
    end)
end

function ObjectService:GetCategory(name: string): string?
    local searchName = normalize(name)
    return self:SearchObjects(function(variant, _, categoryName)
        return normalize(variant.name) == searchName and categoryName
    end)
end

function ObjectService:GetVariant(objectName: string, variantName: string): {any}?
    local searchName = normalize(objectName)
    local searchVariant = normalize(variantName)
    return self:SearchObjects(function(variant, _, _, variantKey)
        return normalize(variant.name) == searchName and normalize(variantKey) == searchVariant and variant
    end)
end

return ObjectService