# Guild Master - Content & Balancing Specification

## Item Database

### Weapon Categories

#### Melee Weapons

**Swords**
| Name | Tier | Damage | STR Req | Special |
|------|------|--------|---------|---------|
| Rusty Sword | Basic | 1d6 | 8 | - |
| Iron Longsword | Basic | 1d8 | 10 | - |
| Steel Greatsword | Advanced | 2d6 | 14 | -2 DEX while equipped |
| Elven Blade | Advanced | 1d8+2 | 10 | +2 DEX checks |
| Flaming Sword | Elite | 1d8+1d4 fire | 12 | Fire damage ignores 5 armor |
| Dragonbane | Legendary | 2d6+3 | 14 | +2d6 vs Dragons |

**Axes**
| Name | Tier | Damage | STR Req | Special |
|------|------|--------|---------|---------|
| Hand Axe | Basic | 1d6 | 8 | Throwable (range 20) |
| Battle Axe | Basic | 1d10 | 12 | Two-handed |
| Dwarven Cleaver | Advanced | 1d10+2 | 13 | Armor penetration 3 |
| Executioner's Axe | Elite | 2d8 | 15 | Crit range 18-20 |

**Bows & Crossbows**
| Name | Tier | Damage | DEX Req | Special |
|------|------|--------|---------|---------|
| Short Bow | Basic | 1d6 | 10 | Range 60 |
| Longbow | Basic | 1d8 | 12 | Range 100 |
| Crossbow | Basic | 1d10 | 10 | Range 80, Reload action |
| Elven Recurve | Advanced | 1d8+2 | 13 | Range 120, +1 to hit |
| Heavy Crossbow | Advanced | 2d6 | 11 | Range 100, Reload, Armor pen 5 |

#### Magical Focuses

**Staves**
| Name | Tier | Bonus | INT/WIS Req | Special |
|------|------|-------|-------------|---------|
| Wooden Staff | Basic | +1 spell power | 10 | - |
| Oak Staff | Basic | +2 spell power | 12 | +5 mana |
| Crystal Staff | Advanced | +3 spell power | 14 | +10 mana, +1 spell slot |
| Staff of Elements | Elite | +4 spell power | 16 | Choose element type daily |
| Archmage Staff | Legendary | +5 spell power | 18 | +20 mana, +2 spell slots |

### Armor

**Light Armor**
| Name | Tier | AC | DEX Penalty | Special |
|------|------|----|-----------|-|---------|
| Leather | Basic | +2 | 0 | - |
| Studded Leather | Basic | +3 | 0 | - |
| Elven Chain | Advanced | +4 | 0 | Advantage on stealth |
| Shadowweave | Elite | +5 | 0 | Invisibility 1/day |

**Medium Armor**
| Name | Tier | AC | DEX Penalty | Special |
|------|------|----|-----------|-|---------|
| Hide Armor | Basic | +3 | -1 | - |
| Chain Shirt | Basic | +4 | -1 | - |
| Scale Mail | Advanced | +5 | -2 | - |
| Breastplate | Advanced | +6 | -1 | - |

**Heavy Armor**
| Name | Tier | AC | DEX Penalty | Special |
|------|------|----|-----------|-|---------|
| Chain Mail | Basic | +5 | -3 | STR 13 required |
| Splint | Advanced | +7 | -3 | STR 15 required |
| Plate Armor | Elite | +8 | -4 | STR 17 required |
| Dragon Scale | Legendary | +9 | -2 | STR 15, Fire resistance |

### Accessories

**Rings**
- Ring of Protection: +1 AC
- Ring of Strength: +2 STR
- Ring of Regeneration: Heal 1 HP per turn in combat
- Ring of Elements: Resistance to one element type
- Ring of Mind Shielding: +2 WIS, Immune to mind control

**Amulets**
- Amulet of Health: +2 CON, +10 max HP
- Amulet of the Devout: +1 spell power (divine)
- Amulet of Natural Armor: +2 AC (doesn't stack with armor)
- Amulet of Leadership: +2 CHA, Party morale +5

**Cloaks**
- Cloak of Elvenkind: Advantage on stealth
- Cloak of Protection: +1 AC, +1 to all saves
- Cloak of the Manta Ray: Can breathe underwater
- Cloak of Displacement: 20% chance enemies miss

### Consumables

**Potions**
- Minor Healing (50g): Restore 2d4+2 HP
- Healing (150g): Restore 4d4+4 HP
- Greater Healing (500g): Restore 8d4+8 HP
- Stamina (100g): Restore 20 stamina
- Mana (200g): Restore 15 mana
- Antidote (50g): Cure poison
- Resist Elements (100g): Resistance for one encounter

**Combat Items**
- Throwing Knife (10g): 1d4 damage, range 30
- Alchemist's Fire (50g): 1d6 fire damage, AOE 2 hexes
- Oil of Sharpness (100g): +1 weapon damage for one quest
- Scroll of Fireball (250g): 6d6 fire, AOE 4 hexes, INT check

---

## Ability Database

### Warrior Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Power Attack | 1 | Active | 5 Stamina | +5 damage, -2 to hit |
| Cleave | 3 | Active | 10 Stamina | If kill, free attack on adjacent enemy |
| Shield Bash | 3 | Active | 5 Stamina | Stun enemy 1 turn, damage 1d6 |
| Second Wind | 5 | Active | - | Heal 25% max HP, once per quest |
| Whirlwind | 7 | Active | 15 Stamina | Attack all adjacent enemies |
| Intimidate | 5 | Active | 10 Stamina | Enemies -2 to hit for 2 turns, CHA check |
| Battle Cry | 9 | Active | 20 Stamina | Allies +3 damage, +2 morale for 3 turns |

### Rogue Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Sneak Attack | 1 | Passive | - | +2d6 damage from stealth/flanking |
| Hide | 1 | Active | 5 Stamina | Enter stealth if not in melee |
| Backstab | 3 | Active | 10 Stamina | If from stealth, 3× damage |
| Disarm Trap | 2 | Active | - | DEX check to disable trap |
| Evasion | 5 | Passive | - | Take half damage from AOE |
| Poison Blade | 5 | Active | 15 Stamina | Next attack poisons (1d4/turn, 3 turns) |
| Smoke Bomb | 7 | Active | 20 Stamina | AOE blind, escape combat |

### Mage Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Magic Missile | 1 | Active | 5 Mana | Auto-hit, 1d4+1 per missile, 3 missiles |
| Fireball | 3 | Active | 15 Mana | 6d6 fire, AOE 4 hexes, DEX save half |
| Shield | 1 | Active | 5 Mana | +5 AC until next turn |
| Haste | 5 | Active | 20 Mana | Target gets 2 actions for 3 turns |
| Polymorph | 7 | Active | 25 Mana | Transform enemy into harmless creature, INT save |
| Meteor Swarm | 9 | Active | 40 Mana | 12d6 fire, AOE 6 hexes, battlefield damage |
| Counterspell | 5 | Reaction | 10 Mana | Cancel enemy spell, INT check |

### Cleric Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Cure Wounds | 1 | Active | 5 Mana | Heal 1d8+WIS |
| Bless | 1 | Active | 10 Mana | Allies +1d4 to attacks, saves for 5 turns |
| Turn Undead | 3 | Active | 15 Mana | Undead flee, WIS check |
| Mass Healing | 5 | Active | 25 Mana | Heal all allies 2d8+WIS |
| Divine Smite | 3 | Active | 10 Mana | +2d8 radiant damage to attack |
| Resurrection | 9 | Active | 50 Mana | Revive dead ally, 1/quest |
| Holy Aura | 7 | Active | 30 Mana | Allies immune to fear, +2 AC, 5 turns |

### Paladin Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Lay on Hands | 1 | Active | - | Heal CHA×5 HP, pool refills after rest |
| Divine Sense | 1 | Active | - | Detect undead/fiends within 60 feet |
| Smite Evil | 3 | Active | 10 Mana | +2d8 radiant to attack vs evil |
| Aura of Protection | 5 | Passive | - | Allies within 2 hexes +CHA to saves |
| Channel Divinity | 5 | Active | - | Various effects, 1/quest |
| Holy Shield | 7 | Reaction | 15 Mana | Intercept attack on ally, take damage |

### Ranger Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Hunter's Mark | 1 | Active | 5 Stamina | +1d6 damage to marked target |
| Volley | 3 | Active | 15 Stamina | Attack all enemies in 4-hex radius |
| Animal Companion | 2 | Passive | - | Summon beast ally |
| Camouflage | 5 | Active | 10 Stamina | Advantage on stealth in natural terrain |
| Multiattack | 7 | Passive | - | Attack twice per turn |

### Druid Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Wildshape | 2 | Active | - | Transform into beast, 2/quest |
| Entangle | 1 | Active | 10 Mana | Root enemies in AOE, STR save |
| Healing Word | 1 | Active | 5 Mana | Heal 1d4+WIS at range |
| Call Lightning | 5 | Active | 20 Mana | 3d10 lightning, AOE, lasts 3 turns |
| Barkskin | 3 | Active | 15 Mana | AC becomes 16 for 5 turns |
| Moonbeam | 5 | Active | 15 Mana | 2d10 radiant, AOE beam, move each turn |

### Bard Abilities

| Ability | Level | Type | Cost | Effect |
|---------|-------|------|------|--------|
| Vicious Mockery | 1 | Active | 5 Mana | 1d4 psychic, enemy disadvantage next turn |
| Bardic Inspiration | 1 | Active | - | Ally +1d6 to next roll, CHA uses per quest |
| Suggestion | 3 | Active | 10 Mana | Command enemy, CHA save |
| Mass Inspiration | 5 | Active | 15 Mana | All allies +1d6 for 3 turns |
| Hypnotic Pattern | 5 | Active | 20 Mana | Charm multiple enemies, INT save |
| Power Word Stun | 9 | Active | 35 Mana | Stun enemy with <150 HP, no save |

---

## Enemy Database

### Common Enemies (Threat 20-50)

**Goblin Scout**
- HP: 15, AC: 13
- STR 8, DEX 14, CON 10, INT 10, WIS 8, CHA 8
- Attacks: Short Sword (1d6+2), Short Bow (1d6+2, range 60)
- Abilities: Nimble Escape (bonus action disengage)
- Loot: 1-10 gold, common dagger

**Bandit**
- HP: 22, AC: 12
- STR 11, DEX 12, CON 12, INT 10, WIS 10, CHA 10
- Attacks: Scimitar (1d6+1), Light Crossbow (1d8+1)
- Loot: 5-20 gold, leather armor

**Giant Rat**
- HP: 7, AC: 12
- STR 7, DEX 15, CON 11, INT 2, WIS 10, CHA 4
- Attacks: Bite (1d4+2, may cause disease)
- Swarm Tactics: +1 attack if ally adjacent

**Skeleton**
- HP: 13, AC: 13
- STR 10, DEX 14, CON 15, INT 6, WIS 8, CHA 5
- Attacks: Shortsword (1d6+2), Shortbow (1d6+2)
- Vulnerabilities: Bludgeoning damage
- Resistances: Piercing damage

### Advanced Enemies (Threat 60-100)

**Orc Warrior**
- HP: 45, AC: 13
- STR 16, DEX 12, CON 16, INT 7, WIS 11, CHA 10
- Attacks: Greataxe (1d12+3), Javelin (1d6+3, range 30)
- Abilities: Aggressive (bonus action move toward enemy)
- Loot: 20-50 gold, greataxe, hide armor

**Ogre**
- HP: 85, AC: 11
- STR 19, DEX 8, CON 16, INT 5, WIS 7, CHA 7
- Attacks: Greatclub (2d8+4), Rock Throw (2d8+4, range 60)
- Abilities: Brutal (crits on 19-20)
- Loot: 50-100 gold, magic item (10% chance)

**Dark Cultist**
- HP: 33, AC: 12
- STR 10, DEX 12, CON 13, INT 14, WIS 12, CHA 14
- Attacks: Dagger (1d4+1)
- Spells: Magic Missile, Fireball, Shield, Counterspell
- Abilities: Dark Blessing (+1 AC per nearby cultist)
- Loot: 30-80 gold, spell scroll, unholy symbol

**Troll**
- HP: 84, AC: 15
- STR 18, DEX 13, CON 20, INT 7, WIS 9, CHA 7
- Attacks: Bite (1d6+4), Claw ×2 (1d6+4 each)
- Abilities: Regeneration (10 HP/turn, unless fire/acid damage)
- Vulnerabilities: Fire, Acid
- Loot: 100-200 gold, troll hide (crafting material)

### Elite Enemies (Threat 150-250)

**Vampire Spawn**
- HP: 82, AC: 15
- STR 16, DEX 16, CON 16, INT 11, WIS 10, CHA 12
- Attacks: Claw (2d6+3 + grapple), Bite (2d6+3 + HP drain)
- Abilities: Spider Climb, Regeneration (10 HP/turn), Vampire Weaknesses
- Loot: 200-400 gold, rare amulet

**Young Dragon (Varies by Color)**
- HP: 150, AC: 18
- STR 20, DEX 10, CON 18, INT 12, WIS 11, CHA 15
- Attacks: Bite (2d10+5), Claw ×2 (1d8+5), Breath Weapon (varies, recharge 5-6)
- Abilities: Frightful Presence, Elemental Resistance
- Loot: 500-1000 gold, dragon scales, magic items

**Demon Lieutenant**
- HP: 120, AC: 16
- STR 18, DEX 14, CON 18, INT 13, WIS 12, CHA 16
- Attacks: Longsword +2 (1d8+6), Fireball
- Abilities: Magic Resistance, Teleport (30 feet), Summon Lesser Demons
- Loot: 400-800 gold, +1/+2 weapon, rare spell component

### Boss Enemies (Threat 300+)

**Lich**
- HP: 200, AC: 17
- STR 11, DEX 16, CON 16, INT 20, WIS 14, CHA 16
- Attacks: Touch (3d6 cold + paralyze)
- Spells: Full 9th level spell list, Legendary Actions
- Abilities: Turn Resistance, Legendary Resistance (3/day), Rejuvenation
- Loot: 2000+ gold, legendary staff, spellbook, phylactery (quest item)

**Ancient Dragon**
- HP: 400, AC: 22
- STR 27, DEX 14, CON 25, INT 16, WIS 15, CHA 19
- Attacks: Bite (2d10+8), Claw ×2 (2d6+8), Tail (2d8+8)
- Breath Weapon: 15d6 damage, huge AOE
- Abilities: Legendary Actions, Lair Actions, Frightful Presence
- Loot: 5000+ gold, legendary items, dragon hoard

**Demon Lord**
- HP: 350, AC: 19
- STR 26, DEX 14, CON 24, INT 16, WIS 16, CHA 22
- Attacks: Greatsword +3 (4d6+11), Constrict (2d6+8 + grapple)
- Abilities: Magic Immunity, Summon Demons, Wish (1/week), Legendary Actions
- Loot: 5000+ gold, artifact weapon, demon heart (crafting)

---

## World Lore & Factions

### The Realm of Aventyr

**Geography:**
- **The Heartlands** - Human kingdoms, the Crown's territory
- **Silverwood** - Elven forests, Druidic Circle domain
- **Ironpeak Mountains** - Dwarven strongholds
- **The Ashlands** - Orc tribal territories, volcanic
- **The Shattered Coast** - Pirate havens, Merchant Consortium
- **Shadowfen** - Swamps, thieves and outcasts
- **The Celestial Spire** - Church of Light headquarters

---

### Faction Deep Dive

#### 1. The Crown (Lawful Authority)

**Leadership:** Queen Elara Voss
**Philosophy:** Order, justice, protection of the realm

**Quest Types:**
- Extermination: Bandit/monster threats
- Defense: Protect villages from raids
- Escort: Guard tax collectors, nobles
- Investigation: Solve crimes, root out corruption

**Reputation Rewards:**
- +10: Access to Crown armory (10% discount)
- +25: Knighthood title, +1 CHA when dealing with lawful NPCs
- +50: Elite knight recruits available
- +75: Grant of land, passive income 100 gold/week
- +100: Royal Champion title, can command Crown troops in quests

**Conflicts With:**
- Thieves' Guild (mutual hostility)
- Tribal Confederacy (border disputes)

---

#### 2. Mages' Conclave (Arcane Knowledge)

**Leadership:** Archmage Thalion Silverquill
**Philosophy:** Pursuit of magical knowledge, protection from magical threats

**Quest Types:**
- Retrieval: Recover arcane artifacts
- Investigation: Research strange magical phenomena
- Extermination: Rogue mages, magical beasts
- Escort: Protect researchers in dangerous areas

**Reputation Rewards:**
- +10: Access to spell library (learn new spells 20% cheaper)
- +25: Conclave robes (+1 spell power)
- +50: Battlemage recruits, enchantment services
- +75: Exclusive spell scrolls (6th-8th level)
- +100: Arcane Fellowship, teleportation network access

**Conflicts With:**
- Church of Light (theological disputes on magic)
- Demon cultists (obvious)

---

#### 3. Thieves' Guild (Shadow Network)

**Leadership:** The Faceless (identity unknown)
**Philosophy:** Freedom from authority, profit through cunning

**Quest Types:**
- Infiltration: Steal documents, items
- Investigation: Gather intelligence
- Sabotage: Disrupt rival operations
- Retrieval: Fence stolen goods

**Reputation Rewards:**
- +10: Black market access (buy illegal items)
- +25: Spy network (intel on rival guilds)
- +50: Master thief recruits, poison supplies
- +75: Safe houses in every city (fast travel)
- +100: Shadow Master title, can call in Guild favors

**Conflicts With:**
- The Crown (sworn enemies)
- Church of Light (moral opposition)

---

#### 4. Church of Light (Divine Order)

**Leadership:** High Priestess Seraphina Dawn
**Philosophy:** Eradicate undead/demons, heal the sick, spread the faith

**Quest Types:**
- Extermination: Undead, demons, cultists
- Rescue: Free the cursed, possessed
- Defense: Protect holy sites
- Escort: Pilgrims to shrines

**Reputation Rewards:**
- +10: Free healing at temples
- +25: Blessed items (holy water, sacred symbols)
- +50: Paladin/Cleric recruits
- +75: Divine blessings (+1 to all saves)
- +100: Saint title, resurrection services 50% off

**Conflicts With:**
- Demon cults (mortal enemies)
- Sometimes Mages' Conclave (disagreements on arcane magic)

---

#### 5. Merchant Consortium (Economic Power)

**Leadership:** Guildmaster Aldric Goldweaver
**Philosophy:** Profit, trade routes, economic stability

**Quest Types:**
- Escort: Protect caravans
- Retrieval: Recover stolen goods
- Extermination: Clear trade routes of monsters/bandits
- Diplomacy: Negotiate trade deals

**Reputation Rewards:**
- +10: 10% discount at all shops
- +25: Access to rare imports
- +50: Merchant contacts (sell items for 20% more)
- +75: Trading company shares (passive income 200 gold/week)
- +100: Consortium seat, can influence regional economy

**Neutral With:** Most factions (business is business)

---

#### 6. Druidic Circle (Nature Guardians)

**Leadership:** Archdruid Thornwick Mossbranch
**Philosophy:** Preserve nature, balance, harmony with beasts

**Quest Types:**
- Investigation: Unnatural phenomena
- Extermination: Aberrations, corrupt fey
- Rescue: Free captured animals
- Defense: Protect sacred groves

**Reputation Rewards:**
- +10: Free passage through Silverwood
- +25: Beast companion options expand
- +50: Druid recruits, natural remedies (superior healing items)
- +75: Wildshape training (gain limited druid ability)
- +100: Nature's Ally title, can summon treants in combat

**Conflicts With:**
- Industrialists, loggers (protection quests)

---

#### 7. Tribal Confederacy (Warrior Culture)

**Leadership:** Warlord Gruumsh Ironhide
**Philosophy:** Strength, honor in battle, tribal unity

**Quest Types:**
- Extermination: Prove strength in combat
- Defense: Protect tribes from threats
- Escort: Honor guards for chieftains
- Diplomacy: Settle inter-tribal disputes

**Reputation Rewards:**
- +10: Tribal warriors available for hire
- +25: Berserker training (+5 HP, +1 STR trait)
- +50: Shaman recruits, tribal tattoos (cosmetic + small stat bonus)
- +75: Bloodbrother title, tribes will fight for you
- +100: Warlord Council seat, can call tribal army

**Conflicts With:**
- The Crown (border skirmishes)

---

## Balancing Philosophy

### Party Composition Balance

**Optimal Party (4 members):**
- 1 Tank (Warrior, Paladin)
- 1 DPS (Rogue, Ranger, melee-focused)
- 1 Caster (Mage, Druid)
- 1 Support (Cleric, Bard)

**Alternative Compositions:**
- Double Tank: Very survivable, slow combat
- No Healer: High risk, must rely on potions
- All DPS: Glass cannon, exciting but fragile

### Difficulty Scaling

**Quest Difficulty = Base × (Party Level Factor) × (Reputation Modifier)**

- Party Level 1-3: Tier 1 quests (Threat 100-200)
- Party Level 4-6: Tier 2 quests (Threat 200-400)
- Party Level 7-9: Tier 3 quests (Threat 400-600)
- Party Level 10+: Tier 4 quests (Threat 600-1000)

**Reputation Modifier:**
- High reputation: Harder quests available (+20% threat)
- Low reputation: Easier quests only

### Economy Balance

**Gold Income vs Expenses:**

Average quest reward: 200-500 gold (tier 1-2)

**Weekly Expenses:**
- Adventurer salaries: 50g per character
- Guild upkeep: 100g
- Equipment repairs: 50g
- Total: ~400g/week for 4-person roster

**Profit Margin:** Should average 100-200g profit per quest

**Item Pricing Guidelines:**
- Common items: 10-100g
- Uncommon: 100-500g
- Rare: 500-2000g
- Very Rare: 2000-10000g
- Legendary: 10000+ g

---

## Random Encounter Tables

### Overworld Travel

**Plains (d10):**
1. Bandit ambush (4-6 bandits)
2. Traveling merchant (trade opportunity)
3. Wild horses (can be tamed, animal handling check)
4. Goblin scouts (2-4)
5. Nothing
6. Abandoned cart (loot or trap)
7. Lost traveler (escort quest opportunity)
8. Weather event (storm, delays travel)
9. Wandering minstrel (party morale +5)
10. Rival guild sighting (possible conflict)

**Forest (d10):**
1. Giant spiders (3-5)
2. Druid's grove (healing, information)
3. Treant (neutral, may talk or attack if provoked)
4. Bandit hideout
5. Nothing
6. Fey creature (trickster, deal or prank)
7. Bear (hostile if approached)
8. Hidden shrine (minor treasure)
9. Elven patrol (friendly if high Druid rep)
10. Mysterious fog (WIS save or confused for 1 hour)

**Mountains (d10):**
1. Avalanche (DEX save or damage)
2. Dwarven outpost (trade)
3. Giant eagles (may offer flight if helped)
4. Orc raiders (4-6)
5. Nothing
6. Cave entrance (potential dungeon)
7. Mountain goats (food source)
8. Rockslide blocks path (detour)
9. Dragon sighting (far away, foreshadowing)
10. Lost treasure cache

---

**FINAL NOTE:** This is still a 2-year scope. For 12 months, you MUST cut 60% of this content.