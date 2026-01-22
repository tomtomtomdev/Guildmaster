# Guild Master - Phase 1 Development Plan
## Alpha: "First Blood" (Months 1-6)

*Goal: Prove the core hook works - AI party members that feel alive.*

---

## Executive Summary

Phase 1 delivers a **playable vertical slice** with the core innovation: **INT-driven AI party members**. By the end of Phase 1, players should be able to:
1. Recruit adventurers with varying intelligence
2. Send parties on quests with turn-based tactical combat
3. Clearly notice the difference between smart and dumb party members
4. Experience the basic guild management loop

**Platform:** iOS (Unity)
**Scope:** 4 races, 4 classes, 10 quests, ~10 hours of gameplay

---

## Phase 1 Breakdown

### Sprint 1-2: Foundation (Weeks 1-4)
**Deliverable:** Playable hex grid with 2 characters fighting 2 enemies

#### 1.1 Project Setup
- [ ] Unity project initialization
- [ ] Git repository setup
- [ ] Folder structure (Assets/Scripts/Models, Views, Controllers, Data, Utils)
- [ ] Basic scene setup (Main Menu, Combat, Guild Hall stubs)

#### 1.2 Hex Grid System
- [ ] Hex grid generation (10x12 default)
- [ ] Hex coordinate system (cube coordinates recommended)
- [ ] Hex rendering (simple colored hexes initially)
- [ ] A* pathfinding implementation (or integrate A* Pathfinding Project)
- [ ] Movement range highlighting
- [ ] Hex selection/tap handling

#### 1.3 Character Data Model
```csharp
// Core character structure
public class Character {
    public string Id;
    public string Name;
    public Race Race;          // Human, Elf, Dwarf, Orc
    public CharacterClass Class; // Warrior, Rogue, Mage, Cleric

    // Primary Stats (1-20)
    public int STR, DEX, CON, INT, WIS, CHA;

    // Secondary Stats (derived)
    public int HP, MaxHP;
    public int Stamina, MaxStamina;
    public int Mana, MaxMana;
    public int Initiative;

    // Level & XP
    public int Level;
    public int XP;
}
```

#### 1.4 Basic Turn System
- [ ] Initiative calculation (DEX + d20 roll)
- [ ] Turn order queue
- [ ] Turn state machine (WaitingForInput → Executing → NextTurn)
- [ ] End turn functionality

---

### Sprint 3-4: Combat Core (Weeks 5-8)
**Deliverable:** Full 4v4 combat with basic attacks and abilities

#### 2.1 Combat Resolution
- [ ] Attack roll system (d20 + modifiers vs AC)
- [ ] Damage calculation (weapon damage + stat modifier)
- [ ] Critical hits (natural 20 = double damage)
- [ ] Critical misses (natural 1 = miss)
- [ ] Line of sight checking for ranged
- [ ] Flanking bonus (+2 attack when ally on opposite side)

#### 2.2 Action Economy
- [ ] Movement phase (speed in hexes)
- [ ] Action phase (attack, ability, item, defend)
- [ ] Action selection UI
- [ ] Target selection system
- [ ] Action animation framework (simple for now)

#### 2.3 Class Abilities (5 per class = 20 total)

**Warrior:**
| Ability | Level | Cost | Effect |
|---------|-------|------|--------|
| Power Attack | 1 | 5 Stamina | +5 damage, -2 to hit |
| Cleave | 3 | 10 Stamina | If kill, free attack on adjacent |
| Shield Bash | 3 | 5 Stamina | Stun 1 turn, 1d6 damage |
| Second Wind | 5 | - | Heal 25% HP, 1/quest |
| Whirlwind | 7 | 15 Stamina | Attack all adjacent enemies |

**Rogue:**
| Ability | Level | Cost | Effect |
|---------|-------|------|--------|
| Sneak Attack | 1 | - | +2d6 from stealth/flanking (passive) |
| Hide | 1 | 5 Stamina | Enter stealth if not in melee |
| Backstab | 3 | 10 Stamina | 3x damage from stealth |
| Evasion | 5 | - | Half damage from AOE (passive) |
| Poison Blade | 5 | 15 Stamina | Poison: 1d4/turn for 3 turns |

**Mage:**
| Ability | Level | Cost | Effect |
|---------|-------|------|--------|
| Magic Missile | 1 | 5 Mana | Auto-hit, 3x(1d4+1) |
| Shield | 1 | 5 Mana | +5 AC until next turn |
| Fireball | 3 | 15 Mana | 6d6 fire, AOE 4 hexes, DEX save half |
| Haste | 5 | 20 Mana | Target gets 2 actions for 3 turns |
| Counterspell | 5 | 10 Mana | Cancel enemy spell, INT check |

**Cleric:**
| Ability | Level | Cost | Effect |
|---------|-------|------|--------|
| Cure Wounds | 1 | 5 Mana | Heal 1d8+WIS |
| Bless | 1 | 10 Mana | Allies +1d4 attacks/saves, 5 turns |
| Turn Undead | 3 | 15 Mana | Undead flee, WIS check |
| Divine Smite | 3 | 10 Mana | +2d8 radiant to attack |
| Mass Healing | 5 | 25 Mana | Heal all allies 2d8+WIS |

---

### Sprint 5-6: INT-Driven AI (Weeks 9-12)
**Deliverable:** Visibly different AI behavior based on INT stat

#### 3.1 AI Architecture
```csharp
public interface ICombatAI {
    CombatAction DecideAction(Character self, BattleState state);
}

public class UtilityAI : ICombatAI {
    public CombatAction DecideAction(Character self, BattleState state) {
        var options = GenerateAllOptions(self, state);
        var scored = options.Select(o => new {
            Option = o,
            Score = ScoreOption(o, self, state)
        });

        // Apply INT-based noise
        scored = ApplyINTNoise(scored, self.INT);

        return scored.OrderByDescending(s => s.Score).First().Option;
    }
}
```

#### 3.2 Three AI Tiers

**LOW INT (1-8):**
```
Behavior:
- 30% random noise added to all decisions
- Ignores flanking opportunities
- Attacks nearest enemy regardless of threat
- Uses abilities randomly (not situationally)
- Walks into hazards
- Doesn't prioritize low-HP enemies
- May use healing when not needed

Example Turn: "Charge nearest goblin ignoring the elite"
```

**MEDIUM INT (9-14):**
```
Behavior:
- 15% random noise
- Recognizes basic threats
- Heals allies below 30% HP
- Uses AOE when 3+ enemies clustered
- Takes cover when available
- Prioritizes elites over minions

Example Turn: "Move to cover, attack the orc shaman"
```

**HIGH INT (15-20):**
```
Behavior:
- Optimal decision making
- Exploits enemy weaknesses
- Coordinates with allies (focus fire)
- Predicts enemy actions (simple)
- Conserves resources when appropriate
- Positions for flanking

Example Turn: "Flank the ogre with Warrior, cast Fireball when grouped"
```

#### 3.3 Utility Scoring Functions
```python
# Attack Target Selection
score = (
    targetThreatLevel × 0.3 +
    targetLowHPBonus × 0.2 +
    targetInRangeBonus × 0.2 +
    targetWeaknessMatch × 0.2 +
    captainPriority × 0.1
)

# Ability Usage
score = (
    abilitySituationalValue × 0.3 +
    resourceEfficiency × 0.2 +
    partyNeed × 0.2 +
    selfPreservation × 0.2 +
    captainDirective × 0.1
)

# Positioning
score = (
    coverAvailable × 0.25 +
    flankingOpportunity × 0.25 +
    supportAllyProximity × 0.2 +
    retreatSafety × 0.2 +
    objectiveDistance × 0.1
)
```

#### 3.4 Captain System
- [ ] Captain designation (highest INT+CHA / 2)
- [ ] Basic commands: "Focus Fire [Target]", "Defensive Formation"
- [ ] Command compliance check: `(CHA × 5) + morale + relationship - stress`
- [ ] Visual indicator when captain issues command
- [ ] Command effect on ally decisions

---

### Sprint 7-8: Quest System (Weeks 13-16)
**Deliverable:** Playable quests from selection to completion

#### 4.1 Quest Data Model
```csharp
public class Quest {
    public string Id;
    public string Title;
    public QuestType Type;      // Extermination, Rescue, Escort
    public DifficultyTier Tier; // Basic, Advanced
    public string Description;
    public int RecommendedLevel;

    public QuestRewards Rewards;
    public List<Encounter> Encounters;
}

public class QuestRewards {
    public int Gold;
    public int XP;
    public List<string> ItemIds;
    public Dictionary<string, int> ReputationChanges;
}
```

#### 4.2 Quest Types (3 for Alpha)

**Extermination:**
- Clear location of enemies
- Structure: 3 combat encounters → Boss
- Success: All enemies defeated
- Failure: Party wiped

**Rescue:**
- Save captive from enemies
- Structure: 2 combat → Skill challenge → Boss with captive
- Success: Captive extracted alive
- Failure: Captive dies or party wiped

**Escort:**
- Protect NPC through danger
- Structure: Combat → Travel (random encounters) → Combat
- Success: NPC reaches destination
- Failure: NPC dies or party wiped

#### 4.3 Quest Flow
```
[Quest Board] → [Quest Detail] → [Party Selection] →
[Quest Start Dialogue] → [Encounters 1-N] →
[Victory/Defeat Screen] → [Debrief] → [Guild Hall]
```

#### 4.4 Encounter System
- [ ] Combat encounter loading
- [ ] Enemy party generation based on difficulty budget
- [ ] Terrain template selection
- [ ] Encounter transition (fade, load, position)
- [ ] Multi-encounter quest state persistence

---

### Sprint 9-10: Guild Management (Weeks 17-20)
**Deliverable:** Recruitment and basic management loop

#### 5.1 Adventurer Pool Generation
```csharp
public Character GenerateAdventurer(CharacterClass preferredClass) {
    // Race weighted by class synergy
    Race race = WeightedRandomRace(preferredClass);

    // Stats: 4d6 drop lowest per stat
    var stats = Generate4d6DropLowest();
    stats = ApplyRacialModifiers(stats, race);
    stats = ApplyClassBoost(stats, preferredClass);

    // Personality (0-10 each)
    var personality = new Personality {
        Greedy = Random(0, 10),
        Loyal = Random(0, 10),
        Brave = Random(0, 10),
        Cautious = Random(0, 10)
    };

    // Hiring cost based on quality
    int hireCost = CalculateHireCost(stats, personality);

    return new Character { ... };
}
```

#### 5.2 Recruitment UI
- [ ] Recruit pool display (5-10 available)
- [ ] Character preview (stats, personality)
- [ ] Hiring confirmation with cost
- [ ] Roster management (view, dismiss)

#### 5.3 Economy (Simple)
```
Weekly Cycle:
- Adventurer salaries: 50g per character
- Guild upkeep: 100g
- Equipment repairs: 50g
- Total: ~400g/week for 4-person roster

Quest Rewards (average):
- Basic tier: 200-300g
- Advanced tier: 400-500g
- Profit margin: 100-200g per quest
```

#### 5.4 Satisfaction System (Simplified)
```csharp
public void UpdateSatisfaction(Character c, QuestResult result) {
    int change = 0;

    // Quest outcome
    if (result.Success) change += 10;
    else change -= 15;

    // Injuries
    if (c.HP < c.MaxHP * 0.3f) change -= 5;

    // Rest (days since last rest)
    if (c.DaysSinceRest > 7) change -= 3 * (c.DaysSinceRest - 7);

    c.Satisfaction = Clamp(c.Satisfaction + change, 0, 100);
}

// Desertion check (satisfaction < 30)
public bool CheckDesertion(Character c) {
    if (c.Satisfaction >= 30) return false;

    int threshold = c.Satisfaction + (c.Personality.Loyal * 5);
    return Random(1, 100) > threshold;
}
```

---

### Sprint 11-12: Content & Polish (Weeks 21-24)
**Deliverable:** 10 playable quests, 15 enemies, 30 items

#### 6.1 Enemy Database (15 types)

**Common (Threat 20-50):**
| Enemy | HP | AC | Damage | Special |
|-------|----|----|--------|---------|
| Goblin Scout | 15 | 13 | 1d6+2 | Nimble Escape |
| Bandit | 22 | 12 | 1d6+1 | - |
| Giant Rat | 7 | 12 | 1d4+2 | Disease on bite |
| Skeleton | 13 | 13 | 1d6+2 | Vulnerable to bludgeon |
| Wolf | 11 | 13 | 2d4+2 | Pack Tactics |

**Advanced (Threat 60-100):**
| Enemy | HP | AC | Damage | Special |
|-------|----|----|--------|---------|
| Orc Warrior | 45 | 13 | 1d12+3 | Aggressive |
| Ogre | 85 | 11 | 2d8+4 | Brutal |
| Dark Cultist | 33 | 12 | Spells | Dark Blessing |
| Troll | 84 | 15 | 1d6+4 x3 | Regeneration |
| Goblin Shaman | 27 | 12 | Spells | Healing |

**Boss (Threat 150+):**
| Enemy | HP | AC | Damage | Special |
|-------|----|----|--------|---------|
| Orc Warlord | 90 | 16 | 2d8+5 | Rally, Multi-attack |
| Troll King | 120 | 16 | 2d6+5 x3 | Enhanced Regen |
| Dark Priest | 75 | 14 | Spells | Summon Undead |
| Giant Spider Queen | 100 | 14 | 2d8+4 | Web, Poison |
| Bandit Lord | 80 | 15 | 1d10+4 | Leadership, Parry |

#### 6.2 Item Database (30 items)

**Weapons (10):**
- Rusty Sword (1d6), Iron Sword (1d8), Steel Sword (1d8+1)
- Hand Axe (1d6, throwable), Battle Axe (1d10)
- Short Bow (1d6), Longbow (1d8)
- Wooden Staff (+1 spell), Oak Staff (+2 spell, +5 mana)
- Dagger (1d4, finesse)

**Armor (10):**
- Leather (+2 AC), Studded Leather (+3 AC)
- Hide (+3 AC, -1 DEX), Chain Shirt (+4 AC, -1 DEX)
- Chain Mail (+5 AC, -3 DEX), Scale Mail (+5 AC, -2 DEX)
- Robes (+1 AC, +5 mana), Acolyte Vestments (+1 AC, +1 spell)
- Shield (+2 AC), Tower Shield (+3 AC, -1 attack)

**Consumables (10):**
- Minor Healing Potion (2d4+2 HP)
- Healing Potion (4d4+4 HP)
- Stamina Potion (20 stamina)
- Mana Potion (15 mana)
- Antidote (cure poison)
- Throwing Knife (1d4, range 30)
- Alchemist Fire (1d6, AOE 2)
- Bandage (stabilize dying ally)
- Torch (light, 1d4 fire)
- Rations (prevent starvation debuff)

#### 6.3 Quest Content (10 quests)

**Tutorial Quest (1):**
1. "Clear the Basement" - Intro quest, 2 rat encounters

**Basic Tier (5):**
2. "Goblin Camp" - Extermination, goblin enemies
3. "Bandit Hideout" - Extermination, bandit enemies
4. "Missing Merchant" - Rescue, mixed enemies
5. "Caravan Guard" - Escort, wolf/bandit ambushes
6. "Crypt Cleanup" - Extermination, undead enemies

**Advanced Tier (4):**
7. "Orc Warband" - Extermination, orc enemies, Warlord boss
8. "Cultist Ritual" - Rescue + boss, cultist enemies
9. "Troll Cave" - Extermination, troll boss
10. "Merchant Prince" - Escort, advanced threats

---

## Technical Architecture

### Project Structure
```
Assets/
├── Scripts/
│   ├── Core/
│   │   ├── GameManager.cs
│   │   ├── SaveManager.cs
│   │   └── AudioManager.cs
│   ├── Models/
│   │   ├── Character.cs
│   │   ├── Quest.cs
│   │   ├── Item.cs
│   │   └── Enemy.cs
│   ├── Combat/
│   │   ├── CombatManager.cs
│   │   ├── HexGrid.cs
│   │   ├── TurnManager.cs
│   │   ├── AI/
│   │   │   ├── ICombatAI.cs
│   │   │   ├── UtilityAI.cs
│   │   │   ├── LowINTBehavior.cs
│   │   │   ├── MedINTBehavior.cs
│   │   │   └── HighINTBehavior.cs
│   │   └── Actions/
│   │       ├── AttackAction.cs
│   │       ├── MoveAction.cs
│   │       └── AbilityAction.cs
│   ├── Guild/
│   │   ├── GuildManager.cs
│   │   ├── RecruitmentManager.cs
│   │   └── EconomyManager.cs
│   ├── Quest/
│   │   ├── QuestManager.cs
│   │   ├── EncounterManager.cs
│   │   └── QuestGenerator.cs
│   └── UI/
│       ├── GuildHallUI.cs
│       ├── CombatUI.cs
│       ├── QuestBoardUI.cs
│       └── CharacterDetailUI.cs
├── Data/
│   ├── Characters/
│   ├── Enemies/
│   ├── Quests/
│   └── Items/
├── Prefabs/
├── Scenes/
│   ├── MainMenu.unity
│   ├── GuildHall.unity
│   └── Combat.unity
└── Resources/
```

### Data Storage
- **Runtime:** ScriptableObjects for static data (enemies, items, quests)
- **Save Data:** JSON serialization + PlayerPrefs (simple) or file-based
- **Auto-save:** On quest completion, recruitment, major events

### Key Unity Packages
- **DOTween** (free) - UI animations
- **TextMesh Pro** (built-in) - Typography
- **A* Pathfinding Project** ($100) or custom implementation
- **Odin Inspector** ($60, optional) - Better editor tools

---

## UI/UX Screens (Alpha)

### Guild Hall (Hub)
```
+----------------------------------+
|  [Guild Crest]   [Gold: 1,234g]  |
|  "The Iron Wolves"               |
+----------------------------------+
|  +----------------------------+  |
|  |     CONTRACT BOARD         |  |
|  |   [!] 3 new quests         |  |
|  +----------------------------+  |
|                                  |
|  +------------+ +------------+   |
|  | BARRACKS   | | RECRUIT    |   |
|  | 4/6 slots  | | 5 available|   |
|  +------------+ +------------+   |
+----------------------------------+
```

### Combat Screen
```
+--------------------------------------------------+
| Turn: 3    [Ally Turn]                    [Menu] |
+--------------------------------------------------+
|                 ENEMY HP BARS                     |
+--------------------------------------------------+
|                                                  |
|              HEX GRID (10x12)                    |
|                                                  |
+--------------------------------------------------+
| [Active Character]              HP: 45/45        |
| +--------+ +--------+ +--------+ +--------+      |
| | MOVE   | | ATTACK | | ABILITY| | END    |      |
| +--------+ +--------+ +--------+ +--------+      |
+--------------------------------------------------+
```

### Victory Screen
```
+--------------------------------------------------+
|              ===== VICTORY =====                 |
+--------------------------------------------------+
|  Duration: 8 turns                               |
|  Enemies Slain: 6                                |
|  Damage Dealt: 342 | Damage Taken: 87            |
+--------------------------------------------------+
|  PARTY RESULTS                                   |
|  [Portrait] Grimjaw    4 kills  156 dmg          |
|  [Portrait] Elara      1 kill   89 dmg           |
|  [Portrait] Thornwick  1 kill   67 dmg   45 heal |
|  [Portrait] Shadow     0 kills  30 dmg           |
+--------------------------------------------------+
|  REWARDS                                         |
|  Gold: +250g    XP: +150 each                    |
|  Items: [Iron Sword] [Health Potion x2]          |
+--------------------------------------------------+
|               [ CONTINUE ]                       |
+--------------------------------------------------+
```

---

## Testing Milestones

### Week 4: Grid Combat Test
- [ ] 2v2 combat works
- [ ] Movement and attacks functional
- [ ] Turn order correct

### Week 8: Full Combat Test
- [ ] 4v4 combat with all classes
- [ ] All 20 abilities functional
- [ ] AI makes decisions

### Week 12: AI Differentiation Test
- [ ] Blind playtest: "Which character is smartest?"
- [ ] Low INT makes visible mistakes
- [ ] High INT makes better choices
- [ ] Captain commands are noticed

### Week 16: Quest Loop Test
- [ ] Full quest from board to completion
- [ ] Victory/defeat outcomes work
- [ ] XP and rewards distributed

### Week 20: Management Loop Test
- [ ] Recruit → Quest → Manage cycle
- [ ] Economy balanced (not going bankrupt)
- [ ] Satisfaction system functional

### Week 24: Alpha Complete
- [ ] 10+ hours playable content
- [ ] All 10 quests completable
- [ ] Core hook validated ("I want different INT characters")

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| AI doesn't feel different | Exaggerate low INT mistakes (comedic); Test at Week 12 |
| Combat too slow | Target 5-7 min fights; Fast animations (0.5s) |
| Scope creep | Feature freeze at Week 8; Everything else goes to Beta |
| Pathfinding complexity | Use A* library; Simple hex grid |
| Balance issues | Placeholder numbers; Iterate in playtesting |

---

## Phase 1 Complete Checklist

### Core Systems
- [ ] Hex grid with pathfinding
- [ ] Turn-based combat
- [ ] 4 races, 4 classes implemented
- [ ] 20 abilities (5 per class)
- [ ] 3-tier INT AI system
- [ ] Captain mechanics
- [ ] Quest flow (3 types)
- [ ] Basic recruitment
- [ ] Simple economy
- [ ] Satisfaction system

### Content
- [ ] 10 quests
- [ ] 15 enemy types
- [ ] 30 items
- [ ] Name generator

### UI
- [ ] Guild Hall hub
- [ ] Contract Board
- [ ] Barracks/Roster
- [ ] Combat screen
- [ ] Victory/Defeat screens

### Technical
- [ ] Save/Load (single slot)
- [ ] Auto-save
- [ ] iOS build working

---

## Success Criteria

**Phase 1 is successful if:**
1. Playtesters can identify INT differences without being told
2. Captain feels impactful in at least 50% of combats
3. "I want to play again" feedback from 3+ testers
4. 10+ hours of gameplay without critical bugs
5. Core loop is engaging: Recruit → Quest → Manage → Repeat

---

*Next Phase: Beta "Battle Ready" - Combat commentary, kill announcer, personality traits, relationships, story, full polish*
