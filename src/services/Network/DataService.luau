--[[ DataService
    Advanced data persistence system with caching, validation, and analytics.
    Manages data storage, backups, migrations, and performance monitoring.
    @author @Daystopia
    @version 1.0.8
    @date 2025-04-11
]]
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

local DataService = {}

DataService.Dependencies = {
    "Event"
}

DataService.Modules = {
    "Data"
}

DataService.Events = {
    Init = { validate = true },
    Save = { validate = true },
    Global = { validate = true }
}

--[[ Constants ]]
local AUTOSAVE_INTERVAL = 300
local GLOBAL_SAVE_INTERVAL = 60
local GLOBAL_SAVE_THRESHOLD = 5
local MAX_RETRIES = 3
local RETRY_DELAY = 1
local DATASTORE_NAME = "PlayerData_V1"
local MIN_SAVE_INTERVAL = 10
local MESSAGE_TOPIC = "GlobalDataUpdate"
local SHORT_ID_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local SHORT_ID_LENGTH = 10
local HEX_ALPHABET = "0123456789abcdef"
local READABLE_CONSONANTS = "bcdfghjklmnpqrstvwxyz"
local READABLE_VOWELS = "aeiou"

DataService.GLOBAL_KEYS = {
    FACTION_DATA = "FactionData",
    CRIME_DATA = "CrimeData",
    GUILD_DATA = "GuildData",
    ADMIN_DATA = "AdminData"
}

--[[ State ]]
local Services
local Modules
local dataStore
local cache = {
    players = {},
    lastSaved = {},
    global = {},
    globalChanges = {},
    lastGlobalSave = {}
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

    task.spawn(function()
        while true do
            task.wait(GLOBAL_SAVE_INTERVAL)
            self:ProcessGlobal()
        end
    end)

    self:SubscribeGlobal()
    return true
end

-- [[ Utility Functions ]]
function DataService:GenerateId(idType: string?, length: number?): string
    if idType == "UUID" then
        return HttpService:GenerateGUID(false)
    elseif idType == "Short" then
        local id = ""
        for i = 1, SHORT_ID_LENGTH do
            local randomPos = math.random(1, #SHORT_ID_ALPHABET)
            id = id .. string.sub(SHORT_ID_ALPHABET, randomPos, randomPos)
        end
        return id
    elseif idType == "Number" then
        return tostring(math.random(1000, 999999))
    elseif idType == "Hex" then
        local id = ""
        for i = 1, length or 6 do
            local randomPos = math.random(1, #HEX_ALPHABET)
            id = id .. string.sub(HEX_ALPHABET, randomPos, randomPos)
        end
        return id
    elseif idType == "Base64" then
        return HttpService:GenerateGUID(false):sub(1, length or 8)
    elseif idType == "Readable" then
        local id = ""
        for i = 1, length or 6 do
            if i % 2 == 0 then
                id = id .. string.sub(READABLE_VOWELS, math.random(1, #READABLE_VOWELS), 1)
            else
                id = id .. string.sub(READABLE_CONSONANTS, math.random(1, #READABLE_CONSONANTS), 1)
            end
        end
        return id
    elseif idType == "Date" then
        local date = os.date("%Y%m%d")
        return date .. "_" .. tostring(math.random(1000, 9999))
    else
        local timestamp = tostring(os.time())
        local random = tostring(math.random(1000, 9999))
        return timestamp .. "_" .. random
    end
end

-- [[ Loading Functions ]]
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

    if success and type(data) == "string" then
        local deserializeSuccess, deserializedData = pcall(function()
            return HttpService:JSONDecode(data)
        end)

        if deserializeSuccess then
            data = deserializedData
        else
            warn("Failed to decode JSON data for user", userId)
            data = {}
        end
    end

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

-- [[ Saving Functions ]]
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

    local jsonData
    success, jsonData = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not success then
        warn("Failed to encode data to JSON:", jsonData)
        return false
    end

    repeat
        success = pcall(function()
            dataStore:SetAsync(userId, jsonData)
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

    self:ProcessGlobal(true)
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

-- [[ Global Functions ]]
function DataService:GetGlobal(key, forceRefresh)
    if not cache.global then
        cache.global = {}
    end

    if cache.global[key] == nil or forceRefresh then
        local globalStoreKey = "GLOBAL_" .. key
        local success, data = pcall(function()
            return dataStore:GetAsync(globalStoreKey)
        end)

        if success and data then
            if type(data) == "string" then
                local deserializeSuccess, deserializedData = pcall(function()
                    return HttpService:JSONDecode(data)
                end)

                if deserializeSuccess then
                    cache.global[key] = deserializedData
                else
                    warn("Failed to decode JSON global data for key", key)
                    cache.global[key] = Modules.Data.Templates[key] and self:DeepCopy(Modules.Data.Templates[key]) or {}
                end
            else
                cache.global[key] = data
            end
        else
            if Modules.Data.Templates[key] then
                cache.global[key] = self:DeepCopy(Modules.Data.Templates[key])
            else
                cache.global[key] = {}
            end
        end
    end

    return cache.global[key]
end

function DataService:SetGlobal(key, data)
    if not cache.global then
        cache.global = {}
    end

    if type(data) == "table" then
        data.lastUpdate = os.time()
    end

    cache.global[key] = data

    cache.globalChanges[key] = (cache.globalChanges[key] or 0) + 1

    local currentTime = os.time()
    local lastSaveTime = cache.lastGlobalSave[key] or 0
    local timeElapsed = currentTime - lastSaveTime

    local shouldSaveNow = false

    if cache.globalChanges[key] >= GLOBAL_SAVE_THRESHOLD then
        shouldSaveNow = true
    end

    if shouldSaveNow then
        return self:SaveGlobal(key, true)
    end

    return true
end

function DataService:ProcessGlobal(force)
    local currentTime = os.time()

    for key, changes in pairs(cache.globalChanges) do
        local lastSaveTime = cache.lastGlobalSave[key] or 0
        local timeElapsed = currentTime - lastSaveTime

        if changes > 0 and (force or
                           changes >= GLOBAL_SAVE_THRESHOLD or
                           timeElapsed >= GLOBAL_SAVE_INTERVAL) then
            self:SaveGlobal(key, true)
            cache.globalChanges[key] = 0
            cache.lastGlobalSave[key] = currentTime
        end
    end
end

function DataService:SaveGlobal(key, forced)
    if not self.GLOBAL_KEYS[key] then
        warn("Invalid global key:", key)
        return false
    end

    if not cache.global or cache.global[key] == nil then
        return false
    end

    local globalData = cache.global[key]
    if not globalData then return false end

    if type(globalData) == "table" then
        globalData.lastUpdate = os.time()
    end

    if not forced then
        cache.globalChanges[key] = (cache.globalChanges[key] or 0) + 1
        return true
    end

    local globalStoreKey = "GLOBAL_" .. key

    local jsonSuccess, jsonData = pcall(function()
        return HttpService:JSONEncode(cache.global[key])
    end)

    if not jsonSuccess then
        warn("Failed to encode global data to JSON:", jsonData)
        return false
    end

    local success, result = pcall(function()
        return dataStore:SetAsync(globalStoreKey, jsonData)
    end)

    if success then
        Services.Event:Fire("Data.Global", {
            key = key,
            data = cache.global[key]
        })

        self:PublishGlobal(key)
        cache.lastGlobalSave[key] = os.time()
    end

    return success
end

function DataService:SubscribeGlobal()
    local success, connection = pcall(function()
        return MessagingService:SubscribeAsync(MESSAGE_TOPIC, function(message)
            if type(message) ~= "table" or type(message.Data) ~= "table" then return end

            local data = message.Data
            if not data.key then return end

            if data.serverId and data.serverId == game.JobId then
                return
            end

            if cache.global[data.key] then
                if data.timestamp and cache.global[data.key].lastUpdate and
                   data.timestamp <= cache.global[data.key].lastUpdate then
                    return
                end

                cache.global[data.key] = nil

                local freshData = self:GetGlobal(data.key)
                if freshData then
                    Services.Event:Fire("Data.Global", {
                        key = data.key,
                        data = freshData
                    })
                end
            end
        end)
    end)

    if not success then
        warn("Failed to subscribe to global updates:", connection)
    end
end

function DataService:PublishGlobal(key)
    local timestamp = os.time()

    if not cache.global[key] then return end

    pcall(function()
        MessagingService:PublishAsync(MESSAGE_TOPIC, {
            key = key,
            serverId = game.JobId,
            timestamp = timestamp
        })
    end)
end

function DataService:ValidateGlobal(key)
    if not self.GLOBAL_KEYS[key] then
        warn("Invalid global key:", key)
        return nil
    end

    local globalData = self:GetGlobal(key)

    if not globalData then
        if Modules.Data.Templates[key] then
            globalData = self:DeepCopy(Modules.Data.Templates[key])
            self:SetGlobal(key, globalData)
        else
            warn("No template available for key:", key)
            return {}
        end
    end

    return globalData
end

function DataService:AddGlobal(key, listName, item, maxItems, uniqueField)
    if not self.GLOBAL_KEYS[key] then
        warn("Invalid global key:", key)
        return false
    end

    local globalData = self:ValidateGlobal(key)
    if not globalData then return false end

    if not globalData[listName] then
        globalData[listName] = {}
    end

    if uniqueField and item[uniqueField] then
        local existingIndex = nil
        for i, existingItem in ipairs(globalData[listName]) do
            if existingItem[uniqueField] == item[uniqueField] then
                existingIndex = i
                break
            end
        end

        if existingIndex then
            globalData[listName][existingIndex] = item
        else
            table.insert(globalData[listName], item)
        end
    else
        table.insert(globalData[listName], item)
    end

    if maxItems and #globalData[listName] > maxItems then
        while #globalData[listName] > maxItems do
            table.remove(globalData[listName], 1)
        end
    end

    return self:SaveGlobal(key, false)
end

function DataService:RemoveGlobal(key, listName, itemIdentifier, identifierField)
    if not self.GLOBAL_KEYS[key] then
        warn("Invalid global key:", key)
        return false
    end

    local globalData = self:ValidateGlobal(key)
    if not globalData or not globalData[listName] then return false end

    local listChanged = false
    local newList = {}

    for i, item in ipairs(globalData[listName]) do
        if not (identifierField and item[identifierField] == itemIdentifier) and
           not (item == itemIdentifier) then
            table.insert(newList, item)
        else
            listChanged = true
        end
    end

    if listChanged then
        globalData[listName] = newList
        return self:SaveGlobal(key, false)
    end

    return false
end

return DataService
