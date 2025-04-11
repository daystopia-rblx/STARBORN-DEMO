--[[ AwakenerDialogue
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueModule = require(ReplicatedStorage.Modules.DialogueModule)

local awakenerRebirthDialogue = {
    id = "awakener_rebirth_dialogue",
    title = "The Awakener",
    description = "Dialogue with the mysterious entity guiding souls through their Awakenings",
    startingLine = "awakening_greeting",
    lines = {
        awakening_greeting = {
            id = "awakening_greeting",
            speaker = "The Awakener",
            text = "Your soul returns once more. This marks your {CYCLE_COUNT} Awakening.",
            animation = "gesture_point",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "{CYCLE_COUNT} Awakening"}},
                {type = "play_effect", value = {type = "rebirth", duration = 2}}
            },
            responses = {
                {text = "What happened to me?", nextDialogueId = "awakening_explanation"},
                {text = "I remember dying...", nextDialogueId = "awakening_memory"},
                {text = "Send me back quickly", nextDialogueId = "awakening_hasty", category = "AGGRESSIVE"}
            }
        },

        awakening_explanation = {
            id = "awakening_explanation",
            speaker = "The Awakener",
            text = "Death is merely a threshold in Ascendium. Your physical form may perish, but your soul persists, growing stronger with each Awakening.",
            animation = "raise_hands",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "Death is merely a threshold"}},
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "growing stronger with each Awakening"}}
            },
            responses = {
                {text = "What did I lose?", nextDialogueId = "awakening_loss"},
                {text = "I'm ready to return", nextDialogueId = "awakening_return"}
            }
        },

        awakening_memory = {
            id = "awakening_memory",
            speaker = "The Awakener",
            text = "Memory is the one treasure that transcends death. Hold onto what you've learned; it is your path to Ascension.",
            animation = "whisper",
            commands = {
                {type = "text_wave", value = {amplitude = 0.3, frequency = 1, text = "Memory is the one treasure"}},
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "path to Ascension"}}
            },
            responses = {
                {text = "Will I ever break this cycle?", nextDialogueId = "awakening_cycle"},
                {text = "I'm ready to return", nextDialogueId = "awakening_return"}
            }
        },

        awakening_loss = {
            id = "awakening_loss",
            speaker = "The Awakener",
            text = "Your material possessions are scattered, your physical progress reset. But knowledge remains, and the bonds you've forged endure, if weakened.",
            animation = "gesture_point",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "material possessions are scattered"}},
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "knowledge remains"}}
            },
            responses = {
                {text = "I'm ready to return", nextDialogueId = "awakening_return"}
            }
        },

        awakening_cycle = {
            id = "awakening_cycle",
            speaker = "The Awakener",
            text = "The cycle continues until you achieve Ascension. Few have managed this feat across the ages. Will you be among them?",
            animation = "raise_hands",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "Ascension"}},
                {type = "play_effect", value = {type = "starlight", duration = 1.5}}
            },
            responses = {
                {text = "I will find a way", nextDialogueId = "awakening_determination", category = "MAIN"},
                {text = "I'm ready to return", nextDialogueId = "awakening_return"}
            }
        },

        awakening_determination = {
            id = "awakening_determination",
            speaker = "The Awakener",
            text = "Determination... interesting. Perhaps your soul carries more potential than I first perceived.",
            animation = "curious",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "Determination... interesting"}},
                {type = "text_speed", value = {speed = 0.8}}
            },
            effects = {
                {type = "reputation", target = "AWAKENER", value = 5}
            },
            responses = {
                {text = "I'm ready to return", nextDialogueId = "awakening_return_special"}
            }
        },

        awakening_hasty = {
            id = "awakening_hasty",
            speaker = "The Awakener",
            text = "Impatience will not serve you in Ascendium. The cycle demands reflection.",
            animation = "shake_head",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "Impatience will not serve you"}},
                {type = "text_shake", value = {intensity = 0.5, text = "demands reflection"}}
            },
            effects = {
                {type = "reputation", target = "AWAKENER", value = -2}
            },
            responses = {
                {text = "Fine. Send me back", nextDialogueId = "awakening_return_hasty"}
            }
        },

        awakening_return = {
            id = "awakening_return",
            speaker = "The Awakener",
            text = "May your next journey bring you closer to understanding. Return now to the world of the living.",
            animation = "gesture_point",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "closer to understanding"}},
                {type = "play_effect", value = {type = "awakening", duration = 3}}
            },
            effects = {
                {type = "respawn", target = "player", duration = 3}
            },
            responses = {
                {text = "I am ready", nextDialogueId = nil}
            }
        },

        awakening_return_special = {
            id = "awakening_return_special",
            speaker = "The Awakener",
            text = "I shall watch your progress with interest. Return now, with a fragment of my guidance.",
            animation = "raise_hands",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "fragment of my guidance"}},
                {type = "play_effect", value = {type = "awakening_special", duration = 3}}
            },
            effects = {
                {type = "respawn", target = "player", value = "AWAKENER_BLESSING", duration = 3},
                {type = "item", target = "MEMORY_FRAGMENT", value = 1}
            },
            responses = {
                {text = "I am ready", nextDialogueId = nil}
            }
        },

        awakening_return_hasty = {
            id = "awakening_return_hasty",
            speaker = "The Awakener",
            text = "So be it. Return to your trials, unenlightened.",
            animation = "dismissive",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "unenlightened"}},
                {type = "play_effect", value = {type = "awakening_hasty", duration = 2}}
            },
            effects = {
                {type = "respawn", target = "player", duration = 2}
            },
            responses = {
                {text = "...", nextDialogueId = nil}
            }
        }
    },
    categories = {
        MAIN = DialogueModule.Categories.MAIN,
        AGGRESSIVE = DialogueModule.Categories.AGGRESSIVE,
        LORE = DialogueModule.Categories.LORE
    },
    metadata = {
        awakenerDialogue = true,
        dialogueType = "awakening"
    }
}

local awakenerRecurringDialogue = {
    id = "awakener_recurring_dialogue",
    title = "The Awakener",
    description = "Brief dialogue for frequent respawns",
    startingLine = "recurring_greeting",
    lines = {
        recurring_greeting = {
            id = "recurring_greeting",
            speaker = "The Awakener",
            text = "Once more the cycle claims you. What will you learn this time?",
            animation = "gesture_point",
            commands = {
                {type = "play_effect", value = {type = "rebirth_quick", duration = 1}}
            },
            responses = {
                {text = "Send me back", nextDialogueId = "recurring_return"},
                {text = "I need more guidance", nextDialogueId = "recurring_guidance", category = "LORE"}
            }
        },

        recurring_guidance = {
            id = "recurring_guidance",
            speaker = "The Awakener",
            text = "Remember: death is not the end, but an opportunity to reflect. Seek the Invocations; they are your path to power.",
            animation = "whisper",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "Invocations"}},
                {type = "text_wave", value = {amplitude = 0.3, frequency = 1, text = "path to power"}}
            },
            responses = {
                {text = "I understand", nextDialogueId = "recurring_return"}
            }
        },

        recurring_return = {
            id = "recurring_return",
            speaker = "The Awakener",
            text = "Return and face your trials with newfound wisdom.",
            animation = "gesture_point",
            commands = {
                {type = "play_effect", value = {type = "awakening_quick", duration = 2}}
            },
            effects = {
                {type = "respawn", target = "player", duration = 2}
            },
            responses = {
                {text = "I am ready", nextDialogueId = nil}
            }
        }
    },
    categories = {
        LORE = DialogueModule.Categories.LORE
    },
    metadata = {
        awakenerDialogue = true,
        dialogueType = "recurring"
    }
}

return {
    ["awakener_rebirth_dialogue"] = awakenerRebirthDialogue,
    ["awakener_recurring_dialogue"] = awakenerRecurringDialogue
}