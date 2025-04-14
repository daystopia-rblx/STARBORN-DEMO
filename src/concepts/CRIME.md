### 🔪 Crime System

Ascendium's crime system focuses on direct consequences for witnessed actions, emphasizing player aptitude in stealth and circumvention.

---

### Crime Mechanics
The fundamental actions and rules governing criminal activities.

#### Types of Criminal Activities
- **Theft**: Stealing owned items from containers, stores, or the environment. Ownership is key; taking unowned items is not a crime.
- **Burglary**: Unlawfully entering a restricted location *and* committing theft within.
- **Pickpocketing**: Attempting to steal directly from an entity's inventory.
- **Assault**: Attacking a non-hostile entity.
- **Murder**: Killing a non-hostile entity.
- **Trespassing**: Entering owned, restricted areas (marked private or requiring a lockpick/key/Invocation) without permission.

### Trespassing & Entry Mechanics
Focuses on bypassing locks and magical wards.
- **Lock Picking**: The primary method for opening standard locked doors and containers. Success depends on the player's **DEXTERITY** versus the difficulty rating of the lock. Higher Dexterity makes picking easier and allows tackling harder locks. Lock difficulty ranges from Novice to Master. Breaking lockpicks can create noise.
- **Keys**: Using the correct key instantly unlocks the corresponding door or container. Keys can be found, stolen, or received as quest rewards.
- **Magical Bypass**: Certain magical locks or wards require specific **Invocations** to dispel or bypass. Knowledge of the correct Invocation is needed, potentially learned through scrolls, quests, or interaction with Authority shrines. Failure might trigger alarms or magical backlash.

#### Theft Mechanics
Actions involved in illegally acquiring items.
- **General Theft**: Taking any item marked as owned by an entity or Faction. Detection is based on being seen or heard (see Detection System).
- **Pickpocketing**: Attempting to take items from an entity's inventory. Success chance is based on the player's **DEXTERITY** versus the target's awareness, influenced by visibility (light/LoS) and player movement noise. Item weight/value can affect difficulty and detection risk. Failure results in immediate detection.

---

### Detection System
Based primarily on direct witnessing by entities.

#### Core Detection Factors
Whether a crime is noticed depends on:
- **Line of Sight (LoS)**: An entity must see the player committing the crime. Darkness and obstructions block LoS.
- **Sound**: Loud actions (breaking lockpicks, failed Invocations, fighting, shouting) can attract nearby entities, even without direct LoS. Player movement noise (running vs. sneaking, heavy armor) also contributes.
- **Player Stealth**: Effectiveness of sneaking is governed by the player's **DEXTERITY** attribute. Higher Dexterity reduces visibility and noise, making detection less likely. Crouching activates sneak mode. Some **Invocations** might temporarily enhance stealth (e.g., muffling sound, brief invisibility).
- **Light Level**: Player is harder to see in darker areas.

#### Witness Reaction & Reporting
- **Detection**: If an entity detects a crime (sees or hears definitively):
    - **Civilians**: May flee, alert nearby guards, or sometimes confront the player (depending on personality).
    - **Guards**: Will immediately attempt to arrest the player if a bounty is incurred.
- **Reporting**: Detected crimes are reported to the local **Guard/Faction** authority, adding a **Bounty** to the player in that specific region/jurisdiction. Not all witnesses successfully report immediately (e.g., if silenced quickly).

#### Jurisdiction
- **Regional Bounties**: Bounties are tracked per major region (e.g., City-State, County) controlled by a specific authority (e.g., City Guard, Faction). Committing a crime in one region does not automatically apply the bounty in another, unless authorities share information.
- **Faction Territory**: Crimes against a specific faction or within their owned territory heavily impact **Faction Standing** and contribute to the bounty in the region they control/influence.

---

### Consequences System
Direct repercussions for reported crimes.

#### Bounty System
Monetary penalty assigned for reported crimes within a specific jurisdiction.
- **Accumulation**: Bounty increases with each reported crime. Severity dictates the amount (Murder > Assault > Burglary > Theft/Pickpocket/Trespass). Item value influences Theft/Burglary bounty amount.
- **Persistence**: Bounties remain active in a jurisdiction until cleared. They do not decay over time and are persistent across different game servers.
- **Clearing Bounties**:
    - **Pay Guards**: Pay the full bounty amount to a guard within that jurisdiction.
    - **Serve Jail Time**: Surrender to a guard and serve time. May involve skill degradation or temporary debuffs upon release. Escaping jail is possible but difficult and increases bounty/infamy.
    - **Faction Intervention**: High standing with the ruling faction might allow negotiation or reduction (rare). Certain factions (e.g., Shattered Fang) might offer alternative, less reputable methods for members.

| Crime Type    | Typical Bounty Range  | Notes                               |
|---------------|-----------------------|-------------------------------------|
| Trespassing   | Low (e.g., 5-25)      | Minor offense if detected entering. |
| Theft         | Low-Medium (Value based) | Based on stolen item value.       |
| Pickpocket    | Low-Medium (Value based) | Based on stolen item value.       |
| Burglary      | Medium (Value based)  | Trespass + Theft combined.        |
| Assault       | Medium-High (e.g., 40-100) | Significant rep loss.             |
| Murder        | High (e.g., 1000+)    | Major rep loss.                     |

#### Law Enforcement Response
How guards react to players with active bounties in their jurisdiction.
- **Arrest Attempt**: Guards who detect a player with a bounty will attempt dialogue: "Wait, I know you..." leading to options:
    - **Pay Bounty**: Clears bounty in the region.
    - **Go to Jail**: Initiates the jail sequence.
    - **Resist Arrest**: Guards become hostile and attack. Other nearby guards will join.
- **Hostility**: If a player resists arrest or commits a crime directly witnessed by guards, they become immediately hostile.

#### Reputation Impact
Focuses on Faction Standing and entity disposition.
- **Faction Standing**: Crimes committed against a faction or within their jurisdiction significantly lower reputation with that faction, potentially locking off quests, services, or dialogue options.
- **Entity Disposition**: Entities who witness a crime or belong to the wronged faction may become hostile or refuse services (trade, quests, dialogue). This is generally a state change rather than granular memory.

---

### Location & Security
Environments where crimes occur and their protective measures.

#### Ownership & Trespassing
- **Clear Ownership**: Locations, containers, and items are clearly marked (e.g., red text for owned items when crosshair is over them) indicating theft/trespass is a crime.
- **Restricted Areas**: Areas marked as private, locked, or requiring explicit permission are considered trespassing zones.

#### Security Features
Focuses on locks, wards, and guard presence.
- **Lock Difficulty**: Locks have clear difficulty tiers (e.g., Novice, Apprentice, Adept, Expert, Master). Success in picking depends on player **DEXTERITY** versus lock difficulty.
- **Magical Wards**: Some high-security locations may be protected by magical wards linked to specific **Authorities**. Bypassing these requires specific **Invocations** or potentially unique items/methods related to that Authority.
- **Guard Presence**: The number, skill level, and patrol routes of guards determine the likelihood of being caught. Higher security areas have more vigilant guards.
- **Entity Schedules**: Basic schedules (e.g., shops closed at night, homes occupied at night) influence entity presence, affecting opportunities and risks.

---

### Gameplay Integration
How the crime system connects with other game mechanics.

#### Attribute Focus (Dexterity) & Invocations
Player attributes and magical knowledge are central to successful criminal activity.
- **Dexterity**: Directly influences the chance of success for:
    - **Sneaking**: Reduces detection probability (visibility/noise).
    - **Lockpicking**: Enables opening standard locked doors/containers vs. lock difficulty.
    - **Pickpocketing**: Enables stealing from entities vs. target awareness/item weight.
- **Invocations**: Can provide alternative solutions or necessities:
    - **Magical Bypass**: Required for certain wards/locks.
    - **Enhanced Stealth**: Invocations can provide enhanced stealth (muffle, invisibility).
- **Speech/Persuasion**: Offers dialogue options to bribe guards (minor bounties) or persuade witnesses (rare), governed by a separate attribute (e.g., Intelligence/Resolve/Charisma).

#### Criminal Infrastructure
Systems supporting the criminal playstyle.
- **Fences**: Specific merchants willing to buy stolen goods (marked as such). These may be independent or loosely affiliated with less scrupulous factions or underground networks.

#### Opportunities & Rewards
- **Loot**: Accessing restricted areas or pickpocketing yields items/gold.
- **Quests**: Certain Faction quests (e.g., from Shattered Fang) or specific entity quests may require criminal actions.
- **Alternative Solutions**: Stealth, theft, and Invocations can provide non-combat ways to achieve objectives.

---

### Memory & Persistence
Focuses on active states and faction reputation.

#### World State Memory
- **Active Bounties**: The system tracks the player's current bounty amount in each major jurisdiction.
- **Faction Reputation**: Factions remember crimes committed against them, affecting the player's standing.

#### Entity Memory
- **Immediate Reaction**: Entities witnessing a crime react immediately (report, flee, fight).
- **Hostility State**: Entities who witness a crime or belong to the wronged faction enter a persistent hostile or non-interactive state towards the player.
