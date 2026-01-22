//
//  Traits.swift
//  Guildmaster
//
//  Acquired traits and personality combat modifiers
//

import Foundation

// MARK: - Acquired Traits

/// Traits that characters can acquire through gameplay
enum AcquiredTrait: String, CaseIterable, Codable {
    // Positive traits from success
    case confident = "Confident"            // Won 3+ quests in a row
    case veteranSlayer = "Veteran Slayer"   // Killed 50+ enemies total
    case heroicStand = "Heroic Stand"       // Survived at <10% HP
    case clutchHealer = "Clutch Healer"     // Saved ally from death 3+ times
    case tacticalGenius = "Tactical Genius" // MVP 5+ times
    case dragonSlayer = "Dragonslayer"      // Defeated a boss enemy solo
    case lucky = "Lucky"                    // Rolled nat 20 on 3+ death saves
    case ironWill = "Iron Will"             // Never fled from combat

    // Negative traits from failure/trauma
    case traumatized = "Traumatized"        // Witnessed 3+ ally deaths
    case scarred = "Scarred"                // Fell to 0 HP 5+ times
    case cowardly = "Cowardly"              // Fled from 3+ combats
    case unlucky = "Unlucky"                // Failed 3+ death saves
    case haunted = "Haunted"                // Sole survivor of TPK
    case bitterRival = "Bitter Rival"       // Major relationship conflict
    case grizzled = "Grizzled"              // Survived 10+ quests with injuries

    // Neutral/situational traits
    case berserker = "Berserker"            // Entered rage state 5+ times (low HP)
    case oneEyed = "One-Eyed"               // Critical injury (cosmetic)
    case scarVeteran = "Scar Veteran"       // 20+ battles survived
    case notorious = "Notorious"            // 100+ total kills

    /// Description of the trait
    var description: String {
        switch self {
        case .confident:
            return "Success breeds success. +5 to morale."
        case .veteranSlayer:
            return "A proven killer. +1 damage to all attacks."
        case .heroicStand:
            return "Survived against impossible odds. +2 to death saves."
        case .clutchHealer:
            return "Known for saving lives. Healing spells +20% effective."
        case .tacticalGenius:
            return "Natural leader. Party gains +1 initiative."
        case .dragonSlayer:
            return "Slayer of great beasts. +3 damage vs boss enemies."
        case .lucky:
            return "Fortune favors this one. Reroll one failed save per quest."
        case .ironWill:
            return "Never backs down. Immune to fear effects."

        case .traumatized:
            return "Haunted by loss. -10 to morale after ally deaths."
        case .scarred:
            return "Body tells a tale of near-death. -1 max HP per level."
        case .cowardly:
            return "Self-preservation instinct. May refuse dangerous orders."
        case .unlucky:
            return "Cursed by fate. -1 to all saving throws."
        case .haunted:
            return "Sole survivor guilt. -5 satisfaction base."
        case .bitterRival:
            return "Conflict with another. -2 to actions when rival nearby."
        case .grizzled:
            return "Worn down but experienced. +1 AC, -1 max stamina."

        case .berserker:
            return "Taps into fury. +3 damage when HP < 30%."
        case .oneEyed:
            return "Lost an eye. -1 ranged attacks, +1 perception (compensates)."
        case .scarVeteran:
            return "Battle-hardened. +1 to all saves."
        case .notorious:
            return "Feared by enemies. -2 enemy morale in combat."
        }
    }

    /// Whether this is a positive, negative, or neutral trait
    var valence: TraitValence {
        switch self {
        case .confident, .veteranSlayer, .heroicStand, .clutchHealer,
             .tacticalGenius, .dragonSlayer, .lucky, .ironWill:
            return .positive
        case .traumatized, .scarred, .cowardly, .unlucky,
             .haunted, .bitterRival:
            return .negative
        case .grizzled, .berserker, .oneEyed, .scarVeteran, .notorious:
            return .neutral
        }
    }

    /// Whether this is a positive trait
    var isPositive: Bool {
        return valence == .positive
    }

    /// Display name for UI
    var displayName: String {
        return rawValue
    }

    /// Combat stat modifiers from this trait
    var combatModifiers: TraitCombatModifiers {
        switch self {
        case .confident:
            return TraitCombatModifiers(moraleBonus: 5)
        case .veteranSlayer:
            return TraitCombatModifiers(damageBonus: 1)
        case .heroicStand:
            return TraitCombatModifiers(deathSaveBonus: 2)
        case .clutchHealer:
            return TraitCombatModifiers(healingBonus: 0.2)
        case .tacticalGenius:
            return TraitCombatModifiers(initiativeBonus: 1, partyInitiativeBonus: 1)
        case .dragonSlayer:
            return TraitCombatModifiers(bossDamageBonus: 3)
        case .lucky:
            return TraitCombatModifiers(rerollsPerQuest: 1)
        case .ironWill:
            return TraitCombatModifiers(fearImmune: true)

        case .traumatized:
            return TraitCombatModifiers(moraleBonus: -10)
        case .scarred:
            return TraitCombatModifiers(maxHPPerLevel: -1)
        case .cowardly:
            return TraitCombatModifiers(mayRefuseOrders: true)
        case .unlucky:
            return TraitCombatModifiers(saveBonus: -1)
        case .haunted:
            return TraitCombatModifiers(baseSatisfactionPenalty: 5)
        case .bitterRival:
            return TraitCombatModifiers(rivalPenalty: 2)

        case .grizzled:
            return TraitCombatModifiers(acBonus: 1, maxStaminaBonus: -1)
        case .berserker:
            return TraitCombatModifiers(lowHPDamageBonus: 3)
        case .oneEyed:
            return TraitCombatModifiers(rangedAttackBonus: -1)
        case .scarVeteran:
            return TraitCombatModifiers(saveBonus: 1)
        case .notorious:
            return TraitCombatModifiers(enemyMoralePenalty: 2)
        }
    }
}

/// Classification of trait effects
enum TraitValence: String, Codable {
    case positive
    case negative
    case neutral
}

/// Combat modifiers from traits
struct TraitCombatModifiers {
    var damageBonus: Int = 0
    var acBonus: Int = 0
    var initiativeBonus: Int = 0
    var partyInitiativeBonus: Int = 0
    var saveBonus: Int = 0
    var deathSaveBonus: Int = 0
    var healingBonus: Double = 0  // Percentage increase
    var maxHPPerLevel: Int = 0
    var maxStaminaBonus: Int = 0
    var moraleBonus: Int = 0
    var baseSatisfactionPenalty: Int = 0
    var bossDamageBonus: Int = 0
    var lowHPDamageBonus: Int = 0
    var rangedAttackBonus: Int = 0
    var rerollsPerQuest: Int = 0
    var rivalPenalty: Int = 0
    var enemyMoralePenalty: Int = 0
    var fearImmune: Bool = false
    var mayRefuseOrders: Bool = false
}

// MARK: - Personality Combat Modifiers

/// Extension to apply personality to combat AI decisions
extension Personality {

    /// Combat behavior modifiers based on personality
    var combatBehavior: PersonalityCombatBehavior {
        return PersonalityCombatBehavior(
            aggressionModifier: calculateAggression(),
            riskTolerance: calculateRiskTolerance(),
            selfPreservation: calculateSelfPreservation(),
            lootPriority: calculateLootPriority(),
            allyProtection: calculateAllyProtection()
        )
    }

    private func calculateAggression() -> Double {
        // Brave increases aggression, cautious decreases it
        let base = 0.5
        let braveBonus = Double(brave - 5) * 0.08
        let cautiousPenalty = Double(cautious - 5) * 0.05
        return max(0.1, min(1.0, base + braveBonus - cautiousPenalty))
    }

    private func calculateRiskTolerance() -> Double {
        // Brave increases risk-taking, cautious decreases it
        let base = 0.5
        let braveBonus = Double(brave - 5) * 0.1
        let cautiousPenalty = Double(cautious - 5) * 0.1
        return max(0.0, min(1.0, base + braveBonus - cautiousPenalty))
    }

    private func calculateSelfPreservation() -> Double {
        // Cowardly characters prioritize their own survival
        let base = 0.5
        let braveReduction = Double(brave - 5) * 0.08
        let cautiousBonus = Double(cautious - 5) * 0.06
        return max(0.1, min(1.0, base - braveReduction + cautiousBonus))
    }

    private func calculateLootPriority() -> Double {
        // Greedy characters prioritize loot over tactics
        let base = 0.3
        let greedyBonus = Double(greedy - 5) * 0.1
        return max(0.0, min(0.8, base + greedyBonus))
    }

    private func calculateAllyProtection() -> Double {
        // Loyal characters protect allies more
        let base = 0.5
        let loyalBonus = Double(loyal - 5) * 0.1
        return max(0.1, min(1.0, base + loyalBonus))
    }
}

/// Combat behavior modifiers from personality
struct PersonalityCombatBehavior {
    /// How aggressively the character attacks (0-1)
    let aggressionModifier: Double

    /// Willingness to take risks (0-1)
    let riskTolerance: Double

    /// Priority on self-survival (0-1)
    let selfPreservation: Double

    /// Priority on collecting loot (0-1)
    let lootPriority: Double

    /// Priority on protecting allies (0-1)
    let allyProtection: Double

    /// Get flee threshold HP percentage
    var fleeThreshold: Double {
        // Higher self-preservation = flee at higher HP
        return 0.1 + (selfPreservation * 0.25)
    }

    /// Whether to prioritize finishing low-HP enemies
    var executioner: Bool {
        return aggressionModifier > 0.6
    }

    /// Whether to hold back resources
    var conservative: Bool {
        return selfPreservation > 0.6 && riskTolerance < 0.4
    }
}

// MARK: - Trait Acquisition Checker

/// Checks if a character should acquire a trait based on their history
class TraitAcquisitionChecker {

    /// Check all potential trait acquisitions for a character
    static func checkForNewTraits(for character: Character, after event: TraitTriggerEvent) -> [AcquiredTrait] {
        var newTraits: [AcquiredTrait] = []

        switch event {
        case .questCompleted(let isVictory, let wasLastSurvivor):
            if isVictory && character.questsCompleted >= 3 {
                if !character.acquiredTraits.contains(AcquiredTrait.confident.rawValue) {
                    // Check for winning streak (would need additional tracking)
                    // For now, simplified check
                    if character.questsFailed == 0 {
                        newTraits.append(.confident)
                    }
                }
            }

            if wasLastSurvivor && !character.acquiredTraits.contains(AcquiredTrait.haunted.rawValue) {
                newTraits.append(.haunted)
            }

        case .enemyKilled(let totalKills, let wasBosskill):
            if totalKills >= 50 && !character.acquiredTraits.contains(AcquiredTrait.veteranSlayer.rawValue) {
                newTraits.append(.veteranSlayer)
            }

            if totalKills >= 100 && !character.acquiredTraits.contains(AcquiredTrait.notorious.rawValue) {
                newTraits.append(.notorious)
            }

            if wasBosskill && !character.acquiredTraits.contains(AcquiredTrait.dragonSlayer.rawValue) {
                // Would need to track if solo kill
                // Simplified: just acquiring it for boss kills for now
            }

        case .survivedLowHP(let hpPercentage):
            if hpPercentage < 0.1 && !character.acquiredTraits.contains(AcquiredTrait.heroicStand.rawValue) {
                newTraits.append(.heroicStand)
            }

        case .allyDied(let totalWitnessed):
            if totalWitnessed >= 3 && !character.acquiredTraits.contains(AcquiredTrait.traumatized.rawValue) {
                newTraits.append(.traumatized)
            }

        case .knockedOut(let totalTimes):
            if totalTimes >= 5 && !character.acquiredTraits.contains(AcquiredTrait.scarred.rawValue) {
                newTraits.append(.scarred)
            }

        case .savedAlly(let totalSaves):
            if totalSaves >= 3 && !character.acquiredTraits.contains(AcquiredTrait.clutchHealer.rawValue) {
                newTraits.append(.clutchHealer)
            }

        case .wonMVP(let totalMVPs):
            if totalMVPs >= 5 && !character.acquiredTraits.contains(AcquiredTrait.tacticalGenius.rawValue) {
                newTraits.append(.tacticalGenius)
            }

        case .battlesCompleted(let total):
            if total >= 20 && !character.acquiredTraits.contains(AcquiredTrait.scarVeteran.rawValue) {
                newTraits.append(.scarVeteran)
            }
        }

        return newTraits
    }
}

/// Events that can trigger trait acquisition
enum TraitTriggerEvent {
    case questCompleted(isVictory: Bool, wasLastSurvivor: Bool)
    case enemyKilled(totalKills: Int, wasBosskill: Bool)
    case survivedLowHP(hpPercentage: Double)
    case allyDied(totalWitnessed: Int)
    case knockedOut(totalTimes: Int)
    case savedAlly(totalSaves: Int)
    case wonMVP(totalMVPs: Int)
    case battlesCompleted(total: Int)
}

// MARK: - Character Extension for Traits

extension Character {
    /// Get all active acquired traits
    var activeAcquiredTraits: [AcquiredTrait] {
        return acquiredTraits.compactMap { AcquiredTrait(rawValue: $0) }
    }

    /// Calculate total combat modifiers from all acquired traits
    var traitCombatModifiers: TraitCombatModifiers {
        var combined = TraitCombatModifiers()

        for trait in activeAcquiredTraits {
            let mods = trait.combatModifiers
            combined.damageBonus += mods.damageBonus
            combined.acBonus += mods.acBonus
            combined.initiativeBonus += mods.initiativeBonus
            combined.saveBonus += mods.saveBonus
            combined.deathSaveBonus += mods.deathSaveBonus
            combined.healingBonus += mods.healingBonus
            combined.maxHPPerLevel += mods.maxHPPerLevel
            combined.maxStaminaBonus += mods.maxStaminaBonus
            combined.moraleBonus += mods.moraleBonus
            combined.bossDamageBonus += mods.bossDamageBonus
            combined.lowHPDamageBonus += mods.lowHPDamageBonus
            combined.rangedAttackBonus += mods.rangedAttackBonus
            combined.rerollsPerQuest += mods.rerollsPerQuest
            combined.enemyMoralePenalty += mods.enemyMoralePenalty
            if mods.fearImmune { combined.fearImmune = true }
            if mods.mayRefuseOrders { combined.mayRefuseOrders = true }
        }

        return combined
    }

    /// Add an acquired trait
    func addTrait(_ trait: AcquiredTrait) {
        if !acquiredTraits.contains(trait.rawValue) {
            acquiredTraits.append(trait.rawValue)
        }
    }

    /// Check and add any new traits based on an event
    func checkForNewTraits(event: TraitTriggerEvent) {
        let newTraits = TraitAcquisitionChecker.checkForNewTraits(for: self, after: event)
        for trait in newTraits {
            addTrait(trait)
        }
    }
}
