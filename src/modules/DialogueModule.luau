--[[ DialogueModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local DialogueModule = {}

--[[ Types ]]
export type DialogueCommand = {
    type: string,
    value: any
}

export type DialogueEffect = {
    type: string,
    target: string,
    value: number | string | boolean,
    duration: number?
}

export type DialogueConsequence = {
    immediate: {DialogueEffect}?,
    delayed: {DialogueEffect}?,
    permanent: {DialogueEffect}?
}

export type DialogueResponse = {
    text: string,
    nextDialogueId: string?,
    requirements: {[string]: any}?,
    effects: {DialogueEffect}?,
    consequences: DialogueConsequence?,
    reputation: {[string]: number}?,
    relationships: {[string]: number}?,
    type: string?,
    category: string?,
    priority: number?,
    returnPoint: string?,
    contextual: boolean?,
    metadata: {[string]: any}?
}

export type DialogueLine = {
    id: string,
    speaker: string,
    text: string | {string},
    emote: string?,
    animation: string?,
    sound: string?,
    commands: {DialogueCommand}?,
    responses: {DialogueResponse}?,
    interruptible: boolean?,
    interruptResponse: string?,
    rushResponse: string?,
    timing: {
        minResponseTime: number?,
        maxResponseTime: number?,
        idealResponseTime: number?
    }?,
    category: string?,
    returnPoint: string?,
    contextual: boolean?,
    metadata: {[string]: any}?
}

export type DialogueTree = {
    id: string,
    title: string,
    description: string,
    startingLine: string,
    lines: {[string]: DialogueLine},
    metadata: {[string]: any}?,
    consequences: {[string]: DialogueConsequence}?,
    categories: {[string]: {
        name: string,
        description: string,
        priority: number,
        icon: string?,
        color: Color3?,
        requirements: {[string]: any}?
    }}?
}

--[[ Constants ]]
DialogueModule.Values = {
    TOWN_NAME = "Ascendium",
    PLAYER_TITLE = "Adventurer",
    NPC_TITLE = "Citizen"
}

--[[ Constants ]]
DialogueModule.CommandTypes = {
    -- Text Processing
    TEXT_REPLACE = "text_replace",

    -- Text Manipulation
    TEXT_COLOR = "text_color",
    TEXT_SIZE = "text_size",
    TEXT_SPEED = "text_speed",
    TEXT_SHAKE = "text_shake",
    TEXT_WAVE = "text_wave",

    -- Audio
    PLAY_SOUND = "play_sound",
    STOP_SOUND = "stop_sound",

    -- Visual Effects
    PLAY_EFFECT = "play_effect",
    SCREEN_FLASH = "screen_flash",
    SCREEN_SHAKE = "screen_shake",

    -- Character Interaction
    PLAY_ANIMATION = "play_animation",
    PLAY_POSE = "play_pose",
    FACE_DIRECTION = "face_direction",

    -- Timing and Interruption
    INTERRUPT_ENABLE = "interrupt_enable",
    INTERRUPT_DISABLE = "interrupt_disable",
    TIMING_CONTROL = "timing_control",

    -- Faction-specific commands
    FACTION_INFLUENCE = "faction_influence",
    FACTION_RELATIONSHIP = "faction_relationship",
    DIPLOMATIC_OPTIONS = "diplomatic_options"
}

DialogueModule.FacingTarget = {
    PLAYER = "player",
    OBJECT = "object",
    POINT = "point",
    DIRECTION = "direction",
    AWAY = "away"
}

DialogueModule.ShakePresets = {
    LIGHT = "Bump",
    MEDIUM = "Impact",
    HEAVY = "HeavyImpact",
    DIZZY = "Dizzy",
    STUN = "Stun"
}

DialogueModule.DirectionPreset = {
    NORTH = Vector3.new(0, 0, 1),
    SOUTH = Vector3.new(0, 0, -1),
    EAST = Vector3.new(1, 0, 0),
    WEST = Vector3.new(-1, 0, 0),
    UP = Vector3.new(0, 1, 0),
    DOWN = Vector3.new(0, -1, 0)
}

DialogueModule.SoundTypes = {
    DIALOGUE_BLIP = "dialogue_blip",
    EMPHASIS = "emphasis",
    QUESTION = "question",
    EXCLAMATION = "exclamation",
    WHISPER = "whisper"
}

DialogueModule.TextColorPresets = {
    DEFAULT = Color3.new(1, 1, 1),
    EMPHASIS = Color3.fromRGB(255, 220, 0),
    QUESTION = Color3.fromRGB(255, 100, 247),
    SUCCESS = Color3.fromRGB(100, 150, 255),
    KEY = Color3.fromRGB(0, 255, 0),
    WARNING = Color3.fromRGB(255, 50, 50),
    SOFT = Color3.fromRGB(200, 200, 200)
}

DialogueModule.EffectTypes = {
    REPUTATION = "reputation",
    RELATIONSHIP = "relationship",
    QUEST = "quest",
    ITEM = "item",
    STAT = "stat",
    FLAG = "flag",
    WORLD_STATE = "world_state",
    PATIENCE = "patience",
    ATTENTION = "attention",
    FACTION_STANDING = "faction_standing",
    FACTION_RELATIONSHIP = "faction_relationship",
    DIPLOMATIC_INFLUENCE = "diplomatic_influence",
    CONFLICT_RESOLUTION = "conflict_resolution",
    GLOBAL_REPUTATION = "global_reputation",
    LORE_DISCOVER = "lore_discover",
    LORE_UNLOCK = "lore_unlock",
    FACTION_VIOLATION = "faction_violation"
}

DialogueModule.TimingPresets = {
    QUICK = {
        minResponseTime = 1,
        maxResponseTime = 5,
        idealResponseTime = 2,
        typingSpeed = 20,
        naturalPauses = {
            comma = 0.2,
            period = 0.5,
            exclamation = 0.5,
            question = 0.5,
            ellipsis = 0.7
        }
    },
    NORMAL = {
        minResponseTime = 2,
        maxResponseTime = 10,
        idealResponseTime = 4,
        typingSpeed = 15,
        naturalPauses = {
            comma = 0.3,
            period = 0.7,
            exclamation = 0.6,
            question = 0.7,
            ellipsis = 1.0
        }
    },
    THOUGHTFUL = {
        minResponseTime = 4,
        maxResponseTime = 15,
        idealResponseTime = 8,
        typingSpeed = 10,
        naturalPauses = {
            comma = 0.5,
            period = 1.0,
            exclamation = 0.8,
            question = 1.2,
            ellipsis = 1.5
        }
    },
    DRAMATIC = {
        minResponseTime = 3,
        maxResponseTime = 12,
        idealResponseTime = 6,
        typingSpeed = 8,
        naturalPauses = {
            comma = 0.7,
            period = 1.5,
            exclamation = 1.2,
            question = 1.5,
            ellipsis = 2.0
        },
        emphasis = {
            delay = 0.5,
            speed = 0.7
        }
    }
}

--[[ Dialogue Templates ]]
DialogueModule.Templates = {
    SimpleConversation = function(params: {
        id: string,
        title: string,
        speaker: string,
        lines: {string},
        responses: {DialogueResponse}?
    }): DialogueTree
        local dialogueLines = {}
        local previousLineId = nil

        for i, text in ipairs(params.lines) do
            local lineId = params.id .. "_line_" .. i
            local line: DialogueLine = {
                id = lineId,
                speaker = params.speaker,
                text = text,
                emote = params.emote or "NEUTRAL",
                commands = params.commands
            }

            if previousLineId then
                dialogueLines[previousLineId].responses = {
                    {text = "Continue", nextDialogueId = lineId}
                }
            end

            if i == #params.lines and params.responses then
                line.responses = params.responses
            end

            dialogueLines[lineId] = line
            previousLineId = lineId
        end

        return {
            id = params.id,
            title = params.title,
            description = params.title,
            startingLine = params.id .. "_line_1",
            lines = dialogueLines
        }
    end,

    BranchingConversation = function(params: {
        id: string,
        title: string,
        speaker: string,
        lines: {[string]: {
            text: string,
            emote: string?,
            commands: {DialogueCommand}?,
            responses: {DialogueResponse}
        }}
    }): DialogueTree
        local dialogueLines = {}

        for lineKey, lineData in pairs(params.lines) do
            local lineId = params.id .. "_" .. lineKey
            dialogueLines[lineId] = {
                id = lineId,
                speaker = params.speaker,
                text = lineData.text,
                emote = lineData.emote or "NEUTRAL",
                commands = lineData.commands,
                responses = lineData.responses
            }
        end

        return {
            id = params.id,
            title = params.title,
            description = params.title,
            startingLine = params.id .. "_start",
            lines = dialogueLines
        }
    end,

    ConflictDialogue = function(params: {
        id: string,
        title: string,
        speaker: string,
        factions: {string},
        conflictType: string,
        cause: string?
    }): DialogueTree
        local conflictId = params.id
        local speaker = params.speaker or "Diplomat"
        local faction1 = params.factions[1]
        local faction2 = params.factions[2]
        local cause = params.cause or "territorial disputes"

        return {
            id = conflictId,
            title = params.title or (faction1 .. " vs " .. faction2 .. " Conflict"),
            description = "A diplomatic situation between " .. faction1 .. " and " .. faction2,
            startingLine = conflictId .. "_start",
            categories = {
                DIPLOMATIC = DialogueModule.Categories.DIPLOMATIC,
                AGGRESSIVE = DialogueModule.Categories.AGGRESSIVE
            },
            lines = {
                [conflictId .. "_start"] = {
                    id = conflictId .. "_start",
                    speaker = speaker,
                    text = "The conflict between " .. faction1 .. " and " .. faction2 .. " has reached a critical point. As an outsider with influence, you could play a role in how this unfolds.",
                    emote = "NEUTRAL",
                    responses = {
                        {
                            text = "Tell me more about this conflict.",
                            nextDialogueId = conflictId .. "_details",
                            category = "MAIN"
                        },
                        {
                            text = "I'd like to help resolve this peacefully.",
                            nextDialogueId = conflictId .. "_mediate",
                            category = "DIPLOMATIC"
                        },
                        {
                            text = "Let them fight. It's not my problem.",
                            nextDialogueId = conflictId .. "_ignore",
                            category = "AGGRESSIVE"
                        }
                    }
                },
                [conflictId .. "_details"] = {
                    id = conflictId .. "_details",
                    speaker = speaker,
                    text = faction1 .. " and " .. faction2 .. " have been at odds over " .. cause .. ". The situation has escalated to dangerous levels.",
                    emote = "NEUTRAL",
                    responses = {
                        {
                            text = "What caused this conflict?",
                            nextDialogueId = conflictId .. "_cause"
                        },
                        {
                            text = "I'd like to help resolve this.",
                            nextDialogueId = conflictId .. "_mediate",
                            category = "DIPLOMATIC"
                        },
                        {
                            text = "Let them fight. I'll watch from a distance.",
                            nextDialogueId = conflictId .. "_ignore",
                            category = "AGGRESSIVE"
                        }
                    }
                },
                [conflictId .. "_cause"] = {
                    id = conflictId .. "_cause",
                    speaker = speaker,
                    text = "This conflict began when tensions boiled over after years of mistrust. Both sides claim the other made the first aggressive move.",
                    emote = "DISTRUSTFUL",
                    responses = {
                        {
                            text = "I'd like to try mediating this conflict.",
                            nextDialogueId = conflictId .. "_mediate",
                            category = "DIPLOMATIC"
                        },
                        {
                            text = "I'm not getting involved in this mess.",
                            nextDialogueId = conflictId .. "_ignore",
                            category = "AGGRESSIVE"
                        }
                    }
                },
                [conflictId .. "_mediate"] = {
                    id = conflictId .. "_mediate",
                    speaker = speaker,
                    text = "You wish to mediate this conflict? Your reputation may precede you, but bringing peace will require diplomatic skill.",
                    emote = "FRIENDLY",
                    responses = {
                        {
                            text = "I'll attempt to find a peaceful resolution.",
                            nextDialogueId = conflictId .. "_diplomatic_options",
                            category = "DIPLOMATIC",
                            type = "diplomatic",
                            metadata = {
                                action = "SHOW_DIPLOMATIC_OPTIONS",
                                conflictId = conflictId
                            }
                        },
                        {
                            text = "Actually, I need to consider this more carefully.",
                            nextDialogueId = conflictId .. "_start"
                        }
                    }
                },
                [conflictId .. "_diplomatic_options"] = {
                    id = conflictId .. "_diplomatic_options",
                    speaker = speaker,
                    text = "There are several approaches you could take to resolve this conflict. Choose wisely - your reputation and the fate of these factions depends on it.",
                    emote = "NEUTRAL",
                    metadata = {
                        showDiplomaticOptions = true,
                        conflict = {
                            id = conflictId,
                            factions = {faction1, faction2}
                        }
                    },
                    responses = {}
                },
                [conflictId .. "_ignore"] = {
                    id = conflictId .. "_ignore",
                    speaker = speaker,
                    text = "You choose to stay neutral. The conflict will run its course without your intervention, though the consequences may affect the region.",
                    emote = "NEUTRAL",
                    responses = {
                        {
                            text = "I'll accept whatever happens.",
                            nextDialogueId = conflictId .. "_ignore_confirm"
                        },
                        {
                            text = "Actually, I should get involved.",
                            nextDialogueId = conflictId .. "_start"
                        }
                    }
                },
                [conflictId .. "_ignore_confirm"] = {
                    id = conflictId .. "_ignore_confirm",
                    speaker = speaker,
                    text = "Very well. Should you change your mind, you can always return. But be warned - conflicts have a way of spreading, and neutrality doesn't guarantee safety.",
                    emote = "DISTRUSTFUL",
                    responses = {
                        {
                            text = "I understand the risks.",
                            type = "faction_action",
                            metadata = {
                                action = "IGNORE_CONFLICT",
                                conflictId = conflictId
                            }
                        }
                    }
                }
            }
        }
    end
}

--[[ Constants ]]
DialogueModule.Categories = {
    MAIN = {
        name = "Main",
        description = "Critical story and quest dialogue",
        priority = 100,
        color = Color3.fromRGB(255, 215, 0)
    },
    QUEST = {
        name = "Quest",
        description = "Active quest-related dialogue",
        priority = 90,
        color = Color3.fromRGB(255, 165, 0)
    },
    LORE = {
        name = "Lore",
        description = "World and story background information",
        priority = 80,
        color = Color3.fromRGB(147, 112, 219)
    },
    PERSONAL = {
        name = "Personal",
        description = "Character backstory and relationships",
        priority = 70,
        color = Color3.fromRGB(100, 149, 237)
    },
    GOSSIP = {
        name = "Gossip",
        description = "Information about other characters and events",
        priority = 60,
        color = Color3.fromRGB(255, 182, 193)
    },
    TRADE = {
        name = "Trade",
        description = "Trading and commerce dialogue",
        priority = 50,
        color = Color3.fromRGB(152, 251, 152)
    },
    DIPLOMATIC = {
        name = "Diplomatic",
        description = "Faction diplomacy and mediation options",
        priority = 85,
        color = Color3.fromRGB(120, 220, 220),
        icon = ""
    },
    AGGRESSIVE = {
        name = "Aggressive",
        description = "Threatening or intimidating dialogue options",
        priority = 55,
        color = Color3.fromRGB(220, 80, 60),
        icon = ""
    }
}

DialogueModule.ResponseTypes = {
    CONTINUE = "continue",
    BRANCH = "branch",
    RETURN = "return",
    EXIT = "exit",
    SHOP = "shop",
    QUEST = "quest",
    DIPLOMATIC = "diplomatic",
    MEDIATE = "mediate",
    THREATEN = "threaten",
    BRIBE = "bribe",
    DECEIVE = "deceive",
    FACTION_ACTION = "faction_action",
    DISRESPECT = "disrespect"
}

--[[ Constants ]]
DialogueModule.EmotionalStates = {
    BETRAYED = {
        name = "Betrayed",
        description = "Deep sense of betrayal and distrust",
        threshold = -50,
        color = Color3.fromRGB(139, 0, 0),
        icon = "",
        reactions = {
            INITIAL = {
                "You... You have the nerve to show your face after what you did?",
                "I trusted you, and this is how you repay me?",
                "Leave. Now. Before I do something we'll both regret."
            },
            PERSISTENT = {
                "I haven't forgotten what you did.",
                "Your presence still brings me pain.",
                "Some wounds don't heal easily..."
            },
            FORGIVING = {
                "Perhaps... perhaps we can move past this.",
                "I see genuine remorse in your eyes.",
                "Everyone deserves a second chance, even you."
            }
        }
    },
    DISTRUSTFUL = {
        name = "Distrustful",
        description = "Wary and suspicious",
        threshold = -30,
        color = Color3.fromRGB(255, 140, 0),
        icon = "",
        reactions = {
            INITIAL = {
                "I've heard about you. Watch yourself.",
                "Your reputation precedes you...",
                "I'll be keeping my eye on you."
            },
            PERSISTENT = {
                "Still don't trust you fully.",
                "You'll have to prove yourself to me.",
                "Actions speak louder than words."
            },
            IMPROVING = {
                "Maybe I judged you too quickly.",
                "You're... not quite what I expected.",
                "Show me I can trust you."
            }
        }
    },
    NEUTRAL = {
        name = "Neutral",
        description = "No strong feelings",
        threshold = 0,
        color = Color3.fromRGB(180, 180, 180),
        icon = ""
    },
    FRIENDLY = {
        name = "Friendly",
        description = "Positive relationship",
        threshold = 30,
        color = Color3.fromRGB(80, 200, 120),
        icon = "",
        reactions = {
            GREETING = {
                "Ah, my friend! Always good to see you.",
                "Your visits always brighten my day!",
                "Welcome back, trusted ally!"
            },
            FAVOR = {
                "For you? Of course I'll help!",
                "You've proven yourself trustworthy.",
                "What do you need, friend?"
            }
        }
    },
    DEVOTED = {
        name = "Devoted",
        description = "Strong loyalty and trust",
        threshold = 50,
        color = Color3.fromRGB(80, 150, 255),
        icon = "",
        reactions = {
            GREETING = {
                "My most trusted friend!",
                "I'd trust you with my life.",
                "Your presence honors me."
            },
            FAVOR = {
                "Anything for you, my friend.",
                "You need only ask.",
                "Your cause is my cause."
            }
        }
    }
}

DialogueModule.EmotionalTriggers = {
    BETRAYAL = {
        value = -50,
        memory = "PERMANENT",
        reactions = {
            immediate = {
                text = "I'll never forget this betrayal...",
                effects = {
                    {type = "relationship", value = -50},
                    {type = "reputation", value = -20}
                }
            },
            delayed = {
                text = "Word of your treachery will spread.",
                effects = {
                    {type = "reputation", value = -10, duration = 604800}
                }
            }
        }
    },
    FORGIVENESS = {
        value = 30,
        memory = "PERMANENT",
        requirements = {
            minRelationship = -60,
            maxRelationship = -20,
            timeElapsed = 86400
        },
        reactions = {
            immediate = {
                text = "Your sincere apology touches my heart.",
                effects = {
                    {type = "relationship", value = 30},
                    {type = "reputation", value = 10}
                }
            },
            delayed = {
                text = "Perhaps people can change...",
                effects = {
                    {type = "reputation", value = 5, duration = 604800}
                }
            }
        }
    }
}

--[[ Validation Functions ]]
function DialogueModule.ValidateTree(tree: DialogueTree): (boolean, string?)
    if not tree.id or not tree.title or not tree.startingLine then
        return false, "Missing required dialogue tree fields"
    end

    if not tree.lines or not tree.lines[tree.startingLine] then
        return false, "Invalid starting line"
    end

    if tree.categories then
        for categoryId, category in pairs(tree.categories) do
            if not category.name or not category.description then
                return false, string.format("Category %s missing required fields", categoryId)
            end
        end
    end

    for lineId, line in pairs(tree.lines) do
        if not line.id or not line.speaker or not line.text then
            return false, string.format("Line %s missing required fields", lineId)
        end

        if line.responses then
            for _, response in pairs(line.responses) do
                if not response.text then
                    return false, string.format("Response in line %s missing text", lineId)
                end

                response.type = response.type or DialogueModule.ResponseTypes.CONTINUE

                if response.type == DialogueModule.ResponseTypes.RETURN and not response.returnPoint then
                    return false, string.format("Return response in line %s missing return point", lineId)
                end

                if response.category and tree.categories and tree.categories[response.category] then
                    response.priority = response.priority or tree.categories[response.category].priority
                else
                    response.priority = response.priority or 0
                end

                response.commands = response.commands or {}
                table.insert(response.commands, {
                    type = DialogueModule.CommandTypes.TEXT_REPLACE,
                    value = {
                        text = response.text,
                        speaker = line.speaker
                    }
                })
            end

            table.sort(line.responses, function(a, b)
                return (a.priority or 0) > (b.priority or 0)
            end)
        end

        line.commands = line.commands or {}
        table.insert(line.commands, {
            type = DialogueModule.CommandTypes.TEXT_REPLACE,
            value = {
                text = line.text,
                speaker = line.speaker
            }
        })
    end

    return true
end

function DialogueModule.Replacements(text: string | {string}, player: Player?, context: {[string]: any}?): string
    if not text then return "" end

    if type(text) == "table" then
        text = text[math.random(#text)]
    end

    local Replacements = {
        ["{PLAYER_NAME}"] = player and player.Name or "Adventurer",
        ["{TOWN_NAME}"] = DialogueModule.Values.TOWN_NAME,
        ["{PLAYER_TITLE}"] = DialogueModule.Values.PLAYER_TITLE
    }

    if context then
        if context.npcName then
            Replacements["{NPC_NAME}"] = context.npcName
        end

        if context.npcModel then
            local attributes = {
                BusinessName = "{BUSINESS_NAME}",
                Title = "{NPC_TITLE}"
            }

            for attrName, placeholder in pairs(attributes) do
                local value = context.npcModel:GetAttribute(attrName)
                if value then
                    Replacements[placeholder] = value
                elseif attrName == "Title" then
                    Replacements[placeholder] = DialogueModule.Values.NPC_TITLE
                end
            end
        end
    end

    for placeholder, value in pairs(Replacements) do
        local isNameOrTitle = placeholder:match("{[%u_]*NAME}") or
                              placeholder:match("{[%u_]*TITLE}")

        local function formatValue(value, isStartOfSentence)
            if not value then return "" end

            if isNameOrTitle or isStartOfSentence then
                return value:gsub("(%a)([%w_']*)", function(first, rest)
                    return first:upper() .. rest:lower()
                end)
            end

            return value:lower()
        end

        text = text:gsub("^" .. placeholder:gsub("%p", "%%%1"), function()
            return formatValue(value, true)
        end)

        text = text:gsub("([%.%!%?]%s+)" .. placeholder:gsub("%p", "%%%1"), function(punctuation)
            return punctuation .. formatValue(value, true)
        end)

        text = text:gsub(placeholder, function()
            return formatValue(value, false)
        end)
    end

    return text
end

--[[ Utility Functions ]]
function DialogueModule.ProcessCommands(commands: {DialogueCommand}, context: {
    camera: Camera?,
    shake: any?,
    character: Model?,
    player: Player?,
    world: any?,
    services: {
        Audio: any?,
        Particle: any?,
        Animation: any?
    }?
})
    if not commands or not context.services then return end

    local processedText = nil

    for _, command in pairs(commands) do
        if command.type == DialogueModule.CommandTypes.TEXT_REPLACE then
            processedText = DialogueModule.Replacements(
                command.value.text,
                context.player,
                {
                    npcName = command.value.speaker,
                    npcModel = workspace:FindFirstChild(command.value.speaker)
                }
            )

        elseif command.type == DialogueModule.CommandTypes.TEXT_SHAKE then
            if context.shake and context.camera then
                local shakePreset = command.value.preset or DialogueModule.ShakePresets.LIGHT
                local duration = command.value.duration or 0.5
                local intensity = command.value.intensity or 1

                local shakeConfig = require(script.Parent.Tool.Shake).GetPreset(shakePreset)
                shakeConfig.Magnitude *= intensity
                shakeConfig.FadeOutTime = duration

                local shaker = require(script.Parent.Tool.Shake).new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
                    context.camera.CFrame *= shakeCFrame
                end)

                shaker:ShakeOnce(shakeConfig)
            end

        elseif command.type == DialogueModule.CommandTypes.PLAY_ANIMATION then
            if context.services.Animation and context.character then
                local animationType = command.value.type or "TALK"
                local duration = command.value.duration
                local looping = command.value.looping or false

                context.services.Animation:PlayAnimation(context.character, {
                    preset = animationType,
                    looped = looping,
                    duration = duration
                })
            end

        elseif command.type == DialogueModule.CommandTypes.PLAY_EFFECT then
            if context.services.Particle and context.character then
                local config = {
                    preset = command.value.type,
                    duration = command.value.duration or 1,
                    position = context.character.PrimaryPart and context.character.PrimaryPart.Position
                }

                context.services.Particle:CreateEffect(context.character, config)
            end

        elseif command.type == DialogueModule.CommandTypes.FACE_DIRECTION then
            if context.character then
                local target = command.value.target or DialogueModule.FacingTarget.PLAYER
                local behavior = command.value.behavior or {}
                local offsetAngle = behavior.offsetAngle or 0
                local rotationSpeed = behavior.rotationSpeed or 10

                local function determineTargetPosition()
                    local characterRoot = context.character.PrimaryPart or context.character:FindFirstChild("HumanoidRootPart")
                    if not characterRoot then return nil end

                    if target == DialogueModule.FacingTarget.PLAYER then
                        local playerRoot = context.player and context.player.Character
                            and context.player.Character:FindFirstChild("HumanoidRootPart")
                        return playerRoot and playerRoot.Position

                    elseif target == DialogueModule.FacingTarget.OBJECT then
                        local targetObject = command.value.value
                        return targetObject and (targetObject.PrimaryPart or targetObject).Position

                    elseif target == DialogueModule.FacingTarget.POINT then
                        return command.value.value

                    elseif target == DialogueModule.FacingTarget.DIRECTION then
                        local directionVector = command.value.value or DialogueModule.DirectionPreset.NORTH
                        return characterRoot.Position + directionVector * 10

                    elseif target == DialogueModule.FacingTarget.AWAY then
                        local playerRoot = context.player and context.player.Character
                            and context.player.Character:FindFirstChild("HumanoidRootPart")
                        return playerRoot and 
                            characterRoot.Position * 2 - playerRoot.Position
                    end
                end

                local targetPosition = determineTargetPosition()
                if targetPosition then
                    local characterRoot = context.character.PrimaryPart or context.character:FindFirstChild("HumanoidRootPart")

                    if offsetAngle ~= 0 then
                        local rotationMatrix = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(offsetAngle))
                        local offsetDirection = (rotationMatrix * (targetPosition - characterRoot.Position).Unit)
                        targetPosition = characterRoot.Position + offsetDirection * (targetPosition - characterRoot.Position).Magnitude
                    end

                    local newCFrame = CFrame.lookAt(
                        characterRoot.Position,
                        Vector3.new(targetPosition.X, characterRoot.Position.Y, targetPosition.Z)
                    )
                    characterRoot.CFrame = newCFrame
                end
            end

        elseif command.type == DialogueModule.CommandTypes.INTERRUPT_ENABLE then
            if context.character then
                local currentLine = context.currentLine
                if currentLine then
                    currentLine.interruptible = true
                    if command.value and command.value.response then
                        currentLine.interruptResponse = command.value.response
                    end
                end
            end

        elseif command.type == DialogueModule.CommandTypes.INTERRUPT_DISABLE then
            if context.character then
                local currentLine = context.currentLine
                if currentLine then
                    currentLine.interruptible = false
                    currentLine.interruptResponse = nil
                end
            end

        elseif command.type == DialogueModule.CommandTypes.TIMING_CONTROL then
            if context.character then
                local currentLine = context.currentLine
                if currentLine then
                    if command.value.preset then
                        currentLine.timing = DialogueModule.TimingPresets[command.value.preset:upper()]
                    else
                        currentLine.timing = {
                            minResponseTime = command.value.minTime,
                            maxResponseTime = command.value.maxTime,
                            idealResponseTime = command.value.idealTime
                        }
                    end
                end
            end
        end
    end

    return processedText
end

function DialogueModule.CheckRequirements(requirements: {[string]: any}, playerState: {[string]: any}): boolean
    if not requirements then return true end

    for key, value in pairs(requirements) do
        local playerValue = playerState[key]
        if playerValue == nil or playerValue < value then
            return false
        end
    end

    return true
end

function DialogueModule.ProcessEffects(effects: {DialogueEffect}, context: {
    player: Player?,
    world: any?,
    services: {[string]: any}?,
    npcId: string?
}): boolean
    if not effects or not context.services then return false end

    for _, effect in ipairs(effects) do
        if effect.type == DialogueModule.EffectTypes.REPUTATION then
            if context.services.Memory then
                if effect.target == "*" and context.npcId then
                    context.services.Memory:UpdateReputation(context.player, context.npcId, effect.value)
                else
                    context.services.Memory:UpdateReputation(context.player, effect.target, effect.value)
                end
            end
        elseif effect.type == DialogueModule.EffectTypes.RELATIONSHIP then
            if context.services.Memory then
                if effect.target == "*" and context.npcId then
                    context.services.Memory:UpdateEmotion(context.player, context.npcId, "TRUST", effect.value)
                else
                    context.services.Memory:UpdateEmotion(context.player, effect.target, "TRUST", effect.value)
                end
            end
        elseif effect.type == DialogueModule.EffectTypes.QUEST then
            if context.services.Quest then
                if effect.value == true then
                    context.services.Quest:StartQuest(context.player, effect.target)
                elseif effect.value == false then
                    context.services.Quest:EndQuest(context.player, effect.target)
                end
            end
        elseif effect.type == DialogueModule.EffectTypes.ITEM then
            if context.services.Inventory then
                if tonumber(effect.value) > 0 then
                    context.services.Inventory:AddItem(context.player, effect.target, effect.value)
                else
                    context.services.Inventory:RemoveItem(context.player, effect.target, math.abs(effect.value))
                end
            end
        elseif effect.type == DialogueModule.EffectTypes.STAT then
            if context.services.Stat then
                context.services.Stat:ModifyStat(context.player, effect.target, effect.value)
            end
        elseif effect.type == DialogueModule.EffectTypes.FLAG then
            if context.services.Flag then
                context.services.Flag:SetFlag(context.player, effect.target, effect.value)
            end
        elseif effect.type == DialogueModule.EffectTypes.WORLD_STATE then
            if context.world and context.world.SetState then
                context.world:SetState(effect.target, effect.value)
            end
        elseif effect.type == DialogueModule.EffectTypes.PATIENCE then
            if context.services.Memory then
                local value = effect.value
                if type(value) == "string" then
                    local timing = context.timing
                    if timing then
                        local responseTime = timing.responseTime or 0
                        local idealTime = timing.idealTime or 4
                        local deviation = math.abs(responseTime - idealTime)

                        if value == "reward" then
                            value = math.max(0, 5 - deviation)
                        elseif value == "penalty" then
                            value = -math.min(10, deviation)
                        end
                    end
                end

                context.services.Memory:UpdateEmotion(
                    context.player,
                    effect.target,
                    "TRUST",
                    value
                )
            end

        elseif effect.type == DialogueModule.EffectTypes.ATTENTION then
            if context.services.Memory then
                local attentionScore = context.attentionScore or 0
                local value = effect.value

                if type(value) == "string" then
                    if value == "scale" then
                        value = attentionScore * 2
                    elseif value == "threshold" then
                        value = attentionScore >= 5 and 10 or -5
                    end
                end

                context.services.Memory:UpdateEmotion(
                    context.player,
                    effect.target,
                    "TRUST",
                    value
                )
            end
        elseif effect.type == DialogueModule.EffectTypes.FACTION_STANDING then
            if context.services.Memory then
                context.services.Memory:UpdateReputation(
                    context.player,
                    effect.target,
                    effect.value
                )
            end
        elseif effect.type == DialogueModule.EffectTypes.FACTION_RELATIONSHIP then
            if context.services.Faction then
                local factions = effect.target:split(":")
                if #factions == 2 then
                    context.services.Faction:UpdateRelationship(
                        factions[1],
                        factions[2],
                        effect.value
                    )
                end
            end
        elseif effect.type == DialogueModule.EffectTypes.DIPLOMATIC_INFLUENCE then
            if context.services.Memory then
                if type(effect.value) == "table" and effect.target == "ALL_FACTIONS" then
                    for factionId, standingChange in pairs(effect.value) do
                        context.services.Memory:UpdateReputation(
                            context.player,
                            factionId,
                            standingChange
                        )
                    end
                end
            end
        elseif effect.type == DialogueModule.EffectTypes.CONFLICT_RESOLUTION then
            if context.services.Faction and context.services.World then
                local conflictId = effect.target
                local resolution = effect.value

                context.services.World:SetState("conflict_" .. conflictId, resolution)

                context.services.Faction:ResolveConflict(conflictId, resolution)
            end
        elseif effect.type == DialogueModule.EffectTypes.GLOBAL_REPUTATION then
            if context.services.Memory then
                context.services.Memory:UpdateReputation(context.player, effect.target, effect.value)
            end
        end
    end

    return true
end

function DialogueModule.ProcessConsequences(consequences: DialogueConsequence, context: {
    player: Player?,
    world: any?,
    services: {[string]: any}?,
    npcId: string?
})
    if not consequences then return end

    if consequences.immediate then
        DialogueModule.ProcessEffects(consequences.immediate, context)
    end

    if consequences.delayed then
        task.delay(5, function()
            DialogueModule.ProcessEffects(consequences.delayed, context)
        end)
    end

    if consequences.permanent then
        DialogueModule.ProcessEffects(consequences.permanent, context)
    end
end

function DialogueModule.GetResponsesByCategory(responses: {DialogueResponse}, tree: DialogueTree): {{DialogueResponse}}
    if not responses then return {} end

    local categorizedResponses = {}
    local uncategorizedResponses = {}

    for _, response in ipairs(responses) do
        if response.category and tree.categories and tree.categories[response.category] then
            local category = tree.categories[response.category]
            categorizedResponses[response.category] = categorizedResponses[response.category] or {
                name = category.name,
                description = category.description,
                color = category.color,
                icon = category.icon,
                responses = {}
            }
            table.insert(categorizedResponses[response.category].responses, response)
        else
            table.insert(uncategorizedResponses, response)
        end
    end

    for _, category in pairs(categorizedResponses) do
        table.sort(category.responses, function(a, b)
            return (a.priority or 0) > (b.priority or 0)
        end)
    end

    if #uncategorizedResponses > 0 then
        categorizedResponses["UNCATEGORIZED"] = {
            name = "Other",
            description = "Additional dialogue options",
            color = Color3.fromRGB(200, 200, 200),
            responses = uncategorizedResponses
        }
    end

    return categorizedResponses
end

function DialogueModule.GetReturn(line: DialogueLine, tree: DialogueTree): string?
    if not line or not tree then return nil end

    if line.returnPoint then
        return line.returnPoint
    end

    if line.contextual then
        for lineId, otherLine in pairs(tree.lines) do
            if otherLine.responses then
                for _, response in ipairs(otherLine.responses) do
                    if response.nextDialogueId == line.id then
                        return lineId
                    end
                end
            end
        end
    end

    return nil
end

--[[ Emotional Processing Functions ]]
function DialogueModule.GetEmotionalState(relationshipValue: number): string
    local currentState = "NEUTRAL"
    local highestThreshold = -math.huge
    
    for state, config in pairs(DialogueModule.EmotionalStates) do
        if config.threshold <= relationshipValue and config.threshold > highestThreshold then
            currentState = state
            highestThreshold = config.threshold
        end
    end
    
    return currentState
end

function DialogueModule.GetEmotionalResponse(state: string, context: {
    isFirstInteraction: boolean?,
    lastInteractionTime: number?,
    hasApologized: boolean?,
    relationshipTrend: string?,
    emotion: number?
}): string
    local stateConfig = DialogueModule.EmotionalStates[state]
    if not stateConfig or not stateConfig.reactions then return nil end

    local reactions = stateConfig.reactions
    local responsePool = nil

    if state == "BETRAYED" then
        if context.hasApologized then
            responsePool = reactions.FORGIVING
        elseif context.isFirstInteraction then
            responsePool = reactions.INITIAL
        else
            responsePool = reactions.PERSISTENT
        end
    elseif state == "DISTRUSTFUL" then
        if context.relationshipTrend == "IMPROVING" then
            responsePool = reactions.IMPROVING
        elseif context.isFirstInteraction then
            responsePool = reactions.INITIAL
        else
            responsePool = reactions.PERSISTENT
        end
    elseif state == "FRIENDLY" or state == "DEVOTED" then
        if context.lastInteractionTime and os.time() - context.lastInteractionTime > 86400 then
            responsePool = reactions.GREETING
        else
            responsePool = reactions.FAVOR
        end
    end

    if responsePool then
        return responsePool[math.random(#responsePool)]
    end
    return nil
end

function DialogueModule.ProcessEmotionalTrigger(trigger: string, context: {
    player: Player?,
    npc: string?,
    services: {[string]: any}?,
    metadata: {[string]: any}?
}): boolean
    local triggerConfig = DialogueModule.EmotionalTriggers[trigger]
    if not triggerConfig then return false end

    if triggerConfig.requirements then
        local req = triggerConfig.requirements
        if req.minRelationship or req.maxRelationship then
            local currentRelationship = context.services.Relationship:GetRelationship(context.player, context.npc)
            if (req.minRelationship and currentRelationship < req.minRelationship) or
               (req.maxRelationship and currentRelationship > req.maxRelationship) then
                return false
            end
        end

        if req.timeElapsed and context.metadata.lastTriggerTime then
            if os.time() - context.metadata.lastTriggerTime < req.timeElapsed then
                return false
            end
        end
    end

    if triggerConfig.reactions.immediate then
        DialogueModule.ProcessEffects(triggerConfig.reactions.immediate.effects, context)
    end

    if triggerConfig.reactions.delayed then
        task.delay(5, function()
            DialogueModule.ProcessEffects(triggerConfig.reactions.delayed.effects, context)
        end)
    end

    return true
end

return DialogueModule