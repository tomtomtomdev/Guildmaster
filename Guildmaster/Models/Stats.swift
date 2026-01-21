//
//  Stats.swift
//  Guildmaster
//
//  Stat structures for characters and modifiers
//

import Foundation

/// Primary stat block (STR, DEX, CON, INT, WIS, CHA)
/// Stats range from 1-20 with 10 being average
struct StatBlock: Codable, Equatable {
    var str: Int  // Strength - Physical damage, carry capacity, intimidation
    var dex: Int  // Dexterity - Initiative, dodge, ranged/finesse attacks
    var con: Int  // Constitution - HP pool, stamina, poison/disease resistance
    var int: Int  // Intelligence - AI Decision Quality, spell power (arcane)
    var wis: Int  // Wisdom - Spell power (divine), insight, willpower saves
    var cha: Int  // Charisma - Leadership/Influence, persuasion, party morale

    /// Default average stats
    static let average = StatBlock(str: 10, dex: 10, con: 10, int: 10, wis: 10, cha: 10)

    /// Zero stat block (for modifiers)
    static let zero = StatBlock(str: 0, dex: 0, con: 0, int: 0, wis: 0, cha: 0)

    /// Calculate modifier for a stat (D&D style: (stat - 10) / 2)
    static func modifier(for value: Int) -> Int {
        return (value - 10) / 2
    }

    /// Get stat value by type
    func value(for stat: StatType) -> Int {
        switch stat {
        case .str: return str
        case .dex: return dex
        case .con: return con
        case .int: return int
        case .wis: return wis
        case .cha: return cha
        }
    }

    /// Get modifier by type
    func modifier(for stat: StatType) -> Int {
        return StatBlock.modifier(for: value(for: stat))
    }

    /// Apply modifiers to this stat block
    func applying(_ modifiers: StatBlock) -> StatBlock {
        return StatBlock(
            str: str + modifiers.str,
            dex: dex + modifiers.dex,
            con: con + modifiers.con,
            int: int + modifiers.int,
            wis: wis + modifiers.wis,
            cha: cha + modifiers.cha
        )
    }

    /// Clamp all stats to valid range (1-20)
    func clamped(min: Int = 1, max: Int = 20) -> StatBlock {
        return StatBlock(
            str: Swift.min(Swift.max(str, min), max),
            dex: Swift.min(Swift.max(dex, min), max),
            con: Swift.min(Swift.max(con, min), max),
            int: Swift.min(Swift.max(int, min), max),
            wis: Swift.min(Swift.max(wis, min), max),
            cha: Swift.min(Swift.max(cha, min), max)
        )
    }

    /// Total of all stats
    var total: Int {
        return str + dex + con + int + wis + cha
    }

    /// Generate random stats using 4d6 drop lowest method
    static func rollStats() -> StatBlock {
        return StatBlock(
            str: roll4d6DropLowest(),
            dex: roll4d6DropLowest(),
            con: roll4d6DropLowest(),
            int: roll4d6DropLowest(),
            wis: roll4d6DropLowest(),
            cha: roll4d6DropLowest()
        )
    }

    /// Roll 4d6 and drop the lowest die
    private static func roll4d6DropLowest() -> Int {
        var rolls = (0..<4).map { _ in Int.random(in: 1...6) }
        rolls.sort()
        rolls.removeFirst()  // Drop lowest
        return rolls.reduce(0, +)  // Sum remaining 3
    }
}

/// Secondary/derived stats calculated from primary stats and other factors
struct SecondaryStats: Codable {
    var hp: Int           // Current hit points
    var maxHP: Int        // Maximum hit points
    var stamina: Int      // Current stamina (physical resource)
    var maxStamina: Int   // Maximum stamina
    var mana: Int         // Current mana (magical resource)
    var maxMana: Int      // Maximum mana
    var initiative: Int   // Turn order bonus
    var movementSpeed: Int // Hexes per turn
    var armorClass: Int   // Defense rating

    /// Create secondary stats from primary stats and class
    static func calculate(
        from stats: StatBlock,
        characterClass: CharacterClass,
        race: Race,
        level: Int
    ) -> SecondaryStats {
        let conMod = StatBlock.modifier(for: stats.con)
        let dexMod = StatBlock.modifier(for: stats.dex)

        // HP = (hit die + CON modifier) at level 1, then (hit die roll + CON mod) per level
        let baseHP = characterClass.hitDie + conMod
        let levelHP = level > 1 ? (level - 1) * ((characterClass.hitDie / 2) + 1 + conMod) : 0
        let maxHP = max(1, baseHP + levelHP)

        // Stamina = CON * multiplier
        let maxStamina = Int(Double(stats.con) * characterClass.staminaMultiplier)

        // Mana = (INT + WIS) * multiplier
        let maxMana = Int(Double(stats.int + stats.wis) * characterClass.manaMultiplier)

        // Initiative = DEX modifier + class bonuses
        let initiative = dexMod

        // Movement speed from race, modified by DEX
        var movementSpeed = race.baseMovementSpeed
        if stats.dex >= 15 { movementSpeed += 1 }

        // Base AC + DEX modifier
        let armorClass = characterClass.baseArmorClass + dexMod

        return SecondaryStats(
            hp: maxHP,
            maxHP: maxHP,
            stamina: maxStamina,
            maxStamina: maxStamina,
            mana: maxMana,
            maxMana: maxMana,
            initiative: initiative,
            movementSpeed: movementSpeed,
            armorClass: armorClass
        )
    }

    /// Check if character is alive
    var isAlive: Bool {
        return hp > 0
    }

    /// Check if character is bloodied (below 50% HP)
    var isBloodied: Bool {
        return hp < maxHP / 2
    }

    /// Check if character is critical (below 30% HP)
    var isCritical: Bool {
        return hp < (maxHP * 3) / 10
    }

    /// HP as percentage (0.0 - 1.0)
    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(hp) / Double(maxHP)
    }
}

/// Personality traits (0-10 scale) that affect behavior
struct Personality: Codable {
    var greedy: Int     // Desire for wealth, loot distribution behavior
    var loyal: Int      // Commitment to guild, desertion resistance
    var brave: Int      // Willingness to face danger, aggression
    var cautious: Int   // Risk assessment, trap detection

    /// Random personality generation
    static func random() -> Personality {
        return Personality(
            greedy: Int.random(in: 0...10),
            loyal: Int.random(in: 0...10),
            brave: Int.random(in: 0...10),
            cautious: Int.random(in: 0...10)
        )
    }

    /// Balanced default personality
    static let balanced = Personality(greedy: 5, loyal: 5, brave: 5, cautious: 5)

    /// Get label for a personality trait value
    static func label(for value: Int, trait: String) -> String {
        switch trait {
        case "greedy":
            if value <= 3 { return "Generous" }
            if value <= 6 { return "Balanced" }
            return "Greedy"
        case "loyal":
            if value <= 3 { return "Mercenary" }
            if value <= 6 { return "Professional" }
            return "Devoted"
        case "brave":
            if value <= 3 { return "Cowardly" }
            if value <= 6 { return "Steady" }
            return "Reckless"
        case "cautious":
            if value <= 3 { return "Reckless" }
            if value <= 6 { return "Balanced" }
            return "Paranoid"
        default:
            return "Unknown"
        }
    }
}
