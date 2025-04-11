--[[ FactionModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local FactionModule = {}

--[[ Types ]]
export type Faction = {
    id: string,
    name: string,
    description: string,
    icon: string?,
    color: Color3?,
    leaderId: string?,
    members: {string}?,
    territories: {[string]: number}?,
    resources: {[string]: number}?,
    population: number?,
    relationships: {[string]: FactionRelationship}?
}

export type FactionRelationship = {
    value: number,
    state: string,
    lastUpdate: number,
    conflictStart: number?,
    allianceStart: number?
}

export type ConflictData = {
    id: string,
    factions: {string},
    relationship: FactionRelationship,
    intensity: number,
    cause: string?,
    causeDescription: string?,
    startDate: number,
    territory: string?,
    resourceDispute: string?
}

export type PlayerFactionData = {
    standing: number,
    reputation: number,
    rank: string,
    lastInteraction: number
}

--[[ Constants ]]
FactionModule.FACTION_IDS = {
    UMBRAL_PACT = "UMBRAL_PACT",
    DAWNWARDENS = "DAWNWARDENS",
    SHATTERED_FANG = "SHATTERED_FANG"
}

FactionModule.Factions = {
    [FactionModule.FACTION_IDS.UMBRAL_PACT] = {
        id = FactionModule.FACTION_IDS.UMBRAL_PACT,
        name = "The Umbral Pact",
        type = "UMBRAL",
        leaderName = "The Shadowlord"
    },
    [FactionModule.FACTION_IDS.DAWNWARDENS] = {
        id = FactionModule.FACTION_IDS.DAWNWARDENS,
        name = "The Dawnwardens",
        type = "DAWN",
        leaderName = "The High Warden"
    },
    [FactionModule.FACTION_IDS.SHATTERED_FANG] = {
        id = FactionModule.FACTION_IDS.SHATTERED_FANG,
        name = "The Shattered Fang",
        type = "ROGUE",
        leaderName = "The Fangmaster"
    }
}

FactionModule.RelationshipStates = {
    WAR = {
        color = Color3.fromRGB(220, 20, 20),
        icon = "rbxassetid://6072809086",
        threshold = -5000,
        description = "Open hostilities between factions"
    },
    HOSTILE = {
        color = Color3.fromRGB(240, 80, 40),
        icon = "rbxassetid://6072809776",
        threshold = -3000,
        description = "Aggressive and distrustful relations"
    },
    TENSE = {
        color = Color3.fromRGB(250, 150, 50),
        icon = "rbxassetid://6072809542",
        threshold = -1000,
        description = "Uneasy diplomatic relations"
    },
    NEUTRAL = {
        color = Color3.fromRGB(200, 200, 200),
        icon = "rbxassetid://6072809542",
        threshold = 0,
        description = "Neither friendly nor hostile"
    },
    CORDIAL = {
        color = Color3.fromRGB(120, 220, 120),
        icon = "rbxassetid://6072809347",
        threshold = 2000,
        description = "Positive diplomatic relations"
    },
    ALLIANCE = {
        color = Color3.fromRGB(80, 150, 255),
        icon = "rbxassetid://6072809915",
        threshold = 5000,
        description = "Strong alliance between factions"
    }
}

FactionModule.DiplomaticOptions = {
    MEDIATE = {
        icon = "rbxassetid://6072809905",
        color = Color3.fromRGB(120, 220, 220),
        description = "Attempt to mediate between conflicting factions",
        requirements = {
            minReputation = 20
        }
    },
    THREATEN = {
        icon = "rbxassetid://6072809086",
        color = Color3.fromRGB(220, 80, 60),
        description = "Use threats to force peace",
        requirements = {
            minStat = {strength = 30}
        }
    },
    BRIBE = {
        icon = "rbxassetid://6072809347",
        color = Color3.fromRGB(250, 200, 60),
        description = "Offer resources to promote peace",
        requirements = {
            minUmbrels = 1000
        }
    }
}

FactionModule.NegotiationOutcomes = {
    MEDIATE = {
        SUCCESS = {
            chance = 0.7,
            reputationGain = 15,
            factionRelationshipChange = 30,
            message = "Your mediation was successful! The factions have agreed to peace terms."
        },
        FAILURE = {
            chance = 0.3,
            reputationLoss = -5,
            factionRelationshipChange = -10,
            message = "Despite your best efforts, the factions could not reach an agreement."
        }
    },

    THREATEN = {
        SUCCESS = {
            chance = 0.5,
            reputationGain = 5,
            factionRelationshipChange = 25,
            message = "Your threats compelled the factions to cease hostilities."
        },
        FAILURE = {
            chance = 0.5,
            reputationLoss = -15,
            factionRelationshipChange = -20,
            message = "Your threats have backfired! The factions now see you as an enemy."
        }
    },

    BRIBE = {
        SUCCESS = {
            chance = 0.8,
            reputationGain = 5,
            factionRelationshipChange = 20,
            message = "Your generous contributions have swayed the factions to make peace."
        },
        FAILURE = {
            chance = 0.2,
            umbrelsReturn = 0.5,
            reputationLoss = -5,
            factionRelationshipChange = 5,
            message = "Your attempt to buy peace between the factions was rejected."
        }
    }
}

FactionModule.FactionTypes = {
    UMBRAL = {
        name = "Dark Order",
        leaderTitle = "Shadowlord",
        militaryStrength = 0.7,
        economicStrength = 0.6,
        diplomaticInfluence = 0.6,
        description = "Dark-aligned, specializing in blood and soul manipulation.",
        bonus = "Slight lifesteal on critical hits."
    },
    DAWN = {
        name = "Order of Light",
        leaderTitle = "High Warden",
        militaryStrength = 0.8,
        economicStrength = 0.7,
        diplomaticInfluence = 0.8,
        description = "Order-based, specializing in light and resilience.",
        bonus = "Reduced bleed and burn duration."
    },
    ROGUE = {
        name = "Rogue Clan",
        leaderTitle = "Fangmaster",
        militaryStrength = 0.6,
        economicStrength = 0.8,
        diplomaticInfluence = 0.5,
        description = "Rogue survivalists, PvP-focused.",
        bonus = "Slight stamina regen boost when below 50% health."
    }
}

FactionModule.ConflictTypes = {
    TERRITORIAL = {
        name = "Territorial Dispute",
        description = "Conflict over control of land or resources",
        severityFactor = 1.2
    },
    IDEOLOGICAL = {
        name = "Ideological Conflict",
        description = "Disagreement over beliefs or governing principles",
        severityFactor = 0.8
    },
    ECONOMIC = {
        name = "Economic Rivalry",
        description = "Competition over trade routes or resources",
        severityFactor = 0.9
    },
    HISTORICAL = {
        name = "Historical Grievance",
        description = "Long-standing grudges and past injustices",
        severityFactor = 1.1
    }
}

FactionModule.Templates = {
    Faction = function(params: {
        id: string,
        name: string,
        type: string,
        leaderName: string?
    }): Faction
        local factionType = FactionModule.FactionTypes[params.type] or FactionModule.FactionTypes.KINGDOM

        return {
            id = params.id,
            name = params.name,
            description = params.name .. " is a " .. string.lower(factionType.name) .. " in the region.",
            type = params.type,
            icon = "rbxassetid://6072809347",
            color = Color3.fromRGB(120, 120, 220),
            leaderId = params.id .. "_leader",
            leaderName = params.leaderName or (factionType.leaderTitle .. " of " .. params.name),
            members = {},
            territories = {},
            resources = {
                UMBRELS = 1000,
                IRON = 500,
                WOOD = 800,
                FOOD = 2000
            },
            population = 5000,
            militaryStrength = factionType.militaryStrength * 100,
            economicStrength = factionType.economicStrength * 100,
            diplomaticInfluence = factionType.diplomaticInfluence * 100,
            relationships = {}
        }
    end,

    Conflict = function(params: {
        factionId1: string,
        factionId2: string,
        conflictType: string?,
        cause: string?,
        territory: string?
    }): ConflictData
        local conflictType = params.conflictType or "TERRITORIAL"
        local conflictInfo = FactionModule.ConflictTypes[conflictType] or FactionModule.ConflictTypes.TERRITORIAL
        local cause = params.cause or conflictInfo.name

        return {
            id = params.factionId1 .. "_vs_" .. params.factionId2,
            factions = {params.factionId1, params.factionId2},
            relationship = {
                value = -3000,
                state = "HOSTILE",
                lastUpdate = os.time(),
                conflictStart = os.time() - math.random(1, 30) * 86400
            },
            intensity = 1,
            conflictType = conflictType,
            cause = cause,
            causeDescription = params.cause and params.cause or nil,
            startDate = os.time() - math.random(1, 30) * 86400,
            territory = params.territory
        }
    end,

    Default = function()
        local defaultFactions = {
            [FactionModule.FACTION_IDS.UMBRAL_PACT] = FactionModule.Templates.Faction({
                id = FactionModule.FACTION_IDS.UMBRAL_PACT,
                name = "The Umbral Pact",
                type = "UMBRAL"
            }),
            [FactionModule.FACTION_IDS.DAWNWARDENS] = FactionModule.Templates.Faction({
                id = FactionModule.FACTION_IDS.DAWNWARDENS,
                name = "The Dawnwardens",
                type = "DAWN"
            }),
            [FactionModule.FACTION_IDS.SHATTERED_FANG] = FactionModule.Templates.Faction({
                id = FactionModule.FACTION_IDS.SHATTERED_FANG,
                name = "The Shattered Fang",
                type = "ROGUE"
            })
        }

        defaultFactions[FactionModule.FACTION_IDS.UMBRAL_PACT].relationships = {
            [FactionModule.FACTION_IDS.DAWNWARDENS] = {
                value = -3000,
                state = "HOSTILE",
                lastUpdate = os.time(),
                conflictStart = os.time() - 86400 * 10
            },
            [FactionModule.FACTION_IDS.SHATTERED_FANG] = {
                value = -500,
                state = "TENSE",
                lastUpdate = os.time()
            }
        }

        defaultFactions[FactionModule.FACTION_IDS.DAWNWARDENS].relationships = {
            [FactionModule.FACTION_IDS.UMBRAL_PACT] = {
                value = -3000,
                state = "HOSTILE",
                lastUpdate = os.time(),
                conflictStart = os.time() - 86400 * 10
            },
            [FactionModule.FACTION_IDS.SHATTERED_FANG] = {
                value = -2000,
                state = "HOSTILE",
                lastUpdate = os.time()
            }
        }

        defaultFactions[FactionModule.FACTION_IDS.SHATTERED_FANG].relationships = {
            [FactionModule.FACTION_IDS.UMBRAL_PACT] = {
                value = -500,
                state = "TENSE",
                lastUpdate = os.time()
            },
            [FactionModule.FACTION_IDS.DAWNWARDENS] = {
                value = -2000,
                state = "HOSTILE",
                lastUpdate = os.time()
            }
        }

        local conflicts = {
            FactionModule.Templates.Conflict({
                factionId1 = FactionModule.FACTION_IDS.UMBRAL_PACT,
                factionId2 = FactionModule.FACTION_IDS.DAWNWARDENS,
                conflictType = "TERRITORIAL",
                territory = "Disputed Borderlands"
            }),
            FactionModule.Templates.Conflict({
                factionId1 = FactionModule.FACTION_IDS.DAWNWARDENS,
                factionId2 = FactionModule.FACTION_IDS.SHATTERED_FANG,
                conflictType = "HISTORICAL",
                cause = "Ancient Blood Feud"
            })
        }

        return {
            factions = defaultFactions,
            conflicts = conflicts
        }
    end
}

--[[ Utility Functions ]]
function FactionModule.GetRelationship(value: number): string
    local state = "NEUTRAL"
    local highestThreshold = -math.huge

    for stateName, stateData in pairs(FactionModule.RelationshipStates) do
        if stateData.threshold <= value and stateData.threshold > highestThreshold then
            state = stateName
            highestThreshold = stateData.threshold
        end
    end

    return state
end

function FactionModule.FormatRelationshipDescription(factionId1: string, factionId2: string, relationshipData: FactionRelationship): string
    local state = relationshipData.state or "NEUTRAL"
    local stateInfo = FactionModule.RelationshipStates[state] or FactionModule.RelationshipStates.NEUTRAL

    local descriptions = {
        WAR = {
            "are engaged in open warfare",
            "are locked in deadly conflict",
            "are at war"
        },
        HOSTILE = {
            "maintain hostile relations",
            "are on the brink of war",
            "hold deep animosity toward each other"
        },
        TENSE = {
            "have tense relations",
            "maintain a fragile peace",
            "regard each other with suspicion"
        },
        NEUTRAL = {
            "have neutral relations",
            "maintain formal diplomatic ties",
            "neither ally nor enemy"
        },
        CORDIAL = {
            "enjoy cordial relations",
            "maintain friendly ties",
            "cooperate on various matters"
        },
        ALLIANCE = {
            "are strong allies",
            "maintain a formal alliance",
            "stand together in matters of importance"
        }
    }

    local descriptionOptions = descriptions[state] or descriptions.NEUTRAL
    local description = descriptionOptions[math.random(#descriptionOptions)]

    return description
end

--[[ Validation Functions ]]
function FactionModule.ValidateFaction(faction: Faction): (boolean, string?)
    if not faction.id or not faction.name then
        return false, "Faction missing required fields (id, name)"
    end
    return true
end

return FactionModule