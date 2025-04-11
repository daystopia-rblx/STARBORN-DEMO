--[[ QuestService
    Manages player quests, objectives, and quest-related rewards.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local QuestService = {}

QuestService.Dependencies = {
    "Event",
    "Data",
    "Memory",
    "Inventory"
}

QuestService.Modules = {
    "Quest"
}

QuestService.Events = {
    Start = { validate = true },
    Complete = { validate = true },
    Update = { validate = true },
    Fail = { validate = true },
    Track = { validate = true },
    Condition = { validate = true },
    Objective = { validate = true }
}

local Services
local Modules
local State = {
    questCollection = {},
    playerQuests = {},
    questEvents = {}
}

QuestService.Listeners = {
    ["Data.Init"] = function(self, data)
        if not data or not data.userId or not data.player then return end

        local userId = data.userId
        local playerData = data.data.PlayerData

        State.playerQuests[userId] = {}

        if playerData and playerData.quests then
            for questId, questState in pairs(playerData.quests.active) do
                if State.questCollection[questId] then
                    State.playerQuests[userId][questId] = questState

                    if questState.status == Modules.Quest.Status.ACTIVE then
                        Services.Event:FireTo(data.player, "Quest.Update", {
                            questId = questId,
                            questState = questState
                        })
                    end
                end
            end

            if playerData.quests.tracked then
                self:TrackQuest(data.player, playerData.quests.tracked, true)
            end
        end
    end,

    ["Memory.Reputation"] = function(self, data)
        if data and data.player and data.factionId and data.value then
            self:ProcessEvent("faction_rep", data.player, {
                target = data.factionId,
                amount = data.value
            })
        end
    end,

    ["Combat.Death"] = function(self, data)
        if data and data.player and data.target then
            local entityType = data.target:GetAttribute("TYPE") or data.target.Name
            self:ProcessEvent("kill", data.player, {
                target = entityType,
                amount = 1
            })
        end
    end,

    ["Inventory.Add"] = function(self, data)
        if data and data.player and data.itemId then
            self:ProcessEvent("collect", data.player, {
                target = data.itemId,
                amount = data.amount or 1
            })
        end
    end,

    ["Interact.End"] = function(self, data)
        if data and data.player and data.object then
            local objectId = data.object:GetAttribute("ID") or data.object.Name
            self:ProcessEvent("interact", data.player, {
                target = objectId,
                amount = 1
            })
        end
    end,

    ["Dialogue.Start"] = function(self, data)
        if data and data.player and data.npcId then
            self:ProcessEvent("talk", data.player, {
                target = data.npcId,
                amount = 1
            })
        end
    end,

    ["Zone.Enter"] = function(self, data)
        if data and data.player and data.zoneId then
            self:ProcessEvent("visit", data.player, {
                target = data.zoneId,
                amount = 1
            })
        end
    end
}

--[[ Core Functions ]]
function QuestService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function QuestService:Start()
    self:LoadQuests()

    task.spawn(function()
        while true do
            self:ProcessQuests()
            task.wait(30)
        end
    end)

    return true
end

function QuestService:Cleanup()
    table.clear(State.playerQuests)
    table.clear(State.questEvents)
end

--[[ Utility Functions ]]
function QuestService:RegisterEvents(quest)
    if not quest or not quest.branches then return end

    for _, branch in pairs(quest.branches) do
        for _, objective in pairs(branch.objectives) do
            for conditionId, condition in pairs(objective.conditions) do
                local eventType = condition.type
                State.questEvents[eventType] = State.questEvents[eventType] or {}
            end
        end
    end
end

function QuestService:GetState(player)
    local playerState = {}

    if Services.Inventory then
        local inventory = Services.Inventory:GetInventory(player)
        for itemId, quantity in pairs(inventory) do
            playerState["item_" .. itemId] = quantity
        end
    end

    if State.playerQuests[player.UserId] then
        for questId, questState in pairs(State.playerQuests[player.UserId]) do
            if questState.status == Modules.Quest.Status.COMPLETED then
                playerState["quest_" .. questId] = true
            end
        end
    end

    return playerState
end

--[[ Quest Management Functions ]]
function QuestService:LoadQuests()
    local questsFolder = game:GetService("ReplicatedStorage").Modules.Data.Quest
    if not questsFolder then
        warn("Quests folder not found")
        return
    end

    for _, module in pairs(questsFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local success, questData = pcall(require, module)
            if success and type(questData) == "table" then
                for id, quest in pairs(questData) do
                    local isValid = true
                    if isValid then
                        State.questCollection[id] = quest
                    else
                        warn("Failed to register quest", tostring(id))
                    end
                end
            else
                warn("Failed to load quests from", module.Name, ":", tostring(questData))
            end
        end
    end

    local totalQuests = 0
    for _ in pairs(State.questCollection) do
        totalQuests += 1
    end
end

function QuestService:GetAvailable(player)
    local availableQuests = {}

    local playerState = self:GetState(player)

    for questId, quest in pairs(State.questCollection) do
        local hasQuest = State.playerQuests[player.UserId] and 
                        State.playerQuests[player.UserId][questId] ~= nil

        local canTake = not hasQuest or
                        (quest.isRepeatable and
                         State.playerQuests[player.UserId][questId].status == Modules.Quest.Status.COMPLETED)

        local meetsRequirements = Modules.Quest.CheckRequirements(quest.requirements, playerState)

        if canTake and meetsRequirements then
            table.insert(availableQuests, quest)
        end
    end

    return availableQuests
end

function QuestService:GetActive(player)
    local activeQuests = {}

    if not State.playerQuests[player.UserId] then
        return activeQuests
    end

    for questId, questState in pairs(State.playerQuests[player.UserId]) do
        if questState.status == Modules.Quest.Status.ACTIVE and State.questCollection[questId] then
            table.insert(activeQuests, {
                quest = State.questCollection[questId],
                state = questState
            })
        end
    end

    return activeQuests
end

function QuestService:StartQuest(player, questId)
    if not State.questCollection[questId] then
        return false, "Quest does not exist"
    end

    local quest = State.questCollection[questId]

    State.playerQuests[player.UserId] = State.playerQuests[player.UserId] or {}

    if State.playerQuests[player.UserId][questId] and
       State.playerQuests[player.UserId][questId].status == Modules.Quest.Status.ACTIVE then
        return false, "Quest already active"
    end

    local playerState = self:GetState(player)
    if not Modules.Quest.CheckRequirements(quest.requirements, playerState) then
        return false, "Requirements not met"
    end

    local questState = {
        id = questId,
        type = quest.type,
        status = Modules.Quest.Status.ACTIVE,
        progress = {},
        branch = quest.startingBranch,
        startTime = os.time(),
        participants = { [player.UserId] = true },
        isTracked = true
    }

    local branch = quest.branches[quest.startingBranch]
    for _, objective in pairs(branch.objectives) do
        for conditionId, condition in pairs(objective.conditions) do
            questState.progress[conditionId] = 0
        end
    end

    State.playerQuests[player.UserId][questId] = questState

    Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
        if not data.quests then
            data.quests = {
                active = {},
                completed = {},
                failed = {},
                lastUpdated = 0,
                tracked = nil
            }
        end

        data.quests.active[questId] = questState
        data.quests.lastUpdated = os.time()

        if questState.isTracked then
            data.quests.tracked = questId
        end

        return data
    end)

    Services.Event:FireTo(player, "Quest.Start", {
        questId = questId,
        questState = questState,
        quest = quest
    })

    Services.Event:Fire("Quest.Start", {
        player = player,
        questId = questId,
        questType = quest.type
    })

    return true
end

function QuestService:CompleteQuest(player, questId)
    if not State.playerQuests[player.UserId] or not State.playerQuests[player.UserId][questId] then
        return false, "Quest not found"
    end

    local questState = State.playerQuests[player.UserId][questId]
    if questState.status ~= Modules.Quest.Status.ACTIVE then
        return false, "Quest not active"
    end

    local quest = State.questCollection[questId]
    if not quest then
        return false, "Quest definition not found"
    end

    local currentBranch = quest.branches[questState.branch]
    if not Modules.Quest.CheckBranch(currentBranch, questState) then
        return false, "Not all objectives completed"
    end

    if currentBranch.nextBranches and #currentBranch.nextBranches > 0 then
        questState.branch = currentBranch.nextBranches[1]

        local newBranch = quest.branches[questState.branch]
        for _, objective in pairs(newBranch.objectives) do
            for conditionId in pairs(objective.conditions) do
                questState.progress[conditionId] = 0
            end
        end

        Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
            if data.quests and data.quests.active and data.quests.active[questId] then
                data.quests.active[questId] = questState
                data.quests.lastUpdated = os.time()
            end
            return data
        end)

        Services.Event:FireTo(player, "Quest.Update", {
            questId = questId,
            questState = questState
        })

        Services.Event:Fire("Quest.Update", {
            player = player,
            questId = questId,
            branch = questState.branch
        })

        return true, "Advanced to next branch"
    else
        questState.status = Modules.Quest.Status.COMPLETED
        questState.endTime = os.time()

        self:DistributeRewards(player, quest, questId)

        Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
            if not data.quests then
                data.quests = {
                    active = {},
                    completed = {},
                    failed = {},
                    lastUpdated = 0,
                    tracked = nil
                }
            end

            if data.quests.active and data.quests.active[questId] then
                data.quests.active[questId] = nil
            end

            data.quests.completed[questId] = questState
            data.quests.lastUpdated = os.time()

            if data.quests.tracked == questId then
                data.quests.tracked = nil
            end

            return data
        end)

        Services.Event:FireTo(player, "Quest.Complete", {
            questId = questId,
            questState = questState,
            rewards = Modules.Quest.GetRewards(quest)
        })

        Services.Event:Fire("Quest.Complete", {
            player = player,
            questId = questId,
            questType = quest.type
        })

        return true, "Quest completed"
    end
end

function QuestService:FailQuest(player, questId, reason)
    if not State.playerQuests[player.UserId] or not State.playerQuests[player.UserId][questId] then
        return false, "Quest not found"
    end

    local questState = State.playerQuests[player.UserId][questId]
    if questState.status ~= Modules.Quest.Status.ACTIVE then
        return false, "Quest not active"
    end

    questState.status = Modules.Quest.Status.FAILED
    questState.endTime = os.time()
    questState.failReason = reason

    Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
        if not data.quests then
            data.quests = {
                active = {},
                completed = {},
                failed = {},
                lastUpdated = 0,
                tracked = nil
            }
        end

        if data.quests.active and data.quests.active[questId] then
            data.quests.active[questId] = nil
        end

        data.quests.failed[questId] = questState
        data.quests.lastUpdated = os.time()

        if data.quests.tracked == questId then
            data.quests.tracked = nil
        end

        return data
    end)

    Services.Event:FireTo(player, "Quest.Fail", {
        questId = questId,
        questState = questState,
        reason = reason
    })

    Services.Event:Fire("Quest.Fail", {
        player = player,
        questId = questId,
        reason = reason
    })

    return true
end

function QuestService:TrackQuest(player, questId, shouldTrack)
    if not State.playerQuests[player.UserId] or not State.playerQuests[player.UserId][questId] then
        return false, "Quest not found"
    end

    local questState = State.playerQuests[player.UserId][questId]
    if questState.status ~= Modules.Quest.Status.ACTIVE then
        return false, "Quest not active"
    end

    questState.isTracked = shouldTrack

    Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
        if not data.quests then
            data.quests = {
                active = {},
                completed = {},
                failed = {},
                lastUpdated = 0,
                tracked = nil
            }
        end

        if data.quests.active and data.quests.active[questId] then
            data.quests.active[questId].isTracked = shouldTrack
        end

        if shouldTrack then
            data.quests.tracked = questId
        elseif data.quests.tracked == questId then
            data.quests.tracked = nil
        end

        data.quests.lastUpdated = os.time()
        return data
    end)

    Services.Event:FireTo(player, "Quest.Track", {
        questId = questId,
        isTracked = shouldTrack
    })

    return true
end

function QuestService:DistributeRewards(player, source, sourceId)
    if not source or not source.rewards then return end

    for _, reward in pairs(source.rewards) do
        local rewardData = reward
        if sourceId then
            rewardData = table.clone(reward)
            rewardData.sourceId = sourceId
        end
        self:GiveReward(player, rewardData)
    end
end

function QuestService:GiveReward(player, reward)
    if reward.type == Modules.Quest.RewardTypes.ITEM then
        if Services.Inventory then
            Services.Inventory:AddItem(player, reward.id, reward.amount or 1)
        end
    elseif reward.type == Modules.Quest.RewardTypes.CURRENCY then
        if Services.Economy then
            Services.Economy:RewardCurrency(player.UserId, reward.amount or 1, {
                source = "quest_reward",
                questId = reward.questId,
                sourceId = reward.sourceId
            })
        end
    elseif reward.type == Modules.Quest.RewardTypes.EXPERIENCE then
        if Services.Character then
            Services.Character:AddExperience(player, reward.amount or 1)
        end
    elseif reward.type == Modules.Quest.RewardTypes.FACTION_STANDING then
        if Services.Memory then
            Services.Memory:UpdateReputation(player, reward.id, reward.amount or 1)
        end
    end
end

function QuestService:SetBranch(player, questId, targetBranchId)
    if not State.playerQuests[player.UserId] or not State.playerQuests[player.UserId][questId] then
        return false, "Quest not found for player"
    end

    local questState = State.playerQuests[player.UserId][questId]
    if questState.status ~= Modules.Quest.Status.ACTIVE then
        return false, "Quest is not active"
    end

    local quest = State.questCollection[questId]
    if not quest then
        return false, "Quest definition not found"
    end

    local targetBranch = quest.branches[targetBranchId]
    if not targetBranch then
        return false, "Target branch does not exist in quest definition"
    end

    questState.branch = targetBranchId
    questState.progress = {}

    for _, objective in pairs(targetBranch.objectives) do
        for conditionId in pairs(objective.conditions) do
            questState.progress[conditionId] = 0
        end
    end

    Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
        if data.quests and data.quests.active and data.quests.active[questId] then
            data.quests.active[questId] = questState
            data.quests.lastUpdated = os.time()
        end
        return data
    end)

    Services.Event:FireTo(player, "Quest.Update", {
        questId = questId,
        questState = questState
    })

    Services.Event:Fire("Quest.Update", {
        player = player,
        questId = questId,
        branch = questState.branch,
        reason = "dialogue_choice"
    })

    return true, "Quest branch updated successfully"
end

function QuestService:UpdateProgress(player, questId, conditionId, progress)
    if not State.playerQuests[player.UserId] or not State.playerQuests[player.UserId][questId] then
        return false, "Quest not found"
    end

    local questState = State.playerQuests[player.UserId][questId]
    if questState.status ~= Modules.Quest.Status.ACTIVE then
        return false, "Quest not active"
    end

    local quest = State.questCollection[questId]
    if not quest then
        return false, "Quest definition not found"
    end

    local branch = quest.branches[questState.branch]
    if not branch then
        return false, "Branch not found"
    end

    local condition = nil
    local objective = nil

    for _, obj in pairs(branch.objectives) do
        if obj.conditions[conditionId] then
            condition = obj.conditions[conditionId]
            objective = obj
            break
        end
    end

    if not condition then
        return false, "Condition not found in current branch"
    end

    local newProgress = progress
    if newProgress > (condition.required or 1) then
        newProgress = condition.required or 1
    end

    local oldProgress = questState.progress[conditionId] or 0
    questState.progress[conditionId] = newProgress

    Services.Data:UpdateData(player.UserId, "PlayerData", function(data)
        if not data.quests then
            data.quests = {
                active = {},
                completed = {},
                failed = {},
                lastUpdated = 0,
                tracked = nil
            }
        end

        if data.quests.active and data.quests.active[questId] then
            data.quests.active[questId].progress[conditionId] = newProgress
            data.quests.lastUpdated = os.time()
        end

        return data
    end)

    if newProgress >= (condition.required or 1) and oldProgress < (condition.required or 1) then
        local objectiveComplete = true
        for _, cond in pairs(objective.conditions) do
            if not cond.isOptional and
               (questState.progress[cond.id] or 0) < (cond.required or 1) then
                objectiveComplete = false
                break
            end
        end

        if objectiveComplete then
            if objective.rewards then
                self:DistributeRewards(player, objective, objective.id)
            end

            local branchComplete = true
            for _, obj in pairs(branch.objectives) do
                if not obj.isOptional and not Modules.Quest.CheckObjective(obj, questState) then
                    branchComplete = false
                    break
                end
            end

            if branchComplete then
                self:CompleteQuest(player, questId)
            end
        end
    end

    Services.Event:FireTo(player, "Quest.Update", {
        questId = questId,
        questState = questState
    })

    return true
end

function QuestService:ProcessQuests()
    for userId, playerQuestData in pairs(State.playerQuests) do
        local player = game.Players:GetPlayerByUserId(userId)
        if player then
            for questId, questState in pairs(playerQuestData) do
                if questState.status == Modules.Quest.Status.ACTIVE then
                    local quest = State.questCollection[questId]
                    if quest and quest.timeLimit then
                        local elapsed = os.time() - questState.startTime
                        if elapsed > quest.timeLimit then
                            self:FailQuest(player, questId, "Time limit exceeded")
                        end
                    end
                end
            end
        end
    end
end

function QuestService:ProcessEvent(eventType, player, data)
    if not player or not State.playerQuests[player.UserId] then return end

    for questId, questState in pairs(State.playerQuests[player.UserId]) do
        if questState.status == Modules.Quest.Status.ACTIVE then
            local quest = State.questCollection[questId]
            if not quest then continue end

            local branch = quest.branches[questState.branch]
            if not branch then continue end

            for _, objective in pairs(branch.objectives) do
                for conditionId, condition in pairs(objective.conditions) do
                    if condition.type == eventType then
                        local match = false

                        if type(condition.target) == "string" then
                            match = condition.target == "*" or condition.target == data.target
                        elseif type(condition.target) == "table" then
                            for _, target in ipairs(condition.target) do
                                if target == data.target then
                                    match = true
                                    break
                                end
                            end
                        end

                        if match then
                            local progress = questState.progress[conditionId] or 0
                            progress += (data.amount or 1)
                            self:UpdateProgress(player, questId, conditionId, progress)
                        end
                    end
                end
            end
        end
    end
end

return QuestService