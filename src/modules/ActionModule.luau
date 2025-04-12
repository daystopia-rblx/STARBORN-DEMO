--[[ ActionModule
    Defines action types and their configurations
    @author @Daystopia
    @version 1.1.1
    @date 2025-04-10
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
    SOCIAL = "social",
    INTERACTION = "interaction",
    CHECKPOINT = "checkpoint",
    SURVIVAL = "survival",
    STEALTH = "stealth"
}

--[[ Action Types ]]
ActionModule.Types = {
    TALK = {
        id = "talk",
        name = "Talk",
        category = ActionModule.Categories.SOCIAL,
        requiresTarget = true,
        persist = true,
        handler = {
            validate = function(services, context)
                return true
            end,

            onStart = function(services, context)
                local instance = context.instance
                local npcName = instance:GetAttribute("NAME")
                if not npcName then
                    warn("NPC has no NAME attribute")
                    return false
                end

                local dialogueId = instance:GetAttribute("DIALOGUE_ID") or
                    services.Dialogue:GetDialogueId("citizen", npcName)
                local playerId = context.player.UserId

                local success = services.Dialogue:StartDialogue(tostring(playerId), dialogueId)
                if success then
                    context.metadata = context.metadata or {}
                    context.metadata.dialogueConnection = services.Event:On("Dialogue.End", function(data)
                        if data.dialogueId == dialogueId and data.context and
                           data.context.player == context.player then
                            context.metadata.dialogueConnection:Disconnect()
                            context.metadata.dialogueConnection = nil
                            services.Event:Fire("Action.Persist", {
                                player = context.player,
                                instance = context.instance,
                                context = context
                            })
                        end
                    end)
                end
                return success
            end,

            onComplete = function(services, context)
                if context.metadata and context.metadata.sound then
                    services.Audio:PlaySound(context.instance, {
                        preset = "talk",
                        spatial = true,
                        distance = 30
                    })
                end
            end,

            onCancel = function(services, context)
                if context.metadata and context.metadata.dialogueConnection then
                    context.metadata.dialogueConnection:Disconnect()
                    context.metadata.dialogueConnection = nil
                end
                services.Dialogue:EndDialogue(tostring(context.player.UserId), "forced_cancel")
            end,

            onPersist = function(services, context)
                if context.metadata and context.metadata.dialogueConnection then
                    context.metadata.dialogueConnection:Disconnect()
                    context.metadata.dialogueConnection = nil
                end
                if context.instance:GetAttribute("CONTROLLER") == tostring(context.player.UserId) then
                    context.instance:SetAttribute("CONTROLLER", nil)
                end
            end
        }
    },

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
    },

    REST = {
        id = "rest",
        name = "Rest",
        category = ActionModule.Categories.CHECKPOINT,
        requiresTarget = true,
        persist = true,
        handler = {
            validate = function(services, context)
                local objectType = context.instance:GetAttribute("TYPE")
                if not objectType then return false end

                local objectData = services.Modules.Object.GetObject(objectType)
                if objectData and objectData.defaults and objectData.defaults.properties then
                    return objectData.defaults.properties.checkpoint == true
                end

                return false
            end,

            onStart = function(services, context)
                local player = context.player
                local character = player.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if not humanoid then return false end

                context.metadata = context.metadata or {}

                local animation = services.Animation:PlayAnimation(character, {
                    preset = "rest",
                    fadeTime = 0.5,
                    weight = 1.0,
                    speed = 1.0
                })

                if animation then
                    context.metadata.restAnimation = animation
                end

                local activationTime = 2.0
                context.metadata.activationTimer = activationTime
                context.metadata.timerConnection = services.RunService.Heartbeat:Connect(function(dt)
                    context.metadata.activationTimer = context.metadata.activationTimer - dt
                    if context.metadata.activationTimer <= 0 then
                        context.metadata.timerConnection:Disconnect()
                        context.metadata.timerConnection = nil

                        local success = services.Spawn:ActivateCheckpoint(player, context.instance)

                        if success then
                            services.Particle:CreateEffect(context.instance, {
                                preset = "checkpoint_activate",
                                duration = 3,
                                position = context.instance:GetPivot().Position
                            })

                            services.Audio:PlaySound(context.instance, {
                                preset = "checkpoint_activate",
                                spatial = true,
                                distance = 50
                            })
                        end

                        task.delay(1, function()
                            if context.metadata.restAnimation then
                                context.metadata.restAnimation:Stop()
                                context.metadata.restAnimation = nil
                            end

                            services.Event:Fire("Action.Persist", {
                                player = context.player,
                                instance = context.instance,
                                context = context
                            })
                        end)
                    end
                end)

                return true
            end,

            onCancel = function(services, context)
                if context.metadata and context.metadata.restAnimation then
                    context.metadata.restAnimation:Stop()
                    context.metadata.restAnimation = nil
                end

                if context.metadata and context.metadata.timerConnection then
                    context.metadata.timerConnection:Disconnect()
                    context.metadata.timerConnection = nil
                end
            end,

            onPersist = function(services, context)
                if context.metadata and context.metadata.restAnimation then
                    context.metadata.restAnimation:Stop()
                    context.metadata.restAnimation = nil
                end

                if context.metadata and context.metadata.timerConnection then
                    context.metadata.timerConnection:Disconnect()
                    context.metadata.timerConnection = nil
                end

                if context.instance:GetAttribute("CONTROLLER") == tostring(context.player.UserId) then
                    context.instance:SetAttribute("CONTROLLER", nil)
                end
            end
        }
    },

    CRAFT = {
        id = "craft",
        name = "Craft",
        category = ActionModule.Categories.INTERACTION,
        requiresTarget = true,
        persist = true,
        handler = {
            validate = function(services, context)
                local stationType = context.instance:GetAttribute("STATION_TYPE")
                if not stationType then
                    return false
                end

                return true
            end,

            onStart = function(services, context)
                local stationType = context.instance:GetAttribute("STATION_TYPE")
                if not stationType then return false end

                local player = context.player
                local userId = tostring(player.UserId)

                context.metadata = context.metadata or {}
                context.metadata.stationType = stationType

                context.instance:SetAttribute("CONTROLLER", userId)

                context.metadata.craftingConnection = services.Event:On("Craft.Complete", function(data)
                    if data.playerId == userId then
                        services.Event:Fire("Action.Persist", {
                            player = context.player,
                            instance = context.instance,
                            context = context
                        })
                    end
                end)

                return true
            end,

            onCancel = function(services, context)
                if context.metadata and context.metadata.craftingConnection then
                    context.metadata.craftingConnection:Disconnect()
                    context.metadata.craftingConnection = nil
                end
            end,

            onPersist = function(services, context)
                if context.metadata and context.metadata.craftingConnection then
                    context.metadata.craftingConnection:Disconnect()
                    context.metadata.craftingConnection = nil
                end

                if context.instance:GetAttribute("CONTROLLER") == tostring(context.player.UserId) then
                    context.instance:SetAttribute("CONTROLLER", nil)
                end
            end
        }
    },

    CONSUME = {
        id = "consume",
        name = "Consume",
        category = ActionModule.Categories.SURVIVAL,
        requiresTarget = true,
        persist = true,
        handler = {
            validate = function(services, context)
                local itemId = context.metadata and context.metadata.itemId
                if not itemId then return false end

                local hasItem = services.Inventory:GetItem(context.player, itemId, 1)
                return hasItem
            end,

            onStart = function(services, context)
                local player = context.player
                local itemId = context.metadata and context.metadata.itemId
                local variant = context.metadata and context.metadata.variant

                if not itemId then return false end

                local character = player.Character
                if not character then return false end

                context.metadata = context.metadata or {}

                local itemTemplate, sourceModule = services.Inventory:GetTemplate(itemId)
                local animationType = "eat"

                if itemTemplate and itemTemplate.defaults and itemTemplate.defaults.tool then
                    if itemTemplate.defaults.tool == "drink" then
                        animationType = "drink"
                    end
                end

                local animation = services.Animation:PlayAnimation(character, {
                    preset = animationType,
                    fadeTime = 0.3,
                    weight = 1.0,
                    speed = 1.0
                })

                if animation then
                    context.metadata.consumeAnimation = animation
                end

                local useTime = 1.5
                if itemTemplate and itemTemplate.defaults and itemTemplate.defaults.useTime then
                    useTime = itemTemplate.defaults.useTime
                end

                task.delay(useTime, function()
                    if context.metadata.consumeAnimation then
                        context.metadata.consumeAnimation:Stop()
                        context.metadata.consumeAnimation = nil
                    end

                    local success, result = services.Inventory:UseItem(player, itemId, variant)

                    if success then
                        if itemTemplate and itemTemplate.defaults and itemTemplate.defaults.tool then
                            services.Audio:PlaySound(character, {
                                preset = itemTemplate.defaults.tool .. "_use",
                                spatial = true,
                                distance = 20
                            })
                        end
                    end

                    services.Event:Fire("Action.Persist", {
                        player = context.player,
                        instance = context.instance,
                        context = context
                    })
                end)

                return true
            end,

            onCancel = function(services, context)
                if context.metadata and context.metadata.consumeAnimation then
                    context.metadata.consumeAnimation:Stop()
                    context.metadata.consumeAnimation = nil
                end
            end,

            onPersist = function(services, context)
                if context.metadata and context.metadata.consumeAnimation then
                    context.metadata.consumeAnimation:Stop()
                    context.metadata.consumeAnimation = nil
                end
            end
        }
    },

    STEAL = {
        id = "steal",
        name = "Steal",
        category = ActionModule.Categories.STEALTH,
        requiresTarget = true,
        cooldown = 30,
        persist = true,
        handler = {
            validate = function(services, context)
                local character = context.player.Character
                if not character then return false end

                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoidRootPart then return false end

                local targetPosition = context.instance:GetPivot().Position
                local playerPosition = humanoidRootPart.Position

                local maxStealDistance = 10
                local distance = (targetPosition - playerPosition).Magnitude

                return distance <= maxStealDistance
            end,

            onStart = function(services, context)
                local player = context.player
                local character = player.Character
                if not character then return false end

                context.metadata = context.metadata or {}

                local animation = services.Animation:PlayAnimation(character, {
                    preset = "steal",
                    fadeTime = 0.3,
                    weight = 1.0,
                    speed = 1.0
                })

                if animation then
                    context.metadata.stealAnimation = animation
                end

                local targetId = services.Object:GetID(context.instance)
                local storeId = context.instance:GetAttribute("STORE_ID")
                local itemId = context.metadata and context.metadata.itemId
                local isStore = storeId ~= nil

                local theftContext = {
                    player = player,
                    targetId = isStore and storeId or targetId,
                    itemId = itemId,
                    value = context.metadata and context.metadata.itemValue,
                    isStore = isStore,
                    metadata = context.metadata
                }

                local success, result = services.Crime:AttemptTheft(theftContext)

                task.delay(1, function()
                    if context.metadata.stealAnimation then
                        context.metadata.stealAnimation:Stop()
                        context.metadata.stealAnimation = nil
                    end

                    if result then
                        if result.success then
                            services.Audio:PlaySound(character, {
                                preset = "steal_success",
                                spatial = true,
                                distance = 5
                            })
                        else
                            services.Audio:PlaySound(character, {
                                preset = "steal_fail",
                                spatial = true,
                                distance = 10
                            })
                        end

                        if result.detected then
                            services.Audio:PlaySound(character, {
                                preset = "detected",
                                spatial = true,
                                distance = 20
                            })
                        end
                    end

                    services.Event:Fire("Action.Persist", {
                        player = context.player,
                        instance = context.instance,
                        context = context
                    })
                end)

                return success
            end,

            onCancel = function(services, context)
                if context.metadata and context.metadata.stealAnimation then
                    context.metadata.stealAnimation:Stop()
                    context.metadata.stealAnimation = nil
                end
            end,

            onPersist = function(services, context)
                if context.metadata and context.metadata.stealAnimation then
                    context.metadata.stealAnimation:Stop()
                    context.metadata.stealAnimation = nil
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