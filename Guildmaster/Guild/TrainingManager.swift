//
//  TrainingManager.swift
//  Guildmaster
//
//  Basic training system for character development
//

import Foundation
import Combine

// MARK: - Training Manager

/// Manages training activities for guild members
class TrainingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TrainingManager()

    // MARK: - Published Properties

    /// Characters currently in training
    @Published var trainingSlots: [TrainingSlot] = []

    /// Available training activities
    @Published var availableActivities: [TrainingActivity] = TrainingActivity.allCases

    /// Maximum concurrent training slots
    let maxSlots = 4

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Start a training activity for a character
    func startTraining(character: Character, activity: TrainingActivity) -> Bool {
        // Check if character is already training
        guard !isTraining(character) else { return false }

        // Check if slots available
        guard trainingSlots.count < maxSlots else { return false }

        // Check if character meets requirements
        guard meetsRequirements(character: character, activity: activity) else { return false }

        // Create training slot
        let slot = TrainingSlot(
            characterId: character.id,
            activity: activity,
            startDay: GuildManager.shared.currentDay,
            daysRemaining: activity.duration
        )

        trainingSlots.append(slot)
        return true
    }

    /// Cancel training for a character
    func cancelTraining(for characterId: UUID) {
        trainingSlots.removeAll { $0.characterId == characterId }
    }

    /// Check if a character is currently training
    func isTraining(_ character: Character) -> Bool {
        return trainingSlots.contains { $0.characterId == character.id }
    }

    /// Get training slot for a character
    func getTrainingSlot(for characterId: UUID) -> TrainingSlot? {
        return trainingSlots.first { $0.characterId == characterId }
    }

    /// Advance training by one day
    func advanceDay() {
        var completedSlots: [TrainingSlot] = []

        for i in trainingSlots.indices {
            trainingSlots[i].daysRemaining -= 1

            if trainingSlots[i].daysRemaining <= 0 {
                completedSlots.append(trainingSlots[i])
            }
        }

        // Process completed training
        for slot in completedSlots {
            completeTraining(slot)
        }

        // Remove completed slots
        trainingSlots.removeAll { $0.daysRemaining <= 0 }
    }

    private func completeTraining(_ slot: TrainingSlot) {
        guard let character = GuildManager.shared.character(byId: slot.characterId) else { return }

        let result = calculateTrainingResult(character: character, activity: slot.activity)

        // Apply results
        switch result.type {
        case .xpGain:
            character.addXP(result.value)
        case .statBoost:
            if let stat = result.stat {
                boostStat(character: character, stat: stat, amount: result.value)
            }
        case .skillBoost:
            // Would need skill tracking - for now just XP
            character.addXP(result.value * 10)
        case .stressReduction:
            character.stress = max(0, character.stress - result.value)
        case .healing:
            character.heal(result.value)
        case .satisfactionGain:
            character.satisfaction = min(100, character.satisfaction + result.value)
        }

        // Relationship boost for sparring
        if slot.activity == .sparring, let partnerId = slot.partnerId {
            RelationshipManager.shared.recordEvent(
                RelationshipEvent(char1: character.id, char2: partnerId, type: .trainedTogether)
            )
        }
    }

    private func calculateTrainingResult(character: Character, activity: TrainingActivity) -> TrainingResult {
        // Base result from activity
        var result = activity.baseResult

        // Modify by INT (smarter characters learn faster)
        let intMod = character.stats.modifier(for: .int)
        if result.type == .xpGain {
            result.value += intMod * 5
        }

        // Random variance
        let variance = Int.random(in: -2...2)
        result.value = max(1, result.value + variance)

        return result
    }

    private func boostStat(character: Character, stat: StatType, amount: Int) {
        // Temporary stat boost (would need status effect system)
        // For now, we'll just give XP
        character.addXP(amount * 20)
    }

    private func meetsRequirements(character: Character, activity: TrainingActivity) -> Bool {
        switch activity {
        case .soloPractice:
            return true  // Anyone can practice alone
        case .sparring:
            // Need another character available
            return GuildManager.shared.roster.filter { !isTraining($0) }.count >= 2
        case .rest:
            return true  // Anyone can rest
        case .study:
            return character.stats.int >= 8  // Need basic intelligence
        case .meditation:
            return character.stats.wis >= 8  // Need basic wisdom
        case .physicalConditioning:
            return character.secondaryStats.hp > character.secondaryStats.maxHP / 2  // Need health
        }
    }

    // MARK: - Save/Load

    func save() -> TrainingSaveData {
        return TrainingSaveData(trainingSlots: trainingSlots)
    }

    func load(from data: TrainingSaveData) {
        trainingSlots = data.trainingSlots
    }

    func reset() {
        trainingSlots.removeAll()
    }
}

// MARK: - Training Activity

/// Types of training activities
enum TrainingActivity: String, CaseIterable, Codable {
    case soloPractice = "Solo Practice"
    case sparring = "Sparring"
    case rest = "Rest & Recovery"
    case study = "Study"
    case meditation = "Meditation"
    case physicalConditioning = "Physical Conditioning"

    var description: String {
        switch self {
        case .soloPractice:
            return "Practice combat techniques alone. Safe but less effective."
        case .sparring:
            return "Train with another guild member. More XP but risk of minor injury."
        case .rest:
            return "Take time to recover. Reduces stress and heals wounds."
        case .study:
            return "Study tactics and lore. Gain experience through knowledge."
        case .meditation:
            return "Meditate to restore mental clarity and reduce stress."
        case .physicalConditioning:
            return "Intense physical training. Temporarily boost physical stats."
        }
    }

    var icon: String {
        switch self {
        case .soloPractice: return "figure.martial.arts"
        case .sparring: return "person.2.fill"
        case .rest: return "bed.double.fill"
        case .study: return "book.fill"
        case .meditation: return "brain.head.profile"
        case .physicalConditioning: return "dumbbell.fill"
        }
    }

    var duration: Int {
        switch self {
        case .soloPractice: return 1
        case .sparring: return 1
        case .rest: return 2
        case .study: return 3
        case .meditation: return 1
        case .physicalConditioning: return 2
        }
    }

    var baseResult: TrainingResult {
        switch self {
        case .soloPractice:
            return TrainingResult(type: .xpGain, value: 25)
        case .sparring:
            return TrainingResult(type: .xpGain, value: 50)
        case .rest:
            return TrainingResult(type: .stressReduction, value: 30)
        case .study:
            return TrainingResult(type: .xpGain, value: 40)
        case .meditation:
            return TrainingResult(type: .stressReduction, value: 20)
        case .physicalConditioning:
            return TrainingResult(type: .statBoost, value: 2, stat: .str)
        }
    }

    var secondaryEffect: TrainingResult? {
        switch self {
        case .rest:
            return TrainingResult(type: .healing, value: 20)
        case .meditation:
            return TrainingResult(type: .satisfactionGain, value: 5)
        case .sparring:
            return TrainingResult(type: .healing, value: -5)  // Minor injury risk
        default:
            return nil
        }
    }

    var requiresPartner: Bool {
        return self == .sparring
    }
}

// MARK: - Training Slot

/// A character's training session
struct TrainingSlot: Identifiable, Codable {
    let id: UUID
    let characterId: UUID
    let activity: TrainingActivity
    let startDay: Int
    var daysRemaining: Int
    var partnerId: UUID?  // For sparring

    init(characterId: UUID, activity: TrainingActivity, startDay: Int, daysRemaining: Int, partnerId: UUID? = nil) {
        self.id = UUID()
        self.characterId = characterId
        self.activity = activity
        self.startDay = startDay
        self.daysRemaining = daysRemaining
        self.partnerId = partnerId
    }

    var progress: Double {
        let total = Double(activity.duration)
        let remaining = Double(daysRemaining)
        return max(0, (total - remaining) / total)
    }
}

// MARK: - Training Result

/// Result of a training session
struct TrainingResult {
    var type: ResultType
    var value: Int
    var stat: StatType?  // For stat boosts

    enum ResultType {
        case xpGain
        case statBoost
        case skillBoost
        case stressReduction
        case healing
        case satisfactionGain
    }
}

// MARK: - Save Data

struct TrainingSaveData: Codable {
    let trainingSlots: [TrainingSlot]
}
