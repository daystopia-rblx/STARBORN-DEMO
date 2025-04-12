## 🔪 **Crime System**

### 1. 🕵️ **Types of Criminal Activities**

- **Theft** – Stealing from stores, NPCs, or other players
- **Burglary** – Breaking into locations AND stealing items
- **Pickpocketing** – Stealing directly from NPCs
- **Assault** – Attacking NPCs or players in safe zones
- **Murder** – Killing NPCs or players outside of combat zones
- **Vandalism** – Destroying property or environment
- **Trespassing** – Entering restricted areas without permission

---

### 2. 🏠 **Location-Based Crimes**

#### Types of Locations
- **Private Homes** – Breaking into private residences to steal valuables
- **Shops & Taverns** – Stealing from merchants and innkeepers during or after hours
- **Noble Estates** – High-security targets with valuable loot and harsh consequences
- **Government Buildings** – Highest security and bounties, but extremely valuable items
- **Faction Halls** – Special restricted locations with unique items and faction penalties

#### Security Levels
- **None (0)** – Wilderness areas, minimal detection chance
- **Low (1)** – Common homes, no guards, simple locks
- **Medium (2)** – Shops, taverns, average detection and security
- **High (3)** – Noble homes, faction halls, advanced detection
- **Maximum (4)** – Castles, treasuries, extensive guards and magical defenses

---

### 3. 🔒 **Breaking & Entering Mechanics**

#### Trespassing
- **Lock Picking** – Skill-based system with difficulty based on lock level
- **Detection Factors**:
  - Time of day (night vs. day)
  - Player's stealth skill
  - Security level of location
  - Number of guards or NPCs present
- **Magical Locks** – Some doors require keys or special magical abilities to bypass
- **Special Defenses**:
  - **Magical Wards** – Higher detection chance, magical requirements to bypass
  - **Traps** – Physical damage or alarm systems

#### Stealing (Interior Theft)
- **Item Value Tiers** – Low, medium, and high value items in different containers
- **Location-specific Loot** – Different valuable items based on location type
- **NPC Schedules** – NPCs may leave homes during day, changing security level
- **Sleeping NPCs** – Higher chance to steal but also higher consequences if caught

---

### 4. 👁️ **Detection System**

#### Theft Detection
- **Base Detection Chance**: 40%
- **Contributing Factors**:
  - Player's Stealth skill (reduces chance)
  - Security level of target (increases chance)
  - Value of stolen goods (higher value = higher detection risk)
  - Environmental factors (time of day, weather, etc.)

#### Witnesses
- **Line of Sight** – NPCs must see you to report crimes
- **NPC Relationship** – Higher relationship reduces chance they'll report you
- **Guard Density** – More guards means higher detection chance

#### Region-Based Reporting
- **Wilderness** – 10% chance a crime is reported
- **Villages** – 40% chance a crime is reported
- **Cities** – 70% chance a crime is reported
- **Different Laws** – Some regions may have different laws or enforcement levels

---

### 5. ⚖️ **Bounty System**

- **Dynamic Bounties** – Crime severity and target value determine bounty amount
- **Bounty Hunters** – Both NPCs and players can hunt criminals with bounties
- **Reputation Recovery** – Clearing bounties through payment or serving time
- **Bounty Expiration** – Bounties naturally decay over time (7 days by default)

#### Crime Types & Bounties
- **Trespassing** – Entering locked private property (25-50 Umbrels)
- **Theft** – Stealing items (Value × 0.5, minimum 50 Umbrels)
- **Burglary** – Breaking in AND stealing (Value × 0.75, minimum 75 Umbrels)
- **Assault** – Attacking non-hostile NPCs (100 Umbrels + reputation loss)
- **Murder** – Killing NPCs (300-500 Umbrels + major reputation loss)

---

### 6. 📉 **Reputation Consequences**

- **Individual NPC Relationships** – Specific NPCs will remember your crimes against them
- **Faction Standing** – Criminal activity affects your standing with various factions
- **Global Reputation** – A city-wide or world-wide infamy system
- **Service Restrictions** – High infamy limits access to certain merchants or services

#### Multi-Tiered Response
- **Warning** – For minor infractions, sometimes just a warning
- **Fine** – Pay off your bounty directly to guards
- **Jail Time** – Alternative to paying fines, serves time in jail
- **Manhunt** – High bounties trigger active pursuit by guards
- **Execution** – For highest bounties or repeated offenses

#### Faction-Specific Consequences
- **Faction Reputation** – Crimes against faction members impact standing
- **Guild Expulsion** – Criminal guilds may expel members who get caught too often
- **Faction Territory** – Different factions control different areas with own rules

---

### 7. ⚡ **Gameplay Integration**

#### Skill Progression
- **Stealth** – Improves through successful sneaking and theft
- **Lockpicking** – Improves by picking locks, especially difficult ones
- **Pickpocket** – Improves through successful pickpocketing
- **Speech** – Used to talk your way out of certain situations with guards

#### Criminal Activities
- **Fences** – Special merchants who buy stolen goods
- **Thieves' Guild** – Faction that provides bonuses to criminal activities
- **Special Quests** – Unlocked based on criminal reputation
- **Unique Items** – Some items can only be acquired through theft

#### Risk vs. Reward
- **Rare Items** – Higher security locations contain rarer valuables
- **Unique Decoration** – Stolen items can be displayed in player homes
- **Quest-Specific Items** – Some quests require stealing specific items
- **Criminal Reputation** – Some NPCs/quests only available with criminal history

---

### 8. 🧠 **Memory System**

#### NPC Memory
- **Long-Term Consequences** – NPCs remember crimes against them
- **Reputation Recovery** – Reputation gradually recovers over time
- **NPC Schedules** – NPCs follow daily routines affecting security
- **Guard Patrols** – Guards patrol different areas based on time and alerts

#### Criminal Record
- **Crime History** – System tracks types and frequency of crimes
- **Repeat Offender** – Increased penalties for repeat offenses
- **Criminal Identity** – Option to create criminal persona/disguise
- **Bounty Hunters** – High bounties attract special NPCs who hunt the player

---

### 9. 🌐 **Technical Implementation**

#### Location System
- **Interior/Exterior Tracking** – System knows player location at all times
- **Region-Based Rules** – Different regions have different crime parameters
- **Property Ownership** – Every location has defined ownership and permissions
- **Container Ownership** – Tracking what belongs to whom

#### Bounty System
- **Per-Region Bounties** – Separate bounties for each region
- **Bounty Expiration** – Bounties naturally decline over time if crimes stop
- **Bounty Cleansing** – Methods to remove bounties (payment, faction favor, time)
- **Bounty Thresholds** – Different response levels based on bounty amount

#### Guard System
- **Guard AI** – Smart pursuit and coordination
- **Guard Communication** – Guards share information about criminals
- **Guard Scheduling** – Different patrol patterns and density by time/location
- **Guard Types** – Different guards with various detection and combat abilities