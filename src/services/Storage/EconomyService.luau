--[[ EconomyService
    Manages the Umbrels currency system for Ascendium.
    Handles player balances, rewards, and transaction history.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local EconomyService = {}

--[[ Dependencies ]]
EconomyService.Dependencies = {
    "Event",
    "Data"
}

--[[ Events ]]
EconomyService.Events = {
    Balance = true,
    Transaction = true,
    Purchase = true,
    Reward = true
}

--[[ Types ]]
type Balance = {
    amount: number,
    lastUpdated: number,
    metadata: {[string]: any}?
}

type Transaction = {
    id: string,
    userId: string,
    amount: number,
    type: string,
    timestamp: number,
    metadata: {[string]: any}?
}

type Multiplier = {
    id: string,
    value: number,
    transactionType: string?,
    startTime: number?,
    endTime: number?,
    metadata: {[string]: any}?
}

--[[ Constants ]]
local TRANSACTION_TYPES = {
    ADD = "add",
    REMOVE = "remove",
    PURCHASE = "purchase",
    REWARD = "reward",
    TRANSFER = "transfer",
    ENEMY_DROP = "enemy_drop",
    QUEST_REWARD = "quest_reward",
    EXPLORATION = "exploration",
    CRAFTING = "crafting",
    ARENA = "arena"
}

local CURRENCY_CONFIG = {
    MAX_BALANCE = 1000000,
    STARTING_BALANCE = 50,
    CURRENCY_NAME = "Umbrels"
}

--[[ State ]]
local Services
local Modules
local state = {
    balances = {} :: {[string]: Balance},
    transactions = {} :: {[string]: {Transaction}},
    multipliers = {} :: {[string]: {[string]: Multiplier}}
}

--[[ Event Listeners ]]
EconomyService.Listeners = {
    ["Data.Init"] = function(self, data)
        if not data or not data.userId or not data.player then return end

        local userId = data.userId
        local playerData = data.data.PlayerData

        if playerData and playerData.economy then
            state.balances[userId] = {
                amount = playerData.economy.balance or CURRENCY_CONFIG.STARTING_BALANCE,
                lastUpdated = playerData.economy.lastUpdated or os.time(),
                metadata = playerData.economy.metadata
            }

            state.transactions[userId] = playerData.economy.transactions or {}

            state.multipliers[userId] = playerData.economy.multipliers or {}
        else
            state.balances[userId] = {
                amount = CURRENCY_CONFIG.STARTING_BALANCE,
                lastUpdated = os.time()
            }
            state.transactions[userId] = {}
            state.multipliers[userId] = {}
        end

        local balance = state.balances[userId]
        Services.Event:FireTo(data.player, "Client.Economy.Balance", {
            userId = userId,
            balance = balance.amount,
            metadata = balance.metadata
        })
        data.player:SetAttribute("UMBRELS", balance.amount)
    end
}

--[[ Core Functions ]]
function EconomyService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function EconomyService:Start()
    return true
end

--[[ Balance Management ]]
function EconomyService:GetBalance(userId: string): number
    local balance = state.balances[userId]
    return balance and balance.amount or 0
end

function EconomyService:SetBalance(userId: string, amount: number, metadata: {[string]: any}?): boolean
    amount = math.floor(amount)
    if amount < 0 then return false end
    if amount > CURRENCY_CONFIG.MAX_BALANCE then
        amount = CURRENCY_CONFIG.MAX_BALANCE
    end

    state.balances[userId] = {
        amount = amount,
        lastUpdated = os.time(),
        metadata = metadata
    }

    Services.Event:Fire("Economy.Balance", {
        userId = userId,
        balance = amount,
        metadata = metadata
    })

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if player then
        player:SetAttribute("UMBRELS", amount)
    end

    return true
end

function EconomyService:AdjustBalance(
    userId: string,
    amount: number,
    transactionType: string,
    metadata: {[string]: any}?
): boolean
    local currentBalance = self:GetBalance(userId)
    local newBalance = currentBalance + amount

    if newBalance < 0 then return false end

    local success = self:SetBalance(userId, newBalance, metadata)
    if success then
        state.transactions[userId] = state.transactions[userId] or {}

        local transaction = {
            id = Services.Data:GenerateId("UUID"),
            userId = userId,
            amount = amount,
            type = transactionType,
            timestamp = os.time(),
            metadata = metadata
        }

        table.insert(state.transactions[userId], transaction)

        if #state.transactions[userId] > 100 then
            table.remove(state.transactions[userId], 1)
        end

        Services.Event:Fire("Economy.Transaction", {
            userId = userId,
            amount = amount,
            type = transactionType,
            balance = newBalance,
            metadata = metadata
        })
    end

    return success
end

--[[ Multiplier Management ]]
function EconomyService:AddMultiplier(userId: string, multiplier: Multiplier): string
    if not state.multipliers[userId] then
        state.multipliers[userId] = {}
    end

    local id = multiplier.id or Services.Data:GenerateId("UUID")
    state.multipliers[userId][id] = {
        id = id,
        value = multiplier.value,
        transactionType = multiplier.transactionType,
        startTime = multiplier.startTime,
        endTime = multiplier.endTime,
        metadata = multiplier.metadata
    }

    return id
end

function EconomyService:RemoveMultiplier(userId: string, multiplierId: string): boolean
    if not state.multipliers[userId] then return false end
    if not state.multipliers[userId][multiplierId] then return false end

    state.multipliers[userId][multiplierId] = nil
    return true
end

function EconomyService:GetMultipliers(
    userId: string,
    transactionType: string?
): {Multiplier}
    if not state.multipliers[userId] then return {} end

    local currentTime = os.time()
    local activeMultipliers = {}

    for _, multiplier in pairs(state.multipliers[userId]) do
        local isTimeValid = true
        if multiplier.startTime and multiplier.startTime > currentTime then
            isTimeValid = false
        end
        if multiplier.endTime and multiplier.endTime < currentTime then
            isTimeValid = false
        end

        local isTypeValid = not transactionType or not multiplier.transactionType or multiplier.transactionType == transactionType

        if isTimeValid and isTypeValid then
            table.insert(activeMultipliers, multiplier)
        end
    end

    return activeMultipliers
end

function EconomyService:CalculateMultipliers(
    userId: string,
    amount: number,
    transactionType: string
): number
    local multipliers = self:GetMultipliers(userId, transactionType)
    local finalMultiplier = 1

    for _, multiplier in ipairs(multipliers) do
        finalMultiplier = finalMultiplier * multiplier.value
    end

    return math.floor(amount * finalMultiplier)
end

--[[ Transaction Helpers ]]
function EconomyService:AddCurrency(userId: string, amount: number, metadata: {[string]: any}?): boolean
    local multipliedAmount = self:CalculateMultipliers(userId, amount, TRANSACTION_TYPES.ADD)
    local meta = metadata or {}
    meta.originalAmount = amount
    meta.multipliedAmount = multipliedAmount
    return self:AdjustBalance(userId, multipliedAmount, TRANSACTION_TYPES.ADD, meta)
end

function EconomyService:RemoveCurrency(userId: string, amount: number, metadata: {[string]: any}?): boolean
    local multipliedAmount = self:CalculateMultipliers(userId, amount, TRANSACTION_TYPES.REMOVE)
    local meta = metadata or {}
    meta.originalAmount = amount
    meta.multipliedAmount = multipliedAmount
    return self:AdjustBalance(userId, -multipliedAmount, TRANSACTION_TYPES.REMOVE, meta)
end

function EconomyService:TransferCurrency(
    fromUserId: string,
    toUserId: string,
    amount: number,
    metadata: {[string]: any}?
): (boolean, string?)
    if amount <= 0 then
        return false, "Invalid amount"
    end

    local senderBalance = self:GetBalance(fromUserId)
    if senderBalance < amount then
        return false, "Insufficient balance"
    end

    local transferMeta = metadata or {}
    transferMeta.transfer = {
        from = fromUserId,
        to = toUserId,
        amount = amount,
        timestamp = os.time()
    }

    local success = self:RemoveCurrency(fromUserId, amount, transferMeta)
    if not success then
        return false, "Failed to remove currency from sender"
    end

    success = self:AddCurrency(toUserId, amount, transferMeta)
    if not success then
        self:AddCurrency(fromUserId, amount, {
            rollback = true,
            originalTransaction = transferMeta
        })
        return false, "Failed to add currency to receiver"
    end

    Services.Event:Fire("Economy.Transaction", {
        type = TRANSACTION_TYPES.TRANSFER,
        from = {
            userId = fromUserId,
            amount = amount
        },
        to = {
            userId = toUserId,
            amount = amount
        },
        metadata = transferMeta
    })

    return true
end

function EconomyService:ProcessPurchase(
    buyerId: string,
    sellerId: string,
    cost: number,
    metadata: {[string]: any}?
): (boolean, string?)
    local purchaseMeta = metadata or {}
    purchaseMeta.purchase = {
        buyer = buyerId,
        seller = sellerId,
        cost = cost,
        timestamp = os.time()
    }

    local success, error = self:TransferCurrency(buyerId, sellerId, cost, purchaseMeta)
    if not success then
        return false, error
    end

    Services.Event:Fire("Economy.Purchase", {
        buyerId = buyerId,
        sellerId = sellerId,
        amount = cost,
        metadata = purchaseMeta
    })

    return true
end

function EconomyService:RewardCurrency(userId: string, amount: number, metadata: {[string]: any}?): boolean
    local success = self:AddCurrency(userId, amount, metadata)
    if success then
        Services.Event:Fire("Economy.Reward", {
            userId = userId,
            amount = amount,
            metadata = metadata
        })
    end
    return success
end

-- [[ History Functions ]]
function EconomyService:GetTransactions(userId: string, limit: number?): {Transaction}
    if not state.transactions[userId] then return {} end

    local transactions = state.transactions[userId]
    local result = {}

    limit = limit or #transactions

    for i = math.max(1, #transactions - limit + 1), #transactions do
        table.insert(result, transactions[i])
    end

    return result
end

function EconomyService:GetMetrics(userId: string): {[string]: any}
    local balance = self:GetBalance(userId)
    local transactions = self:GetTransactions(userId)

    local earned = 0
    local spent = 0
    local stats = {
        balance = balance,
        transactions = #transactions,
        earned = 0,
        spent = 0,
        sources = {}
    }

    for _, transaction in ipairs(transactions) do
        if transaction.amount > 0 then
            stats.earned = stats.earned + transaction.amount

            local source = transaction.type
            stats.sources[source] = (stats.sources[source] or 0) + transaction.amount
        elseif transaction.amount < 0 then
            stats.spent = stats.spent + math.abs(transaction.amount)
        end
    end

    return stats
end

return EconomyService