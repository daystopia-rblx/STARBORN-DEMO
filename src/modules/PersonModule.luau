--[[ PersonModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local PersonModule = {}

function PersonModule.GetPerson(name: string)
    name = name:upper()
    if PersonModule.Templates[name] then return PersonModule.Templates[name] end
    for _, category in pairs(PersonModule.Templates) do
        if category[name] then return category[name] end
    end
    return nil
end

function PersonModule.GetDialogue(personType: string, variant: string?, dialogueType: string, subType: string): {string}
    local template = PersonModule.Templates[personType:upper()]
    if not template then return nil end

    local dialogue
    if variant and template.variants and template.variants[variant] then
        dialogue = template.variants[variant].dialogue
    end

    if not dialogue or not dialogue[dialogueType] or not dialogue[dialogueType][subType] then
        dialogue = template.defaults.dialogue
    end

    return dialogue and dialogue[dialogueType] and dialogue[dialogueType][subType]
end

function PersonModule.GetPersonality(personType: string, variant: string?): {[string]: any}
    local result = {}
    local stats = PersonModule.GetStats(personType, variant)

    result.trust = stats.TRUST or 0
    result.memoryDuration = stats.MEMORY_DURATION or 604800

    return result
end

function PersonModule.GetStats(personType: string, variant: string?): {[string]: number}
    local template = PersonModule.Templates[personType:upper()]
    if not template then return nil end

    local stats = table.clone(template.defaults.stats or {})

    if variant and template.variants and template.variants[variant] and template.variants[variant].stats then
        for key, value in pairs(template.variants[variant].stats) do
            stats[key] = value
        end
    end

    return stats
end

function PersonModule.CheckUnique(personType: string, variant: string?): boolean
    local template = PersonModule.Templates[personType:upper()]
    if not template then return false end

    if template.defaults.unique then return true end

    if variant and template.variants and template.variants[variant] then
        return template.variants[variant].unique or false
    end

    return false
end

PersonModule.Categories = {
    VILLAGER = "Villager",
    MERCHANT = "Merchant",
    GUARD = "Guard",
    NOBLE = "Noble",
    SCHOLAR = "Scholar",
    WARRIOR = "Warrior",
    UNIQUE = "Unique"
}

PersonModule.CategoryGroups = {
    CIVILIAN = {
        "VILLAGER",
        "MERCHANT",
        "SCHOLAR"
    },
    AUTHORITY = {
        "GUARD",
        "NOBLE"
    },
    COMBAT = {
        "WARRIOR"
    }
}

PersonModule.Templates = {
    VILLAGER = {
        defaults = {
            unique = false,
            dialogue = {
                apology = {
                    accepting = {"I appreciate your honesty. Perhaps we can move past this.", "Everyone makes mistakes. I'm willing to give you another chance.", "Your apology seems sincere. Let's start fresh."},
                    rejecting = {"Words alone cannot mend what you've done.", "I need more than just words to trust you again.", "Actions speak louder than words. Prove yourself first."}
                },
                greeting = {
                    friendly = {"Good to see you around!", "Welcome, friend!", "Always nice to have friendly faces about."},
                    hostile = {"What do you want?", "I have nothing to say to you.", "Best keep your distance."}
                }
            },
            stats = {HEALTH = 100, MANA = 50, STAMINA = 80, POSTURE = 75, SPEED = 14, DAMAGE = 5, TRUST = 0, MEMORY = 604800}
        },
        variants = {
            farmer = {
                name = "Farmer", description = "Works the land and tends to crops",
                dialogue = {apology = {accepting = {"Aye, the land teaches us forgiveness. I'll give ye another chance.", "Like a new season, we can start fresh.", "The fields don't hold grudges, neither will I."}}},
                stats = {HEALTH = 120, STAMINA = 100, POSTURE = 85}
            },
            baker = {
                name = "Baker", description = "Provides fresh bread and pastries",
                dialogue = {apology = {accepting = {"Sweet words like honey, but let's see if they're genuine.", "A fresh start, like a new batch of bread.", "I suppose everyone deserves a second chance to prove their worth."}}},
                stats = {HEALTH = 100, MANA = 60, STAMINA = 75}
            }
        }
    },
    MERCHANT = {
        defaults = {
            unique = false,
            dialogue = {
                apology = {
                    accepting = {"Business is business. Let's move forward.", "A wise merchant knows when to renegotiate terms.", "Trust can be rebuilt, like any good trade relationship."},
                    rejecting = {"Bad business is bad business. I won't forget.", "Trust, once broken, is costly to repair.", "My ledger remembers all debts, including trust."}
                },
                greeting = {
                    friendly = {"Welcome to my shop!", "Always good to see a valued customer!", "What can I interest you in today?"},
                    hostile = {"Buy something or leave.", "I reserve the right to refuse service.", "Your coin's no good here."}
                }
            },
            stats = {HEALTH = 90, MANA = 60, STAMINA = 70, POSTURE = 60, SPEED = 13, DAMAGE = 3, FORGIVENESS_THRESHOLD = 40, TRUST_GAIN_RATE = 1.2, TRUST_LOSS_RATE = 1.5, MEMORY = 1209600}
        },
        variants = {
            general = {
                name = "General Merchant", description = "Sells various everyday goods",
                stats = {HEALTH = 85, MANA = 70, DAMAGE = 2}
            },
            blacksmith = {
                name = "Blacksmith", description = "Crafts and sells weapons and armor",
                dialogue = {apology = {accepting = {"Like metal in the forge, trust can be reshaped.", "Even the strongest steel can be reforged.", "Perhaps you can be tempered into something better."}}},
                stats = {HEALTH = 130, STAMINA = 90, POSTURE = 90, DAMAGE = 7}
            }
        }
    },
    GUARD = {
        defaults = {
            unique = false,
            dialogue = {
                apology = {
                    accepting = {"Keep to the law, and we won't have problems.", "I'm watching you, but I'll give you a chance.", "Don't make me regret this decision."},
                    rejecting = {"The law doesn't forget so easily.", "Your words mean nothing against your actions.", "Justice has a long memory."}
                },
                greeting = {
                    friendly = {"Stay safe, citizen.", "All quiet today?", "Keep to the law, friend."},
                    hostile = {"You're treading on thin ice.", "I've got my eye on you.", "Move along, troublemaker."}
                }
            },
            stats = {HEALTH = 150, MANA = 40, STAMINA = 120, POSTURE = 100, SPEED = 16, DAMAGE = 10, RESONANCE = 25, FORGIVENESS_THRESHOLD = 50, TRUST_GAIN_RATE = 0.8, TRUST_LOSS_RATE = 1.8, MEMORY = 2419200}
        },
        variants = {
            patrol = {
                name = "Guard Patrol", description = "Maintains order in the streets",
                stats = {HEALTH = 140, STAMINA = 130, SPEED = 17}
            },
            captain = {
                unique = true,
                name = "Guard Captain", description = "Leads the city guard",
                stats = {HEALTH = 200, STAMINA = 150, POSTURE = 120, DAMAGE = 15, RESONANCE = 40, FORGIVENESS_THRESHOLD = 60, TRUST_GAIN_RATE = 0.6, TRUST_LOSS_RATE = 2.0}
            }
        }
    },
    UNIQUE = {
        defaults = {
            unique = true,
            dialogue = {
                greeting = {
                    friendly = {"Greetings, Seeker of Ascension.", "I've been observing your journey.", "The cycle continues. How fascinating."},
                    hostile = {"Another failed attempt at breaking the cycle.", "You are not ready for Ascension.", "The cycle claims all in the end."}
                },
                apology = {
                    accepting = {"Time is circular. All wrongs can be made right.", "I see a new path forming for you.", "Errors are part of the journey to Ascension."},
                    rejecting = {"Some actions echo through all Awakenings.", "The cycle remembers, even when you forget.", "Ascension requires more than mere words."}
                }
            },
            stats = {HEALTH = 500, MANA = 300, STAMINA = 200, POSTURE = 300, SPEED = 18, DAMAGE = 20, RESONANCE = 100, FORGIVENESS_THRESHOLD = 70, TRUST_GAIN_RATE = 0.5, TRUST_LOSS_RATE = 2.5, MEMORY = 9999999}
        },
        variants = {
            awakener = {
                unique = true,
                name = "The Awakener", description = "A mysterious entity who guides souls through their Awakenings",
                dialogue = {
                    greeting = {
                        friendly = {"Welcome back to the realm of the living. Your soul grows stronger with each Awakening.", "I have watched you die seventy-three times. Perhaps this cycle will be different.", "The path to Ascension is not through survival alone, but through understanding."},
                        hostile = {"Another failed cycle. How disappointing.", "You cling to material strength when it is wisdom you lack.", "The cycle will continue until you learn its purpose."}
                    },
                    apology = {accepting = {"Your regret echoes across all your lives. I accept.", "One who acknowledges failure is one step closer to Ascension.", "Perhaps you are beginning to understand the cycle after all."}},
                    knowledge = {
                        invocation = {"Invocations are not mere words, but bridges between your will and the Authorities.", "The sequence matters. The rhythm matters. Your intent... matters most of all.", "Some Invocations were never meant for mortal tongues. Seek them with caution."},
                        ascension = {"Ascension is not an escape from death, but a transcendence of the cycle itself.", "Many have tried. All but a few have failed.", "The path to Ascension is unique to each soul. Yours remains... unwritten."}
                    }
                },
                stats = {HEALTH = 1000, MANA = 500, STAMINA = 300, POSTURE = 500, SPEED = 20, DAMAGE = 40, RESONANCE = 200, FORGIVENESS_THRESHOLD = 80, TRUST_GAIN_RATE = 0.4, TRUST_LOSS_RATE = 3.0, MEMORY = 9999999},
                abilities = {"MEMORY_ECHO", "INVOCATION_TEACH", "CYCLE_SENSE"}
            }
        }
    }
}

return PersonModule
