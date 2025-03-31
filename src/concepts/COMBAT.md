# Ascendium Combat System

Ascendium's combat system combines fluid movement, strategic combat mechanics, and survival elements to create an immersive fighting experience. This document outlines all combat-related mechanics and their interactions.

---

## Movement System
The movement system emphasizes freedom and fluidity, allowing players to traverse the environment dynamically.

### Core Movement Mechanics
- **Walking**: Base movement speed
- **Running**: Increased movement speed
- **Rolling & Roll Canceling**: Tactical evasion with cancel options
- **Sliding**: Momentum-based sliding movement
- **Wall Running**: Vertical surface traversal
- **Wall Climbing**: Vertical surface scaling
- **Swinging**: 
  - Automatically activates on contact with branches/swingable items
  - Maintains momentum for fluid traversal
- **Ledge Vaulting**: Environmental obstacle traversal

---

## Core Combat Features
The combat system is built around strategic engagement and skillful execution.

### Primary Systems
- **180° Blocking System**
  - Directional blocking mechanics
  - Integrated guardbreak system
- **Weapon Management**
  - Physical weapon carry system
  - Visible weapon placement on character
- **Environmental Interaction**
  - Dynamic fall damage system
  - Contextual character dialogue
- **Interface Systems**
  - Custom combat UI
  - Intuitive hotbar system
- **Combat Framework**
  - Robust ability system
  - Advanced parrying mechanics
  - Input buffering for smooth combinations
  - Carry/Knock mechanics
  - Comprehensive inventory management

---

## Game Controls
Intuitive control scheme designed for fluid combat and movement.

### Pre-Combat Controls
| Input | Action |
|-------|--------|
| W (double tap) | Sprint |
| Q | Roll |
| C | Crouch |
| CTRL + Sprint | Slide |

### Combat Controls
| Input | Action |
|-------|--------|
| M1 | Light Attack |
| M2 | Cancel Action |
| M3/R | Critical Attack |
| F | Parry |
| F (Hold) | Block |
| B | Execute KO'ed Enemy |
| V | Carry KO'ed Enemy |

### Utility Controls
| Input | Action |
|-------|--------|
| E | Interact |
| T | Emote |
| Y | Switch Stance |
| TAB | Open Inventory |

---

## Player HUD Elements
The HUD is designed for clarity and immediate feedback during combat.

### Status Bars (Top to Bottom)
1. **Blood Meter**
2. **Posture Bar**
3. **Health Bar**
4. **Mana Gauge**
5. **Cooldown Indicators**

### Blood System
A unique vitality system separate from health.

**Key Features:**
- Independent from health pool
- Affects consciousness state
- Screen darkening feedback
- Variable drain rates
- Natural regeneration
- Critical for combat survival

### Posture System
Strategic defensive mechanic preventing passive play.

**Mechanics:**
- Block pressure gauge
- Guard break threshold
- Dynamic regeneration
- Attack-based recovery
- Anti-turtle mechanism
- Parry incentivization

### Health System
Primary combat survival metric.

**Progression:**
- Base health scaling
- Multiple upgrade paths:
  - Level progression
  - Attribute allocation
  - Equipment bonuses
- Recovery mechanics:
  - Passive regeneration
  - Knock-out states
  - Execution vulnerability

### Mana System
Magical resource management.

**Characteristics:**
- Spell casting resource
- Special ability fuel
- Regenerative properties
- Strategic management requirement

---

## Survival Mechanics

### Hunger System (Orange Bar)
**Core Mechanics:**
- Time-based depletion
- Performance impacts:
  - Stamina reduction
  - Movement penalties
  - Health deterioration
- Resource management:
  - Food variety
  - Cooking system
  - Consumable effects

### Thirst System
**Core Mechanics:**
- Progressive depletion
- Status effects:
  - Health degradation
  - Stamina penalties
  - Visual impairment
- Resource options:
  - Water sources
  - Consumable liquids
  - Special beverages
  - Environmental sources

---

## Combat Feedback Systems

### Cooldown Interface
Five primary indicators:
1. **Roll/Dodge Timer**
2. **Parry Availability**
3. **Block Status**
4. **Cancel/Feint Timer**
5. **Resonance Meter**

### Combat Status
- Top screen indicator
- Active combat state display
- Engagement feedback

---

## Weapon Classifications

The combat system features three distinct weapon categories, each with unique characteristics and playstyles.

### Light Weapons
Fast, agile weapons focused on quick strikes and mobility.

**Available Types:**
- **Fists**
  - Fastest attack speed
  - Short range
  - Special: Combo system
  - Perfect for parrying

- **Daggers**
  - Quick strikes
  - Critical hit focus
  - Backstab specialists
  - High mobility

- **Guns**
  - Rapid fire
  - Ammo management
  - Medium range
  - Low posture damage

- **Rapiers**
  - Precise thrusts
  - Counter-attack focused
  - Perfect parry bonus
  - Stance-based combat

- **Nunchucks**
  - Chain combos
  - Stance variations
  - Defensive capabilities
  - Rhythm-based attacks

- **Bow**
  - Long range
  - Charged shots
  - Various arrow types
  - Stealth capability

### Medium Weapons
Balanced weapons offering versatility in combat.

**Available Types:**
- **Long Swords**
  - Balanced damage/speed
  - Versatile moveset
  - Good reach
  - All-around performance

- **Spears**
  - Extended reach
  - Thrust specialization
  - Formation fighting
  - Keep-away tactics

- **Katanas**
  - Swift strikes
  - Stance system
  - Bleeding effects
  - Counter-attack focus

- **Rifles**
  - Long range
  - High precision
  - Slower rate of fire
  - High single-target damage

- **Tridents**
  - Piercing damage
  - Sweep attacks
  - Water combat bonus
  - Multiple hit points

### Heavy Weapons
Powerful weapons emphasizing high damage and posture breaking.

**Available Types:**
- **Great Axes**
  - Highest raw damage
  - Armor breaking
  - Slow swing speed
  - Devastating criticals

- **Great Swords**
  - Wide swing arc
  - High posture damage
  - Charged attacks
  - Guard crush potential

- **Scythes**
  - Sweeping attacks
  - Death effects
  - Soul harvest mechanic
  - Extended reach

### Weapon Properties

**Common Attributes:**
- Durability
- Sharpness
- Weight
- Base Damage
- Special Effects

**Category-Specific Traits:**
- Light: Higher attack speed, lower stamina cost
- Medium: Balanced stats, versatile movesets
- Heavy: High damage, high stamina cost, posture break focus

**Upgrade Paths:**
- Physical enhancement
- Magical infusion
- Special effect augmentation
- Unique weapon arts