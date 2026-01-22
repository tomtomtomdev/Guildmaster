//
//  QuestManager.swift
//  Guildmaster
//
//  Manages the quest system, quest flow, and quest board
//

import Foundation
import Combine

/// Manages all quest-related operations
class QuestManager: ObservableObject {

    // MARK: - Singleton

    static let shared = QuestManager()

    // MARK: - Published State

    /// Available quests on the quest board
    @Published var availableQuests: [Quest] = []

    /// Quest currently being attempted
    @Published var activeQuest: Quest?

    /// Completed quests history
    @Published var completedQuests: [Quest] = []

    /// Failed quests history
    @Published var failedQuests: [Quest] = []

    /// Current quest flow state
    @Published var questFlowState: QuestFlowState = .idle

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Generate initial quests
        refreshQuestBoard()
    }

    // MARK: - Quest Board

    /// Refresh the quest board with new quests
    func refreshQuestBoard() {
        // Keep some existing quests, add new ones
        let maxQuests = 5
        let keepCount = min(2, availableQuests.count)

        // Keep first few quests
        var newQuests = Array(availableQuests.prefix(keepCount))

        // Add new quests until we reach max
        while newQuests.count < maxQuests {
            let quest = generateRandomQuest()
            // Avoid duplicates by title
            if !newQuests.contains(where: { $0.title == quest.title }) {
                newQuests.append(quest)
            }
        }

        availableQuests = newQuests
    }

    /// Generate a random quest from templates
    private func generateRandomQuest() -> Quest {
        let templates = Quest.allTemplates
        return templates.randomElement()!
    }

    /// Get quests filtered by difficulty
    func quests(forTier tier: DifficultyTier) -> [Quest] {
        return availableQuests.filter { $0.tier == tier }
    }

    // MARK: - Quest Flow

    /// Start a quest with the assigned party
    func startQuest(_ quest: Quest, party: [Character]) {
        guard quest.status == .available else { return }

        // Assign party to quest
        quest.assignedPartyIds = party.map { $0.id }
        quest.status = .inProgress
        quest.currentEncounterIndex = 0

        // Reset encounter completion
        for i in 0..<quest.encounters.count {
            quest.encounters[i].isCompleted = false
        }

        // Reset character ability uses for the quest
        for character in party {
            character.resetAbilityUses()
        }

        activeQuest = quest
        questFlowState = .questStartDialogue

        // Remove from available quests
        availableQuests.removeAll { $0.id == quest.id }
    }

    /// Advance quest flow to next state
    func advanceQuestFlow() {
        guard let quest = activeQuest else { return }

        switch questFlowState {
        case .idle:
            break

        case .questStartDialogue:
            questFlowState = .encounter

        case .encounter:
            // Combat will call completeCurrentEncounter when done
            break

        case .encounterComplete:
            if quest.hasMoreEncounters {
                quest.advanceToNextEncounter()
                questFlowState = .encounter
            } else {
                questFlowState = .victory
            }

        case .victory:
            completeQuest(success: true)

        case .defeat:
            completeQuest(success: false)

        case .debrief:
            questFlowState = .idle
            activeQuest = nil
        }
    }

    /// Mark the current encounter as complete
    func completeCurrentEncounter(victory: Bool, stats: CombatStatistics) {
        guard let quest = activeQuest else { return }

        // Update quest stats
        quest.turnsElapsed += stats.turnsElapsed
        quest.totalDamageDealt += stats.totalDamageDealt
        quest.totalDamageTaken += stats.totalDamageDealt  // Assuming symmetry
        quest.enemiesKilled += stats.enemiesKilled

        if victory {
            quest.encounters[quest.currentEncounterIndex].isCompleted = true
            questFlowState = .encounterComplete
        } else {
            questFlowState = .defeat
        }
    }

    /// Complete the quest (success or failure)
    private func completeQuest(success: Bool) {
        guard let quest = activeQuest else { return }

        if success {
            quest.markCompleted()
            completedQuests.append(quest)

            // Award rewards (handled by GuildManager)
            NotificationCenter.default.post(
                name: .questCompleted,
                object: nil,
                userInfo: ["quest": quest]
            )
        } else {
            quest.markFailed()
            failedQuests.append(quest)

            NotificationCenter.default.post(
                name: .questFailed,
                object: nil,
                userInfo: ["quest": quest]
            )
        }

        questFlowState = .debrief
    }

    /// Cancel/abandon the active quest
    func abandonQuest() {
        guard let quest = activeQuest else { return }

        quest.markFailed()
        failedQuests.append(quest)
        activeQuest = nil
        questFlowState = .idle

        NotificationCenter.default.post(
            name: .questAbandoned,
            object: nil,
            userInfo: ["quest": quest]
        )
    }

    /// Clear active quest without affecting history (for data reset)
    func clearActiveQuest() {
        activeQuest = nil
        questFlowState = .idle
        availableQuests = []
        completedQuests = []
        failedQuests = []
    }

    /// Get the current encounter for the active quest
    var currentEncounter: QuestEncounter? {
        return activeQuest?.currentEncounter
    }

    /// Generate enemies for the current encounter
    func generateCurrentEnemies() -> [Enemy] {
        return currentEncounter?.generateEnemies() ?? []
    }

    // MARK: - Statistics

    var totalQuestsCompleted: Int {
        return completedQuests.count
    }

    var totalQuestsFailed: Int {
        return failedQuests.count
    }

    var successRate: Double {
        let total = totalQuestsCompleted + totalQuestsFailed
        guard total > 0 else { return 0 }
        return Double(totalQuestsCompleted) / Double(total)
    }

    // MARK: - Save/Load

    func save() -> QuestManagerSaveData {
        return QuestManagerSaveData(
            availableQuests: availableQuests,
            completedQuests: completedQuests,
            failedQuests: failedQuests
        )
    }

    func load(from data: QuestManagerSaveData) {
        availableQuests = data.availableQuests
        completedQuests = data.completedQuests
        failedQuests = data.failedQuests
    }
}

// MARK: - Quest Flow State

enum QuestFlowState {
    case idle               // No active quest
    case questStartDialogue // Showing quest intro
    case encounter          // In combat encounter
    case encounterComplete  // Encounter finished, transitioning
    case victory            // Quest completed successfully
    case defeat             // Party wiped
    case debrief            // Showing results
}

// MARK: - Save Data

struct QuestManagerSaveData: Codable {
    let availableQuests: [Quest]
    let completedQuests: [Quest]
    let failedQuests: [Quest]
}

// MARK: - Notifications

extension Notification.Name {
    static let questCompleted = Notification.Name("questCompleted")
    static let questFailed = Notification.Name("questFailed")
    static let questAbandoned = Notification.Name("questAbandoned")
}
