### **1. Loot Sources**

- **Entity Drops**:
  Obtained from NPCs with type and variant-specific drop tables using weighted probability.
  - **Example**: **"FARMER"** - Drops wheat, apples, or occasionally a sickle.

- **Containers**:
  Physical objects that can be opened to obtain randomized loot.
  - **Example**: **"CHEST"** - Contains tier-based loot from common consumables to rare treasures.

- **Locations**:
  Environmental areas that provide loot opportunities.
  - **Example**: **"CAVE"** - May yield mineral resources or ancient relics based on tier.

- **Quest Rewards**:
  Predetermined or randomized rewards for completing objectives.
  - **Example**: **"RESCUE_MISSION"** - Rewards umbrels and potentially rare items.

---

### **2. Rarity System & Value Scaling**

- **Five-Tier Rarity System**:
  Items are classified by rarity with associated value ranges:
  1. **COMMON**: Basic items worth 5-30 umbrels
  2. **UNCOMMON**: Better items worth 25-75 umbrels
  3. **RARE**: Valuable items worth 70-150 umbrels
  4. **EPIC**: Exceptional items worth 140-300 umbrels
  5. **LEGENDARY**: Extraordinary items worth 280-600 umbrels

- **Tier-Based Generation**:
  Environmental tiers determine possible rarity outcomes:
  - **Low Tier**: Common and Uncommon items
  - **Medium Tier**: Uncommon and Rare items
  - **High Tier**: Rare, Epic, and Legendary items

---

### **3. Item Categories**

- **Valuables**:
  Currency and precious objects primarily for selling.
  - **Examples**: Jewelry, goblets, gems

- **Tools**:
  Functional items with specific utility purposes.
  - **Examples**: Fishing, farming, smithing, writing tools

- **Containers**:
  Items that hold or store other items or substances.
  - **Examples**: Flasks, bowls, mugs

- **Books & Knowledge**:
  Items containing information or magical properties.
  - **Examples**: Common books, magic tomes, scrolls, maps

- **Keys**:
  Access items for locked areas or containers.
  - **Examples**: Small keys, merchant keys, temple keys

---

### **4. Loot Generation Mechanics**

- **Weighted Probability**:
  Entity drops use weight values to determine drop chances. Higher weight means more common drops.

- **Quantity Ranges**:
  Items can drop in variable quantities with typical ranges.