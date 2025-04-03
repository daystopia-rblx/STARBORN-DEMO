--[[ MovementService
    Manages player movement states and speed modifications.
    @author @Daystopia
    @version 1.1.2
    @date 2025-04-02
]]
local MovementService = {}

--[[ Dependencies ]]
MovementService.Dependencies = {
    "Event",
    "State"
}

MovementService.Modules = {
    "State",
    "Movement",
    "Stat"
}

--[[ Services ]]
local Services
local Modules

--[[ Events ]]
MovementService.Events = {
    Execute = true,
    Camera = true
}

--[[ State ]]
local state = {
    players = {} :: {[Player]: MovementState}
}

MovementService.Listeners = {
    ["State.Enter"] = function(self, data)
        if not data or not data.entity or not data.state then return end

        local stateTemplate = Modules.State.Templates[data.state]
        if not stateTemplate then return end

        if stateTemplate.metadata and stateTemplate.metadata.speedModifier then
            self:AddModifier(data.entity, data.state)
        end
    end,

    ["State.Exit"] = function(self, data)
        if not data or not data.entity or not data.state then return end

        local player = game.Players:GetPlayerFromCharacter(data.entity)
        if not player then return end

        local playerState = state.players[player]
        if not playerState then return end

        if playerState.cleanups and playerState.cleanups[data.state] then
            local cleanupFunc = playerState.cleanups[data.state]
            if type(cleanupFunc) == "function" then
                task.spawn(cleanupFunc)
            end
            playerState.cleanups[data.state] = nil
        end

        local stateTemplate = Modules.State.Templates[data.state]
        if stateTemplate and stateTemplate.metadata and stateTemplate.metadata.speedModifier then
            self:RemoveModifier(player, data.state)
        end
    end
}

--[[ Constants ]]
local CONTROL_SETTINGS = {}

--[[ Types ]]
type Modifier = {
    value: number,
    priority: number,
    duration: number?,
    startTime: number?,
    cleanupTask: any?
}

type MovementState = {
    isRunning: boolean,
    canJump: boolean,
    lastUpdate: number,
    baseSpeed: number?,
    modifiers: {[string]: Modifier},
    cleanups: {[string]: () -> ()}?
}

--[[ Core Functions ]]
function MovementService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function MovementService:Start()
    self:InitializeSettings()

    game.Players.PlayerAdded:Connect(function(player)
        self:InitializeMovement(player)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)

    for _, player in pairs(game.Players:GetPlayers()) do
        self:InitializeMovement(player)
    end

    return true
end

--[[ Settings Functions ]]
function MovementService:InitializeSettings()
    CONTROL_SETTINGS = {
        WALK_SPEED = Modules.Stat.Constants.MOVEMENT.BASE_WALK_SPEED,
        RUN_SPEED = Modules.Stat.Constants.MOVEMENT.BASE_WALK_SPEED * Modules.Stat.Constants.MOVEMENT.SPRINT_MULTIPLIER,
        CROUCH_SPEED = Modules.Stat.Constants.MOVEMENT.BASE_WALK_SPEED * Modules.Stat.Constants.MOVEMENT.CROUCH_MULTIPLIER,
        JUMP_POWER = Modules.Stat.Constants.MOVEMENT.JUMP_POWER,
        JUMP_HEIGHT = Modules.Stat.Constants.MOVEMENT.JUMP_HEIGHT,

        -- Camera Settings
        WALK_FOV = Modules.Stat.Constants.MOVEMENT.WALK_CAMERA_FOV,
        SPRINT_FOV = Modules.Stat.Constants.MOVEMENT.SPRINT_CAMERA_FOV,

        -- Movement Timings
        SPRINT_DOUBLE_TAP_DELAY = Modules.Stat.Constants.MOVEMENT.SPRINT_DOUBLE_TAP_DELAY,
        JUMP_DURATION = Modules.Stat.Constants.MOVEMENT.JUMP_DURATION,
        JUMP_FALL_SMOOTH_TIME = Modules.Stat.Constants.MOVEMENT.JUMP_FALL_SMOOTH_TIME,
        JUMP_COMBAT_COOLDOWN = Modules.Stat.Constants.MOVEMENT.JUMP_COMBAT_COOLDOWN,

        -- Movement Mechanics
        SLIDE_DURATION = Modules.Stat.Constants.MOVEMENT.SLIDE_DURATION,
        SLIDE_SPEED = Modules.Stat.Constants.MOVEMENT.BASE_WALK_SPEED * Modules.Stat.Constants.MOVEMENT.SLIDE_SPEED_MULTIPLIER,
        SLIDE_FRICTION = Modules.Stat.Constants.MOVEMENT.SLIDE_FRICTION,
        SLIDE_COOLDOWN = Modules.Stat.Constants.MOVEMENT.SLIDE_COOLDOWN,

        ROLL_DURATION = Modules.Stat.Constants.MOVEMENT.ROLL_DURATION_Z,
        ROLL_SPEED = Modules.Stat.Constants.MOVEMENT.ROLL_SPEED_Z,
        ROLL_FRICTION = Modules.Stat.Constants.MOVEMENT.ROLL_FRICTION_Z,
        ROLL_COOLDOWN = Modules.Stat.Constants.MOVEMENT.ROLL_COOLDOWN_Z,

        AIR_DASH_SPEED = Modules.Stat.Constants.MOVEMENT.AIR_DASH_SPEED,

        -- Wall Movement
        WALL_RUN_SPEED = Modules.Stat.Constants.MOVEMENT.WALL_RUN_SPEED,
        WALL_RUN_DURATION = Modules.Stat.Constants.MOVEMENT.WALL_RUN_DURATION,
        WALL_CLIMB_SPEED = Modules.Stat.Constants.MOVEMENT.WALL_CLIMB_SPEED,

        -- Limits
        MIN_SPEED = Modules.Stat.Constants.MOVEMENT.MIN_MOVEMENT_SPEED,
        MAX_SPEED = Modules.Stat.Constants.MOVEMENT.MAX_MOVEMENT_SPEED
    }
end

--[[ Movement Functions ]]
function MovementService:InitializeMovement(player: Player)
    player.DevEnableMouseLock = false

    state.players[player] = {
        isRunning = false,
        canJump = true,
        lastUpdate = 0,
        baseSpeed = nil,
        modifiers = {},
        cleanups = {}
    }
end

function MovementService:ExecuteMovement(movementType: string, player: Player, data: {[string]: any}?): (boolean, string?)
    if not movementType then
        return false, "No movement type provided"
    end

    local character = player.Character
    if not character then return false, "No character found" end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false, "No humanoid found" end

    local rootPart = character.PrimaryPart
    if not rootPart then return false, "No primary part found" end

    if movementType:upper() == "MOVE" then
        local currentStates = Services.State:GetStates(character)
        for stateName, _ in pairs(currentStates) do
            local currentTemplate = Modules.State.Templates[stateName]
            if currentTemplate and currentTemplate.exclusive then
                if not currentTemplate.transitions or currentTemplate.transitions.MOVE ~= true then
                   humanoid:Move(Vector3.zero)
                   return false, "Cannot MOVE while in exclusive state: " .. stateName
                end
            end
        end

        if data and data.direction then
            humanoid:Move(data.direction, true)
            return true, "Movement executed successfully"
        end
        return false, "No movement direction provided"
    end

    local stateType = movementType:upper()
    local stateTemplate = Modules.State.Templates[stateType]
    if not stateTemplate then return false, "Invalid movement type" end

    local currentStates = Services.State:GetStates(character)
    for stateName, _ in pairs(currentStates) do
        local currentTemplate = Modules.State.Templates[stateName]
        if currentTemplate and currentTemplate.exclusive then
            if not currentTemplate.transitions or currentTemplate.transitions[stateType] ~= true then
               return false, "Cannot transition to " .. stateType .. " from exclusive state: " .. stateName
            end
        end
    end

    local handlerName = movementType:sub(1,1):upper() .. movementType:sub(2):lower()
    local handler = Modules.Movement.Handlers[handlerName]
    if not handler then return false, "No handler found for movement type: " .. handlerName end

    local metadata = data or {}

    local success = Services.State:EnterState(character, stateType, {
        category = "MOVEMENT",
        duration = stateTemplate.duration,
        cooldown = stateTemplate.cooldown,
        metadata = metadata
    })

    if not success then
        warn("Failed to enter movement state:", stateType)
        return false, "Failed to enter movement state"
    end

    local executionResult = handler:Execute(character, data)
    if executionResult and executionResult.cleanup then
        local playerState = state.players[player]
        if playerState then
            if not playerState.cleanups then playerState.cleanups = {} end
            playerState.cleanups[stateType] = executionResult.cleanup
        end
    end

    if stateTemplate.metadata and stateTemplate.metadata.speedModifier then
        self:SetSpeed(player)
    end

    return true, "Movement executed successfully"
end

function MovementService:SetSpeed(player: Player)
    local playerState = state.players[player]
    if not playerState then return end

    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local baseSpeed = playerState.baseSpeed or (playerState.isRunning and CONTROL_SETTINGS.RUN_SPEED or CONTROL_SETTINGS.WALK_SPEED)

    local activeStates = Services.State:GetStates(player)
    local stateModifiers = {}

    if activeStates then
        for stateName in pairs(activeStates) do
            local stateTemplate = Modules.State.Templates[stateName]
            if stateTemplate and stateTemplate.metadata and stateTemplate.metadata.speedModifier then
                table.insert(stateModifiers, {
                    value = stateTemplate.metadata.speedModifier,
                    priority = stateTemplate.metadata.speedPriority or 0
                })
            end
        end
    end

    table.sort(stateModifiers, function(a, b)
        return a.priority > b.priority
    end)

    local finalSpeed = baseSpeed
    for _, modifier in ipairs(stateModifiers) do
        finalSpeed *= modifier.value
    end

    humanoid.WalkSpeed = finalSpeed
    humanoid.JumpPower = CONTROL_SETTINGS.JUMP_POWER
end

--[[ Modifier Functions ]]
function MovementService:AddModifier(player: Player, id: string, value: number?, options: {priority: number?, duration: number?}?): boolean
    local playerState = state.players[player]
    if not playerState then return false end

    local stateTemplate = Modules.State:GetTemplate(id)
    if not stateTemplate or not stateTemplate.metadata or not stateTemplate.metadata.speedModifier then
        return false
    end

    value = stateTemplate.metadata.speedModifier
    options = {
        priority = stateTemplate.metadata.speedPriority or 0,
        duration = stateTemplate.duration
    }

    local existingModifier = playerState.modifiers[id]
    if existingModifier and existingModifier.cleanupTask then
        task.cancel(existingModifier.cleanupTask)
    end

    local modifier: Modifier = {
        value = value,
        priority = options.priority,
        duration = options.duration,
        startTime = options.duration and os.time() or nil,
        cleanupTask = nil
    }

    if options.duration then
        modifier.cleanupTask = task.delay(options.duration, function()
            self:RemoveModifier(player, id)
        end)
    end

    playerState.modifiers[id] = modifier
    self:SetSpeed(player)
    return true
end

function MovementService:RemoveModifier(player: Player, id: string): boolean
    local playerState = state.players[player]
    if not playerState or not playerState.modifiers[id] then return false end

    local modifier = playerState.modifiers[id]
    if modifier.cleanupTask then
        task.cancel(modifier.cleanupTask)
    end

    playerState.modifiers[id] = nil
    self:SetSpeed(player)
    return true
end

--[[ Utility Functions ]]
function MovementService:GetModifiers(player: Player): {[string]: Modifier}?
    local playerState = state.players[player]
    return playerState and playerState.modifiers
end

function MovementService:GetSpeed(player: Player): number?
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    return humanoid and humanoid.WalkSpeed
end

function MovementService:CleanupPlayer(player: Player)
    local playerState = state.players[player]
    if not playerState then return end

    if playerState.cleanups then
        for stateName, cleanupFunc in pairs(playerState.cleanups) do
             if type(cleanupFunc) == "function" then
                task.spawn(cleanupFunc)
            end
        end
    end

    for _, modifier in pairs(playerState.modifiers) do
        if modifier.cleanupTask then
            task.cancel(modifier.cleanupTask)
        end
    end

    state.players[player] = nil
end

return MovementService