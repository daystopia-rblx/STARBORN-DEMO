--[[ ActionService
    Extensible action system for managing and executing interaction behaviors. 
    Handles action registration, validation, cooldowns, and state tracking.
    @author @Daystopia
    @version 1.0.5
    @date 2025-03-31
]]
local ActionService = {}

--[[ Dependencies ]]
ActionService.Dependencies = {
    "Event",
    "Object",
    "Interact",
    "Asset",
    "Tool"
}

--[[ Modules ]]
ActionService.Modules = {
    "Action",
    "Interact"
}

--[[ Events ]]
ActionService.Events = {
    Start = true,
    End = true,
    Fail = true,
    Persist = true
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Constants ]]
local DEFAULT_COOLDOWN = 0.1

--[[ Types ]]
local Types = require(game:GetService("ReplicatedStorage").Modules.ActionModule)
type ActionConfig = Types.ActionConfig
type ActionContext = Types.ActionContext
type ActionHandler = Types.ActionHandler

--[[ State ]]
local state = {
    handlers = {} :: {[string]: ActionHandler},
    activeActions = {} :: {[Player]: {[string]: ActionContext}},
    cooldowns = {} :: {[Player]: {[string]: number}},
    controllers = {} :: {[string]: string}
}

--[[ Listeners ]]
ActionService.Listeners = {
    ["Interact.Start"] = function(self, player, instance, context)
        if not (player and instance and context) then
            return
        end

        local actionType = context.interactionType:lower()

        self:ExecuteAction(actionType, {
            player = player,
            instance = instance,
            metadata = context.metadata
        })
    end,

    ["Player.Left"] = function(self, player)
        state.activeActions[player] = nil
        state.cooldowns[player] = nil
    end,

    ["Action.Persist"] = function(self, data)
        if data.context then
            self:EndPersist(data.context.actionType, data.context)
        end
    end
}

--[[ Utility Functions ]]
local function GetConfig(actionType: string): ActionConfig?
    return Modules.Action.Types[actionType:upper()]
end

local function ValidateCooldown(player: Player, actionType: string): (boolean, number?)
    local playerCooldowns = state.cooldowns[player]
    if not playerCooldowns then return true end

    local lastUse = playerCooldowns[actionType]
    if not lastUse then return true end

    local config = GetConfig(actionType)
    local cooldown = config and config.cooldown or DEFAULT_COOLDOWN
    local timeLeft = cooldown - (tick() - lastUse)

    return timeLeft <= 0, timeLeft > 0 and timeLeft or cooldown
end

local function SetCooldown(player: Player, actionType: string)
    state.cooldowns[player] = state.cooldowns[player] or {}
    state.cooldowns[player][actionType] = tick()
end

local function ValidateController(instance: Instance, userId: string, newActionType: string?): boolean
    local currentController = instance:GetAttribute("CONTROLLER")
    if not currentController or currentController == "" then
        return true
    end

    local interactionType = instance:GetAttribute("INTERACTION")
    if interactionType then
        local template = Modules.Interact.Templates[interactionType:lower()]
        if template and template.shared then
            return true
        end
    end

    if currentController == userId and newActionType then
        local player = game.Players:GetPlayerByUserId(tonumber(userId))
        if player then
            local playerActions = state.activeActions[player]
            if playerActions then
                for actionType, context in pairs(playerActions) do
                    local config = GetConfig(actionType)
                    if config and config.persist then
                        return true
                    end
                end
            end
        end
    end

    return currentController == userId
end

local function SetController(instance: Instance, userId: string?)
    local interactionType = instance:GetAttribute("INTERACTION")
    if interactionType then
        local template = Modules.Interact.Templates[interactionType:lower()]
        if template and template.shared then
            return
        end

        if type(interactionType) == "string" then
            for iType in interactionType:gmatch("[^,]+") do
                local actionType = iType:match("^%s*(.-)%s*$"):lower()
                local actionConfig = Modules.Action.Types[actionType:upper()]
                if actionConfig and (actionConfig.repeatable or actionConfig.noController) then
                    return
                end
            end
        end
    end
    instance:SetAttribute("CONTROLLER", userId or "")
end

local function PlayEffects(services, context: Types.ActionContext, config: Types.ActionConfig)
    if not config.effects then return end

    if config.effects.animation and services.Animation then
        local anim = config.effects.animation
        local target = anim.target == "object" and context.instance or context.player.Character
        if target then
            services.Animation:PlayAnimation(target, {
                preset = anim.id,
                fadeTime = anim.fadeTime,
                weight = anim.weight,
                speed = anim.speed
            })
        end
    end

    if config.effects.sound and services.Audio then
        local sound = config.effects.sound
        local target = sound.target == "player" and context.player or context.instance
        if target then
            services.Audio:PlaySound(target, {
                preset = sound.id,
                spatial = sound.spatial,
                distance = sound.distance,
                volume = sound.volume
            })
        end
    end

    if config.effects.particles and services.Particle then
        local particles = config.effects.particles
        local target = particles.target == "player" and context.player.Character or context.instance
        if target then
            services.Particle:CreateEffect(target, {
                preset = particles.preset,
                duration = particles.duration,
                position = particles.position
            })
        end
    end

    if config.effects.camera and config.effects.camera.shake then
        local shake = config.effects.camera.shake
        services.Event:FireTo(context.player, "Client.Camera.Shake", {
            preset = shake.preset,
            intensity = shake.intensity,
            duration = shake.duration
        })
    end
end

local function CheckInventory(player: Player): boolean
    local playerActions = state.activeActions[player]
    if not playerActions then return false end

    return playerActions["storage"] ~= nil
end

local function SetAction(player: Player, actionType: string?)
    player:SetAttribute("ACTION", actionType or "None")
end

--[[ Core Functions ]]
function ActionService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function ActionService:Start()
    for actionType, config in Modules.Action.Types do
        if config.handler then
            self:RegisterHandler(config.id, config.handler)
        end
    end
    return true
end

--[[ Action Management ]]
function ActionService:ExecuteAction(actionName: string, params: {[string]: any}): (boolean, string?)
    local action = Modules.Action.Types[actionName:upper()]
    if not action then
        warn("Invalid action:", actionName)
        return false, "Invalid action"
    end

    local player, instance = params.player, params.instance
    if not (player and instance) then
        warn("Missing required parameters - Player:", player, "Instance:", instance)
        return false, "Missing required parameters"
    end

    local userId = tostring(player.UserId)

    if actionName:lower() == "storage" and CheckInventory(player) then
        return false, "An inventory is already open"
    end

    if not ValidateController(instance, userId, actionName:lower()) then
        -- warn("Object is being used by another player")
        return false, "Object is being used by another player"
    end

    local onCooldown, timeLeft = ValidateCooldown(player, actionName)
    if not onCooldown then
        -- warn("Action on cooldown:", timeLeft, "seconds remaining")
        return false, string.format("Action on cooldown (%.1f seconds remaining)", timeLeft)
    end

    params.variant = params.variant or instance:GetAttribute("VARIANT")
    params.category = params.category or instance:GetAttribute("CATEGORY")

    SetController(instance, userId)
    SetAction(player, actionName:lower())

    local success, result = pcall(function()
        local handler = self:GetHandler(actionName)
        if not handler then
            warn("No handler found for action:", actionName)
            return false, "No handler found"
        end

        local context: ActionContext = {
            id = Services.Object:GetID(instance),
            instance = instance,
            player = player,
            actionType = actionName:lower(),
            metadata = params
        }

        if handler.validate and not handler.validate(Services, context) then
            warn("Validation failed for action:", actionName)
            return false, "Validation failed"
        end

        Services.Event:Fire("Action.Start", {
            player = player,
            instance = instance,
            context = context
        })

        local success = handler.onStart and handler.onStart(Services, context)

        if success then
            SetCooldown(player, actionName:lower())
            SetAction(player, "none")

            local currentState = instance:GetAttribute("STATE")
            if currentState == nil then
                instance:SetAttribute("STATE", "ACTIVE")
            else
                instance:SetAttribute("STATE", currentState == "ACTIVE" and "INACTIVE" or "ACTIVE")
            end

            local newState = instance:GetAttribute("STATE")
            for _, descendant in ipairs(instance:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    local actionType = descendant:GetAttribute("ACTION")
                    if actionType then
                        local template = Modules.Interact.Templates[actionType:lower()]
                        if template and template.state and template.state[newState] then
                            local stateValue = template.state[newState]
                            descendant.ActionText = type(stateValue) == "table" and stateValue.text or stateValue
                            if descendant.ObjectText ~= "" then
                                descendant.ObjectText = instance:GetAttribute("NAME") or ""
                            end
                        end
                    end
                end
            end

            state.activeActions[player] = state.activeActions[player] or {}
            state.activeActions[player][actionName:lower()] = context

            PlayEffects(Services, context, action)

            if handler.onComplete then
                handler.onComplete(Services, context)
                if not action.persist then
                    if instance:GetAttribute("CONTROLLER") == userId then
                        SetController(instance, nil)
                    end
                    if state.activeActions[player] then
                        state.activeActions[player][actionName:lower()] = nil
                        if not next(state.activeActions[player]) then
                            state.activeActions[player] = nil
                        end
                    end
                end
            end
        else
            if handler.onCancel then
                handler.onCancel(Services, context)
                SetAction(player, "none")
                if instance:GetAttribute("CONTROLLER") == userId then
                    SetController(instance, nil)
                end
            end
        end

        Services.Event:Fire("Action.End", {
            player = player,
            instance = instance,
            context = context,
            success = success
        })

        return success, "Action completed successfully"
    end)

    if not success then
        warn("Action execution failed:", result)
        Services.Event:Fire("Action.Fail", player, actionName, instance, result)
        if instance:GetAttribute("CONTROLLER") == userId then
            SetController(instance, nil)
        end
    end

    return success, result
end

--[[ Handler Management ]]
function ActionService:RegisterHandler(
    actionType: string,
    handler: ActionHandler
): boolean
    if type(actionType) ~= "string" then return false end
    state.handlers[actionType:lower()] = handler
    return true
end

function ActionService:UnregisterHandler(actionType: string): boolean
    if type(actionType) ~= "string" then return false end
    state.handlers[actionType:lower()] = nil
    return true
end

function ActionService:GetHandler(actionType: string): ActionHandler?
    return state.handlers[actionType:lower()]
end

--[[ State Management ]]
function ActionService:GetActive(
    player: Player,
    actionType: string?
): ActionContext?
    local playerActions = state.activeActions[player]
    if not playerActions then return nil end

    if actionType then
        return playerActions[actionType:lower()]
    end
    return next(playerActions)
end

function ActionService:HasActive(player: Player): boolean
    return state.activeActions[player] ~= nil
end

function ActionService:CancelAction(
    player: Player,
    actionType: string?
): boolean
    local playerActions = state.activeActions[player]
    if not playerActions then return false end

    if actionType then
        local actionTypeLower = actionType:lower()
        local context = playerActions[actionTypeLower]
        if not context then return false end

        local handler = self:GetHandler(actionType)
        if handler and handler.onCancel then
            handler.onCancel(Services, context)
        end
        playerActions[actionTypeLower] = nil
        if not next(playerActions) then
            state.activeActions[player] = nil
        end
        SetAction(player, "none")
        return true
    end

    for type, context in pairs(playerActions) do
        local handler = self:GetHandler(type)
        if handler and handler.onCancel then
            handler.onCancel(Services, context)
        end
    end
    state.activeActions[player] = nil
    SetAction(player, "none")
    return true
end

function ActionService:EndPersist(actionType: string, context: Types.ActionContext)
    local handler = self:GetHandler(actionType)
    if handler and handler.onPersist then
        handler.onPersist(Services, context)
    end

    local player = context.player
    if state.activeActions[player] then
        state.activeActions[player][actionType:lower()] = nil
        if not next(state.activeActions[player]) then
            state.activeActions[player] = nil
        end
    end

    SetAction(context.player, "none")

    Services.Event:Fire("Action.End", {
        player = context.player,
        instance = context.instance,
        context = context,
        success = true
    })
end

return ActionService
