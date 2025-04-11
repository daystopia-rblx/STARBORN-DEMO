--[[ DialogueService
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local DialogueService = {}

--[[ Dependencies ]]
DialogueService.Dependencies = {
    "Event",
    "Data",
    "Animation",
    "Audio",
    "Particle",
    "Quest",
    "Object",
    "Inventory",
    "Stat",
    "Memory",
    "Faction"
}

--[[ Events ]]
DialogueService.Events = {
    Start = true,
    End = true,
    Progress = true,
    Remind = true,
    Cleanup = true
}

--[[ Modules ]]
DialogueService.Modules = {
    "Dialogue",
    "Person"
}

--[[ Services & Modules ]]
local Services
local Modules

--[[ Types ]]
type DialogueState = {
    currentTree: string?,
    currentLine: string?,
    completedDialogues: {[string]: boolean},
    interruptedDialogues: {[string]: {
        lineId: string,
        type: string,
        timestamp: number,
        context: {[string]: any}?
    }}
}

--[[ State ]]
local state = {
    dialogueTrees = {},
    playerStates = {} :: {[string]: DialogueState},
    dialogueGenerators = {},
    warningStates = {} :: {[string]: {
        isWarning: boolean,
        warningTime: number?,
        lastDialogue: {
            text: string,
            responses: {any}?
        }?,
        activeInterruption: string?
    }},
    dialogueHistory = {} :: {[string]: {
        treeId: string,
        lineId: string,
        timestamp: number,
        metadata: {[string]: any}?
    }}
}

--[[ Interruption Types ]]
DialogueService.InterruptionType = {
    DISTANCE = "distance",
    COMBAT = "combat",
    TIMEOUT = "timeout",
    FORCED_CANCEL = "forced_cancel",
    PLAYER_INTERRUPT = "player_interrupt",
    PLAYER_RUSH = "player_rush"
}

--[[ Warning Config ]]
local WarningConfig = {
    [DialogueService.InterruptionType.DISTANCE] = {
        threshold = 8,
        maxThreshold = 12,
        duration = 5,
        warningMessage = "Stay your ground, traveler. Our words are not yet finished.",
        returnMessage = "Good. Now, as I was about to tell you...",
        moodEffect = -10
    },
    [DialogueService.InterruptionType.COMBAT] = {
        threshold = 0,
        duration = 2,
        warningMessage = "Blood is spilling! Defend yourself first, then we shall speak again.",
        returnMessage = "Your wounds seem contained. Let us continue our discussion...",
        moodEffect = 0
    },
    [DialogueService.InterruptionType.TIMEOUT] = {
        threshold = 45,
        maxThreshold = 60,
        duration = 15,
        warningMessage = "Has your mind drifted to the void? Focus on my words.",
        returnMessage = "Your attention returns. Now, where were we...",
        moodEffect = -5
    },
    [DialogueService.InterruptionType.PLAYER_INTERRUPT] = {
        threshold = 0,
        duration = 2,
        warningMessage = "You dare interrupt me? Mind your manners!",
        returnMessage = "Very well, I shall be brief...",
        moodEffect = -15
    },
    [DialogueService.InterruptionType.PLAYER_RUSH] = {
        threshold = 3,
        maxThreshold = 5,
        duration = 2,
        warningMessage = "Patience, young one. Rushing through our talk will not serve you well.",
        returnMessage = "I see you are in a hurry. I shall be more concise.",
        moodEffect = -8
    }
}

--[[ Event Listeners ]]
DialogueService.Listeners = {
    ["Data.Init"] = function(self, data)
        if not data or not data.userId then return end

        local userId = data.userId
        local playerData = data.data.PlayerData or data.data

        if playerData and playerData.dialogue then
            state.playerStates[userId] = {
                currentTree = nil,
                currentLine = nil,
                completedDialogues = playerData.dialogue.completedDialogues or {},
                interruptedDialogues = playerData.dialogue.interruptedDialogues or {}
            }
        else
            state.playerStates[userId] = {
                currentTree = nil,
                currentLine = nil,
                completedDialogues = {},
                interruptedDialogues = {}
            }
        end
    end,

    ["Dialogue.Progress"] = function(self, player, data)
        if not player or not data or not data.responseId then return end

        local userId = tostring(player.UserId)
        self:ProgressDialogue(userId, data.responseId)
    end,

    ["Dialogue.Diplomacy"] = function(self, player, data)
        if not player or not data then return end

        local userId = tostring(player.UserId)
        local conflictId = data.conflictId

        if not conflictId then
            return false, "No conflict specified"
        end

        local conflict = Services.Faction:GetConflict(conflictId)
        if not conflict then
            return false, "Conflict not found"
        end

        local playerState = state.playerStates[userId]
        if not playerState or not playerState.currentTree then
            return false, "No active dialogue"
        end

        local diplomaticOptions = Services.Faction:GetDiplomacy(player, conflict)

        Services.Event:FireTo(
            player,
            "Dialogue.Progress",
            {
                line = {
                    speaker = "Diplomat",
                    text = "How would you like to approach this diplomatic situation?",
                    diplomaticOptions = diplomaticOptions,
                    metadata = {
                        showDiplomaticOptions = true,
                        conflict = conflict
                    }
                }
            }
        )

        return true
    end
}

--[[ Helper Functions ]]
local function ParseQuests(questsAttribute)
    if type(questsAttribute) ~= "string" then
        return {}
    end

    local trimmed = questsAttribute:match("^%s*(.-)%s*$")
    if trimmed:sub(1, 1) == "[" then
        local HttpService = game:GetService("HttpService")
        local success, result = pcall(HttpService.JSONDecode, HttpService, trimmed)
        return (success and type(result) == "table") and result or {}
    end

    local questsTable = {}
    for quest in questsAttribute:gmatch("[^,]+") do
        table.insert(questsTable, quest:match("^%s*(.-)%s*$"))
    end
    return questsTable
end

local function CheckQuest(questId, availableQuests)
    if not questId or not availableQuests or #availableQuests == 0 then
        return false
    end

    local normalizedQuestId = questId:lower():gsub("_", " ")
    local shortQuestId = questId:match("[^_]+$") or questId
    local normalizedShortQuestId = shortQuestId:lower()

    for _, availableQuest in ipairs(availableQuests) do
        local normalizedAvailableQuest = availableQuest:lower():gsub("_", " ")

        if normalizedAvailableQuest == normalizedQuestId then
            return true
        end

        if normalizedAvailableQuest:find(normalizedQuestId, 1, true) or
           normalizedQuestId:find(normalizedAvailableQuest, 1, true) or
           normalizedAvailableQuest:find(normalizedShortQuestId, 1, true) then
            return true
        end
    end

    return false
end

local function FilterDialogue(responses, userId, npcInstance, context)
    if not responses or #responses == 0 then
        return {}
    end

    local player = context.player or game.Players:GetPlayerByUserId(tonumber(userId))
    local filteredResponses = {}

    for _, response in ipairs(responses) do
        local canShow = true
        local modifiedResponse = table.clone(response)

        if response.questIndicator then
            local questId = response.nextDialogueId and response.nextDialogueId:match("(.+)_quest")
            if questId then
                local npcAvailableQuests = npcInstance:GetAttribute("QUESTS")
                local questsTable = ParseQuests(npcAvailableQuests)

                if CheckQuest(questId, questsTable) then
                    local quest = Services.Quest:GetQuest(questId)
                    if quest then
                        local isActive = Services.Quest:CheckActive(userId, questId)
                        if isActive then
                            local shortName = questId:match("[^_]+$") or questId
                            shortName = shortName:lower()
                            if shortName:sub(-1) ~= "s" then
                                shortName = shortName .. "s"
                            end
                            local modifiedText = string.format("About the %s...", shortName)
                            modifiedResponse = {
                                text = modifiedText,
                                nextDialogueId = questId .. "_quest_reminder",
                                questIndicator = true,
                                commands = {}
                            }
                            canShow = true
                        else
                            canShow = Services.Quest:ValidateQuest(userId, questId)
                            if canShow then
                                modifiedResponse = table.clone(response)
                            end
                        end
                    else
                        canShow = false
                    end
                else
                    canShow = false
                end
            end
        end

        if canShow then
            if #(modifiedResponse.commands or {}) > 0 then
                modifiedResponse.text = Modules.Dialogue.ProcessCommands(
                    modifiedResponse.commands,
                    {
                        player = player,
                        services = Services,
                        character = npcInstance
                    }
                ) or modifiedResponse.text
            end
            table.insert(filteredResponses, modifiedResponse)
        end
    end

    return filteredResponses
end

local function FindSpeaker(speakerName, services)
    if not speakerName then return nil end

    local normalizedSpeakerName = speakerName:lower()
    local ObjectService = services.Object
    local candidates = {}

    for _, instance in workspace:GetDescendants() do
        if not ObjectService:GetID(instance) then continue end

        local name = instance:GetAttribute("NAME")
        if not name then continue end

        local instanceName = name:lower()

        local score = 0
        if instanceName == normalizedSpeakerName then
            return instance
        elseif instanceName:find(normalizedSpeakerName, 1, true) or
               normalizedSpeakerName:find(instanceName, 1, true) then
            score = 1
        end

        if score > 0 then
            table.insert(candidates, {instance = instance, score = score})
        end
    end

    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates[1] and candidates[1].instance
end

--[[ Core Functions ]]
function DialogueService:Init(services, modules)
    Services = services
    Modules = modules

    self:LoadDialogue()
    self:RegisterGenerators()
    return true
end

function DialogueService:Start()
    return true
end

--[[ Dialogue Tree Management ]]
function DialogueService:LoadDialogue()
    local dialoguesFolder = game:GetService("ReplicatedStorage").Modules.Data.Dialogue
    if not dialoguesFolder then
        warn("Dialogues folder not found")
        return
    end

    for _, module in pairs(dialoguesFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local success, dialogueData = pcall(require, module)
            if success then
                if type(dialogueData) == "function" then
                    dialogueData = dialogueData()
                end

                if type(dialogueData) == "table" then
                    for id, tree in pairs(dialogueData) do
                        local isValid, errorMsg = Modules.Dialogue.ValidateTree(tree)
                        if isValid then
                            state.dialogueTrees[id] = tree
                        else
                            warn("Failed to register dialogue", tostring(id), ":", tostring(errorMsg))
                        end
                    end
                else
                    warn("Invalid dialogue data from", module.Name, ":", tostring(dialogueData))
                end
            else
                warn("Failed to load dialogues from", module.Name, ":", tostring(dialogueData))
            end
        end
    end

    local totalDialogues = 0
    for _ in pairs(state.dialogueTrees) do
        totalDialogues += 1
    end
end

function DialogueService:RegisterGenerators(name: string?, generatorFunc: ((string) -> table)?)
    if name and generatorFunc then
        state.dialogueGenerators[name] = generatorFunc
        return
    end

    local dialoguesFolder = game:GetService("ReplicatedStorage").Modules.Data.Dialogue
    if not dialoguesFolder then
        warn("Dialogues folder not found")
        return
    end

    for _, module in pairs(dialoguesFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local success, dialogueGenerator = pcall(require, module)
            if success and type(dialogueGenerator) == "function" then
                local generatorName = module.Name:gsub("Dialogues$", ""):lower()
                state.dialogueGenerators[generatorName] = dialogueGenerator
            end
        end
    end
end

function DialogueService:RegisterTree(tree)
    local isValid, error = Modules.Dialogue.ValidateTree(tree)
    if not isValid then
        warn(string.format("Failed to register dialogue %s: %s", tree.id, error))
        return false
    end

    state.dialogueTrees[tree.id] = tree
    return true
end

function DialogueService:GetDialogueId(generatorName: string, npcName: string): string
    return string.format("%s_%s_dialogue", generatorName:lower(), npcName:lower():gsub("%s+", "_"))
end

function DialogueService:ValidateExistence(generatorName: string, npcName: string): string
    local dialogueId = self:GetDialogueId(generatorName, npcName)

    if not state.dialogueTrees[dialogueId] then
        local generator = state.dialogueGenerators[generatorName]
        if not generator then
            local upperNpcName = npcName:upper()

            local npcPerson
            for category, template in pairs(Modules.Person.Templates) do
                if category == upperNpcName then
                    npcPerson = template
                    generator = state.dialogueGenerators[category:lower()]
                    dialogueId = self:GetDialogueId(category:lower(), npcName)
                    break
                end

                if template.variants then
                    for variantKey, variant in pairs(template.variants) do
                        if variant.name and variant.name:upper() == upperNpcName then
                            npcPerson = variant
                            generator = state.dialogueGenerators[category:lower()]
                            dialogueId = self:GetDialogueId(category:lower(), npcName)
                            break
                        end

                        if variant.unique and variant.name and upperNpcName:find(variant.name:upper()) then
                            generator = state.dialogueGenerators[variantKey:lower()] or state.dialogueGenerators[category:lower()]
                            if generator then
                                dialogueId = self:GetDialogueId(variantKey:lower(), npcName)
                                break
                            end
                        end
                    end
                end
            end

            if not generator then
                for generatorKey, generatorFunc in pairs(state.dialogueGenerators) do
                    if string.find(generatorKey:upper(), upperNpcName) or
                       string.find(upperNpcName, generatorKey:upper()) then
                        generator = generatorFunc
                        dialogueId = self:GetDialogueId(generatorKey, npcName)
                        break
                    end
                end
            end

            if not generator then
                warn("No generator found for:", generatorName, "or NPC:", npcName)
                return dialogueId
            end
        end

        local tree = generator(npcName)
        if not tree then
            warn("Generator failed to create tree for:", npcName)
            return dialogueId
        end

        tree.id = dialogueId
        self:RegisterTree(tree)
    end

    return dialogueId
end

--[[ Dialogue Functions ]]
function DialogueService:StartDialogue(userId: string, dialogueId: string): (boolean, string?)
    local playerState = state.playerStates[userId]
    if playerState and playerState.currentTree then
        return false, "Already in dialogue"
    end

    local dialogueTree = state.dialogueTrees[dialogueId]
    if not dialogueTree then
        local generatorMatch = dialogueId:match("^([^_]+)_")
        local npcName = dialogueId:match("^[^_]+_(.+)_dialogue$")
        if generatorMatch and npcName then
            dialogueId = self:ValidateExistence(generatorMatch, npcName)
            dialogueTree = state.dialogueTrees[dialogueId]
        end

        if not dialogueTree and npcName then
            local npcInstance = FindSpeaker(npcName, Services)
            if npcInstance then
                local npcType = npcInstance:GetAttribute("TYPE")
                if npcType then
                    dialogueId = self:ValidateExistence(npcType:lower(), npcName)
                    dialogueTree = state.dialogueTrees[dialogueId]
                end

                if not dialogueTree then
                    for category, _ in pairs(Modules.Person.Templates) do
                        dialogueId = self:ValidateExistence(category:lower(), npcName)
                        dialogueTree = state.dialogueTrees[dialogueId]
                        if dialogueTree then
                            break
                        end
                    end
                end
            end
        end
    end

    if not dialogueTree then
        return false, "Dialogue not found: " .. dialogueId
    end

    if not dialogueTree.startingLine or not dialogueTree.lines[dialogueTree.startingLine] then
        return false, "Invalid dialogue starting point"
    end

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if not player then
        return false, "Player not found"
    end

    if not playerState then
        state.playerStates[userId] = {
            currentTree = nil,
            currentLine = nil,
            completedDialogues = {},
            interruptedDialogues = {}
        }
        playerState = state.playerStates[userId]
    end

    local startingLine = dialogueTree.startingLine
    local startingLineData = dialogueTree.lines[startingLine]
    if not startingLineData then
        return false, "Starting line not found"
    end

    local npcInstance = FindSpeaker(startingLineData.speaker, Services)
    local initialHealth = npcInstance and npcInstance:FindFirstChild("Humanoid") and
                         npcInstance:FindFirstChild("Humanoid").Health or 0

    if npcInstance and npcInstance:GetAttribute("CONTROLLER") and
        npcInstance:GetAttribute("CONTROLLER") ~= userId then
        return false, "NPC is already in a conversation"
    end

    if npcInstance then
        npcInstance:SetAttribute("CONTROLLER", userId)
    end

    playerState.currentTree = dialogueId
    playerState.currentLine = startingLine

    local emotionState = "NEUTRAL"
    if npcInstance then
        local npcId = Services.Object:GetID(npcInstance)
        if npcId then
            local relationship = Services.Memory:GetRelationship(player, npcId)
            if relationship and relationship.mood then
                emotionState = relationship.mood
            end
        end
    end

    local line = self:GetLine(userId, startingLine)
    if not line then
        return false, "Failed to process dialogue line"
    end

    Services.Event:FireTo(
        player,
        "Dialogue.Start",
        {
            dialogueId = dialogueTree.id,
            lineId = startingLine,
            line = line,
            emotion = emotionState
        }
    )

    playerState.dialogueMetadata = {
        lastInteractionTime = os.time(),
        lastProgressTime = os.time(),
        npcInstance = npcInstance,
        initialHealth = initialHealth
    }

    self:StartMonitoring(userId)
    return true
end

function DialogueService:EndDialogue(userId: string, interruptionType: string?, additionalContext: {[string]: any}?): (boolean, string?)
    local playerState = state.playerStates[userId]
    if not playerState or not playerState.currentTree then
        return false, "No active dialogue to end"
    end

    if playerState.monitoringConnection then
        playerState.monitoringConnection:Disconnect()
        playerState.monitoringConnection = nil
    end

    local dialogueTree = state.dialogueTrees[playerState.currentTree]
    local currentLineId = playerState.currentLine
    local currentLine = dialogueTree.lines[currentLineId]
    if not currentLine then
        return false, "Invalid dialogue state"
    end

    additionalContext = additionalContext or {}
    if playerState.dialogueMetadata then
        for k, v in pairs(playerState.dialogueMetadata) do
            additionalContext[k] = v
        end
    end

    local npcInstance = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance
    if not npcInstance then
        warn("Could not find NPC instance for speaker:", currentLine.speaker)
        npcInstance = FindSpeaker(currentLine.speaker, Services)
    end

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if not player then
        return false, "Player not found"
    end

    if interruptionType and self.InterruptionHandlers[interruptionType] then
        local shouldInterrupt, interruptContext = self.InterruptionHandlers[interruptionType](
            self,
            userId,
            additionalContext
        )

        if not shouldInterrupt then
            self:StartMonitoring(userId)
            return false, "Interruption condition not met"
        end

        for k, v in pairs(interruptContext) do
            additionalContext[k] = v
        end
    end

    playerState.interruptedDialogues = playerState.interruptedDialogues or {}

    playerState.interruptedDialogues[playerState.currentTree] = {
        lineId = currentLineId,
        type = interruptionType or DialogueService.InterruptionType.FORCED_CANCEL,
        timestamp = os.time(),
        context = additionalContext
    }

    local dialogueId = playerState.currentTree
    playerState.currentTree = nil
    playerState.currentLine = nil
    playerState.dialogueMetadata = nil

    Services.Event:FireTo(
        player,
        "Dialogue.End",
        {
            dialogueId = dialogueTree.id,
            interruptionType = interruptionType,
            wasInterrupted = true,
            context = additionalContext
        }
    )

    Services.Event:Fire(
        "Dialogue.End",
        {
            dialogueId = dialogueId,
            context = {
                instance = npcInstance,
                player = player,
                interruptionType = interruptionType,
                wasInterrupted = true,
                additionalContext = additionalContext
            }
        }
    )

    if npcInstance then
        npcInstance:SetAttribute("CONTROLLER", nil)
    end

    if interruptionType then
        self:ApplyMood(userId, interruptionType)
    end

    return true
end

function DialogueService:ProgressDialogue(userId: string, responseId: string, metadata: {[string]: any}?): (boolean, string?)
    local playerState = state.playerStates[userId]
    if not playerState or not playerState.currentTree then
        return false, "No active dialogue"
    end

    if playerState.dialogueMetadata then
        playerState.dialogueMetadata.lastInteractionTime = os.time()

        local shouldCheckRush = true
        if responseId == "My mind returns to your words" then
            shouldCheckRush = false
        end

        if shouldCheckRush then
            local shouldInterrupt, interruptContext = self.InterruptionHandlers[DialogueService.InterruptionType.PLAYER_RUSH](
                self,
                userId,
                playerState.dialogueMetadata
            )

            if shouldInterrupt then
                self:EndDialogue(userId, DialogueService.InterruptionType.PLAYER_RUSH, interruptContext)
                return false, "Dialogue interrupted due to rushing"
            end
        end
    end

    local warningState = state.warningStates[userId]
    if warningState and warningState.isWarning and warningState.activeInterruption == DialogueService.InterruptionType.TIMEOUT and responseId == "My mind returns to your words" then
        warningState.isWarning = false
        warningState.warningTime = nil
        warningState.activeInterruption = nil
        warningState.hasWarned = false

        if playerState.dialogueMetadata then
            playerState.dialogueMetadata.lastInteractionTime = os.time()
        end

        local player = game.Players:GetPlayerByUserId(tonumber(userId))
        if player then
            local npcInstance = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance
            local dialogueTree = state.dialogueTrees[playerState.currentTree]
            local currentLine = dialogueTree.lines[playerState.currentLine]

            local processedLine = table.clone(currentLine)

            local config = WarningConfig[DialogueService.InterruptionType.TIMEOUT]
            processedLine.text = config.returnMessage .. "\n\n" .. processedLine.text

            local filteredResponses = FilterDialogue(processedLine.responses, userId, npcInstance, {player = player})
            processedLine.responses = filteredResponses

            Services.Event:FireTo(
                player,
                "Dialogue.Progress",
                {
                    dialogueId = dialogueTree.id,
                    lineId = playerState.currentLine,
                    line = processedLine
                }
            )
        end

        return true
    end

    local dialogueTree = state.dialogueTrees[playerState.currentTree]
    local currentLine = dialogueTree.lines[playerState.currentLine]

    if not currentLine or not currentLine.responses then
        return false, "No responses available"
    end

    local selectedResponse
    for _, response in pairs(currentLine.responses) do
        if response.questIndicator then
            local questId = response.nextDialogueId and response.nextDialogueId:match("(.+)_quest")
            if questId then
                local quest = Services.Quest:GetQuest(questId)
                if quest then
                    local isActive = Services.Quest:CheckActive(userId, questId)
                    if isActive then
                        local shortName = questId:match("[^_]+$") or questId
                        shortName = shortName:lower()
                        if shortName:sub(-1) ~= "s" then
                            shortName = shortName .. "s"
                        end
                        local expectedText = string.format("About the %s...", shortName)
                        if responseId == expectedText then
                            selectedResponse = {
                                text = responseId,
                                nextDialogueId = questId .. "_quest_reminder",
                                questIndicator = true
                            }
                            break
                        end
                    end
                end
            end
        end

        if response.text == responseId then
            selectedResponse = response
            break
        end
    end

    if not selectedResponse then
        return false, "Invalid response"
    end

    if selectedResponse.requirements and
       not Modules.Dialogue.CheckRequirements(selectedResponse.requirements, playerState) then
        return false, "Requirements not met"
    end

    if selectedResponse.questIndicator then
        local questId = selectedResponse.nextDialogueId and selectedResponse.nextDialogueId:match("(.+)_quest")
        if questId then
            local quest = Services.Quest:GetQuest(questId)
            if quest then
                local isActive = Services.Quest:CheckActive(userId, questId)
                if not isActive then
                    if selectedResponse.nextDialogueId:match("_quest_accept$") then
                        local canAccept = Services.Quest:ValidateQuest(userId, questId)
                        if canAccept then
                            local success, error = Services.Quest:AcceptQuest(userId, questId)
                            if not success then
                                warn("Failed to accept quest:", error)
                                return false, error
                            end
                        end
                    end
                end
            end
        end
    end

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    local npcInstance = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance
    local npcId = npcInstance and Services.Object:GetID(npcInstance)

    local context = {
        player = player,
        services = Services,
        world = workspace,
        character = npcInstance,
        npcId = npcId
    }

    if selectedResponse.effects then
        Modules.Dialogue.ProcessEffects(selectedResponse.effects, context)
    end

    if selectedResponse.consequences then
        Modules.Dialogue.ProcessConsequences(selectedResponse.consequences, context)
    end

    if selectedResponse.reputation then
        for faction, value in pairs(selectedResponse.reputation) do
            local npcInstance = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance
            local npcId = npcInstance and Services.Object:GetID(npcInstance)

            if faction == "*" and npcId then
                Services.Memory:UpdateReputation(player, npcId, value)
            else
                Services.Memory:UpdateReputation(player, faction, value)
            end
        end
    end

    if selectedResponse.relationships then
        for npc, value in pairs(selectedResponse.relationships) do
            Services.Relationship:ModifyRelationship(player, npc, value)
        end
    end

    if selectedResponse.goToQuestBranch then
        local questId = selectedResponse.goToQuestBranch.questId
        local branchId = selectedResponse.goToQuestBranch.branchId
        if questId and branchId then
            local success, message = Services.Quest:SetBranch(player, questId, branchId)
            if not success then
                warn(string.format("Failed to set quest branch via dialogue: %s", message))
            else
                self:EndDialogue(userId)
                return true
            end
        end
    end

    local nextLineId = selectedResponse.nextDialogueId
    if selectedResponse.type == Modules.Dialogue.ResponseTypes.RETURN then
        nextLineId = selectedResponse.returnPoint
    elseif selectedResponse.type == Modules.Dialogue.ResponseTypes.EXIT then
        self:EndDialogue(userId)
        return true
    end

    if not nextLineId then
        self:EndDialogue(userId)
        return true
    end

    local nextLine = dialogueTree.lines[nextLineId]
    if not nextLine then
        return false, "Next line not found"
    end

    table.insert(state.dialogueHistory[userId], {
        treeId = playerState.currentTree,
        lineId = nextLineId,
        timestamp = os.time(),
        metadata = metadata
    })

    playerState.currentLine = nextLineId

    local player = game.Players:GetPlayerByUserId(tonumber(userId))

    if playerState.dialogueMetadata then
        playerState.dialogueMetadata.lastProgressTime = os.time()
    end

    local processedLine = table.clone(nextLine)
    processedLine.text = Modules.Dialogue.ProcessCommands(
        nextLine.commands,
        {
            player = player,
            services = Services,
            character = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance,
            currentLine = processedLine
        }
    ) or nextLine.text

    if processedLine.responses then
        for i, response in ipairs(processedLine.responses) do
            response.text = Modules.Dialogue.ProcessCommands(
                response.commands,
                {
                    player = player,
                    services = Services,
                    character = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance,
                    currentLine = processedLine
                }
            ) or response.text
        end

        local npcInstance = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance
        if npcInstance then
            processedLine.responses = FilterDialogue(processedLine.responses, userId, npcInstance, {player = player})
        end
    end

    local returnPoint = Modules.Dialogue.GetReturn(processedLine, dialogueTree)
    if returnPoint then
        processedLine.returnPoint = returnPoint
    end

    Services.Event:FireTo(
        player,
        "Dialogue.Progress",
        {
            dialogueId = dialogueTree.id,
            lineId = nextLineId,
            line = processedLine,
            metadata = metadata
        }
    )

    local selectedResponse
    for _, response in pairs(currentLine.responses) do
        if response.text == responseId or response.id == responseId then
            selectedResponse = response
            break
        end
    end

    if not selectedResponse then
        return false, "Response not found"
    end

    if selectedResponse.metadata and selectedResponse.metadata.emotionalImpact then
        if player and npcId then
            Services.Memory:UpdateEmotion(
                player,
                npcId,
                selectedResponse.metadata.emotionalImpact.type,
                selectedResponse.metadata.emotionalImpact.intensity or 1
            )
        end
    end

    if selectedResponse.metadata and selectedResponse.metadata.isApology then
        if player and npcId then
            local accepted, response = Services.Memory:ProcessApology(
                player,
                npcId,
                selectedResponse.metadata.offenseType or "GENERAL"
            )

            if selectedResponse.metadata.acceptedDialogueId and accepted then
                selectedResponse.nextDialogueId = selectedResponse.metadata.acceptedDialogueId
            elseif selectedResponse.metadata.rejectedDialogueId and not accepted then
                selectedResponse.nextDialogueId = selectedResponse.metadata.rejectedDialogueId
            end
        end
    end

    return true
end

function DialogueService:RemindDialogue(userId: string, questId: string): (boolean, string?)
    local playerState = state.playerStates[userId]
    if not playerState or not playerState.currentTree then
        return false, "No active dialogue"
    end

    local quest = Services.Quest:GetQuest(questId)
    local questState = Services.Quest:GetState(userId, questId)

    if not quest or not questState then
        return false, "Quest not found"
    end

    local branch = quest.branches[questState.branch]
    local reminderText = string.format("Reminder: %s\n%s", quest.name, branch.description)

    Services.Event:FireTo(
        game.Players:GetPlayerByUserId(tonumber(userId)),
        "Dialogue.Remind",
        {
            questId = questId,
            quest = quest,
            state = questState,
            reminderText = reminderText
        }
    )

    return true
end

--[[ Interruption Functions ]]
function DialogueService:WarnPlayer(userId: string, interruptType: string, context: any, exceeds: boolean, currentValue: number)
    local config = WarningConfig[interruptType]
    if not config then return false end

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if not player then return false end

    local npcInstance = context.npc
    if not npcInstance then return false end

    state.warningStates[userId] = state.warningStates[userId] or {
        isWarning = false,
        warningTime = nil,
        lastDialogue = nil,
        activeInterruption = nil,
        hasWarned = false
    }
    local warningState = state.warningStates[userId]

    if warningState.isWarning and warningState.activeInterruption ~= interruptType then
        return false
    end

    if warningState.hasWarned and exceeds then
        return true
    end

    if warningState.isWarning and not exceeds then
        warningState.isWarning = false
        warningState.warningTime = nil
        warningState.activeInterruption = nil
        warningState.hasWarned = false

        if warningState.lastDialogue then
            local playerState = state.playerStates[userId]
            local dialogueTree = playerState and playerState.currentTree and state.dialogueTrees[playerState.currentTree]
            local npcInstance = context.npc

            local returnMessage = self:GetMessage("return", interruptType, npcInstance)

            local processedLine = {
                speaker = npcInstance:GetAttribute("NAME"),
                text = returnMessage .. "\n\n" .. warningState.lastDialogue.text,
                commands = warningState.lastDialogue.commands,
                effects = warningState.lastDialogue.effects,
                animation = warningState.lastDialogue.animation,
                sound = warningState.lastDialogue.sound,
                emote = warningState.lastDialogue.emote
            }

            if warningState.lastDialogue.responses then
                local filteredResponses = FilterDialogue(warningState.lastDialogue.responses, userId, npcInstance, {player = player})
                processedLine.responses = filteredResponses
            else
                processedLine.responses = {}
            end

            Services.Event:FireTo(
                player,
                "Dialogue.Progress",
                {
                    line = processedLine
                }
            )
        end
        return false
    end

    if exceeds and not warningState.isWarning then
        if warningState.hasWarned then
            return true
        end

        warningState.isWarning = true
        warningState.warningTime = os.time()
        warningState.activeInterruption = interruptType
        warningState.hasWarned = true

        local playerState = state.playerStates[userId]
        if playerState and playerState.currentTree then
            local dialogueTree = state.dialogueTrees[playerState.currentTree]
            local currentLine = dialogueTree.lines[playerState.currentLine]
            warningState.lastDialogue = {
                text = currentLine.text,
                responses = currentLine.responses,
                commands = currentLine.commands,
                effects = currentLine.effects,
                animation = currentLine.animation,
                sound = currentLine.sound,
                emote = currentLine.emote
            }
        end

        task.wait(0.2)

        local responses = {}
        if interruptType == DialogueService.InterruptionType.TIMEOUT then
            table.insert(responses, {
                text = "My mind returns to your words",
                commands = {},
                special = "resume_dialogue"
            })
        end

        local warningMessage = self:GetMessage("warning", interruptType, npcInstance)

        Services.Event:FireTo(
            player,
            "Dialogue.Progress",
            {
                line = {
                    speaker = npcInstance:GetAttribute("NAME"),
                    text = warningMessage,
                    responses = responses,
                    commands = {},
                    effects = {}
                }
            }
        )
        return false
    end

    if warningState.isWarning and os.time() - warningState.warningTime >= config.duration then
        warningState.isWarning = false
        warningState.warningTime = nil
        warningState.lastDialogue = nil
        warningState.activeInterruption = nil
        return true
    end

    if config.maxThreshold and currentValue > config.maxThreshold then
        warningState.isWarning = false
        warningState.warningTime = nil
        warningState.lastDialogue = nil
        warningState.activeInterruption = nil
        return true
    end

    return false
end

DialogueService.InterruptionHandlers = {
    [DialogueService.InterruptionType.DISTANCE] = function(self, userId, context)
        local player = game.Players:GetPlayerByUserId(tonumber(userId))
        local playerChar = player and player.Character
        local npcChar = context.npc

        if not playerChar then return false end

        if not npcChar or not npcChar.Parent then
            local npcId = npcChar and Services.Object:GetID(npcChar)
            if npcId then
                for _, instance in workspace:GetDescendants() do
                    if Services.Object:GetID(instance) == npcId then
                        npcChar = instance
                        break
                    end
                end
            end

            if not npcChar or not npcChar.Parent then
                return true, {
                    reason = "NPC no longer exists",
                    distance = math.huge
                }
            end
        end

        if not playerChar.PrimaryPart then return false end

        if not npcChar.PrimaryPart then
            npcChar.PrimaryPart = npcChar:FindFirstChild("HumanoidRootPart")
                or npcChar:FindFirstChild("Torso")
                or npcChar:FindFirstChild("UpperTorso")
                or npcChar:FindFirstChildWhichIsA("BasePart")

            if not npcChar.PrimaryPart then
                return true, {
                    reason = "NPC has no valid root part",
                    distance = math.huge
                }
            end
        end

        local distance = (playerChar.PrimaryPart.Position - npcChar.PrimaryPart.Position).Magnitude
        local config = WarningConfig[DialogueService.InterruptionType.DISTANCE]
        local exceeds = distance > config.threshold

        if self:WarnPlayer(userId, DialogueService.InterruptionType.DISTANCE, context, exceeds, distance) then
            return true, {
                distance = distance,
                maxDistance = config.maxThreshold,
                reason = "Distance exceeded"
            }
        end

        return false
    end,

    [DialogueService.InterruptionType.COMBAT] = function(self, userId, context)
        local player = game.Players:GetPlayerByUserId(tonumber(userId))
        local playerChar = player and player.Character
        if not playerChar then return false end

        local humanoid = playerChar:FindFirstChild("Humanoid")
        if not humanoid then return false end

        local initialHealth = context.initialHealth or humanoid.Health
        local currentHealth = humanoid.Health
        local healthLost = initialHealth - currentHealth
        local config = WarningConfig[DialogueService.InterruptionType.COMBAT]

        if self:WarnPlayer(userId, DialogueService.InterruptionType.COMBAT, context, healthLost > 0, healthLost) then
            return true, {
                currentHealth = currentHealth,
                initialHealth = initialHealth,
                healthLost = healthLost,
                reason = "Health decreased"
            }
        end

        return false
    end,

    [DialogueService.InterruptionType.TIMEOUT] = function(self, userId, context)
        if not context.startTime then return false end

        local currentTime = os.time()
        local inactiveDuration = currentTime - context.lastInteractionTime
        local config = WarningConfig[DialogueService.InterruptionType.TIMEOUT]

        local timeSinceStart = currentTime - context.startTime
        local MIN_DIALOGUE_TIME = 10

        if timeSinceStart < MIN_DIALOGUE_TIME then
            return false
        end

        local playerState = state.playerStates[userId]
        if playerState and playerState.dialogueMetadata then
            local lastProgressTime = playerState.dialogueMetadata.lastProgressTime
            if lastProgressTime and (currentTime - lastProgressTime) < MIN_DIALOGUE_TIME then
                return false
            end
        end

        if self:WarnPlayer(userId, DialogueService.InterruptionType.TIMEOUT, context, inactiveDuration > config.threshold, inactiveDuration) then
            return true, {
                inactiveDuration = inactiveDuration,
                maxInactiveDuration = config.maxThreshold,
                reason = "Inactivity timeout"
            }
        end

        return false
    end,

    [DialogueService.InterruptionType.PLAYER_INTERRUPT] = function(self, userId, context)
        local player = game.Players:GetPlayerByUserId(tonumber(userId))
        if not player then return false end

        local playerState = state.playerStates[userId]
        if not playerState or not playerState.currentTree then return false end

        local dialogueTree = state.dialogueTrees[playerState.currentTree]
        local currentLine = dialogueTree.lines[playerState.currentLine]

        if not currentLine or not currentLine.interruptible then return false end

        if self:WarnPlayer(userId, DialogueService.InterruptionType.PLAYER_INTERRUPT, context, true, 1) then
            return true, {
                reason = "Player interrupted dialogue",
                originalLine = currentLine.text,
                shortenedResponse = currentLine.interruptResponse or "Fine, I'll be brief."
            }
        end

        return false
    end,

    [DialogueService.InterruptionType.PLAYER_RUSH] = function(self, userId, context)
        local player = game.Players:GetPlayerByUserId(tonumber(userId))
        if not player then return false end

        local playerState = state.playerStates[userId]
        if not playerState or not playerState.dialogueMetadata then return false end

        local quickResponses = playerState.dialogueMetadata.quickResponses or 0
        local timeBetweenResponses = os.time() - (playerState.dialogueMetadata.lastResponseTime or 0)

        if timeBetweenResponses < 2 then
            quickResponses = quickResponses + 1
        else
            quickResponses = math.max(0, quickResponses - 1)
        end

        playerState.dialogueMetadata.quickResponses = quickResponses
        playerState.dialogueMetadata.lastResponseTime = os.time()

        local config = WarningConfig[DialogueService.InterruptionType.PLAYER_RUSH]
        if self:WarnPlayer(userId, DialogueService.InterruptionType.PLAYER_RUSH, context, quickResponses >= config.threshold, quickResponses) then
            return true, {
                reason = "Player rushing through dialogue",
                quickResponses = quickResponses,
                threshold = config.threshold
            }
        end

        return false
    end
}

function DialogueService:StartMonitoring(userId: string)
    local playerState = state.playerStates[userId]
    if not playerState or not playerState.currentTree then return end

    if playerState.monitoringConnection then
        playerState.monitoringConnection:Disconnect()
        playerState.monitoringConnection = nil
    end

    local CHECK_INTERVAL = 0.5
    local WARNING_COOLDOWN = 1

    local isChecking = false
    local lastCheckTime = os.clock()
    local lastWarningTime = os.clock()
    local RunService = game:GetService("RunService")

    playerState.monitoringConnection = RunService.Heartbeat:Connect(function()
        if not playerState.currentTree then
            if playerState.monitoringConnection then
                playerState.monitoringConnection:Disconnect()
                playerState.monitoringConnection = nil
            end
            return
        end

        local currentTime = os.clock()
        if currentTime - lastCheckTime < CHECK_INTERVAL then return end
        lastCheckTime = currentTime

        if isChecking then return end
        isChecking = true

        local metadata = playerState.dialogueMetadata or {}
        local context = {
            npc = metadata.npcInstance,
            startTime = metadata.startTime or os.time(),
            lastInteractionTime = metadata.lastInteractionTime or os.time(),
            initialHealth = metadata.initialHealth
        }

        if not context.npc then
            self:EndDialogue(userId, DialogueService.InterruptionType.FORCED_CANCEL)
            isChecking = false
            return
        end

        local warningState = state.warningStates[userId]
        if warningState and warningState.isWarning then
            local config = WarningConfig[warningState.activeInterruption]
            if config and os.time() - warningState.warningTime < config.duration then
                isChecking = false
                return
            end
        end

        if currentTime - lastWarningTime >= WARNING_COOLDOWN then
            for interruptType, handler in pairs(self.InterruptionHandlers) do
                if interruptType == DialogueService.InterruptionType.FORCED_CANCEL then
                    continue
                end

                local shouldInterrupt, interruptContext = handler(self, userId, context)

                if shouldInterrupt then
                    if not warningState or not warningState.isWarning then
                        if playerState.monitoringConnection then
                            playerState.monitoringConnection:Disconnect()
                            playerState.monitoringConnection = nil
                        end

                        local player = game.Players:GetPlayerByUserId(tonumber(userId))
                        if player then
                            Services.Event:FireTo(player, "Client.Dialogue.Cleanup", {})
                        end

                        task.wait(0.1)
                        self:EndDialogue(userId, interruptType, interruptContext)
                        isChecking = false
                        return
                    end
                elseif warningState and warningState.isWarning then
                    lastWarningTime = currentTime
                end
            end
        end

        isChecking = false
    end)
end

--[[ Mood Functions ]]
function DialogueService:ApplyMood(userId: string, interruptionType: string)
    local playerState = state.playerStates[userId]
    if not playerState or not playerState.dialogueMetadata then return end

    local npcInstance = playerState.dialogueMetadata.npcInstance
    if not npcInstance then return end

    local npcId = Services.Object:GetID(npcInstance)
    if not npcId then return end

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if not player then return end

    local emotionType, intensity = "NEUTRAL", 0

    if interruptionType == DialogueService.InterruptionType.FORCED_CANCEL then
        emotionType, intensity = "DISAPPOINTMENT", 0.5
    elseif interruptionType == DialogueService.InterruptionType.PLAYER_INTERRUPT then
        emotionType, intensity = "ANNOYANCE", 0.3
    elseif interruptionType == DialogueService.InterruptionType.COMBAT then
        emotionType, intensity = "ANGER", 1.0
    elseif interruptionType == DialogueService.InterruptionType.DISTANCE then
        emotionType, intensity = "DISAPPOINTMENT", 0.3
    end

    Services.Memory:UpdateEmotion(player, npcId, emotionType, intensity)
end

--[[ Getter Functions ]]
function DialogueService:GetLine(userId: string, lineId: string)
    local playerState = state.playerStates[userId]
    if not playerState or not playerState.currentTree then
        return nil
    end

    local dialogueTree = state.dialogueTrees[playerState.currentTree]
    if not dialogueTree or not dialogueTree.lines[lineId] then
        return nil
    end

    local player = game.Players:GetPlayerByUserId(tonumber(userId))
    if not player then
        return nil
    end

    local npcInstance = playerState.dialogueMetadata and playerState.dialogueMetadata.npcInstance
    if not npcInstance then
        npcInstance = FindSpeaker(dialogueTree.lines[lineId].speaker, Services)
    end

    local emotionState = "NEUTRAL"
    local relationship = nil
    local reputationLevel = nil
    if npcInstance then
        local npcId = Services.Object:GetID(npcInstance)
        if npcId then
            relationship = Services.Memory:GetRelationship(player, npcId)
            if relationship and relationship.mood then
                emotionState = relationship.mood
            end

            reputationLevel = Services.Memory:GetReputation(player, npcId)
        end
    end

    local processedLine = table.clone(dialogueTree.lines[lineId])

    processedLine.emotion = emotionState
    processedLine.reputationLevel = reputationLevel

    if not lineId:find("_response_") and npcInstance then
        local npcId = Services.Object:GetID(npcInstance)
        if npcId and (processedLine.text:find("Hello") or processedLine.text:find("Greetings")) then
            local customGreeting = Services.Memory:GetGreeting(player, npcId)
            if customGreeting then
                processedLine.text = customGreeting
            end
        end
    end

    if processedLine.responses and relationship then
        local filteredResponses = {}
        local npcId = Services.Object:GetID(npcInstance)

        for _, response in ipairs(processedLine.responses) do
            local include = true

            if response.requirements and response.requirements.relationship then
                local reqRelationship = response.requirements.relationship

                if reqRelationship.minTrust and relationship.trust < reqRelationship.minTrust then
                    include = false
                end

                if reqRelationship.mood and relationship.mood ~= reqRelationship.mood then
                    include = false
                end
            end

            if response.requirements and response.requirements.reputation then
                local reqReputation = response.requirements.reputation

                if reqReputation.minValue and relationship.reputation < reqReputation.minValue then
                    include = false
                end

                if reqReputation.level and reputationLevel ~= reqReputation.level then
                    include = false
                end
            end

            if include then
                local modifiedResponse = table.clone(response)
                modifiedResponse.metadata = modifiedResponse.metadata or {}
                modifiedResponse.metadata.relationshipContext = {
                    trust = relationship.trust,
                    mood = relationship.mood,
                    reputation = relationship.reputation,
                    reputationLevel = reputationLevel
                }

                if modifiedResponse.metadata.isApology and npcId then
                    modifiedResponse.metadata.apologyProcessor = function()
                        return Services.Memory:ProcessApology(player, npcId, modifiedResponse.metadata.offenseType or "GENERAL")
                    end
                end

                table.insert(filteredResponses, modifiedResponse)
            end
        end

        processedLine.responses = filteredResponses
    end

    processedLine.text = Modules.Dialogue.ProcessCommands(
        processedLine.commands,
        {
            player = player,
            services = Services,
            character = npcInstance
        }
    ) or processedLine.text

    return processedLine
end

function DialogueService:GetMessage(messageType: string, interruptType: string, npcInstance: Instance): string
    local fallbackMessages = {
        warning = "Our conversation is interrupted.",
        ["return"] = "Let us continue our discussion."
    }

    local fallbackMessage = "Let us continue."

    local config = WarningConfig[interruptType]
    if not config then
        return fallbackMessages[messageType] or fallbackMessage
    end

    local messageKey = messageType .. "Message"

    local defaultMessage = config[messageKey]
    if not defaultMessage then
        return fallbackMessages[messageType] or fallbackMessage
    end

    if npcInstance then
        local personType = npcInstance:GetAttribute("TYPE")
        local personVariant = npcInstance:GetAttribute("VARIANT")

        if personType then
            local messages = Modules.Person.GetDialogue(personType, personVariant, messageType, interruptType:lower())

            if messages and #messages > 0 then
                return messages[math.random(#messages)]
            end
        end
    end

    return defaultMessage
end

function DialogueService:GetHistory(userId: string, limit: number?): {[number]: {
    treeId: string,
    lineId: string,
    timestamp: number,
    metadata: {[string]: any}?
}}
    local history = state.dialogueHistory[userId] or {}
    if limit then
        local limitedHistory = {}
        for i = math.max(1, #history - limit + 1), #history do
            table.insert(limitedHistory, history[i])
        end
        return limitedHistory
    end
    return history
end

return DialogueService