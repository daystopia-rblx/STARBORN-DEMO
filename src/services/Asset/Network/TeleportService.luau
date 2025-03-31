--[[ TeleportService
    Handles player teleportation between places and servers
    @author @Daystopia
    @version 1.0.0
    @date 2025-02-06
]]
local TeleportService = {}

--[[ Dependencies ]]
TeleportService.Dependencies = {
    "Event",
    "Data"
}

--[[ Services ]]
local RobloxTeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

--[[ Events ]]
TeleportService.Events = {
    Init = true,
    Fail = true,
    Success = true,
    Queue = true,
    Retry = true
}

--[[ Types ]]
type TeleportOptions = {
    loadingScreen: Instance?,
    spawnName: string?,
    serverInstanceId: string?,
    reservedServerAccessCode: string?,
    shouldReserveServer: boolean?,
    teleportData: {[string]: any}?,
    retryCount: number?,
    retryDelay: number?,
    queuePriority: number?,
    validateServer: (placeId: number, jobId: string) -> boolean?,
    onRetry: (attempt: number, error: string) -> boolean?
}

type TeleportResult = {
    success: boolean,
    error: string?,
    jobId: string?,
    placeId: number?,
    options: TeleportOptions?,
    attempts: number?
}

type QueuedTeleport = {
    players: {Player},
    placeId: number,
    options: TeleportOptions,
    priority: number,
    timestamp: number
}

type LoadingScreenConfig = {
    gui: Instance,
    transitionIn: {
        duration: number?,
        style: Enum.EasingStyle?,
        direction: Enum.EasingDirection?
    }?,
    transitionOut: {
        duration: number?,
        style: Enum.EasingStyle?,
        direction: Enum.EasingDirection?
    }?,
    customData: {[string]: any}?,
    preserveOnLoad: boolean?
}

type LoadingScreenState = {
    gui: Instance,
    config: LoadingScreenConfig,
    active: boolean,
    timestamp: number
}

--[[ Constants ]]
local DEFAULT_RETRY_COUNT = 3
local DEFAULT_RETRY_DELAY = 1
local MAX_GROUP_SIZE = 50
local TELEPORT_QUEUE_CHECK_INTERVAL = 1

local DEFAULT_TRANSITION = {
    duration = 0.5,
    style = Enum.EasingStyle.Quad,
    direction = Enum.EasingDirection.Out
}

local LOADING_SCREEN_TYPES = {
    DEFAULT = "default",
    MATCHMAKING = "matchmaking",
    PRIVATE_SERVER = "private_server",
    RETRY = "retry"
}

--[[ State ]]
local Services
local state = {
    teleportHistory = {},
    reservedServers = {},
    loadingScreens = {} :: {[string]: LoadingScreenState},
    activeScreen = nil :: string?,
    teleportQueue = {},
    activeRetries = {},
    loadingScreensEnabled = false
}

--[[ Event Listeners ]]
TeleportService.Listeners = {
    [RobloxTeleportService.TeleportInitFailed] = function(self, player: Player, teleportResult: Enum.TeleportResult, errorMessage: string, placeId: number, teleportOptions: any)
        local result = {
            success = false,
            error = errorMessage,
            placeId = placeId,
            options = teleportOptions,
            result = teleportResult
        }

        Services.Event:Fire("Teleport.Fail", {
            userId = player.UserId,
            result = result
        })

        table.insert(state.teleportHistory, {
            timestamp = os.time(),
            type = "FAILED",
            userId = player.UserId,
            result = result
        })

        self:FailTeleport(player, result)
    end,

    ["Players.PlayerRemoving"] = function(self, player: Player)
        if state.activeRetries[player.UserId] then
            state.activeRetries[player.UserId] = nil
        end
    end
}

--[[ Core Functions ]]
function TeleportService:Init(services)
    Services = services
    self:StartQueue()
    return true
end

--[[ Teleport Functions ]]
function TeleportService:TeleportPlayer(
    player: Player,
    placeId: number,
    options: TeleportOptions?
): TeleportResult
    if not player or not placeId then
        warn("Invalid player or placeId")
        return { success = false, error = "Invalid player or placeId" }
    end

    options = options or {}
    local attempt = if state.activeRetries[player.UserId] then state.activeRetries[player.UserId].attempt + 1 else 1

    local teleportOptions = Instance.new("TeleportOptions")
    if options.serverInstanceId then
        if not self:ValidateServer(placeId, options.serverInstanceId, options) then
            return { success = false, error = "Server validation failed", attempts = attempt }
        end
        teleportOptions.ServerInstanceId = options.serverInstanceId
    end
    if options.reservedServerAccessCode then
        teleportOptions.ReservedServerAccessCode = options.reservedServerAccessCode
    end
    if options.shouldReserveServer then
        teleportOptions.ShouldReserveServer = true
    end
    if options.teleportData then
        teleportOptions:SetTeleportData(options.teleportData)
    end

    if options.loadingScreen then
        RobloxTeleportService:SetTeleportGui(options.loadingScreen)
    end

    local attemptData = {
        timestamp = os.time(),
        type = "INITIATED",
        userId = player.UserId,
        placeId = placeId,
        options = options,
        attempt = attempt
    }
    table.insert(state.teleportHistory, attemptData)

    Services.Event:Fire("Teleport.Init", attemptData)

    local success, result = pcall(function()
        return RobloxTeleportService:TeleportAsync(placeId, {player}, teleportOptions)
    end)

    if success and result then
        if state.activeRetries[player.UserId] then
            state.activeRetries[player.UserId] = nil
        end

        Services.Event:Fire("Teleport.Success", {
            userId = player.UserId,
            placeId = placeId,
            jobId = result.PrivateServerId,
            attempt = attempt
        })

        return {
            success = true,
            jobId = result.PrivateServerId,
            placeId = placeId,
            options = options,
            attempts = attempt
        }
    else
        local error = if success then "Teleport failed" else result

        if self:RetryTeleport(player, placeId, options, error, attempt) then
            return {
                success = false,
                error = error,
                placeId = placeId,
                options = options,
                attempts = attempt
            }
        end

        return {
            success = false,
            error = error,
            placeId = placeId,
            options = options,
            attempts = attempt
        }
    end
end

function TeleportService:TeleportGroup(
    players: {Player},
    placeId: number,
    options: TeleportOptions?
): TeleportResult
    if not players or #players == 0 or not placeId then
        warn("Invalid players or placeId")
        return { success = false, error = "Invalid players or placeId" }
    end

    if #players > MAX_GROUP_SIZE then
        return { success = false, error = "Group size exceeds maximum limit" }
    end

    options = options or {}

    local teleportOptions = Instance.new("TeleportOptions")
    if options.serverInstanceId then
        if not self:ValidateServer(placeId, options.serverInstanceId, options) then
            return { success = false, error = "Server validation failed" }
        end
        teleportOptions.ServerInstanceId = options.serverInstanceId
    end
    if options.reservedServerAccessCode then
        teleportOptions.ReservedServerAccessCode = options.reservedServerAccessCode
    end
    if options.shouldReserveServer then
        teleportOptions.ShouldReserveServer = true
    end
    if options.teleportData then
        teleportOptions:SetTeleportData(options.teleportData)
    end

    local attemptData = {
        timestamp = os.time(),
        type = "GROUP_INITIATED",
        userIds = {},
        placeId = placeId,
        options = options
    }
    for _, player in ipairs(players) do
        table.insert(attemptData.userIds, player.UserId)
    end
    table.insert(state.teleportHistory, attemptData)

    Services.Event:Fire("Teleport.Init", attemptData)

    local success, result = pcall(function()
        return RobloxTeleportService:TeleportAsync(placeId, players, teleportOptions)
    end)

    if success and result then
        Services.Event:Fire("Teleport.Success", {
            userIds = attemptData.userIds,
            placeId = placeId,
            jobId = result.PrivateServerId
        })

        return {
            success = true,
            jobId = result.PrivateServerId,
            placeId = placeId,
            options = options
        }
    else
        return {
            success = false,
            error = if success then "Group teleport failed" else result,
            placeId = placeId,
            options = options
        }
    end
end

function TeleportService:RetryTeleport(
    player: Player,
    placeId: number,
    options: TeleportOptions,
    error: string,
    attempt: number
): boolean
    local maxRetries = options.retryCount or DEFAULT_RETRY_COUNT
    local retryDelay = options.retryDelay or DEFAULT_RETRY_DELAY

    if attempt >= maxRetries then return false end

    if options.onRetry then
        local success, shouldRetry = pcall(options.onRetry, attempt, error)
        if not success or not shouldRetry then return false end
    end

    Services.Event:Fire("Teleport.Retry", {
        userId = player.UserId,
        placeId = placeId,
        attempt = attempt,
        error = error
    })

    state.activeRetries[player.UserId] = {
        attempt = attempt,
        timestamp = os.time()
    }

    task.delay(retryDelay, function()
        if player.Parent ~= Players then return end
        self:TeleportPlayer(player, placeId, options)
    end)

    return true
end

function TeleportService:FailTeleport(player: Player, result: TeleportResult)
    if result.options then
        self:RetryTeleport(player, result.placeId, result.options, result.error or "Unknown error", result.attempts or 1)
    end
end

--[[ Queue Functions ]]
function TeleportService:QueueTeleport(
    players: {Player} | Player,
    placeId: number,
    options: TeleportOptions?
): boolean

    options = options or {}
    local playerList = if typeof(players) == "table" then players else {players}

    if #playerList > MAX_GROUP_SIZE then
        return false
    end

    local queuedTeleport: QueuedTeleport = {
        players = playerList,
        placeId = placeId,
        options = options,
        priority = options.queuePriority or 0,
        timestamp = os.time()
    }

    table.insert(state.teleportQueue, queuedTeleport)
    table.sort(state.teleportQueue, function(a, b)
        if a.priority == b.priority then
            return a.timestamp < b.timestamp
        end
        return a.priority > b.priority
    end)

    Services.Event:Fire("Teleport.Queue", {
        players = playerList,
        placeId = placeId,
        options = options
    })

    return true
end

function TeleportService:StartQueue()
    task.spawn(function()
        while true do
            self:ProcessQueue()
            task.wait(TELEPORT_QUEUE_CHECK_INTERVAL)
        end
    end)
end

function TeleportService:ProcessQueue()
    if #state.teleportQueue == 0 then return end

    local nextTeleport = table.remove(state.teleportQueue, 1)
    if not nextTeleport then return end

    local validPlayers = {}
    for _, player in ipairs(nextTeleport.players) do
        if player.Parent == Players then
            table.insert(validPlayers, player)
        end
    end

    if #validPlayers > 0 then
        if #validPlayers == 1 then
            self:TeleportPlayer(validPlayers[1], nextTeleport.placeId, nextTeleport.options)
        else
            self:TeleportGroup(validPlayers, nextTeleport.placeId, nextTeleport.options)
        end
    end
end

-- [[ Server Functions ]]
function TeleportService:ReserveServer(placeId: number): (string?, string?)
    local success, accessCode, privateServerId = pcall(function()
        return RobloxTeleportService:ReserveServer(placeId)
    end)

    if success then
        state.reservedServers[accessCode] = {
            placeId = placeId,
            privateServerId = privateServerId,
            timestamp = os.time()
        }
        return accessCode, privateServerId
    end
    return nil, "Failed to reserve server"
end

function TeleportService:ValidateServer(placeId: number, jobId: string, options: TeleportOptions?): boolean
    if not options or not options.validateServer then return true end

    local success, isValid = pcall(options.validateServer, placeId, jobId)
    if not success then
        warn("Failed to validate server")
        return false
    end
    return isValid
end

function TeleportService:GetServer(userId: number): (number?, string?)
    local success, placeId, jobId = pcall(function()
        return RobloxTeleportService:GetPlayerPlaceInstanceAsync(userId)
    end)

    if success then
        return placeId, jobId
    end
    return nil, "Failed to get player server"
end

function TeleportService:GetData(player: Player): {[string]: any}?
    local success, data = pcall(function()
        return RobloxTeleportService:GetLocalPlayerTeleportData()
    end)

    if success and data then
        return data
    end
    return nil
end

-- [[ Loading Screen Functions ]]
function TeleportService:RegisterScreen(
    name: string,
    config: LoadingScreenConfig
): boolean
    if not state.loadingScreensEnabled then return false end

    if not config.gui or not config.gui:IsA("ScreenGui") then
        return false
    end

    if config.customData and config.customData.type then
        local isValidType = false
        for _, screenType in pairs(LOADING_SCREEN_TYPES) do
            if config.customData.type == screenType then
                isValidType = true
                break
            end
        end
        if not isValidType then
            warn(string.format("Invalid loading screen type: %s", config.customData.type))
            return false
        end
    else
        config.customData = config.customData or {}
        config.customData.type = LOADING_SCREEN_TYPES.DEFAULT
    end

    config.transitionIn = config.transitionIn or DEFAULT_TRANSITION
    config.transitionOut = config.transitionOut or DEFAULT_TRANSITION

    state.loadingScreens[name] = {
        gui = config.gui,
        config = config,
        active = false,
        timestamp = os.time()
    }

    return true
end

function TeleportService:SetScreen(
    name: string | Instance,
    customData: {[string]: any}?
)
    if not state.loadingScreensEnabled then return end

    if typeof(name) == "Instance" then
        local screen = name
        name = screen.Name
        self:RegisterScreen(name, {
            gui = screen,
            customData = customData
        })
    end

    local screenState = state.loadingScreens[name]
    if not screenState then return end

    if customData then
        screenState.config.customData = customData
    end

    state.activeScreen = name

    RobloxTeleportService:SetTeleportGui(screenState.gui)
end

function TeleportService:GetActiveScreen(): (LoadingScreenState?, string?)
    if not state.activeScreen then
        return nil, "No active loading screen"
    end
    return state.loadingScreens[state.activeScreen]
end

function TeleportService:TransitionScreen(
    name: string,
    transitionType: "in" | "out"
): boolean
    local screenState = state.loadingScreens[name]
    if not screenState then return false end

    local transition = if transitionType == "in"
        then screenState.config.transitionIn
        else screenState.config.transitionOut

    if not transition then return false end

    local gui = screenState.gui
    if not gui then return false end

    local tweenInfo = TweenInfo.new(
        transition.duration or DEFAULT_TRANSITION.duration,
        transition.style or DEFAULT_TRANSITION.style,
        transition.direction or DEFAULT_TRANSITION.direction
    )

    local targetTransparency = if transitionType == "in" then 0 else 1
    local tween = game:GetService("TweenService"):Create(gui, tweenInfo, {
        BackgroundTransparency = targetTransparency,
        GroupTransparency = targetTransparency
    })

    tween:Play()
    screenState.active = (transitionType == "in")

    return true
end

function TeleportService:ArriveScreen()
    local arrivingGui = RobloxTeleportService:GetArrivingTeleportGui()
    if not arrivingGui then return end

    local screenName
    for name, state in pairs(state.loadingScreens) do
        if state.gui == arrivingGui then
            screenName = name
            break
        end
    end

    if not screenName then
        screenName = arrivingGui.Name
        self:RegisterScreen(screenName, {
            gui = arrivingGui,
            preserveOnLoad = true
        })
    end

    local screenState = state.loadingScreens[screenName]
    if not screenState then return end

    if screenState.config.preserveOnLoad then
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        arrivingGui.Parent = playerGui

        task.spawn(function()
            self:TransitionScreen(screenName, "out")
            task.wait(screenState.config.transitionOut.duration or DEFAULT_TRANSITION.duration)
            if not screenState.config.preserveOnLoad then
                arrivingGui:Destroy()
            end
        end)
    else
        arrivingGui:Destroy()
    end
end

function TeleportService:GetScreens(screenType: string?): {[string]: LoadingScreenState}
    if not screenType then
        return state.loadingScreens
    end

    local filtered = {}
    for name, screenState in pairs(state.loadingScreens) do
        if screenState.config.customData and screenState.config.customData.type == screenType then
            filtered[name] = screenState
        end
    end
    return filtered
end

function TeleportService:ClearScreen(name: string)
    local screenState = state.loadingScreens[name]
    if not screenState then return end

    if screenState.active then
        self:TransitionScreen(name, "out")
    end

    if state.activeScreen == name then
        state.activeScreen = nil
    end

    state.loadingScreens[name] = nil
end

-- [[ History Functions ]]
function TeleportService:GetHistory(userId: number?): {any}
    if userId then
        local userHistory = {}
        for _, record in ipairs(state.teleportHistory) do
            if record.userId == userId or (record.userIds and table.find(record.userIds, userId)) then
                table.insert(userHistory, record)
            end
        end
        return userHistory
    end
    return state.teleportHistory
end

return TeleportService