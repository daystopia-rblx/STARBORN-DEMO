### **1. Affliction Types**

- **Contagious Illnesses**:
  Contracted through exposure to pathogens or infected areas like swamps or caves.
  - **Example**: **"Marsh Rot"** - Progressive vitality drain in swamp areas with stages causing stamina loss and slowed movement.

- **Environmental Effects**:
  Physical conditions caused by extreme environments like deserts or mountains.
  - **Example**: **"Desert Heat"** - Progressive dehydration and exhaustion from extreme heat exposure.

- **Magical Afflictions**:
  Caused by exposure to unstable arcane energies or dark magic.
  - **Example**: **"Arcane Flux"** - Resonance instability causing random magical surges and health damage.

- **Undead Curses**:
  Supernatural maladies transmitted by undead entities or cursed locations.
  - **Example**: **"Grave Chill"** - Spectral cold that intensifies at night, draining health and resolve.

- **Elemental Maladies**:
  Element-based conditions from exposure to pure elemental forces.
  - **Example**: **"Stone Lungs"** - Progressive petrification of respiratory system in earth-aligned areas.

---

### **2. Affliction Structure & Mechanics**

- **Progressive Stages**:
  Three distinct stages with increasing severity, each lasting 15-120 minutes of real-time gameplay:
  1. **Early Symptoms**: Minor stat debuffs (5-15% reduction)
  2. **Advanced Infection**: Significant impairments (20-40% reduction)
  3. **Critical Condition**: Life-threatening debuffs (50%+ reduction)

- **Dynamic Symptoms**:
  Stage-dependent effects that impact:
  - Core stats (Health, Stamina, Resonance)
  - Regeneration rates
  - Movement capabilities
  - Combat effectiveness

- **Area-Based Transmission**:
  Infection chances tied to specific environment types:
  ```lua
  zones = {"SWAMP", "CAVE", "CRYPT"} -- Infection only occurs in these areas
  infectionChance = 0.05 -- 5% chance per check interval
  ```

---

### **3. Cures & Remedies**

- **Tiered Treatment System**:
  - **Basic Remedies**: Temporary relief (30-50% effectiveness)
  - **Advanced Cures**: Stage reversal (70-90% effectiveness)
  - **Master Solutions**: Complete cure + temporary immunity