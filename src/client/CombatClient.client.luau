--[[ CombatClient
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-02
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Services = {
    Event = require(ReplicatedStorage.Services.Network.EventService)
}

local Modules = {
    Animation = require(ReplicatedStorage.Modules.AnimationModule),
    Combat = require(ReplicatedStorage.Modules.CombatModule)
}

local Utility = {
    Sound = require(script.Parent.Utility.Sound),
    Controller = require(script.Parent.Utility.Controller),
    Animation = require(script.Parent.Utility.Animation),
    Particle = require(script.Parent.Utility.Particle)
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Animations = {}

--[[ Constants ]]
local CONTROL_BINDINGS = {
    {action = "LightAttack", key = Enum.UserInputType.MouseButton1, description = "Light Attack"},
    {action = "CancelAction", key = Enum.UserInputType.MouseButton2, description = "Cancel Action"},
    {action = "CriticalAttack", key = Enum.UserInputType.MouseButton3, description = "Critical Attack"},
    {action = "CriticalAttackAlt", key = Enum.KeyCode.R, description = "Critical Attack (Alternative)"},
    {action = "Parry", key = Enum.KeyCode.F, description = "Parry"},
    {action = "Block", key = Enum.KeyCode.F, description = "Block", holdAction = true},
    {action = "Execute", key = Enum.KeyCode.B, description = "Execute KO'ed Enemy"},
    {action = "Carry", key = Enum.KeyCode.V, description = "Carry KO'ed Enemy"},
    {action = "SwitchStance", key = Enum.KeyCode.Y, description = "Switch Stance"}
}

--[[ State ]]
local State = {
    combat = {
        isAttacking = false,
        isBlocking = false,
        isParrying = false,
        isExecuting = false,
        isCarrying = false,
        currentStance = "NORMAL",
        lastAttack = 0,
        lastBlock = 0,
        lastParry = 0,
        lastStanceSwitch = 0,
        equippedWeapon = nil,
        comboCount = 0,
        maxCombo = 3,
        target = nil,
        isStunned = false
    }
}

--[[ Animation Functions ]]
local function PlayAnimation(category: string, name: string?)
    Utility.Animation.Play(Animations, category, name, Modules.Animation.Assets.Animations)
end

local function StopAnimation(category: string, name: string?)
    Utility.Animation.Stop(Animations, category, name, Modules.Animation.Assets.Animations)
end

local function InitializeAnimations()
    local categories = {
        "WEAPONS",
        "COMBAT"
    }

    Animations = Utility.Animation.Categories(Animator, categories, Modules.Animation.Assets.Animations)
end

--[[ Combat Handlers ]]
local CombatHandlers = {
    ATTACK = function(data)
        if State.combat.isAttacking or State.combat.isStunned then return end
        if os.clock() - State.combat.lastAttack < Modules.Combat.Constants.ATTACK_PROPERTIES[data.type or "LIGHT"].cooldown then return end

        State.combat.isAttacking = true
        State.combat.lastAttack = os.clock()
        State.combat.comboCount = (State.combat.comboCount % State.combat.maxCombo) + 1

        local weaponType = State.combat.equippedWeapon or "GLOVES"
        PlayAnimation("WEAPONS", weaponType .. "_SWING_" .. State.combat.comboCount)

        Services.Event:FireServer("Client.Combat.Attack", {
            type = "ATTACK",
            attackType = data.type or "LIGHT",
            combo = State.combat.comboCount,
            data = data
        })

        task.delay(Modules.Combat.Constants.ATTACK_PROPERTIES[data.type or "LIGHT"].duration + 0.5, function()
            if os.clock() - State.combat.lastAttack >= 0.5 then
                State.combat.comboCount = 0
            end
            State.combat.isAttacking = false
        end)
    end,

    BLOCK = function(data)
        if State.combat.isBlocking or State.combat.isStunned then return end
        if os.clock() - State.combat.lastBlock < Modules.Combat.Constants.DEFENSE_PROPERTIES.BLOCK.cooldown then return end

        State.combat.isBlocking = true
        State.combat.lastBlock = os.clock()

        local weaponType = State.combat.equippedWeapon or "GLOVES"
        PlayAnimation("WEAPONS", weaponType .. "_BLOCK_POSE")

        Services.Event:FireServer("Client.Combat.Attack", {
            type = "BLOCK",
            data = data
        })
    end,

    PARRY = function(data)
        if State.combat.isParrying or State.combat.isStunned then return end
        if os.clock() - State.combat.lastParry < Modules.Combat.Constants.DEFENSE_PROPERTIES.PARRY.cooldown then return end

        State.combat.isParrying = true
        State.combat.lastParry = os.clock()

        local weaponType = State.combat.equippedWeapon or "GLOVES"
        PlayAnimation("WEAPONS", weaponType .. "_PARRY")

        Services.Event:FireServer("Client.Combat.Attack", {
            type = "PARRY",
            data = data
        })

        task.delay(Modules.Combat.Constants.DEFENSE_PROPERTIES.PARRY.window, function()
            State.combat.isParrying = false
        end)
    end,

    FEINT = function(data)
        if not State.combat.isAttacking then return end

        local character = LocalPlayer.Character
        if not character then return end

        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if not torso then return end

        local weaponType = State.combat.equippedWeapon or "GLOVES"
        StopAnimation("WEAPONS", weaponType .. "_ATTACK_" .. State.combat.comboCount)
        State.combat.isAttacking = false
        State.combat.comboCount = 0

        local offset = torso.CFrame.LookVector * 2
        Utility.Particle.Play("Feint", torso, {
            offset = CFrame.new(offset),
            weld = true,
            sound = {
                playbackSpeed = 1
            }
        })

        Services.Event:FireServer("Client.Combat.Attack", {
            type = "FEINT",
            data = data
        })
    end,

    EXECUTE = function(data)
        if State.combat.isExecuting or State.combat.isStunned then return end

        local character = LocalPlayer.Character
        if not character then return end

        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if not torso then return end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {character}

        local raycastResult = workspace:Raycast(
            torso.Position,
            torso.CFrame.LookVector * 5,
            raycastParams
        )

        if raycastResult and raycastResult.Instance then
            local target = raycastResult.Instance:FindFirstAncestorWhichIsA("Model")
            if target and target:FindFirstChild("Humanoid") and (target:GetAttribute("KNOCKED") or target:GetAttribute("DEAD")) then
                State.combat.isExecuting = true
                State.combat.target = target

                local weaponType = State.combat.equippedWeapon or "GLOVES"
                PlayAnimation("WEAPONS", weaponType .. "_EXECUTE")

                Services.Event:FireServer("Client.Combat.Attack", {
                    type = "EXECUTE",
                    target = target,
                    data = data
                })

                task.delay(1, function()
                    State.combat.isExecuting = false
                    State.combat.target = nil
                end)
            end
        end
    end,

    CARRY = function(data)
        if State.combat.isCarrying or State.combat.isStunned then return end

        local character = LocalPlayer.Character
        if not character then return end

        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if not torso then return end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {character}

        local raycastResult = workspace:Raycast(
            torso.Position,
            torso.CFrame.LookVector * 5,
            raycastParams
        )

        if raycastResult and raycastResult.Instance then
            local target = raycastResult.Instance:FindFirstAncestorWhichIsA("Model")
            if target and target:FindFirstChild("Humanoid") and (target:GetAttribute("KNOCKED") or target:GetAttribute("DEAD")) then
                State.combat.isCarrying = not State.combat.isCarrying
                State.combat.target = State.combat.isCarrying and target or nil

                if State.combat.isCarrying then
                    PlayAnimation("CARRY", "HOLD")
                else
                    StopAnimation("CARRY", "HOLD")
                end

                Services.Event:FireServer("Client.Combat.Attack", {
                    type = "CARRY",
                    target = target,
                    enabled = State.combat.isCarrying,
                    data = data
                })
            end
        end
    end,

    SWITCH_STANCE = function(data)
        if State.combat.isStunned then return end
        if os.clock() - State.combat.lastStanceSwitch < 0.5 then return end

        State.combat.lastStanceSwitch = os.clock()
        local stances = {"NORMAL", "DEFENSIVE", "AGGRESSIVE"}
        local currentIndex = table.find(stances, State.combat.currentStance) or 1
        State.combat.currentStance = stances[currentIndex % #stances + 1]

        local weaponType = State.combat.equippedWeapon or "GLOVES"
        PlayAnimation("WEAPONS", weaponType .. "_STANCE_" .. State.combat.currentStance)

        Services.Event:FireServer("Client.Combat.Attack", {
            type = "STANCE",
            stance = State.combat.currentStance,
            data = data
        })
    end
}

--[[ Combat Input Handling ]]
local function ExecuteCombat(actionName, inputState, inputObject)
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return Enum.ContextActionResult.Pass end

    if State.combat.isStunned then return Enum.ContextActionResult.Sink end

    if actionName == "LightAttack" then
        if inputState == Enum.UserInputState.Begin then
            CombatHandlers.ATTACK({type = "LIGHT"})
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "CancelAction" or actionName == "CriticalAttack" or actionName == "CriticalAttackAlt" then
        if inputState == Enum.UserInputState.Begin then
            if actionName == "CancelAction" then
                CombatHandlers.FEINT({})
            else
                CombatHandlers.ATTACK({type = "CRITICAL"})
            end
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "Parry" then
        if inputState == Enum.UserInputState.Begin and not UserInputService:IsKeyDown(Enum.KeyCode.F) then
            CombatHandlers.PARRY({})
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "Block" then
        if inputState == Enum.UserInputState.Begin then
            CombatHandlers.BLOCK({})
        elseif inputState == Enum.UserInputState.End then
            State.combat.isBlocking = false
            local weaponType = State.combat.equippedWeapon or "GLOVES"
            StopAnimation("WEAPONS", weaponType .. "_BLOCK_POSE")
            Services.Event:FireServer("Client.Combat.Attack", {
                type = "BLOCK",
                enabled = false
            })
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "Execute" then
        if inputState == Enum.UserInputState.Begin then
            CombatHandlers.EXECUTE({})
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "Carry" then
        if inputState == Enum.UserInputState.Begin then
            CombatHandlers.CARRY({})
        end
        return Enum.ContextActionResult.Sink
    end

    if actionName == "SwitchStance" then
        if inputState == Enum.UserInputState.Begin then
            CombatHandlers.SWITCH_STANCE({})
        end
        return Enum.ContextActionResult.Sink
    end

    return Enum.ContextActionResult.Pass
end

local function SetupKeybindings()
    for _, binding in ipairs(CONTROL_BINDINGS) do
        ContextActionService:BindAction(
            binding.action,
            ExecuteCombat,
            false,
            binding.key
        )
    end
end

local function CleanupKeybindings()
    for _, binding in ipairs(CONTROL_BINDINGS) do
        ContextActionService:UnbindAction(binding.action)
    end
end

--[[ Events ]]
local Events = {
    ["Character.Added"] = {
        handler = function(newCharacter)
            Character = newCharacter

            for key, _ in pairs(State.combat) do
                if type(State.combat[key]) == "boolean" then
                    State.combat[key] = false
                end
            end

            State.combat.comboCount = 0
            State.combat.currentStance = "NORMAL"
            State.combat.target = nil

            Humanoid = Character:WaitForChild("Humanoid")
            Animator = Humanoid:WaitForChild("Animator")
            Animations = {}
            InitializeAnimations()

            SetupKeybindings()
        end
    },

    ["Character.Removing"] = {
        handler = function()
            CleanupKeybindings()
        end
    },

    ["Client.Combat.Attack"] = {
        handler = function(response)
            if not response.success then
                if State.combat.isAttacking then
                    State.combat.isAttacking = false
                    State.combat.comboCount = 0
                    local weaponType = State.combat.equippedWeapon or "GLOVES"
                    StopAnimation("WEAPONS", weaponType .. "_ATTACK_" .. State.combat.comboCount)
                end
                return
            end

            local torso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
            if not torso then return end

            if response.type == "PARRY_SUCCESS" then
                Utility.Particle.Play("Parry", torso, {
                    weld = true,
                    sound = {
                        playbackSpeed = 1 + math.random(-2, 5)/10
                    }
                })
            elseif response.type == "BLOCK_SUCCESS" then
                Utility.Particle.Play("BlockedHit", torso, {
                    weld = true,
                    sound = {
                        playbackSpeed = 1 + math.random(-2, 5)/10
                    }
                })

                if response.data and response.data.angle then
                    local angle = response.data.angle
                    local effect = "BlockedHit"
                    local size = 1
                    local intensity = 1

                    if angle < 30 then
                        effect = "PerfectBlock"
                        size = 1.5
                        intensity = 1.2
                    elseif angle < 60 then
                        effect = "StrongBlock"
                        size = 1.2
                        intensity = 1
                    else
                        effect = "WeakBlock"
                        size = 0.8
                        intensity = 0.8
                    end

                    Utility.Particle.Play(effect, torso, {
                        weld = true,
                        scale = Vector3.new(size, size, size),
                        sound = {
                            playbackSpeed = 1 + math.random(-2, 5)/10 * intensity
                        }
                    })
                end

                PlayAnimation("STATUS", "BLOCK_BROKEN")
            elseif response.type == "BLOCK_BREAK" and response.target then
                local targetTorso = response.target:FindFirstChild("UpperTorso") or response.target:FindFirstChild("Torso")
                if targetTorso then
                    Utility.Particle.Play("BlockBreak", targetTorso, {
                        weld = true,
                        sound = {
                            playbackSpeed = 1 + math.random(-2, 5)/10
                        }
                    })
                end
            elseif response.type == "CRITICAL_HIT" and response.target then
                local targetTorso = response.target:FindFirstChild("UpperTorso") or response.target:FindFirstChild("Torso")
                if targetTorso then
                    Utility.Particle.Play("CriticalHit", targetTorso, {
                        weld = true,
                        sound = {
                            playbackSpeed = 1 + math.random(-2, 5)/10
                        }
                    })
                end
            elseif response.type == "BLUNT_HIT" and response.target then
                local targetTorso = response.target:FindFirstChild("UpperTorso") or response.target:FindFirstChild("Torso")
                if targetTorso then
                    Utility.Particle.Play("BluntHit", targetTorso, {
                        weld = true,
                        sound = {
                            playbackSpeed = 1 + math.random(-2, 5)/10
                        }
                    })
                end
            elseif response.type == "SLASH_HIT" and response.target then
                local targetTorso = response.target:FindFirstChild("UpperTorso") or response.target:FindFirstChild("Torso")
                if targetTorso then
                    Utility.Particle.Play("SlashHit", targetTorso, {
                        weld = true,
                        sound = {
                            playbackSpeed = 1 + math.random(-2, 5)/10
                        }
                    })
                end
            end
        end
    }
}

--[[ Initialize ]]
local function Initialize()
    InitializeAnimations()

    for eventName, handler in pairs(Events) do
        if eventName == "Character.Added" then
            LocalPlayer.CharacterAdded:Connect(handler.handler)
            if Character then
                handler.handler(Character)
            end
        elseif eventName == "Character.Removing" then
            LocalPlayer.CharacterRemoving:Connect(handler.handler)
        else
            Services.Event:OnClientEvent(eventName, handler.handler)
        end
    end

    SetupKeybindings()
end

Initialize()