//
//  GuildManager.swift
//  Guildmaster
//
//  Manages the guild state, roster, and overall game progression
//

import Foundation
import Combine

/// Manages all guild-related state and operations
class GuildManager: ObservableObject {

    // MARK: - Singleton

    static let shared = GuildManager()

    // MARK: - Published State

    /// Guild name
    @Published var guildName: String = "The Iron Wolves"

    /// Current gold
    @Published var gold: Int = 500

    /// Guild roster (hired adventurers)
    @Published var roster: [Character] = []

    /// Maximum roster size
    @Published var maxRosterSize: Int = 6

    /// Current game day
    @Published var currentDay: Int = 1

    /// Guild reputation with various factions
    @Published var reputation: [String: Int] = [
        "merchants": 0,
        "temple": 0,
        "guard": 0,
        "frontier": 0,
        "nobility": 0,
        "tavern": 0
    ]

    /// Guild statistics
    @Published var stats: GuildStatistics = GuildStatistics()

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()
    private let economyManager = EconomyManager.shared
    private let recruitmentManager = RecruitmentManager.shared

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Quest completion
        NotificationCenter.default.publisher(for: .questCompleted)
            .sink { [weak self] notification in
                if let quest = notification.userInfo?["quest"] as? Quest {
                    self?.handleQuestCompleted(quest)
                }
            }
            .store(in: &cancellables)

        // Quest failure
        NotificationCenter.default.publisher(for: .questFailed)
            .sink { [weak self] notification in
                if let quest = notification.userInfo?["quest"] as? Quest {
                    self?.handleQuestFailed(quest)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Roster Management

    /// Hire a character from the recruitment pool
    func hireCharacter(_ character: Character) -> Bool {
        guard roster.count < maxRosterSize else { return false }
        guard gold >= character.hireCost else { return false }

        gold -= character.hireCost
        character.hireDate = currentDay
        roster.append(character)

        stats.totalCharactersHired += 1

        return true
    }

    /// Dismiss a character from the roster
    func dismissCharacter(_ character: Character) {
        roster.removeAll { $0.id == character.id }
    }

    /// Get available party members (not on quest, alive)
    var availableRoster: [Character] {
        let questManager = QuestManager.shared
        let assignedIds = questManager.activeQuest?.assignedPartyIds ?? []
        return roster.filter { $0.isAlive && !assignedIds.contains($0.id) }
    }

    /// Get character by ID
    func character(byId id: UUID) -> Character? {
        return roster.first { $0.id == id }
    }

    // MARK: - Quest Rewards

    private func handleQuestCompleted(_ quest: Quest) {
        // Award gold
        gold += quest.rewards.gold
        stats.totalGoldEarned += quest.rewards.gold

        // Award XP to party members
        let partyIds = quest.assignedPartyIds
        let xpPerCharacter = quest.rewards.xp

        for id in partyIds {
            if let character = character(byId: id), character.isAlive {
                character.addXP(xpPerCharacter)
                character.questsCompleted += 1
                character.updateSatisfaction(questSuccess: true, partyDeaths: 0, daysRested: false)
            }
        }

        // Award reputation
        for (faction, change) in quest.rewards.reputationChanges {
            reputation[faction, default: 0] += change
        }

        // Update stats
        stats.totalQuestsCompleted += 1
        stats.totalEnemiesKilled += quest.enemiesKilled

        // TODO: Award items
    }

    private func handleQuestFailed(_ quest: Quest) {
        let partyIds = quest.assignedPartyIds

        for id in partyIds {
            if let character = character(byId: id) {
                character.questsFailed += 1
                character.updateSatisfaction(questSuccess: false, partyDeaths: 1, daysRested: false)

                // Check for desertion after failure
                if character.checkDesertion() {
                    dismissCharacter(character)
                    stats.totalDesertions += 1
                }
            }
        }

        stats.totalQuestsFailed += 1
    }

    // MARK: - Time Progression

    /// Advance to the next day
    func advanceDay() {
        currentDay += 1

        // Pay weekly costs on day 7, 14, 21, etc.
        if currentDay % 7 == 0 {
            processWeeklyCosts()
        }

        // Update character states
        for character in roster {
            character.daysSinceRest += 1

            // Apply fatigue if overworked
            if character.daysSinceRest > 7 {
                character.stress = min(100, character.stress + 5)
            }
        }

        // Refresh recruitment pool periodically
        if currentDay % 3 == 0 {
            recruitmentManager.refreshPool()
        }
    }

    /// Process weekly costs (salaries, upkeep)
    private func processWeeklyCosts() {
        let costs = economyManager.calculateWeeklyCosts(roster: roster)

        if gold >= costs.total {
            gold -= costs.total
            stats.totalExpenses += costs.total
        } else {
            // Can't afford costs - morale penalty
            let deficit = costs.total - gold
            gold = 0

            for character in roster {
                character.satisfaction = max(0, character.satisfaction - 10)
                character.morale = max(0, character.morale - 10)
            }

            stats.totalDeficits += deficit
        }
    }

    /// Rest a character (reset days since rest)
    func restCharacter(_ character: Character) {
        character.daysSinceRest = 0
        character.stress = max(0, character.stress - 20)
        character.satisfaction = min(100, character.satisfaction + 5)

        // Heal over rest
        let healAmount = character.secondaryStats.maxHP / 4
        character.heal(healAmount)
    }

    // MARK: - New Game

    /// Start a new game with initial setup
    func startNewGame(guildName: String) {
        self.guildName = guildName
        self.gold = 500
        self.roster = []
        self.currentDay = 1
        self.reputation = [
            "merchants": 0,
            "temple": 0,
            "guard": 0,
            "frontier": 0,
            "nobility": 0,
            "tavern": 0
        ]
        self.stats = GuildStatistics()

        // Generate starting roster
        roster.append(Character.generateRandom(forClass: .warrior, level: 1))
        roster.append(Character.generateRandom(forClass: .rogue, level: 1))
        roster.append(Character.generateRandom(forClass: .mage, level: 1))
        roster.append(Character.generateRandom(forClass: .cleric, level: 1))

        // Refresh recruitment pool
        recruitmentManager.refreshPool()

        // Refresh quest board
        QuestManager.shared.refreshQuestBoard()
    }

    // MARK: - Save/Load

    func save() -> GuildSaveData {
        return GuildSaveData(
            guildName: guildName,
            gold: gold,
            roster: roster,
            maxRosterSize: maxRosterSize,
            currentDay: currentDay,
            reputation: reputation,
            stats: stats
        )
    }

    func load(from data: GuildSaveData) {
        guildName = data.guildName
        gold = data.gold
        roster = data.roster
        maxRosterSize = data.maxRosterSize
        currentDay = data.currentDay
        reputation = data.reputation
        stats = data.stats
    }
}

// MARK: - Guild Statistics

struct GuildStatistics: Codable {
    var totalQuestsCompleted: Int = 0
    var totalQuestsFailed: Int = 0
    var totalGoldEarned: Int = 0
    var totalExpenses: Int = 0
    var totalDeficits: Int = 0
    var totalCharactersHired: Int = 0
    var totalDesertions: Int = 0
    var totalEnemiesKilled: Int = 0
    var totalCharacterDeaths: Int = 0
}

// MARK: - Save Data

struct GuildSaveData: Codable {
    let guildName: String
    let gold: Int
    let roster: [Character]
    let maxRosterSize: Int
    let currentDay: Int
    let reputation: [String: Int]
    let stats: GuildStatistics
}
