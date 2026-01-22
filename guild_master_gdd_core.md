# Guild Master - Core Game Design Document

## High Concept
A fantasy guild management simulation where you recruit, train, and command adventurers on quests. Features intelligent AI-driven party members, deep character progression, and a living world that reacts to your choices.

**Platform:** iOS  
**Target Development Time:** 18-24 months (realistic scope)  
**Genre:** Management Simulation / Strategy RPG  
**Core Inspiration:** Football Manager + Darkest Dungeon + Baldur's Gate

---

## Core Gameplay Loop

1. **Manage Guild Hall** - Review resources, upgrade facilities, check reports
2. **Recruit Adventurers** - Scout, interview, hire from various races/classes
3. **Prepare Expedition** - Assign party, equip items, brief on quest
4. **Execute Quest** - Turn-based tactical combat with AI party members
5. **Debrief & Results** - Distribute rewards, manage morale, handle consequences
6. **World Response** - Events trigger based on success/failure, reputation shifts

---

## Character System

### Primary Stats (1-20 scale)
- **STR** (Strength) - Physical damage, carry capacity, intimidation
- **DEX** (Dexterity) - Initiative, dodge, ranged/finesse attacks
- **CON** (Constitution) - HP pool, stamina, poison/disease resistance
- **INT** (Intelligence) - **AI Decision Quality**, spell power (arcane), perception
- **WIS** (Wisdom) - Spell power (divine), insight, willpower saves
- **CHA** (Charisma) - **Leadership/Influence**, persuasion, party morale buff

### Intelligence-Driven AI Behavior
**Low INT (1-8):** 
- Makes obvious tactical errors
- Ignores environmental hazards
- Uses abilities randomly
- Poor target prioritization

**Medium INT (9-14):**
- Follows basic tactics
- Recognizes threats
- Uses abilities situationally
- Decent target selection

**High INT (15-20):**
- Optimizes action economy
- Exploits enemy weaknesses
- Coordinates with allies
- Adapts to changing battlefield

### Charisma-Driven Influence
**Leadership Mechanics:**
- High CHA characters can be designated **Captain**
- Captain rating = (INT + CHA) / 2
- Good captains improve team coordination, morale recovery
- Can override low-INT decisions in critical moments
- Charisma affects: negotiation outcomes, morale recovery speed, rebellion prevention

### Secondary Stats
- **HP** - Derived from CON × 5 + class modifier
- **Stamina** - Physical ability resource, CON × 3
- **Mana** - Magical resource, (INT + WIS) × 2
- **Initiative** - DEX + class modifier
- **Morale** - Affected by success/failure, CHA, conditions
- **Stress** - Darkest Dungeon-style mental health (accumulates from trauma)

### Satisfaction System
Each adventurer tracks satisfaction (0-100):

**Factors Increasing Satisfaction:**
- Quest success
- Fair loot distribution
- Rest periods
- Guild upgrades (better beds, training grounds)
- Compatible party members
- Fulfilling personal goals/traits

**Factors Decreasing Satisfaction:**
- Quest failure
- Injuries/death of allies
- Greed conflicts (loot disputes)
- Incompatible party dynamics
- Overwork without rest
- Broken promises

**Consequences:**
- <30: Risk of desertion, poor performance
- 30-70: Normal operation
- 70+: Loyalty bonuses, performance boost, mentor juniors

---

## Races & Cultural Traits

### Playable Races (for Guildmaster & Adventurers)

**Humans**
- Balanced stats, adaptable
- Trait: "Jack of All Trades" - faster skill learning
- Cultural variants: Imperial (discipline), Nomad (survival), Merchant (negotiation)

**Elves**
- High DEX, INT; Lower CON, STR
- Trait: "Ancient Knowledge" - bonus to arcane abilities
- Variants: High Elf (magical), Wood Elf (nature), Dark Elf (subterfuge)

**Dwarves**
- High CON, STR; Lower DEX, CHA
- Trait: "Stone Blood" - poison/disease resistance
- Variants: Mountain (warriors), Deep (miners), Sky (engineers)

**Orcs**
- High STR, CON; Lower INT, CHA
- Trait: "Battle Fury" - damage boost at low HP
- Variants: Plains (honorable), Ash (shamanic), Iron (disciplined)

**Halflings**
- High DEX, CHA; Lower STR, CON
- Trait: "Lucky" - re-roll critical failures once per quest
- Variants: Shire (social), River (agile), Shadow (sneaky)

**Tieflings**
- Varied stats, +CHA
- Trait: "Infernal Legacy" - fire resistance, intimidation bonus
- Social penalty: Lower starting reputation with lawful factions

**Dragonborn**
- High STR, CHA; Lower DEX
- Trait: "Draconic Breath" - elemental breath weapon ability
- Color determines breath type and personality tendency

---

## Classes & Backgrounds

### Base Classes (8 core)

1. **Warrior** - High HP, melee tank
2. **Ranger** - Ranged DPS, tracking, survival
3. **Rogue** - Stealth, traps, critical strikes
4. **Paladin** - Tank/support, divine magic
5. **Mage** - Arcane DPS, crowd control
6. **Cleric** - Healing, buffs, divine magic
7. **Druid** - Shapeshifting, nature magic, versatile
8. **Bard** - Support, CHA-based buffs, skill monkey

### Backgrounds (Job History)
Backgrounds provide skill bonuses and trait modifiers:

- **Soldier** - +Discipline, +Tactics, follows orders well
- **Scholar** - +INT skills, +Lore, poor physical stats
- **Criminal** - +Stealth, +Lockpicking, trust issues
- **Noble** - +CHA, +Resources, entitled personality
- **Farmer** - +CON, +Survival, humble, loyal
- **Merchant** - +Negotiation, +Appraisal, profit-motivated
- **Acolyte** - +Divine knowledge, +Medicine, faithful
- **Outlander** - +Survival, +Nature, independent streak

**Background Compatibility:** Nobles clash with Criminals, Soldiers respect discipline, etc.

---

## Quest System

### Quest Types

1. **Extermination** - Slay monsters/bandits
2. **Rescue** - Save prisoners/captives
3. **Escort** - Protect VIP through danger
4. **Retrieval** - Find and return item/person
5. **Investigation** - Solve mystery, gather intel
6. **Defense** - Hold position against waves
7. **Infiltration** - Stealth mission, minimize combat
8. **Diplomacy** - Negotiate with hostile faction

### Quest Structure
- **Preparation Phase** - Choose party, buy supplies, gather intel
- **Travel Phase** - Random encounters, resource management
- **Main Objective** - 2-5 combat/challenge encounters
- **Return Phase** - Carry loot, potential ambush
- **Debrief** - Distribute rewards, handle consequences

### Quest Rewards
- **Gold** - Guild operating budget
- **Items** - Equipment, consumables, rare artifacts
- **Reputation** - With factions/nations
- **Experience** - Character progression
- **Story Progress** - Unlock quest chains, world events
- **Unlocks** - New recruits, facilities, regions

### Quest Generation
- **Contract Board** - Available quests based on reputation, world state
- **Urgent Requests** - Time-limited, high reward/risk
- **Story Quests** - Main narrative branches
- **Faction Quests** - Reputation building with specific groups
- **Random Events** - Reactive to world state

---

## Combat System

### Turn-Based Tactical Combat
- **Grid-based positioning** (hex or square, TBD based on scope)
- **Initiative order** - DEX-based with modifiers
- **Action Economy** - Move + Action per turn, bonus actions for some abilities
- **Environmental Interaction** - Cover, high ground, hazards
- **Line of Sight** - Affects ranged attacks, spell targeting

### AI Party Member Behavior
Intelligence determines decision trees:

**Low INT Example:**
- Turn 1: Charge nearest enemy
- Turn 2: Attack same target regardless of HP
- Turn 3: Ignore healing opportunities

**High INT Example:**
- Analyzes party composition
- Prioritizes threats (enemy healers first)
- Positions for flanking bonuses
- Uses consumables tactically
- Protects low-HP allies

**Captain Override:**
- High INT+CHA captain can issue commands mid-combat
- "Focus fire," "Defensive formation," "Retreat"
- Low CHA = party may ignore orders if stressed/low morale

### Combat Challenges
- **Elite Enemies** - Mini-boss encounters
- **Environmental Hazards** - Traps, lava, collapsing structures
- **Reinforcements** - Mid-combat enemy waves
- **Objectives** - Not all fights are "kill all enemies"

---

## Rival Guilds

### Rival Mechanics
- **3-5 rival guilds** in the region
- Each has distinct personality, specialty, reputation
- Compete for the same contracts

**Rival Actions:**
- **Contract Stealing** - Outbid you on lucrative quests
- **Sabotage** - Spread rumors, lower your reputation
- **Ambush** - Attack your parties returning from quests
- **Poaching** - Offer better deals to your adventurers
- **Alliance** - Temporary cooperation for major threats

**Counter-Strategies:**
- Build strong reputation to lock contracts early
- Hire spies to learn rival plans
- Form alliances with factions
- Direct confrontation (high risk)

---

## Faction & Reputation System

### Major Factions

1. **The Crown** - Ruling monarchy, lawful quests
2. **Mages' Conclave** - Arcane research, magical threats
3. **Thieves' Guild** - Underground economy, shadowy contracts
4. **Church of Light** - Religious authority, holy quests
5. **Merchant Consortium** - Trade, escort, economic missions
6. **Druidic Circle** - Nature preservation, fey threats
7. **Tribal Confederacy** - Honor culture, orc/barbarian clans

### Reputation Tiers
- **Hostile (-100 to -50)** - Attacks on sight, no access
- **Unfriendly (-49 to -10)** - Poor prices, limited quests
- **Neutral (-9 to +9)** - Standard interactions
- **Friendly (+10 to +49)** - Better prices, more quests
- **Allied (+50 to +100)** - Exclusive contracts, special recruits, discounts

### Special Recruitment
High faction rep unlocks unique adventurers:
- Crown: Elite Knights with "Sworn Oath" trait
- Mages: Battlemages with rare spells
- Thieves: Master Infiltrators
- Church: Inquisitors, Paladins
- Druids: Wildshape specialists
- Tribes: Berserkers, Shamans

---

## World Events & Dynamics

### Dynamic World State
The world changes based on time and player actions:

**Event Types:**
- **Political Upheaval** - Leadership changes, war declarations
- **Natural Disasters** - Floods, earthquakes affect regions
- **Monster Invasions** - Surge in specific quest types
- **Economic Shifts** - Prices fluctuate, trade routes change
- **Plagues** - Healing quests spike, travel risks increase

**Quest Availability:**
- Peaceful region: Low combat quests, high escort/delivery
- War-torn region: High extermination, rescue, defense
- Plague-hit region: Investigation, herb gathering, escort healers

**Recruitment Changes:**
- Refugee influx: More desperate, cheap recruits
- Post-war: Veterans available but traumatized (high stress)
- Prosperity: Fewer adventurers, higher prices

---

## Progression & Story Branches

### Guild Progression
- **Facilities** - Barracks, Training Grounds, Infirmary, Tavern, Vault
- **Upgrades** - Improve capacity, efficiency, unlock features
- **Staff** - Hire non-combat NPCs (healer, blacksmith, trainer, spy)

### Story Branches (3 Major Paths)

**Path 1: Heroic Guardian**
- Focus: Protect the realm, defeat ancient evil
- Quests: Aid all factions equally, defeat demon lord/dragon
- Ending: Become legendary heroes, guild becomes official kingdom force

**Path 2: Conqueror**
- Focus: Build military power, dominate region
- Quests: Mercenary work, hostile takeovers, faction wars
- Ending: Establish your own kingdom/empire through force

**Path 3: Harbinger of Chaos**
- Focus: Accelerate world collapse, embrace darkness
- Quests: Sabotage factions, release sealed evils, betray allies
- Ending: World falls into darkness, you rule the ruins

**Branching Points:**
- Major story quests have moral choices
- Faction allegiances lock out others
- Accumulation of reputation/infamy
- Key character decisions (sacrifice, betrayal)

---

## Roguelike Elements (NOT Procedural)

### Fixed Content, Permadeath Options
- **Campaign Mode** - Standard play, adventurer death is permanent
- **Story Mode** - Injured retire, can be replaced
- **Hardcore Mode** - Guild destruction ends run completely

### Randomized Each Playthrough
- **Adventurer Pool** - Different recruits available each campaign
- **Event Order** - World events trigger in varied sequences
- **Loot Distribution** - Item drops randomized within tables
- **Rival Behavior** - AI guilds make different strategic choices

### Meta-Progression (Optional)
- **Legacy System** - Retired guilds leave bonuses (starting gold, unlocked classes)
- **Codex** - Unlocked lore entries persist
- **Achievements** - Track across playthroughs

---

## UI/UX Design

### Visual Style
- **Minimalist Fantasy** - Clean, readable, no clutter
- **Color Palette** - Muted whites, yellows, parchment tones
- **Light Mode Focus** - Papyrus/old paper aesthetic
- **Fonts** - Times New Roman for body, stylized ancient text for headers
- **Iconography** - Simple, symbolic, fantasy medieval inspired

### Core Screens

1. **Guild Hall Hub** - Central navigation, resource overview
2. **Contract Board** - Available quests, filtering, details
3. **Barracks** - Adventurer roster, stats, equipment
4. **World Map** - Travel, regions, factions, events
5. **Combat View** - Grid battlefield, character portraits, action UI
6. **Management Ledger** - Finances, reputation, world state tracking

### Mobile-Specific Considerations
- **Portrait Orientation Primary** - Easier one-handed use
- **Gesture Controls** - Swipe to navigate, tap to select
- **Auto-Save** - Preserve progress for interrupted sessions
- **Battery Optimization** - Turn-based = lower power draw than real-time

---

## Technical Considerations

### Development Tools (Claude Code Assisted)
- **Engine:** Unity (best iOS support) or Godot (open-source)
- **Language:** C# (Unity) or GDScript (Godot)
- **Data Management:** JSON/SQLite for save data, character sheets
- **AI System:** Utility AI or Behavior Trees for party member decisions
- **Version Control:** Git + GitHub

### Minimum Viable Product (MVP) Scope
To hit 12-month timeline, CUT to MVP:

**KEEP:**
- 4 races (Human, Elf, Dwarf, Orc)
- 4 classes (Warrior, Rogue, Mage, Cleric)
- 4 quest types (Extermination, Rescue, Retrieval, Escort)
- 3 rival guilds
- 2 main story paths
- Simple grid combat (no complex environment)
- 1 faction system (Crown only)

**CUT/DELAY:**
- Complex world events (add post-launch)
- 7+ factions (start with 3)
- Multiple backgrounds (add in updates)
- Advanced AI behaviors (start with basic decision trees)
- Extensive balancing (iterate post-MVP)

---

## Development Roadmap

### Phase 1 (Months 1-3): Core Systems
- Character creation & stat system
- Basic turn-based combat
- Simple AI behavior (3 INT tiers)
- Quest generation framework

### Phase 2 (Months 4-6): Guild Management
- Recruitment system
- Satisfaction mechanics
- Guild facility upgrades
- Basic UI implementation

### Phase 3 (Months 7-9): Content & Polish
- Full quest type implementation
- Rival guild AI
- Story branch implementation
- Combat balancing

### Phase 4 (Months 10-12): Testing & Release Prep
- Closed beta testing
- Bug fixing
- iOS optimization
- App Store submission

### Post-Launch (Months 13-18)
- Content updates (new races, classes)
- Additional factions
- World event system expansion
- QoL improvements based on feedback

---

## Success Metrics

### Player Engagement Goals
- Average session: 20-30 minutes
- Retention: 40%+ Day 7, 20%+ Day 30
- Completion rate: 30%+ finish one story path

### Monetization (If Applicable)
- **Premium Model ($9.99)** - No ads, single purchase
- **Freemium Option** - Limited guild slots, cosmetic purchases
- **Expansion DLCs** - New campaigns, races, classes

---

## Risk Assessment

### High-Risk Areas
1. **AI Complexity** - INT-driven behavior may be too ambitious
2. **Scope Creep** - Feature list is already massive
3. **Balance** - Turn-based with AI party is hard to tune
4. **Solo Development** - This is realistically a team project

### Mitigation Strategies
- Prototype AI system first (validate feasibility)
- Strict feature freeze after Phase 2
- Early playtesting with limited content
- Consider finding a co-developer or contractor for art/audio

---

**NEXT STEPS:** Review this document, identify what to cut for timeline, then we'll create detailed technical specs and implementation guides.