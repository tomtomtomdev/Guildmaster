# Guild Master

A fantasy guild management strategy RPG for iOS featuring INT-driven AI party members and hex-based tactical combat.

## Overview

Guild Master combines management simulation with turn-based tactical combat. Recruit adventurers, manage your guild, and send parties on quests where AI-controlled party members make decisions based on their Intelligence stat—creating emergent personalities and tactical variety.

## Features

### Combat System
- **Hex Grid Tactical Combat** - 10x12 grid with cube coordinate system and A* pathfinding
- **INT-Driven AI** - Party members make contextually appropriate decisions based on their Intelligence stat
  - Low INT: Random noise and occasional mistakes
  - High INT: Optimal tactical decisions
- **19 Combat Abilities** - Class-specific skills including Power Attack, Magic Missile, Cure Wounds, and more
- **Captain System** - High CHA/INT characters can lead squads, improving team coordination

### Character System
- **4 Races** - Human, Elf, Dwarf, Orc with unique racial traits and stat modifiers
- **4 Classes** - Warrior, Rogue, Mage, Cleric with distinct abilities and progression
- **D&D-Style Stats** - STR, DEX, CON, INT, WIS, CHA on a 1-20 scale
- **Equipment System** - Weapons, armor, and accessories with attribute bonuses
- **Personality & Relationships** - Characters develop traits and relationships affecting morale and performance

### Guild Management
- **Recruitment** - Hire adventurers from a pool with randomized stats and personalities
- **Training Grounds** - Improve adventurer stats through dedicated training slots
- **Economy** - Manage gold through quest rewards and hiring costs
- **Reputation** - Track standing with 6 factions (merchants, temple, guard, frontier, nobility, tavern)

### Quest System
- **5 Quest Types** - Extermination, Rescue, Escort, Investigation, Defense
- **3 Difficulty Tiers** - Tutorial, Basic, Advanced
- **Random Encounters** - Procedural events between quests
- **Skill Challenges** - Non-combat challenges requiring specific party compositions

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository
2. Open `Guildmaster.xcodeproj` in Xcode
3. Build and run on simulator or device

## Project Structure

```
Guildmaster/
├── Models/          # Data structures (Character, Race, Class, Quest, Item, etc.)
├── Combat/          # Battle system (CombatManager, HexGrid, CombatAI, Pathfinding)
├── Guild/           # Guild management (GuildManager, Recruitment, Training, Economy)
├── Views/           # SwiftUI views organized by feature
├── Quest/           # Quest and encounter management
├── Story/           # Narrative and campaign progression
├── Core/            # Save system and persistence
├── Managers/        # Audio and tutorial systems
└── Utils/           # Utilities (name generation, etc.)
```

## Architecture

- **SwiftUI** - Native iOS UI framework
- **MVVM** - Model-View-ViewModel with Observable pattern
- **Combine** - Reactive state management
- **Codable** - JSON serialization for save/load

## Documentation

Design documents are available in the `Documentation/` folder:
- `guild_master_gdd_core.md` - Core game design document
- `guild_master_technical_spec.md` - Technical systems specification
- `guild_master_battle_system_spec.md` - Combat system details
- `guild_master_content_spec.md` - Content guidelines

## License

All rights reserved.
