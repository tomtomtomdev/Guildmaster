//
//  RecruitmentManager.swift
//  Guildmaster
//
//  Manages the adventurer recruitment pool
//

import Foundation
import Combine

/// Manages adventurer generation and recruitment pool
class RecruitmentManager: ObservableObject {

    // MARK: - Singleton

    static let shared = RecruitmentManager()

    // MARK: - Published State

    /// Available adventurers for hire
    @Published var recruitPool: [Character] = []

    /// Pool size configuration
    @Published var minPoolSize: Int = 5
    @Published var maxPoolSize: Int = 10

    // MARK: - Initialization

    private init() {
        refreshPool()
    }

    // MARK: - Pool Management

    /// Refresh the recruitment pool with new adventurers
    func refreshPool() {
        // Keep some existing recruits (they don't instantly disappear)
        let keepCount = min(2, recruitPool.count)
        var newPool = Array(recruitPool.prefix(keepCount))

        // Fill up the pool
        let targetSize = Int.random(in: minPoolSize...maxPoolSize)

        while newPool.count < targetSize {
            let recruit = generateAdventurer()
            // Avoid duplicate names
            if !newPool.contains(where: { $0.name == recruit.name }) {
                newPool.append(recruit)
            }
        }

        recruitPool = newPool
    }

    /// Generate a new adventurer for recruitment
    func generateAdventurer(preferredClass: CharacterClass? = nil, level: Int = 1) -> Character {
        let character = Character.generateRandom(forClass: preferredClass, level: level)
        return character
    }

    /// Remove a character from the pool (when hired)
    func removeFromPool(_ character: Character) {
        recruitPool.removeAll { $0.id == character.id }
    }

    /// Get recruits filtered by class
    func recruits(forClass characterClass: CharacterClass) -> [Character] {
        return recruitPool.filter { $0.characterClass == characterClass }
    }

    /// Get recruits sorted by a specific stat
    func recruitsSorted(by stat: StatType, ascending: Bool = false) -> [Character] {
        return recruitPool.sorted { char1, char2 in
            let val1 = char1.stats.value(for: stat)
            let val2 = char2.stats.value(for: stat)
            return ascending ? val1 < val2 : val1 > val2
        }
    }

    /// Get recruits within a hire cost range
    func recruits(maxCost: Int) -> [Character] {
        return recruitPool.filter { $0.hireCost <= maxCost }
    }

    // MARK: - Quality Metrics

    /// Average stat total of current pool
    var averageQuality: Double {
        guard !recruitPool.isEmpty else { return 0 }
        let totalStats = recruitPool.reduce(0) { $0 + $1.stats.total }
        return Double(totalStats) / Double(recruitPool.count)
    }

    /// Highest INT in the pool
    var highestINT: Int {
        return recruitPool.map { $0.stats.int }.max() ?? 0
    }

    /// Get the "best" recruit by a simple heuristic
    var bestRecruit: Character? {
        return recruitPool.max { $0.stats.total < $1.stats.total }
    }

    /// Get the cheapest recruit
    var cheapestRecruit: Character? {
        return recruitPool.min { $0.hireCost < $1.hireCost }
    }

    // MARK: - Save/Load

    func save() -> RecruitmentSaveData {
        return RecruitmentSaveData(
            recruitPool: recruitPool,
            minPoolSize: minPoolSize,
            maxPoolSize: maxPoolSize
        )
    }

    func load(from data: RecruitmentSaveData) {
        recruitPool = data.recruitPool
        minPoolSize = data.minPoolSize
        maxPoolSize = data.maxPoolSize
    }
}

// MARK: - Save Data

struct RecruitmentSaveData: Codable {
    let recruitPool: [Character]
    let minPoolSize: Int
    let maxPoolSize: Int
}

