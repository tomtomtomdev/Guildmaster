# Guild Master - Battle System Specification

*Comprehensive specification for turn-based combat, text commentary, kill announcer, and victory/defeat flows.*

---

## Table of Contents
1. [Battle Flow Overview](#battle-flow-overview)
2. [Combat Commentary System](#combat-commentary-system)
3. [Kill & Streak Announcer](#kill--streak-announcer)
4. [Victory Screen](#victory-screen)
5. [Defeat Screen](#defeat-screen)
6. [Combat Log Implementation](#combat-log-implementation)

---

## Battle Flow Overview

### Combat Phases

```
[QUEST START]
       |
       v
+------------------+
| PRE-COMBAT PHASE |  <- Party deployment, terrain reveal
+------------------+
       |
       v
+------------------+
| INITIATIVE ROLL  |  <- Determine turn order
+------------------+
       |
       v
+------------------+
| COMBAT ROUNDS    |  <- Main loop
| (Turn by Turn)   |
+------------------+
       |
       v
+------------------+    +------------------+
| VICTORY CHECK    |--->| VICTORY SCREEN   |
+------------------+    +------------------+
       |
       v
+------------------+    +------------------+
| DEFEAT CHECK     |--->| DEFEAT SCREEN    |
+------------------+    +------------------+
       |
       v
+------------------+
| NEXT ENCOUNTER   |  <- If more encounters in quest
+------------------+
```

### Turn Structure

Each character's turn consists of:

```
1. START OF TURN
   - Apply status effects (poison, burn, regen)
   - Commentary: Status effect damage/healing

2. MOVEMENT PHASE
   - Character can move up to speed in hexes
   - Commentary: Movement descriptions

3. ACTION PHASE
   - Attack, Ability, Item, or Defend
   - Commentary: Action descriptions, hit/miss, damage

4. BONUS ACTION (if available)
   - Quick abilities, some items
   - Commentary: Bonus action descriptions

5. END OF TURN
   - Trigger reactions from enemies
   - Commentary: Reaction descriptions
   - Update turn order display
```

---

## Combat Commentary System

### Commentary Architecture

The commentary system provides real-time narrative feedback in a scrolling text log during combat.

```python
class CombatCommentary:
    def __init__(self):
        self.log = []
        self.templates = load_commentary_templates()

    def add_entry(self, event_type, **context):
        """
        Generate and add a commentary line based on event type.
        """
        template_pool = self.templates[event_type]

        # Select template based on context (critical, personality, etc.)
        template = self.select_template(template_pool, context)

        # Fill in the template
        text = template.format(**context)

        # Add styling info
        entry = {
            'text': text,
            'type': event_type,
            'timestamp': get_combat_timestamp(),
            'style': get_style_for_event(event_type)
        }

        self.log.append(entry)
        self.display_entry(entry)

    def select_template(self, pool, context):
        """
        Select appropriate template based on context:
        - Critical hits get dramatic templates
        - Low-INT characters get comedic templates
        - High-CHA captains get heroic templates
        """
        if context.get('is_critical'):
            return random.choice(pool['critical'])
        elif context.get('is_miss'):
            return random.choice(pool['miss'])
        elif context.get('actor_int', 10) <= 8:
            return random.choice(pool.get('low_int', pool['normal']))
        else:
            return random.choice(pool['normal'])
```

### Commentary Templates by Event Type

#### Attack Events

```json
{
  "melee_attack": {
    "normal": [
      "{attacker} swings at {target} with {weapon}!",
      "{attacker} strikes at {target}!",
      "{attacker} attacks {target} with a powerful blow!",
      "{attacker} lunges toward {target}!"
    ],
    "critical": [
      "{attacker} lands a DEVASTATING blow on {target}!",
      "CRITICAL HIT! {attacker} finds {target}'s weak point!",
      "{attacker} strikes TRUE! A perfect hit on {target}!",
      "The crowd would roar! {attacker} CRUSHES {target}!"
    ],
    "miss": [
      "{attacker} swings wide, missing {target} completely!",
      "{target} narrowly dodges {attacker}'s attack!",
      "{attacker}'s blow glances off {target}'s armor!",
      "A clumsy swing! {attacker} hits nothing but air!"
    ],
    "low_int": [
      "{attacker} charges in recklessly at {target}!",
      "Without thinking, {attacker} swings wildly at {target}!",
      "{attacker} attacks {target}... was that the plan?"
    ]
  },
  "ranged_attack": {
    "normal": [
      "{attacker} looses an arrow at {target}!",
      "{attacker} takes aim and fires at {target}!",
      "A bolt flies from {attacker} toward {target}!",
      "{attacker} draws and releases in one smooth motion!"
    ],
    "critical": [
      "BULLSEYE! {attacker}'s shot pierces {target}'s defenses!",
      "{attacker}'s arrow finds its mark PERFECTLY!",
      "An impossible shot! {attacker} strikes {target} dead center!",
      "The arrow sings through the air - CRITICAL HIT on {target}!"
    ],
    "miss": [
      "{attacker}'s arrow flies harmlessly past {target}!",
      "The shot goes wide! {attacker} misses {target}!",
      "{target} sidesteps {attacker}'s projectile!",
      "{attacker}'s aim falters - the shot misses!"
    ]
  }
}
```

#### Damage Events

```json
{
  "damage_dealt": {
    "light": [
      "{target} takes {damage} damage. A scratch!",
      "{damage} damage to {target}. Just a flesh wound.",
      "{target} winces. {damage} damage dealt."
    ],
    "moderate": [
      "{target} staggers from {damage} damage!",
      "A solid hit! {damage} damage to {target}!",
      "{target} grunts in pain. {damage} damage!"
    ],
    "heavy": [
      "{target} REELS from {damage} damage!",
      "DEVASTATING! {damage} damage tears into {target}!",
      "{target} is badly wounded! {damage} damage!"
    ],
    "massive": [
      "CRUSHING BLOW! {damage} damage nearly fells {target}!",
      "{target} is BROKEN by {damage} points of damage!",
      "The blow echoes! {damage} damage - {target} barely stands!"
    ]
  }
}
```

#### Ability Events

```json
{
  "ability_used": {
    "warrior": {
      "Power Attack": [
        "{actor} roars and unleashes a POWER ATTACK!",
        "With tremendous force, {actor} swings!"
      ],
      "Cleave": [
        "{actor} cleaves through the enemy line!",
        "The axe arcs through multiple foes!"
      ],
      "Second Wind": [
        "{actor} catches their breath and recovers!",
        "Determination fills {actor} - Second Wind activated!"
      ],
      "Whirlwind": [
        "{actor} spins in a deadly WHIRLWIND!",
        "Steel death surrounds {actor} - Whirlwind!"
      ]
    },
    "rogue": {
      "Sneak Attack": [
        "{actor} strikes from the shadows! SNEAK ATTACK!",
        "Unseen until too late - {actor}'s blade finds flesh!"
      ],
      "Backstab": [
        "{actor} materializes behind {target} - BACKSTAB!",
        "From nowhere, a blade in the back!"
      ],
      "Smoke Bomb": [
        "{actor} throws down a smoke bomb!",
        "Smoke billows - {actor} vanishes!"
      ]
    },
    "mage": {
      "Magic Missile": [
        "Arcane bolts streak from {actor}'s fingertips!",
        "{actor} conjures MAGIC MISSILES!"
      ],
      "Fireball": [
        "{actor} hurls a massive FIREBALL!",
        "Fire and fury! {actor} unleashes inferno!",
        "The air ignites - FIREBALL incoming!"
      ],
      "Haste": [
        "{actor} weaves time magic - HASTE on {target}!",
        "Reality bends! {target} moves with impossible speed!"
      ]
    },
    "cleric": {
      "Cure Wounds": [
        "Divine light flows from {actor} to {target}!",
        "{actor}'s healing prayer mends {target}'s wounds!"
      ],
      "Turn Undead": [
        "{actor} raises their holy symbol - TURN UNDEAD!",
        "By the light! The undead recoil in terror!"
      ],
      "Resurrection": [
        "{actor} calls upon the divine - {target} RISES!",
        "A miracle! {target} returns from death's door!"
      ]
    }
  }
}
```

#### Healing Events

```json
{
  "healing": {
    "normal": [
      "{target} is healed for {amount} HP!",
      "Wounds close! {target} recovers {amount} HP!",
      "{amount} HP restored to {target}!"
    ],
    "critical_heal": [
      "The healing surges! {target} recovers {amount} HP!",
      "Divine favor! {target} is restored for {amount} HP!",
      "Maximum healing! {target} gains {amount} HP!"
    ],
    "potion": [
      "{actor} drinks a healing potion - {amount} HP restored!",
      "The potion takes effect! {actor} heals {amount}!",
      "Refreshing! {actor} recovers {amount} HP from the potion!"
    ]
  }
}
```

#### Status Effect Events

```json
{
  "status_applied": {
    "poison": [
      "{target} is POISONED!",
      "Venom courses through {target}'s veins!",
      "The poison takes hold - {target} is afflicted!"
    ],
    "burn": [
      "{target} catches FIRE!",
      "Flames lick at {target}!",
      "{target} burns!"
    ],
    "stun": [
      "{target} is STUNNED!",
      "The blow leaves {target} dazed!",
      "{target} can't act - Stunned!"
    ],
    "blessed": [
      "Divine blessing empowers {target}!",
      "Holy light surrounds {target}!",
      "{target} is blessed!"
    ]
  },
  "status_tick": {
    "poison": [
      "Poison saps {target} - {damage} damage!",
      "The venom burns! {target} takes {damage}!",
      "{target} suffers {damage} poison damage!"
    ],
    "burn": [
      "Flames sear {target} for {damage}!",
      "{target} burns for {damage} damage!",
      "The fire consumes {target} - {damage} damage!"
    ],
    "regen": [
      "{target} regenerates {amount} HP!",
      "Wounds knit closed - {target} heals {amount}!",
      "{target} recovers {amount} HP from regeneration!"
    ]
  }
}
```

#### Movement Events

```json
{
  "movement": {
    "normal": [
      "{actor} moves to a new position.",
      "{actor} repositions on the battlefield.",
      "{actor} advances."
    ],
    "tactical": [
      "{actor} takes cover behind {terrain}!",
      "{actor} flanks {target}!",
      "{actor} moves to high ground!",
      "{actor} retreats to safety!"
    ],
    "low_int": [
      "{actor} wanders into danger...",
      "{actor} moves... somewhere.",
      "Was that intentional? {actor} repositions oddly."
    ]
  }
}
```

#### Captain Command Events

```json
{
  "captain_command": {
    "focus_fire": [
      "Captain {captain}: \"Focus fire on {target}!\"",
      "{captain} commands: \"Bring down {target}!\"",
      "\"All attacks on {target}!\" orders {captain}."
    ],
    "defensive_formation": [
      "Captain {captain}: \"Defensive positions!\"",
      "{captain} orders a defensive stance!",
      "\"Hold the line!\" commands {captain}."
    ],
    "retreat": [
      "Captain {captain}: \"Fall back!\"",
      "{captain} calls for retreat!",
      "\"We're pulling out!\" shouts {captain}."
    ],
    "override": [
      "{captain} overrides {target}'s decision!",
      "\"Not like that, {target}!\" - {captain} intervenes!",
      "{captain}'s leadership guides {target} to a better choice!"
    ],
    "ignored": [
      "{target} ignores {captain}'s orders!",
      "{captain}'s command falls on deaf ears!",
      "Defiance! {target} acts independently!"
    ]
  }
}
```

### Commentary Display

```
+--------------------------------------------------+
|                 COMBAT LOG                        |
+--------------------------------------------------+
| [Turn 3]                                          |
| Grimjaw swings at Goblin Scout with Iron Axe!     |
| A solid hit! 12 damage to Goblin Scout!           |
|                                                   |
| Elara weaves time magic - HASTE on Grimjaw!       |
| Grimjaw moves with impossible speed!              |
|                                                   |
| Goblin Scout takes aim and fires at Thornwick!    |
| The shot goes wide! Goblin Scout misses!          |
|                                                   |
| Captain Aldric: "Focus fire on the Shaman!"       |
| The party coordinates their assault!              |
|                                                   |
| [KILL] Grimjaw executes Goblin Scout!             |
+--------------------------------------------------+
| [Scroll for more]                                 |
+--------------------------------------------------+
```

### Commentary Style Classes

```css
.commentary-normal {
    color: var(--ink-primary);
}

.commentary-damage-light {
    color: var(--damage-red);
    opacity: 0.7;
}

.commentary-damage-heavy {
    color: var(--damage-red);
    font-weight: bold;
}

.commentary-critical {
    color: var(--gold-accent);
    font-weight: bold;
    text-transform: uppercase;
}

.commentary-heal {
    color: var(--health-green);
}

.commentary-kill {
    color: var(--gold-accent);
    font-weight: bold;
    border-left: 3px solid var(--gold-accent);
    padding-left: 8px;
}

.commentary-captain {
    color: var(--ink-primary);
    font-style: italic;
    background: rgba(201, 162, 39, 0.1);
}

.commentary-death {
    color: var(--damage-red);
    font-weight: bold;
    background: rgba(139, 38, 53, 0.1);
}
```

---

## Kill & Streak Announcer

### Kill Event System

When any character lands a killing blow, the kill announcer triggers.

```python
class KillAnnouncer:
    def __init__(self):
        self.kill_counts = {}  # character_id: kills_this_combat
        self.streaks = {}      # character_id: current_streak
        self.multi_kills = {}  # character_id: kills_this_turn

    def register_kill(self, killer, victim, combat_context):
        """
        Called when a character kills an enemy.
        """
        # Update counts
        self.kill_counts[killer.id] = self.kill_counts.get(killer.id, 0) + 1
        self.streaks[killer.id] = self.streaks.get(killer.id, 0) + 1
        self.multi_kills[killer.id] = self.multi_kills.get(killer.id, 0) + 1

        # Determine announcement type
        announcement = self.get_announcement(killer, victim, combat_context)

        return announcement

    def end_turn(self, character_id):
        """
        Reset multi-kill counter at end of character's turn.
        Check for multi-kill announcement.
        """
        multi_count = self.multi_kills.get(character_id, 0)
        if multi_count > 1:
            self.announce_multi_kill(character_id, multi_count)
        self.multi_kills[character_id] = 0

    def break_streak(self, character_id):
        """
        Called when character dies or combat ends.
        """
        self.streaks[character_id] = 0

    def get_announcement(self, killer, victim, context):
        kills = self.kill_counts[killer.id]
        streak = self.streaks[killer.id]
        is_boss = victim.is_boss

        # Build announcement
        announcement = {
            'type': 'kill',
            'killer': killer,
            'victim': victim,
            'kill_count': kills,
            'streak': streak,
            'templates': self.select_templates(kills, streak, is_boss, killer)
        }

        return announcement
```

### Kill Announcement Templates

#### Standard Kill Announcements

```json
{
  "kill_standard": {
    "normal": [
      "{killer} defeats {victim}!",
      "{killer} slays {victim}!",
      "{victim} falls to {killer}!",
      "{killer} finishes off {victim}!"
    ],
    "execution": [
      "{killer} EXECUTES {victim}!",
      "No mercy! {killer} ends {victim}!",
      "{killer} delivers the killing blow to {victim}!"
    ],
    "overkill": [
      "{killer} OBLITERATES {victim}!",
      "Overkill! {killer} destroys {victim}!",
      "{victim} is ANNIHILATED by {killer}!"
    ]
  }
}
```

#### Kill Streak Announcements

| Streak | Title | Announcement |
|--------|-------|--------------|
| 2 | Double Kill | "{killer} scores a DOUBLE KILL!" |
| 3 | Killing Spree | "{killer} is on a KILLING SPREE!" |
| 4 | Dominating | "{killer} is DOMINATING!" |
| 5 | Rampage | "{killer} is on a RAMPAGE!" |
| 6 | Unstoppable | "{killer} is UNSTOPPABLE!" |
| 7 | Godlike | "{killer} is GODLIKE!" |
| 8+ | Legendary | "{killer} has achieved LEGENDARY status!" |

```json
{
  "kill_streak": {
    "2": {
      "title": "DOUBLE KILL",
      "templates": [
        "{killer} scores a DOUBLE KILL!",
        "Two down! {killer} is heating up!",
        "{killer} with the double!"
      ]
    },
    "3": {
      "title": "KILLING SPREE",
      "templates": [
        "{killer} is on a KILLING SPREE!",
        "Three kills! {killer} can't be stopped!",
        "KILLING SPREE! {killer} dominates!"
      ]
    },
    "4": {
      "title": "DOMINATING",
      "templates": [
        "{killer} is DOMINATING the battlefield!",
        "Four kills! {killer} DOMINATES!",
        "DOMINATING! Who can stop {killer}?"
      ]
    },
    "5": {
      "title": "RAMPAGE",
      "templates": [
        "{killer} is on a RAMPAGE!",
        "Five kills! {killer} goes on a RAMPAGE!",
        "RAMPAGE! {killer} tears through the enemy!"
      ]
    },
    "6": {
      "title": "UNSTOPPABLE",
      "templates": [
        "{killer} is UNSTOPPABLE!",
        "Six kills! Nothing can stop {killer}!",
        "UNSTOPPABLE! {killer} is a force of nature!"
      ]
    },
    "7": {
      "title": "GODLIKE",
      "templates": [
        "{killer} is GODLIKE!",
        "Seven kills! {killer} achieves GODLIKE status!",
        "GODLIKE! {killer} transcends mortal limits!"
      ]
    },
    "8": {
      "title": "LEGENDARY",
      "templates": [
        "{killer} has become LEGENDARY!",
        "Eight kills and beyond! {killer} is LEGENDARY!",
        "LEGENDARY! Bards will sing of {killer}'s deeds!"
      ]
    }
  }
}
```

#### Multi-Kill Announcements (Same Turn)

| Count | Title | Announcement |
|-------|-------|--------------|
| 2 | Double Kill | "DOUBLE KILL! {killer} drops two in one turn!" |
| 3 | Triple Kill | "TRIPLE KILL! {killer} devastates!" |
| 4 | Quadra Kill | "QUADRA KILL! {killer} is unstoppable!" |
| 5+ | PENTAKILL | "PENTAKILL! {killer} wipes the enemy!" |

```json
{
  "multi_kill": {
    "2": {
      "title": "DOUBLE KILL",
      "templates": [
        "DOUBLE KILL! {killer} drops two in one turn!",
        "{killer} with the DOUBLE! Two fall at once!",
        "Two kills, one turn! {killer} is efficient!"
      ]
    },
    "3": {
      "title": "TRIPLE KILL",
      "templates": [
        "TRIPLE KILL! {killer} is a whirlwind of death!",
        "Three in one turn! {killer} DEVASTATES!",
        "TRIPLE! {killer} cuts through like a scythe!"
      ]
    },
    "4": {
      "title": "QUADRA KILL",
      "templates": [
        "QUADRA KILL! {killer} is beyond mortal!",
        "Four kills! QUADRA for {killer}!",
        "Impossible! {killer} scores a QUADRA!"
      ]
    },
    "5": {
      "title": "PENTAKILL",
      "templates": [
        "PENTAKILL! {killer} single-handedly wins!",
        "TOTAL ANNIHILATION! {killer} with the PENTA!",
        "LEGENDARY PENTAKILL from {killer}!"
      ]
    }
  }
}
```

#### Boss Kill Announcements

```json
{
  "boss_kill": {
    "templates": [
      "{killer} lands the FINISHING BLOW on {boss}!",
      "THE BEAST FALLS! {killer} slays {boss}!",
      "BOSS DEFEATED! {killer} claims victory over {boss}!",
      "Against all odds, {killer} brings down {boss}!"
    ],
    "team_effort": [
      "The party triumphs! {boss} is defeated!",
      "Together they stand! {boss} falls at last!",
      "Victory! {boss} could not withstand the guild's might!"
    ]
  }
}
```

#### First Blood

```json
{
  "first_blood": {
    "templates": [
      "FIRST BLOOD! {killer} draws first!",
      "{killer} scores FIRST BLOOD on {victim}!",
      "The battle's first casualty: {victim} falls to {killer}!",
      "FIRST BLOOD to the guild! {killer} opens the scoring!"
    ]
  }
}
```

### Kill Announcer UI Display

```
+--------------------------------------------------+
|                                                  |
|              [PORTRAIT: Grimjaw]                 |
|                                                  |
|            ===== KILLING SPREE =====             |
|                                                  |
|       "Grimjaw is on a KILLING SPREE!"           |
|                                                  |
|                 3 KILLS                          |
|                                                  |
+--------------------------------------------------+
```

The announcement appears as an overlay, stays for 2 seconds, then fades.

### Kill Announcer Audio

| Event | Sound |
|-------|-------|
| Standard Kill | Blade impact + death cry |
| Double Kill | Epic horn short |
| Triple Kill | Epic horn + chime |
| Killing Spree | Dramatic sting |
| Rampage+ | Full epic fanfare |
| Boss Kill | Victory horn + orchestral hit |
| First Blood | Dramatic drum hit |

---

## Victory Screen

### Victory Trigger Conditions

Combat ends in victory when:
1. All enemies are dead/fled
2. Primary objective is completed (escort reached destination, item retrieved, etc.)

### Victory Screen Flow

```
[Final Kill]
    |
    v
[Kill Announcement] (2s)
    |
    v
[Screen Transition: Fade to parchment]
    |
    v
+----------------------------------+
|        === VICTORY ===           |  <- Header with fanfare
+----------------------------------+
    |
    v
+----------------------------------+
|     COMBAT SUMMARY (3s reveal)   |  <- Stats animate in
+----------------------------------+
    |
    v
+----------------------------------+
|     MVP ANNOUNCEMENT (2s)        |  <- Highlight top performer
+----------------------------------+
    |
    v
+----------------------------------+
|     LOOT & REWARDS (reveal)      |  <- Items appear one by one
+----------------------------------+
    |
    v
+----------------------------------+
|     XP & LEVEL UPS (reveal)      |  <- XP bars fill
+----------------------------------+
    |
    v
[Continue Button]
    |
    v
[Debrief Screen / Next Encounter]
```

### Victory Screen Layout

```
+--------------------------------------------------+
|                                                  |
|              ===== VICTORY =====                 |
|                                                  |
+--------------------------------------------------+
|  COMBAT SUMMARY                                  |
+--------------------------------------------------+
|                                                  |
|  Duration: 8 turns (4:32)                        |
|  Enemies Slain: 6                                |
|  Damage Dealt: 342                               |
|  Damage Taken: 87                                |
|  Healing Done: 45                                |
|                                                  |
+--------------------------------------------------+
|  === MVP: GRIMJAW IRONHIDE ===                   |
|  "Unstoppable" - 4 Kills, 156 Damage             |
+--------------------------------------------------+
|  PARTY PERFORMANCE                               |
+--------------------------------------------------+
|  [Portrait] Grimjaw    4 kills  156 dmg  0 heal  |
|  [Portrait] Elara      1 kill   89 dmg   0 heal  |
|  [Portrait] Thornwick  1 kill   67 dmg   45 heal |
|  [Portrait] Shadow     0 kills  30 dmg   0 heal  |
+--------------------------------------------------+
|  REWARDS                                         |
+--------------------------------------------------+
|  Gold: +250g                                     |
|  Items: [Iron Sword] [Health Potion x2]          |
|  XP: +150 each                                   |
+--------------------------------------------------+
|                                                  |
|               [ CONTINUE ]                       |
|                                                  |
+--------------------------------------------------+
```

### MVP Selection Algorithm

```python
def select_mvp(party, combat_stats):
    """
    MVP is selected based on weighted contribution score.
    """
    scores = {}

    for character in party:
        stats = combat_stats[character.id]

        score = (
            stats['kills'] * 100 +
            stats['damage_dealt'] * 1 +
            stats['healing_done'] * 2 +
            stats['damage_prevented'] * 1.5 +  # Tanking
            stats['buffs_applied'] * 20 -
            stats['times_downed'] * 50 +
            stats['kill_streak_max'] * 30
        )

        # Bonus for finishing blow on boss
        if stats['boss_kill']:
            score += 200

        scores[character.id] = score

    mvp_id = max(scores, key=scores.get)
    return get_character(mvp_id)
```

### MVP Titles

Based on performance type:

| Condition | Title |
|-----------|-------|
| Highest kills | "Slayer" |
| Highest damage | "Destroyer" |
| Highest healing | "Lifebringer" |
| Highest damage taken (survived) | "Unbreakable" |
| Perfect (no damage taken) | "Untouchable" |
| Boss kill | "Giant Slayer" |
| 5+ kill streak | "Unstoppable" |
| Multi-kill (3+) | "Whirlwind" |
| Most abilities used | "Virtuoso" |

### Victory Quotes

Displayed below MVP announcement, based on party personality/class:

```json
{
  "victory_quotes": {
    "warrior": [
      "\"A good fight. I needed that.\"",
      "\"They should have brought more.\"",
      "\"My blade thirsts for more!\""
    ],
    "rogue": [
      "\"Too easy. Where's the challenge?\"",
      "\"They never saw me coming.\"",
      "\"I'll be taking their valuables now.\""
    ],
    "mage": [
      "\"The arcane arts triumph again.\"",
      "\"Fascinating combat data to analyze.\"",
      "\"Magic conquers all.\""
    ],
    "cleric": [
      "\"The light guided our victory.\"",
      "\"We prevail through faith.\"",
      "\"None shall fall while I stand.\""
    ],
    "personality_brave": [
      "\"Is that all they had?\"",
      "\"Bring me a real challenge!\""
    ],
    "personality_cautious": [
      "\"We're all still breathing. Good.\"",
      "\"That could have gone worse.\""
    ]
  }
}
```

### Victory Conditions - Special Cases

#### Flawless Victory
No party member dropped below 50% HP.

```
+--------------------------------------------------+
|              ===== VICTORY =====                 |
|              ~ FLAWLESS ~                        |
|                                                  |
|  "Not a scratch on us!"                          |
|                                                  |
|  BONUS: +50% Gold, +25% XP                       |
+--------------------------------------------------+
```

#### Pyrrhic Victory
All party members below 25% HP at end.

```
+--------------------------------------------------+
|              ===== VICTORY =====                 |
|              (Barely...)                         |
|                                                  |
|  "We won... but at what cost?"                   |
|                                                  |
|  All party members: Stress +10                   |
+--------------------------------------------------+
```

#### Speed Victory
Combat ended in 3 turns or less.

```
+--------------------------------------------------+
|              ===== VICTORY =====                 |
|              ~ SWIFT ~                           |
|                                                  |
|  "They didn't stand a chance."                   |
|                                                  |
|  BONUS: +25% Gold                                |
+--------------------------------------------------+
```

---

## Defeat Screen

### Defeat Trigger Conditions

Combat ends in defeat when:
1. All party members are dead/incapacitated
2. Primary objective failed (escort died, retreat forced, etc.)
3. Party morale collapsed (all fled)

### Defeat Screen Flow

```
[Final Party Death]
    |
    v
[Death Announcement] (2s)
    |
    v
[Screen Transition: Fade to dark parchment]
    |
    v
+----------------------------------+
|        === DEFEAT ===            |  <- Header with somber music
+----------------------------------+
    |
    v
+----------------------------------+
|     FALLEN HEROES                |  <- Show who died
+----------------------------------+
    |
    v
+----------------------------------+
|     SURVIVORS (if any)           |  <- Who escaped/retreated
+----------------------------------+
    |
    v
+----------------------------------+
|     CONSEQUENCES                 |  <- What happens next
+----------------------------------+
    |
    v
[Return to Guild]
    |
    v
[Guild Hall - Mourning State]
```

### Defeat Screen Layout

```
+--------------------------------------------------+
|                                                  |
|              ===== DEFEAT =====                  |
|                                                  |
|          "The battle is lost..."                 |
|                                                  |
+--------------------------------------------------+
|  FALLEN IN BATTLE                                |
+--------------------------------------------------+
|                                                  |
|  [Portrait-Dimmed] Grimjaw Ironhide              |
|  "He died holding the line."                     |
|                                                  |
|  [Portrait-Dimmed] Elara Moonwhisper             |
|  "She fell saving her allies."                   |
|                                                  |
+--------------------------------------------------+
|  RETREATED                                       |
+--------------------------------------------------+
|                                                  |
|  [Portrait] Thornwick                            |
|  Status: Injured, Stressed                       |
|                                                  |
+--------------------------------------------------+
|  CONSEQUENCES                                    |
+--------------------------------------------------+
|                                                  |
|  - Quest Failed: Goblin Mine Clearance           |
|  - Gold Lost: -150g (abandoned supplies)         |
|  - Reputation: Crown -10                         |
|  - Survivors: Stress +25, Morale -20             |
|                                                  |
+--------------------------------------------------+
|                                                  |
|          [ RETURN TO GUILD ]                     |
|                                                  |
+--------------------------------------------------+
```

### Defeat Types & Consequences

#### Total Party Kill (TPK)

All party members died.

```python
def process_tpk(party, quest):
    consequences = {
        'gold_lost': quest.invested_supplies,
        'equipment_lost': calculate_lost_equipment(party),  # 50% of equipped items
        'reputation_penalty': -20,
        'quest_failed': True,
        'party_status': 'all_dead'
    }

    # Permanent death in Campaign mode
    if game_mode == 'Campaign':
        for character in party:
            character.status = 'DEAD'
            guild.roster.remove(character)

    # Injury in Story mode
    elif game_mode == 'Story':
        for character in party:
            character.status = 'CRITICAL_INJURY'
            character.recovery_days = 7

    return consequences
```

#### Partial Wipe

Some party members survived (fled/retreated).

```python
def process_partial_wipe(party, survivors, quest):
    consequences = {
        'gold_lost': quest.invested_supplies * 0.5,
        'reputation_penalty': -10,
        'quest_failed': True
    }

    for character in party:
        if character in survivors:
            character.stress += 25
            character.morale -= 20
            character.satisfaction -= 15

            # "Watched Ally Die" relationship impact
            for dead_ally in party:
                if dead_ally not in survivors:
                    modify_relationship(character, dead_ally, -30, "death_trauma")
        else:
            # Dead character
            if game_mode == 'Campaign':
                character.status = 'DEAD'
            else:
                character.status = 'CRITICAL_INJURY'

    return consequences
```

#### Objective Failed (Non-Combat)

Escort died, item destroyed, etc.

```python
def process_objective_failure(party, quest, failure_type):
    consequences = {
        'gold_lost': 0,
        'reputation_penalty': -15,
        'quest_failed': True,
        'party_status': 'alive_but_failed'
    }

    for character in party:
        character.stress += 15
        character.satisfaction -= 10

        # Personality impacts
        if character.personality['loyal'] >= 7:
            character.satisfaction -= 10  # Feels responsible
        if character.personality['greedy'] >= 7:
            # Less affected by mission failure
            character.satisfaction += 5

    return consequences
```

### Death Epitaphs

Generated based on how the character died:

```json
{
  "death_epitaphs": {
    "last_stand": [
      "Died holding the line.",
      "Fell defending their allies.",
      "Stood firm until the end."
    ],
    "saving_ally": [
      "Gave their life for another.",
      "Died a hero's death.",
      "Sacrificed everything."
    ],
    "overwhelmed": [
      "Fell against impossible odds.",
      "Outnumbered, but not outfought.",
      "They never stopped fighting."
    ],
    "critical_hit": [
      "Struck down by a devastating blow.",
      "A single strike was all it took.",
      "Fate was not kind today."
    ],
    "magic": [
      "Consumed by arcane fire.",
      "The magic was too strong.",
      "Claimed by dark sorcery."
    ],
    "poison": [
      "The venom was too potent.",
      "Succumbed to poison.",
      "Betrayed by a coward's weapon."
    ],
    "low_int_death": [
      "Charged in without thinking.",
      "Bravery without wisdom.",
      "If only they'd been more careful..."
    ]
  }
}
```

### Defeat Quotes

```json
{
  "defeat_quotes": {
    "general": [
      "\"We'll return... we must.\"",
      "\"This isn't over. Not by a long shot.\"",
      "\"Remember them. Honor them.\""
    ],
    "survivor_guilty": [
      "\"I should have done more...\"",
      "\"Why them and not me?\"",
      "\"I'll carry this forever.\""
    ],
    "bitter": [
      "\"Damn it all...\"",
      "\"We weren't prepared.\"",
      "\"Next time will be different.\""
    ]
  }
}
```

### Memorial System

Dead adventurers (Campaign mode) are added to a memorial:

```
+--------------------------------------------------+
|              HALL OF THE FALLEN                  |
+--------------------------------------------------+
|                                                  |
|  [Portrait] Grimjaw Ironhide                     |
|  Orc Warrior, Level 4                            |
|  Quests Completed: 12                            |
|  Kills: 47                                       |
|  Fell in: Goblin Mine Clearance                  |
|  "He died holding the line."                     |
|                                                  |
+--------------------------------------------------+
|                                                  |
|  [Portrait] Elara Moonwhisper                    |
|  Elf Mage, Level 3                               |
|  Quests Completed: 8                             |
|  Kills: 23                                       |
|  Fell in: Dragon's Lair                          |
|  "Consumed by arcane fire."                      |
|                                                  |
+--------------------------------------------------+
```

---

## Combat Log Implementation

### Data Structure

```python
class CombatLog:
    def __init__(self):
        self.entries = []
        self.turn_markers = []
        self.kills = []
        self.deaths = []

    def add_entry(self, entry_type, data, style='normal'):
        entry = {
            'id': generate_uuid(),
            'timestamp': get_combat_time(),
            'turn': current_turn,
            'type': entry_type,
            'data': data,
            'text': generate_text(entry_type, data),
            'style': style
        }
        self.entries.append(entry)

        # Track special entries
        if entry_type == 'kill':
            self.kills.append(entry)
        elif entry_type == 'death':
            self.deaths.append(entry)

        return entry

    def get_entries_for_turn(self, turn_number):
        return [e for e in self.entries if e['turn'] == turn_number]

    def export_battle_report(self):
        """
        Generate full battle report for debrief screen.
        """
        return {
            'total_turns': max(e['turn'] for e in self.entries),
            'entries': self.entries,
            'kills_by_character': group_by(self.kills, 'killer_id'),
            'damage_by_character': calculate_damage_totals(),
            'healing_by_character': calculate_healing_totals(),
            'timeline': generate_timeline()
        }
```

### Combat Log Display Modes

**Compact Mode (Default)**
- Shows last 5 entries
- Auto-scrolls with new entries
- Tap to expand

**Expanded Mode**
- Full scrollable log
- Filter by: All / Kills / Damage / Healing / Commands
- Search functionality

**Export Mode (Post-Combat)**
- Full text export
- Share to clipboard
- Save to battle history

### Combat Log Settings

| Setting | Options | Default |
|---------|---------|---------|
| Log Display | Compact / Expanded / Hidden | Compact |
| Auto-Scroll | On / Off | On |
| Verbosity | Minimal / Normal / Detailed | Normal |
| Show Damage Numbers | On / Off | On |
| Show Kill Announcements | On / Off | On |
| Announce Streaks | On / Off | On |
| Sound on Kill | On / Off | On |

---

## Appendix: Event Trigger Reference

### Combat Events

| Event | Trigger | Commentary | Kill System | Sound |
|-------|---------|------------|-------------|-------|
| ATTACK_START | Character begins attack | Yes | No | Whoosh |
| ATTACK_HIT | Attack hits target | Yes | No | Impact |
| ATTACK_MISS | Attack misses | Yes | No | Whoosh |
| ATTACK_CRITICAL | Critical hit | Yes (dramatic) | No | Epic impact |
| DAMAGE_DEALT | Damage applied | Yes | No | None |
| KILL | Target dies | Yes | Yes (full) | Kill sound |
| FIRST_BLOOD | First kill of combat | Yes | Yes | Dramatic |
| MULTI_KILL | Multiple kills same turn | Yes | Yes | Fanfare |
| STREAK | Kill streak milestone | Yes | Yes | Escalating |
| ABILITY_USED | Ability activated | Yes | No | Ability sound |
| HEAL | Healing applied | Yes | No | Chime |
| BUFF_APPLIED | Buff/debuff applied | Yes | No | Magic |
| STATUS_TICK | Status effect ticks | Yes | No | Subtle |
| DEATH | Ally/enemy dies | Yes | Varies | Death cry |
| CAPTAIN_COMMAND | Captain issues order | Yes | No | Voice |
| VICTORY | Combat won | Transition | Wrap-up | Fanfare |
| DEFEAT | Combat lost | Transition | Wrap-up | Somber |

---

**End of Battle System Specification**
