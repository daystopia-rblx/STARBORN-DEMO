local QuestModule = require(game:GetService("ReplicatedStorage").Modules.QuestModule)

return {
    ["faction_initiation"] = {
        id = "faction_initiation",
        type = QuestModule.Types.FACTION,
        chapter = 1,
        name = "Choosing Your Path",
        description = "Decide which faction you will pledge your allegiance to",
        hint = "Speak with the representatives of each faction to learn about their values",
        level = 15,
        isRepeatable = false,
        isShareable = false,
        giver = "FACTION_HERALD",
        branches = {
            faction_discovery = {
                id = "faction_discovery",
                name = "Faction Exploration",
                description = "Learn about the three major factions of Ascendium",
                objectives = {
                    meet_representatives = {
                        id = "meet_representatives",
                        name = "Meeting the Leaders",
                        description = "Speak with representatives from each faction",
                        conditions = {
                            meet_umbral = { id = "meet_umbral", type = "talk", target = "SHADOWLORD", required = 1, progress = 0 },
                            meet_dawn = { id = "meet_dawn", type = "talk", target = "HIGH_WARDEN", required = 1, progress = 0 },
                            meet_fang = { id = "meet_fang", type = "talk", target = "FANGMASTER", required = 1, progress = 0 }
                        }
                    },
                    observe_territories = {
                        id = "observe_territories",
                        name = "Territory Assessment",
                        description = "Visit and observe each faction's territory",
                        conditions = {
                            visit_umbral = { id = "visit_umbral", type = "visit", target = "UMBRAL_TERRITORY", required = 1, progress = 0 },
                            visit_dawn = { id = "visit_dawn", type = "visit", target = "DAWN_TERRITORY", required = 1, progress = 0 },
                            visit_fang = { id = "visit_fang", type = "visit", target = "FANG_TERRITORY", required = 1, progress = 0 }
                        }
                    }
                },
                nextBranches = {"faction_trials"}
            },

            faction_trials = {
                id = "faction_trials",
                name = "Trials of Worth",
                description = "Prove your worth to the factions through trial and combat",
                objectives = {
                    combat_trials = {
                        id = "combat_trials",
                        name = "Combat Prowess",
                        description = "Demonstrate your combat skills in faction trials",
                        conditions = { 
                            defeat_champions = { id = "defeat_champions", type = "defeat", target = "FACTION_CHAMPION", required = 3, progress = 0 },
                            survive_arena = { id = "survive_arena", type = "survive", target = "ARENA_CHALLENGE", required = 1, progress = 0 }
                        }
                    },
                    skill_demonstration = {
                        id = "skill_demonstration",
                        name = "Skills and Talents",
                        description = "Show your unique skills to faction representatives",
                        conditions = { 
                            craft_artifact = { id = "craft_artifact", type = "craft", target = "FACTION_ARTIFACT", required = 1, progress = 0 },
                            resonance_display = { id = "resonance_display", type = "action", target = "faction_resonance", required = 1, progress = 0 }
                        }
                    }
                },
                nextBranches = {"faction_choice"}
            },

            faction_choice = {
                id = "faction_choice",
                name = "The Fateful Choice",
                description = "Choose which faction you will join",
                objectives = {
                    final_decision = {
                        id = "final_decision",
                        name = "Allegiance Pledge",
                        description = "Pledge your allegiance to one of the three factions",
                        conditions = { 
                            pledge_allegiance = { id = "pledge_allegiance", type = "choice", target = "FACTION_PLEDGE", required = 1, progress = 0, choices = {"UMBRAL_PACT", "DAWNWARDENS", "SHATTERED_FANG"} }
                        }
                    },
                    initiation_ritual = {
                        id = "initiation_ritual",
                        name = "Initiation Ceremony",
                        description = "Complete your chosen faction's initiation ritual",
                        conditions = { 
                            complete_ritual = { id = "complete_ritual", type = "event", target = "FACTION_RITUAL", required = 1, progress = 0 },
                            receive_blessing = { id = "receive_blessing", type = "effect", target = "FACTION_BLESSING", required = 1, progress = 0 }
                        }
                    }
                }
            }
        },
        startingBranch = "faction_discovery",
        rewards = {
            faction_cloak = {
                type = QuestModule.RewardTypes.ITEM,
                id = "FACTION_CLOAK",
                amount = 1,
                metadata = {
                    dynamic = true,
                    sourceId = "chosen_faction"
                }
            },
            potions = {
                type = QuestModule.RewardTypes.ITEM,
                id = "HEALTH_POTION",
                variant = "minor",
                amount = 2
            },
            strength_potion = {
                type = QuestModule.RewardTypes.ITEM,
                id = "STRENGTH_POTION",
                variant = "minor",
                amount = 1
            },
            currency = { 
                type = QuestModule.RewardTypes.CURRENCY,
                id = "UMBRELS",
                amount = 1000
            },
            experience = { 
                type = QuestModule.RewardTypes.EXPERIENCE,
                amount = 5000
            },
            passive_buff = {
                type = QuestModule.RewardTypes.BUFF,
                id = "FACTION_PASSIVE",
                amount = 1,
                metadata = {
                    dynamic = true,
                    sourceId = "chosen_faction"
                }
            },
            faction_standing = {
                type = QuestModule.RewardTypes.FACTION_STANDING,
                id = "chosen_faction",
                amount = 5000
            }
        },
        metadata = {
            isMilestone = true,
            choice = {
                affects = "faction_allegiance",
                permanent = true,
                lockDuration = 86400 * 40
            }
        }
    },

    ["mediation_quest_template"] = {
        id = "mediation_quest_template",
        type = QuestModule.Types.FACTION,
        chapter = 2,
        name = "Diplomatic Resolution",
        description = "Attempt to resolve a conflict between two factions through diplomacy",
        hint = "Speak with the diplomat about the ongoing conflict",
        level = 20,
        isRepeatable = true,
        isShareable = false,
        dynamicId = true,
        branches = {
            investigation_branch = {
                id = "investigation_branch",
                name = "Conflict Investigation",
                description = "Investigate the causes and details of the conflict",
                objectives = {
                    speak_representatives = {
                        id = "speak_representatives",
                        name = "Diplomatic Inquiries",
                        description = "Speak with representatives from both factions to understand their perspective",
                        conditions = { 
                            speak_faction1 = { id = "speak_faction1", type = "talk", target = "FACTION1_DIPLOMAT", required = 1, progress = 0, dynamic = true },
                            speak_faction2 = { id = "speak_faction2", type = "talk", target = "FACTION2_DIPLOMAT", required = 1, progress = 0, dynamic = true }
                        }
                    },
                    gather_information = {
                        id = "gather_information",
                        name = "Information Gathering",
                        description = "Collect relevant information about the conflict",
                        conditions = { 
                            collect_documents = { id = "collect_documents", type = "collect", target = "CONFLICT_DOCUMENTS", required = 3, progress = 0 },
                            visit_location = { id = "visit_location", type = "visit", target = "DISPUTE_LOCATION", required = 1, progress = 0, dynamic = true }
                        }
                    }
                },
                nextBranches = {"mediation_branch"}
            },

            mediation_branch = {
                id = "mediation_branch",
                name = "Diplomatic Mediation",
                description = "Attempt to facilitate a peaceful resolution between the factions",
                objectives = {
                    arrange_meeting = {
                        id = "arrange_meeting",
                        name = "Peace Summit",
                        description = "Arrange and attend a meeting between faction representatives",
                        conditions = { 
                            invite_faction1 = { id = "invite_faction1", type = "talk", target = "FACTION1_LEADER", required = 1, progress = 0, dynamic = true },
                            invite_faction2 = { id = "invite_faction2", type = "talk", target = "FACTION2_LEADER", required = 1, progress = 0, dynamic = true },
                            attend_meeting = { id = "attend_meeting", type = "visit", target = "NEUTRAL_GROUND", required = 1, progress = 0 }
                        }
                    },
                    negotiation = {
                        id = "negotiation",
                        name = "Delicate Negotiations",
                        description = "Navigate the complex negotiations between factions",
                        conditions = { 
                            persuade_faction1 = { id = "persuade_faction1", type = "persuade", target = "FACTION1_DEMAND", required = 1, progress = 0, dynamic = true },
                            persuade_faction2 = { id = "persuade_faction2", type = "persuade", target = "FACTION2_DEMAND", required = 1, progress = 0, dynamic = true },
                            propose_solution = { id = "propose_solution", type = "persuade", target = "PEACE_TERMS", required = 1, progress = 0 }
                        }
                    }
                },
                nextBranches = {"resolution_branch"}
            },

            resolution_branch = {
                id = "resolution_branch",
                name = "Conflict Resolution",
                description = "Formalize and implement the peace agreement",
                objectives = {
                    peace_treaty = {
                        id = "peace_treaty",
                        name = "Treaty Formalization",
                        description = "Oversee the signing of a formal peace treaty",
                        conditions = { 
                            draft_treaty = { id = "draft_treaty", type = "craft", target = "PEACE_TREATY", required = 1, progress = 0 },
                            obtain_signatures = { id = "obtain_signatures", type = "collect", target = "FACTION_SIGNATURE", required = 2, progress = 0 }
                        }
                    },
                    conflict_resolution = {
                        id = "conflict_resolution",
                        name = "Resolution Implementation",
                        description = "Ensure the terms of the agreement are properly implemented",
                        conditions = { 
                            withdraw_forces = { id = "withdraw_forces", type = "visit", target = "CONFLICT_ZONE", required = 1, progress = 0 },
                            deliver_treaty = { id = "deliver_treaty", type = "deliver", target = "TREATY_ARCHIVE", required = 1, progress = 0 }
                        }
                    }
                }
            }
        },
        startingBranch = "investigation_branch",
        rewards = {
            diplomat_insignia = {
                type = QuestModule.RewardTypes.ITEM, 
                id = "DIPLOMAT_INSIGNIA",
                amount = 1
            },
            currency = { 
                type = QuestModule.RewardTypes.CURRENCY,
                id = "UMBRELS",
                amount = 2000
            },
            experience = { 
                type = QuestModule.RewardTypes.EXPERIENCE,
                amount = 3000
            },
            faction1_standing = {
                type = QuestModule.RewardTypes.FACTION_STANDING,
                id = "dynamic_faction1",
                amount = 1000,
                dynamic = true
            },
            faction2_standing = {
                type = QuestModule.RewardTypes.FACTION_STANDING,
                id = "dynamic_faction2",
                amount = 1000,
                dynamic = true
            }
        },
        metadata = {
            isDynamic = true,
            templateType = "mediation",
            outcomes = {
                "PEACEFUL_RESOLUTION",
                "TEMPORARY_TRUCE",
                "FAILED_NEGOTATION"
            }
        }
    },

    ["faction_mission_template"] = {
        id = "faction_mission_template",
        type = QuestModule.Types.FACTION_MISSION,
        chapter = 2,
        name = "Faction Mission",
        description = "Complete a mission on behalf of your faction",
        hint = "Check the faction mission board for available tasks",
        level = 20,
        isRepeatable = true,
        isShareable = false,
        dynamicId = true,
        branches = {
            mission_objective = {
                id = "mission_objective",
                name = "Faction Assignment",
                description = "Complete your assigned mission for the faction",
                objectives = {
                    primary_task = {
                        id = "primary_task",
                        name = "Primary Objective",
                        description = "Complete the main objective of your mission",
                        conditions = {
                            mission_target = { id = "mission_target", type = "dynamic", target = "MISSION_TARGET", required = 1, progress = 0, dynamic = true }
                        }
                    },
                    secondary_task = {
                        id = "secondary_task",
                        name = "Secondary Objective",
                        description = "Complete an additional objective to maximize your reward",
                        isOptional = true,
                        conditions = {
                            bonus_target = { id = "bonus_target", type = "dynamic", target = "BONUS_TARGET", required = 1, progress = 0, dynamic = true }
                        }
                    }
                },
                nextBranches = {"mission_completion"}
            },

            mission_completion = {
                id = "mission_completion",
                name = "Mission Report",
                description = "Return to your faction headquarters to report your success",
                objectives = {
                    return_report = {
                        id = "return_report",
                        name = "Mission Debriefing",
                        description = "Report the results of your mission",
                        conditions = {
                            deliver_report = { id = "deliver_report", type = "talk", target = "FACTION_COMMANDER", required = 1, progress = 0, dynamic = true }
                        }
                    }
                }
            }
        },
        startingBranch = "mission_objective",
        rewards = {
            faction_tokens = {
                type = QuestModule.RewardTypes.ITEM,
                id = "FACTION_TOKEN",
                amount = 5,
                dynamic = true
            },
            potion_reward = {
                type = QuestModule.RewardTypes.ITEM,
                id = "VITALITY_POTION",
                variant = "minor",
                amount = 1,
                dynamic = true
            },
            currency = { 
                type = QuestModule.RewardTypes.CURRENCY, 
                id = "UMBRELS",
                amount = 500,
                dynamic = true
            },
            experience = {
                type = QuestModule.RewardTypes.EXPERIENCE,
                amount = 1000,
                dynamic = true
            },
            faction_standing = {
                type = QuestModule.RewardTypes.FACTION_STANDING,
                id = "player_faction",
                amount = 500,
                dynamic = true
            }
        },
        metadata = {
            isDynamic = true,
            templateType = "faction_mission",
            missionTypes = {
                "RETRIEVE_RELIC",
                "ELIMINATE_RIVALS",
                "DEFEND_LOCATION",
                "GATHER_INTELLIGENCE",
                "SABOTAGE_OPERATION"
            },
            dailyLimit = 3
        }
    }
}