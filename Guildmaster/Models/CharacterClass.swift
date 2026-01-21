//
//  CharacterClass.swift
//  Guildmaster
//
//  Core class definitions with abilities and progression
//

import Foundation

/// The four playable classes (MVP scope)
enum CharacterClass: String, CaseIterable, Codable, Identifiable {
    case warrior = "Warrior"
    case rogue = "Rogue"
    case mage = "Mage"
    case cleric = "Cleric"

    var id: String { rawValue }

    /// Primary stat for this class (gets +2 during creation)
    var primaryStat: StatType {
        switch self {
        case .warrior: return .str
        case .rogue: return .dex
        case .mage: return .int
        case .cleric: return .wis
        }
    }

    /// Hit die for HP calculation on level up
    var hitDie: Int {
        switch self {
        case .warrior: return 10  // d10
        case .rogue: return 8     // d8
        case .mage: return 6      // d6
        case .cleric: return 8    // d8
        }
    }

    /// Base armor class without equipment
    var baseArmorClass: Int {
        switch self {
        case .warrior: return 10
        case .rogue: return 10
        case .mage: return 10
        case .cleric: return 10
        }
    }

    /// Starting mana pool multiplier
    var manaMultiplier: Double {
        switch self {
        case .warrior: return 0.0   // Warriors use stamina
        case .rogue: return 0.0     // Rogues use stamina
        case .mage: return 2.0      // (INT + WIS) * 2
        case .cleric: return 1.5    // (INT + WIS) * 1.5
        }
    }

    /// Starting stamina multiplier
    var staminaMultiplier: Double {
        switch self {
        case .warrior: return 3.0   // CON * 3
        case .rogue: return 3.0     // CON * 3
        case .mage: return 1.5      // CON * 1.5
        case .cleric: return 2.0    // CON * 2
        }
    }

    /// Class description
    var description: String {
        switch self {
        case .warrior:
            return "Masters of martial combat, warriors excel at protecting allies and dealing devastating melee damage."
        case .rogue:
            return "Cunning and deadly, rogues strike from the shadows with precision and guile."
        case .mage:
            return "Wielders of arcane power, mages command devastating spells but are fragile in close combat."
        case .cleric:
            return "Divine servants who heal allies and smite the unholy with sacred magic."
        }
    }

    /// Innate class trait
    var classTrait: ClassTrait {
        switch self {
        case .warrior: return .combatStance
        case .rogue: return .opportunist
        case .mage: return .arcaneFocus
        case .cleric: return .divineGrace
        }
    }

    /// Abilities unlocked at each level
    func abilitiesForLevel(_ level: Int) -> [AbilityType] {
        switch self {
        case .warrior:
            return warriorAbilities(at: level)
        case .rogue:
            return rogueAbilities(at: level)
        case .mage:
            return mageAbilities(at: level)
        case .cleric:
            return clericAbilities(at: level)
        }
    }

    private func warriorAbilities(at level: Int) -> [AbilityType] {
        var abilities: [AbilityType] = []
        if level >= 1 { abilities.append(.powerAttack) }
        if level >= 3 { abilities.append(contentsOf: [.cleave, .shieldBash]) }
        if level >= 5 { abilities.append(.secondWind) }
        if level >= 7 { abilities.append(.whirlwind) }
        return abilities
    }

    private func rogueAbilities(at level: Int) -> [AbilityType] {
        var abilities: [AbilityType] = []
        if level >= 1 { abilities.append(contentsOf: [.sneakAttack, .hide]) }
        if level >= 3 { abilities.append(.backstab) }
        if level >= 5 { abilities.append(contentsOf: [.evasion, .poisonBlade]) }
        return abilities
    }

    private func mageAbilities(at level: Int) -> [AbilityType] {
        var abilities: [AbilityType] = []
        if level >= 1 { abilities.append(contentsOf: [.magicMissile, .shield]) }
        if level >= 3 { abilities.append(.fireball) }
        if level >= 5 { abilities.append(contentsOf: [.haste, .counterspell]) }
        return abilities
    }

    private func clericAbilities(at level: Int) -> [AbilityType] {
        var abilities: [AbilityType] = []
        if level >= 1 { abilities.append(contentsOf: [.cureWounds, .bless]) }
        if level >= 3 { abilities.append(contentsOf: [.turnUndead, .divineSmite]) }
        if level >= 5 { abilities.append(.massHealing) }
        return abilities
    }
}

/// Class traits that provide unique passive abilities
enum ClassTrait: String, Codable {
    case combatStance = "Combat Stance"   // Warrior: Defensive/Offensive stance
    case opportunist = "Opportunist"       // Rogue: +2d6 on flanked/surprised
    case arcaneFocus = "Arcane Focus"     // Mage: Sacrifice HP for mana
    case divineGrace = "Divine Grace"     // Cleric: Auto-save from death 1/quest

    var description: String {
        switch self {
        case .combatStance:
            return "Can adopt Defensive (+2 AC, -2 attack) or Offensive (+2 attack, -2 AC) stance."
        case .opportunist:
            return "+2d6 damage against flanked or surprised enemies."
        case .arcaneFocus:
            return "Can sacrifice 5 HP to recover 10 mana."
        case .divineGrace:
            return "Once per quest, automatically succeed a death save or stabilize a dying ally."
        }
    }
}

/// Stat types for reference
enum StatType: String, CaseIterable, Codable {
    case str = "STR"
    case dex = "DEX"
    case con = "CON"
    case int = "INT"
    case wis = "WIS"
    case cha = "CHA"

    var fullName: String {
        switch self {
        case .str: return "Strength"
        case .dex: return "Dexterity"
        case .con: return "Constitution"
        case .int: return "Intelligence"
        case .wis: return "Wisdom"
        case .cha: return "Charisma"
        }
    }
}
