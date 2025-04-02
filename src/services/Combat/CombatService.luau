--[[ CombatService
    @author @Daystopia
    @version 1.0.2
    @date 2025-04-02
]]
local CombatService = {}

CombatService.Dependencies = {
    "Data",
    "Event",
    "Stat",
    "State",
    "Weapon"
}

CombatService.Modules = {
    "Combat",
    "State"
}

CombatService.Events = {
    Attack = { validate = true },
    Damage = { validate = true },
    Death = { validate = true }
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services
local Modules

--[[ Types ]]
local Types = require(script.Parent.Parent.Parent.Modules.CombatModule)
type DamageInfo = Types.DamageInfo

--[[ State Management ]]
local State = {
    combatTimers = {},
    lastAttacks = {},
    parryWindows = {},
    carriedTargets = {},
    stances = {},
    combos = {}
}

CombatService.Listeners = {
    ["Players.PlayerAdded"] = function(self, player)
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.Died:Connect(function()
                    Services.Event:Fire("Combat.Death", {
                        entity = character,
                        player = player,
                        damage = {
                            amount = 0,
                            type = "ENVIRONMENT",
                            source = "death"
                        }
                    })
                end)
            end

            Services.State:EnterState(character, "STANCE_NORMAL")
            State.combos[character] = 0
        end)
    end,

    ["Players.PlayerRemoving"] = function(self, player)
        local character = player.Character
        if character then
            State.combos[character] = nil
            State.carriedTargets[character] = nil
        end
    end
}

--[[ Core Functions ]]
function CombatService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function CombatService:Cleanup()
    table.clear(State.combatTimers)
    table.clear(State.lastAttacks)
    table.clear(State.parryWindows)
    table.clear(State.carriedTargets)
    table.clear(State.stances)
    table.clear(State.combos)
end

--[[ Hitbox Functions ]]
function CombatService:CreateHitbox(attacker: Model, attackType: string): {[Model]: string}
    if not (attacker and attacker.PrimaryPart) then return {} end
    local attackProps = Modules.Combat.Constants.ATTACK_PROPERTIES[attackType]
    if not attackProps then return {} end

    local attackerCF = attacker.PrimaryPart.CFrame
    local lookVector = attackerCF.LookVector
    local attackRange = attackProps.range or 6

    local hitTargets = {}
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = {attacker}
    overlapParams.MaxParts = 20

    local parts = workspace:GetPartBoundsInRadius(attackerCF.Position, attackRange, overlapParams)
    if not parts then return hitTargets end

    local processed = {}
    for _, part in ipairs(parts) do
        local target = part:FindFirstAncestorWhichIsA("Model")
        if not target or processed[target] or target == attacker or not target:FindFirstChild("Humanoid") or not target:FindFirstChild("HumanoidRootPart") then
            continue
        end
        processed[target] = true

        local targetCF = target.PrimaryPart.CFrame
        local directionToTarget = (targetCF.Position - attackerCF.Position).Unit
        local dotProduct = lookVector:Dot(directionToTarget)

        local attackAngle = math.cos(math.rad(attackProps.angle or 60))
        if dotProduct > attackAngle then
            local hitInfo = self:DetermineHit(attacker, target, lookVector)

            if typeof(hitInfo) == "table" and hitInfo.result == "BLOCKED" then
                hitTargets[target] = hitInfo
            else
                hitTargets[target] = hitInfo
            end
        end
    end

    return hitTargets
end

function CombatService:DetermineHit(attacker: Model, target: Model, lookVector: Vector3): string | {result: string, angle: number}
    if Services.State:GetCategory(target, "STATUS")["INVINCIBLE"] then
        return "INVINCIBLE"
    end

    if Services.State:GetStates(target) then
        local statusStates = Services.State:GetCategory(target, "STATUS")
        for _, state in ipairs(statusStates) do
            if state == "DEAD" or state == "KNOCKED" or state == "GRIPPED" then
                return "IGNORE"
            end
        end
    end

    if target:GetAttribute("PARRYING") then
        return "PARRIED"
    end

    if target:GetAttribute("BLOCKING") then
        local blockAngle = Modules.Combat.Constants.DEFENSE_PROPERTIES.BLOCK.angle or 180

        local targetLookVector = target.PrimaryPart.CFrame.LookVector
        local attackDirection = -lookVector

        local dotProduct = targetLookVector:Dot(attackDirection)
        local angle = math.acos(math.clamp(dotProduct, -1, 1)) * (180/math.pi)

        local isBlockable = angle <= blockAngle/2

        return isBlockable and {result = "BLOCKED", angle = angle} or "DAMAGED"
    end

    return "DAMAGED"
end

--[[ Combat Functions ]]
function CombatService:ExecuteCombat(player: Player, data: {[string]: any}): (boolean, string?)
    if not player or not data then return false, "Invalid input" end

    local character = player.Character
    if not character then return false, "No character found" end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, "Character is not alive"
    end

    local stamina = character:GetAttribute("STAMINA")
    local posture = character:GetAttribute("POSTURE")

    if not stamina or not posture then
        return false, "Missing required stats"
    end

    local combatType = data.type and string.upper(data.type)
    if not combatType then return false, "No combat type specified" end

    local handler = CombatService.CombatHandlers[combatType]
    if not handler then return false, "Invalid combat type" end

    return handler(self, character, data)
end

CombatService.CombatHandlers = {
    ATTACK = function(self, character, data)
        local attackType = data.attackType or "LIGHT"
        local attackProps = Modules.Combat.Constants.ATTACK_PROPERTIES[attackType]
        if not attackProps then return false, "Invalid attack type" end

        local stamina = character:GetAttribute("STAMINA")
        if stamina < attackProps.stamina_cost then
            return false, "Not enough stamina"
        end

        local comboCount = data.combo or 1
        if comboCount > 3 then return false, "Invalid combo count" end
        State.combos[character] = comboCount

        local stance = Services.State:GetCategory(character, "STANCE")[1] or "STANCE_NORMAL"
        local damageMultiplier = 1
        if stance == "STANCE_AGGRESSIVE" then
            damageMultiplier = 1.2
        elseif stance == "STANCE_DEFENSIVE" then
            damageMultiplier = 0.8
        end

        local hitTargets = self:CreateHitbox(character, attackType)
        for target, hitInfo in pairs(hitTargets) do
            local hitState = ""
            local blockAngle = nil

            if typeof(hitInfo) == "table" and hitInfo.result then
                hitState = hitInfo.result
                blockAngle = hitInfo.angle
            else
                hitState = hitInfo
            end

            if hitState == "DAMAGED" then
                local baseDamage = attackProps.damage_multiplier * 10
                local damage, isCritical = self:CalculateDamage(character, baseDamage * damageMultiplier)

                self:ApplyDamage(character, target, {
                    amount = damage,
                    type = Modules.Combat.Constants.DAMAGE_TYPES.PHYSICAL,
                    source = "attack",
                    critical = isCritical,
                    weapon = character:GetAttribute("EQUIPPED_WEAPON"),
                    metadata = {
                        attackType = attackType,
                        combo = comboCount,
                        stance = stance
                    }
                })
            elseif hitState == "PARRIED" then
                Services.Event:FireTo(target:FindFirstChild("OWNER"), "Client.Combat.Attack", {
                    type = "PARRY_SUCCESS",
                    success = true
                })
            elseif hitState == "BLOCKED" then
                Services.Event:FireTo(target:FindFirstChild("OWNER"), "Client.Combat.Attack", {
                    type = "BLOCK_SUCCESS",
                    success = true,
                    data = {
                        angle = blockAngle
                    }
                })
            end
        end

        Services.Stat:ModifyStat(character, "STAMINA", {
            operation = "subtract",
            value = attackProps.stamina_cost,
            metadata = { source = "attack" }
        })

        Services.State:EnterState(character, attackType .. "_ATTACK", {
            duration = attackProps.duration,
            combo = comboCount
        })

        return true
    end,

    BLOCK = function(self, character, data)
        local blockProps = Modules.Combat.Constants.DEFENSE_PROPERTIES.BLOCK
        local stamina = character:GetAttribute("STAMINA")

        if data.enabled == false then
            character:SetAttribute("BLOCKING", false)
            Services.State:ExitState(character, "BLOCK")
            return true
        end

        if stamina < blockProps.stamina_cost then 
            return false, "Not enough stamina" 
        end

        character:SetAttribute("BLOCKING", true)
        Services.State:EnterState(character, "BLOCK", {
            cleanup = function()
                character:SetAttribute("BLOCKING", false)
            end
        })

        Services.Stat:ModifyStat(character, "STAMINA", {
            operation = "subtract",
            value = blockProps.stamina_cost,
            metadata = { source = "block" }
        })

        return true
    end,

    PARRY = function(self, character, data)
        local parryProps = Modules.Combat.Constants.DEFENSE_PROPERTIES.PARRY
        local stamina = character:GetAttribute("STAMINA")

        if stamina < parryProps.stamina_cost then
            return false, "Not enough stamina"
        end

        character:SetAttribute("PARRYING", true)

        Services.State:EnterState(character, "PARRY", {
            duration = parryProps.window,
            cleanup = function()
                character:SetAttribute("PARRYING", false)
                State.parryWindows[character] = nil
            end
        })

        State.parryWindows[character] = {
            start = os.clock(),
            duration = parryProps.window
        }

        Services.Stat:ModifyStat(character, "STAMINA", {
            operation = "subtract",
            value = parryProps.stamina_cost,
            metadata = { source = "parry" }
        })

        return true
    end,

    FEINT = function(self, character, data)
        local stamina = character:GetAttribute("STAMINA")
        if stamina < 10 then return false, "Not enough stamina" end

        Services.State:EnterState(character, "FEINT", {
            duration = 0.2
        })

        Services.Stat:ModifyStat(character, "STAMINA", {
            operation = "subtract",
            value = 10,
            metadata = { source = "feint" }
        })

        State.combos[character] = 0
        return true
    end,

    EXECUTE = function(self, character, data)
        if not data.target then return false, "No target specified" end

        local target = data.target
        local targetStates = Services.State:GetCategory(target, "STATUS")
        if not (table.find(targetStates, "KNOCK") or table.find(targetStates, "DEAD")) then
            return false, "Invalid target state"
        end

        local distance = (character.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
        if distance > 5 then return false, "Target too far" end

        Services.State:EnterState(character, "EXECUTE", {
            target = target,
            duration = 2
        })

        self:ApplyDamage(character, target, {
            amount = 999999,
            type = Modules.Combat.Constants.DAMAGE_TYPES.TRUE,
            source = "execution",
            critical = true,
            metadata = { execution = true }
        })

        return true
    end,

    CARRY = function(self, character, data)
        if not data.target then return false, "No target specified" end

        local target = data.target
        local targetStates = Services.State:GetCategory(target, "STATUS")
        if not (table.find(targetStates, "KNOCK") or table.find(targetStates, "DEAD")) then
            return false, "Invalid target state"
        end

        if data.enabled then
            local distance = (character.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
            if distance > 5 then return false, "Target too far" end

            local attachment = Instance.new("Attachment")
            attachment.Parent = character.PrimaryPart
            attachment.Position = Vector3.new(0, 0, -1)

            local alignPos = Instance.new("AlignPosition")
            alignPos.Attachment0 = attachment
            alignPos.Attachment1 = target.PrimaryPart.RootAttachment
            alignPos.RigidityEnabled = true
            alignPos.Parent = target.PrimaryPart

            State.carriedTargets[character] = {
                target = target,
                attachment = attachment,
                alignPos = alignPos
            }

            Services.State:EnterState(character, "CARRY", {
                target = target
            })
            Services.State:EnterState(target, "GRIP")
        else
            local carried = State.carriedTargets[character]
            if carried then
                carried.alignPos:Destroy()
                carried.attachment:Destroy()
                State.carriedTargets[character] = nil
            end

            Services.State:ExitState(character, "CARRY")
            if target then
                Services.State:ExitState(target, "GRIP")
            end
        end

        return true
    end,

    STANCE = function(self, character, data)
        if not data.stance then return false, "No stance specified" end

        local validStances = {
            STANCE_NORMAL = true,
            STANCE_DEFENSIVE = true,
            STANCE_AGGRESSIVE = true
        }

        if not validStances[data.stance] then
            return false, "Invalid stance"
        end

        local currentStance = Services.State:GetCategory(character, "STANCE")[1]
        if currentStance then
            Services.State:ExitState(character, currentStance)
        end

        Services.State:EnterState(character, data.stance)
        return true
    end
}

--[[ Damage Functions ]]
function CombatService:ApplyDamage(attacker: any, target: any, damageInfo: DamageInfo)
    if not (target and damageInfo) then return false end

    if damageInfo.critical and damageInfo.vfx ~= false then
        Modules.Combat.Visuals.Critical(Modules.Combat, target, attacker, damageInfo)
    end

    if target:GetAttribute("BLOCKING") then
        local blockProps = Modules.Combat.Constants.DEFENSE_PROPERTIES.BLOCK

        if attacker and attacker.PrimaryPart and target.PrimaryPart then
            local targetLookVector = target.PrimaryPart.CFrame.LookVector
            local attackDirection = (attacker.PrimaryPart.Position - target.PrimaryPart.Position).Unit

            local dotProduct = targetLookVector:Dot(-attackDirection)
            local angle = math.acos(math.clamp(dotProduct, -1, 1)) * (180/math.pi)

            local angleFactor = 1 - (angle / (blockProps.angle/2))
            angleFactor = math.clamp(angleFactor, 0.3, 1)

            damageInfo.amount = damageInfo.amount * (1 - (blockProps.damage_reduction * angleFactor))
            local postureDamage = blockProps.posture_damage * (1 + angleFactor)

            Services.Stat:ModifyStat(target, "POSTURE", {
                operation = "subtract",
                value = postureDamage,
                metadata = { source = "block", angle = angle }
            })
        else
            damageInfo.amount = damageInfo.amount * (1 - blockProps.damage_reduction)

            Services.Stat:ModifyStat(target, "POSTURE", {
                operation = "subtract",
                value = blockProps.posture_damage,
                metadata = { source = "block" }
            })
        end
    end

    local parryWindow = State.parryWindows[target]
    if parryWindow and (os.clock() - parryWindow.start) <= parryWindow.duration then
        local parryProps = Modules.Combat.Constants.DEFENSE_PROPERTIES.PARRY

        Services.Stat:ModifyStat(target, "STAMINA", {
            operation = "add",
            value = parryProps.stamina_restore,
            metadata = { source = "parry" }
        })

        if attacker then
            Services.Stat:ModifyStat(attacker, "POSTURE", {
                operation = "subtract",
                value = parryProps.posture_damage,
                metadata = { source = "parried" }
            })
        end

        return true
    end

    local currentHealth = target:GetAttribute("HEALTH")
    Services.Stat:ModifyStat(target, "HEALTH", {
        operation = "subtract",
        value = damageInfo.amount,
        metadata = damageInfo.metadata
    })

    if currentHealth - damageInfo.amount <= 0 then
        Services.State:EnterState(target, "DEAD")

        local deathParticles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Particles"):WaitForChild("Death")
        if deathParticles then
            local clonedParticles = deathParticles:Clone()
            clonedParticles.Parent = target

            for _, emitter in ipairs(clonedParticles:GetDescendants()) do
                if emitter:IsA("ParticleEmitter") then
                    emitter.Enabled = true
                end
            end

            task.delay(5, function()
                clonedParticles:Destroy()
            end)
        end

        Services.Event:Fire("Combat.Death", {
            entity = target,
            damage = damageInfo
        })
    end

    Services.Event:Fire("Combat.Damage", {
        attacker = attacker,
        target = target,
        damage = damageInfo
    })

    return true
end

function CombatService:CalculateDamage(attacker: any, baseDamage: number): number
    local damage = baseDamage

    local stanceDamage = attacker:GetAttribute("STANCE_DAMAGE") or 1
    damage = damage * stanceDamage

    local resonance = attacker:GetAttribute("RESONANCE") or 0
    if resonance > 0 then
        damage = damage * (1 + (resonance / 100))
    end

    local weapon = Services.Weapon:GetWeapon(attacker)
    if weapon then
        local durability = weapon:GetAttribute("DURABILITY") or 100
        local sharpness = weapon:GetAttribute("SHARPNESS") or 100
        damage = damage * (0.5 + (0.5 * (durability / 100)))
        damage = damage * (0.8 + (0.2 * (sharpness / 100)))
    end

    local criticalChance = attacker:GetAttribute("CRITICAL_CHANCE") or 0.05
    local criticalMultiplier = attacker:GetAttribute("CRITICAL_MULTIPLIER") or 1.5
    local isCritical = math.random() < criticalChance

    if isCritical then
        damage = damage * criticalMultiplier
    end

    return damage, isCritical
end

return CombatService
