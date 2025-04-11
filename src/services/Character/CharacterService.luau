-- Reworking old character creation menu
--[[ CharacterService
    Character creation and management system that handles customization,
    persistence, and initialization of game characters.
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local CharacterService = {}

CharacterService.Dependencies = {
    "Event",
    "Data",
    "Stat"
}

CharacterService.Modules = {
    Character = {
        Body = "Data/Character/BodyModule",
        Name = "Data/Character/NameModule",
        Race = "Data/Character/RaceModule"
    }
}

CharacterService.Events = {
    Create = { validate = true },
    Load = { validate = true },
    Select = { validate = true },
    Customize = { validate = true }
}

--[[ Services ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ State ]]
local Services
local Modules
local State = {
    characters = {},
    activeCharacters = {},
    characterLimit = 3
}

--[[ Event Listeners ]]
CharacterService.Listeners = {
    ["Player.Join"] = function(self, data)
    end,

    ["Character.Create"] = function(self, data)
        local player = data.player
        local characterData = data.characterData

        if not characterData then return end

        self:CreateCharacter(player, characterData)
    end,

    ["Character.Load"] = function(self, data)
        local player = data.player
        local slotId = data.slotId

        if not slotId then return end

        self:LoadCharacter(player, slotId)
    end,

    ["Data.Init"] = function(self, data)
        local player = data.player
        local loadedData = data.data

        if not player or not loadedData then return end

        State.characters[player.UserId] = loadedData.PlayerData.characters or {}
        State.activeCharacters[player.UserId] = loadedData.PlayerData.activeCharacter
    end
}

--[[ Core Functions ]]
function CharacterService:Init(services, modules)
    Services = services
    Modules = modules
    return true
end

function CharacterService:Start()
    return true
end

--[[ Character Functions ]]
function CharacterService:LoadCharacters(player)
    if not player then return end

    local userId = player.UserId

    local playerData = Services.Data:GetData(userId, "PlayerData")

    if not playerData or not playerData.characters then
        State.characters[userId] = {}
        return
    end

    State.characters[userId] = playerData.characters
    State.activeCharacters[userId] = playerData.activeCharacter
end

function CharacterService:StartCustomization(player)
    if not player then return end

    local userId = player.UserId
    local characters = State.characters[userId] or {}

    local characterNames = {}
    for i = 1, State.characterLimit do
        local character = characters[i]
        characterNames[i] = character and (character.firstName .. " " .. character.lastName) or ""
    end

    Services.Event:FireTo("Character.Customize", player, {
        potentialFullName = characterNames,
        slotsAvailable = State.characterLimit
    })
end

--[[ Creation Functions ]]
function CharacterService:CreateCharacter(player, characterData)
    if not player or not characterData then return end

    local userId = player.UserId
    local slotId = characterData.Slot

    if not slotId or slotId < 1 or slotId > State.characterLimit then
        return false, "Invalid slot ID"
    end

    local characters = State.characters[userId] or {}

    if characters[slotId] then
        return false, "Slot already contains a character"
    end

    if not self:ValidateCharacter(characterData) then
        return false, "Invalid character data"
    end

    local firstName = characterData.FirstName or ""
    local lastName = characterData.LastName or ""
    local race = characterData.Race or "Aetherion"
    local bodyType = characterData.BodyType or "Muscular"
    local skinColor = characterData.SkinColor or Modules.Character.Body.SkinColors["Ivory"]
    local facialMarking = characterData["Facial Marking"] or ""
    local ornament = characterData.Ornament or ""
    local relic = characterData.Relic or ""

    local newCharacter = {
        id = Services.Data:GenerateId("UUID"),
        firstName = firstName,
        lastName = lastName,
        race = race,
        bodyType = bodyType,
        skinColor = skinColor,
        facialMarking = facialMarking,
        ornament = ornament,
        relic = relic,
        level = 1,
        experience = 0,
        created = os.time(),
        lastPlayed = os.time(),
        attributes = {
            STRENGTH = Modules.Stat.Templates.STRENGTH.baseValue,
            GRIT = Modules.Stat.Templates.GRIT.baseValue,
            DEXTERITY = Modules.Stat.Templates.DEXTERITY.baseValue,
            INTELLIGENCE = Modules.Stat.Templates.INTELLIGENCE.baseValue,
            RESOLVE = Modules.Stat.Templates.RESOLVE.baseValue
        }
    }

    characters[slotId] = newCharacter
    State.characters[userId] = characters
    State.activeCharacters[userId] = slotId

    Services.Data:SetData(userId, "PlayerData", State.characters[userId])

    self:SpawnCharacter(player, newCharacter)

    Services.Event:Fire("Character.Create", {
        player = player,
        characterId = newCharacter.id,
        slotId = slotId,
        character = newCharacter
    })

    return true, newCharacter.id
end

function CharacterService:LoadCharacter(player, slotId)
    if not player or not slotId then return false end

    local userId = player.UserId
    local characters = State.characters[userId] or {}

    if not characters[slotId] then
        return false, "Character does not exist"
    end

    local characterData = characters[slotId]
    characterData.lastPlayed = os.time()

    State.activeCharacters[userId] = slotId

    self:SpawnCharacter(player, characterData)

    Services.Event:Fire("Character.Load", {
        player = player,
        characterId = characterData.id,
        slotId = slotId,
        character = characterData
    })

    return true, characterData.id
end

function CharacterService:SpawnCharacter(player, characterData)
    if not player or not characterData then return end

    if player.Character then
        player.Character:Destroy()
    end

    local character = player.Character or player:LoadCharacter()

    self:ApplyAppearance(character, characterData)

    self:ApplyAttributes(character, characterData)

    return character
end

--[[ Appearance Functions ]]
function CharacterService:ApplyAppearance(character, characterData)
    if not character or not characterData then return end

    local skinColor = characterData.skinColor
    if skinColor then
        local bodyColors = character:FindFirstChild("Body Colors")
        if bodyColors then
            local color = Color3.fromHex(skinColor)
            for _, bodyPartEnum in ipairs(Enum.BodyPart:GetEnumItems()) do
                bodyColors[bodyPartEnum.Name.."Color3"] = color
            end
        end
    end

    local facialMarking = characterData.facialMarking
    if facialMarking and facialMarking ~= "" then
        local head = character:FindFirstChild("Head")
        if head then
            local marking = ReplicatedStorage.Customization.FacialMarkings:FindFirstChild(characterData.race):FindFirstChild(facialMarking)
            if marking then
                local markingClone = marking:Clone()
                markingClone.Parent = head
                markingClone.Name = "Marking"
            end
        end
    end

    local ornament = characterData.ornament
    if ornament and ornament ~= "" then
        local head = character:FindFirstChild("Head")
        if head then
            local ornamentModel = ReplicatedStorage.Customization.Ornaments:FindFirstChild(characterData.race):FindFirstChild(ornament)
            if ornamentModel then
                local ornamentClone = ornamentModel:Clone()
                ornamentClone.Parent = head
                ornamentClone.Name = "Ornament"

                if ornamentClone:FindFirstChildWhichIsA("Weld") then
                    ornamentClone:FindFirstChildWhichIsA("Weld").Part0 = head
                end
            end
        end
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayName = characterData.firstName .. " " .. characterData.lastName
    end
end

--[[ Attribute Functions ]]
function CharacterService:ApplyAttributes(character, characterData)
    if not character or not characterData then return end

    local attributes = characterData.attributes

    if attributes then
        for statName, value in pairs(attributes) do
            Services.Stat:SetStat(character, statName, value, { source = "character_load" })
        end
    else
        Services.Stat:SetStat(character, "STRENGTH", Modules.Stat.Templates.STRENGTH.baseValue, { source = "character_load" })
        Services.Stat:SetStat(character, "GRIT", Modules.Stat.Templates.GRIT.baseValue, { source = "character_load" })
        Services.Stat:SetStat(character, "DEXTERITY", Modules.Stat.Templates.DEXTERITY.baseValue, { source = "character_load" })
        Services.Stat:SetStat(character, "INTELLIGENCE", Modules.Stat.Templates.INTELLIGENCE.baseValue, { source = "character_load" })
        Services.Stat:SetStat(character, "RESOLVE", Modules.Stat.Templates.RESOLVE.baseValue, { source = "character_load" })
    end

    local raceBonuses = self:GetRaceBonuses(characterData.race)
    for statName, value in pairs(raceBonuses) do
        Services.Stat:ModifyStat(character, statName, {
            operation = "add",
            value = value,
            metadata = {
                source = "race_bonus",
                race = characterData.race
            }
        })
    end

    character:SetAttribute("CHARACTER_ID", characterData.id)
    character:SetAttribute("RACE", characterData.race)
    character:SetAttribute("FIRST_NAME", characterData.firstName)
    character:SetAttribute("LAST_NAME", characterData.lastName)
end

--[[ Validation Functions ]]
function CharacterService:ValidateCharacter(characterData)
    if not characterData then return false end

    if not characterData.FirstName or not characterData.LastName or not characterData.Race then
        return false
    end

    local validRaces = Modules.Character.Race.RaceIndex
    local raceIsValid = false

    for _, race in ipairs(validRaces) do
        if race == characterData.Race then
            raceIsValid = true
            break
        end
    end

    if not raceIsValid then
        return false
    end

    local validFirstNames = Modules.Character.Name.FirstName
    local validLastNames = Modules.Character.Name.LastName

    local firstNameIsValid = false
    local lastNameIsValid = false

    for _, name in ipairs(validFirstNames) do
        if name == characterData.FirstName then
            firstNameIsValid = true
            break
        end
    end

    for _, name in ipairs(validLastNames) do
        if name == characterData.LastName then
            lastNameIsValid = true
            break
        end
    end

    if not firstNameIsValid or not lastNameIsValid then
        return false
    end

    return true
end

--[[ Getter Functions ]]
function CharacterService:GetCharacter(player, slotId)
    if not player then return nil end

    local userId = player.UserId
    local characters = State.characters[userId] or {}

    if slotId then
        return characters[slotId]
    else
        local activeSlot = State.activeCharacters[userId]
        return activeSlot and characters[activeSlot] or nil
    end
end

function CharacterService:GetActive(player)
    if not player then return nil end

    local userId = player.UserId
    local activeSlot = State.activeCharacters[userId]

    if not activeSlot then return nil end

    local characters = State.characters[userId] or {}
    return characters[activeSlot]
end

function CharacterService:GetRaces()
    return Modules.Character.Race.RaceIndex
end

function CharacterService:GetRaceDescription(race)
    if not race then return "" end
    return Modules.Character.Race.Races[race] or ""
end

function CharacterService:GetRaceBonuses(race)
    if not race then return {} end
    return Modules.Character.Race.RaceBonuses[race] or {}
end

function CharacterService:GetNames(race)
    local firstNames = Modules.Character.Name.FirstName
    local lastNames = Modules.Character.Name.LastName

    return {
        firstNames = firstNames,
        lastNames = lastNames
    }
end

function CharacterService:GetSkinColors()
    return Modules.Character.Body.SkinIndex
end

function CharacterService:GetSkinColor(colorName)
    if not colorName then return "#FFFFFF" end
    return Modules.Character.Body.SkinColors[colorName] or "#FFFFFF"
end

return CharacterService
