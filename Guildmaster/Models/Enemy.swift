//
//  Enemy.swift
//  Guildmaster
//
//  Enemy data model for combat encounters
//

import Foundation
import Combine

/// Represents an enemy in combat
class Enemy: Identifiable, ObservableObject {
    let id: UUID
    let name: String
    let enemyType: EnemyType
    let tier: EnemyTier

    // Stats
    let stats: StatBlock
    @Published var hp: Int
    let maxHP: Int
    @Published var mana: Int
    let maxMana: Int
    let armorClass: Int
    let movementSpeed: Int

    // Combat
    let abilities: [AbilityType]
    let attackDamage: DiceRoll
    let attackRange: Int  // 1 = melee, >1 = ranged

    // AI
    let intelligenceTier: IntelligenceTier
    let behaviorType: EnemyBehavior

    // Position
    @Published var position: HexCoordinate?

    // Threat rating for encounter balancing
    let threatRating: Int

    // Loot
    let goldDropMin: Int
    let goldDropMax: Int
    let lootTable: [LootDrop]

    // Special properties
    let isUndead: Bool
    let immunities: [DamageType]
    let vulnerabilities: [DamageType]
    let specialAbilities: [String]

    init(
        name: String,
        enemyType: EnemyType,
        tier: EnemyTier,
        stats: StatBlock,
        maxHP: Int,
        maxMana: Int = 0,
        armorClass: Int,
        movementSpeed: Int = 6,
        abilities: [AbilityType] = [],
        attackDamage: DiceRoll,
        attackRange: Int = 1,
        intelligenceTier: IntelligenceTier = .medium,
        behaviorType: EnemyBehavior = .aggressive,
        threatRating: Int,
        goldDrop: ClosedRange<Int> = 5...15,
        lootTable: [LootDrop] = [],
        isUndead: Bool = false,
        immunities: [DamageType] = [],
        vulnerabilities: [DamageType] = [],
        specialAbilities: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.enemyType = enemyType
        self.tier = tier
        self.stats = stats
        self.hp = maxHP
        self.maxHP = maxHP
        self.mana = maxMana
        self.maxMana = maxMana
        self.armorClass = armorClass
        self.movementSpeed = movementSpeed
        self.abilities = abilities
        self.attackDamage = attackDamage
        self.attackRange = attackRange
        self.intelligenceTier = intelligenceTier
        self.behaviorType = behaviorType
        self.position = nil
        self.threatRating = threatRating
        self.goldDropMin = goldDrop.lowerBound
        self.goldDropMax = goldDrop.upperBound
        self.lootTable = lootTable
        self.isUndead = isUndead
        self.immunities = immunities
        self.vulnerabilities = vulnerabilities
        self.specialAbilities = specialAbilities
    }

    var isAlive: Bool { hp > 0 }
    var isBloodied: Bool { hp < maxHP / 2 }

    /// Roll gold drop amount
    var goldDrop: Int {
        Int.random(in: goldDropMin...goldDropMax)
    }

    func takeDamage(_ amount: Int, type: DamageType = .physical) {
        var finalDamage = amount

        // Check immunities
        if immunities.contains(type) {
            finalDamage = 0
        }

        // Check vulnerabilities
        if vulnerabilities.contains(type) {
            finalDamage = Int(Double(finalDamage) * 1.5)
        }

        hp = max(0, hp - finalDamage)
    }
}

// MARK: - Enemy Type

enum EnemyType: String, Codable, CaseIterable {
    case beast = "Beast"
    case humanoid = "Humanoid"
    case undead = "Undead"
    case monster = "Monster"
    case demon = "Demon"
    case dragon = "Dragon"
}

// MARK: - Enemy Tier

enum EnemyTier: String, Codable {
    case minion = "Minion"       // Weak, dies quickly
    case common = "Common"       // Standard enemy
    case elite = "Elite"         // Tougher, more dangerous
    case boss = "Boss"           // Major encounter

    var hpMultiplier: Double {
        switch self {
        case .minion: return 0.5
        case .common: return 1.0
        case .elite: return 1.5
        case .boss: return 2.5
        }
    }
}

// MARK: - Enemy Behavior

enum EnemyBehavior: String, Codable {
    case aggressive = "Aggressive"     // Charges nearest enemy
    case defensive = "Defensive"       // Stays back, waits
    case supportive = "Supportive"     // Heals/buffs allies
    case cowardly = "Cowardly"         // Flees when bloodied
    case berserker = "Berserker"       // More aggressive when hurt
    case tactical = "Tactical"         // Focuses weak targets
}

// MARK: - Damage Type

enum DamageType: String, Codable {
    case physical = "Physical"
    case fire = "Fire"
    case ice = "Ice"
    case lightning = "Lightning"
    case poison = "Poison"
    case radiant = "Radiant"
    case necrotic = "Necrotic"
    case arcane = "Arcane"
}

// MARK: - Loot Drop

struct LootDrop: Codable {
    let itemId: String
    let dropChance: Double  // 0.0 - 1.0

    func shouldDrop() -> Bool {
        return Double.random(in: 0...1) < dropChance
    }
}

// MARK: - Enemy Templates

extension Enemy {

    /// Create an enemy from a template
    static func create(type: EnemyTemplate) -> Enemy {
        return type.createEnemy()
    }
}

/// Predefined enemy templates
enum EnemyTemplate: String, CaseIterable, Codable {
    // Common enemies (Threat 20-50)
    case goblinScout
    case bandit
    case giantRat
    case skeleton
    case wolf

    // Advanced enemies (Threat 60-100)
    case orcWarrior
    case ogre
    case darkCultist
    case troll
    case goblinShaman

    // Bosses (Threat 150+)
    case orcWarlord
    case trollKing
    case darkPriest
    case giantSpiderQueen
    case banditLord

    func createEnemy() -> Enemy {
        switch self {
        // COMMON ENEMIES
        case .goblinScout:
            return Enemy(
                name: "Goblin Scout",
                enemyType: .humanoid,
                tier: .common,
                stats: StatBlock(str: 8, dex: 14, con: 10, int: 8, wis: 8, cha: 6),
                maxHP: 15,
                armorClass: 13,
                movementSpeed: 7,
                attackDamage: DiceRoll(count: 1, sides: 6, modifier: 2),
                intelligenceTier: .low,
                behaviorType: .cowardly,
                threatRating: 25,
                goldDrop: 5...15,
                specialAbilities: ["Nimble Escape"]
            )

        case .bandit:
            return Enemy(
                name: "Bandit",
                enemyType: .humanoid,
                tier: .common,
                stats: StatBlock(str: 12, dex: 12, con: 12, int: 10, wis: 10, cha: 10),
                maxHP: 22,
                armorClass: 12,
                attackDamage: DiceRoll(count: 1, sides: 6, modifier: 1),
                intelligenceTier: .medium,
                behaviorType: .aggressive,
                threatRating: 30,
                goldDrop: 10...30
            )

        case .giantRat:
            return Enemy(
                name: "Giant Rat",
                enemyType: .beast,
                tier: .minion,
                stats: StatBlock(str: 7, dex: 15, con: 11, int: 2, wis: 10, cha: 4),
                maxHP: 7,
                armorClass: 12,
                movementSpeed: 6,
                attackDamage: DiceRoll(count: 1, sides: 4, modifier: 2),
                intelligenceTier: .low,
                behaviorType: .aggressive,
                threatRating: 20,
                goldDrop: 0...5,
                specialAbilities: ["Disease Bite"]
            )

        case .skeleton:
            return Enemy(
                name: "Skeleton",
                enemyType: .undead,
                tier: .common,
                stats: StatBlock(str: 10, dex: 14, con: 15, int: 6, wis: 8, cha: 5),
                maxHP: 13,
                armorClass: 13,
                attackDamage: DiceRoll(count: 1, sides: 6, modifier: 2),
                intelligenceTier: .low,
                behaviorType: .aggressive,
                threatRating: 25,
                goldDrop: 0...10,
                isUndead: true,
                vulnerabilities: [.radiant],
                specialAbilities: ["Vulnerable to Bludgeoning"]
            )

        case .wolf:
            return Enemy(
                name: "Wolf",
                enemyType: .beast,
                tier: .common,
                stats: StatBlock(str: 12, dex: 15, con: 12, int: 3, wis: 12, cha: 6),
                maxHP: 11,
                armorClass: 13,
                movementSpeed: 8,
                attackDamage: DiceRoll(count: 2, sides: 4, modifier: 2),
                intelligenceTier: .low,
                behaviorType: .aggressive,
                threatRating: 25,
                goldDrop: 0...5,
                specialAbilities: ["Pack Tactics"]
            )

        // ADVANCED ENEMIES
        case .orcWarrior:
            return Enemy(
                name: "Orc Warrior",
                enemyType: .humanoid,
                tier: .elite,
                stats: StatBlock(str: 16, dex: 12, con: 16, int: 7, wis: 11, cha: 10),
                maxHP: 45,
                armorClass: 13,
                attackDamage: DiceRoll(count: 1, sides: 12, modifier: 3),
                intelligenceTier: .low,
                behaviorType: .berserker,
                threatRating: 70,
                goldDrop: 20...50,
                specialAbilities: ["Aggressive"]
            )

        case .ogre:
            return Enemy(
                name: "Ogre",
                enemyType: .monster,
                tier: .elite,
                stats: StatBlock(str: 19, dex: 8, con: 16, int: 5, wis: 7, cha: 7),
                maxHP: 85,
                armorClass: 11,
                movementSpeed: 5,
                attackDamage: DiceRoll(count: 2, sides: 8, modifier: 4),
                intelligenceTier: .low,
                behaviorType: .aggressive,
                threatRating: 100,
                goldDrop: 30...60,
                specialAbilities: ["Brutal"]
            )

        case .darkCultist:
            return Enemy(
                name: "Dark Cultist",
                enemyType: .humanoid,
                tier: .common,
                stats: StatBlock(str: 10, dex: 10, con: 12, int: 14, wis: 14, cha: 12),
                maxHP: 33,
                maxMana: 30,
                armorClass: 12,
                abilities: [.magicMissile],
                attackDamage: DiceRoll(count: 1, sides: 4, modifier: 0),
                attackRange: 6,
                intelligenceTier: .medium,
                behaviorType: .supportive,
                threatRating: 60,
                goldDrop: 15...40,
                specialAbilities: ["Dark Blessing"]
            )

        case .troll:
            return Enemy(
                name: "Troll",
                enemyType: .monster,
                tier: .elite,
                stats: StatBlock(str: 18, dex: 13, con: 20, int: 7, wis: 9, cha: 7),
                maxHP: 84,
                armorClass: 15,
                attackDamage: DiceRoll(count: 1, sides: 6, modifier: 4),
                intelligenceTier: .low,
                behaviorType: .aggressive,
                threatRating: 90,
                goldDrop: 40...80,
                vulnerabilities: [.fire],
                specialAbilities: ["Regeneration", "Multi-Attack (3)"]
            )

        case .goblinShaman:
            return Enemy(
                name: "Goblin Shaman",
                enemyType: .humanoid,
                tier: .common,
                stats: StatBlock(str: 8, dex: 12, con: 10, int: 12, wis: 14, cha: 10),
                maxHP: 27,
                maxMana: 25,
                armorClass: 12,
                abilities: [.cureWounds],
                attackDamage: DiceRoll(count: 1, sides: 4, modifier: 0),
                attackRange: 4,
                intelligenceTier: .medium,
                behaviorType: .supportive,
                threatRating: 50,
                goldDrop: 15...35,
                specialAbilities: ["Healing"]
            )

        // BOSSES
        case .orcWarlord:
            return Enemy(
                name: "Orc Warlord",
                enemyType: .humanoid,
                tier: .boss,
                stats: StatBlock(str: 18, dex: 12, con: 18, int: 11, wis: 11, cha: 16),
                maxHP: 90,
                armorClass: 16,
                attackDamage: DiceRoll(count: 2, sides: 8, modifier: 5),
                intelligenceTier: .medium,
                behaviorType: .tactical,
                threatRating: 180,
                goldDrop: 100...200,
                specialAbilities: ["Rally", "Multi-Attack (2)"]
            )

        case .trollKing:
            return Enemy(
                name: "Troll King",
                enemyType: .monster,
                tier: .boss,
                stats: StatBlock(str: 20, dex: 12, con: 22, int: 8, wis: 10, cha: 10),
                maxHP: 120,
                armorClass: 16,
                attackDamage: DiceRoll(count: 2, sides: 6, modifier: 5),
                intelligenceTier: .low,
                behaviorType: .berserker,
                threatRating: 200,
                goldDrop: 150...300,
                vulnerabilities: [.fire],
                specialAbilities: ["Enhanced Regeneration", "Multi-Attack (3)"]
            )

        case .darkPriest:
            return Enemy(
                name: "Dark Priest",
                enemyType: .humanoid,
                tier: .boss,
                stats: StatBlock(str: 10, dex: 10, con: 14, int: 16, wis: 18, cha: 16),
                maxHP: 75,
                maxMana: 60,
                armorClass: 14,
                abilities: [.cureWounds, .massHealing, .magicMissile],
                attackDamage: DiceRoll(count: 1, sides: 6, modifier: 2),
                attackRange: 8,
                intelligenceTier: .high,
                behaviorType: .supportive,
                threatRating: 170,
                goldDrop: 120...250,
                specialAbilities: ["Summon Undead", "Dark Shield"]
            )

        case .giantSpiderQueen:
            return Enemy(
                name: "Giant Spider Queen",
                enemyType: .beast,
                tier: .boss,
                stats: StatBlock(str: 16, dex: 16, con: 16, int: 4, wis: 12, cha: 6),
                maxHP: 100,
                armorClass: 14,
                movementSpeed: 7,
                attackDamage: DiceRoll(count: 2, sides: 8, modifier: 4),
                intelligenceTier: .low,
                behaviorType: .tactical,
                threatRating: 160,
                goldDrop: 80...150,
                specialAbilities: ["Web", "Poison Bite", "Summon Spiders"]
            )

        case .banditLord:
            return Enemy(
                name: "Bandit Lord",
                enemyType: .humanoid,
                tier: .boss,
                stats: StatBlock(str: 16, dex: 16, con: 14, int: 14, wis: 12, cha: 16),
                maxHP: 80,
                armorClass: 15,
                attackDamage: DiceRoll(count: 1, sides: 10, modifier: 4),
                intelligenceTier: .high,
                behaviorType: .tactical,
                threatRating: 150,
                goldDrop: 100...250,
                specialAbilities: ["Leadership", "Parry", "Dirty Fighting"]
            )
        }
    }
}
