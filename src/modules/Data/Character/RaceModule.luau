--[[ RaceModule
    @author @Daystopia
    @version 1.0.0
    @date 2025-04-10
]]
local RaceModule = {}

RaceModule.Races = {
	["Aetherion"] = "Tall, elegant beings with an innate connection to the astral planes. Their celestial heritage grants them a natural resilience, making them difficult to break. Many Aetherion wear flowing robes, capes, and mystical adornments to reflect their ethereal nature.",
	["Varkoth"] = "A race of beast-like humanoids, known for their raw strength and feral instincts. Their bodies are built for war, with thick hides and sharpened senses. Varkoth often wear rugged armor, gauntlets, and heavy boots, favoring function over form.",
	["Nyxian"] = "A shadow-born race with an affinity for stealth and deception. Their darkened features allow them to blend into the night, making them feared assassins. Many Nyxian adorn themselves with hoods, scarves, and lightweight gear for mobility.",
	["Sylvael"] = "Mystical forest-dwellers with an innate bond to nature. Their presence is often marked by vine-like tattoos and body markings. Sylvael prefer practical tunics and cloaks, allowing them to move seamlessly through the wilds.",
	["Drakhaar"] = "Descendants of draconic lineage, the Drakhaar bear scaled skin and an imposing presence. Some possess vestigial horns, a sign of their ancient bloodline. They favor ornate armor, capes, and heavy gauntlets, reflecting their regal yet brutal nature.",
	["Vensari"] = "Silver-tongued tricksters and cunning merchants, the Vensari are as dangerous as they are charming. Their attire leans toward the extravagant—rings, necklaces, and finely tailored robes, always ensuring they look as wealthy as they claim to be.",
	["Orionis"] = "Celestial wanderers said to be guided by the stars. Their luminous markings set them apart, hinting at their prophetic nature. Orionis often wear layered tunics, arm wrappings, and subtle jewelry to signify their mystic path.",
	["Feydrin"] = "Fae-touched beings with unpredictable tendencies. Their presence distorts reality, and their bodies often bear arcane markings. Feydrin attire is fluid and ever-changing, with scarves, cloaks, and accessories shifting as if responding to unseen forces.",
	["Gor'thar"] = "Towering brutes forged in conflict, the Gor'thar are built for war. Their heavy-set frames and tribal scars tell stories of battles fought. They favor reinforced chestplates, thick gauntlets, and war-torn capes, always ready for their next fight.",
	["Echolan"] = "Wraith-like entities tethered between life and death. Their spectral nature gives them an unsettling presence, often seen in their hollowed eyes and faded skin. Echolan prefer flowing robes, hoods, and arm wrappings, as if shrouding themselves from a world they do not fully belong to.",
}

RaceModule.RaceIndex = {
	"Aetherion", "Varkoth", "Nyxian", "Sylvael", "Drakhaar",
	"Vensari", "Orionis", "Feydrin", "Gor'thar", "Echolan"
}

RaceModule.RaceBonuses = {
    ["Aetherion"] = { INTELLIGENCE = 2, RESOLVE = 2 },
    ["Varkoth"] = { STRENGTH = 3, GRIT = 1 },
    ["Nyxian"] = { DEXTERITY = 3, INTELLIGENCE = 1 },
    ["Sylvael"] = { DEXTERITY = 2, RESOLVE = 2 },
    ["Drakhaar"] = { STRENGTH = 2, GRIT = 2 },
    ["Vensari"] = { INTELLIGENCE = 3, DEXTERITY = 1 },
    ["Orionis"] = { RESOLVE = 3, INTELLIGENCE = 1 },
    ["Feydrin"] = { DEXTERITY = 2, INTELLIGENCE = 2 },
    ["Gor'thar"] = { STRENGTH = 3, GRIT = 1 },
    ["Echolan"] = { RESOLVE = 2, INTELLIGENCE = 2 }
}

return RaceModule
