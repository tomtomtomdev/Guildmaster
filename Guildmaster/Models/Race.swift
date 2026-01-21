//
//  Race.swift
//  Guildmaster
//
//  Core race definitions with stat modifiers and traits
//

import Foundation

/// The four playable races in the game (MVP scope)
enum Race: String, CaseIterable, Codable, Identifiable {
    case human = "Human"
    case elf = "Elf"
    case dwarf = "Dwarf"
    case orc = "Orc"

    var id: String { rawValue }

    /// Stat modifiers applied during character creation
    var statModifiers: StatBlock {
        switch self {
        case .human:
            return StatBlock(str: 1, dex: 1, con: 1, int: 1, wis: 1, cha: 1)
        case .elf:
            return StatBlock(str: -1, dex: 2, con: -1, int: 2, wis: 1, cha: 1)
        case .dwarf:
            return StatBlock(str: 2, dex: -1, con: 2, int: 0, wis: 1, cha: -1)
        case .orc:
            return StatBlock(str: 3, dex: 0, con: 2, int: -2, wis: -1, cha: -1)
        }
    }

    /// Innate racial trait
    var racialTrait: RacialTrait {
        switch self {
        case .human:
            return .adaptable
        case .elf:
            return .keenSenses
        case .dwarf:
            return .stoneBlood
        case .orc:
            return .battleFury
        }
    }

    /// Description of the race
    var description: String {
        switch self {
        case .human:
            return "Versatile and ambitious, humans excel at adapting to any situation."
        case .elf:
            return "Ancient and wise, elves possess keen senses and natural magical affinity."
        case .dwarf:
            return "Sturdy and resilient, dwarves are resistant to poison and disease."
        case .orc:
            return "Fierce warriors who grow stronger when bloodied in battle."
        }
    }

    /// Base movement speed in hexes
    var baseMovementSpeed: Int {
        switch self {
        case .human: return 6
        case .elf: return 7
        case .dwarf: return 5
        case .orc: return 6
        }
    }
}

/// Racial traits that provide unique passive abilities
enum RacialTrait: String, Codable {
    case adaptable = "Adaptable"        // Human: +10% XP gain
    case keenSenses = "Keen Senses"     // Elf: +2 perception, immune to surprise
    case stoneBlood = "Stone Blood"     // Dwarf: 50% poison resistance, +2 vs disease
    case battleFury = "Battle Fury"     // Orc: +3 damage when HP < 30%

    var description: String {
        switch self {
        case .adaptable:
            return "+10% XP gain. Learn new abilities one level early."
        case .keenSenses:
            return "+2 to perception checks. Cannot be surprised in the first round."
        case .stoneBlood:
            return "50% resistance to poison. +2 to saves against disease."
        case .battleFury:
            return "+3 damage when HP falls below 30%."
        }
    }
}
