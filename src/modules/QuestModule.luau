--[[ QuestModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local QuestModule = {}

--[[ Types ]]
export type QuestCondition = {
    id: string,
    type: string,
    target: any,
    progress: number?,
    required: number?,
    approach: string?,
    isOptional: boolean?,
    metadata: {[string]: any}?
}

export type QuestObjective = {
    id: string,
    name: string,
    description: string,
    conditions: {[string]: QuestCondition},
    rewards: {[string]: any}?,
    isOptional: boolean?,
    isHidden: boolean?,
    metadata: {[string]: any}?
}

export type QuestBranch = {
    id: string,
    name: string,
    description: string,
    objectives: {[string]: QuestObjective},
    nextBranches: {string}?,
    requirements: {[string]: any}?,
    metadata: {[string]: any}?
}

export type QuestReward = {
    type: string,
    id: string?,
    amount: number?,
    metadata: {[string]: any}?
}

export type Quest = {
    id: string,
    type: string,
    name: string,
    description: string,
    hint: string?,
    chapter: number?,
    level: number?,
    branches: {[string]: QuestBranch},
    startingBranch: string,
    rewards: {[string]: QuestReward}?,
    requirements: {[string]: any}?,
    cooldown: number?,
    timeLimit: number?,
    isRepeatable: boolean?,
    isShareable: boolean?,
    maxParticipants: number?,
    metadata: {[string]: any}?
}

export type QuestState = {
    id: string,
    type: string,
    status: string,
    progress: {[string]: number},
    branch: string,
    startTime: number,
    endTime: number?,
    participants: {[string]: boolean}?,
    isTracked: boolean?,
    metadata: {[string]: any}?
}

--[[ Constants ]]
QuestModule.Types = {
    MAIN = "main",
    SIDE = "side",
    FACTION = "faction",
    DYNAMIC = "dynamic",
    DAILY = "daily",
    WEEKLY = "weekly",
    EVENT = "event",
    TUTORIAL = "tutorial",
    LEGACY = "legacy"
}

QuestModule.Status = {
    AVAILABLE = "available",
    ACTIVE = "active",
    COMPLETED = "completed",
    FAILED = "failed",
    LOCKED = "locked",
    EXPIRED = "expired",
    CANCELLED = "cancelled",
    PAUSED = "paused"
}

QuestModule.ApproachTypes = {
    ANY = "any",
    COMBAT = "combat",
    STEALTH = "stealth",
    DIPLOMACY = "diplomacy",
    EXPLORATION = "exploration"
}

QuestModule.ConditionTypes = {
    KILL = "kill",
    COLLECT = "collect",
    INTERACT = "interact",
    TALK = "talk",
    VISIT = "visit",
    ESCORT = "escort",
    DEFEND = "defend",
    CRAFT = "craft",
    USE = "use",
    EQUIP = "equip",
    DISCOVER = "discover",
    COMPLETE = "complete",
    FACTION_REP = "faction_rep",
    TIME_SURVIVED = "time_survived",
    STEAL = "steal",
    PERSUADE = "persuade"
}

QuestModule.RewardTypes = {
    ITEM = "item",
    CURRENCY = "currency",
    EXPERIENCE = "experience",
    REPUTATION = "reputation",
    FACTION_STANDING = "faction_standing",
    SKILL_POINT = "skill_point",
    ABILITY = "ability",
    LORE = "lore",
    TITLE = "title",
    COSMETIC = "cosmetic",
    BLUEPRINT = "blueprint",
    UNLOCK = "unlock"
}

QuestModule.Categories = {
    COMBAT = {
        name = "Combat",
        description = "Battle, kill or defeat enemies",
        color = Color3.fromRGB(220, 60, 60)
    },
    EXPLORATION = {
        name = "Exploration",
        description = "Discover and navigate the world",
        color = Color3.fromRGB(60, 220, 120)
    },
    DIPLOMACY = {
        name = "Diplomacy", 
        description = "Interact with characters and factions",
        color = Color3.fromRGB(120, 180, 255)
    },
    CRAFTING = {
        name = "Crafting",
        description = "Create and upgrade items",
        color = Color3.fromRGB(255, 180, 80)
    },
    STEALTH = {
        name = "Stealth",
        description = "Remain undetected and conceal actions",
        color = Color3.fromRGB(100, 100, 120)
    },
    PUZZLE = {
        name = "Puzzle",
        description = "Solve challenges with logic or skill",
        color = Color3.fromRGB(200, 120, 255)
    }
}

--[[ Templates ]]
QuestModule.Templates = {
    SimpleQuest = function(params: {
        id: string,
        name: string,
        description: string,
        type: string?,
        objectives: {{
            id: string?,
            name: string,
            description: string,
            conditions: {{
                type: string,
                target: any,
                required: number?
            }}
        }},
        rewards: {{
            type: string,
            id: string?,
            amount: number?
        }}?
    }): Quest
        local questId = params.id
        local questType = params.type or QuestModule.Types.SIDE
        local objectives = {}
        local branches = {}

        local mainBranchId = questId .. "_main"

        for i, objData in ipairs(params.objectives) do
            local objId = objData.id or (questId .. "_obj_" .. i)
            local conditions = {}

            for j, condData in ipairs(objData.conditions) do
                local condId = questId .. "_cond_" .. i .. "_" .. j
                conditions[condId] = {
                    id = condId,
                    type = condData.type,
                    target = condData.target,
                    required = condData.required or 1,
                    progress = 0
                }
            end

            objectives[objId] = {
                id = objId,
                name = objData.name,
                description = objData.description,
                conditions = conditions
            }
        end

        branches[mainBranchId] = {
            id = mainBranchId,
            name = params.name,
            description = params.description,
            objectives = objectives
        }

        local rewards = {}
        if params.rewards then
            for i, rewardData in ipairs(params.rewards) do
                local rewardId = questId .. "_reward_" .. i
                rewards[rewardId] = {
                    type = rewardData.type,
                    id = rewardData.id,
                    amount = rewardData.amount
                }
            end
        end

        return {
            id = questId,
            type = questType,
            name = params.name,
            description = params.description,
            branches = branches,
            startingBranch = mainBranchId,
            rewards = rewards,
            isRepeatable = false
        }
    end,

    BranchingQuest = function(params: {
        id: string,
        name: string,
        description: string,
        type: string?,
        branches: {{
            id: string,
            name: string,
            description: string,
            objectives: {{
                id: string,
                name: string,
                description: string,
                conditions: {{
                    type: string,
                    target: any,
                    required: number?
                }}
            }},
            nextBranches: {string}?
        }},
        startingBranch: string,
        rewards: {{
            type: string,
            id: string?,
            amount: number?
        }}?
    }): Quest
        local questId = params.id
        local questType = params.type or QuestModule.Types.MAIN
        local branches = {}

        for _, branchData in ipairs(params.branches) do
            local branchId = branchData.id
            local objectives = {}

            for i, objData in ipairs(branchData.objectives) do
                local objId = objData.id or (branchId .. "_obj_" .. i)
                local conditions = {}

                for j, condData in ipairs(objData.conditions) do
                    local condId = branchId .. "_cond_" .. i .. "_" .. j
                    conditions[condId] = {
                        id = condId,
                        type = condData.type,
                        target = condData.target,
                        required = condData.required or 1,
                        progress = 0
                    }
                end

                objectives[objId] = {
                    id = objId,
                    name = objData.name,
                    description = objData.description,
                    conditions = conditions
                }
            end

            branches[branchId] = {
                id = branchId,
                name = branchData.name,
                description = branchData.description,
                objectives = objectives,
                nextBranches = branchData.nextBranches
            }
        end

        local rewards = {}
        if params.rewards then
            for i, rewardData in ipairs(params.rewards) do
                local rewardId = questId .. "_reward_" .. i
                rewards[rewardId] = {
                    type = rewardData.type,
                    id = rewardData.id,
                    amount = rewardData.amount
                }
            end
        end

        return {
            id = questId,
            type = questType,
            name = params.name,
            description = params.description,
            branches = branches,
            startingBranch = params.startingBranch,
            rewards = rewards,
            isRepeatable = false
        }
    end,

    FactionQuest = function(params: {
        id: string,
        name: string,
        description: string,
        faction: string,
        objectives: {{
            id: string?,
            name: string,
            description: string,
            conditions: {{
                type: string,
                target: any,
                required: number?
            }}
        }},
        rewards: {{
            type: string,
            id: string?,
            amount: number?
        }}?,
        repReward: number?
    }): Quest
        local questId = params.id
        local objectives = {}
        local branches = {}

        local mainBranchId = questId .. "_main"

        for i, objData in ipairs(params.objectives) do
            local objId = objData.id or (questId .. "_obj_" .. i)
            local conditions = {}

            for j, condData in ipairs(objData.conditions) do
                local condId = questId .. "_cond_" .. i .. "_" .. j
                conditions[condId] = {
                    id = condId,
                    type = condData.type,
                    target = condData.target,
                    required = condData.required or 1,
                    progress = 0
                }
            end

            objectives[objId] = {
                id = objId,
                name = objData.name,
                description = objData.description,
                conditions = conditions
            }
        end

        branches[mainBranchId] = {
            id = mainBranchId,
            name = params.name,
            description = params.description,
            objectives = objectives
        }

        local rewards = {}
        if params.rewards then
            for i, rewardData in ipairs(params.rewards) do
                local rewardId = questId .. "_reward_" .. i
                rewards[rewardId] = {
                    type = rewardData.type,
                    id = rewardData.id,
                    amount = rewardData.amount
                }
            end
        end

        if params.repReward then
            rewards[questId .. "_faction_rep"] = {
                type = QuestModule.RewardTypes.FACTION_STANDING,
                id = params.faction,
                amount = params.repReward
            }
        end

        return {
            id = questId,
            type = QuestModule.Types.FACTION,
            name = params.name,
            description = params.description,
            branches = branches,
            startingBranch = mainBranchId,
            rewards = rewards,
            isRepeatable = false,
            metadata = {
                faction = params.faction
            }
        }
    end,

    DynamicQuest = function(params: {
        id: string,
        name: string,
        description: string,
        generationType: string,
        targetLocation: Vector3?,
        difficulty: number?,
        rewards: {{
            type: string,
            id: string?,
            amount: number?
        }}?
    }): Quest
        local questId = params.id
        local objectives = {}
        local branches = {}

        local mainBranchId = questId .. "_main"

        objectives[questId .. "_obj_1"] = {
            id = questId .. "_obj_1",
            name = "Dynamic Objective",
            description = "This objective will be generated at runtime",
            conditions = {
                [questId .. "_cond_1"] = {
                    id = questId .. "_cond_1",
                    type = "dynamic",
                    target = "dynamic",
                    required = 1,
                    progress = 0
                }
            }
        }

        branches[mainBranchId] = {
            id = mainBranchId,
            name = params.name,
            description = params.description,
            objectives = objectives
        }

        local rewards = {}
        if params.rewards then
            for i, rewardData in ipairs(params.rewards) do
                local rewardId = questId .. "_reward_" .. i
                rewards[rewardId] = {
                    type = rewardData.type,
                    id = rewardData.id,
                    amount = rewardData.amount
                }
            end
        end

        return {
            id = questId,
            type = QuestModule.Types.DYNAMIC,
            name = params.name,
            description = params.description,
            branches = branches,
            startingBranch = mainBranchId,
            rewards = rewards,
            isRepeatable = true,
            metadata = {
                generationType = params.generationType,
                targetLocation = params.targetLocation,
                difficulty = params.difficulty or 1
            }
        }
    end
}

--[[ Validation Functions ]]
function QuestModule.ValidateQuest(quest: Quest): (boolean, string?)
    if not quest.id or not quest.name or not quest.description then
        return false, "Missing required quest fields"
    end

    if not quest.branches or not quest.startingBranch then
        return false, "Quest must have branches and a starting branch"
    end

    if not quest.branches[quest.startingBranch] then
        return false, "Starting branch does not exist"
    end

    for branchId, branch in pairs(quest.branches) do
        if not branch.id or not branch.name or not branch.description then
            return false, string.format("Branch %s missing required fields", branchId)
        end

        if not branch.objectives or next(branch.objectives) == nil then
            return false, string.format("Branch %s has no objectives", branchId)
        end

        for objectiveId, objective in pairs(branch.objectives) do
            if not objective.id or not objective.name or not objective.description then
                return false, string.format("Objective %s missing required fields", objectiveId)
            end

            if not objective.conditions or next(objective.conditions) == nil then
                return false, string.format("Objective %s has no conditions", objectiveId)
            end

            for conditionId, condition in pairs(objective.conditions) do
                if not condition.id or not condition.type or condition.target == nil then
                    return false, string.format("Condition %s missing required fields", conditionId)
                end
            end
        end

        if branch.nextBranches then
            for _, nextBranchId in ipairs(branch.nextBranches) do
                if not quest.branches[nextBranchId] then
                    return false, string.format("Next branch %s does not exist", nextBranchId)
                end
            end
        end
    end

    return true
end

function QuestModule.CheckObjective(objective: QuestObjective, questState: QuestState?): boolean
    if not objective or not objective.conditions then
        return false
    end

    local conditionsMet = false
    local hasNonOptionalConditions = false

    for conditionId, condition in pairs(objective.conditions) do
        if not condition.isOptional then
            hasNonOptionalConditions = true
            local progress = (questState and questState.progress and questState.progress[conditionId]) or condition.progress or 0
            if progress >= (condition.required or 1) then
                conditionsMet = true
                break
            end
        end
    end

    return not hasNonOptionalConditions or conditionsMet
end

function QuestModule.CheckBranch(branch: QuestBranch, questState: QuestState?): boolean
    if not branch or not branch.objectives then
        return false
    end

    for _, objective in pairs(branch.objectives) do
        if not objective.isOptional and not QuestModule.CheckObjective(objective, questState) then
            return false
        end
    end

    return true
end

function QuestModule.GetProgress(quest: Quest, questState: QuestState): number
    if not quest or not questState then
        return 0
    end

    local totalObjectives = 0
    local completedObjectives = 0

    for _, branch in pairs(quest.branches) do
        for _, objective in pairs(branch.objectives) do
            if not objective.isOptional then
                totalObjectives += 1

                if QuestModule.CheckObjective(objective, questState) then
                    completedObjectives += 1
                end
            end
        end
    end

    if totalObjectives == 0 then
        return 100
    end

    return (completedObjectives / totalObjectives) * 100
end

function QuestModule.GetObjectives(quest: Quest, questState: QuestState): {QuestObjective}
    if not quest or not questState then
        return {}
    end

    local currentBranch = quest.branches[questState.branch]
    if not currentBranch then
        return {}
    end

    local incompleteObjectives = {}

    for _, objective in pairs(currentBranch.objectives) do
        if not QuestModule.CheckObjective(objective, questState) then
            table.insert(incompleteObjectives, objective)
        end
    end

    return incompleteObjectives
end

function QuestModule.GetObjectiveProgress(objective: QuestObjective): number
    if not objective or not objective.conditions then
        return 0
    end

    local totalProgress = 0
    local totalRequired = 0

    for _, condition in pairs(objective.conditions) do
        totalRequired += (condition.required or 1)
        totalProgress += math.min(condition.progress or 0, condition.required or 1)
    end

    if totalRequired == 0 then
        return 100
    end

    return (totalProgress / totalRequired) * 100
end

function QuestModule.CheckRequirements(requirements: {[string]: any}, playerState: {[string]: any}): boolean
    if not requirements then
        return true
    end

    for key, value in pairs(requirements) do
        local playerValue = playerState[key]
        if playerValue == nil or playerValue < value then
            return false
        end
    end

    return true
end

function QuestModule.GetRewards(quest: Quest): string
    if not quest or not quest.rewards then
        return "No rewards"
    end

    local rewardText = ""
    local rewardsByType = {}

    for _, reward in pairs(quest.rewards) do
        rewardsByType[reward.type] = rewardsByType[reward.type] or {}
        table.insert(rewardsByType[reward.type], reward)
    end

    local rewardDescriptions = {}

    if rewardsByType[QuestModule.RewardTypes.CURRENCY] then
        for _, reward in ipairs(rewardsByType[QuestModule.RewardTypes.CURRENCY]) do
            table.insert(rewardDescriptions, reward.amount .. " " .. (reward.id or "coins"))
        end
    end

    if rewardsByType[QuestModule.RewardTypes.EXPERIENCE] then
        for _, reward in ipairs(rewardsByType[QuestModule.RewardTypes.EXPERIENCE]) do
            table.insert(rewardDescriptions, reward.amount .. " XP")
        end
    end

    if rewardsByType[QuestModule.RewardTypes.ITEM] then
        for _, reward in ipairs(rewardsByType[QuestModule.RewardTypes.ITEM]) do
            local quantity = reward.amount and reward.amount > 1 and (" x" .. reward.amount) or ""
            table.insert(rewardDescriptions, (reward.id or "item") .. quantity)
        end
    end

    if rewardsByType[QuestModule.RewardTypes.FACTION_STANDING] then
        for _, reward in ipairs(rewardsByType[QuestModule.RewardTypes.FACTION_STANDING]) do
            local sign = reward.amount >= 0 and "+" or ""
            table.insert(rewardDescriptions, sign .. reward.amount .. " " .. (reward.id or "faction") .. " standing")
        end
    end

    for rewardType, rewards in pairs(rewardsByType) do
        if rewardType ~= QuestModule.RewardTypes.CURRENCY and
           rewardType ~= QuestModule.RewardTypes.EXPERIENCE and
           rewardType ~= QuestModule.RewardTypes.ITEM and
           rewardType ~= QuestModule.RewardTypes.FACTION_STANDING then
            for _, reward in ipairs(rewards) do
                local rewardName = reward.id or QuestModule.RewardTypes[rewardType] or rewardType
                table.insert(rewardDescriptions, rewardName)
            end
        end
    end

    return table.concat(rewardDescriptions, ", ")
end

return QuestModule