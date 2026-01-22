# Guild Master - Development Milestones

*Reorganized from all spec documents into clear development phases.*

---

## Milestone Overview

| Milestone | Codename | Description | Est. Timeline |
|-----------|----------|-------------|---------------|
| Alpha | "First Blood" | Playable core loop, minimal content | Months 1-6 |
| Beta | "Battle Ready" | Feature complete, content complete | Months 7-9 |
| Gold Master | "Release" | Polished, optimized, App Store ready | Months 10-12 |
| Expansion 1 | "Rising Ranks" | New classes, factions, content | Months 13-16 |
| Expansion 2 | "Rival Wars" | Rival guilds, PvP-style features | Months 17-20 |
| Expansion 3 | "Endless Dungeon" | Roguelike mode, procedural content | Months 21-24 |
| Sequel | "Guild Master II: Kingdoms" | New setting, kingdom management | Year 3+ |

---

## ALPHA (MVP) - "First Blood"
*Goal: Prove the core hook works - AI party members that feel alive.*

### Core Systems (Must Have)

#### Character System
- [ ] 4 Races: Human, Elf, Dwarf, Orc (no variants)
- [ ] 4 Classes: Warrior, Rogue, Mage, Cleric
- [ ] 6 Stats: STR, DEX, CON, INT, WIS, CHA
- [ ] Basic stat generation (3d6 drop lowest)
- [ ] Racial stat modifiers
- [ ] Level 1-10 progression
- [ ] XP system with level-up benefits
- [ ] Hit dice by class

#### INT-Driven AI (The Core Hook)
- [ ] 3 AI tiers: Low (1-8), Medium (9-14), High (15-20)
- [ ] Low INT behavior: Obvious mistakes, random ability use, poor targeting
- [ ] Medium INT behavior: Basic tactics, threat recognition
- [ ] High INT behavior: Optimized decisions, ally coordination
- [ ] Utility scoring system for decisions
- [ ] Behavior trees per tier

#### Captain Mechanics
- [ ] Captain assignment (highest INT+CHA)
- [ ] Basic commands: Focus Fire, Defensive Formation
- [ ] Command compliance check (CHA-based)
- [ ] Visual feedback for captain orders

#### Combat System
- [ ] Hex grid (10x12)
- [ ] Turn-based initiative (DEX + d20)
- [ ] Move + Action per turn
- [ ] Basic attack resolution (d20 + mods vs AC)
- [ ] Critical hits (nat 20) and misses (nat 1)
- [ ] 5 abilities per class (see below)
- [ ] Basic positioning: flanking (+2 attack)
- [ ] Line of sight for ranged
- [ ] HP, death at 0

#### Combat Abilities (Alpha Set - 20 total)
**Warrior:**
- [ ] Power Attack (Lv1)
- [ ] Cleave (Lv3)
- [ ] Shield Bash (Lv3)
- [ ] Second Wind (Lv5)
- [ ] Whirlwind (Lv7)

**Rogue:**
- [ ] Sneak Attack (Lv1 - passive)
- [ ] Hide (Lv1)
- [ ] Backstab (Lv3)
- [ ] Evasion (Lv5 - passive)
- [ ] Poison Blade (Lv5)

**Mage:**
- [ ] Magic Missile (Lv1)
- [ ] Shield (Lv1)
- [ ] Fireball (Lv3)
- [ ] Haste (Lv5)
- [ ] Counterspell (Lv5)

**Cleric:**
- [ ] Cure Wounds (Lv1)
- [ ] Bless (Lv1)
- [ ] Turn Undead (Lv3)
- [ ] Divine Smite (Lv3)
- [ ] Mass Healing (Lv5)

#### Quest System
- [ ] 3 Quest types: Extermination, Rescue, Escort
- [ ] Linear structure: Travel → 3 encounters → Boss → Return
- [ ] Quest board UI (3-5 available quests)
- [ ] Quest acceptance flow
- [ ] Party selection (4 members max)
- [ ] Difficulty tiers: Basic, Advanced

#### Guild Management (Bare Bones)
- [ ] Recruit adventurers from pool of 10
- [ ] 1 Facility: Barracks (capacity upgrades)
- [ ] Simple economy: Gold income/expense
- [ ] Weekly upkeep costs
- [ ] Adventurer salaries

#### Satisfaction System (Simplified)
- [ ] Satisfaction score (0-100)
- [ ] Basic factors: Quest success/failure, rest, injuries
- [ ] Desertion threshold (<30)
- [ ] Basic desertion check

#### Content (Alpha)
- [ ] 10 Quests (hand-crafted)
- [ ] 15 Enemy types (5 common, 7 advanced, 3 boss)
- [ ] 30 Items (10 weapons, 10 armor, 10 consumables)
- [ ] Name generator (4 races)

#### UI/UX (Functional)
- [ ] Guild Hall hub screen
- [ ] Contract Board
- [ ] Barracks/roster screen
- [ ] Combat screen with hex grid
- [ ] Basic character detail view
- [ ] Victory/Defeat screens (basic)

#### Technical Foundation
- [ ] Unity project setup
- [ ] Hex grid system with A* pathfinding
- [ ] Turn order management
- [ ] Save/Load system (single slot)
- [ ] Basic auto-save

### Alpha Deliverables
- Playable prototype: Recruit → Quest → Combat → Manage → Repeat
- 10+ hours of gameplay
- Core AI behavior demonstrably different by INT tier

---

## BETA - "Battle Ready"
*Goal: Feature complete, content complete, ready for testing.*

### New Systems

#### Combat Commentary System
- [ ] Real-time text log during combat
- [ ] Templates by event type (attack, damage, ability, heal)
- [ ] Style variations (normal, critical, miss, low-INT)
- [ ] Captain command commentary
- [ ] Scrollable combat log

#### Kill & Streak Announcer
- [ ] Kill tracking per character
- [ ] First Blood announcement
- [ ] Kill streak milestones (Double → Legendary)
- [ ] Multi-kill announcements (same turn)
- [ ] Boss kill special announcements
- [ ] Kill announcer UI overlay

#### Victory Screen (Full)
- [ ] Combat summary (turns, damage, healing)
- [ ] MVP selection algorithm
- [ ] MVP titles (Slayer, Destroyer, Lifebringer, etc.)
- [ ] Party performance breakdown
- [ ] Reward reveal animation
- [ ] Victory quotes by class/personality
- [ ] Special victory types: Flawless, Pyrrhic, Swift

#### Defeat Screen (Full)
- [ ] Fallen heroes display with epitaphs
- [ ] Survivor status (injuries, stress)
- [ ] Consequence breakdown
- [ ] Death epitaph generation
- [ ] Defeat quotes
- [ ] TPK vs Partial Wipe handling

#### Personality Traits (4 Dimensions)
- [ ] Greedy (0-10): Loot behavior, hiring cost
- [ ] Loyal (0-10): Desertion resistance, protection behavior
- [ ] Brave (0-10): Aggression, flee threshold
- [ ] Cautious (0-10): Trap detection, ambush awareness
- [ ] Combat AI modified by personality

#### Innate & Acquired Traits
- [ ] Racial traits (Human: Adaptable, Elf: Keen Senses, etc.)
- [ ] Class traits (Warrior: Combat Stance, Rogue: Opportunist, etc.)
- [ ] Acquired traits from gameplay (Confident, Traumatized, Scarred Veteran, etc.)

#### Relationship System
- [ ] Relationship matrix (-100 to +100)
- [ ] Relationship events (positive/negative)
- [ ] Relationship thresholds (Hostile → Bonded)
- [ ] Synergy abilities for Bonded pairs (+80)
- [ ] Party compatibility effects

#### Skill System
- [ ] 8 Utility skills (Perception, Athletics, Stealth, etc.)
- [ ] Skill check resolution (d20 + stat + class bonus)
- [ ] Skill challenges in quests
- [ ] Class skill bonuses

#### Story System
- [ ] Single linear story with 5 beats
- [ ] 2 Endings (based on final choice)
- [ ] 5 Story quests integrated into campaign
- [ ] Dialogue system with portraits
- [ ] Dialogue options (some with skill checks)

#### Training System (Basic)
- [ ] Solo Practice (low XP, safe)
- [ ] Sparring between adventurers
- [ ] Rest & Recovery (heal + stress reduction)
- [ ] Training scheduling UI

### Content Additions (Beta)

#### Additional Content
- [ ] 5 More enemy types (20 total)
- [ ] 20 More items (50 total)
- [ ] Investigation quest type (4th type)
- [ ] Defense quest type (5th type)
- [ ] Random encounter tables (overworld travel)

#### Audio
- [ ] 5-8 Music tracks (Title, Guild Hall, Combat, Boss, Victory, Defeat)
- [ ] UI sound effects (buttons, transitions, notifications)
- [ ] Combat sound effects (hits, misses, abilities, deaths)

### UI/UX Improvements

#### Visual Polish
- [ ] Parchment aesthetic implemented
- [ ] Color palette applied
- [ ] Typography (Cinzel headers, Crimson body)
- [ ] Component styling (buttons, cards, progress bars)
- [ ] Character portraits

#### Additional Screens
- [ ] Adventurer detail (full stats, personality, traits)
- [ ] Equipment management
- [ ] Ledger (finances, quest log)
- [ ] Training screen

#### Tutorial
- [ ] 5-segment tutorial (~15 min)
- [ ] Contextual tooltips (first-time triggers)
- [ ] Skip tutorial option

### Beta Deliverables
- Feature complete game
- Full story campaign (beginning to end)
- All UI screens implemented
- Audio integrated
- Ready for closed playtesting

---

## GOLD MASTER - "Release"
*Goal: Polished, optimized, bug-free, App Store submission.*

### Polish & Optimization

#### Performance
- [ ] iOS optimization (battery, memory, load times)
- [ ] 30 FPS in menus, 60 FPS in combat
- [ ] Sprite pooling (max 20 loaded)
- [ ] Lazy-load animations
- [ ] Compressed save files (JSON + gzip)

#### Touch Controls
- [ ] All tap targets 44x44pt minimum
- [ ] Swipe gestures for navigation
- [ ] Long-press for details
- [ ] Pinch-to-zoom on combat grid

#### Quality of Life
- [ ] Auto-save at quest completion, recruitment, story choice
- [ ] Multiple save slots (3)
- [ ] Cloud save (iCloud)
- [ ] Quick resume from app background

#### Balance Pass
- [ ] Combat win rate tuned to 60-70%
- [ ] Economy balanced (100-200g profit per quest)
- [ ] Satisfaction system: No mass desertions in normal play
- [ ] Enemy HP/damage tuning
- [ ] Ability balance

### Accessibility
- [ ] Text size options (Normal, Large, Extra Large)
- [ ] Color blind modes (3 types)
- [ ] High contrast toggle
- [ ] VoiceOver support
- [ ] One-handed mode
- [ ] Auto-battle option
- [ ] Slow mode (50% animation speed)
- [ ] Visual cues for audio events

### Localization (5 Languages)
- [ ] English (base)
- [ ] Spanish
- [ ] French
- [ ] German
- [ ] Portuguese (BR)

### Analytics & Legal
- [ ] Analytics implementation (Firebase or similar)
- [ ] GDPR/CCPA compliance
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Age rating preparation

### App Store Preparation
- [ ] App icon (multiple sizes)
- [ ] Screenshots (all device sizes)
- [ ] App preview video/trailer
- [ ] App Store description
- [ ] Keywords optimization
- [ ] TestFlight beta

### Gold Master Deliverables
- Bug-free, polished game
- Optimized for all supported iOS devices
- Localized in 5 languages
- Accessible
- App Store approved and live

---

## EXPANSION 1 - "Rising Ranks"
*Goal: Extend content, add depth without overwhelming.*

### New Races (+3)
- [ ] Halfling (High DEX, CHA; Low STR, CON; "Lucky" trait)
- [ ] Tiefling (Varied stats, +CHA; "Infernal Legacy" trait)
- [ ] Dragonborn (High STR, CHA; Low DEX; "Draconic Breath" trait)

### New Classes (+2)
- [ ] Ranger (Ranged DPS, tracking, survival)
  - Hunter's Mark, Volley, Animal Companion, Camouflage, Multiattack
- [ ] Paladin (Tank/support, divine magic)
  - Lay on Hands, Divine Sense, Smite Evil, Aura of Protection, Holy Shield

### Faction System (3 Factions)
- [ ] The Crown (lawful authority)
  - Quest types: Extermination, Defense, Escort, Investigation
  - Reputation rewards: Armory discount → Elite knight recruits → Land grant
- [ ] Mages' Conclave (arcane knowledge)
  - Quest types: Retrieval, Investigation, Extermination
  - Reputation rewards: Spell library → Battlemage recruits → Teleportation
- [ ] Church of Light (divine order)
  - Quest types: Undead extermination, Rescue, Defense
  - Reputation rewards: Free healing → Paladin/Cleric recruits → Resurrection discount

### Background System
- [ ] 8 Backgrounds: Soldier, Scholar, Criminal, Noble, Farmer, Merchant, Acolyte, Outlander
- [ ] Background skill bonuses
- [ ] Background compatibility (Nobles clash with Criminals, etc.)

### Guild Facilities (+3)
- [ ] Training Grounds (sparring, hired trainers)
- [ ] Library (study sessions, spell learning)
- [ ] Chapel (meditation, stress recovery)

### Training System (Full)
- [ ] Mentorship program (high-level trains low-level)
- [ ] Group study sessions
- [ ] Hired trainers (Weapons Master, Arcane Tutor, etc.)
- [ ] Training quests (low-risk field training)
- [ ] Exploration expeditions
- [ ] Faction apprenticeships

### Content
- [ ] +10 Quests (20 total story + side)
- [ ] +10 Enemy types (30 total)
- [ ] +20 Items (70 total)
- [ ] Infiltration quest type
- [ ] Diplomacy quest type

### Expansion 1 Deliverables
- 7 playable races
- 6 playable classes
- 3 faction reputation systems
- Full training system
- 30+ hours of content

---

## EXPANSION 2 - "Rival Wars"
*Goal: Dynamic replayability through competition.*

### Rival Guild System
- [ ] 3 AI-controlled rival guilds
- [ ] Rival personalities (aggressive, greedy, honorable)
- [ ] Weekly rival decisions

### Rival Actions
- [ ] Contract stealing (outbid on quests)
- [ ] Sabotage (reputation damage)
- [ ] Ambush (attack returning parties)
- [ ] Poaching (recruit your adventurers)
- [ ] Temporary alliance (major threats)

### Ambush System
- [ ] Detection chance (WIS-based)
- [ ] Surprise round mechanics
- [ ] Loot stealing
- [ ] Post-ambush consequences

### Counter-Strategies
- [ ] Spy network (intel on rival plans)
- [ ] Reputation locking (early contract claims)
- [ ] Direct confrontation (high-risk guild battles)
- [ ] Faction alliances

### Additional Factions (+4 = 7 total)
- [ ] Thieves' Guild (shadow network)
- [ ] Merchant Consortium (economic power)
- [ ] Druidic Circle (nature guardians)
- [ ] Tribal Confederacy (warrior culture)

### World Events System
- [ ] Political upheaval (leadership changes)
- [ ] Natural disasters (affect regions)
- [ ] Monster invasions (quest surges)
- [ ] Economic shifts (price fluctuations)
- [ ] Plagues (healing quest spikes)

### Content
- [ ] +10 Quests
- [ ] Rival guild quest types
- [ ] PvP-style guild combat encounters
- [ ] Espionage quests

### Expansion 2 Deliverables
- Dynamic rival guild competition
- 7 faction systems
- World event system
- 40+ hours of content

---

## EXPANSION 3 - "Endless Dungeon"
*Goal: Infinite replayability, community engagement.*

### Roguelike Mode
- [ ] Procedural dungeon generation
- [ ] Permadeath (Hardcore mode)
- [ ] Run-based progression
- [ ] Randomized loot tables
- [ ] Escalating difficulty

### Meta-Progression
- [ ] Legacy system (retired guilds leave bonuses)
- [ ] Codex unlocks (persist across runs)
- [ ] Achievement system
- [ ] Starting bonus unlocks

### Procedural Content
- [ ] Procedural quest generation
- [ ] Procedural enemy encounters
- [ ] Procedural dungeon layouts
- [ ] Random event encounters

### Leaderboards
- [ ] Deepest dungeon floor reached
- [ ] Fastest boss kills
- [ ] Most gold accumulated
- [ ] Longest streak

### Additional Content
- [ ] +2 Classes: Bard, Druid (full ability trees)
- [ ] Racial variants (3 per race = 21 total)
- [ ] Elite/Legendary difficulty tiers
- [ ] Secret bosses

### Expansion 3 Deliverables
- Infinite roguelike mode
- Full meta-progression
- Leaderboards
- Complete 8-class roster

---

## SEQUEL - "Guild Master II: Kingdoms"
*A fundamentally different game warranting a new title.*

### Core Concept Shift
- From: Single guild management
- To: Multi-guild empire / kingdom management

### New Features (Sequel-Worthy)
- [ ] Multiple guilds under your banner
- [ ] Kingdom building (cities, territories)
- [ ] Grand strategy layer (war, diplomacy)
- [ ] Generational play (adventurer descendants)
- [ ] Multiplayer guild alliances
- [ ] Real-time with pause combat option
- [ ] 3D graphics upgrade

### Setting Change
- New continent/world
- New races (beast-folk, constructs, etc.)
- New magic systems
- Different technology era

### Scope
- 2-3 year development cycle
- Team of 5-10
- Full AA production values

---

## Feature Priority Matrix

### Must Have (Alpha)
| Feature | Uniqueness | Complexity | Priority |
|---------|------------|------------|----------|
| INT-driven AI | Core hook | High | P0 |
| Captain mechanics | Core hook | Medium | P0 |
| Turn-based combat | Foundation | High | P0 |
| 4 classes/races | MVP content | Medium | P0 |
| Quest system | Core loop | Medium | P0 |
| Basic satisfaction | Management | Low | P0 |

### Should Have (Beta)
| Feature | Uniqueness | Complexity | Priority |
|---------|------------|------------|----------|
| Combat commentary | Polish | Medium | P1 |
| Kill announcer | Engagement | Medium | P1 |
| Personality traits | Depth | Medium | P1 |
| Relationship system | Depth | Medium | P1 |
| Full victory/defeat | Polish | Low | P1 |
| Story | Content | Medium | P1 |
| Tutorial | Onboarding | Medium | P1 |

### Nice to Have (Gold/Expansion)
| Feature | Uniqueness | Complexity | Priority |
|---------|------------|------------|----------|
| Training system | Depth | Medium | P2 |
| Faction system | Depth | High | P2 |
| Rival guilds | Replayability | High | P2 |
| World events | Dynamic | High | P2 |
| Roguelike mode | Replayability | High | P2 |
| 8 classes | Content | Medium | P2 |

---

## Risk Assessment by Milestone

### Alpha Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| AI doesn't feel different | High | Critical | Prototype first, exaggerate differences |
| Combat too slow | Medium | High | Fast animations, 5-7 min target |
| Scope creep | High | High | Strict feature freeze at Month 2 |

### Beta Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Story expands scope | Medium | Medium | Stay disciplined, minimal branching |
| Balance issues | High | Medium | Extensive playtesting |
| Audio integration delays | Medium | Low | Use placeholder royalty-free first |

### Gold Master Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| iOS optimization issues | Medium | High | Start optimization early (Month 10) |
| App Store rejection | Low | High | Study guidelines early, no lootboxes |
| Localization bugs | Medium | Medium | Hire native speakers for QA |

### Expansion Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Player base moved on | Medium | High | Launch updates within 3-4 months |
| Feature bloat | High | Medium | Each update focused on one system |
| Rival AI too complex | High | High | Simplify, iterate |

---

## Success Criteria by Milestone

### Alpha Success
- [ ] Playtesters can identify INT differences without being told
- [ ] Captain feels impactful in at least 50% of combats
- [ ] "I want to play again" feedback from 3+ testers

### Beta Success
- [ ] Full campaign playthrough in <8 hours
- [ ] Combat pacing: 5-7 minutes average
- [ ] No mass desertions in normal play
- [ ] Tutorial completion >80% in testing

### Gold Master Success
- [ ] App Store approval on first submission
- [ ] 4.0+ star rating in first week
- [ ] 1,000+ downloads in first month
- [ ] Day 7 retention >30%

### Expansion Success
- [ ] Re-engage 30%+ of lapsed players
- [ ] Maintain 4.0+ rating
- [ ] Revenue increase 25%+ per expansion

---

## Version Numbering

| Version | Milestone | Content |
|---------|-----------|---------|
| 0.1 | Alpha prototype | Core combat only |
| 0.5 | Alpha feature complete | Full alpha scope |
| 0.9 | Beta feature complete | All features |
| 1.0 | Gold Master | Release version |
| 1.1 | Expansion 1 | Rising Ranks |
| 1.2 | Expansion 2 | Rival Wars |
| 1.3-1.5 | QoL updates | Balance, fixes |
| 2.0 | Expansion 3 | Endless Dungeon |
| 3.0 | Sequel | Guild Master II |

---

*Document generated from: Core GDD, Technical Spec, Content Spec, MVP Roadmap, Battle System Spec, Supplemental Spec*
