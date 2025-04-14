### 🔄 Trade System

---

### Ownership Mechanics

#### Types of Ownership
- **PRIVATE**: Items or locations exclusively owned by a specific entity. Only the owner can access without permission.
- **PUBLIC**: Freely accessible items or locations. Anyone may interact despite nominal ownership.
- **RESTRICTED**: Access limited by reputation thresholds. Only entities with sufficient standing may interact.
- **FACTION**: Ownership tied to a faction. Access determined by faction standing and relationship.
- **TEMPORARY**: Time-limited ownership that reverts or changes under specific conditions.

#### Ownership Attribution
- **Direct Attribution**: Items have "OWNER" attributes identifying their owner entity by ID.
- **Persistence**: Ownership persists across sessions and transfers.
- **Non-Ownership**: Items without owners are available to be claimed by any entity.

---

### Trade Mechanics

#### Transfer Types
- **Direct Transfer**: Voluntary handover of ownership from one entity to another.
- **Trade Exchange**: Mutual transfer of items, potentially with currency adjustment.
- **Theft**: Involuntary transfer through criminal action.
- **Quest Reward**: Automatic transfer as part of quest completion.
- **Crafting Output**: Creation of new owned items through crafting.

#### Trade Protocol
1. **Initiation**: Source entity creates a request with target entity and item details.
2. **Validation**: System checks ownership rights and permissions.
3. **Notification**: Target entity receives notification of pending request.
4. **Review**: Target entity can examine offered items and conditions.
5. **Decision**: Target entity accepts, rejects, or counter-offers. 
6. **Execution**: Upon acceptance, ownership attributes change, registering new ownership.
7. **Confirmation**: Both entities receive confirmation of completed transfer.

#### Special Cases
- **Secure Trades**: Two-way exchanges require mutual confirmation before execution.
- **Conditional Transfers**: Ownership changes only when specific conditions are met.
- **Bulk Transfers**: Multiple items can be transferred in a single transaction.
- **Restricted Items**: Some items may be marked as untradeable or bound to their owner.

#### Request States
- **PENDING**: Awaiting response from target entity.
- **COMPLETED**: Successfully executed and ownership transferred.
- **REJECTED**: Declined by target entity.
- **EXPIRED**: No response within time limit.
- **CANCELLED**: Withdrawn by source entity.

---

### Permission System

#### Access Control
- **Owner Access**: Original owner always has unrestricted access.
- **Reputation-Based**: Access granted based on reputation thresholds.
- **Faction-Based**: Access determined by faction relationship and standing.
- **Location-Based**: Different rules may apply in different zones or locations.

#### Permission Levels
| Level | Description | Typical Threshold |
|-------|-------------|-------------------|
| HOSTILE | No access, may trigger defensive response | Below -50 reputation |
| SUSPICIOUS | Limited access, heightened scrutiny | -50 to -20 reputation |
| NEUTRAL | Basic access to public functions | -20 to +20 reputation |
| FRIENDLY | Expanded access and favorable terms | +20 to +50 reputation |
| ALLIED | Full access except critically restricted functions | Above +50 reputation |

#### Permission Hierarchy
- **Ownership Type**: Defines the basic access framework (PRIVATE most restrictive, PUBLIC least).
- **Reputation Level**: Further refines access within the ownership type framework.
- **Special Overrides**: Quests, faction status, or special conditions may override standard permissions.
- **Zone Rules**: Different regions may enforce different permission rules based on local customs.

---

### Economy Integration

#### Value Assessment
- **Base Value**: Each item has intrinsic worth based on rarity and utility.
- **Condition Modifiers**: Item condition may affect trade value.
- **Market Fluctuation**: Prices and trade values may shift based on supply/demand.
- **Reputation Impact**: Higher reputation can lead to more favorable terms.

#### Currency Exchange
- **Direct Sales**: Items can be exchanged for currency.
- **Bartering**: Items can be traded for other items of comparable value.
- **Weighted Trades**: Mixed exchanges of items and currency to balance value.

---

### Theft and Illegitimate Transfers

#### Stolen Items
- **Stolen Flag**: Items acquired through theft maintain metadata about their original owner.
- **Detection Risk**: Possession of stolen items increases risk of detection by authorities.
- **Fencing**: Specialized merchants required to convert stolen goods into currency.
- **Recovery**: Original owners may seek recovery of stolen items through quests or authority intervention.

#### Ownership Disputes
- **Proof of Ownership**: Some items may require verification of legitimate ownership.
- **Authority Intervention**: In disputed cases, faction authorities may adjudicate ownership.
- **Confiscation**: Authorities may seize illegitimately acquired items.

---

### Location Ownership

#### Property Types
- **Personal Dwellings**: Private homes with highly restricted access.
- **Faction Holdings**: Territory controlled by a specific faction.
- **Public Spaces**: Areas with universal access despite nominal ownership.
- **Commercial Establishments**: Shops and services with time-based access rules.

#### Property Rights
- **Access Control**: Owners can restrict entry to their property.
- **Storage Rights**: Secure storage of items within owned locations.