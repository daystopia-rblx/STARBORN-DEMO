--[[ DataService
    Advanced data persistence system with caching, validation, and analytics.
    Manages data storage, backups, migrations, and performance monitoring.
    @author @Daystopia
    @version 1.0.6
    @date 2025-04-09
]]
local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

DataService.Dependencies = {
    "Event"
}

DataService.Modules = {
    "Data"
}

-- Constants
local AUTOSAVE_INTERVAL = 300
local MAX_RETRIES = 3
local RETRY_DELAY = 1
local DATASTORE_NAME = "PlayerData_V1"
local MIN_SAVE_INTERVAL = 10

-- State
local Services
local Modules
local dataStore
local cache = {
    players = {},
    lastSaved = {}
}

-- [[ Core Functions ]]
function DataService:Init(services, modules)
    Services = services
    Modules = modules

    dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
    return true
end

function DataService:Start()
    game.Players.PlayerAdded:Connect(function(player)
        self:LoadAllData(player)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        self:SaveAllData(player)
        self:ClearCache(player)
    end)

    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_INTERVAL)
            self:AutoSave()
        end
    end)

    return true
end

-- [[ Data Loading Functions ]]
function DataService:LoadAllData(player)
    if not player then return end

    local userId = tostring(player.UserId)
    cache.players[userId] = {}

    local success, allData = self:LoadData(userId)
    if success then
        for dataType, template in pairs(Modules.Data.Templates) do
            local baseTemplate = self:DeepCopy(template)
            local data = allData[dataType] or baseTemplate

            self:EnsureFields(data, baseTemplate)

            cache.players[userId][dataType] = data
        end

        Services.Event:Fire("Data.Init", {
            player = player,
            userId = userId,
            data = cache.players[userId]
        })
    end
end

function DataService:LoadData(userId)
    if not dataStore then return false end

    local success, data
    local retries = 0

    repeat
        success, data = pcall(function()
            return dataStore:GetAsync(userId) or {}
        end)

        if not success then
            retries += 1
            task.wait(RETRY_DELAY)
        end
    until success or retries >= MAX_RETRIES

    if success and not data then
        data = {}
        for dataType, template in pairs(Modules.Data.Templates) do
            data[dataType] = table.clone(template)
        end
    end

    return success, data or {}
end

function DataService:DeepCopy(original)
    if type(original) ~= "table" then return original end

    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end

    return copy
end

function DataService:EnsureFields(data, template)
    if type(data) ~= "table" or type(template) ~= "table" then return end

    for k, v in pairs(template) do
        if data[k] == nil then
            data[k] = self:DeepCopy(v)
        elseif type(v) == "table" and type(data[k]) == "table" then
            self:EnsureFields(data[k], v)
        end
    end
end

-- [[ Data Saving Functions ]]
function DataService:SaveAllData(player)
    if not player then return end

    local userId = tostring(player.UserId)
    if not cache.players or not cache.players[userId] then
        return
    end

    local currentTime = os.time()
    local lastSaveTime = cache.lastSaved[userId] or 0
    if (currentTime - lastSaveTime) < MIN_SAVE_INTERVAL then
        return
    end

    local playerData = cache.players[userId]
    if type(playerData) ~= "table" then
        return
    end

    local success = self:SaveData(userId, playerData)

    if success then
        cache.lastSaved[userId] = currentTime

        if Services and Services.Event and Services.Event._isInitialized then
            for dataType, data in pairs(playerData) do
                pcall(function()
                    Services.Event:Fire("Data.Save", {
                        player = player,
                        userId = userId,
                        data = data,
                        dataType = dataType
                    })
                end)
            end
        end
    end
end

function DataService:SaveData(userId, data)
    if not dataStore then return false end

    local success
    local retries = 0

    repeat
        success = pcall(function()
            dataStore:SetAsync(userId, data)
        end)

        if not success then
            retries += 1
            task.wait(RETRY_DELAY)
        end
    until success or retries >= MAX_RETRIES

    return success
end

function DataService:AutoSave()
    for i, player in ipairs(game.Players:GetPlayers()) do
        task.spawn(function()
            task.wait(i * 0.5)
            self:SaveAllData(player)
        end)
    end
end

-- [[ Cache Functions ]]
function DataService:GetData(userId, dataType)
    if not userId or not dataType then return nil end

    local playerCache = cache.players[tostring(userId)]
    if not playerCache then return nil end

    return playerCache[dataType]
end

function DataService:SetData(userId, data, dataType)
    if not userId or not data or not dataType then return false end

    local playerCache = cache.players[tostring(userId)]
    if not playerCache then
        playerCache = {}
        cache.players[tostring(userId)] = playerCache
    end

    playerCache[dataType] = data
    return true
end

function DataService:UpdateData(userId, dataType, updateFunc)
    local currentData = self:GetData(userId, dataType)
    if not currentData then return false end

    local newData = updateFunc(currentData)
    if not newData then return false end

    return self:SetData(userId, newData, dataType)
end

function DataService:ClearCache(player)
    if not player then return end
    local userId = tostring(player.UserId)
    cache.players[userId] = nil
    cache.lastSaved[userId] = nil
end

return DataService
