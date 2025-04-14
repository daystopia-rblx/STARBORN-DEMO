--[[ CrimeModule
    @author @Daystopia
    @version 1.0.1
    @date 2025-04-14
]]
local CrimeModule = {}

CrimeModule.Types = {
    THEFT = "theft",
    ASSAULT = "assault",
    MURDER = "murder",
    TRESPASSING = "trespassing",
    PICKPOCKET = "pickpocket",
    BURGLARY = "burglary"
}

CrimeModule.SecurityLevels = {
    NONE = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    MAXIMUM = 4
}

CrimeModule.BountyConfig = {
    BASE_THEFT_BOUNTY = 50,
    VALUE_MULTIPLIER = 0.5,
    DEFAULT_EXPIRY = 604800,
    MIN_BOUNTY = 25,
    MAX_BOUNTY = 10000,

    TRESPASSING = {min = 25, max = 50},
    THEFT = {min = 50, multiplier = 0.5},
    BURGLARY = {min = 75, multiplier = 0.75},
    ASSAULT = {base = 100},
    MURDER = {min = 300, max = 500}
}

CrimeModule.TheftConfig = {
    BASE_CHANCE = 20,
    BASE_SUCCESS_CHANCE = 20,
    DEX_SUCCESS_BONUS = 2,
    STEALTH_BONUS = 2,
    SECURITY_PENALTY = 15,
    VALUE_GRADIENT = 1,
    MIN_CHANCE = 1,
    MAX_CHANCE = 95,
    MIN_SUCCESS_CHANCE = 5,
    MAX_SUCCESS_CHANCE = 95,

    DETECTION_BASE = 40,
    DETECTION_SECURITY_BONUS = 10
}

CrimeModule.ReputationImpact = {
    THEFT_CAUGHT = {
        INDIVIDUAL = -25,
        FACTION = -10,
        GLOBAL = -5
    },
    THEFT_UNCAUGHT = {
        INDIVIDUAL = -5,
        FACTION = -2,
        GLOBAL = -1
    },
    BOUNTY_CLEARED = {
        INDIVIDUAL = 15,
        FACTION = 5,
        GLOBAL = 2
    },
    ASSAULT = {
        INDIVIDUAL = -30,
        FACTION = -15,
        GLOBAL = -8
    },
    MURDER = {
        INDIVIDUAL = -50,
        FACTION = -25,
        GLOBAL = -15
    }
}

CrimeModule.DetectionFactors = {
    LINE_OF_SIGHT = {
        VISIBLE = 0,
        PARTIAL = -15,
        OBSTRUCTED = -30,
        NONE = -100
    },
    SOUND = {
        SILENT = -20,
        QUIET = -10,
        NORMAL = 0,
        LOUD = 15,
        VERY_LOUD = 30
    },
    LIGHT_LEVEL = {
        BRIGHT = 0,
        NORMAL = -5,
        DIM = -15,
        DARK = -25,
        PITCH_DARK = -40
    }
}

function CrimeModule:GetBounty(crimeType, targetValue, locationSecurityLevel)
    crimeType = crimeType:upper()
    locationSecurityLevel = locationSecurityLevel or self.SecurityLevels.MEDIUM
    targetValue = targetValue or 0

    local config = self.BountyConfig[crimeType]
    if not config then
        return self.BountyConfig.MIN_BOUNTY
    end

    local bounty = config.base or 0

    if config.multiplier then
        bounty = bounty + math.max(targetValue * config.multiplier, config.min or 0)
    else
        bounty = math.random(config.min or 0, config.max or config.min or 0)
    end

    local securityMultiplier = 1 + (locationSecurityLevel * 0.2)
    bounty = bounty * securityMultiplier

    return math.min(math.max(bounty, self.BountyConfig.MIN_BOUNTY), self.BountyConfig.MAX_BOUNTY)
end

function CrimeModule:GetDetection(playerDexterity, securityLevel, itemValue, lightLevel, soundLevel, lineOfSight)
    local baseChance = self.TheftConfig.DETECTION_BASE
    local stealthModifier = playerDexterity or 0
    local securityModifier = (securityLevel or 1) * self.TheftConfig.DETECTION_SECURITY_BONUS
    local valueModifier = (itemValue or 0) / (100 * self.TheftConfig.VALUE_GRADIENT)

    local lightLevelModifier = self.DetectionFactors.LIGHT_LEVEL[lightLevel or "NORMAL"] or 0
    local soundModifier = self.DetectionFactors.SOUND[soundLevel or "NORMAL"] or 0
    local lineOfSightModifier = self.DetectionFactors.LINE_OF_SIGHT[lineOfSight or "VISIBLE"] or 0

    local detectionChance = baseChance + securityModifier + valueModifier + lightLevelModifier + soundModifier + lineOfSightModifier - stealthModifier

    return math.clamp(detectionChance, 5, 95)
end

function CrimeModule:GetSuccess(playerDexterity, securityLevel, itemValue)
    local baseChance = self.TheftConfig.BASE_CHANCE
    local stealthBonus = (playerDexterity or 0) * self.TheftConfig.STEALTH_BONUS
    local securityPenalty = (securityLevel or 1) * self.TheftConfig.SECURITY_PENALTY
    local valueGradient = (itemValue or 0) / 100 * self.TheftConfig.VALUE_GRADIENT

    local successChance = baseChance + stealthBonus - securityPenalty - valueGradient

    return math.clamp(successChance, self.TheftConfig.MIN_SUCCESS_CHANCE, self.TheftConfig.MAX_SUCCESS_CHANCE)
end

return CrimeModule