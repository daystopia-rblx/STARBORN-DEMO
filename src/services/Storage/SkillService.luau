--[[ SkillService
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-07
]]
local SkillService = {}

SkillService.Dependencies = {
    "Data",
    "Event",
    "Stat"
}

SkillService.Modules = {
    "Skill"
}

SkillService.Events = {
    Acquire = { validate = true },
    Activate = { validate = true },
    Deactivate = { validate = true },
    Cooldown = { validate = true }
}

local Players = game:GetService("Players")
local Services
local Modules

--[[ State Management ]]
local State = {
    activeSkills = {},
    cooldowns = {},
    modifiers = setmetatable({}, {
        __index = function(self, key)
            if not rawget(self, key) then
                rawset(self, key, {})
            end
            return rawget(self, key)
        end
    })
}

--[[ Core Functions ]]
function SkillService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function SkillService:Start()
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayer(player)
    end)

    return true
end

function SkillService:Cleanup()
    for player, _ in pairs(State.activeSkills) do
        self:CleanupPlayer(player)
    end
    table.clear(State.activeSkills)
    table.clear(State.cooldowns)
    table.clear(State.modifiers)
end

--[[ Player Management ]]
function SkillService:InitializePlayer(player: Player)
    State.activeSkills[player] = {}
    State.cooldowns[player] = {}
    State.modifiers[player] = {}
end

function SkillService:CleanupPlayer(player: Player)
    if State.activeSkills[player] then
        for skillId, _ in pairs(State.activeSkills[player]) do
            self:DeactivateSkill(player, skillId)
        end
    end

    if State.modifiers[player] then
        for statName, modifiers in pairs(State.modifiers[player]) do
            for modifierId, _ in pairs(modifiers) do
                Services.Stat:RemoveModifier(player, statName, modifierId)
            end
        end
    end

    State.activeSkills[player] = nil
    State.cooldowns[player] = nil
    State.modifiers[player] = nil
end

--[[ Effect Functions ]]
function SkillService:ApplyEffect(player: Player, skillId: string, effectName: string, effect: {type: string, value: any})
    local modifierId = skillId .. "_" .. effectName
    local value = type(effect.value) == "function" and effect.value(player) or effect.value

    State.modifiers[player][effectName] = State.modifiers[player][effectName] or {}
    State.modifiers[player][effectName][modifierId] = value

    Services.Stat:AddModifier(player, effectName, {
        id = modifierId,
        value = value,
        type = effect.type,
        source = "skill",
        metadata = {
            skillId = skillId
        }
    })
end

function SkillService:RemoveEffect(player: Player, skillId: string, effectName: string)
    local modifierId = skillId .. "_" .. effectName
    if State.modifiers[player][effectName] then
        State.modifiers[player][effectName][modifierId] = nil
        if not next(State.modifiers[player][effectName]) then
            State.modifiers[player][effectName] = nil
        end
    end

    Services.Stat:RemoveModifier(player, effectName, modifierId)
end

--[[ Skill Functions ]]
function SkillService:AcquireSkill(player: Player, skillId: string): boolean
    local skill = Modules.Skill.GetSkill(skillId)
    if not skill then return false end

    local skillPoints = Services.Stat:GetPoints(player, "SKILL")
    if skillPoints < 1 then return false end

    if skill.requirements then
        if skill.requirements.level and Services.Stat:GetStat(player, "LEVEL") < skill.requirements.level then
            return false
        end

        if skill.requirements.stats then
            for statName, requiredValue in pairs(skill.requirements.stats) do
                if Services.Stat:GetStat(player, statName) < requiredValue then
                    return false
                end
            end
        end

        if skill.requirements.skills then
            for _, requiredSkill in ipairs(skill.requirements.skills) do
                if not self:HasSkill(player, requiredSkill) then
                    return false
                end
            end
        end

        if skill.requirements.conditions then
            for _, condition in ipairs(skill.requirements.conditions) do
                if not condition(player) then
                    return false
                end
            end
        end
    end

    local activeCount = 0
    local passiveCount = 0
    for _, activeSkill in pairs(State.activeSkills[player]) do
        if activeSkill.isPassive then
            passiveCount += 1
        else
            activeCount += 1
        end
    end

    if skill.isPassive and passiveCount >= Modules.Skill.Constants.MAX_PASSIVE_SKILLS then
        return false
    elseif not skill.isPassive and activeCount >= Modules.Skill.Constants.MAX_ACTIVE_SKILLS then
        return false
    end

    if not Services.Stat:SpendPoints(player, "SKILL", 1) then
        return false
    end

    State.activeSkills[player][skillId] = skill

    if skill.isPassive and skill.effects then
        for effectName, effect in pairs(skill.effects) do
            self:ApplyEffect(player, skillId, effectName, effect)
        end
    end

    Services.Event:Fire("Skill.Acquire", {
        player = player,
        skillId = skillId,
        skill = skill
    })

    return true
end

function SkillService:HasSkill(player: Player, skillId: string): boolean
    return State.activeSkills[player] and State.activeSkills[player][skillId] ~= nil
end

function SkillService:ActivateSkill(player: Player, skillId: string): boolean
    local skill = State.activeSkills[player] and State.activeSkills[player][skillId]
    if not skill or skill.isPassive then return false end

    local cooldown = State.cooldowns[player][skillId]
    if cooldown and cooldown > tick() then return false end

    if skill.manaCost and Services.Stat:GetStat(player, "MANA") < skill.manaCost then
        return false
    end
    if skill.staminaCost and Services.Stat:GetStat(player, "STAMINA") < skill.staminaCost then
        return false
    end

    if skill.manaCost then
        Services.Stat:ModifyStat(player, "MANA", {
            operation = "subtract",
            value = skill.manaCost,
            metadata = {
                source = "skill_cost",
                skillId = skillId
            }
        })
    end
    if skill.staminaCost then
        Services.Stat:ModifyStat(player, "STAMINA", {
            operation = "subtract",
            value = skill.staminaCost,
            metadata = {
                source = "skill_cost",
                skillId = skillId
            }
        })
    end

    if skill.effects then
        for effectName, effect in pairs(skill.effects) do
            self:ApplyEffect(player, skillId, effectName, effect)
        end
    end

    if skill.cooldown then
        State.cooldowns[player][skillId] = tick() + skill.cooldown
        task.delay(skill.cooldown, function()
            if State.cooldowns[player] then
                State.cooldowns[player][skillId] = nil
                Services.Event:Fire("Skill.Cooldown", {
                    player = player,
                    skillId = skillId
                })
            end
        end)
    end

    Services.Event:Fire("Skill.Activate", {
        player = player,
        skillId = skillId,
        skill = skill
    })

    if skill.metadata and skill.metadata.duration then
        task.delay(skill.metadata.duration, function()
            self:DeactivateSkill(player, skillId)
        end)
    end

    return true
end

function SkillService:DeactivateSkill(player: Player, skillId: string): boolean
    local skill = State.activeSkills[player] and State.activeSkills[player][skillId]
    if not skill or skill.isPassive then return false end

    if skill.effects then
        for effectName, _ in pairs(skill.effects) do
            self:RemoveEffect(player, skillId, effectName)
        end
    end

    Services.Event:Fire("Skill.Deactivate", {
        player = player,
        skillId = skillId,
        skill = skill
    })

    return true
end

return SkillService