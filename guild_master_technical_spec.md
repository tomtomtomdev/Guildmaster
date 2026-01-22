# Guild Master - Technical Systems Specification

## Data Architecture

### Character Data Structure

```json
{
  "characterID": "uuid",
  "name": "string",
  "race": "enum",
  "class": "enum",
  "background": "enum",
  "level": "int (1-20)",
  "stats": {
    "str": "int (1-20)",
    "dex": "int (1-20)",
    "con": "int (1-20)",
    "int": "int (1-20)",
    "wis": "int (1-20)",
    "cha": "int (1-20)"
  },
  "secondaryStats": {
    "hp": "int",
    "maxHp": "int",
    "stamina": "int",
    "maxStamina": "int",
    "mana": "int",
    "maxMana": "int",
    "initiative": "int",
    "morale": "int (0-100)",
    "stress": "int (0-100)"
  },
  "satisfaction": "int (0-100)",
  "satisfactionFactors": {
    "questSuccessStreak": "int",
    "daysSinceRest": "int",
    "injuryCount": "int",
    "lootShareFairness": "float"
  },
  "equipment": {
    "weapon": "itemID",
    "armor": "itemID",
    "accessory1": "itemID",
    "accessory2": "itemID"
  },
  "abilities": ["abilityID array"],
  "traits": ["traitID array"],
  "personality": {
    "greedy": "int (0-10)",
    "loyal": "int (0-10)",
    "brave": "int (0-10)",
    "cautious": "int (0-10)"
  },
  "relationships": {
    "characterID": "int (-100 to +100)"
  },
  "questHistory": {
    "totalQuests": "int",
    "successCount": "int",
    "failureCount": "int",
    "killCount": "int",
    "deathsWitnessed": "int"
  }
}
```

---

## AI Decision System

### Utility AI Framework

Each combat decision is scored based on multiple utility curves:

#### Decision Options Per Turn
1. Move to position X
2. Attack target Y
3. Use ability Z
4. Use item W
5. Defend/Wait
6. Flee (if morale < threshold)

#### Utility Scoring Factors

**Attack Target Selection:**
```
score = 
  (targetThreatLevel × 0.3) +
  (targetLowHPBonus × 0.2) +
  (targetInRangeBonus × 0.2) +
  (targetWeaknessMatch × 0.2) +
  (captainPriority × 0.1)
  
Modified by INT:
- Low INT (1-8): Random 30% noise added
- Medium INT (9-14): Random 15% noise
- High INT (15-20): Optimal selection
```

**Ability Usage:**
```
score = 
  (abilitySituationalValue × 0.3) +
  (resourceEfficiency × 0.2) +
  (partyNeed × 0.2) +
  (selfPreservation × 0.2) +
  (captainDirective × 0.1)

Examples:
- Healing spell: High if ally < 30% HP
- AOE: High if 3+ clustered enemies
- Buff: High at combat start
- Debuff: High vs elite enemies
```

**Positioning:**
```
score = 
  (coverAvailable × 0.25) +
  (flankingOpportunity × 0.25) +
  (supportAllyProximity × 0.2) +
  (retreatSafety × 0.2) +
  (objectiveDistance × 0.1)
```

### Behavior Trees by INT Tier

**LOW INT (1-8) Behavior Tree:**
```
ROOT
├─ IF in melee range
│  └─ Attack nearest enemy
├─ ELSE IF enemy visible
│  └─ Move toward nearest enemy
└─ ELSE
   └─ Move randomly
```

**MEDIUM INT (9-14) Behavior Tree:**
```
ROOT
├─ IF HP < 30%
│  ├─ IF healing available → Use healing
│  └─ ELSE → Move to cover
├─ IF ally HP < 20%
│  └─ IF has healing → Heal ally
├─ IF elite enemy present
│  └─ Focus fire elite
├─ IF multiple enemies clustered
│  └─ Use AOE if available
└─ DEFAULT
   └─ Attack most threatening target in range
```

**HIGH INT (15-20) Behavior Tree:**
```
ROOT
├─ Evaluate battlefield state
├─ Predict enemy actions (simple)
├─ IF critical threat detected
│  ├─ Coordinate with allies
│  └─ Focus fire
├─ IF opportunity for advantage
│  ├─ Position for flanking
│  └─ Setup combo with allies
├─ IF resources low
│  └─ Conserve abilities, use basic attacks
└─ DEFAULT
   └─ Optimal target selection with multi-turn planning
```

### Captain Influence System

**Captain Command Options:**
- "Focus Fire [Target]" - All party members prioritize one enemy
- "Defensive Formation" - Reduce aggression, increase survival
- "Spread Out" - Counter AOE threats
- "Retreat to Position" - Tactical repositioning
- "Conserve Resources" - Limit ability usage

**Command Compliance:**
```
complianceChance = 
  (captainCHA × 5) + 
  (targetMorale) + 
  (relationshipWithCaptain) - 
  (targetStress)

Roll d100:
- Success: Command followed
- Failure: Target acts on own AI
- Critical Failure (morale < 20): Target panics or rebels
```

---

## Satisfaction Mechanics

### Calculation Per Quest

```python
def calculate_satisfaction_change(character, quest_result):
    change = 0
    
    # Quest outcome (biggest factor)
    if quest_result.success:
        change += 10
        if quest_result.flawless_victory:
            change += 5
    else:
        change -= 15
        if quest_result.party_deaths > 0:
            change -= 10
    
    # Loot distribution
    loot_share = character.loot_received / quest_result.total_loot
    expected_share = 1.0 / party_size
    
    if character.personality.greedy > 7:
        if loot_share < expected_share:
            change -= 10
        elif loot_share > expected_share:
            change += 5
    
    # Injuries and stress
    if character.hp < character.maxHp * 0.3:
        change -= 5
    if character.stress > 70:
        change -= 8
    
    # Rest and overwork
    if character.days_since_rest > 7:
        change -= 3 * (character.days_since_rest - 7)
    
    # Relationship factors
    for ally in party:
        if character.relationships[ally.id] < -30:
            change -= 3  # Hates party member
        elif character.relationships[ally.id] > 50:
            change += 2  # Enjoys company
    
    # Guild facilities
    if guild.has_luxury_barracks:
        change += 2
    if guild.has_training_grounds:
        change += 1
    
    return clamp(change, -50, +50)
```

### Desertion Threshold

```python
def check_desertion(character):
    if character.satisfaction >= 30:
        return False  # Safe
    
    # Loyalty trait reduces desertion risk
    loyalty_bonus = character.personality.loyal * 5
    
    desertion_roll = random(1, 100)
    threshold = character.satisfaction + loyalty_bonus
    
    if desertion_roll > threshold:
        # Character attempts to leave
        if guild.has_strong_leadership:  # Guildmaster high CHA
            # Second chance to convince them to stay
            persuasion_check = guildmaster.cha * 5
            if random(1, 100) < persuasion_check:
                character.satisfaction += 10  # Convinced to stay
                return False
        
        return True  # Desertion happens
    
    return False
```

---

## Combat System Implementation

### Grid-Based Battlefield

**Grid Type:** Hexagonal (easier diagonal movement)

**Grid Size:** 
- Small encounter: 8×10 hexes
- Medium encounter: 12×15 hexes
- Large encounter: 15×20 hexes

**Terrain Types:**
- Open: No modifiers
- Cover (half): +2 AC vs ranged
- Cover (full): +5 AC vs ranged, blocks line of sight
- Difficult (mud, rubble): Movement cost ×2
- Hazard (fire, poison): Damage per turn
- High Ground: +1 attack bonus, advantage on ranged

### Turn Order System

```python
def initialize_combat(participants):
    initiative_order = []
    
    for character in participants:
        roll = random(1, 20)
        initiative = character.dex + roll + character.initiative_bonus
        
        initiative_order.append({
            'character': character,
            'initiative': initiative,
            'hasActed': False
        })
    
    initiative_order.sort(key=lambda x: x['initiative'], reverse=True)
    return initiative_order

def combat_round(initiative_order):
    for entry in initiative_order:
        if not entry['hasActed'] and entry['character'].hp > 0:
            execute_turn(entry['character'])
            entry['hasActed'] = True
    
    # Reset for next round
    for entry in initiative_order:
        entry['hasActed'] = False
```

### Action Economy

Each character's turn:
1. **Movement** (up to movement speed in hexes)
2. **Main Action** (attack, ability, item)
3. **Bonus Action** (if ability grants it)
4. **Reaction** (triggered by enemy actions, e.g., opportunity attack)

**Movement Speed by Race/Class:**
- Standard: 6 hexes
- High DEX (15+): 7 hexes
- Encumbered: 4 hexes
- Difficult terrain: ÷2

### Attack Resolution

```python
def resolve_attack(attacker, defender, attack_type):
    # Attack roll
    attack_roll = random(1, 20)
    
    if attack_roll == 1:
        return {'result': 'critical_miss', 'damage': 0}
    elif attack_roll == 20:
        return {'result': 'critical_hit', 'damage': calculate_damage(attacker, attack_type) * 2}
    
    # Normal hit calculation
    attack_bonus = attacker.str if attack_type == 'melee' else attacker.dex
    attack_total = attack_roll + attack_bonus + attacker.weapon_bonus
    
    defender_ac = defender.armor_class + get_cover_bonus(defender.position)
    
    if attack_total >= defender_ac:
        damage = calculate_damage(attacker, attack_type)
        return {'result': 'hit', 'damage': damage}
    else:
        return {'result': 'miss', 'damage': 0}

def calculate_damage(attacker, attack_type):
    base_damage = attacker.weapon_damage
    stat_bonus = attacker.str if attack_type == 'melee' else attacker.dex
    
    damage = random(base_damage['min'], base_damage['max']) + stat_bonus
    
    # Critical modifiers
    if attacker.has_trait('Keen_Edge'):
        damage += random(1, 6)
    
    return max(1, damage)  # Minimum 1 damage
```

---

## Quest Generation System

### Dynamic Quest Pool

```python
class QuestGenerator:
    def generate_available_quests(self, world_state, guild_reputation):
        quests = []
        base_quest_count = 8
        
        # Factor 1: World events affect quest types
        if world_state.has_event('Monster_Invasion'):
            extermination_weight = 3.0
        else:
            extermination_weight = 1.0
        
        if world_state.has_event('War'):
            escort_weight = 2.0
            defense_weight = 2.0
        else:
            escort_weight = 1.0
            defense_weight = 1.0
        
        # Factor 2: Reputation unlocks higher tier quests
        available_tiers = []
        if guild_reputation['Crown'] >= 50:
            available_tiers.append('Elite')
        if guild_reputation['Crown'] >= 20:
            available_tiers.append('Advanced')
        available_tiers.append('Basic')
        
        # Generate quest pool
        quest_types = {
            'extermination': extermination_weight,
            'rescue': 1.0,
            'escort': escort_weight,
            'retrieval': 1.0,
            'investigation': 0.5,
            'defense': defense_weight,
            'infiltration': 0.3
        }
        
        for i in range(base_quest_count):
            quest_type = weighted_random(quest_types)
            tier = random.choice(available_tiers)
            quest = self.create_quest(quest_type, tier, world_state)
            quests.append(quest)
        
        return quests
    
    def create_quest(self, quest_type, tier, world_state):
        difficulty_modifier = {
            'Basic': 1.0,
            'Advanced': 1.5,
            'Elite': 2.0
        }
        
        quest = {
            'id': generate_uuid(),
            'type': quest_type,
            'tier': tier,
            'title': generate_quest_title(quest_type),
            'description': generate_quest_description(quest_type, world_state),
            'location': select_location(world_state),
            'difficulty': calculate_difficulty(tier),
            'rewards': {
                'gold': base_gold * difficulty_modifier[tier],
                'items': generate_loot_table(tier),
                'reputation': base_rep * difficulty_modifier[tier],
                'exp': base_exp * difficulty_modifier[tier]
            },
            'encounters': generate_encounters(quest_type, tier),
            'time_limit': None if quest_type != 'escort' else 7  # days
        }
        
        return quest
```

### Encounter Generation

```python
def generate_encounters(quest_type, tier):
    encounter_count = {
        'Basic': random(2, 3),
        'Advanced': random(3, 4),
        'Elite': random(4, 5)
    }
    
    encounters = []
    for i in range(encounter_count[tier]):
        encounter_type = 'combat' if random() < 0.7 else 'skill_challenge'
        
        if encounter_type == 'combat':
            enemy_party = generate_enemy_party(tier, i == encounter_count[tier] - 1)
        else:
            challenge = generate_skill_challenge(quest_type)
        
        encounters.append({
            'type': encounter_type,
            'enemies': enemy_party if encounter_type == 'combat' else None,
            'challenge': challenge if encounter_type == 'skill_challenge' else None
        })
    
    return encounters

def generate_enemy_party(tier, is_boss_fight):
    difficulty_budget = {
        'Basic': 300,
        'Advanced': 600,
        'Elite': 1000
    }
    
    budget = difficulty_budget[tier]
    if is_boss_fight:
        budget *= 1.5
    
    enemies = []
    enemy_templates = load_enemy_database()
    
    while budget > 0:
        if is_boss_fight and len(enemies) == 0:
            # First enemy is boss
            enemy = select_boss_enemy(tier)
        else:
            enemy = weighted_select(enemy_templates, budget)
        
        enemies.append(create_enemy_instance(enemy))
        budget -= enemy.threat_value
    
    return enemies
```

---

## Rival Guild AI

### Rival Behavior Models

Each rival guild has personality traits that affect their strategy:

```python
class RivalGuild:
    def __init__(self, name, personality):
        self.name = name
        self.resources = 5000  # Starting gold
        self.reputation = {faction: 0 for faction in FACTIONS}
        self.adventurers = generate_starting_party(4)
        self.personality = personality  # {'aggressive': 0-10, 'greedy': 0-10, 'honorable': 0-10}
    
    def make_weekly_decision(self, available_quests, player_guild):
        # Decision weights based on personality
        actions = []
        
        # Action 1: Take a quest
        for quest in available_quests:
            value = quest.reward_value
            
            # Aggressive rivals prefer combat quests
            if self.personality['aggressive'] > 7 and quest.type == 'extermination':
                value *= 1.5
            
            # Greedy rivals prefer high-gold quests
            if self.personality['greedy'] > 7:
                value *= (quest.gold_reward / 1000)
            
            actions.append({
                'type': 'take_quest',
                'quest': quest,
                'value': value
            })
        
        # Action 2: Sabotage player
        if self.personality['aggressive'] > 6 and player_guild.reputation['Crown'] > self.reputation['Crown']:
            sabotage_value = (player_guild.reputation['Crown'] - self.reputation['Crown']) * 10
            actions.append({
                'type': 'sabotage_reputation',
                'target': player_guild,
                'value': sabotage_value,
                'cost': 500
            })
        
        # Action 3: Ambush returning party
        if self.personality['aggressive'] > 8 and not self.personality['honorable'] > 5:
            if player_guild.has_party_on_quest():
                actions.append({
                    'type': 'ambush',
                    'target': player_guild.active_party,
                    'value': 800,  # High value if successful
                    'cost': 0,
                    'risk': 0.4  # Might fail
                })
        
        # Action 4: Recruit adventurer
        if len(self.adventurers) < 8:
            actions.append({
                'type': 'recruit',
                'value': 300,
                'cost': 800
            })
        
        # Select best action by value-to-cost ratio
        best_action = max(actions, key=lambda a: a['value'] / max(a.get('cost', 1), 1))
        self.execute_action(best_action)
```

### Ambush System

```python
def execute_ambush(rival_guild, player_party):
    # Check if ambush is detected
    detection_chance = max(player_party.member_with_highest('wis').wis * 3, 20)
    
    if random(1, 100) < detection_chance:
        return {'detected': True, 'can_avoid': True}
    
    # Ambush initiates combat
    # Rivals get surprise round
    combat_state = initialize_ambush_combat(
        attackers=rival_guild.adventurers,
        defenders=player_party.members,
        surprise_attackers=True
    )
    
    result = resolve_combat(combat_state)
    
    if result.winner == 'attackers':
        # Rivals steal loot and injure party
        stolen_loot = player_party.loot * 0.5
        rival_guild.resources += stolen_loot
        
        for member in player_party.members:
            member.satisfaction -= 20
            member.stress += 15
        
        return {'success': True, 'loot_stolen': stolen_loot}
    else:
        # Player defeats ambush, gains rival guild reputation penalty
        rival_guild.reputation['Crown'] -= 10
        return {'success': False, 'rival_weakened': True}
```

---

## Save System

### Save Data Structure

```json
{
  "saveVersion": "1.0.0",
  "metadata": {
    "guildName": "string",
    "playtime": "int (seconds)",
    "lastSaved": "timestamp",
    "difficulty": "enum"
  },
  "guildState": {
    "resources": {
      "gold": "int",
      "reputation": {"faction": "int"}
    },
    "facilities": ["facilityID array"],
    "staff": ["staffID array"]
  },
  "roster": ["characterData array"],
  "worldState": {
    "currentDay": "int",
    "activeEvents": ["eventID array"],
    "completedQuests": ["questID array"],
    "factionStates": ["factionData array"]
  },
  "rivalGuilds": ["rivalData array"],
  "storyProgress": {
    "mainQuestStage": "int",
    "branchPath": "enum",
    "importantChoices": ["choiceID array"]
  },
  "unlockedContent": {
    "races": ["raceID array"],
    "classes": ["classID array"],
    "codexEntries": ["entryID array"]
  }
}
```

### Auto-Save Points
- After every quest completion
- After recruiting new adventurer
- After major story choice
- Every 5 minutes of idle time
- On app backgrounding (iOS)

---

## Performance Optimization

### Mobile-Specific Considerations

1. **Memory Management**
   - Pool character sprites (max 20 loaded)
   - Lazy-load combat animations
   - Unload unused quest data after completion

2. **Battery Life**
   - Reduce frame rate to 30 FPS in menus
   - Pause background calculations when app inactive
   - Use sprite sheets for animations

3. **Load Times**
   - Async loading for quest generation
   - Progressive loading: Core systems first, then content
   - Compress save files with JSON + gzip

4. **Touch Controls**
   - Minimum tap target: 44×44 points (iOS standard)
   - Swipe gestures for navigation
   - Long-press for character details
   - Pinch-to-zoom on combat grid

---

## Testing Strategy

### Unit Tests
- Character stat calculations
- AI decision scoring
- Combat resolution
- Quest generation algorithms

### Integration Tests
- Full quest playthrough
- Rival guild interactions
- Multi-quest campaign simulation
- Save/load integrity

### Playtesting Goals
- 50+ hours of playtesting before launch
- Test all story branches
- Balance testing: Win rate should be 60-70%
- Satisfaction system: No mass desertions in normal play

---

**Next Document:** Content specification (enemies, items, abilities, world lore)