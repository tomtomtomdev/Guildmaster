//
//  Relationships.swift
//  Guildmaster
//
//  Character relationship system with synergy abilities
//

import Foundation
import Combine

// MARK: - Relationship Manager

/// Manages relationships between all characters in the guild
class RelationshipManager: ObservableObject {

    // MARK: - Singleton

    static let shared = RelationshipManager()

    // MARK: - Published Properties

    /// Relationship matrix: [character1Id][character2Id] = value
    /// Values range from -100 (hostile) to +100 (bonded)
    @Published var relationships: [UUID: [UUID: Int]] = [:]

    /// History of relationship events
    @Published var eventHistory: [RelationshipEvent] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Get relationship value between two characters (-100 to +100)
    func getRelationship(between char1: UUID, and char2: UUID) -> Int {
        // Relationships are symmetric
        if let value = relationships[char1]?[char2] {
            return value
        }
        if let value = relationships[char2]?[char1] {
            return value
        }
        return 0  // Neutral by default
    }

    /// Get the relationship tier between two characters
    func getTier(between char1: UUID, and char2: UUID) -> RelationshipTier {
        let value = getRelationship(between: char1, and: char2)
        return RelationshipTier.tier(for: value)
    }

    /// Set relationship value (clamped to -100...100)
    func setRelationship(between char1: UUID, and char2: UUID, to value: Int) {
        let clamped = max(-100, min(100, value))

        // Store in both directions for easy lookup
        if relationships[char1] == nil {
            relationships[char1] = [:]
        }
        if relationships[char2] == nil {
            relationships[char2] = [:]
        }

        relationships[char1]?[char2] = clamped
        relationships[char2]?[char1] = clamped
    }

    /// Modify relationship value
    func modifyRelationship(between char1: UUID, and char2: UUID, by delta: Int) {
        let current = getRelationship(between: char1, and: char2)
        setRelationship(between: char1, and: char2, to: current + delta)
    }

    /// Record a relationship event
    func recordEvent(_ event: RelationshipEvent) {
        eventHistory.append(event)

        // Apply the relationship change
        modifyRelationship(
            between: event.character1Id,
            and: event.character2Id,
            by: event.type.valueChange
        )

        // Keep history manageable
        if eventHistory.count > 500 {
            eventHistory.removeFirst(100)
        }
    }

    /// Get all characters with a specific relationship tier to a character
    func getCharacters(relatedTo charId: UUID, at tier: RelationshipTier) -> [UUID] {
        guard let charRelationships = relationships[charId] else { return [] }

        return charRelationships.compactMap { (otherId, value) in
            if RelationshipTier.tier(for: value) == tier {
                return otherId
            }
            return nil
        }
    }

    /// Get bonded pairs (relationship >= 80)
    func getBondedPairs() -> [(UUID, UUID)] {
        var pairs: [(UUID, UUID)] = []
        var checked: Set<UUID> = []

        for (char1, relations) in relationships {
            for (char2, value) in relations {
                if value >= 80 && !checked.contains(char2) {
                    pairs.append((char1, char2))
                }
            }
            checked.insert(char1)
        }

        return pairs
    }

    /// Calculate party compatibility score (average of all relationships)
    func partyCompatibility(members: [UUID]) -> Double {
        guard members.count >= 2 else { return 1.0 }

        var total = 0
        var count = 0

        for i in 0..<members.count {
            for j in (i+1)..<members.count {
                total += getRelationship(between: members[i], and: members[j])
                count += 1
            }
        }

        guard count > 0 else { return 0.5 }

        // Convert from -100...100 to 0...1
        let average = Double(total) / Double(count)
        return (average + 100) / 200
    }

    /// Get synergy ability if characters are bonded
    func getSynergyAbility(char1: UUID, char2: UUID) -> SynergyAbility? {
        let tier = getTier(between: char1, and: char2)
        guard tier == .bonded else { return nil }

        // Would need Character class info to determine synergy type
        // Return a generic synergy for now
        return .combatSync
    }

    // MARK: - Save/Load

    func save() -> RelationshipSaveData {
        return RelationshipSaveData(
            relationships: relationships,
            eventHistory: eventHistory
        )
    }

    func load(from data: RelationshipSaveData) {
        relationships = data.relationships
        eventHistory = data.eventHistory
    }

    func reset() {
        relationships.removeAll()
        eventHistory.removeAll()
    }
}

// MARK: - Relationship Tier

/// Relationship level thresholds
enum RelationshipTier: String, CaseIterable {
    case hostile = "Hostile"        // -100 to -60
    case unfriendly = "Unfriendly"  // -59 to -30
    case neutral = "Neutral"        // -29 to +29
    case friendly = "Friendly"      // +30 to +59
    case trusted = "Trusted"        // +60 to +79
    case bonded = "Bonded"          // +80 to +100

    static func tier(for value: Int) -> RelationshipTier {
        switch value {
        case -100 ... -60: return .hostile
        case -59 ... -30: return .unfriendly
        case -29 ... 29: return .neutral
        case 30 ... 59: return .friendly
        case 60 ... 79: return .trusted
        default: return .bonded
        }
    }

    var color: String {
        switch self {
        case .hostile: return "red"
        case .unfriendly: return "orange"
        case .neutral: return "gray"
        case .friendly: return "blue"
        case .trusted: return "cyan"
        case .bonded: return "green"
        }
    }

    var description: String {
        switch self {
        case .hostile:
            return "These characters despise each other."
        case .unfriendly:
            return "There's tension between them."
        case .neutral:
            return "Professional acquaintances."
        case .friendly:
            return "They get along well."
        case .trusted:
            return "A strong friendship has formed."
        case .bonded:
            return "An unbreakable bond. They fight as one."
        }
    }

    /// Combat modifiers for this relationship tier
    var combatModifiers: RelationshipCombatModifiers {
        switch self {
        case .hostile:
            return RelationshipCombatModifiers(
                attackBonusNearby: -2,
                protectionPriority: -0.5,
                synergyEnabled: false
            )
        case .unfriendly:
            return RelationshipCombatModifiers(
                attackBonusNearby: -1,
                protectionPriority: -0.2,
                synergyEnabled: false
            )
        case .neutral:
            return RelationshipCombatModifiers()
        case .friendly:
            return RelationshipCombatModifiers(
                attackBonusNearby: 1,
                protectionPriority: 0.2,
                synergyEnabled: false
            )
        case .trusted:
            return RelationshipCombatModifiers(
                attackBonusNearby: 1,
                protectionPriority: 0.4,
                healingBonus: 0.1,
                synergyEnabled: false
            )
        case .bonded:
            return RelationshipCombatModifiers(
                attackBonusNearby: 2,
                protectionPriority: 0.8,
                healingBonus: 0.2,
                initiativeBonus: 1,
                synergyEnabled: true
            )
        }
    }
}

/// Combat modifiers based on relationship
struct RelationshipCombatModifiers {
    var attackBonusNearby: Int = 0      // Bonus when adjacent to this ally
    var protectionPriority: Double = 0  // Priority modifier for protecting
    var healingBonus: Double = 0        // Bonus healing given/received
    var initiativeBonus: Int = 0        // Initiative bonus when in same party
    var synergyEnabled: Bool = false    // Can use synergy abilities
}

// MARK: - Relationship Events

/// Types of events that affect relationships
enum RelationshipEventType: String, Codable {
    // Positive events
    case savedLife = "Saved Life"           // +20
    case foughtTogether = "Fought Together" // +3
    case sharedVictory = "Shared Victory"   // +5
    case healedWounds = "Healed Wounds"     // +5
    case protectedInBattle = "Protected"    // +8
    case gaveGift = "Gave Gift"             // +10
    case trainedTogether = "Trained"        // +2
    case complimented = "Complimented"      // +3

    // Negative events
    case abandonedInBattle = "Abandoned"    // -15
    case stoleKill = "Stole Kill"           // -5
    case friendlyFire = "Friendly Fire"     // -10
    case insult = "Insulted"                // -5
    case letDie = "Let Die"                 // -25
    case betrayed = "Betrayed"              // -30
    case competedForLoot = "Loot Dispute"   // -8

    // Neutral events
    case questTogether = "Quest Together"   // +1

    var valueChange: Int {
        switch self {
        case .savedLife: return 20
        case .foughtTogether: return 3
        case .sharedVictory: return 5
        case .healedWounds: return 5
        case .protectedInBattle: return 8
        case .gaveGift: return 10
        case .trainedTogether: return 2
        case .complimented: return 3
        case .abandonedInBattle: return -15
        case .stoleKill: return -5
        case .friendlyFire: return -10
        case .insult: return -5
        case .letDie: return -25
        case .betrayed: return -30
        case .competedForLoot: return -8
        case .questTogether: return 1
        }
    }

    var isPositive: Bool {
        return valueChange > 0
    }
}

/// A recorded relationship event
struct RelationshipEvent: Identifiable, Codable {
    let id: UUID
    let character1Id: UUID
    let character2Id: UUID
    let type: RelationshipEventType
    let timestamp: Date
    let context: String?

    init(char1: UUID, char2: UUID, type: RelationshipEventType, context: String? = nil) {
        self.id = UUID()
        self.character1Id = char1
        self.character2Id = char2
        self.type = type
        self.timestamp = Date()
        self.context = context
    }
}

// MARK: - Synergy Abilities

/// Special abilities unlocked by bonded relationships
enum SynergyAbility: String, CaseIterable, Codable {
    case combatSync = "Combat Sync"         // +2 attack when adjacent
    case guardianBond = "Guardian Bond"     // Take damage for ally
    case healingAura = "Healing Aura"       // Heal when adjacent at turn start
    case coordinatedStrike = "Coordinated"  // Extra attack when both hit same target
    case lastStand = "Last Stand"           // +5 all stats when bonded ally falls

    var description: String {
        switch self {
        case .combatSync:
            return "When adjacent to bonded ally, both gain +2 to attack rolls."
        case .guardianBond:
            return "Can redirect damage from bonded ally to self (50% reduction)."
        case .healingAura:
            return "At the start of each turn, heal bonded ally for 2 HP if adjacent."
        case .coordinatedStrike:
            return "If both bonded allies hit the same target this round, deal +50% damage."
        case .lastStand:
            return "When bonded ally is knocked out, gain +5 to all stats for 3 turns."
        }
    }

    /// Determine synergy based on class combinations
    static func forClasses(_ class1: CharacterClass, _ class2: CharacterClass) -> SynergyAbility {
        let classes = Set([class1, class2])

        // Warrior + Cleric = Guardian Bond
        if classes == Set([.warrior, .cleric]) {
            return .guardianBond
        }

        // Warrior + Warrior or Rogue + Rogue = Coordinated Strike
        if class1 == class2 && (class1 == .warrior || class1 == .rogue) {
            return .coordinatedStrike
        }

        // Cleric + anyone = Healing Aura
        if classes.contains(.cleric) {
            return .healingAura
        }

        // Mage + Rogue = Combat Sync (tactical coordination)
        if classes == Set([.mage, .rogue]) {
            return .combatSync
        }

        // Default
        return .combatSync
    }
}

// MARK: - Save Data

struct RelationshipSaveData: Codable {
    let relationships: [UUID: [UUID: Int]]
    let eventHistory: [RelationshipEvent]
}
