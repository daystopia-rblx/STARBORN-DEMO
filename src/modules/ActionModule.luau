--[[ ActionModule
    Defines action types and their configurations
    @author @Daystopia
    @version 1.1.0
    @date 2025-03-30
]]
local ActionModule = {}

--[[ Types ]]
export type ActionConfig = {
    id: string,
    name: string,
    description: string?,
    category: string?,
    requiresTarget: boolean?,
    cooldown: number?,
    repeatable: boolean?,
    noController: boolean?,
    metadata: {[string]: any}?,
    persist: boolean?
}

export type ActionContext = {
    id: string,
    instance: Instance,
    player: Player,
    actionType: string,
    metadata: {[string]: any}?
}

export type ActionHandler = {
    onStart: ((services: any, context: ActionContext) -> boolean)?,
    onComplete: ((services: any, context: ActionContext) -> ())?,
    onCancel: ((services: any, context: ActionContext) -> ())?,
    onPersist: ((services: any, context: ActionContext) -> ())?,
    validate: ((services: any, context: ActionContext) -> boolean)?
}

--[[ Action Categories ]]
ActionModule.Categories = {
    INTERACTION = "interaction",
    CHECKPOINT = "checkpoint"
}

--[[ Action Types ]]
ActionModule.Types = {
    SEAT = {
        id = "seat",
        name = "Seat",
        category = ActionModule.Categories.INTERACTION,
        requiresTarget = true,
        persist = true,
        handler = {
            validate = function(services, context)
                for _, child in ipairs(context.instance:GetDescendants()) do
                    if child:IsA("Seat") or child:IsA("VehicleSeat") then
                        child.Disabled = true
                    end
                end

                local hasUnoccupiedSeat = false
                for _, child in ipairs(context.instance:GetDescendants()) do
                    if child:IsA("Seat") or child:IsA("VehicleSeat") then
                        if not child.Occupant then
                            hasUnoccupiedSeat = true
                            break
                        end
                    end
                end
                return hasUnoccupiedSeat
            end,
            onStart = function(services, context)
                local character = context.player.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if not humanoid then return false end

                local targetSeat
                for _, child in ipairs(context.instance:GetDescendants()) do
                    if (child:IsA("Seat") or child:IsA("VehicleSeat")) and not child.Occupant then
                        targetSeat = child
                        break
                    end
                end

                if not targetSeat then return false end

                context.metadata = context.metadata or {}
                context.metadata.targetSeat = targetSeat

                targetSeat.Disabled = false
                targetSeat:Sit(humanoid)

                if context.metadata.sound then
                    services.Audio:PlaySound(targetSeat, {
                        preset = "sit",
                        spatial = true,
                        distance = 20
                    })
                end

                local connection
                connection = targetSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
                    if not targetSeat.Occupant then
                        targetSeat.Disabled = true
                        if context.metadata.sound then
                            services.Audio:PlaySound(targetSeat, {
                                preset = "unsit",
                                spatial = true,
                                distance = 20
                            })
                        end
                        services.Event:Fire("Action.Persist", {
                            player = context.player,
                            instance = context.instance,
                            context = context
                        })
                        connection:Disconnect()
                    end
                end)

                return true
            end,
            onComplete = function(services, context)
                if context.metadata and context.metadata.sound then
                    services.Asset:PlaySound(context.player, "sit")
                end
            end,
            onPersist = function(services, context)
                if context.instance:GetAttribute("CONTROLLER") == tostring(context.player.UserId) then
                    context.instance:SetAttribute("CONTROLLER", nil)
                end
            end
        }
    }
}

--[[ Handler Management ]]
function ActionModule:GetHandler(actionType: string): ActionHandler?
    local config = self.Types[actionType:upper()]
    return config and config.handler
end

return ActionModule