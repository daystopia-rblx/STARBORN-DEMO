--[[ GuardDialogue
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-13
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogueModule = require(ReplicatedStorage.Modules.DialogueModule)

local guardArrestDialogue = {
    id = "guard_arrest_dialogue",
    title = "Guard Arrest",
    description = "Dialogue when a guard attempts to arrest a player with bounty",
    startingLine = "arrest_greeting",
    lines = {
        arrest_greeting = {
            id = "arrest_greeting",
            speaker = "Guard",
            text = "Wait, I know you... You have a bounty in this region.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "bounty in this region"}},
                {type = "face_direction", value = {target = "PLAYER"}}
            },
            responses = {
                {text = "I'll pay my bounty", nextDialogueId = "arrest_pay_bounty", category = "MAIN"},
                {text = "I'll come quietly", nextDialogueId = "arrest_surrender", category = "MAIN"},
                {text = "I don't have time for this", nextDialogueId = "arrest_resist", category = "AGGRESSIVE"}
            }
        },

        arrest_pay_bounty = {
            id = "arrest_pay_bounty",
            speaker = "Guard",
            text = "A wise choice. Your bounty amounts to {BOUNTY_AMOUNT} umbrels. Pay it, and you're free to go.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "{BOUNTY_AMOUNT} umbrels"}}
            },
            responses = {
                {text = "Here's your umbrels", nextDialogueId = "arrest_bounty_paid", metadata = {action = "PAY_BOUNTY"}},
                {text = "I don't have enough umbrels", nextDialogueId = "arrest_insufficient_funds"}
            }
        },

        arrest_bounty_paid = {
            id = "arrest_bounty_paid",
            speaker = "Guard",
            text = "Your debt to society is paid. Stay out of trouble, citizen.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "debt to society is paid"}}
            },
            effects = {
                {type = "reputation", target = "GUARD_FACTION", value = 2}
            },
            responses = {
                {text = "Thank you, officer", nextDialogueId = nil}
            }
        },

        arrest_insufficient_funds = {
            id = "arrest_insufficient_funds",
            speaker = "Guard",
            text = "No umbrels, no freedom. Looks like you're headed to jail then.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "headed to jail"}}
            },
            responses = {
                {text = "I'll come quietly", nextDialogueId = "arrest_surrender"},
                {text = "I'd rather resist", nextDialogueId = "arrest_resist", category = "AGGRESSIVE"}
            }
        },

        arrest_surrender = {
            id = "arrest_surrender",
            speaker = "Guard",
            text = "At least you know when you're beaten. To jail with you. You'll serve your time according to your crimes.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "serve your time"}}
            },
            effects = {
                {type = "jail", target = "player", value = "STANDARD"},
                {type = "reputation", target = "GUARD_FACTION", value = -5}
            },
            responses = {
                {text = "Lead the way", nextDialogueId = nil}
            }
        },

        arrest_resist = {
            id = "arrest_resist",
            speaker = "Guard",
            text = "Then pay with your blood! Guards, to arms!",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "pay with your blood"}},
                {type = "text_shake", value = {intensity = 0.7, text = "Guards, to arms!"}},
                {type = "play_sound", value = {sound = "guard_alert"}}
            },
            effects = {
                {type = "faction_violation", target = "GUARD_FACTION", value = "RESIST_ARREST"},
                {type = "reputation", target = "GUARD_FACTION", value = -20}
            },
            responses = {
                {text = "Defend yourself", nextDialogueId = nil, metadata = {action = "INITIATE_COMBAT"}}
            }
        }
    },
    categories = {
        MAIN = DialogueModule.Categories.MAIN,
        AGGRESSIVE = DialogueModule.Categories.AGGRESSIVE
    },
    metadata = {
        guardDialogue = true,
        dialogueType = "arrest"
    }
}

local guardCrimeWitnessDialogue = {
    id = "guard_crime_witness_dialogue",
    title = "Guard Crime Witness",
    description = "Dialogue when a guard witnesses a crime",
    startingLine = "witness_greeting",
    lines = {
        witness_greeting = {
            id = "witness_greeting",
            speaker = "Guard",
            text = "Stop right there, criminal scum! I saw what you just did!",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "criminal scum"}},
                {type = "text_shake", value = {intensity = 0.5, text = "Stop right there"}},
                {type = "face_direction", value = {target = "PLAYER"}}
            },
            responses = {
                {text = "I'll pay for my crime", nextDialogueId = "witness_pay_fine", category = "MAIN"},
                {text = "It wasn't me!", nextDialogueId = "witness_deny", category = "MAIN"},
                {text = "I don't have time for this", nextDialogueId = "witness_resist", category = "AGGRESSIVE"}
            }
        },

        witness_pay_fine = {
            id = "witness_pay_fine",
            speaker = "Guard",
            text = "At least you admit it. Your fine is {CRIME_FINE} umbrels. Pay it now.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "{CRIME_FINE} umbrels"}}
            },
            responses = {
                {text = "Here's your umbrels", nextDialogueId = "witness_fine_paid", metadata = {action = "PAY_FINE"}},
                {text = "I don't have enough umbrels", nextDialogueId = "witness_insufficient_funds"}
            }
        },

        witness_fine_paid = {
            id = "witness_fine_paid",
            speaker = "Guard",
            text = "Fine paid. Don't let me catch you doing that again.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "Fine paid"}}
            },
            effects = {
                {type = "reputation", target = "GUARD_FACTION", value = -5}
            },
            responses = {
                {text = "It won't happen again", nextDialogueId = nil}
            }
        },

        witness_deny = {
            id = "witness_deny",
            speaker = "Guard",
            text = "Don't play dumb with me. I saw you with my own eyes! Pay the fine or go to jail.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "saw you with my own eyes"}}
            },
            responses = {
                {text = "I'll pay the fine", nextDialogueId = "witness_pay_fine"},
                {text = "I'll go to jail", nextDialogueId = "witness_surrender"},
                {text = "I'd rather resist", nextDialogueId = "witness_resist", category = "AGGRESSIVE"}
            }
        },

        witness_insufficient_funds = {
            id = "witness_insufficient_funds",
            speaker = "Guard",
            text = "No umbrels? Then it's off to jail with you.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "off to jail"}}
            },
            responses = {
                {text = "I'll come quietly", nextDialogueId = "witness_surrender"},
                {text = "I'd rather resist", nextDialogueId = "witness_resist", category = "AGGRESSIVE"}
            }
        },

        witness_surrender = {
            id = "witness_surrender",
            speaker = "Guard",
            text = "A wise choice. To jail with you, criminal.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "To jail"}}
            },
            effects = {
                {type = "jail", target = "player", value = "STANDARD"},
                {type = "reputation", target = "GUARD_FACTION", value = -10}
            },
            responses = {
                {text = "Lead the way", nextDialogueId = nil}
            }
        },

        witness_resist = {
            id = "witness_resist",
            speaker = "Guard",
            text = "You dare resist arrest? Guards, we have a criminal here!",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "resist arrest"}},
                {type = "text_shake", value = {intensity = 0.7, text = "Guards, we have a criminal here!"}},
                {type = "play_sound", value = {sound = "guard_alert"}}
            },
            effects = {
                {type = "faction_violation", target = "GUARD_FACTION", value = "RESIST_ARREST"},
                {type = "reputation", target = "GUARD_FACTION", value = -25}
            },
            responses = {
                {text = "Defend yourself", nextDialogueId = nil, metadata = {action = "INITIATE_COMBAT"}}
            }
        }
    },
    categories = {
        MAIN = DialogueModule.Categories.MAIN,
        AGGRESSIVE = DialogueModule.Categories.AGGRESSIVE
    },
    metadata = {
        guardDialogue = true,
        dialogueType = "witness"
    }
}

local guardRegularDialogue = {
    id = "guard_regular_dialogue",
    title = "Guard Regular Dialogue",
    description = "Regular dialogue with guards when player has no bounty",
    startingLine = "regular_greeting",
    lines = {
        regular_greeting = {
            id = "regular_greeting",
            speaker = "Guard",
            text = "Citizen.",
            commands = {
                {type = "face_direction", value = {target = "PLAYER"}}
            },
            responses = {
                {text = "How are things in the city?", nextDialogueId = "regular_city_info", category = "MAIN"},
                {text = "Good day", nextDialogueId = nil}
            }
        },

        regular_city_info = {
            id = "regular_city_info",
            speaker = "Guard",
            text = "Quiet enough, though we've had reports of {RECENT_CRIME_TYPE} in the {CITY_DISTRICT} district. Keep your wits about you.",
            responses = {
                {text = "I'll be careful", nextDialogueId = "regular_farewell"},
                {text = "Any criminals I should watch for?", nextDialogueId = "regular_criminals_info"}
            }
        },

        regular_criminals_info = {
            id = "regular_criminals_info",
            speaker = "Guard",
            text = "We've got bounties out for several troublemakers. Check the notice board by the barracks if you're interested in hunting them down.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "notice board"}}
            },
            responses = {
                {text = "I might do that", nextDialogueId = "regular_farewell"}
            }
        },

        regular_farewell = {
            id = "regular_farewell",
            speaker = "Guard",
            text = "Stay safe, citizen.",
            responses = {
                {text = "Farewell", nextDialogueId = nil}
            }
        }
    },
    categories = {
        MAIN = DialogueModule.Categories.MAIN
    },
    metadata = {
        guardDialogue = true,
        dialogueType = "regular"
    }
}

local guardHighReputationDialogue = {
    id = "guard_high_reputation_dialogue",
    title = "Guard High Reputation Dialogue",
    description = "Dialogue with guards when player has high reputation with their faction",
    startingLine = "high_rep_greeting",
    lines = {
        high_rep_greeting = {
            id = "high_rep_greeting",
            speaker = "Guard",
            text = "Good to see you, {PLAYER_NAME}. Your reputation precedes you.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "reputation precedes you"}},
                {type = "face_direction", value = {target = "PLAYER"}}
            },
            responses = {
                {text = "How are things in the city?", nextDialogueId = "high_rep_city_info", category = "MAIN"},
                {text = "Any special assignments?", nextDialogueId = "high_rep_assignments", category = "MAIN"},
                {text = "Good day", nextDialogueId = nil}
            }
        },

        high_rep_city_info = {
            id = "high_rep_city_info",
            speaker = "Guard",
            text = "For you? I can share that we're investigating {ONGOING_INVESTIGATION}. Keep it to yourself, though.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.EMPHASIS, text = "{ONGOING_INVESTIGATION}"}}
            },
            responses = {
                {text = "I appreciate the trust", nextDialogueId = "high_rep_farewell"}
            }
        },

        high_rep_assignments = {
            id = "high_rep_assignments",
            speaker = "Guard",
            text = "Nothing official, but the captain might have something. He's been looking for trustworthy individuals for some... sensitive matters.",
            responses = {
                {text = "I'll speak with him", nextDialogueId = "high_rep_farewell"}
            }
        },

        high_rep_farewell = {
            id = "high_rep_farewell",
            speaker = "Guard",
            text = "Always a pleasure, {PLAYER_NAME}. Stay vigilant out there.",
            responses = {
                {text = "Farewell", nextDialogueId = nil}
            }
        }
    },
    categories = {
        MAIN = DialogueModule.Categories.MAIN
    },
    metadata = {
        guardDialogue = true,
        dialogueType = "high_reputation",
        reputationThreshold = 50
    }
}

local guardBribeDialogue = {
    id = "guard_bribe_dialogue",
    title = "Guard Bribe Dialogue",
    description = "Dialogue for attempting to bribe a guard",
    startingLine = "bribe_offer",
    lines = {
        bribe_offer = {
            id = "bribe_offer",
            speaker = "Guard",
            text = "Are you trying to bribe an officer of the law? Think carefully about your answer.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "bribe an officer"}},
                {type = "face_direction", value = {target = "PLAYER"}}
            },
            responses = {
                {text = "Just a gift among friends (50 umbrels)", nextDialogueId = "bribe_small", metadata = {action = "BRIBE", amount = 50}},
                {text = "For your troubles (100 umbrels)", nextDialogueId = "bribe_medium", metadata = {action = "BRIBE", amount = 100}},
                {text = "A substantial donation (200 umbrels)", nextDialogueId = "bribe_large", metadata = {action = "BRIBE", amount = 200}},
                {text = "No, of course not", nextDialogueId = "bribe_decline"}
            }
        },

        bribe_small = {
            id = "bribe_small",
            speaker = "Guard",
            text = "This isn't enough to risk my position. Consider this a warning - don't try to bribe guards.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "warning"}}
            },
            effects = {
                {type = "reputation", target = "GUARD_FACTION", value = -5}
            },
            responses = {
                {text = "My mistake", nextDialogueId = nil}
            }
        },

        bribe_medium = {
            id = "bribe_medium",
            speaker = "Guard",
            text = "{GUARD_BRIBE_RESPONSE}",
            metadata = {
                conditionalDialogue = true,
                conditions = {
                    {
                        check = "GUARD_CORRUPTIBILITY",
                        threshold = 30,
                        dialogue = "Perhaps I could look the other way... just this once.",
                        success = true
                    },
                    {
                        check = "GUARD_CORRUPTIBILITY",
                        threshold = 30,
                        dialogue = "Attempting to bribe a guard is itself a crime! This won't go well for you.",
                        success = false
                    }
                }
            },
            responses = {
                {
                    text = "Thank you for understanding",
                    nextDialogueId = "bribe_success",
                    requirements = {BRIBE_SUCCESS = true}
                },
                {
                    text = "It was just a misunderstanding",
                    nextDialogueId = "bribe_failed",
                    requirements = {BRIBE_SUCCESS = false}
                }
            }
        },

        bribe_large = {
            id = "bribe_large",
            speaker = "Guard",
            text = "{GUARD_BRIBE_RESPONSE}",
            metadata = {
                conditionalDialogue = true,
                conditions = {
                    {
                        check = "GUARD_CORRUPTIBILITY",
                        threshold = 10,
                        dialogue = "Consider your small... infraction... forgotten. I didn't see anything.",
                        success = true
                    },
                    {
                        check = "GUARD_CORRUPTIBILITY",
                        threshold = 10,
                        dialogue = "That's a serious crime you're committing right now. I'm going to have to take you in.",
                        success = false
                    }
                }
            },
            responses = {
                {
                    text = "Pleasure doing business",
                    nextDialogueId = "bribe_success",
                    requirements = {BRIBE_SUCCESS = true}
                },
                {
                    text = "Wait, I didn't mean-",
                    nextDialogueId = "bribe_failed",
                    requirements = {BRIBE_SUCCESS = false}
                }
            }
        },

        bribe_success = {
            id = "bribe_success",
            speaker = "Guard",
            text = "Move along now. And don't mention this to anyone.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.SUCCESS, text = "Move along"}}
            },
            effects = {
                {type = "flag", target = "BRIBED_GUARD", value = true},
                {type = "reputation", target = "GUARD_FACTION", value = -10}
            },
            responses = {
                {text = "Farewell", nextDialogueId = nil}
            }
        },

        bribe_failed = {
            id = "bribe_failed",
            speaker = "Guard",
            text = "Attempting to bribe a guard is a crime. Your bounty has been increased.",
            commands = {
                {type = "text_color", value = {color = DialogueModule.TextColorPresets.WARNING, text = "crime"}}
            },
            effects = {
                {type = "bounty", target = "player", value = 100},
                {type = "reputation", target = "GUARD_FACTION", value = -20}
            },
            responses = {
                {text = "I'm sorry", nextDialogueId = nil}
            }
        },

        bribe_decline = {
            id = "bribe_decline",
            speaker = "Guard",
            text = "Good. Make sure it stays that way. We take our duty seriously here.",
            responses = {
                {text = "Of course", nextDialogueId = nil}
            }
        }
    },
    categories = {
        MAIN = DialogueModule.Categories.MAIN
    },
    metadata = {
        guardDialogue = true,
        dialogueType = "bribe"
    }
}

return {
    ["guard_arrest_dialogue"] = guardArrestDialogue,
    ["guard_crime_witness_dialogue"] = guardCrimeWitnessDialogue,
    ["guard_regular_dialogue"] = guardRegularDialogue,
    ["guard_high_reputation_dialogue"] = guardHighReputationDialogue,
    ["guard_bribe_dialogue"] = guardBribeDialogue
} 