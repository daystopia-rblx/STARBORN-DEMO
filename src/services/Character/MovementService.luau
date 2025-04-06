--[[ MovementService
    Core movement system for character state management.
    Manages character movement state transitions and physics.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-05
]]
local MovementService = {}

MovementService.Dependencies = {
    "Event",
    "Stat"
}

MovementService.Events = {
    State = { validate = true }
}

MovementService.Listeners = {
    ["Players.PlayerAdded"] = function(self, player)
        player.CharacterAdded:Connect(function(character)
            self:SetupCharacter(player, character)
        end)

        if player.Character then
            self:SetupCharacter(player, player.Character)
        end
    end
}

--[[ State Management ]]
local Players = game:GetService("Players")
local Services

--[[ Configuration ]]
local CONFIG = {
    MOVEMENT = {
        BASE_WALK_SPEED = 10,
        SPRINT_MULTIPLIER = 2.6,
        CROUCH_MULTIPLIER = 0.7
    },

    STATES = {
        RUNNING = {
            priority = 2,
            fieldName = "isSprinting",
            speedModifier = function(baseSpeed, multiplier)
                multiplier = multiplier or 1
                return baseSpeed * multiplier
            end,
            default = false
        },
        CROUCHING = {
            priority = 1,
            fieldName = "isCrouching",
            speedModifier = function(baseSpeed, multiplier)
                multiplier = multiplier or 1
                return baseSpeed * multiplier
            end,
            default = false
        },
        RAGDOLL = {
            priority = 3,
            fieldName = "isRagdoll",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        ROLL = {
            priority = 4,
            fieldName = "isRolling",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        SLIDE = {
            priority = 4,
            fieldName = "isSliding",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        DASH = {
            priority = 4,
            fieldName = "isDashing",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        VAULT = {
            priority = 4,
            fieldName = "isVaulting",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        CLIMB = {
            priority = 4,
            fieldName = "isClimbing",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        WALL_RUN = {
            priority = 4,
            fieldName = "isWallRunning",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        SWING = {
            priority = 4,
            fieldName = "isSwinging",
            speedModifier = function()
                return 0
            end,
            default = false
        },
        LEDGE = {
            priority = 4,
            fieldName = "isLedgeHanging",
            speedModifier = function()
                return 0
            end,
            default = false
        }
    },

    SPEED_MODIFIER = function(baseSpeed)
        return baseSpeed
    end
}

--[[ State ]]
local characterStates = {}

--[[ Core Functions ]]
function MovementService:Init(services)
    Services = services

    local Stat = require(script.Parent.Parent.Parent.Modules.StatModule)

    CONFIG.MOVEMENT.BASE_WALK_SPEED = Stat.Constants.MOVEMENT.BASE_WALK_SPEED or CONFIG.MOVEMENT.BASE_WALK_SPEED
    CONFIG.MOVEMENT.SPRINT_MULTIPLIER = Stat.Constants.MOVEMENT.SPRINT_MULTIPLIER or CONFIG.MOVEMENT.SPRINT_MULTIPLIER
    CONFIG.MOVEMENT.CROUCH_MULTIPLIER = Stat.Constants.MOVEMENT.CROUCH_MULTIPLIER or CONFIG.MOVEMENT.CROUCH_MULTIPLIER

    if not CONFIG.MOVEMENT.SPRINT_MULTIPLIER or CONFIG.MOVEMENT.SPRINT_MULTIPLIER == 0 then
        CONFIG.MOVEMENT.SPRINT_MULTIPLIER = 2.6
    end

    if not CONFIG.MOVEMENT.CROUCH_MULTIPLIER or CONFIG.MOVEMENT.CROUCH_MULTIPLIER == 0 then
        CONFIG.MOVEMENT.CROUCH_MULTIPLIER = 0.7
    end

    for _, player in pairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function(character)
            self:SetupCharacter(player, character)
        end)

        if player.Character then
            self:SetupCharacter(player, player.Character)
        end
    end

    return true
end

function MovementService:Start()
    return true
end

--[[ Helper Functions ]]
function MovementService:ValidateState(stateName)
    return CONFIG.STATES[stateName] ~= nil
end

function MovementService:GetPriority(character)
    local highestPriority = 0
    local highestState = nil

    for stateName, stateConfig in pairs(CONFIG.STATES) do
        if character:GetAttribute(stateName) and stateConfig.priority > highestPriority then
            highestPriority = stateConfig.priority
            highestState = stateName
        end
    end

    return highestState
end

--[[ Movement Functions ]]
function MovementService:SetState(character, stateName, value)
    if not character then return false end
    if not self:ValidateState(stateName) then return false end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end

    if character:GetAttribute(stateName) == value then return false end

    character:SetAttribute(stateName, value)
    self:UpdateSpeed(humanoid, character)
    return true
end

function MovementService:UpdateSpeed(humanoid, character)
    local baseSpeed = CONFIG.MOVEMENT.BASE_WALK_SPEED
    local activeState = self:GetPriority(character)

    if activeState and CONFIG.STATES[activeState] then
        local stateConfig = CONFIG.STATES[activeState]
        local multiplier = 1

        if activeState == "RUNNING" then
            multiplier = CONFIG.MOVEMENT.SPRINT_MULTIPLIER or 1
        elseif activeState == "CROUCHING" then
            multiplier = CONFIG.MOVEMENT.CROUCH_MULTIPLIER or 1
        end

        humanoid.WalkSpeed = stateConfig.speedModifier(baseSpeed, multiplier)
    else
        humanoid.WalkSpeed = CONFIG.SPEED_MODIFIER(baseSpeed)
    end
end

function MovementService:GetStates()
    local states = {}
    for stateName, stateConfig in pairs(CONFIG.STATES) do
        states[stateName] = stateConfig.default
    end
    return states
end

function MovementService:SetupCharacter(player, character)
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local states = self:GetStates()
    for stateName, defaultValue in pairs(states) do
        if character:GetAttribute(stateName) == nil then
            character:SetAttribute(stateName, defaultValue)
        end
    end

    characterStates[character] = {
        player = player,
        connections = {}
    }

    local connections = characterStates[character].connections

    for stateName, _ in pairs(CONFIG.STATES) do
        connections[stateName:lower()] = character:GetAttributeChangedSignal(stateName):Connect(function()
            self:UpdateSpeed(humanoid, character)
        end)
    end

    connections.ancestryChanged = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:CleanupCharacter(character)
        end
    end)

    self:UpdateSpeed(humanoid, character)
end

function MovementService:CleanupCharacter(character)
    if not characterStates[character] then return end

    for _, connection in pairs(characterStates[character].connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end

    characterStates[character] = nil
end

return MovementService