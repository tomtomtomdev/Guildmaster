//
//  CaptainSystem.swift
//  Guildmaster
//
//  Captain mechanics - highest INT+CHA character leads
//  Captain can issue commands that influence ally AI
//

import Foundation
import Combine

/// Manages the captain system during combat
class CaptainSystem: ObservableObject {

    // MARK: - Published State

    @Published var captain: CombatUnit?
    @Published var currentCommand: CaptainCommand?
    @Published var commandHistory: [CommandRecord] = []

    // MARK: - Configuration

    /// Base compliance chance formula: (CHA * 5) + morale + relationship - stress
    static let baseComplianceModifier = 5

    /// Compliance thresholds
    static let guaranteedComplianceThreshold = 90  // 90%+ always complies
    static let guaranteedRefusalThreshold = 20      // 20%- always refuses

    // MARK: - Initialization

    init() {}

    // MARK: - Captain Selection

    /// Select the captain from a group (highest INT+CHA / 2)
    func selectCaptain(from units: [CombatUnit]) {
        captain = units
            .max { captainRating($0) < captainRating($1) }

        if let captain = captain {
            addToHistory(CommandRecord(
                command: nil,
                issuedBy: captain.id,
                turn: 0,
                message: "\(captain.name) takes command!"
            ))
        }
    }

    /// Calculate captain rating for a unit
    private func captainRating(_ unit: CombatUnit) -> Int {
        if let character = unit.character {
            return (character.stats.int + character.stats.cha) / 2
        }
        if let enemy = unit.enemy {
            return (enemy.stats.int + enemy.stats.cha) / 2
        }
        return 0
    }

    // MARK: - Command Issuance

    /// Issue a command from the captain
    func issueCommand(_ command: CaptainCommand, turn: Int) {
        guard let captain = captain else { return }

        currentCommand = command

        addToHistory(CommandRecord(
            command: command,
            issuedBy: captain.id,
            turn: turn,
            message: "\(captain.name): \"\(command.description)\""
        ))
    }

    /// Clear the current command
    func clearCommand() {
        currentCommand = nil
    }

    // MARK: - Command Compliance

    /// Check if a unit will comply with the captain's command
    func checkCompliance(unit: CombatUnit, command: CaptainCommand) -> ComplianceResult {
        guard let captain = captain else {
            return ComplianceResult(willComply: false, reason: "No captain")
        }

        // Captain always follows their own orders
        if unit.id == captain.id {
            return ComplianceResult(willComply: true, reason: "Captain's own order")
        }

        // Calculate compliance chance
        let chance = calculateComplianceChance(unit: unit, captain: captain, command: command)

        // Guaranteed thresholds
        if chance >= Self.guaranteedComplianceThreshold {
            return ComplianceResult(willComply: true, reason: "High loyalty", chance: chance)
        }
        if chance <= Self.guaranteedRefusalThreshold {
            return ComplianceResult(willComply: false, reason: "Distrust/fear", chance: chance)
        }

        // Roll for compliance
        let roll = Int.random(in: 1...100)
        let willComply = roll <= chance

        let reason = willComply ? "Follows orders" : "Acts independently"
        return ComplianceResult(willComply: willComply, reason: reason, chance: chance, roll: roll)
    }

    /// Calculate the compliance chance percentage
    private func calculateComplianceChance(unit: CombatUnit, captain: CombatUnit, command: CaptainCommand) -> Int {
        guard let character = unit.character else { return 50 }

        var chance = 0

        // Captain's CHA influence
        let captainCHA = captain.character?.stats.cha ?? 10
        chance += captainCHA * Self.baseComplianceModifier

        // Unit's morale
        chance += character.morale

        // Unit's loyalty personality trait
        chance += character.personality.loyal * 3

        // Stress reduces compliance
        chance -= character.stress / 2

        // INT affects understanding of tactical commands
        // Low INT might not understand complex orders
        if character.intelligenceTier == .low {
            switch command {
            case .focusFire, .protectAlly:
                chance -= 15  // Complex tactical commands
            case .advance, .retreat:
                chance += 5   // Simple commands easier
            case .defensive:
                chance -= 5
            }
        }

        // Brave/cowardly affects certain commands
        switch command {
        case .advance:
            chance += (character.personality.brave - 5) * 2  // Brave more likely to advance
        case .retreat:
            chance -= (character.personality.brave - 5) * 2  // Brave less likely to retreat
        case .defensive:
            chance += (character.personality.cautious - 5) * 2  // Cautious prefers defense
        default:
            break
        }

        // Clamp to 0-100
        return min(100, max(0, chance))
    }

    // MARK: - Command Effects on AI

    /// Apply command modifiers to AI scoring
    func applyCommandModifier(to option: ScoredOption, for unit: CombatUnit, state: BattleState) -> ScoredOption {
        guard let command = currentCommand else { return option }

        // Check if unit will comply
        let compliance = checkCompliance(unit: unit, command: command)
        guard compliance.willComply else { return option }

        var modified = option

        switch command {
        case .focusFire(let targetId):
            // Bonus for attacking the specified target
            if case .attack(let pos) = option.action {
                if let target = state.unit(at: pos), target.id == targetId {
                    modified.captainBonus = 50.0  // Strong preference for focus target
                }
            }
            if case .useAbility(_, let pos) = option.action {
                if let target = state.unit(at: pos), target.id == targetId {
                    modified.captainBonus = 40.0
                }
            }

        case .defensive:
            // Bonus for defensive actions, penalty for aggressive ones
            if case .defend = option.action {
                modified.captainBonus = 30.0
            }
            if case .move(let dest) = option.action {
                // Penalize moving toward enemies
                let enemies = state.enemies(for: unit)
                for enemy in enemies {
                    guard let enemyPos = enemy.position, let unitPos = unit.position else { continue }
                    if dest.distance(to: enemyPos) < unitPos.distance(to: enemyPos) {
                        modified.captainBonus = -20.0
                        break
                    }
                }
            }

        case .protectAlly(let allyId):
            // Bonus for staying near the protected ally
            if case .move(let dest) = option.action {
                if let ally = state.allUnits.first(where: { $0.id == allyId }),
                   let allyPos = ally.position {
                    let distance = dest.distance(to: allyPos)
                    if distance <= 1 {
                        modified.captainBonus = 30.0  // Adjacent to ally
                    } else if distance <= 2 {
                        modified.captainBonus = 15.0  // Close to ally
                    }
                }
            }
            // Bonus for attacking enemies near the protected ally
            if case .attack(let targetPos) = option.action {
                if let ally = state.allUnits.first(where: { $0.id == allyId }),
                   let allyPos = ally.position {
                    if targetPos.distance(to: allyPos) <= 2 {
                        modified.captainBonus = 25.0  // Attack threats to ally
                    }
                }
            }

        case .advance:
            // Bonus for moving toward enemies
            if case .move(let dest) = option.action {
                let enemies = state.enemies(for: unit)
                for enemy in enemies {
                    guard let enemyPos = enemy.position, let unitPos = unit.position else { continue }
                    if dest.distance(to: enemyPos) < unitPos.distance(to: enemyPos) {
                        modified.captainBonus = 20.0
                        break
                    }
                }
            }
            // Bonus for attacking
            if case .attack(_) = option.action {
                modified.captainBonus = 15.0
            }

        case .retreat:
            // Bonus for moving away from enemies
            if case .move(let dest) = option.action {
                let enemies = state.enemies(for: unit)
                var movingAway = true
                for enemy in enemies {
                    guard let enemyPos = enemy.position, let unitPos = unit.position else { continue }
                    if dest.distance(to: enemyPos) <= unitPos.distance(to: enemyPos) {
                        movingAway = false
                        break
                    }
                }
                if movingAway {
                    modified.captainBonus = 25.0
                }
            }
            // Penalty for attacking (should be retreating)
            if case .attack(_) = option.action {
                modified.captainBonus = -15.0
            }
        }

        return modified
    }

    // MARK: - History

    private func addToHistory(_ record: CommandRecord) {
        commandHistory.append(record)
        if commandHistory.count > 50 {
            commandHistory.removeFirst()
        }
    }
}

// MARK: - Supporting Types

/// Result of a compliance check
struct ComplianceResult {
    let willComply: Bool
    let reason: String
    var chance: Int = 0
    var roll: Int = 0

    var description: String {
        if roll > 0 {
            return "\(reason) (Needed: \(chance)%, Rolled: \(roll))"
        }
        return reason
    }
}

/// Record of a command issued
struct CommandRecord: Identifiable {
    let id = UUID()
    let command: CaptainCommand?
    let issuedBy: UUID
    let turn: Int
    let message: String
    let timestamp = Date()
}

// MARK: - UI Support

extension CaptainCommand {
    var iconName: String {
        switch self {
        case .focusFire: return "target"
        case .defensive: return "shield.fill"
        case .protectAlly: return "person.fill.checkmark"
        case .advance: return "arrow.forward.circle.fill"
        case .retreat: return "arrow.backward.circle.fill"
        }
    }
}
