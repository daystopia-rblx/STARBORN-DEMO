--[[ AssetService
    Advanced asset management system with dynamic loading and resource pooling.
    Handles asset preloading, caching, runtime loading, and memory optimization.
    @author @Daystopia
    @version 1.0.10
    @date 2025-03-05
]]
local AssetService = {}

--[[ Dependencies ]]
AssetService.Dependencies = {
    "Event"
}

--[[ Events ]]
AssetService.Events = {
    Load = true
}

--[[ Services & Modules ]]
local Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asset = require(ReplicatedStorage.Modules.AssetModule)

--[[ Constants ]]
local CONSTANTS = {
    CRITICAL_ASSETS = {
        "Animation",
        "Sound",
        "ImageLabel",
        "Decal",
        "Model"
    },
    POOL_CONFIG = {
        minSize = 5,
        maxSize = 50,
        expandSize = 5
    },
    IGNORED_KEYS = {
        ["data"] = true,
        ["id"] = true,
        ["assets"] = true,
        ["templates"] = true,
        ["animations"] = true,
        ["sounds"] = true,
        ["images"] = true,
        ["decals"] = true,
        ["models"] = true,
        ["effects"] = true,
        ["sfx"] = true,
        ["particles"] = true,
        ["lighting"] = true,
        ["properties"] = true,
        ["attributes"] = true,
        ["children"] = true,
        ["interface"] = true,
        ["ui"] = true,
        ["presets"] = true
    }
}

--[[ Types ]]
type PoolData = {
    available: {Instance},
    inUse: {[Instance]: boolean},
    template: Instance?,
    size: number
}

--[[ State ]]
local state = {
    preload = {},
    pools = {},
    definitions = {}
}

--[[ Core Functions ]]
function AssetService:Init(services)
    Services = services

    local assetsFolder = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder")
    assetsFolder.Name = "Assets"
    assetsFolder.Parent = ReplicatedStorage

    local runtimeFolder = workspace:FindFirstChild("Runtime") or Instance.new("Folder")
    runtimeFolder.Name = "Runtime"
    runtimeFolder.Parent = workspace

    local soundsFolder = runtimeFolder:FindFirstChild("Sounds") or Instance.new("Folder")
    soundsFolder.Name = "Sounds"
    soundsFolder.Parent = runtimeFolder

    for _, category in pairs({"SFX", "Ambient", "UI", "Music"}) do
        local categoryFolder = soundsFolder:FindFirstChild(category) or Instance.new("Folder")
        categoryFolder.Name = category
        categoryFolder.Parent = soundsFolder
    end

    task.spawn(self.LoadModule, self)
    return true
end

function AssetService:Cleanup()
    if state.pools then
        for _, pool in pairs(state.pools) do
            if pool.inUse then
                for instance in pairs(pool.inUse) do
                    instance:Destroy()
                end
            end
            if pool.available then
                for _, instance in ipairs(pool.available) do
                    instance:Destroy()
                end
            end
            if pool.template then
                pool.template:Destroy()
            end
        end
    end

    for _, tableName in ipairs({"pools", "preload", "definitions"}) do
        if state[tableName] then
            table.clear(state[tableName])
        end
    end
end


--[[ Pool Management ]]
local Pool = {}

function Pool.get(assetType, category, name)
    local poolKey = string.format("%s_%s_%s", assetType, category, name)
    local pool = state.pools[poolKey]

    if not pool then
        local asset = state.preload[category] and state.preload[category][name]
        if not asset then return nil end

        pool = {
            available = {},
            inUse = {},
            template = asset.instance:Clone(),
            size = 0
        }
        state.pools[poolKey] = pool
    end

    if pool.size >= CONSTANTS.POOL_CONFIG.maxSize then
        warn(`Pool maxSize reached for {poolKey}`)
        return nil
    end

    local instance = table.remove(pool.available) or pool.template:Clone()
    pool.size = pool.size + (instance == pool.template:Clone() and 1 or 0)
    pool.inUse[instance] = true

    return instance
end

function Pool.release(instance, assetType, category, name)
    local poolKey = string.format("%s_%s_%s", assetType, category, name)
    local pool = state.pools[poolKey]
    if not pool or not pool.inUse[instance] then return end

    pool.inUse[instance] = nil
    if #pool.available < CONSTANTS.POOL_CONFIG.maxSize then
        instance.Parent = nil
        table.insert(pool.available, instance)
    else
        instance:Destroy()
    end
end

function Pool.preload(assetType, category, name, count)
    count = math.min(count or CONSTANTS.POOL_CONFIG.minSize, CONSTANTS.POOL_CONFIG.maxSize)
    local poolKey = string.format("%s_%s_%s", assetType, category, name)
    local pool = state.pools[poolKey]

    if not pool then
        local asset = state.preload[category] and state.preload[category][name]
        if not asset then return end

        pool = {
            available = table.create(count),
            inUse = {},
            template = asset.instance:Clone(),
            size = 0
        }
        state.pools[poolKey] = pool
    elseif not pool.template then
        local asset = state.preload[category] and state.preload[category][name]
        if not asset then return end
        pool.template = asset.instance:Clone()
    end

    local numToAdd = count - pool.size
    if numToAdd <= 0 then return end

    for _ = 1, numToAdd do
        table.insert(pool.available, pool.template:Clone())
    end
    pool.size += numToAdd
end

--[[ Utility Functions ]]
function AssetService:ApplyData(instance, data, propertyMap)
    if propertyMap then
        for dataProp, instanceProp in pairs(propertyMap) do
            local value = data[dataProp]
            if value == nil then continue end

            if type(instanceProp) == "table" then
                for _, prop in ipairs(instanceProp) do
                    instance[prop] = value
                end
            else
                instance[instanceProp] = value
            end
        end
    end

    if data.attributes then
        for name, value in pairs(data.attributes) do
            instance:SetAttribute(name, value)
        end
    end

    if data.childAttributes then
        for childName, attributes in pairs(data.childAttributes) do
            local child = instance:FindFirstChild(childName, true)
            if child then
                for name, value in pairs(attributes) do
                    child:SetAttribute(name, value)
                end
            end
        end
    end
end

--[[ Asset Management ]]
function AssetService:LoadAsset(assetType, category, name, data, categoryFolder)
    local config = Asset.Config[assetType]
    if not config then return end

    pcall(function()
        local instance

        if assetType == "Model" then
            local success, model = pcall(function()
                return game:GetObjects(data.id)[1]
            end)
            if success then instance = model end
        else
            instance = Instance.new(assetType)
            instance[config.idProp] = type(data) == "string" and data or data.id
        end

        if instance then
            instance.Name = name

            if type(data) == "table" then
                if config.defaults then
                    for prop, value in pairs(config.defaults) do
                        pcall(function()
                            instance[prop] = value
                        end)
                    end
                end
                self:ApplyData(instance, data, Asset.Properties[assetType])
            end

            state.preload[category] = state.preload[category] or {}
            state.preload[category][name] = {
                instance = instance,
                data = type(data) == "table" and table.clone(data) or { id = data }
            }

            instance.Parent = categoryFolder
        end
    end)
end

function AssetService:GetAsset(category, assetName, assetType)
    local instance = Pool.get(assetType, category, assetName)
    if instance then
        return {
            instance = instance,
            data = state.preload[category][assetName].data 
        }
    end

    local categoryAssets = state.preload[category]
    if not categoryAssets then
        -- warn(`No assets found for category: {category}`)
        return nil
    end

    assetName = assetName:lower()

    for storedName, asset in pairs(categoryAssets) do
        if asset.instance:IsA(assetType) then
            local storedLower = storedName:lower()
            if storedLower == assetName then
                return asset
            end
        end
    end

    warn(`{assetType} not found: {category}/{assetName}`)
    return nil
end

function AssetService:ReleaseAsset(instance, category, assetName, assetType)
    Pool.release(instance, assetType, category, assetName)
end

function AssetService:PreloadAsset(category, assetName, assetType, count)
    Pool.preload(assetType, category, assetName, count)
end

local function ValidateId(id)
    return type(id) == "string" and (id:match("^rbxassetid://(%d+)$") or id:match("^ref://(.+)$")) ~= nil
end

local function ProcessData(data, path, assets)
    local function CreateName(path)
        local cleanPath = table.create(#path)
        for _, part in ipairs(path) do
            local partStr = tostring(part)
            if not CONSTANTS.IGNORED_KEYS[partStr:lower()] then
                table.insert(cleanPath, partStr:upper())
            end
        end
        return table.concat(cleanPath, "_")
    end

    local function ResolveReference(ref)
        local refPath = ref:match("^ref://(.+)$")
        if not refPath then return ref end

        for _, categoryData in pairs(state.preload) do
            local assetData = categoryData[refPath]
            if assetData then
                return type(assetData.data) == "table" and table.clone(assetData.data) or assetData.data
            end
        end

        warn("Could not resolve asset reference:", ref)
        return ref
    end

    if type(data) == "table" then
        if data.id and ValidateId(data.id) then
            local assetName = CreateName(path)
            if assetName ~= "" then
                local assetData = table.clone(data)
                if assetData.id:match("^ref://") then
                    local resolvedData = ResolveReference(assetData.id)
                    if type(resolvedData) == "table" then
                        for k, v in pairs(resolvedData) do
                            assetData[k] = assetData[k] or v
                        end
                        assetData.id = resolvedData.id
                    else
                        assetData.id = resolvedData
                    end
                end
                assets[assetName] = assetData
            end
        elseif ValidateId(data) then
            local assetName = CreateName(path)
            if assetName ~= "" then
                assets[assetName] = data:match("^ref://") and ResolveReference(data) or data
            end
        else
            for key, value in pairs(data) do
                local newPath = table.clone(path)
                table.insert(newPath, key)
                ProcessData(value, newPath, assets)
            end
        end
    elseif ValidateId(data) then
        local assetName = CreateName(path)
        if assetName ~= "" then
            assets[assetName] = data:match("^ref://") and ResolveReference(data) or data
        end
    end
end

function AssetService:LoadModule()
    local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
    if not modulesFolder then
        warn("Modules folder not found")
        return
    end

    local function CreateFolder(parentFolder, folderName)
        local folder = parentFolder:FindFirstChild(folderName) or Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parentFolder
        return folder
    end

    local assetsFolder = ReplicatedStorage.Assets
    local assetFolders = {}
    local pendingReferences = {}

    for assetType, config in pairs(Asset.Config) do
        assetFolders[assetType] = CreateFolder(assetsFolder, config.folder)
    end

    local function ExtractAssets(data)
        local assets = {}
        ProcessData(data, {}, assets)
        return assets
    end

    local function ProcessAssets(data, category, assetType)
        if type(data) ~= "table" then return {}, false end

        local assetData = data.Assets and data.Assets[assetType .. "s"] or data[assetType .. "s"] or data[assetType]
        if not assetData then return {}, false end

        local validAssets = {}
        local extractedAssets = ExtractAssets(assetData)
        local hasValidAssets = false

        for name, assetData in pairs(extractedAssets) do
            if name == "" then continue end
            local cleanName = name:gsub("^" .. assetType .. "_", "")
            if cleanName:match("^" .. category .. "_") then continue end

            local formattedName = cleanName:gsub("_(%l)", string.upper):gsub("^%l", string.upper)
            if validAssets[formattedName] then continue end

            if type(assetData) == "string" and assetData:match("^ref://") then
                table.insert(pendingReferences, {
                    category = category,
                    name = formattedName,
                    type = assetType,
                    reference = assetData
                })
                continue
            elseif type(assetData) == "table" and assetData.id and assetData.id:match("^ref://") then
                table.insert(pendingReferences, {
                    category = category,
                    name = formattedName,
                    type = assetType,
                    reference = assetData.id,
                    overrides = assetData
                })
                continue
            end

            validAssets[formattedName] = assetData
            hasValidAssets = true
        end

        return validAssets, hasValidAssets
    end

    for _, module in ipairs(modulesFolder:GetChildren()) do
        if not (module:IsA("ModuleScript") and module.Name:match("Module$")) then continue end

        local success, result = pcall(require, module)
        if not success then
            warn(string.format("Failed to require %s: %s", module.Name, result))
            continue
        end

        local category = module.Name:gsub("Module$", "")
        state.definitions[category] = state.definitions[category] or {}
        state.preload[category] = state.preload[category] or {}

        for assetType, folder in pairs(assetFolders) do
            local validAssets, hasValidAssets = ProcessAssets(result, category, assetType)
            if hasValidAssets then
                state.definitions[category][assetType .. "s"] = validAssets
                for name, data in pairs(validAssets) do
                    self:LoadAsset(assetType, category, name, data, CreateFolder(folder, category))
                end
            end
        end
    end

    for _, ref in ipairs(pendingReferences) do
        local refPath = ref.reference:match("^ref://(.+)$")
        local sourceAsset

        for _, categoryData in pairs(state.preload) do
            sourceAsset = categoryData[refPath]
            if sourceAsset then break end
        end

        if sourceAsset then
            local data
            if ref.overrides then
                data = table.clone(ref.overrides)
                data.id = sourceAsset.data.id
                for k, v in pairs(sourceAsset.data) do
                    data[k] = data[k] or v
                end
            else
                data = table.clone(sourceAsset.data)
            end

            self:LoadAsset(ref.type, ref.category, ref.name, data, CreateFolder(assetFolders[ref.type], ref.category))
        else
            warn("Could not resolve asset reference:", ref.reference, "for", ref.name)
        end
    end

    Services.Event:Fire("Asset.Load")
end

return AssetService