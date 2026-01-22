//
//  RandomEncounters.swift
//  Guildmaster
//
//  Random encounter tables for procedural combat generation
//

import Foundation

// MARK: - Encounter Region

/// Different regions with unique encounter tables
enum EncounterRegion: String, CaseIterable, Codable {
    case forest = "Forest"
    case cave = "Cave"
    case ruins = "Ruins"
    case swamp = "Swamp"
    case mountain = "Mountain"
    case dungeon = "Dungeon"

    var description: String {
        switch self {
        case .forest:
            return "Dense woodlands filled with beasts and bandits."
        case .cave:
            return "Dark underground passages home to creatures that shun the light."
        case .ruins:
            return "Ancient structures haunted by undead and guarded by cultists."
        case .swamp:
            return "Treacherous marshlands where danger lurks beneath the murky water."
        case .mountain:
            return "Rocky heights populated by hardy creatures and territorial monsters."
        case .dungeon:
            return "Man-made labyrinths filled with traps and powerful enemies."
        }
    }

    var ambientHazards: [String] {
        switch self {
        case .forest:
            return ["Dense undergrowth", "Hidden pitfalls", "Poisonous plants"]
        case .cave:
            return ["Low visibility", "Unstable ceiling", "Slippery floors"]
        case .ruins:
            return ["Crumbling walls", "Hidden traps", "Cursed ground"]
        case .swamp:
            return ["Quicksand", "Toxic mist", "Disease-carrying insects"]
        case .mountain:
            return ["Thin air", "Rockslides", "Extreme cold"]
        case .dungeon:
            return ["Pit traps", "Poison darts", "Locked doors"]
        }
    }
}

// MARK: - Encounter Table Entry

/// A weighted entry in an encounter table
struct EncounterTableEntry: Codable {
    let enemies: [EnemyTemplate]
    let weight: Int  // Higher = more likely
    let minPartyLevel: Int
    let maxPartyLevel: Int

    init(enemies: [EnemyTemplate], weight: Int, minLevel: Int = 1, maxLevel: Int = 20) {
        self.enemies = enemies
        self.weight = weight
        self.minPartyLevel = minLevel
        self.maxPartyLevel = maxLevel
    }

    func isValidFor(partyLevel: Int) -> Bool {
        return partyLevel >= minPartyLevel && partyLevel <= maxPartyLevel
    }
}

// MARK: - Random Encounter Manager

/// Manages random encounter generation
class RandomEncounterManager {

    // MARK: - Singleton

    static let shared = RandomEncounterManager()

    private init() {}

    // MARK: - Encounter Tables

    /// Get encounter table for a region
    func encounterTable(for region: EncounterRegion) -> [EncounterTableEntry] {
        switch region {
        case .forest:
            return forestEncounters
        case .cave:
            return caveEncounters
        case .ruins:
            return ruinsEncounters
        case .swamp:
            return swampEncounters
        case .mountain:
            return mountainEncounters
        case .dungeon:
            return dungeonEncounters
        }
    }

    /// Generate a random encounter for a region
    func generateEncounter(region: EncounterRegion, partyLevel: Int) -> [EnemyTemplate] {
        let table = encounterTable(for: region)
        let validEntries = table.filter { $0.isValidFor(partyLevel: partyLevel) }

        guard !validEntries.isEmpty else {
            // Fallback to basic encounter
            return [.goblinScout, .goblinScout]
        }

        // Weighted random selection
        let totalWeight = validEntries.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 1...totalWeight)

        for entry in validEntries {
            roll -= entry.weight
            if roll <= 0 {
                return entry.enemies
            }
        }

        return validEntries.first?.enemies ?? [.goblinScout]
    }

    /// Generate a boss encounter for a region
    func generateBossEncounter(region: EncounterRegion, partyLevel: Int) -> [EnemyTemplate] {
        let bosses = bossTable(for: region)
        let validBosses = bosses.filter { $0.isValidFor(partyLevel: partyLevel) }

        guard let boss = validBosses.randomElement() else {
            return [.banditLord]
        }

        return boss.enemies
    }

    // MARK: - Forest Encounters

    private var forestEncounters: [EncounterTableEntry] {
        return [
            // Early game (levels 1-3)
            EncounterTableEntry(enemies: [.wolf, .wolf], weight: 15, minLevel: 1, maxLevel: 5),
            EncounterTableEntry(enemies: [.giantRat, .giantRat, .giantRat], weight: 15, minLevel: 1, maxLevel: 3),
            EncounterTableEntry(enemies: [.goblinScout, .goblinScout], weight: 20, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.wildBoar], weight: 10, minLevel: 1, maxLevel: 4),

            // Mid game (levels 3-6)
            EncounterTableEntry(enemies: [.bandit, .bandit, .goblinScout], weight: 15, minLevel: 3, maxLevel: 6),
            EncounterTableEntry(enemies: [.wolf, .wolf, .wolf], weight: 10, minLevel: 3, maxLevel: 6),
            EncounterTableEntry(enemies: [.goblinScout, .goblinScout, .goblinShaman], weight: 12, minLevel: 3, maxLevel: 7),

            // Late game (levels 5+)
            EncounterTableEntry(enemies: [.bandit, .bandit, .bandit], weight: 10, minLevel: 5, maxLevel: 10),
            EncounterTableEntry(enemies: [.orcWarrior, .goblinScout, .goblinScout], weight: 8, minLevel: 5, maxLevel: 10),
            EncounterTableEntry(enemies: [.ogre], weight: 5, minLevel: 6, maxLevel: 12)
        ]
    }

    // MARK: - Cave Encounters

    private var caveEncounters: [EncounterTableEntry] {
        return [
            // Early game
            EncounterTableEntry(enemies: [.giantRat, .giantRat], weight: 15, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.goblinScout, .goblinScout], weight: 15, minLevel: 1, maxLevel: 4),

            // Mid game
            EncounterTableEntry(enemies: [.goblinScout, .goblinScout, .goblinShaman], weight: 12, minLevel: 3, maxLevel: 6),
            EncounterTableEntry(enemies: [.orcWarrior, .goblinScout], weight: 10, minLevel: 4, maxLevel: 7),

            // Late game
            EncounterTableEntry(enemies: [.troll], weight: 8, minLevel: 5, maxLevel: 10),
            EncounterTableEntry(enemies: [.ogre, .goblinScout, .goblinScout], weight: 8, minLevel: 6, maxLevel: 10),
            EncounterTableEntry(enemies: [.orcWarrior, .orcWarrior], weight: 6, minLevel: 6, maxLevel: 12)
        ]
    }

    // MARK: - Ruins Encounters

    private var ruinsEncounters: [EncounterTableEntry] {
        return [
            // Early game
            EncounterTableEntry(enemies: [.skeleton, .skeleton], weight: 20, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.zombie, .zombie], weight: 15, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.darkCultist], weight: 10, minLevel: 2, maxLevel: 5),

            // Mid game
            EncounterTableEntry(enemies: [.skeleton, .skeleton, .zombie], weight: 12, minLevel: 3, maxLevel: 6),
            EncounterTableEntry(enemies: [.darkCultist, .skeleton, .skeleton], weight: 12, minLevel: 3, maxLevel: 7),
            EncounterTableEntry(enemies: [.ghoul, .skeleton], weight: 10, minLevel: 4, maxLevel: 8),

            // Late game
            EncounterTableEntry(enemies: [.ghoul, .ghoul], weight: 8, minLevel: 5, maxLevel: 10),
            EncounterTableEntry(enemies: [.wraith], weight: 6, minLevel: 6, maxLevel: 12),
            EncounterTableEntry(enemies: [.darkCultist, .darkCultist, .ghoul], weight: 6, minLevel: 6, maxLevel: 10)
        ]
    }

    // MARK: - Swamp Encounters

    private var swampEncounters: [EncounterTableEntry] {
        return [
            // Early game
            EncounterTableEntry(enemies: [.giantRat, .giantRat, .giantRat], weight: 15, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.zombie, .zombie], weight: 15, minLevel: 1, maxLevel: 5),

            // Mid game
            EncounterTableEntry(enemies: [.zombie, .zombie, .zombie], weight: 12, minLevel: 3, maxLevel: 6),
            EncounterTableEntry(enemies: [.troll], weight: 8, minLevel: 4, maxLevel: 8),
            EncounterTableEntry(enemies: [.ghoul, .zombie, .zombie], weight: 10, minLevel: 4, maxLevel: 8),

            // Late game
            EncounterTableEntry(enemies: [.troll, .zombie, .zombie], weight: 6, minLevel: 6, maxLevel: 10),
            EncounterTableEntry(enemies: [.wraith, .ghoul], weight: 5, minLevel: 7, maxLevel: 12)
        ]
    }

    // MARK: - Mountain Encounters

    private var mountainEncounters: [EncounterTableEntry] {
        return [
            // Early game
            EncounterTableEntry(enemies: [.wolf, .wolf], weight: 15, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.wildBoar, .wildBoar], weight: 12, minLevel: 1, maxLevel: 5),

            // Mid game
            EncounterTableEntry(enemies: [.orcWarrior, .orcWarrior], weight: 12, minLevel: 3, maxLevel: 7),
            EncounterTableEntry(enemies: [.ogre], weight: 10, minLevel: 4, maxLevel: 8),

            // Late game
            EncounterTableEntry(enemies: [.troll, .orcWarrior], weight: 8, minLevel: 5, maxLevel: 10),
            EncounterTableEntry(enemies: [.ogre, .orcWarrior, .orcWarrior], weight: 6, minLevel: 6, maxLevel: 12)
        ]
    }

    // MARK: - Dungeon Encounters

    private var dungeonEncounters: [EncounterTableEntry] {
        return [
            // Early game
            EncounterTableEntry(enemies: [.skeleton, .skeleton, .skeleton], weight: 15, minLevel: 1, maxLevel: 4),
            EncounterTableEntry(enemies: [.goblinScout, .goblinScout, .goblinShaman], weight: 12, minLevel: 2, maxLevel: 5),
            EncounterTableEntry(enemies: [.darkCultist, .skeleton, .skeleton], weight: 10, minLevel: 2, maxLevel: 5),

            // Mid game
            EncounterTableEntry(enemies: [.demonImp, .demonImp, .darkCultist], weight: 10, minLevel: 4, maxLevel: 8),
            EncounterTableEntry(enemies: [.ghoul, .skeleton, .skeleton], weight: 12, minLevel: 4, maxLevel: 8),
            EncounterTableEntry(enemies: [.orcWarrior, .orcWarrior, .goblinShaman], weight: 10, minLevel: 5, maxLevel: 8),

            // Late game
            EncounterTableEntry(enemies: [.wraith, .skeleton, .skeleton], weight: 6, minLevel: 6, maxLevel: 12),
            EncounterTableEntry(enemies: [.darkCultist, .darkCultist, .ghoul, .ghoul], weight: 5, minLevel: 7, maxLevel: 12),
            EncounterTableEntry(enemies: [.troll, .orcWarrior, .orcWarrior], weight: 5, minLevel: 7, maxLevel: 12)
        ]
    }

    // MARK: - Boss Tables

    private func bossTable(for region: EncounterRegion) -> [EncounterTableEntry] {
        switch region {
        case .forest:
            return [
                EncounterTableEntry(enemies: [.banditLord, .bandit, .bandit], weight: 10, minLevel: 3, maxLevel: 8),
                EncounterTableEntry(enemies: [.giantSpiderQueen], weight: 8, minLevel: 5, maxLevel: 12)
            ]
        case .cave:
            return [
                EncounterTableEntry(enemies: [.trollKing], weight: 10, minLevel: 5, maxLevel: 12),
                EncounterTableEntry(enemies: [.giantSpiderQueen, .goblinShaman], weight: 8, minLevel: 5, maxLevel: 10)
            ]
        case .ruins:
            return [
                EncounterTableEntry(enemies: [.darkPriest, .skeleton, .skeleton], weight: 10, minLevel: 4, maxLevel: 10),
                EncounterTableEntry(enemies: [.darkPriest, .ghoul, .ghoul], weight: 8, minLevel: 6, maxLevel: 12)
            ]
        case .swamp:
            return [
                EncounterTableEntry(enemies: [.trollKing, .zombie, .zombie], weight: 10, minLevel: 5, maxLevel: 12)
            ]
        case .mountain:
            return [
                EncounterTableEntry(enemies: [.orcWarlord, .orcWarrior, .orcWarrior], weight: 10, minLevel: 5, maxLevel: 12),
                EncounterTableEntry(enemies: [.trollKing, .ogre], weight: 8, minLevel: 7, maxLevel: 12)
            ]
        case .dungeon:
            return [
                EncounterTableEntry(enemies: [.darkPriest, .darkCultist, .darkCultist], weight: 10, minLevel: 5, maxLevel: 10),
                EncounterTableEntry(enemies: [.orcWarlord, .orcWarrior, .orcWarrior], weight: 8, minLevel: 6, maxLevel: 12),
                EncounterTableEntry(enemies: [.trollKing, .troll], weight: 6, minLevel: 8, maxLevel: 12)
            ]
        }
    }

    // MARK: - Difficulty Scaling

    /// Scale an encounter based on party strength
    func scaleEncounter(enemies: [EnemyTemplate], partyStrength: Int) -> [EnemyTemplate] {
        // Add reinforcements for strong parties
        if partyStrength > 4 {
            let reinforcements = enemies.prefix(min(2, enemies.count))
            return enemies + reinforcements
        }

        // Remove enemies for weak parties
        if partyStrength < 3 && enemies.count > 2 {
            return Array(enemies.prefix(enemies.count - 1))
        }

        return enemies
    }

    /// Calculate encounter difficulty rating
    func calculateDifficulty(enemies: [EnemyTemplate], partyLevel: Int, partySize: Int) -> EncounterDifficulty {
        let totalThreat = enemies.reduce(0) { $0 + $1.createEnemy().threatRating }
        let partyPower = partyLevel * partySize * 20

        let ratio = Double(totalThreat) / Double(partyPower)

        switch ratio {
        case ..<0.5:
            return .trivial
        case 0.5..<0.75:
            return .easy
        case 0.75..<1.0:
            return .medium
        case 1.0..<1.5:
            return .hard
        case 1.5..<2.0:
            return .deadly
        default:
            return .impossible
        }
    }
}

// MARK: - Encounter Difficulty

/// How difficult an encounter is relative to the party
enum EncounterDifficulty: String, CaseIterable {
    case trivial = "Trivial"
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case deadly = "Deadly"
    case impossible = "Impossible"

    var color: String {
        switch self {
        case .trivial: return "gray"
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .deadly: return "red"
        case .impossible: return "purple"
        }
    }

    var xpMultiplier: Double {
        switch self {
        case .trivial: return 0.5
        case .easy: return 0.75
        case .medium: return 1.0
        case .hard: return 1.25
        case .deadly: return 1.5
        case .impossible: return 2.0
        }
    }
}

// MARK: - Random Event

/// Random events that can occur during quests
enum RandomEvent: String, CaseIterable {
    case ambush = "Ambush"
    case treasure = "Treasure"
    case trap = "Trap"
    case shrine = "Shrine"
    case merchant = "Wandering Merchant"
    case rest = "Safe Haven"
    case reinforcements = "Enemy Reinforcements"
    case weather = "Weather Change"

    var description: String {
        switch self {
        case .ambush:
            return "Enemies attack from hiding! Initiative penalty."
        case .treasure:
            return "You discover a hidden cache of valuables."
        case .trap:
            return "A hidden trap is triggered!"
        case .shrine:
            return "An ancient shrine offers blessings to the worthy."
        case .merchant:
            return "A traveling merchant offers rare goods."
        case .rest:
            return "You find a safe place to rest and recover."
        case .reinforcements:
            return "More enemies arrive to join the fight!"
        case .weather:
            return "The weather takes a turn, affecting visibility."
        }
    }

    var weight: Int {
        switch self {
        case .ambush: return 15
        case .treasure: return 10
        case .trap: return 15
        case .shrine: return 5
        case .merchant: return 8
        case .rest: return 12
        case .reinforcements: return 10
        case .weather: return 10
        }
    }

    static func rollEvent() -> RandomEvent? {
        // 30% chance of random event
        guard Int.random(in: 1...100) <= 30 else { return nil }

        let totalWeight = RandomEvent.allCases.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 1...totalWeight)

        for event in RandomEvent.allCases {
            roll -= event.weight
            if roll <= 0 {
                return event
            }
        }

        return nil
    }
}
