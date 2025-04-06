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
    Particle = require(script.Parent.Utility.Particle),
    Input = require(script.Parent.Utility.Input)
}

--[[ Variables ]]
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local Animations = {}

--[[ State ]]
local State = {
    initialized = false,
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
    },
    input = {
        connection = nil
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

--[[ Input Setup ]]
local function SetupInput()
    if State.input.connection then
        State.input.connection.Disconnect()
        State.input.connection = nil
    end

    local function notStunned()
        return not State.combat.isStunned
    end

    local combatActions = {
        Utility.Input.CreateAction("LightAttack",
            {Enum.UserInputType.MouseButton1},
            function(state)
                if state then CombatHandlers.ATTACK({type = "LIGHT"}) end
            end, 
            {condition = notStunned}
        ),

        Utility.Input.CreateAction("CancelAction",
            {Enum.UserInputType.MouseButton2},
            function(state)
                if state then CombatHandlers.FEINT({}) end
            end, 
            {condition = notStunned}
        ),

        Utility.Input.CreateAction("CriticalAttack",
            {Enum.UserInputType.MouseButton3, Enum.KeyCode.R},
            function(state)
                if state then CombatHandlers.ATTACK({type = "CRITICAL"}) end
            end, 
            {condition = notStunned}
        ),

        Utility.Input.CreateAction("Parry",
            {Enum.KeyCode.F},
            function(state)
                if state and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    CombatHandlers.PARRY({})
                end
            end, 
            {condition = notStunned, throttle = 0.1}
        ),

        Utility.Input.CreateAction("Block",
            {Enum.KeyCode.LeftShift},
            function(state)
                if state then
                    CombatHandlers.BLOCK({})
                else
                    State.combat.isBlocking = false
                    local weaponType = State.combat.equippedWeapon or "GLOVES"
                    StopAnimation("WEAPONS", weaponType .. "_BLOCK_POSE")
                    Services.Event:FireServer("Client.Combat.Attack", {
                        type = "BLOCK",
                        enabled = false
                    })
                end
            end,
            {condition = notStunned}
        ),

        Utility.Input.CreateAction("Execute",
            {Enum.KeyCode.B},
            function(state)
                if state then CombatHandlers.EXECUTE({}) end
            end, 
            {condition = notStunned}
        ),

        Utility.Input.CreateAction("Carry",
            {Enum.KeyCode.V},
            function(state)
                if state then CombatHandlers.CARRY({}) end
            end, 
            {condition = notStunned}
        ),

        Utility.Input.CreateAction("SwitchStance",
            {Enum.KeyCode.Y}, 
            function(state)
                if state then CombatHandlers.SWITCH_STANCE({}) end
            end, 
            {condition = notStunned}
        )
    }

    local inputConfig = {
        id = "Combat",
        actions = combatActions,
        keyboardEnabled = true,
        mouseEnabled = true,
        gamepadEnabled = true,
        touchEnabled = false,
        ignoreProcessed = false,
        requireGameFocus = true
    }

    State.input.connection = Utility.Input.HandleInput(inputConfig)

    return State.input.connection
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
        end
    },

    ["Character.Removing"] = {
        handler = function()
            for key, _ in pairs(State.combat) do
                if type(State.combat[key]) == "boolean" then
                    State.combat[key] = false
                end
            end
            State.combat.comboCount = 0
            State.combat.currentStance = "NORMAL"
            State.combat.target = nil
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
    if State.initialized then return end
    State.initialized = true

    InitializeAnimations()

    SetupInput()

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
end