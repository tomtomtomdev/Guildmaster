# Guild Master - Supplemental Specification

*This document fills the remaining specification gaps not covered by the Core GDD, Technical Spec, Content Spec, or MVP Roadmap.*

---

## Table of Contents
1. [Character Generation System](#character-generation-system)
2. [Trait System Mechanics](#trait-system-mechanics)
3. [Relationship System](#relationship-system)
4. [Skill System](#skill-system)
5. [Level Progression](#level-progression)
6. [Training & Development System](#training--development-system)
7. [UI/UX Detailed Specification](#uiux-detailed-specification)
8. [Tutorial & Onboarding](#tutorial--onboarding)
9. [Dialogue System](#dialogue-system)
10. [Audio Design](#audio-design)
11. [Name & Text Generation](#name--text-generation)
12. [Accessibility Features](#accessibility-features)
13. [Error Handling & Edge Cases](#error-handling--edge-cases)
14. [Analytics & Telemetry](#analytics--telemetry)
15. [Localization Framework](#localization-framework)

---

## Character Generation System

### Adventurer Pool Generation

At campaign start, generate 15-20 potential recruits. Each campaign uses a seeded random generation to ensure variety across playthroughs.

```python
def generate_adventurer_pool(seed, count=18):
    random.seed(seed)
    pool = []

    # Ensure class distribution (MVP: 4 classes)
    class_distribution = {
        'Warrior': 5,
        'Rogue': 4,
        'Mage': 4,
        'Cleric': 5
    }

    for class_type, class_count in class_distribution.items():
        for _ in range(class_count):
            adventurer = generate_single_adventurer(class_type)
            pool.append(adventurer)

    random.shuffle(pool)
    return pool[:count]

def generate_single_adventurer(class_type):
    # Race selection (weighted by class synergy)
    race_weights = get_race_weights(class_type)
    race = weighted_random(race_weights)

    # Base stat generation (3d6 drop lowest, per stat)
    base_stats = {}
    for stat in ['str', 'dex', 'con', 'int', 'wis', 'cha']:
        rolls = sorted([random(1,6) for _ in range(4)], reverse=True)
        base_stats[stat] = sum(rolls[:3])  # 3-18 range

    # Apply racial modifiers
    stats = apply_racial_modifiers(base_stats, race)

    # Apply class primary stat boost (+2 to main stat)
    stats = apply_class_boost(stats, class_type)

    # Generate personality traits
    personality = generate_personality()

    # Generate name
    name = generate_name(race)

    # Calculate hiring cost
    hire_cost = calculate_hire_cost(stats, personality)

    return {
        'name': name,
        'race': race,
        'class': class_type,
        'stats': stats,
        'personality': personality,
        'level': 1,
        'hire_cost': hire_cost,
        'traits': assign_starting_traits(race, class_type, personality)
    }
```

### Race-Class Synergy Weights

```python
RACE_CLASS_WEIGHTS = {
    'Warrior': {'Human': 1.0, 'Elf': 0.5, 'Dwarf': 1.5, 'Orc': 1.5},
    'Rogue':   {'Human': 1.0, 'Elf': 1.5, 'Dwarf': 0.5, 'Orc': 0.3},
    'Mage':    {'Human': 1.0, 'Elf': 1.5, 'Dwarf': 0.3, 'Orc': 0.2},
    'Cleric':  {'Human': 1.2, 'Elf': 0.8, 'Dwarf': 1.2, 'Orc': 0.5}
}
```

### Racial Stat Modifiers

| Race | STR | DEX | CON | INT | WIS | CHA |
|------|-----|-----|-----|-----|-----|-----|
| Human | +1 | +1 | +1 | +1 | +1 | +1 |
| Elf | -1 | +2 | -1 | +2 | +1 | +1 |
| Dwarf | +2 | -1 | +2 | +0 | +1 | -1 |
| Orc | +3 | +0 | +2 | -2 | -1 | -1 |

### Hiring Cost Formula

```python
def calculate_hire_cost(stats, personality):
    # Base cost by stat total
    stat_total = sum(stats.values())
    base_cost = (stat_total - 60) * 20 + 200  # 200-600 gold range

    # Personality modifiers
    if personality['greedy'] >= 7:
        base_cost *= 1.3  # Greedy adventurers cost more
    if personality['loyal'] >= 7:
        base_cost *= 0.9  # Loyal ones accept less
    if personality['brave'] >= 8:
        base_cost *= 1.1  # Brave ones know their worth

    # Ensure minimum
    return max(100, int(base_cost))
```

---

## Trait System Mechanics

### Personality Traits (0-10 Scale)

Each adventurer has 4 personality dimensions that affect gameplay:

#### Greedy (0-10)
*Desire for wealth and material possessions*

| Score | Label | Effects |
|-------|-------|---------|
| 0-3 | Generous | +5 relationship with party; accepts less loot share |
| 4-6 | Balanced | No modifier |
| 7-10 | Greedy | -3 satisfaction if loot share < average; may steal from party (WIS check) |

**Combat AI Impact:**
- Greedy 8+: Prioritizes looting over combat (may break formation to grab items)
- Greedy 3-: Shares consumables with allies in need

#### Loyal (0-10)
*Commitment to guild and allies*

| Score | Label | Effects |
|-------|-------|---------|
| 0-3 | Mercenary | -20% desertion threshold; +50% poaching vulnerability |
| 4-6 | Professional | Standard behavior |
| 7-10 | Devoted | +30% desertion threshold; immune to rival poaching; +1 morale to nearby allies |

**Combat AI Impact:**
- Loyal 8+: Moves to protect low-HP allies; takes opportunity attacks for friends
- Loyal 3-: May flee combat early if losing

#### Brave (0-10)
*Willingness to face danger*

| Score | Label | Effects |
|-------|-------|---------|
| 0-3 | Cowardly | -2 morale in dangerous situations; may refuse high-risk quests |
| 4-6 | Steady | Standard behavior |
| 7-10 | Reckless | +2 attack when outnumbered; -2 AC (takes risks) |

**Combat AI Impact:**
- Brave 8+: Charges powerful enemies; ignores retreat orders (CHA check to override)
- Brave 3-: Flees at 40% HP instead of 20%

#### Cautious (0-10)
*Carefulness and risk assessment*

| Score | Label | Effects |
|-------|-------|---------|
| 0-3 | Reckless | +10% trap trigger chance; doesn't check for ambush |
| 4-6 | Balanced | Standard behavior |
| 7-10 | Paranoid | +30% trap detection; +20% ambush detection; -1 initiative (overthinks) |

**Combat AI Impact:**
- Cautious 8+: Always takes cover; waits for allies before engaging
- Cautious 3-: Walks into hazards; triggers traps

### Innate Traits (Racial/Class)

These are fixed traits based on race/class:

**Racial Traits:**
| Race | Trait | Effect |
|------|-------|--------|
| Human | Adaptable | +10% XP gain; learn new abilities 1 level early |
| Elf | Keen Senses | +2 perception; immune to surprise in first round |
| Dwarf | Stone Blood | Poison resistance (50%); +2 vs disease saves |
| Orc | Battle Fury | +3 damage when HP < 30%; +1 STR when bloodied |

**Class Traits:**
| Class | Trait | Effect |
|-------|-------|--------|
| Warrior | Combat Stance | Can adopt defensive (+2 AC, -2 attack) or offensive (+2 attack, -2 AC) stance |
| Rogue | Opportunist | +2d6 damage on flanked or surprised enemies |
| Mage | Arcane Focus | Can sacrifice HP (5) to recover mana (10) |
| Cleric | Divine Grace | 1/quest: Auto-succeed a death save or stabilize ally |

### Acquired Traits

Earned through gameplay events:

| Trigger | Trait | Effect | Duration |
|---------|-------|--------|----------|
| 3 quest successes in a row | Confident | +5 morale, +1 CHA checks | Until failure |
| Witness ally death | Traumatized | +10 stress per quest; -2 WIS | 5 quests or therapy |
| Survive at 1 HP | Scarred Veteran | +2 CON, -1 CHA | Permanent |
| Kill a boss alone | Glory Seeker | +10% damage vs elites; may disobey captain to get kill | Permanent |
| 10 quests with same ally | Bonded (Ally) | +2 all stats when in party with that ally | While ally alive |
| Betrayed by rival guild | Vendetta | +20% damage vs rival guild members | Until rival defeated |

---

## Relationship System

### Relationship Score (-100 to +100)

Every adventurer pair has a relationship score that evolves over time.

```python
class RelationshipMatrix:
    def __init__(self, roster):
        self.scores = {}  # (charA_id, charB_id): score

    def get_relationship(self, char_a, char_b):
        key = tuple(sorted([char_a.id, char_b.id]))
        return self.scores.get(key, 0)  # Default neutral

    def modify_relationship(self, char_a, char_b, delta, reason):
        key = tuple(sorted([char_a.id, char_b.id]))
        current = self.scores.get(key, 0)
        self.scores[key] = clamp(current + delta, -100, 100)

        # Log for player visibility
        log_relationship_event(char_a, char_b, delta, reason)
```

### Relationship Thresholds

| Score | Label | Effects |
|-------|-------|---------|
| -100 to -50 | Hostile | Will not party together; may sabotage each other |
| -49 to -20 | Dislike | -1 to coordination rolls; stress +5 when paired |
| -19 to +19 | Neutral | No effect |
| +20 to +49 | Friendly | +1 coordination; share consumables |
| +50 to +79 | Close Friends | +2 coordination; protect each other in combat |
| +80 to +100 | Bonded | Synergy attacks unlock; morale linked |

### Relationship Events

**Positive Events:**
| Event | Change | Notes |
|-------|--------|-------|
| Complete quest together | +3 | Shared success |
| One heals/saves the other | +10 | Life debt |
| Compatible personality (both Loyal 7+) | +2/quest | Organic growth |
| Give loot share to other | +5 | Generosity |
| 5 quests together without conflict | +5 | Familiarity bonus |

**Negative Events:**
| Event | Change | Notes |
|-------|--------|-------|
| One blamed for quest failure | -10 | Scapegoating |
| Loot dispute | -8 | Greedy characters trigger this |
| Left behind in combat | -15 | Abandonment |
| Incompatible personality | -2/quest | Friction |
| One kills the other's friend | -30 | Trauma |

### Synergy Abilities (Bonded Pairs)

When two characters reach +80 relationship, they unlock a synergy ability:

| Class Pair | Ability | Effect |
|------------|---------|--------|
| Warrior + Warrior | Shield Wall | Both +4 AC when adjacent |
| Warrior + Cleric | Holy Guardian | Cleric heals +50% when Warrior adjacent |
| Rogue + Mage | Arcane Ambush | Rogue can apply Mage's spell to sneak attack |
| Mage + Mage | Spell Surge | Combined casting: 2x damage, 2x mana cost |
| Cleric + Cleric | Divine Circle | AOE heal radius doubled |
| Rogue + Rogue | Double Strike | Coordinated attack: both attack same target |

---

## Skill System

### Skill Categories (MVP: Simplified)

**Combat Skills** (Passive, level automatically)
- Governed by class and stats
- Not player-managed

**Utility Skills** (Active, used in skill challenges)

| Skill | Governing Stat | Uses |
|-------|----------------|------|
| Perception | WIS | Detect traps, ambushes, hidden items |
| Athletics | STR | Climb, swim, break barriers |
| Stealth | DEX | Avoid detection, sneak past enemies |
| Lockpicking | DEX | Open locked chests, doors |
| Persuasion | CHA | Negotiate, intimidate, deceive |
| Medicine | WIS | Stabilize dying allies, cure disease |
| Arcana | INT | Identify magic items, disable magical traps |
| Survival | WIS | Track enemies, forage, navigate |

### Skill Check Resolution

```python
def skill_check(character, skill, difficulty):
    """
    difficulty: 5 (trivial), 10 (easy), 15 (medium), 20 (hard), 25 (very hard)
    """
    governing_stat = SKILL_STATS[skill]
    stat_value = character.stats[governing_stat]

    # Stat bonus: (stat - 10) / 2
    stat_bonus = (stat_value - 10) // 2

    # Class bonus if applicable
    class_bonus = get_class_skill_bonus(character.class, skill)

    # Roll d20
    roll = random(1, 20)

    # Critical success/failure
    if roll == 20:
        return {'success': True, 'critical': True}
    if roll == 1:
        return {'success': False, 'critical': True}

    total = roll + stat_bonus + class_bonus
    success = total >= difficulty

    return {'success': success, 'critical': False, 'roll': roll, 'total': total}
```

### Class Skill Bonuses

| Class | Bonus Skills (+3) |
|-------|-------------------|
| Warrior | Athletics, Intimidation |
| Rogue | Stealth, Lockpicking, Perception |
| Mage | Arcana, Perception |
| Cleric | Medicine, Persuasion |

### Skill Challenges in Quests

Non-combat encounters that use skills:

**Example: Trapped Corridor**
```json
{
  "type": "skill_challenge",
  "name": "Trapped Corridor",
  "description": "A hallway lined with pressure plates and dart traps.",
  "options": [
    {
      "action": "Detect and disarm",
      "checks": [
        {"skill": "Perception", "difficulty": 15},
        {"skill": "Lockpicking", "difficulty": 12}
      ],
      "success": "Party passes safely, +20 gold from trap components",
      "failure": "2d6 damage to lead character, continue"
    },
    {
      "action": "Rush through",
      "checks": [
        {"skill": "Athletics", "difficulty": 12, "all_party": true}
      ],
      "success": "Party passes with minor scratches (1d6 damage each)",
      "failure": "3d6 damage to each character who fails"
    },
    {
      "action": "Find alternate route",
      "checks": [
        {"skill": "Perception", "difficulty": 18}
      ],
      "success": "Bypass trap entirely, -10 minutes (time cost in timed quests)",
      "failure": "Waste 30 minutes, must choose another option"
    }
  ]
}
```

---

## Level Progression

### XP Requirements

| Level | XP Required | Total XP |
|-------|-------------|----------|
| 1 | 0 | 0 |
| 2 | 300 | 300 |
| 3 | 600 | 900 |
| 4 | 1200 | 2100 |
| 5 | 2400 | 4500 |
| 6 | 4800 | 9300 |
| 7 | 7200 | 16500 |
| 8 | 10000 | 26500 |
| 9 | 15000 | 41500 |
| 10 | 20000 | 61500 |

### XP Awards

| Source | XP |
|--------|-----|
| Enemy defeated (per threat level) | Threat / 10 |
| Quest completion (Basic) | 100 |
| Quest completion (Advanced) | 200 |
| Quest completion (Elite) | 400 |
| Bonus: Flawless (no party death) | +50% |
| Bonus: Under-leveled (avg party level < quest tier) | +25% |

### Level Up Benefits

```python
def level_up(character):
    character.level += 1

    # HP increase
    hp_roll = random(1, CLASS_HIT_DIE[character.class])
    con_bonus = (character.stats['con'] - 10) // 2
    hp_gain = max(1, hp_roll + con_bonus)
    character.max_hp += hp_gain
    character.hp = character.max_hp  # Full heal on level up

    # Stat increase (every 4 levels)
    if character.level % 4 == 0:
        # Player chooses or auto-assign based on class
        character.stat_points_available += 2

    # Ability unlock
    new_ability = get_ability_for_level(character.class, character.level)
    if new_ability:
        character.abilities.append(new_ability)

    # Secondary stat recalculation
    recalculate_secondary_stats(character)
```

### Class Hit Dice

| Class | Hit Die | Average HP/Level |
|-------|---------|------------------|
| Warrior | d10 | 5.5 + CON mod |
| Rogue | d8 | 4.5 + CON mod |
| Mage | d6 | 3.5 + CON mod |
| Cleric | d8 | 4.5 + CON mod |

### Ability Unlock Schedule

| Level | Warrior | Rogue | Mage | Cleric |
|-------|---------|-------|------|--------|
| 1 | Power Attack | Sneak Attack | Magic Missile | Cure Wounds |
| 2 | - | Hide | Shield | - |
| 3 | Cleave, Shield Bash | Backstab | Fireball | Bless, Turn Undead |
| 5 | Second Wind, Intimidate | Evasion, Poison Blade | Haste, Counterspell | Mass Healing, Divine Smite |
| 7 | Whirlwind | Smoke Bomb | Polymorph | Holy Aura |
| 9 | Battle Cry | - | Meteor Swarm | Resurrection |

---

## Training & Development System

Training allows adventurers to gain XP, improve stats, and learn new abilities without going on full quests. This provides progression options during downtime and creates meaningful management decisions.

### Training Overview

```
+------------------+     +------------------+     +------------------+
|   BARRACKS       |     |   GUILD HALL     |     |   FIELD          |
|   TRAINING       |     |   ACTIVITIES     |     |   TRAINING       |
+------------------+     +------------------+     +------------------+
| - Solo Practice  |     | - Sparring       |     | - Training Quests|
| - Equipment Drills|    | - Study Sessions |     | - Exploration    |
| - Rest & Recovery|     | - Mentorship     |     | - Apprenticeship |
+------------------+     +------------------+     +------------------+
        |                        |                        |
        v                        v                        v
   [Low XP/Safe]           [Medium XP/Social]       [High XP/Risky]
```

### Training Methods

---

#### 1. Barracks Training (Solo)

**Location:** Barracks facility
**Duration:** 1-7 days
**Risk:** None
**Cost:** Facility upkeep only

Solo training activities that adventurers can do independently.

##### Solo Practice

```python
class SoloPractice:
    """
    Basic training that any adventurer can do alone.
    Low XP gain but completely safe.
    """

    PRACTICE_TYPES = {
        'weapon_drills': {
            'description': "Practice combat forms and techniques",
            'xp_per_day': 15,
            'stat_focus': ['str', 'dex'],
            'class_bonus': {'Warrior': 1.5, 'Rogue': 1.2}
        },
        'physical_conditioning': {
            'description': "Strength and endurance training",
            'xp_per_day': 12,
            'stat_focus': ['str', 'con'],
            'class_bonus': {'Warrior': 1.3, 'Paladin': 1.2}
        },
        'meditation': {
            'description': "Mental focus and mana recovery",
            'xp_per_day': 12,
            'stat_focus': ['wis', 'int'],
            'class_bonus': {'Mage': 1.5, 'Cleric': 1.4, 'Druid': 1.3}
        },
        'agility_training': {
            'description': "Speed and reflexes practice",
            'xp_per_day': 12,
            'stat_focus': ['dex'],
            'class_bonus': {'Rogue': 1.5, 'Ranger': 1.3}
        },
        'study': {
            'description': "Read tomes and study tactics",
            'xp_per_day': 10,
            'stat_focus': ['int', 'wis'],
            'class_bonus': {'Mage': 1.4, 'Cleric': 1.2},
            'requires': 'library_facility'
        }
    }

    def calculate_daily_xp(self, character, practice_type):
        base_xp = self.PRACTICE_TYPES[practice_type]['xp_per_day']

        # Class bonus
        class_mult = self.PRACTICE_TYPES[practice_type]['class_bonus'].get(
            character.class, 1.0
        )

        # INT affects learning speed
        int_bonus = 1.0 + (character.stats['int'] - 10) * 0.02

        # Facility quality bonus
        facility_bonus = get_barracks_quality_bonus()  # 1.0 to 1.5

        # Diminishing returns after 3 consecutive days
        fatigue_mult = max(0.5, 1.0 - (character.consecutive_training_days - 3) * 0.1)

        total_xp = base_xp * class_mult * int_bonus * facility_bonus * fatigue_mult

        return int(total_xp)
```

##### Equipment Familiarity

New equipment requires training to use effectively.

```python
class EquipmentTraining:
    """
    Training to become proficient with new equipment.
    Removes unfamiliarity penalties.
    """

    FAMILIARITY_LEVELS = {
        'unfamiliar': {'penalty': -2, 'training_days': 0},
        'learning': {'penalty': -1, 'training_days': 1},
        'familiar': {'penalty': 0, 'training_days': 3},
        'proficient': {'penalty': 0, 'bonus': 1, 'training_days': 7}
    }

    def train_with_equipment(self, character, item, days):
        """
        Train with a specific piece of equipment.
        """
        current_familiarity = character.equipment_familiarity.get(item.id, 0)

        # Training speed based on INT and item complexity
        learning_rate = 1.0 + (character.stats['int'] - 10) * 0.05
        effective_days = days * learning_rate

        new_familiarity = current_familiarity + effective_days
        character.equipment_familiarity[item.id] = new_familiarity

        # XP bonus for equipment training
        xp_gained = days * 5
        character.xp += xp_gained

        return {
            'familiarity_gained': effective_days,
            'new_level': get_familiarity_level(new_familiarity),
            'xp_gained': xp_gained
        }
```

##### Rest & Recovery Training

Light training combined with rest for injured/stressed adventurers.

| Activity | Duration | Effect |
|----------|----------|--------|
| Light Exercise | 1 day | Recover 10% HP, 5 XP |
| Rest & Study | 2 days | Recover 25% HP, -10 Stress, 15 XP |
| Full Recovery | 3 days | Full HP, -20 Stress, 20 XP |
| Meditation Retreat | 5 days | Full HP, Stress = 0, +30 XP, +1 WIS (temp) |

---

#### 2. Guild Hall Training (Social)

**Location:** Guild Hall / Training Grounds facility
**Duration:** 1-5 days
**Risk:** Minor (sparring injuries)
**Cost:** Trainer fees / opportunity cost

Training that involves other adventurers or hired trainers.

##### Sparring

```python
class SparringSystem:
    """
    Combat practice between two adventurers.
    Better XP than solo, builds relationships, small injury risk.
    """

    def conduct_sparring(self, character_a, character_b, intensity='normal'):
        """
        intensity: 'light', 'normal', 'intense'
        """
        intensities = {
            'light': {'xp_mult': 0.7, 'injury_chance': 0.02, 'relationship_change': 2},
            'normal': {'xp_mult': 1.0, 'injury_chance': 0.08, 'relationship_change': 3},
            'intense': {'xp_mult': 1.4, 'injury_chance': 0.20, 'relationship_change': 5}
        }

        settings = intensities[intensity]
        base_xp = 30

        # Calculate XP for each participant
        for char in [character_a, character_b]:
            opponent = character_b if char == character_a else character_a

            # Learn more from fighting stronger opponents
            level_diff = opponent.level - char.level
            level_bonus = 1.0 + max(0, level_diff * 0.1)  # Up to +50% for 5 levels higher

            xp_gained = int(base_xp * settings['xp_mult'] * level_bonus)
            char.xp += xp_gained

        # Relationship change (positive from shared activity)
        modify_relationship(
            character_a, character_b,
            settings['relationship_change'],
            reason='sparring_together'
        )

        # Injury check
        results = {'injuries': []}
        for char in [character_a, character_b]:
            if random.random() < settings['injury_chance']:
                injury = apply_sparring_injury(char)
                results['injuries'].append({'character': char, 'injury': injury})

        return results

    def apply_sparring_injury(self, character):
        """
        Minor injuries from sparring - heal quickly.
        """
        injuries = [
            {'name': 'Bruised', 'hp_loss': 5, 'duration': 1},
            {'name': 'Sprained', 'hp_loss': 10, 'duration': 2, 'stat_penalty': {'dex': -1}},
            {'name': 'Minor Cut', 'hp_loss': 8, 'duration': 1}
        ]

        injury = random.choice(injuries)
        character.hp -= injury['hp_loss']
        character.add_temporary_condition(injury)

        return injury
```

##### Mentorship Program

High-level adventurers can mentor lower-level ones.

```python
class MentorshipSystem:
    """
    Experienced adventurers teach newer ones.
    Great XP for student, satisfaction for mentor.
    """

    MENTORSHIP_REQUIREMENTS = {
        'min_mentor_level': 4,
        'max_level_gap': 5,  # Mentor must be at least this many levels higher
        'same_class_bonus': 1.5,
        'compatible_class_bonus': 1.2  # e.g., Warrior mentoring Paladin
    }

    def start_mentorship(self, mentor, student, duration_days):
        """
        Begin a mentorship session.
        """
        if mentor.level < self.MENTORSHIP_REQUIREMENTS['min_mentor_level']:
            return {'error': 'Mentor level too low'}

        if mentor.level - student.level < 2:
            return {'error': 'Level gap too small for effective mentorship'}

        # Calculate effectiveness
        level_gap = mentor.level - student.level
        base_xp_per_day = 25 + (level_gap * 5)  # 25-50 XP/day

        # Class synergy
        if mentor.class == student.class:
            class_mult = self.MENTORSHIP_REQUIREMENTS['same_class_bonus']
        elif are_compatible_classes(mentor.class, student.class):
            class_mult = self.MENTORSHIP_REQUIREMENTS['compatible_class_bonus']
        else:
            class_mult = 1.0

        # Mentor's teaching ability (CHA + INT)
        teaching_skill = (mentor.stats['cha'] + mentor.stats['int']) / 2
        teaching_mult = 0.8 + (teaching_skill - 10) * 0.03  # 0.8 to 1.1

        # Student's learning ability (INT)
        learning_mult = 0.9 + (student.stats['int'] - 10) * 0.02

        total_xp = int(base_xp_per_day * duration_days * class_mult * teaching_mult * learning_mult)

        return {
            'student_xp': total_xp,
            'mentor_satisfaction': 5 * duration_days,
            'relationship_change': 5 + duration_days,
            'special_unlock': check_special_teaching(mentor, student, duration_days)
        }

    def check_special_teaching(self, mentor, student, duration):
        """
        Long mentorships can unlock special abilities or traits.
        """
        if duration >= 5 and mentor.level >= 7:
            # Chance to teach a signature move
            if random.random() < 0.2:
                teachable = get_teachable_abilities(mentor)
                if teachable:
                    ability = random.choice(teachable)
                    return {'type': 'ability_learned', 'ability': ability}

        if duration >= 3:
            # Student may adopt mentor's combat style
            if random.random() < 0.3:
                return {'type': 'trait_gained', 'trait': 'Mentored',
                        'effect': f'+5% damage when {mentor.name} is in party'}

        return None

# Compatible class pairs for mentorship
COMPATIBLE_CLASSES = {
    'Warrior': ['Paladin', 'Ranger'],
    'Rogue': ['Ranger', 'Bard'],
    'Mage': ['Cleric', 'Druid', 'Bard'],
    'Cleric': ['Paladin', 'Druid'],
    'Paladin': ['Warrior', 'Cleric'],
    'Ranger': ['Warrior', 'Rogue', 'Druid'],
    'Druid': ['Cleric', 'Ranger', 'Mage'],
    'Bard': ['Rogue', 'Mage']
}
```

##### Group Study Sessions

```python
class StudySession:
    """
    Group learning sessions for magical/knowledge skills.
    All participants gain XP, better with more participants.
    """

    def conduct_study_session(self, participants, topic):
        """
        topics: 'arcana', 'tactics', 'history', 'medicine', 'religion'
        """
        TOPICS = {
            'arcana': {
                'stat_focus': 'int',
                'class_bonus': ['Mage', 'Druid'],
                'base_xp': 20
            },
            'tactics': {
                'stat_focus': 'int',
                'class_bonus': ['Warrior', 'Paladin', 'Ranger'],
                'base_xp': 20
            },
            'history': {
                'stat_focus': 'int',
                'class_bonus': ['Bard', 'Cleric'],
                'base_xp': 15
            },
            'medicine': {
                'stat_focus': 'wis',
                'class_bonus': ['Cleric', 'Druid'],
                'base_xp': 20
            },
            'religion': {
                'stat_focus': 'wis',
                'class_bonus': ['Cleric', 'Paladin'],
                'base_xp': 18
            }
        }

        topic_data = TOPICS[topic]

        # Group size bonus (2-4 participants ideal)
        group_bonus = {1: 0.7, 2: 1.0, 3: 1.2, 4: 1.3, 5: 1.2, 6: 1.0}
        size_mult = group_bonus.get(len(participants), 0.8)

        results = []
        for char in participants:
            xp = topic_data['base_xp']

            # Class bonus
            if char.class in topic_data['class_bonus']:
                xp *= 1.3

            # Stat bonus
            stat_value = char.stats[topic_data['stat_focus']]
            stat_mult = 1.0 + (stat_value - 10) * 0.03

            final_xp = int(xp * size_mult * stat_mult)
            char.xp += final_xp

            results.append({'character': char, 'xp': final_xp})

        # Relationship bonus for all pairs
        for i, char_a in enumerate(participants):
            for char_b in participants[i+1:]:
                modify_relationship(char_a, char_b, 1, 'studied_together')

        return results
```

##### Hired Trainers

Special NPCs that can be hired to train adventurers.

```python
TRAINER_TYPES = {
    'weapons_master': {
        'cost_per_day': 100,
        'xp_per_day': 40,
        'stat_boost_chance': 0.1,  # 10% chance per day for +1 STR or DEX
        'stat_options': ['str', 'dex'],
        'class_affinity': ['Warrior', 'Paladin', 'Ranger'],
        'unlocks_at': 'Training Grounds Level 2'
    },
    'arcane_tutor': {
        'cost_per_day': 150,
        'xp_per_day': 45,
        'stat_boost_chance': 0.1,
        'stat_options': ['int'],
        'class_affinity': ['Mage', 'Bard'],
        'special': 'Can teach new spells',
        'unlocks_at': 'Library Facility'
    },
    'battle_priest': {
        'cost_per_day': 120,
        'xp_per_day': 40,
        'stat_boost_chance': 0.1,
        'stat_options': ['wis'],
        'class_affinity': ['Cleric', 'Paladin', 'Druid'],
        'special': 'Reduces stress by 5/day during training',
        'unlocks_at': 'Chapel Facility'
    },
    'shadow_mentor': {
        'cost_per_day': 200,
        'xp_per_day': 50,
        'stat_boost_chance': 0.15,
        'stat_options': ['dex'],
        'class_affinity': ['Rogue'],
        'special': 'Can teach Thieves Guild abilities',
        'unlocks_at': 'Thieves Guild Rep +25'
    },
    'retired_hero': {
        'cost_per_day': 300,
        'xp_per_day': 60,
        'stat_boost_chance': 0.2,
        'stat_options': ['str', 'dex', 'con'],
        'class_affinity': ['all'],
        'special': 'Can teach legendary techniques',
        'unlocks_at': 'Guild Reputation 50+'
    }
}
```

---

#### 3. Field Training (Active)

**Location:** Outside guild
**Duration:** 1-7 days
**Risk:** Low to Medium
**Cost:** Travel + supplies

Training through actual (but controlled) field experience.

##### Training Quests

Special low-risk quests designed for training purposes.

```python
class TrainingQuest:
    """
    Simplified quests with reduced rewards but safer learning.
    """

    TRAINING_QUEST_TYPES = {
        'pest_control': {
            'description': "Clear giant rats from a farmer's barn",
            'difficulty': 'trivial',
            'enemy_level_cap': 1,
            'xp_reward': 50,
            'gold_reward': 30,
            'encounters': 2,
            'max_party_level': 3  # Overleveled parties get no XP
        },
        'patrol_duty': {
            'description': "Patrol the roads around town",
            'difficulty': 'easy',
            'enemy_level_cap': 2,
            'xp_reward': 75,
            'gold_reward': 50,
            'encounters': 2,
            'encounter_chance': 0.6,  # 60% chance per encounter slot
            'max_party_level': 4
        },
        'escort_training': {
            'description': "Escort a merchant on a safe route",
            'difficulty': 'easy',
            'enemy_level_cap': 2,
            'xp_reward': 80,
            'gold_reward': 60,
            'encounters': 1,
            'skill_challenges': 2,
            'max_party_level': 5
        },
        'dungeon_dive': {
            'description': "Explore the first level of an old ruin",
            'difficulty': 'normal',
            'enemy_level_cap': 3,
            'xp_reward': 120,
            'gold_reward': 100,
            'encounters': 3,
            'has_treasure': True,
            'max_party_level': 6
        }
    }

    def generate_training_quest(self, quest_type, party_avg_level):
        quest_data = self.TRAINING_QUEST_TYPES[quest_type]

        # Check if party is overleveled
        if party_avg_level > quest_data['max_party_level']:
            return {
                'warning': 'Party overleveled - reduced XP',
                'xp_modifier': 0.25
            }

        # Scale difficulty slightly to party
        scaled_enemies = self.generate_training_enemies(
            quest_data['enemy_level_cap'],
            quest_data['encounters'],
            party_avg_level
        )

        return {
            'type': 'training_quest',
            'base_data': quest_data,
            'enemies': scaled_enemies,
            'retreat_always_available': True,  # Can always flee safely
            'death_converted_to_injury': True  # Deaths become injuries instead
        }
```

##### Exploration Expeditions

Scouting missions that provide XP through discovery rather than combat.

```python
class ExplorationExpedition:
    """
    Non-combat focused training through exploration.
    Good for leveling non-combat skills.
    """

    EXPLORATION_TYPES = {
        'wilderness_survey': {
            'description': "Map and survey a wilderness region",
            'duration_days': 3,
            'xp_per_day': 25,
            'skill_checks': ['survival', 'perception', 'athletics'],
            'discoveries': ['herb_cache', 'hidden_path', 'monster_den', 'ancient_marker'],
            'encounter_chance': 0.2
        },
        'ruin_scouting': {
            'description': "Scout an unexplored ruin for future quests",
            'duration_days': 2,
            'xp_per_day': 35,
            'skill_checks': ['perception', 'arcana', 'stealth'],
            'discoveries': ['treasure_room', 'trap_locations', 'enemy_patrol', 'secret_passage'],
            'encounter_chance': 0.4
        },
        'urban_investigation': {
            'description': "Gather information in a nearby city",
            'duration_days': 2,
            'xp_per_day': 20,
            'skill_checks': ['persuasion', 'perception', 'stealth'],
            'discoveries': ['contact', 'rumor', 'quest_lead', 'black_market'],
            'encounter_chance': 0.1
        }
    }

    def conduct_expedition(self, party, expedition_type):
        exp_data = self.EXPLORATION_TYPES[expedition_type]
        results = {
            'xp_gained': {},
            'discoveries': [],
            'skill_improvements': [],
            'encounters': []
        }

        for day in range(exp_data['duration_days']):
            # Daily XP for participation
            for char in party:
                base_xp = exp_data['xp_per_day']

                # WIS bonus for exploration
                wis_mult = 1.0 + (char.stats['wis'] - 10) * 0.02

                daily_xp = int(base_xp * wis_mult)
                results['xp_gained'][char.id] = results['xp_gained'].get(char.id, 0) + daily_xp

            # Skill checks for discoveries
            for skill in exp_data['skill_checks']:
                best_char = max(party, key=lambda c: get_skill_bonus(c, skill))
                check_result = skill_check(best_char, skill, difficulty=12)

                if check_result['success']:
                    discovery = random.choice(exp_data['discoveries'])
                    results['discoveries'].append({
                        'type': discovery,
                        'found_by': best_char,
                        'skill_used': skill
                    })

                    # Bonus XP for discoveries
                    results['xp_gained'][best_char.id] += 15

            # Random encounter chance
            if random.random() < exp_data['encounter_chance']:
                encounter = generate_exploration_encounter(expedition_type)
                results['encounters'].append(encounter)

        return results
```

##### Apprenticeship with Factions

Placing adventurers with faction trainers for extended periods.

```python
class FactionApprenticeship:
    """
    Long-term training with faction mentors.
    Requires faction reputation, provides unique benefits.
    """

    APPRENTICESHIPS = {
        'crown_military': {
            'faction': 'Crown',
            'required_rep': 20,
            'duration_days': 7,
            'cost': 200,
            'xp_total': 200,
            'benefits': [
                {'type': 'stat_increase', 'stat': 'str', 'amount': 1, 'chance': 0.3},
                {'type': 'ability_learn', 'ability': 'Shield Wall', 'chance': 0.2},
                {'type': 'trait_gain', 'trait': 'Military Discipline', 'chance': 0.4}
            ],
            'class_requirement': ['Warrior', 'Paladin']
        },
        'conclave_study': {
            'faction': 'Mages Conclave',
            'required_rep': 25,
            'duration_days': 10,
            'cost': 400,
            'xp_total': 300,
            'benefits': [
                {'type': 'stat_increase', 'stat': 'int', 'amount': 1, 'chance': 0.4},
                {'type': 'spell_learn', 'spell_tier': 'advanced', 'chance': 0.3},
                {'type': 'mana_increase', 'amount': 10, 'chance': 0.5}
            ],
            'class_requirement': ['Mage', 'Bard']
        },
        'thieves_guild_training': {
            'faction': 'Thieves Guild',
            'required_rep': 30,
            'duration_days': 5,
            'cost': 300,
            'xp_total': 175,
            'benefits': [
                {'type': 'stat_increase', 'stat': 'dex', 'amount': 1, 'chance': 0.35},
                {'type': 'ability_learn', 'ability': 'Improved Sneak Attack', 'chance': 0.25},
                {'type': 'skill_bonus', 'skill': 'lockpicking', 'amount': 2, 'chance': 0.6}
            ],
            'class_requirement': ['Rogue']
        },
        'temple_retreat': {
            'faction': 'Church of Light',
            'required_rep': 20,
            'duration_days': 7,
            'cost': 150,
            'xp_total': 180,
            'benefits': [
                {'type': 'stat_increase', 'stat': 'wis', 'amount': 1, 'chance': 0.35},
                {'type': 'spell_learn', 'spell': 'Greater Healing', 'chance': 0.2},
                {'type': 'stress_reduction', 'amount': 30, 'chance': 1.0}
            ],
            'class_requirement': ['Cleric', 'Paladin']
        },
        'druidic_communion': {
            'faction': 'Druidic Circle',
            'required_rep': 25,
            'duration_days': 14,
            'cost': 100,  # Low gold cost, high time cost
            'xp_total': 350,
            'benefits': [
                {'type': 'stat_increase', 'stat': 'wis', 'amount': 1, 'chance': 0.4},
                {'type': 'ability_learn', 'ability': 'Beast Speech', 'chance': 0.3},
                {'type': 'trait_gain', 'trait': 'Nature Attunement', 'chance': 0.5}
            ],
            'class_requirement': ['Druid', 'Ranger']
        },
        'tribal_warrior_rites': {
            'faction': 'Tribal Confederacy',
            'required_rep': 30,
            'duration_days': 5,
            'cost': 50,
            'xp_total': 150,
            'benefits': [
                {'type': 'stat_increase', 'stat': 'con', 'amount': 1, 'chance': 0.4},
                {'type': 'hp_increase', 'amount': 10, 'chance': 0.3},
                {'type': 'trait_gain', 'trait': 'Tribal Fury', 'chance': 0.35}
            ],
            'class_requirement': ['Warrior', 'Druid']
        }
    }

    def start_apprenticeship(self, character, apprenticeship_type):
        app_data = self.APPRENTICESHIPS[apprenticeship_type]

        # Validation
        if character.class not in app_data['class_requirement']:
            return {'error': f"Class {character.class} cannot take this apprenticeship"}

        faction_rep = get_faction_reputation(app_data['faction'])
        if faction_rep < app_data['required_rep']:
            return {'error': f"Requires {app_data['required_rep']} reputation with {app_data['faction']}"}

        if guild.gold < app_data['cost']:
            return {'error': 'Insufficient gold'}

        # Start apprenticeship
        guild.gold -= app_data['cost']
        character.status = 'apprenticeship'
        character.unavailable_days = app_data['duration_days']
        character.current_apprenticeship = apprenticeship_type

        return {
            'started': True,
            'completion_day': current_day + app_data['duration_days'],
            'cost_paid': app_data['cost']
        }

    def complete_apprenticeship(self, character):
        app_data = self.APPRENTICESHIPS[character.current_apprenticeship]

        results = {
            'xp_gained': app_data['xp_total'],
            'benefits_received': []
        }

        character.xp += app_data['xp_total']

        # Roll for each benefit
        for benefit in app_data['benefits']:
            if random.random() < benefit['chance']:
                self.apply_benefit(character, benefit)
                results['benefits_received'].append(benefit)

        # Faction reputation boost
        modify_faction_rep(app_data['faction'], 5)
        results['faction_rep_gained'] = 5

        character.status = 'available'
        character.current_apprenticeship = None

        return results
```

---

### Training Facility Upgrades

Training effectiveness scales with guild facilities.

```python
TRAINING_FACILITIES = {
    'barracks': {
        'levels': {
            1: {'capacity': 4, 'training_bonus': 1.0, 'cost': 0},
            2: {'capacity': 6, 'training_bonus': 1.1, 'cost': 500},
            3: {'capacity': 8, 'training_bonus': 1.2, 'cost': 1500}
        },
        'unlocks': {
            1: ['solo_practice', 'rest_recovery'],
            2: ['equipment_training'],
            3: ['advanced_conditioning']
        }
    },
    'training_grounds': {
        'levels': {
            1: {'sparring_slots': 2, 'training_bonus': 1.15, 'cost': 800},
            2: {'sparring_slots': 4, 'training_bonus': 1.25, 'cost': 2000},
            3: {'sparring_slots': 6, 'training_bonus': 1.4, 'cost': 5000}
        },
        'unlocks': {
            1: ['sparring', 'weapons_master_trainer'],
            2: ['group_drills', 'combat_simulations'],
            3: ['arena_battles', 'retired_hero_trainer']
        }
    },
    'library': {
        'levels': {
            1: {'study_bonus': 1.2, 'cost': 600},
            2: {'study_bonus': 1.4, 'cost': 1500},
            3: {'study_bonus': 1.6, 'spell_research': True, 'cost': 4000}
        },
        'unlocks': {
            1: ['study_sessions', 'arcane_tutor'],
            2: ['advanced_study', 'spell_copying'],
            3: ['spell_research', 'tome_of_knowledge']
        }
    },
    'chapel': {
        'levels': {
            1: {'meditation_bonus': 1.2, 'stress_recovery': 1.2, 'cost': 500},
            2: {'meditation_bonus': 1.3, 'stress_recovery': 1.4, 'cost': 1200},
            3: {'meditation_bonus': 1.5, 'stress_recovery': 1.6, 'blessing': True, 'cost': 3000}
        },
        'unlocks': {
            1: ['meditation', 'battle_priest_trainer'],
            2: ['group_prayer', 'confession'],
            3: ['divine_blessing', 'resurrection_service']
        }
    }
}
```

---

### Training Scheduling & Management

#### Weekly Training Schedule

```python
class TrainingScheduler:
    """
    Manage training assignments for the guild.
    """

    def __init__(self):
        self.schedule = {}  # character_id: [daily_assignments]

    def assign_training(self, character, training_type, days, start_day=None):
        """
        Assign a character to training for specified days.
        """
        if start_day is None:
            start_day = current_day

        # Check availability
        for day in range(start_day, start_day + days):
            if self.is_busy(character, day):
                return {'error': f'{character.name} is busy on day {day}'}

        # Make assignment
        assignment = {
            'type': training_type,
            'start_day': start_day,
            'end_day': start_day + days,
            'status': 'scheduled'
        }

        if character.id not in self.schedule:
            self.schedule[character.id] = []

        self.schedule[character.id].append(assignment)

        return {'success': True, 'assignment': assignment}

    def get_daily_activities(self, day):
        """
        Get all training activities happening on a specific day.
        """
        activities = []

        for char_id, assignments in self.schedule.items():
            for assignment in assignments:
                if assignment['start_day'] <= day < assignment['end_day']:
                    activities.append({
                        'character_id': char_id,
                        'training_type': assignment['type']
                    })

        return activities

    def process_daily_training(self, day):
        """
        Process all training for a given day.
        Returns results for each character training.
        """
        activities = self.get_daily_activities(day)
        results = []

        for activity in activities:
            character = get_character(activity['character_id'])
            training_type = activity['training_type']

            result = execute_training(character, training_type)
            results.append(result)

        return results
```

#### Training UI Screen

```
+--------------------------------------------------+
|  [<Back]           TRAINING                      |
+--------------------------------------------------+
|                                                  |
|  AVAILABLE FOR TRAINING (4)                      |
|  +--------------------------------------------+  |
|  | [Portrait] Grimjaw - Warrior Lv4           |  |
|  | Status: Idle        [ASSIGN TRAINING]      |  |
|  +--------------------------------------------+  |
|  | [Portrait] Elara - Mage Lv3                |  |
|  | Status: Resting (1 day)  [VIEW]            |  |
|  +--------------------------------------------+  |
|                                                  |
|  CURRENTLY TRAINING (2)                          |
|  +--------------------------------------------+  |
|  | [Portrait] Thornwick - Cleric Lv5          |  |
|  | Training: Temple Retreat (3 days left)     |  |
|  | Progress: [======----] 60%                 |  |
|  +--------------------------------------------+  |
|  | [Portrait] Shadow - Rogue Lv2              |  |
|  | Training: Sparring with Grimjaw            |  |
|  | Progress: [===-------] 30%                 |  |
|  +--------------------------------------------+  |
|                                                  |
|  TRAINING OPTIONS                                |
|  +------------+  +------------+  +------------+  |
|  | BARRACKS   |  | TRAINERS   |  | EXPEDITIONS|  |
|  | Solo/Rest  |  | Hire Expert|  | Field Work |  |
|  +------------+  +------------+  +------------+  |
|                                                  |
+--------------------------------------------------+
```

---

### Training Balance Guidelines

| Training Type | XP/Day | Risk | Cost | Best For |
|---------------|--------|------|------|----------|
| Solo Practice | 10-15 | None | Free | Safe catch-up |
| Equipment Training | 5 | None | Free | New gear |
| Rest & Recovery | 5-10 | None | Free | Injured/stressed |
| Sparring | 25-35 | Low | Free | Combat skills |
| Mentorship | 30-50 | None | Free | Low-level chars |
| Group Study | 15-25 | None | Free | Magic users |
| Hired Trainer | 40-60 | None | 100-300g/day | Focused growth |
| Training Quest | 50-120 | Low | Supplies | Practical XP |
| Exploration | 50-100 | Med | Supplies | Discovery + XP |
| Apprenticeship | 150-350 | None | 50-400g total | Special abilities |

**Design Goals:**
- Training should never be better than questing for XP
- Training provides safe progression during downtime
- High-cost training should offer unique benefits (stats, abilities)
- Social training (sparring, mentorship) builds relationships
- Field training has risk/reward similar to easy quests

---

## UI/UX Detailed Specification

### Screen Flow Diagram

```
[Title Screen]
    |
    +-- [New Game] --> [Guild Naming] --> [Guildmaster Creation] --> [Tutorial] --> [Guild Hall]
    |
    +-- [Continue] --> [Guild Hall]
    |
    +-- [Settings]
    |
    +-- [Credits]

[Guild Hall] (Hub)
    |
    +-- [Contract Board] --> [Quest Detail] --> [Party Selection] --> [Quest Execution]
    |                                                                       |
    |                                                        [Combat Screen] <--> [Victory/Defeat]
    |                                                                       |
    +-- [Barracks] --> [Adventurer Detail] --> [Equipment]          [Debrief Screen]
    |                                                                       |
    +-- [Recruitment] --> [Recruit Pool] --> [Hire Confirmation]    [Guild Hall]
    |
    +-- [Ledger] --> [Finances] / [Reputation] / [Quest Log]
    |
    +-- [World Map] --> [Region Detail] (Post-MVP)
    |
    +-- [Settings]
```

### Screen Specifications

#### 1. Guild Hall (Hub Screen)

**Layout:** Single-screen portrait view

```
+----------------------------------+
|  [Guild Crest]   [Gold: 1,234g]  |
|  "The Iron Wolves"               |
+----------------------------------+
|                                  |
|  +----------------------------+  |
|  |     CONTRACT BOARD         |  |
|  |   [!] 3 new quests         |  |
|  +----------------------------+  |
|                                  |
|  +------------+ +------------+   |
|  | BARRACKS   | | RECRUIT    |   |
|  | 4/6 slots  | | 5 available|   |
|  +------------+ +------------+   |
|                                  |
|  +------------+ +------------+   |
|  | LEDGER     | | WORLD MAP  |   |
|  | (finances) | | (locked)   |   |
|  +------------+ +------------+   |
|                                  |
+----------------------------------+
|         [Settings Gear]          |
+----------------------------------+
```

**Interactions:**
- Tap any button to navigate
- Long-press for tooltip
- Pull down to refresh world state

#### 2. Contract Board

**Layout:** Scrollable list

```
+----------------------------------+
|  [<Back]    CONTRACTS    [Filter]|
+----------------------------------+
| +------------------------------+ |
| | [!] Goblin Infestation       | |
| | Type: Extermination          | |
| | Difficulty: [**---]          | |
| | Reward: 250g, +10 Crown rep  | |
| | Recommended: Level 2+        | |
| +------------------------------+ |
|                                  |
| +------------------------------+ |
| | Merchant Escort              | |
| | Type: Escort                 | |
| | Difficulty: [***--]          | |
| | Reward: 400g, Steel Sword    | |
| | Recommended: Level 3+        | |
| +------------------------------+ |
|                                  |
| +------------------------------+ |
| | [LOCKED] Elite Contract      | |
| | Requires: Crown Rep +25      | |
| +------------------------------+ |
+----------------------------------+
```

**Interactions:**
- Tap quest for detail view
- Swipe left to dismiss/decline
- Filter button shows type/difficulty filters

#### 3. Combat Screen

**Layout:** Landscape preferred, portrait supported

```
+--------------------------------------------------+
| Turn: 3    [Ally Turn]                    [Menu] |
+--------------------------------------------------+
|                                                  |
|    [Enemy 1]    [Enemy 2]    [Enemy 3]           |
|       HP:30        HP:15        HP:45            |
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |              HEX GRID                      |  |
|  |           (10x12 hexes)                    |  |
|  |                                            |  |
|  |    [W]  [R]     vs     [G] [G] [O]         |  |
|  |         [M] [C]                            |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
+--------------------------------------------------+
| [Warrior - YOUR TURN]              HP: 45/45    |
| +--------+ +--------+ +--------+ +--------+     |
| | MOVE   | | ATTACK | | POWER  | | DEFEND |     |
| |        | |        | | ATTACK | |        |     |
| +--------+ +--------+ +--------+ +--------+     |
+--------------------------------------------------+
```

**Interactions:**
- Tap hex to move (highlights valid hexes)
- Tap enemy to target
- Tap ability button to use
- Pinch to zoom grid
- Swipe portrait row to see other characters

#### 4. Adventurer Detail

```
+----------------------------------+
|  [<Back]                [Dismiss]|
+----------------------------------+
|        [Portrait]                |
|     "Grimjaw Ironhide"           |
|     Orc Warrior, Level 4         |
+----------------------------------+
|  STR: 16 (+3)  |  INT: 8 (-1)   |
|  DEX: 12 (+1)  |  WIS: 10 (+0)  |
|  CON: 14 (+2)  |  CHA: 9 (-1)   |
+----------------------------------+
|  HP: 45/45  |  Stamina: 42/42   |
|  Satisfaction: 72 (Content)      |
|  Morale: 85   |  Stress: 15     |
+----------------------------------+
| PERSONALITY                      |
|  Greedy: [####------] 4          |
|  Loyal:  [########--] 8          |
|  Brave:  [#########-] 9          |
|  Cautious: [##--------] 2        |
+----------------------------------+
| TRAITS                           |
|  [Battle Fury] [Scarred Veteran] |
+----------------------------------+
| EQUIPMENT            [Change]    |
|  Weapon: Iron Battleaxe          |
|  Armor: Chain Mail               |
|  Acc 1: Ring of Strength         |
|  Acc 2: (empty)                  |
+----------------------------------+
| ABILITIES                        |
|  Power Attack, Cleave, Second    |
|  Wind, Shield Bash               |
+----------------------------------+
```

### Visual Design System

#### Color Palette

```css
/* Primary Colors */
--parchment-bg: #F4E4BC;      /* Main background */
--parchment-dark: #D4C4A0;    /* Borders, dividers */
--ink-primary: #2C1810;       /* Main text */
--ink-secondary: #5C4030;     /* Secondary text */
--gold-accent: #C9A227;       /* Gold, currency, highlights */

/* Status Colors */
--health-green: #4A7C59;      /* HP bars, positive */
--damage-red: #8B2635;        /* Damage, negative */
--mana-blue: #2E5090;         /* Mana, magic */
--stamina-orange: #C17817;    /* Stamina, physical */

/* Rarity Colors */
--common: #5C4030;
--uncommon: #2E5090;
--rare: #6B2D7B;
--legendary: #C9A227;
```

#### Typography

```css
/* Headers - Stylized medieval */
--font-header: 'Cinzel', 'Times New Roman', serif;
--font-header-size-large: 24pt;
--font-header-size-medium: 18pt;

/* Body - Readable classic */
--font-body: 'Crimson Text', 'Times New Roman', serif;
--font-body-size: 14pt;
--font-body-small: 12pt;

/* Numbers/Stats - Monospace for alignment */
--font-stats: 'Courier Prime', monospace;
--font-stats-size: 14pt;
```

#### Component Specifications

**Buttons (Primary)**
- Size: 88pt width, 44pt height (iOS minimum)
- Background: Parchment gradient with dark border
- Text: Ink primary, 14pt, centered
- States: Normal, Pressed (darker), Disabled (50% opacity)

**Cards (Quest/Character)**
- Background: Parchment with 2pt dark border
- Corner radius: 8pt
- Shadow: 2pt drop shadow, 20% opacity
- Padding: 12pt internal

**Progress Bars**
- Height: 12pt
- Background: Parchment dark
- Fill: Status color
- Border: 1pt ink secondary

---

## Tutorial & Onboarding

### Tutorial Structure (5 segments, ~15 minutes total)

#### Segment 1: Welcome (2 min)
- Narrative introduction: You've inherited a failing guild
- Name your guild
- Meet your first 2 adventurers (pre-generated)
- UI tour: Guild Hall basics

#### Segment 2: First Quest (5 min)
- Forced tutorial quest: "Clear the Basement"
- Learn: Quest acceptance, party selection
- Combat tutorial: Move, Attack, End Turn
- Highlight: INT-based AI ("Notice how Grimjaw rushed in? He's... not the brightest.")
- Victory, loot distribution

#### Segment 3: Recruitment (3 min)
- Tutorial: Visit Recruitment
- Show: Stat comparison, personality traits
- Hire one adventurer (limited choice of 2)
- Explain: Satisfaction system basics

#### Segment 4: Second Quest with AI Focus (4 min)
- Quest: "Escort the Merchant" (forced)
- Introduce: 4-person party
- Highlight: Captain mechanics (assign high-CHA character)
- Show: Captain override in action
- Combat with positioning tutorial (flanking, cover)

#### Segment 5: Freedom (1 min)
- Tutorial complete banner
- Unlock: Full Contract Board
- Hint: "Now it's up to you. Build your legend."
- Optional: Tips reminder toggle

### Contextual Tooltips

First-time triggers for UI elements:

| Element | Trigger | Tooltip |
|---------|---------|---------|
| Low satisfaction icon | First time any adventurer drops below 50 | "This adventurer is unhappy. Rest them or they may leave." |
| Enemy with weakness | First combat with elemental enemy | "Some enemies have weaknesses. Fire hurts trolls!" |
| Captain icon | First combat with captain assigned | "Your captain can issue commands. Tap the command button." |
| Greedy trait | First loot distribution with greedy character | "Greedy adventurers expect extra loot. Decide wisely." |
| Relationship up | First +10 relationship event | "These two are becoming friends! Party them together for bonuses." |

### Skip Tutorial Option

- Available after guild naming
- Warning: "This game has unique AI mechanics. Are you sure?"
- If skipped: Give 4 starting adventurers, 500 gold, unlock all UI

---

## Dialogue System

### Dialogue Data Structure

```json
{
  "dialogueID": "quest_01_intro",
  "speaker": "Mayor Aldric",
  "portrait": "npc_mayor",
  "text": "Thank the gods you've come! Goblins have infested the old mine. Our workers are trapped!",
  "options": [
    {
      "text": "We'll handle it. What's the pay?",
      "personality_check": null,
      "next": "quest_01_payment",
      "effects": []
    },
    {
      "text": "How many goblins are we talking about?",
      "personality_check": null,
      "next": "quest_01_intel",
      "effects": []
    },
    {
      "text": "[Intimidate] Double the pay, or find someone else.",
      "personality_check": {"stat": "cha", "difficulty": 15},
      "next_success": "quest_01_intimidate_success",
      "next_failure": "quest_01_intimidate_fail",
      "effects_success": [{"type": "gold_reward_modifier", "value": 1.5}],
      "effects_failure": [{"type": "reputation_change", "faction": "Crown", "value": -5}]
    }
  ]
}
```

### Dialogue Display

```
+----------------------------------+
|  [Portrait]  Mayor Aldric        |
+----------------------------------+
|                                  |
|  "Thank the gods you've come!    |
|   Goblins have infested the      |
|   old mine. Our workers are      |
|   trapped!"                      |
|                                  |
+----------------------------------+
| > We'll handle it. What's the    |
|   pay?                           |
+----------------------------------+
| > How many goblins?              |
+----------------------------------+
| > [CHA 15] Double the pay, or    |
|   find someone else.             |
+----------------------------------+
```

### Text Speed & Settings

- Default: 30 characters/second
- Fast: 60 characters/second
- Instant: All text appears immediately
- Auto-advance: Off by default, 3-second delay if on

---

## Audio Design

### Music Tracks (MVP: 5-8 tracks)

| Context | Track Name | Mood | BPM |
|---------|------------|------|-----|
| Title Screen | "Legacy of Steel" | Epic, anticipatory | 90 |
| Guild Hall | "Hearth and Home" | Warm, peaceful | 70 |
| Contract Board | "Whispers of Adventure" | Mysterious, inviting | 80 |
| Combat (Normal) | "Clash of Blades" | Tense, rhythmic | 120 |
| Combat (Boss) | "The Final Stand" | Epic, intense | 140 |
| Victory | "Triumphant Return" | Celebratory | 100 |
| Defeat | "Fallen Heroes" | Somber, respectful | 60 |
| Story/Cutscene | "Tales of Old" | Emotional, narrative | 80 |

### Sound Effects

**UI Sounds:**
| Action | Sound | Notes |
|--------|-------|-------|
| Button tap | Soft parchment rustle | 0.1s |
| Screen transition | Page turn | 0.3s |
| Gold received | Coin clink | 0.2s |
| Level up | Triumphant horn + chime | 1.0s |
| Error/invalid | Low thud | 0.2s |
| Notification | Bell chime | 0.5s |

**Combat Sounds:**
| Action | Sound |
|--------|-------|
| Melee hit | Metal clash / flesh impact |
| Melee miss | Whoosh |
| Ranged hit | Arrow thud / bolt impact |
| Ranged miss | Arrow whiz |
| Spell cast | Arcane whoosh + element |
| Heal | Warm chime + sparkle |
| Critical hit | Impact + dramatic sting |
| Death | Thud + gasp |

### Audio Settings

- Master Volume: 0-100%
- Music Volume: 0-100%
- SFX Volume: 0-100%
- Voice (if any): 0-100%
- Mute when backgrounded: Toggle (default on)

---

## Name & Text Generation

### Character Name Generator

```python
NAME_COMPONENTS = {
    'Human': {
        'first_male': ['Aldric', 'Bram', 'Cedric', 'Dorian', 'Edmund', 'Felix', 'Garrett', 'Harold'],
        'first_female': ['Alara', 'Brianna', 'Celeste', 'Diana', 'Elena', 'Fiona', 'Gwendolyn', 'Helena'],
        'surname': ['Blackwood', 'Ironforge', 'Stormwind', 'Silverhand', 'Oakenshield', 'Ravencrest']
    },
    'Elf': {
        'first_male': ['Aelindor', 'Caelum', 'Eryndor', 'Faelar', 'Galadrim', 'Lorien', 'Thalion', 'Vaeril'],
        'first_female': ['Aelindra', 'Caelia', 'Elowen', 'Faelara', 'Galadriel', 'Lirael', 'Thalindra', 'Vaelora'],
        'surname': ['Moonwhisper', 'Starweaver', 'Leafshadow', 'Dawnstrider', 'Nightbloom', 'Silvervine']
    },
    'Dwarf': {
        'first_male': ['Balin', 'Dain', 'Gimli', 'Thorin', 'Brokk', 'Durin', 'Morgrim', 'Thrain'],
        'first_female': ['Brynhild', 'Dagny', 'Freya', 'Hilda', 'Ingrid', 'Sigrid', 'Thora', 'Vigdis'],
        'surname': ['Ironbeard', 'Stonefist', 'Deepdelve', 'Goldvein', 'Hammerfall', 'Anvilthorn']
    },
    'Orc': {
        'first_male': ['Grokk', 'Thrak', 'Urgak', 'Mogul', 'Nazgrim', 'Ragnar', 'Skullcrusher', 'Warbringer'],
        'first_female': ['Grukka', 'Shara', 'Ursa', 'Mogra', 'Nazra', 'Ragnara', 'Skullsplitter', 'Warsister'],
        'surname': ['Bloodfang', 'Ironhide', 'Skullsplitter', 'Bonecrusher', 'Ashhand', 'Doomhammer']
    }
}

def generate_name(race, gender=None):
    if gender is None:
        gender = random.choice(['male', 'female'])

    components = NAME_COMPONENTS[race]
    first = random.choice(components[f'first_{gender}'])
    surname = random.choice(components['surname'])

    return f"{first} {surname}"
```

### Quest Title Generator

```python
QUEST_TEMPLATES = {
    'extermination': [
        "Clear the {location} of {enemy_plural}",
        "The {enemy} Menace",
        "{enemy} Infestation in {location}",
        "Hunt the {enemy_plural}"
    ],
    'rescue': [
        "Save the {victim} from {location}",
        "Rescue Mission: {location}",
        "The Missing {victim}",
        "Prisoners of {enemy_plural}"
    ],
    'escort': [
        "Escort to {destination}",
        "Guard the {cargo}",
        "Safe Passage to {destination}",
        "The {cargo} Delivery"
    ]
}

LOCATIONS = ['Old Mine', 'Darkwood Forest', 'Abandoned Keep', 'Merchant Road', 'Swamp Ruins']
ENEMIES = ['Goblin', 'Bandit', 'Orc', 'Undead', 'Troll']
VICTIMS = ['Merchant', 'Noble', 'Villagers', 'Scholars', 'Prisoners']
```

---

## Accessibility Features

### Visual Accessibility

| Feature | Implementation |
|---------|----------------|
| Text size | 3 options: Normal, Large (+20%), Extra Large (+40%) |
| Color blind modes | Deuteranopia, Protanopia, Tritanopia filters |
| High contrast | Toggle for increased contrast ratios |
| Screen reader | VoiceOver support (iOS native) |
| Button size | All interactive elements minimum 44x44pt |

### Motor Accessibility

| Feature | Implementation |
|---------|----------------|
| One-handed mode | All UI reachable with thumb in portrait |
| Hold instead of tap | Optional for long-press actions |
| Auto-battle | Toggle to let AI control all party members |
| Slow mode | Combat animations at 50% speed |
| No time pressure | All timers optional/extendable |

### Cognitive Accessibility

| Feature | Implementation |
|---------|----------------|
| Tutorial replay | Accessible from settings anytime |
| Tooltip toggle | Always-on tooltips option |
| Simple mode | Hides advanced stats, shows only essentials |
| Quest log | Full history of active/completed quests |
| Combat log | Scrollable text log of all actions |

### Audio Accessibility

| Feature | Implementation |
|---------|----------------|
| Subtitles | All dialogue displayed as text |
| Visual cues | Sound events have visual indicators |
| Haptic feedback | Optional vibration for key events |

---

## Error Handling & Edge Cases

### Save System Edge Cases

| Scenario | Handling |
|----------|----------|
| App killed during save | Auto-save uses atomic write (temp file, then rename) |
| Corrupted save detected | Offer to load backup (keeps last 3 saves) |
| Cloud sync conflict | Show comparison, let player choose |
| Storage full | Alert before save attempt, offer to clear cache |

### Combat Edge Cases

| Scenario | Handling |
|----------|----------|
| All party members dead | Quest fails, return to guild hall, injuries applied |
| All enemies flee | Quest success (partial), reduced rewards |
| Ally kills ally (confusion) | Counts as death, relationship -50 between killer/victim's friends |
| Combat infinite loop | After 50 turns, force retreat option |
| Disconnection mid-combat | Auto-save at turn start, resume on reconnect |

### Recruitment Edge Cases

| Scenario | Handling |
|----------|----------|
| Guild full | "Barracks full" message, prompt upgrade |
| No gold for hiring | "Insufficient funds" message, cannot proceed |
| Last adventurer | Cannot dismiss, must have minimum 1 |
| Recruit pool empty | Pool refreshes weekly, show countdown |

### Quest Edge Cases

| Scenario | Handling |
|----------|----------|
| All quests too hard | Always offer 1 easy quest (level-appropriate) |
| Quest expired | Remove from board, show notification |
| Party too small for quest | Warning, allow anyway with difficulty note |
| Same quest attempted twice | Different enemy placement, same structure |

---

## Analytics & Telemetry

### Data Collection (GDPR/CCPA Compliant)

**Collected (Anonymized):**
- Session length
- Quest completion/failure rates
- Character class/race distribution
- Combat duration
- Feature engagement (screens visited)
- Tutorial completion rate
- Crash reports

**NOT Collected:**
- Player names
- Device identifiers (without consent)
- Location data
- Personal information

### Key Metrics to Track

| Metric | Target | Purpose |
|--------|--------|---------|
| Tutorial completion | >80% | Onboarding quality |
| Day 1 retention | >50% | First impression |
| Day 7 retention | >30% | Core loop engagement |
| Day 30 retention | >15% | Long-term appeal |
| Average session length | 15-25 min | Pacing validation |
| Quests per session | 1-3 | Content pacing |
| Class distribution | ~25% each | Balance check |
| Combat win rate | 60-70% | Difficulty tuning |
| Desertion rate | <5% | Satisfaction balance |
| IAP conversion (if F2P) | >3% | Monetization |

### Analytics Implementation

```swift
// iOS Analytics (using Firebase or similar)

func logEvent(_ event: AnalyticsEvent) {
    let params: [String: Any] = [
        "timestamp": Date().timeIntervalSince1970,
        "session_id": currentSessionID,
        "game_day": gameState.currentDay,
        "guild_level": gameState.guildLevel
    ]

    Analytics.logEvent(event.name, parameters: params.merging(event.params))
}

enum AnalyticsEvent {
    case questStarted(questType: String, difficulty: Int)
    case questCompleted(questType: String, success: Bool, duration: Int)
    case combatEnded(turns: Int, partyDeaths: Int, enemiesKilled: Int)
    case adventurerRecruited(race: String, class: String)
    case adventurerDeserted(satisfaction: Int, daysSinceHire: Int)
    case tutorialStep(step: Int, completed: Bool)
    case sessionStart
    case sessionEnd(duration: Int)
}
```

---

## Localization Framework

### Supported Languages (MVP)

1. **English** (Base)
2. **Spanish** (Large iOS market)
3. **French** (Large iOS market)
4. **German** (Strong strategy game market)
5. **Portuguese (BR)** (Growing market)

### String Management

```json
// en.json
{
  "ui": {
    "guild_hall": "Guild Hall",
    "contract_board": "Contract Board",
    "barracks": "Barracks",
    "recruit": "Recruit",
    "gold_display": "{amount}g"
  },
  "combat": {
    "your_turn": "Your Turn",
    "enemy_turn": "Enemy Turn",
    "attack": "Attack",
    "move": "Move",
    "defend": "Defend"
  },
  "messages": {
    "quest_success": "Quest Complete!",
    "quest_failed": "Quest Failed",
    "adventurer_deserted": "{name} has left the guild.",
    "not_enough_gold": "Not enough gold ({required}g required)"
  }
}
```

### Localization Guidelines

- Use ICU message format for plurals/gender
- Avoid concatenated strings
- Leave 30% extra space for German (longer words)
- Right-to-left support structure (post-MVP for Arabic/Hebrew)
- Date/number formatting via iOS locale APIs

### Text Placeholder System

```python
def localize(key, **kwargs):
    """
    Example: localize("messages.adventurer_deserted", name="Grimjaw")
    Returns: "Grimjaw has left the guild."
    """
    template = get_localized_string(key, current_locale)
    return template.format(**kwargs)
```

---

## Appendix: Data File Templates

### Character Save Schema

```json
{
  "$schema": "character_v1",
  "id": "uuid",
  "name": "string",
  "race": "Human|Elf|Dwarf|Orc",
  "class": "Warrior|Rogue|Mage|Cleric",
  "level": 1,
  "xp": 0,
  "stats": {
    "str": 10, "dex": 10, "con": 10,
    "int": 10, "wis": 10, "cha": 10
  },
  "current_hp": 10,
  "max_hp": 10,
  "satisfaction": 50,
  "stress": 0,
  "morale": 50,
  "personality": {
    "greedy": 5, "loyal": 5, "brave": 5, "cautious": 5
  },
  "traits": ["trait_id"],
  "abilities": ["ability_id"],
  "equipment": {
    "weapon": "item_id|null",
    "armor": "item_id|null",
    "accessory1": "item_id|null",
    "accessory2": "item_id|null"
  },
  "relationships": {
    "character_id": 0
  },
  "quest_history": {
    "total": 0, "successes": 0, "failures": 0
  },
  "days_since_rest": 0,
  "hire_date": 1
}
```

### Quest Definition Schema

```json
{
  "$schema": "quest_v1",
  "id": "quest_tutorial_01",
  "title": "Clear the Basement",
  "type": "extermination",
  "tier": "basic",
  "description": "Rats have infested the guild cellar. Clear them out!",
  "recommended_level": 1,
  "rewards": {
    "gold": 100,
    "xp": 50,
    "items": ["item_minor_healing_potion"],
    "reputation": {}
  },
  "encounters": [
    {
      "type": "combat",
      "enemies": ["enemy_giant_rat", "enemy_giant_rat", "enemy_giant_rat"],
      "terrain": "dungeon_small"
    },
    {
      "type": "skill_challenge",
      "challenge_id": "challenge_locked_door"
    },
    {
      "type": "combat",
      "enemies": ["enemy_giant_rat", "enemy_giant_rat", "enemy_rat_king"],
      "terrain": "dungeon_small",
      "is_boss": true
    }
  ],
  "dialogue": {
    "intro": "dialogue_quest_tutorial_01_intro",
    "success": "dialogue_quest_tutorial_01_success",
    "failure": "dialogue_quest_tutorial_01_failure"
  }
}
```

---

## Document Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Initial | Complete supplemental specification |

---

**End of Supplemental Specification**

*This document should be read alongside the Core GDD, Technical Spec, Content Spec, and MVP Roadmap for complete project specification.*
