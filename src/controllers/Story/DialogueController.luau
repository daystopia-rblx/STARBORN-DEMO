--[[ DialogueController
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local DialogueController = {}

DialogueController.Dependencies = {
    "Event"
}

--[[ State ]]
local Controllers
local Modules
local State = {
    isOpen = false,
    isTyping = false,
    typewriterConnection = nil,
    container = nil,
    activeScreen = nil,
    currentDialogue = nil,
    currentLine = nil,
    currentResponses = nil,
    currentEmotion = nil,
    diplomaticOptions = nil,
    attentionScore = 0,
    skipCount = 0,
    ui = {
        dialogueFrame = nil,
        textLabel = nil,
        speakerLabel = nil,
        responseContainer = nil,
        responseFrame = nil,
        emotionIndicator = nil,
        emotionIcon = nil,
        responses = {}
    }
}

--[[ Utilities ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = {
    Controller = require(ReplicatedStorage.Modules.Utility.Controller),
    Input = require(ReplicatedStorage.Modules.Utility.Input),
    Scale = require(ReplicatedStorage.Modules.Utility.Scale),
    Sound = require(ReplicatedStorage.Modules.Utility.Sound),
    Style = require(ReplicatedStorage.Modules.Utility.Style),
    Component = require(ReplicatedStorage.Modules.Utility.Component),
    Animation = require(ReplicatedStorage.Modules.Utility.Animation)
}

local Tools = {
    Shake = require(ReplicatedStorage.Modules.Tool.Shake)
}

--[[ Mood Config ]]
DialogueController.EmotionConfig = {
    BETRAYED = {
        color = Color3.fromRGB(139, 0, 0),
        icon = "rbxassetid://6072809086",
        animations = {"ANGRY", "THREATENING"},
        soundType = "hostile"
    },
    DISTRUSTFUL = {
        color = Color3.fromRGB(255, 140, 0),
        icon = "rbxassetid://6072809776",
        animations = {"SUSPICIOUS", "GUARDED"},
        soundType = "suspicious"
    },
    NEUTRAL = {
        color = Color3.fromRGB(180, 180, 180),
        icon = "rbxassetid://6072809542",
        animations = {"NEUTRAL", "IDLE"},
        soundType = "neutral"
    },
    FRIENDLY = {
        color = Color3.fromRGB(80, 200, 120),
        icon = "rbxassetid://6072809347",
        animations = {"FRIENDLY", "WELCOMING"},
        soundType = "friendly"
    },
    DEVOTED = {
        color = Color3.fromRGB(80, 150, 255),
        icon = "rbxassetid://6072809915",
        animations = {"HAPPY", "EXCITED"},
        soundType = "trusted"
    }
}

--[[ Listeners ]]
DialogueController.Listeners = {
    ["Dialogue.Start"] = function(self, data)
        if not State.container then self:CreateDialogue() end
        State.isOpen = true
        State.currentDialogue = data.dialogueId
        State.currentLine = data.line
        State.currentResponses = data.line.responses
        State.currentEmotion = data.emotion or "NEUTRAL"

        if data.diplomaticOptions then
            State.diplomaticOptions = data.diplomaticOptions
        end

        if data.line.metadata and data.line.metadata.showDiplomaticOptions then
            self:ShowDiplomacy(data.line.metadata.conflict)
        end

        Utility.Controller.Update({
            instance = State.container,
            properties = {Position = UDim2.new(0.5, 0, 1, -120), BackgroundTransparency = 0},
            duration = 0.3,
            easingStyle = Enum.EasingStyle.Back
        })
        Utility.Controller.Update({instance = State.ui.speakerLabel, properties = {TextTransparency = 0}, duration = 0.2})
        Utility.Controller.Update({instance = State.ui.textLabel, properties = {TextTransparency = 0}, duration = 0.2})

        if State.ui.emotionIndicator then
            self:UpdateEmotion(State.currentEmotion)
        end

        if data.line.animation then
            self:PlayAnimation(data.line.speaker, data.line.animation)
        end

        State.ui.speakerLabel.Text = self:FormatName(data.line.speaker)
        if data.line.interruptible then
            self:AddInterrupt()
        end
        self:TypewriterEffect(data.line.text, State.ui.textLabel, data.line.commands, data.line.effects)
    end,

    ["Dialogue.Progress"] = function(self, data)
        State.currentLine = data.line
        State.currentResponses = data.line.responses
        State.currentEmotion = data.emotion or State.currentEmotion
        State.ui.speakerLabel.Text = self:FormatName(data.line.speaker)

        if data.line.metadata and data.line.metadata.showDiplomaticOptions then
            self:ShowDiplomacy(data.line.metadata.conflict)
        end

        if data.emotion and State.ui.emotionIndicator then
            self:UpdateEmotion(data.emotion)
        end

        if data.line.animation then
            self:PlayAnimation(data.line.speaker, data.line.animation)
        end

        for _, response in ipairs(State.ui.responses) do
            Utility.Controller.Update({
                instance = response,
                properties = {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                },
                duration = 0.15
            })
        end
        task.wait(0.15)
        for _, response in ipairs(State.ui.responses) do
            response:Destroy()
        end
        State.ui.responses = {}

        Utility.Controller.Update({
            instance = State.ui.responseFrame,
            properties = {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 330, 0, 0)
            },
            duration = 0.2
        })

        if data.line.interruptible then
            self:AddInterrupt()
        end

        self:TypewriterEffect(data.line.text, State.ui.textLabel, data.line.commands, data.line.effects)
    end,

    ["Dialogue.Cleanup"] = function(self)
        if State.currentCleanup then
            State.currentCleanup()
            State.currentCleanup = nil
        end
    end,

    ["Dialogue.End"] = function(self, data)
        State.isTyping = false
        State.isOpen = false
        State.currentDialogue = nil
        State.currentLine = nil
        State.diplomaticOptions = nil
        State.attentionScore = 0

        if State.currentCleanup then
            State.currentCleanup()
            State.currentCleanup = nil
        end

        for _, button in ipairs(State.ui.responses) do
            Utility.Controller.Update({
                instance = button,
                properties = {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                },
                duration = 0.2
            })
        end

        Utility.Controller.Update({
            instance = State.ui.responseFrame,
            properties = {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 330, 0, 0)
            },
            duration = 0.3
        })

        Utility.Controller.Update({
            instance = State.container,
            properties = {Position = UDim2.new(0.5, 0, 1, 20), BackgroundTransparency = 1},
            duration = 0.3,
            easingStyle = Enum.EasingStyle.Back
        })
        Utility.Controller.Update({instance = State.ui.speakerLabel, properties = {TextTransparency = 1}, duration = 0.2})
        Utility.Controller.Update({instance = State.ui.textLabel, properties = {TextTransparency = 1}, duration = 0.2})

        task.wait(0.3)
        for _, response in ipairs(State.ui.responses) do response:Destroy() end
        State.ui.responses = {}
    end
}

--[[ Core Functions ]]
function DialogueController:Init(controllers, modules)
    Controllers = controllers
    Modules = modules
    return true
end

--[[ Utility Functions ]]
function DialogueController:FormatName(name)
    return string.gsub(name, "(%a)([%w_']*)", function(first, rest)
        return string.upper(first) .. rest
    end)
end

function DialogueController:PlayAnimation(speakerName, animationType)
    local character = workspace:FindFirstChild(speakerName)
    if not character or not animationType then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local emotion = self:GetEmotion(State.currentEmotion)
    local animations = emotion and emotion.animations or {"NEUTRAL", "IDLE"}

    local animationToPlay = animationType

    if animationType == "AUTO" and animations then
        animationToPlay = animations[math.random(#animations)]
    end

    local category, name = "EMOTION", "NEUTRAL"

    if animationToPlay:find("_") then
        category, name = animationToPlay:match("([^_]+)_(.+)")
    else
        name = animationToPlay
    end

    if not State.characterAnimations then
        State.characterAnimations = {}
    end

    if not State.characterAnimations[speakerName] then
        local npcType = character:GetAttribute("TYPE") or "NPC"
        local categories = {"EMOTION", "DIALOGUE", npcType}

        State.characterAnimations[speakerName] = Utility.Animation.Categories(animator, categories)
    end

    Utility.Animation.Play(
        State.characterAnimations[speakerName],
        category,
        name,
        0.3,
        1.0
    )
end

--[[ Mood Functions ]]
function DialogueController:GetEmotion(emotion)
    emotion = string.upper(emotion or "NEUTRAL")
    return self.EmotionConfig[emotion] or self.EmotionConfig.NEUTRAL
end

function DialogueController:UpdateEmotion(emotion)
    if not State.ui.emotionIndicator then return end

    local emotionConfig = self:GetEmotion(emotion)
    State.currentEmotion = string.upper(emotion)

    State.ui.emotionIndicator.Text = string.upper(string.sub(emotion, 1, 1)) .. string.lower(string.sub(emotion, 2))
    State.ui.emotionIndicator.TextColor3 = emotionConfig.color

    if State.ui.emotionIcon then
        State.ui.emotionIcon.Image = emotionConfig.icon

        Utility.Controller.Update({
            instance = State.ui.emotionIcon,
            properties = {
                ImageTransparency = 1,
                Rotation = -15
            },
            duration = 0.1
        })

        task.wait(0.1)

        Utility.Controller.Update({
            instance = State.ui.emotionIcon,
            properties = {
                ImageTransparency = 0,
                Rotation = 0
            },
            duration = 0.2,
            easingStyle = Enum.EasingStyle.Back
        })
    end

    if emotionConfig.soundType then
        Utility.Sound.Dialogue(emotionConfig.soundType)
    end
end

function DialogueController:GetResponse(emotion, isHovered)
    local emotionConfig = self:GetEmotion(emotion)
    local baseColor = Color3.fromRGB(35, 35, 45)
    local textColor = emotionConfig.color

    if isHovered then
        return {
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
            TextColor3 = textColor:Lerp(Color3.new(1, 1, 1), 0.3)
        }
    else
        return {
            BackgroundColor3 = baseColor,
            TextColor3 = textColor:Lerp(Color3.new(0.8, 0.8, 0.8), 0.7)
        }
    end
end

--[[ Interface Functions ]]
function DialogueController:CreateDialogue()
    if State.activeScreen then State.activeScreen:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DialogueGui"
    screenGui.Parent = game.Players.LocalPlayer.PlayerGui
    State.activeScreen = screenGui

    local dialogueFrame = Utility.Component.CreateFrame({
        Name = "DialogueFrame",
        Size = UDim2.new(0, 800, 0, 200),
        Position = UDim2.new(0.5, 0, 1, 20),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        cornerRadius = 12,
        Parent = screenGui
    })
    State.container = dialogueFrame

    local speakerLabel = Utility.Component.CreateLabel({
        Name = "SpeakerLabel",
        Size = UDim2.new(1, -150, 0, 30),
        Position = UDim2.new(0, 20, 0, 10),
        Text = "",
        TextSize = 26,
        RichText = true,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = dialogueFrame
    })
    State.ui.speakerLabel = speakerLabel

    local emotionIndicator = Utility.Component.CreateLabel({
        Name = "EmotionIndicator",
        Size = UDim2.new(0, 100, 0, 30),
        Position = UDim2.new(1, -130, 0, 10),
        Text = "Neutral",
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Parent = dialogueFrame
    })
    State.ui.emotionIndicator = emotionIndicator

    local emotionIcon = Utility.Component.CreateImage({
        Name = "EmotionIcon",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -30, 0, 13),
        Image = self.EmotionConfig.NEUTRAL.icon,
        BackgroundTransparency = 1,
        Parent = dialogueFrame
    })
    State.ui.emotionIcon = emotionIcon

    local textLabel = Utility.Component.CreateLabel({
        Name = "TextLabel",
        Size = UDim2.new(1, -40, 0, 140),
        Position = UDim2.new(0, 20, 0, 50),
        Text = "",
        TextSize = 22,
        RichText = true,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Parent = dialogueFrame
    })
    State.ui.textLabel = textLabel

    local responseFrame = Utility.Component.CreateFrame({
        Name = "ResponseFrame",
        Size = UDim2.new(0, 330, 0, 0),
        Position = UDim2.new(1, 20, 0, 0),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        cornerRadius = 12,
        BackgroundTransparency = 1,
        Parent = dialogueFrame
    })

    local responseContainer = Utility.Component.CreateFrame({
        Name = "ResponseContainer",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Parent = responseFrame
    })
    State.ui.responseContainer = responseContainer
    State.ui.responseFrame = responseFrame

    local categoryContainer = Utility.Component.CreateFrame({
        Name = "CategoryContainer",
        Size = UDim2.new(0, 330, 0, 0),
        Position = UDim2.new(1, 20, 0, 0),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        cornerRadius = 12,
        BackgroundTransparency = 1,
        Parent = dialogueFrame
    })
    State.ui.categoryContainer = categoryContainer

    dialogueFrame.BackgroundTransparency = 1
    speakerLabel.TextTransparency = 1
    textLabel.TextTransparency = 1
    emotionIndicator.TextTransparency = 1
    emotionIcon.ImageTransparency = 1

    return dialogueFrame
end

function DialogueController:ShowResponses(responses)
    State.ui.responseContainer:ClearAllChildren()
    State.ui.responses = {}

    if State.ui.categoryContainer then
        State.ui.categoryContainer:ClearAllChildren()
    end

    State.ui.responseFrame.Size = UDim2.new(0, 330, 0, 0)
    State.ui.responseFrame.BackgroundTransparency = 1

    if not responses or #responses == 0 then return end

    local categorizedResponses = Modules.Dialogue.GetResponsesByCategory(responses, State.currentDialogue)
    local totalHeight = 0
    local categorySpacing = 10
    local responseSpacing = 5

    for categoryId, category in pairs(categorizedResponses) do
        local categoryFrame = Utility.Component.CreateFrame({
            Name = "Category_" .. categoryId,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, totalHeight),
            BackgroundTransparency = 1,
            Parent = State.ui.responseContainer
        })

        -- Category Header
        if categoryId ~= "UNCATEGORIZED" then
            local headerFrame = Utility.Component.CreateFrame({
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 30),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = category.color:Lerp(Color3.new(0, 0, 0), 0.7),
                cornerRadius = 8,
                Parent = categoryFrame
            })

            local headerLabel = Utility.Component.CreateLabel({
                Name = "HeaderLabel",
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                Text = category.name,
                TextSize = 18,
                Font = Enum.Font.GothamBold,
                TextColor3 = category.color,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Parent = headerFrame
            })

            if category.icon then
                local iconImage = Utility.Component.CreateImage({
                    Name = "Icon",
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(0, 8, 0.5, -10),
                    Image = category.icon,
                    BackgroundTransparency = 1,
                    ImageColor3 = category.color,
                    Parent = headerFrame
                })
            end

            totalHeight = totalHeight + 35
        end

        -- Responses
        local responseHeight = 0
        for i, response in ipairs(category.responses) do
            local responseStyle = self:GetResponse(State.currentEmotion, false)
            local button = Utility.Component.CreateButton({
                Name = "ResponseButton_" .. i,
                Size = UDim2.new(1, 0, 0, 40),
                Position = UDim2.new(0, 0, 0, responseHeight + (categoryId ~= "UNCATEGORIZED" and 35 or 0)),
                Text = response.text,
                TextSize = 22,
                RichText = true,
                Font = Enum.Font.GothamBold,
                BackgroundColor3 = responseStyle.BackgroundColor3,
                TextColor3 = category.color or responseStyle.TextColor3,
                cornerRadius = 8,
                Parent = categoryFrame,
                BackgroundTransparency = 1,
                TextTransparency = 1
            })

            local moodBorder = Instance.new("Frame")
            moodBorder.Name = "MoodBorder"
            moodBorder.Size = UDim2.new(0, 3, 1, -6)
            moodBorder.Position = UDim2.new(0, 0, 0, 3)
            moodBorder.BackgroundColor3 = category.color or self:GetEmotion(State.currentEmotion).color
            moodBorder.BorderSizePixel = 0
            moodBorder.BackgroundTransparency = 1
            moodBorder.Parent = button

            button.MouseButton1Click:Connect(function()
                if not button.Visible or
                   button.BackgroundTransparency > 0 or
                   button.TextTransparency > 0 or
                   State.isTyping then
                    return
                end

                for _, btn in ipairs(State.ui.responses) do
                    btn.AutoButtonColor = false
                    btn.Active = false
                end

                State.isTyping = false
                if State.currentCleanup then
                    State.currentCleanup()
                    State.currentCleanup = nil
                end
                if State.typewriterConnection then
                    State.typewriterConnection:Disconnect()
                    State.typewriterConnection = nil
                end

                for _, btn in ipairs(State.ui.responses) do
                    Utility.Controller.Update({
                        instance = btn,
                        properties = {
                            BackgroundTransparency = 1,
                            TextTransparency = 1
                        },
                        duration = 0.15
                    })

                    local btnBorder = btn:FindFirstChild("MoodBorder")
                    if btnBorder then
                        Utility.Controller.Update({
                            instance = btnBorder,
                            properties = { BackgroundTransparency = 1 },
                            duration = 0.15
                        })
                    end
                end

                task.wait(0.15)

                Utility.Controller.Update({
                    instance = State.ui.responseFrame,
                    properties = {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 330, 0, 0)
                    },
                    duration = 0.2
                })

                State.ui.textLabel.Text = ""
                State.currentLine = nil

                task.wait(0.2)
                Controllers.Event:FireServer("Dialogue.Progress", {
                    responseId = response.text,
                    metadata = response.metadata
                })
            end)

            button.MouseEnter:Connect(function()
                local hoverStyle = self:GetResponse(State.currentEmotion, true)
                Utility.Controller.Update({
                    instance = button,
                    properties = {
                        BackgroundColor3 = hoverStyle.BackgroundColor3,
                        TextColor3 = category.color or hoverStyle.TextColor3
                    },
                    duration = 0.1
                })

                local border = button:FindFirstChild("MoodBorder")
                if border then
                    Utility.Controller.Update({
                        instance = border,
                        properties = { Size = UDim2.new(0, 4, 1, -4) },
                        duration = 0.1
                    })
                end
            end)

            button.MouseLeave:Connect(function()
                local normalStyle = self:GetResponse(State.currentEmotion, false)
                Utility.Controller.Update({
                    instance = button,
                    properties = {
                        BackgroundColor3 = normalStyle.BackgroundColor3,
                        TextColor3 = category.color or normalStyle.TextColor3
                    },
                    duration = 0.1
                })

                local border = button:FindFirstChild("MoodBorder")
                if border then
                    Utility.Controller.Update({
                        instance = border,
                        properties = { Size = UDim2.new(0, 3, 1, -6) },
                        duration = 0.1
                    })
                end
            end)

            table.insert(State.ui.responses, button)
            responseHeight = responseHeight + 45
        end

        categoryFrame.Size = UDim2.new(1, 0, 0, responseHeight + (categoryId ~= "UNCATEGORIZED" and 35 or 0))
        totalHeight = totalHeight + responseHeight + categorySpacing
    end

    task.wait(0.1)
    State.ui.responseFrame.Size = UDim2.new(0, 330, 0, totalHeight)

    Utility.Controller.Update({
        instance = State.ui.responseFrame,
        properties = {BackgroundTransparency = 0},
        duration = 0.2
    })

    task.wait(0.2)
    for _, button in ipairs(State.ui.responses) do
        Utility.Controller.Update({
            instance = button,
            properties = {
                BackgroundTransparency = 0,
                TextTransparency = 0
            },
            duration = 0.15
        })

        local border = button:FindFirstChild("MoodBorder")
        if border then
            Utility.Controller.Update({
                instance = border,
                properties = { BackgroundTransparency = 0 },
                duration = 0.15
            })
        end
    end
end

function DialogueController:AddInterrupt()
    local interruptButton = Utility.Component.CreateButton({
        Name = "InterruptButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -40, 0, 10),
        Text = "!",
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Color3.fromRGB(255, 80, 80),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        cornerRadius = 15,
        Parent = State.container
    })

    interruptButton.MouseButton1Click:Connect(function()
        if not State.isTyping then return end

        Controllers.Event:FireServer("Dialogue.Progress", {
            responseId = "__interrupt__"
        })
    end)

    local function updateStyle(isHovered: boolean)
        Utility.Controller.Update({
            instance = interruptButton,
            properties = {
                BackgroundColor3 = isHovered and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 80, 80),
                Size = isHovered and UDim2.new(0, 32, 0, 32) or UDim2.new(0, 30, 0, 30)
            },
            duration = 0.1
        })
    end

    interruptButton.MouseEnter:Connect(function()
        updateStyle(true)
    end)

    interruptButton.MouseLeave:Connect(function()
        updateStyle(false)
    end)

    return interruptButton
end

function DialogueController:TypewriterEffect(text, label, commands, effects)
    State.isTyping = false
    if State.currentCleanup then
        State.currentCleanup()
        State.currentCleanup = nil
    end
    if State.typewriterConnection then
        State.typewriterConnection:Disconnect()
        State.typewriterConnection = nil
    end

    label.Text = ""
    for _, child in ipairs(label:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name == "TypingIndicator" then
            child:Destroy()
        end
    end

    for _, child in ipairs(State.container:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name == "TypingIndicator" then
            child:Destroy()
        end
    end

    task.wait()
    local responses = State.currentLine and State.currentLine.responses
    State.currentLine = { text = text }
    State.currentLine.responses = responses
    local currentIndex = 1
    State.isTyping = true
    label.RichText = true

    local typingIndicator = Instance.new("ImageLabel")
    typingIndicator.Name = "TypingIndicator"
    typingIndicator.Image = "rbxassetid://6034818372"
    typingIndicator.Size = UDim2.new(0, 40, 0, 40)
    typingIndicator.Position = UDim2.new(1, -50, 1, -50)
    typingIndicator.BackgroundTransparency = 1
    typingIndicator.Parent = State.container

    local indicatorTween
    local function animateIndicator()
        if indicatorTween then indicatorTween:Cancel() end

        local tweenInfo = TweenInfo.new(
            1,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut,
            -1,
            true
        )

        indicatorTween = game:GetService("TweenService"):Create(typingIndicator, tweenInfo, {
            Position = UDim2.new(1, -50, 1, -60)
        })
        indicatorTween:Play()
    end
    animateIndicator()

    local colorSegments = {}
    local activeEffects = {}
    local shakeSegments = {}
    local originalPosition = label.Position
    local lastSoundTime = 0
    local SOUND_COOLDOWN = 0.05
    local effectConnection = nil
    local textSpeed = 1
    local currentTextSpeed = 1
    local waitingForPlayerAttention = false

    local function updateEffects()
        if #activeEffects == 0 then return end

        local currentTime = tick()
        local offsetX, offsetY = 0, 0

        for _, effect in ipairs(activeEffects) do
            if currentIndex >= effect.start and currentIndex <= effect.finish then
                if effect.type == "text_shake" then
                    local intensity = effect.intensity * 2
                    offsetX = offsetX + math.random(-intensity, intensity)
                    offsetY = offsetY + math.random(-intensity, intensity)
                elseif effect.type == "text_wave" then
                    local elapsed = currentTime - effect.startTime
                    offsetY = offsetY + math.sin(elapsed * effect.frequency) * (effect.amplitude * 10)
                end
            end
        end

        label.Position = originalPosition + UDim2.new(0, offsetX, 0, offsetY)
    end

    local function startEffects()
        if effectConnection then return end
        effectConnection = game:GetService("RunService").RenderStepped:Connect(updateEffects)
    end

    local cameraShake = nil
    if effects and effects.camera_shake then
        local camera = workspace.CurrentCamera
        cameraShake = Tools.Shake.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
            camera.CFrame *= shakeCFrame
        end)
        cameraShake:Start()
        cameraShake:ShakeOnce(Tools.Shake.GetPreset(effects.camera_shake.preset))

        if effects.camera_shake.delay then
            table.insert(shakeSegments, {
                start = math.floor(effects.camera_shake.delay / 0.03),
                preset = effects.camera_shake.preset
            })
        else
            table.insert(shakeSegments, {
                start = 1,
                preset = effects.camera_shake.preset
            })
        end
    end

    local textTransforms = {}

    if commands then
        for _, command in ipairs(commands) do
            if command.type == "text_speed" then
                textSpeed = command.value.speed or 1
            elseif command.type == "play_sound" then
                local soundConfig = command.value
                if type(soundConfig) == "string" then
                    Utility.Sound.Play(soundConfig)
                elseif type(soundConfig) == "table" then
                    Utility.Sound.Play(soundConfig.sound or soundConfig.name)
                end
            elseif command.type == "screen_flash" then
                local flashConfig = command.value or {}
                local screenGui = State.activeScreen

                if screenGui then
                    local flash = Instance.new("Frame")
                    flash.Name = "ScreenFlash"
                    flash.Size = UDim2.new(1, 0, 1, 0)
                    flash.Position = UDim2.new(0, 0, 0, 0)
                    flash.BackgroundColor3 = flashConfig.color or Color3.fromRGB(255, 255, 255)
                    flash.BackgroundTransparency = 1
                    flash.ZIndex = 999
                    flash.Parent = screenGui

                    Utility.Controller.Update({
                        instance = flash,
                        properties = {
                            BackgroundTransparency = flashConfig.transparency or 0.7
                        },
                        duration = flashConfig.fadeInTime or 0.1
                    })

                    task.delay(flashConfig.duration or 0.2, function()
                        Utility.Controller.Update({
                            instance = flash,
                            properties = {
                                BackgroundTransparency = 1
                            },
                            duration = flashConfig.fadeOutTime or 0.3
                        })

                        task.delay(flashConfig.fadeOutTime or 0.3, function()
                            flash:Destroy()
                        end)
                    end)
                end
            elseif command.type == "play_animation" then
                local animData = command.value
                if animData and animData.target then
                    self:PlayAnimation(animData.target, animData.preset or "TALK")
                end
            elseif command.type == "play_pose" then
                if command.value and command.value.target then
                    local character = workspace:FindFirstChild(command.value.target)
                    if character then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                        if animator then
                            local poseType = command.value.preset or "NEUTRAL"

                            if not State.characterAnimations then
                                State.characterAnimations = {}
                            end

                            if not State.characterAnimations[command.value.target] then
                                local npcType = character:GetAttribute("TYPE") or "NPC"
                                local categories = {"EMOTION", "DIALOGUE", npcType}

                                State.characterAnimations[command.value.target] = Utility.Animation.Categories(animator, categories)
                            end

                            Utility.Animation.Play(
                                State.characterAnimations[command.value.target],
                                "POSE",
                                poseType,
                                0.5,
                                1.0
                            )
                        end
                    end
                end
            elseif command.type == "face_direction" then
                if command.value and command.value.target then
                    local character = workspace:FindFirstChild(command.value.target)
                    if character then
                        local targetType = command.value.targetType or "PLAYER"
                        local targetValue = command.value.value
                        local player = game.Players.LocalPlayer

                        Modules.Dialogue.ProcessCommands({
                            {
                                type = Modules.Dialogue.CommandTypes.FACE_DIRECTION,
                                value = {
                                    target = targetType:lower(),
                                    value = targetValue,
                                    behavior = command.value.behavior
                                }
                            }
                        }, {
                            player = player,
                            character = character,
                            currentLine = State.currentLine,
                            services = {}
                        })
                    end
                end
            elseif command.type == "timing_control" then
                if command.value and command.value.wait then
                    waitingForPlayerAttention = true
                    task.delay(command.value.wait, function()
                        if waitingForPlayerAttention then
                            self:TrackAttention(-1)
                            waitingForPlayerAttention = false
                        end
                    end)
                end
            elseif command.value and command.value.text then
                local startPos = string.find(text, command.value.text, 1, true)
                if startPos then
                    if command.type == "text_color" then
                        local color = command.value.color
                        if color then
                            table.insert(colorSegments, {
                                start = startPos,
                                finish = startPos + #command.value.text - 1,
                                text = command.value.text,
                                color = color
                            })
                        end
                    elseif command.type == "text_size" then
                        local size = command.value.size
                        if size then
                            table.insert(textTransforms, {
                                start = startPos,
                                finish = startPos + #command.value.text - 1,
                                text = command.value.text,
                                transform = function(t)
                                    return string.format('<font size="%d">%s</font>', size, t)
                                end
                            })
                        end
                    elseif command.type == "text_shake" or command.type == "text_wave" then
                        local commandText = command.value.text
                        local textToCheck = string.sub(text, startPos, startPos + #commandText - 1)
                        if textToCheck == commandText then
                            table.insert(activeEffects, {
                                type = command.type,
                                start = startPos,
                                finish = startPos + #commandText - 1,
                                intensity = command.value.intensity or 0.3,
                                amplitude = command.value.amplitude or 0.5,
                                frequency = command.value.frequency or 2,
                                startTime = tick()
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(colorSegments, function(a, b) return a.start < b.start end)
    table.sort(textTransforms, function(a, b) return a.start < b.start end)
    table.sort(shakeSegments, function(a, b) return a.start < b.start end)

    local function cleanupEffects()
        State.isTyping = false
        waitingForPlayerAttention = false
        if effectConnection then
            effectConnection:Disconnect()
            effectConnection = nil
        end
        if cameraShake then
            cameraShake:Stop()
            cameraShake = nil
        end
        if indicatorTween then
            indicatorTween:Cancel()
            Utility.Controller.Update({
                instance = typingIndicator,
                properties = {
                    Position = UDim2.new(1, -50, 1, -50),
                    ImageTransparency = 1
                },
                duration = 0.2
            })
            task.wait(0.2)
            typingIndicator:Destroy()
            indicatorTween = nil
        end
        label.Position = originalPosition
        State.currentCleanup = nil
        State.typewriterConnection = nil
    end

    State.currentCleanup = cleanupEffects

    local function getCurrentText(visibleLength)
        local result = ""
        local currentPos = 1

        while currentPos <= visibleLength do
            local char = string.sub(text, currentPos, currentPos)
            local hasColor = false
            local hasTransform = false

            for _, segment in ipairs(colorSegments) do
                if currentPos >= segment.start and currentPos <= segment.finish then
                    if currentPos == segment.start then
                        local visibleColorText = string.sub(segment.text, 1, math.min(visibleLength - segment.start + 1, #segment.text))
                        local hex = string.format("#%02X%02X%02X",
                            math.floor(segment.color.R * 255),
                            math.floor(segment.color.G * 255),
                            math.floor(segment.color.B * 255))
                        result = result .. string.format('<font color="%s">%s</font>', hex, visibleColorText)
                        currentPos = currentPos + #visibleColorText
                        hasColor = true
                        break
                    else
                        hasColor = true
                        break
                    end
                end
            end

            if not hasColor then
                for _, transform in ipairs(textTransforms) do
                    if currentPos >= transform.start and currentPos <= transform.finish then
                        if currentPos == transform.start then
                            local visibleText = string.sub(transform.text, 1, math.min(visibleLength - transform.start + 1, #transform.text))
                            result = result .. transform.transform(visibleText)
                            currentPos = currentPos + #visibleText
                            hasTransform = true
                            break
                        else
                            hasTransform = true
                            break
                        end
                    end
                end
            end

            if not hasColor and not hasTransform then
                result = result .. char
                currentPos = currentPos + 1
            end
        end

        return result
    end

    local function completeText()
        State.isTyping = false
        if waitingForPlayerAttention then
            self:TrackAttention(1)
            waitingForPlayerAttention = false
        end

        if #activeEffects > 0 then
            startEffects()
        end
        cleanupEffects()

        if State.currentLine and State.currentLine.responses and #State.currentLine.responses > 0 then
            task.wait(0.1)
            self:ShowResponses(State.currentLine.responses)
        end
    end

    local function skipTyping()
        if not State.isTyping then return end

        if State.skipCount and State.skipCount > 2 then
            Controllers.Event:FireServer("Dialogue.Progress", {
                responseId = "__rush__"
            })
            State.skipCount = 0
            return
        end

        State.skipCount = (State.skipCount or 0) + 1
        State.isTyping = false
        label.Text = getCurrentText(#text)
        completeText()

        task.delay(2, function()
            State.skipCount = math.max(0, (State.skipCount or 0) - 1)
        end)
    end

    State.container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            skipTyping()
        end
    end)

    Utility.Input.HandleInput({
        id = "Dialogue",
        actions = {
            {
                name = "Skip_Dialogue",
                keys = {Enum.KeyCode.Return, Enum.KeyCode.ButtonA},
                callback = function(inputState)
                    if not inputState then return end
                    skipTyping()
                end
            }
        },
        keyboardEnabled = true,
        mouseEnabled = true,
        gamepadEnabled = true,
        ignoreProcessed = false,
        requireGameFocus = true
    })

    local function updateText()
        if not State.isTyping then return end

        local currentChar = string.sub(text, currentIndex, currentIndex)
        label.Text = getCurrentText(currentIndex)

        local currentTime = tick()
        if currentTime - lastSoundTime >= SOUND_COOLDOWN then
            Utility.Sound.Dialogue("Type")
            lastSoundTime = currentTime
        end

        for i = #shakeSegments, 1, -1 do
            local shake = shakeSegments[i]
            if currentIndex == shake.start then
                if shake.sound then
                    Utility.Sound.Dialogue(shake.sound)
                end
                if cameraShake and shake.preset then
                    cameraShake:Start()
                    cameraShake:ShakeOnce(Tools.Shake.GetPreset(shake.preset))
                end
                table.remove(shakeSegments, i)
            end
        end

        for _, effect in ipairs(activeEffects) do
            if currentIndex == effect.start then
                startEffects()
                break
            end
        end

        for _, command in ipairs(commands or {}) do
            if command.type == "text_speed" and command.value then
                local startPos = 1
                if command.value.text then
                    startPos = string.find(text, command.value.text, 1, true)
                end
                if currentIndex >= startPos then
                    currentTextSpeed = command.value.speed or 1
                end
            end
        end

        if currentChar == "." or currentChar == "!" or currentChar == "?" then
            task.wait(0.5 / currentTextSpeed)
        elseif currentChar == "," or currentChar == ";" or currentChar == ":" then
            task.wait(0.2 / currentTextSpeed)
        else
            task.wait(0.03 / currentTextSpeed)
        end

        currentIndex = currentIndex + 1

        if currentIndex <= #text then
            task.spawn(updateText)
        else
            completeText()
        end
    end

    task.spawn(updateText)
    return cleanupEffects
end

--[[ Diplomacy Functions ]]
function DialogueController:ShowDiplomacy(conflictData)
    if not conflictData or not State.diplomaticOptions then return end

    State.ui.responseFrame.Size = UDim2.new(0, 330, 0, 0)
    State.ui.responseFrame.BackgroundTransparency = 1
    State.ui.responseContainer:ClearAllChildren()
    State.ui.responses = {}

    local totalHeight = 0
    local categorySpacing = 15

    local headerFrame = Utility.Component.CreateFrame({
        Name = "DiplomaticHeader",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(60, 60, 70),
        cornerRadius = 8,
        Parent = State.ui.responseContainer
    })

    local headerLabel = Utility.Component.CreateLabel({
        Name = "HeaderLabel",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = "Diplomatic Options: " .. conflictData.id,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1,
        Parent = headerFrame
    })

    totalHeight = totalHeight + 50

    local factionInfoFrame = Utility.Component.CreateFrame({
        Name = "FactionInfo",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, totalHeight),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        cornerRadius = 8,
        Parent = State.ui.responseContainer
    })

    local faction1Label = Utility.Component.CreateLabel({
        Name = "Faction1",
        Size = UDim2.new(0.5, -15, 0, 25),
        Position = UDim2.new(0, 10, 0, 5),
        Text = conflictData.factions[1] or "Faction 1",
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(100, 149, 237),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent = factionInfoFrame
    })

    local faction2Label = Utility.Component.CreateLabel({
        Name = "Faction2",
        Size = UDim2.new(0.5, -15, 0, 25),
        Position = UDim2.new(0.5, 5, 0, 5),
        Text = conflictData.factions[2] or "Faction 2",
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(220, 80, 60),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent = factionInfoFrame
    })

    local vsLabel = Utility.Component.CreateLabel({
        Name = "VersusLabel",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 30),
        Text = "Diplomatic conflict requires your intervention",
        TextSize = 16,
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1,
        Parent = factionInfoFrame
    })

    totalHeight = totalHeight + 70

    if State.diplomaticOptions and #State.diplomaticOptions > 0 then
        for i, option in ipairs(State.diplomaticOptions) do
            local optionFrame = Utility.Component.CreateButton({
                Name = "Option_" .. i,
                Size = UDim2.new(1, 0, 0, 80),
                Position = UDim2.new(0, 0, 0, totalHeight),
                BackgroundColor3 = Color3.fromRGB(35, 35, 45),
                cornerRadius = 8,
                Parent = State.ui.responseContainer,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = true
            })

            local titleLabel = Utility.Component.CreateLabel({
                Name = "Title",
                Size = UDim2.new(1, -20, 0, 25),
                Position = UDim2.new(0, 10, 0, 5),
                Text = option.title,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                TextColor3 = option.color or Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Parent = optionFrame
            })

            local descLabel = Utility.Component.CreateLabel({
                Name = "Description",
                Size = UDim2.new(1, -20, 0, 45),
                Position = UDim2.new(0, 10, 0, 30),
                Text = option.description,
                TextSize = 16,
                Font = Enum.Font.Gotham,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                BackgroundTransparency = 1,
                Parent = optionFrame
            })

            if option.icon then
                local iconImage = Utility.Component.CreateImage({
                    Name = "Icon",
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -30, 0, 10),
                    Image = option.icon,
                    BackgroundTransparency = 1,
                    ImageColor3 = option.color or Color3.fromRGB(255, 255, 255),
                    Parent = optionFrame
                })
            end

            local impactLabel = Utility.Component.CreateLabel({
                Name = "Impact",
                Size = UDim2.new(0, 100, 0, 20),
                Position = UDim2.new(1, -110, 0, 55),
                Text = "Impact: " .. (option.impact or "Medium"),
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextColor3 = Color3.fromRGB(180, 180, 180),
                TextXAlignment = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1,
                Parent = optionFrame
            })

            optionFrame.MouseButton1Click:Connect(function()
                if not optionFrame.Visible or
                   optionFrame.BackgroundTransparency > 0 or
                   State.isTyping then
                    return
                end

                for _, btn in ipairs(State.ui.responses) do
                    btn.AutoButtonColor = false
                    btn.Active = false

                    Utility.Controller.Update({
                        instance = btn,
                        properties = {
                            BackgroundTransparency = 1,
                            TextTransparency = 1
                        },
                        duration = 0.15
                    })
                end

                Utility.Controller.Update({
                    instance = State.ui.responseFrame,
                    properties = {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 330, 0, 0)
                    },
                    duration = 0.2
                })

                task.wait(0.2)

                Controllers.Event:FireServer("Dialogue.Diplomacy", {
                    conflictId = conflictData.id,
                    action = option.action,
                    optionId = option.id,
                    metadata = option.metadata
                })
            end)

            optionFrame.MouseEnter:Connect(function()
                Utility.Controller.Update({
                    instance = optionFrame,
                    properties = {
                        BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                    },
                    duration = 0.1
                })

                Utility.Controller.Update({
                    instance = titleLabel,
                    properties = {
                        TextColor3 = option.color and option.color:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.fromRGB(255, 255, 255)
                    },
                    duration = 0.1
                })
            end)

            optionFrame.MouseLeave:Connect(function()
                Utility.Controller.Update({
                    instance = optionFrame,
                    properties = {
                        BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                    },
                    duration = 0.1
                })

                Utility.Controller.Update({
                    instance = titleLabel,
                    properties = {
                        TextColor3 = option.color or Color3.fromRGB(255, 255, 255)
                    },
                    duration = 0.1
                })
            end)

            table.insert(State.ui.responses, optionFrame)
            totalHeight = totalHeight + 90
        end
    end

    task.wait(0.1)
    State.ui.responseFrame.Size = UDim2.new(0, 330, 0, totalHeight)

    Utility.Controller.Update({
        instance = State.ui.responseFrame,
        properties = {BackgroundTransparency = 0},
        duration = 0.2
    })

    task.wait(0.2)
    for _, button in ipairs(State.ui.responses) do
        Utility.Controller.Update({
            instance = button,
            properties = {
                BackgroundTransparency = 0
            },
            duration = 0.15
        })

        for _, child in ipairs(button:GetChildren()) do
            if child:IsA("TextLabel") then
                Utility.Controller.Update({
                    instance = child,
                    properties = { TextTransparency = 0 },
                    duration = 0.15
                })
            elseif child:IsA("ImageLabel") then
                Utility.Controller.Update({
                    instance = child,
                    properties = { ImageTransparency = 0 },
                    duration = 0.15
                })
            end
        end
    end
end

return DialogueController