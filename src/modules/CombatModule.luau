--[[ CombatModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-03-31
]]
local CombatModule = {}

export type DamageInfo = {
    amount: number,
    type: string,
    source: string,
    critical: boolean?,
    backstab: boolean?,
    headshot: boolean?,
    weapon: string?,
    metadata: {[string]: any}?,
    vfx: boolean?
}

export type AttackInfo = {
    type: string,
    damage: number,
    stamina: number,
    posture: number,
    range: number,
    angle: number,
    duration: number,
    cooldown: number,
    metadata: {[string]: any}?
}

CombatModule.Constants = {
    DAMAGE_TYPES = {
        PHYSICAL = "PHYSICAL",
        MAGICAL = "MAGICAL",
        TRUE = "TRUE",
        POSTURE = "POSTURE"
    },

    ATTACK_TYPES = {
        LIGHT = "LIGHT",
        HEAVY = "HEAVY",
        CRITICAL = "CRITICAL",
        SPECIAL = "SPECIAL"
    },

    ATTACK_PROPERTIES = {
        LIGHT = {
            damage_multiplier = 1.0,
            stamina_cost = 15,
            posture_damage = 10,
            duration = 0.4,
            cooldown = 0.2
        },
        HEAVY = {
            damage_multiplier = 1.5,
            stamina_cost = 30,
            posture_damage = 25,
            duration = 0.6,
            cooldown = 0.4
        },
        CRITICAL = {
            damage_multiplier = 2.0,
            stamina_cost = 40,
            posture_damage = 40,
            duration = 0.8,
            cooldown = 1.5
        }
    },

    DEFENSE_PROPERTIES = {
        BLOCK = {
            damage_reduction = 0.8,
            stamina_cost = 5,
            posture_damage = 10,
            angle = 180,
            cooldown = 0.2
        },
        PARRY = {
            window = 0.2,
            recovery = 0.5,
            posture_damage = 30,
            stamina_restore = 20,
            cooldown = 0.2
        }
    },

    HIT_ZONES = {
        HEAD = {
            multiplier = 1.25,
            critical_chance = 0.1
        },
        TORSO = {
            multiplier = 1.0,
            critical_chance = 0.05
        },
        LIMBS = {
            multiplier = 0.8,
            critical_chance = 0.02
        }
    },

    CRITICAL = {
        duration = 0.65,
        responsiveness = 15,
        offset = CFrame.new(0, 3, -26.5),
        cleanup_delay = 0.25
    }
}

--[[ Visuals Handlers ]]
CombatModule.Visuals = {
    Critical = function(self, target: Model, attacker: Model, damageInfo: DamageInfo)
        if not (target and attacker) then return end

        target:SetAttribute("RAGDOLL", true)

        local vfxPart = Instance.new("Part")
        vfxPart.Position = attacker.PrimaryPart.CFrame * self.Constants.CRITICAL.offset.Position
        vfxPart.Name = "CriticalPart"
        vfxPart.Size = Vector3.one
        vfxPart.CanCollide = false
        vfxPart.Transparency = 1
        vfxPart.Parent = workspace.Extra

        local alignPosition = Instance.new("AlignPosition")
        alignPosition.Parent = target.PrimaryPart
        alignPosition.Name = "CriticalAlign"
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.Attachment0 = target.PrimaryPart.RootAttachment
        alignPosition.ApplyAtCenterOfMass = true
        alignPosition.Responsiveness = self.Constants.CRITICAL.responsiveness
        alignPosition.Position = vfxPart.Position

        task.delay(self.Constants.CRITICAL.cleanup_delay, function()
            vfxPart:Destroy()
        end)

        task.delay(self.Constants.CRITICAL.duration, function()
            alignPosition:Destroy()
            target:SetAttribute("RAGDOLL", false)
        end)
    end
}

return CombatModule