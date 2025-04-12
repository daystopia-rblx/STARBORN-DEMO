local QuestModule = require(game:GetService("ReplicatedStorage").Modules.QuestModule)

return {
    ["awakening_tutorial"] = {
        id = "awakening_tutorial",
        type = QuestModule.Types.TUTORIAL,
        chapter = 0,
        name = "The First Awakening",
        description = "Learn the fundamentals of survival in Ascendium as you begin your journey",
        hint = "Speak with The Awakener to begin your path",
        level = 1,
        isRepeatable = false,
        isShareable = false,
        giver = "THE_AWAKENER",
        branches = {
            awakening_survival = {
                id = "awakening_survival",
                name = "Fundamentals of Survival",
                description = "Master the basic survival mechanics that will keep you alive in Ascendium",
                objectives = {
                    basic_movement = {
                        id = "basic_movement",
                        name = "First Steps",
                        description = "Learn how to move through the world",
                        conditions = {
                            walk = { id = "walk", type = "distance", target = "walking", required = 50, progress = 0 },
                            sprint = { id = "sprint", type = "action", target = "sprint", required = 3, progress = 0 },
                            jump = { id = "jump", type = "action", target = "jump", required = 5, progress = 0 },
                            roll = { id = "roll", type = "action", target = "roll", required = 3, progress = 0 }
                        }
                    },
                    survival_needs = {
                        id = "survival_needs",
                        name = "Staying Alive",
                        description = "Learn to manage your basic survival needs",
                        conditions = {
                            eat_food = { id = "eat_food", type = "consume", target = "FOOD", required = 1, progress = 0 },
                            drink_water = { id = "drink_water", type = "consume", target = "WATER", required = 1, progress = 0 },
                            rest = { id = "rest", type = "interact", target = "Bonfire", required = 1, progress = 0 }
                        }
                    }
                },
                nextBranches = {"awakening_combat"}
            },

            awakening_combat = {
                id = "awakening_combat",
                name = "Combat Essentials",
                description = "Learn the fundamentals of combat to defend yourself in Ascendium",
                objectives = {
                    weapon_basics = {
                        id = "weapon_basics",
                        name = "Weapon Fundamentals",
                        description = "Master the basics of weapon combat",
                        conditions = {
                            equip_weapon = { id = "equip_weapon", type = "equip", target = "WEAPON", required = 1, progress = 0 },
                            light_attack = { id = "light_attack", type = "action", target = "light_attack", required = 5, progress = 0 },
                            critical_attack = { id = "critical_attack", type = "action", target = "critical_attack", required = 2, progress = 0 }
                        }
                    },
                    defense_techniques = {
                        id = "defense_techniques",
                        name = "Defensive Maneuvers",
                        description = "Learn to defend yourself from enemy attacks",
                        conditions = { 
                            block = { id = "block", type = "action", target = "block", required = 3, progress = 0 },
                            parry = { id = "parry", type = "action", target = "parry", required = 1, progress = 0 },
                            posture = { id = "posture", type = "maintain", target = "posture", required = 30, progress = 0 }
                        }
                    }
                },
                nextBranches = {"awakening_resonance"}
            },

            awakening_resonance = {
                id = "awakening_resonance",
                name = "Understanding Resonance",
                description = "Discover the power of Resonance and how to harness it",
                objectives = {
                    resonance_basics = {
                        id = "resonance_basics",
                        name = "Resonance Awakening",
                        description = "Connect with the supernatural forces of Ascendium",
                        conditions = {
                            visit_shrine = { id = "visit_shrine", type = "visit", target = "RESONANCE_SHRINE", required = 1, progress = 0 },
                            channel_resonance = { id = "channel_resonance", type = "action", target = "channel_resonance", required = 1, progress = 0 }
                        }
                    },
                    resonance_application = {
                        id = "resonance_application",
                        name = "Applying Resonance",
                        description = "Learn to use Resonance in practical situations",
                        conditions = {
                            use_ability = { id = "use_ability", type = "action", target = "resonance_ability", required = 3, progress = 0 },
                            restore_resonance = { id = "restore_resonance", type = "consume", target = "RESONANCE_POTION", required = 1, progress = 0 }
                        }
                    }
                },
                nextBranches = {"awakening_checkpoint"}
            },

            awakening_checkpoint = {
                id = "awakening_checkpoint",
                name = "Refuge in Darkness",
                description = "Learn how checkpoints work to survive in the harsh world of Ascendium",
                objectives = {
                    checkpoint_basics = {
                        id = "checkpoint_basics",
                        name = "Sanctuary Amidst Chaos",
                        description = "Discover how checkpoints save your progress and heal your wounds",
                        conditions = { 
                            find_bed = { id = "find_bed", type = "interact", target = "Bed", required = 1, progress = 0 },
                            activate_checkpoint = { id = "activate_checkpoint", type = "interact", target = "Bonfire", required = 1, progress = 0 },
                            heal_at_checkpoint = { id = "heal_at_checkpoint", type = "action", target = "checkpoint_heal", required = 1, progress = 0 }
                        }
                    },
                    death_cycle = {
                        id = "death_cycle",
                        name = "The Cycle of Rebirth",
                        description = "Experience the cycle of death and rebirth central to Ascendium",
                        conditions = {
                            respawn_checkpoint = { id = "respawn_checkpoint", type = "event", target = "respawn", required = 1, progress = 0 },
                            return_checkpoint = { id = "return_checkpoint", type = "visit", target = "last_checkpoint", required = 1, progress = 0 }
                        }
                    }
                },
                nextBranches = {"awakening_trial"}
            },

            awakening_trial = {
                id = "awakening_trial",
                name = "The Awakener's Trial",
                description = "Complete a final challenge to prove your readiness for Ascendium",
                objectives = {
                    preparation = {
                        id = "preparation",
                        name = "Preparation",
                        description = "Prepare yourself for the final trial",
                        conditions = { 
                            restore_health = { id = "restore_health", type = "consume", target = "HEALTH_POTION", required = 1, progress = 0 },
                            craft_item = { id = "craft_item", type = "craft", target = "BANDAGE", required = 1, progress = 0 }
                        }
                    },
                    final_challenge = {
                        id = "final_challenge",
                        name = "Trial of the Awakened",
                        description = "Complete the Awakener's challenge",
                        conditions = { 
                            defeat_shade = { id = "defeat_shade", type = "defeat", target = "SHADE", required = 3, progress = 0 },
                            reach_monument = { id = "reach_monument", type = "visit", target = "AWAKENER_MONUMENT", required = 1, progress = 0 },
                            return_awakener = { id = "return_awakener", type = "talk", target = "THE_AWAKENER", required = 1, progress = 0 }
                        }
                    }
                }
            }
        },
        startingBranch = "awakening_survival",
        rewards = {
            medallion = { 
                type = QuestModule.RewardTypes.ITEM,
                id = "AWAKENER_MEDALLION",
                amount = 1
            },
            currency = { 
                type = QuestModule.RewardTypes.CURRENCY,
                id = "UMBRELS",
                amount = 500
            },
            experience = { 
                type = QuestModule.RewardTypes.EXPERIENCE,
                amount = 1000 
            },
            waterskin = { 
                type = QuestModule.RewardTypes.ITEM,
                id = "WATERSKIN",
                amount = 1
            },
            rations = { 
                type = QuestModule.RewardTypes.ITEM,
                id = "TRAVEL_RATIONS",
                amount = 5
            },
            resonance_orb = { 
                type = QuestModule.RewardTypes.ITEM,
                id = "RESONANCE_ORB",
                amount = 1
            },
            title = {
                type = QuestModule.RewardTypes.TITLE,
                id = "AWAKENED",
                amount = 1
            }
        },
        metadata = {
            isOptional = true,
            skipOnRebirth = true,
            tutorialType = "awakening"
        }
    }
}