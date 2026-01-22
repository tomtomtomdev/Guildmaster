//
//  Skills.swift
//  Guildmaster
//
//  Utility skill system for non-combat challenges
//

import Foundation

// MARK: - Skill Types

/// The 8 utility skills
enum SkillType: String, CaseIterable, Codable {
    case perception = "Perception"      // WIS - Spotting traps, hidden enemies, clues
    case athletics = "Athletics"        // STR - Climbing, swimming, jumping, breaking
    case stealth = "Stealth"           // DEX - Sneaking, hiding, ambush
    case arcana = "Arcana"             // INT - Magic knowledge, identifying spells/items
    case medicine = "Medicine"         // WIS - Healing, stabilizing, identifying ailments
    case survival = "Survival"         // WIS - Tracking, foraging, navigation
    case persuasion = "Persuasion"     // CHA - Convincing, negotiating, charming
    case intimidation = "Intimidation"  // STR/CHA - Threatening, interrogating

    /// The primary stat for this skill
    var primaryStat: StatType {
        switch self {
        case .perception: return .wis
        case .athletics: return .str
        case .stealth: return .dex
        case .arcana: return .int
        case .medicine: return .wis
        case .survival: return .wis
        case .persuasion: return .cha
        case .intimidation: return .cha  // Can use STR optionally
        }
    }

    /// Alternative stat that can be used (if any)
    var alternateStat: StatType? {
        switch self {
        case .intimidation: return .str
        default: return nil
        }
    }

    var description: String {
        switch self {
        case .perception:
            return "Notice hidden things, spot traps, read people."
        case .athletics:
            return "Physical feats of strength and endurance."
        case .stealth:
            return "Move silently and remain unseen."
        case .arcana:
            return "Knowledge of magic, spells, and magical items."
        case .medicine:
            return "Treat wounds and identify ailments."
        case .survival:
            return "Track prey, navigate wilderness, forage."
        case .persuasion:
            return "Convince others through charm and reason."
        case .intimidation:
            return "Threaten and coerce through fear."
        }
    }

    var icon: String {
        switch self {
        case .perception: return "eye.fill"
        case .athletics: return "figure.run"
        case .stealth: return "moon.fill"
        case .arcana: return "sparkles"
        case .medicine: return "cross.case.fill"
        case .survival: return "leaf.fill"
        case .persuasion: return "text.bubble.fill"
        case .intimidation: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Skill Check

/// Result of a skill check
struct SkillCheckResult {
    let skill: SkillType
    let roll: Int              // d20 roll
    let modifier: Int          // Total modifier
    let total: Int             // Roll + modifier
    let dc: Int                // Difficulty class
    let success: Bool          // Did they pass?
    let criticalSuccess: Bool  // Nat 20
    let criticalFailure: Bool  // Nat 1

    var margin: Int {
        return total - dc
    }
}

/// Difficulty classes for skill checks
enum SkillDifficulty: Int, CaseIterable {
    case trivial = 5
    case easy = 10
    case medium = 15
    case hard = 20
    case veryHard = 25
    case nearlyImpossible = 30

    var name: String {
        switch self {
        case .trivial: return "Trivial"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        case .nearlyImpossible: return "Nearly Impossible"
        }
    }
}

// MARK: - Skill Manager

/// Handles skill checks and proficiency
class SkillManager {

    // MARK: - Singleton

    static let shared = SkillManager()

    private init() {}

    // MARK: - Skill Checks

    /// Perform a skill check for a character
    func check(
        skill: SkillType,
        for character: Character,
        dc: Int,
        advantage: Bool = false,
        disadvantage: Bool = false
    ) -> SkillCheckResult {
        // Roll d20 (or 2d20 for adv/dis)
        var roll: Int
        if advantage && !disadvantage {
            roll = max(Int.random(in: 1...20), Int.random(in: 1...20))
        } else if disadvantage && !advantage {
            roll = min(Int.random(in: 1...20), Int.random(in: 1...20))
        } else {
            roll = Int.random(in: 1...20)
        }

        // Calculate modifier
        let modifier = calculateModifier(skill: skill, for: character)
        let total = roll + modifier

        // Determine success
        let critSuccess = roll == 20
        let critFail = roll == 1
        let success = critSuccess || (!critFail && total >= dc)

        return SkillCheckResult(
            skill: skill,
            roll: roll,
            modifier: modifier,
            total: total,
            dc: dc,
            success: success,
            criticalSuccess: critSuccess,
            criticalFailure: critFail
        )
    }

    /// Calculate total skill modifier for a character
    func calculateModifier(skill: SkillType, for character: Character) -> Int {
        var modifier = 0

        // Base stat modifier
        let statMod = character.stats.modifier(for: skill.primaryStat)

        // Check if alternate stat is better (for intimidation)
        if let altStat = skill.alternateStat {
            let altMod = character.stats.modifier(for: altStat)
            modifier = max(statMod, altMod)
        } else {
            modifier = statMod
        }

        // Class skill bonus
        if isClassSkill(skill, for: character.characterClass) {
            modifier += 2
        }

        // Racial bonuses
        modifier += racialBonus(skill: skill, race: character.race)

        // Level bonus (half level, rounded down)
        modifier += character.level / 2

        // Trait bonuses
        modifier += traitBonus(skill: skill, for: character)

        return modifier
    }

    /// Check if a skill is a class skill (gets +2 bonus)
    func isClassSkill(_ skill: SkillType, for characterClass: CharacterClass) -> Bool {
        let classSkills: [CharacterClass: [SkillType]] = [
            .warrior: [.athletics, .intimidation],
            .rogue: [.stealth, .perception],
            .mage: [.arcana, .perception],
            .cleric: [.medicine, .persuasion]
        ]

        return classSkills[characterClass]?.contains(skill) ?? false
    }

    /// Get racial skill bonus
    func racialBonus(skill: SkillType, race: Race) -> Int {
        switch (race, skill) {
        case (.elf, .perception): return 2
        case (.elf, .stealth): return 1
        case (.dwarf, .survival): return 1
        case (.human, _): return 1  // Humans get +1 to all skills
        case (.orc, .intimidation): return 2
        case (.orc, .athletics): return 1
        default: return 0
        }
    }

    /// Get bonus from acquired traits
    func traitBonus(skill: SkillType, for character: Character) -> Int {
        var bonus = 0

        for traitName in character.acquiredTraits {
            guard let trait = AcquiredTrait(rawValue: traitName) else { continue }

            switch (trait, skill) {
            case (.veteranSlayer, .intimidation): bonus += 2
            case (.scarVeteran, .survival): bonus += 1
            case (.tacticalGenius, .perception): bonus += 1
            case (.oneEyed, .perception): bonus += 1  // Compensates
            default: break
            }
        }

        return bonus
    }

    // MARK: - Group Checks

    /// Perform a group skill check (majority must succeed)
    func groupCheck(
        skill: SkillType,
        for party: [Character],
        dc: Int
    ) -> (success: Bool, results: [SkillCheckResult]) {
        let results = party.map { check(skill: skill, for: $0, dc: dc) }
        let successes = results.filter { $0.success }.count
        let success = successes >= (party.count + 1) / 2  // Majority

        return (success, results)
    }

    /// Find the best character for a skill check
    func bestCharacter(for skill: SkillType, in party: [Character]) -> Character? {
        return party.max { calculateModifier(skill: skill, for: $0) < calculateModifier(skill: skill, for: $1) }
    }

    /// Get all skill modifiers for a character
    func allModifiers(for character: Character) -> [SkillType: Int] {
        var modifiers: [SkillType: Int] = [:]
        for skill in SkillType.allCases {
            modifiers[skill] = calculateModifier(skill: skill, for: character)
        }
        return modifiers
    }
}

// MARK: - Skill Challenge

/// A multi-skill challenge in quests
struct SkillChallenge: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let requiredChecks: [SkillCheck]
    let successesNeeded: Int
    var currentSuccesses: Int = 0
    var currentFailures: Int = 0
    var isComplete: Bool = false

    struct SkillCheck: Codable {
        let skill: SkillType
        let dc: Int
        let description: String
    }

    init(name: String, description: String, checks: [(SkillType, Int, String)], successesNeeded: Int) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.requiredChecks = checks.map { SkillCheck(skill: $0.0, dc: $0.1, description: $0.2) }
        self.successesNeeded = successesNeeded
    }

    mutating func recordResult(success: Bool) {
        if success {
            currentSuccesses += 1
        } else {
            currentFailures += 1
        }

        // Challenge ends when either threshold is met
        if currentSuccesses >= successesNeeded || currentFailures >= (requiredChecks.count - successesNeeded + 1) {
            isComplete = true
        }
    }

    var isSuccess: Bool {
        return isComplete && currentSuccesses >= successesNeeded
    }
}

// MARK: - Character Extension

extension Character {
    /// Get modifier for a specific skill
    func skillModifier(for skill: SkillType) -> Int {
        return SkillManager.shared.calculateModifier(skill: skill, for: self)
    }

    /// Perform a skill check
    func skillCheck(
        _ skill: SkillType,
        dc: Int,
        advantage: Bool = false,
        disadvantage: Bool = false
    ) -> SkillCheckResult {
        return SkillManager.shared.check(
            skill: skill,
            for: self,
            dc: dc,
            advantage: advantage,
            disadvantage: disadvantage
        )
    }

    /// Get best skill
    var bestSkill: (skill: SkillType, modifier: Int)? {
        let modifiers = SkillManager.shared.allModifiers(for: self)
        guard let best = modifiers.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }
}
