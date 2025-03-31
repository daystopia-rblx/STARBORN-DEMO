--[[ CombatService
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local CombatService = {}

CombatService.Dependencies = {
    "Data",
    "Event",
    "Stat",
    "State",
    "Weapon",
    "Equipment"
}

CombatService.Modules = {
    "Combat",
    "State"
}

CombatService.Events = {
    Attack = { validate = true },
    Block = { validate = true },
    Parry = { validate = true },
    Damage = { validate = true },
    Death = { validate = true }
}

local Services
local Modules

--[[ Types ]]
local Types = require(script.Parent.Parent.Parent.Modules.CombatModule)
type DamageInfo = Types.DamageInfo

--[[ Constants ]]
local DEBUG_HITBOX = false

--[[ State Management ]]
local State = {
    combatTimers = {},
    lastAttacks = {},
    parryWindows = {}
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
        end)
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
end

--[[ Hitbox Functions ]]
function CombatService:CreateHitbox(attacker: Model, attackType: string): {[Model]: string}
    if not (attacker and attacker.PrimaryPart) then return {} end
    local attackProps = Modules.Combat.Constants.ATTACK_PROPERTIES[attackType]
    if not attackProps then return {} end

    local attackerCF = attacker.PrimaryPart.CFrame
    local hitboxSize = Vector3.new(
        attackProps.width or 5,
        attackProps.height or 5,
        attackProps.range or 10
    )
    local hitboxPosition = attackerCF * CFrame.new(0, 0, -hitboxSize.Z / 2)
    local lookVector = attackerCF.LookVector

    if DEBUG_HITBOX then
        local debugPart = Instance.new("Part")
        debugPart.Name = "DebugHitbox"
        debugPart.Size = hitboxSize
        debugPart.CFrame = hitboxPosition
        debugPart.Transparency = 0.5
        debugPart.Color = Color3.new(1, 0, 0)
        debugPart.Material = Enum.Material.Neon
        debugPart.Anchored = true
        debugPart.CanCollide = false
        debugPart.Parent = workspace.Extra
        game.Debris:AddItem(debugPart, 0.2)
    end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = {workspace.Humanoids}
    overlapParams.MaxParts = 20

    local hitTargets = {}
    local parts = workspace:GetPartBoundsInBox(hitboxPosition, hitboxSize, overlapParams)
    if not parts then return hitTargets end

    local processed = {}
    for _, part in ipairs(parts) do
        local target = part.Parent
        if processed[target] or target == attacker or not target:FindFirstChild("HumanoidRootPart") then
            continue
        end
        processed[target] = true

        local hitState = self:DetermineHit(attacker, target, lookVector)
        hitTargets[target] = hitState
    end

    return hitTargets
end

function CombatService:DetermineHit(attacker: Model, target: Model, lookVector: Vector3): string
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
        local isFrontFacing = lookVector:Dot(target.PrimaryPart.CFrame.LookVector) > 0
        return isFrontFacing and "BLOCKED" or "DAMAGED"
    end

    return "DAMAGED"
end

--[[ Combat Functions ]]
function CombatService:AttackEntity(attacker: any, attackType: string, target: any?)
    if not (attacker and attackType) then return false, "Invalid input" end

    local attackProps = Modules.Combat.Constants.ATTACK_PROPERTIES[attackType]
    if not attackProps then return false, "Invalid attack type" end

    if not Services.State:ValidateState(attacker, "ATTACKING") then
        return false, "Cannot attack in current state"
    end

    local stamina = attacker:GetAttribute("STAMINA")
    if stamina < attackProps.stamina_cost then
        return false, "Insufficient stamina"
    end

    local weapon = Services.Weapon:GetWeapon(attacker)
    if not weapon then return false, "No weapon equipped" end

    local baseDamage = weapon.damage * attackProps.damage_multiplier
    local finalDamage, isCritical = self:CalculateDamage(attacker, baseDamage)

    Services.State:EnterState(attacker, "ATTACKING", {
        type = attackType,
        weapon = weapon.id,
        damage = finalDamage
    })

    Services.Stat:ModifyStat(attacker, "STAMINA", {
        operation = "subtract",
        value = attackProps.stamina_cost,
        metadata = { source = "attack" }
    })

    State.lastAttacks[attacker] = {
        type = attackType,
        time = os.clock(),
        damage = finalDamage
    }

    if target then
        task.delay(attackProps.duration * 0.5, function()
            self:ApplyDamage(attacker, target, {
                amount = finalDamage,
                type = "PHYSICAL",
                source = "attack",
                weapon = weapon.id,
                critical = isCritical
            })
        end)
    end

    Services.Event:Fire("Combat.Attack", {
        attacker = attacker,
        target = target,
        type = attackType,
        weapon = weapon.id,
        damage = finalDamage
    })

    return true
end

function CombatService:BlockEntity(blocker: any)
    if not blocker then return false end

    if not Services.State:ValidateState(blocker, "BLOCKING") then
        return false, "Cannot block in current state"
    end

    local weapon = Services.Weapon:GetWeapon(blocker)
    if not (weapon and weapon.properties.can_block) then
        return false, "Cannot block with current weapon"
    end

    Services.State:EnterState(blocker, "BLOCKING")

    Services.Event:Fire("Combat.Block", {
        blocker = blocker,
        weapon = weapon.id
    })

    return true
end

function CombatService:ParryEntity(parrier: any)
    if not parrier then return false end

    if not Services.State:ValidateState(parrier, "PARRYING") then
        return false, "Cannot parry in current state"
    end

    local weapon = Services.Weapon:GetWeapon(parrier)
    if not (weapon and weapon.properties.can_parry) then
        return false, "Cannot parry with current weapon"
    end

    Services.State:EnterState(parrier, "PARRYING")

    local parryProps = Modules.Combat.Constants.DEFENSE_PROPERTIES.PARRY
    State.parryWindows[parrier] = {
        start = os.clock(),
        duration = parryProps.window
    }

    Services.Event:Fire("Combat.Parry", {
        parrier = parrier,
        weapon = weapon.id
    })

    return true
end

--[[ Damage Functions ]]
function CombatService:ApplyDamage(attacker: any, target: any, damageInfo: DamageInfo)
    if not (target and damageInfo) then return false end

    if damageInfo.critical and damageInfo.vfx ~= false then
        Modules.Combat.Visuals.Critical(Modules.Combat, target, attacker, damageInfo)
    end

    if target:GetAttribute("BLOCKING") then
        local blockProps = Modules.Combat.Constants.DEFENSE_PROPERTIES.BLOCK
        damageInfo.amount = damageInfo.amount * (1 - blockProps.damage_reduction)

        Services.Stat:ModifyStat(target, "POSTURE", {
            operation = "subtract",
            value = blockProps.posture_damage,
            metadata = { source = "block" }
        })
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
