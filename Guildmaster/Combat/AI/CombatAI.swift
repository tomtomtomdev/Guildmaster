//
//  CombatAI.swift
//  Guildmaster
//
//  INT-driven AI system - the core innovation
//  Low INT: Makes obvious mistakes, random choices
//  Medium INT: Basic tactics, threat recognition
//  High INT: Optimal decisions, coordination
//

import Foundation

/// Protocol for AI decision making
protocol CombatAIProtocol {
    func decideAction(for unit: CombatUnit, in state: BattleState) -> AIAction
}

/// The main AI decision system using utility scoring
class CombatAI: CombatAIProtocol {

    // MARK: - Configuration

    /// Noise added to decisions based on INT
    static let lowINTNoise: Double = 0.35      // 35% random noise
    static let mediumINTNoise: Double = 0.15   // 15% random noise
    static let highINTNoise: Double = 0.0      // No noise - optimal play

    /// Low INT mistake chance
    static let lowINTMistakeChance: Double = 0.25  // 25% chance of obvious mistake

    /// Captain system references for command modifiers (one per team)
    weak var enemyCaptainSystem: CaptainSystem?
    weak var playerCaptainSystem: CaptainSystem?

    // MARK: - Main Decision Method

    func decideAction(for unit: CombatUnit, in state: BattleState) -> AIAction {
        // Get all possible actions
        let options = generateAllOptions(for: unit, in: state)

        // Score all options
        var scoredOptions = options.map { option -> ScoredOption in
            let score = scoreOption(option, for: unit, in: state)
            return ScoredOption(action: option, baseScore: score)
        }

        // Apply INT-based modifications
        scoredOptions = applyINTModifications(scoredOptions, unit: unit, state: state)

        // Apply captain command modifiers from the unit's team captain
        let captainSystem = unit.isPlayerControlled ? playerCaptainSystem : enemyCaptainSystem
        if let captainSystem = captainSystem {
            scoredOptions = scoredOptions.map { option in
                captainSystem.applyCommandModifier(to: option, for: unit, state: state)
            }
        }

        // Sort by final score
        scoredOptions.sort { $0.finalScore > $1.finalScore }

        // Return best option, or pass if none available
        return scoredOptions.first?.action ?? .pass
    }

    // MARK: - Option Generation

    private func generateAllOptions(for unit: CombatUnit, in state: BattleState) -> [AIAction] {
        var options: [AIAction] = []

        guard let position = unit.position else { return [.pass] }

        // Movement options
        if !state.hasMovedThisTurn {
            let reachableHexes = state.grid.reachableHexes(
                from: position,
                movement: unit.movementSpeed,
                blockedHexes: state.blockedHexes
            )

            for hex in reachableHexes where hex != position {
                options.append(.move(hex))
            }
        }

        // Attack options
        if !state.hasActedThisTurn {
            let enemies = state.enemies(for: unit)
            for enemy in enemies {
                guard let enemyPos = enemy.position else { continue }

                // Check if in attack range
                if position.distance(to: enemyPos) <= 1 {  // Melee range
                    options.append(.attack(enemyPos))
                }
            }

            // Ability options
            for ability in unit.abilities where canUseAbility(ability, unit: unit) {
                let targets = getValidTargets(for: ability, from: unit, in: state)
                for target in targets {
                    options.append(.useAbility(ability, target))
                }
            }

            // Defend option
            options.append(.defend)
        }

        // Always allow pass
        options.append(.pass)

        return options
    }

    private func canUseAbility(_ ability: AbilityType, unit: CombatUnit) -> Bool {
        let data = ability.data
        if data.isPassive { return false }

        switch data.resourceType {
        case .stamina:
            return unit.currentStamina >= data.resourceCost
        case .mana:
            return unit.currentMana >= data.resourceCost
        default:
            return true
        }
    }

    private func getValidTargets(for ability: AbilityType, from unit: CombatUnit, in state: BattleState) -> [HexCoordinate] {
        guard let position = unit.position else { return [] }

        let data = ability.data
        var targets: [HexCoordinate] = []

        switch data.targetType {
        case .selfOnly:
            targets.append(position)

        case .singleEnemy:
            let enemies = state.enemies(for: unit)
            for enemy in enemies {
                guard let enemyPos = enemy.position else { continue }
                if position.distance(to: enemyPos) <= data.range {
                    targets.append(enemyPos)
                }
            }

        case .singleAlly:
            let allies = state.allies(for: unit)
            for ally in allies {
                guard let allyPos = ally.position else { continue }
                if position.distance(to: allyPos) <= data.range {
                    targets.append(allyPos)
                }
            }

        case .areaOfEffect:
            // Can target any hex in range
            for hex in position.hexesInRange(data.range) {
                if state.grid.isValidCoordinate(hex) {
                    targets.append(hex)
                }
            }

        default:
            break
        }

        return targets
    }

    // MARK: - Scoring System

    private func scoreOption(_ option: AIAction, for unit: CombatUnit, in state: BattleState) -> Double {
        switch option {
        case .move(let destination):
            return scoreMovement(to: destination, for: unit, in: state)

        case .attack(let target):
            return scoreAttack(target: target, for: unit, in: state)

        case .useAbility(let ability, let target):
            return scoreAbility(ability, target: target, for: unit, in: state)

        case .defend:
            return scoreDefend(for: unit, in: state)

        case .pass:
            return 0.0
        }
    }

    // MARK: - Movement Scoring

    private func scoreMovement(to destination: HexCoordinate, for unit: CombatUnit, in state: BattleState) -> Double {
        var score = 0.0

        guard let currentPos = unit.position else { return 0.0 }

        let enemies = state.enemies(for: unit)
        let allies = state.allies(for: unit)

        // Find closest enemy
        var closestEnemyDistance = Int.max
        var closestEnemy: CombatUnit?
        for enemy in enemies {
            guard let enemyPos = enemy.position else { continue }
            let dist = destination.distance(to: enemyPos)
            if dist < closestEnemyDistance {
                closestEnemyDistance = dist
                closestEnemy = enemy
            }
        }

        // Score based on unit role
        if unit.character?.characterClass == .warrior || unit.character?.characterClass == .rogue {
            // Melee classes want to get closer to enemies
            if let enemy = closestEnemy, let enemyPos = enemy.position {
                let currentDist = currentPos.distance(to: enemyPos)
                let newDist = destination.distance(to: enemyPos)

                // Getting into melee range is high priority
                if newDist == 1 {
                    score += 40.0
                } else if newDist < currentDist {
                    score += 20.0  // Getting closer is good
                }
            }

            // Flanking opportunity
            if let enemy = closestEnemy, let enemyPos = enemy.position {
                let allyPositions = allies.compactMap { $0.position }
                if HexPathfinder.isFlanked(target: enemyPos, by: destination, allies: allyPositions) {
                    score += 25.0  // Flanking bonus
                }
            }

        } else {
            // Ranged/caster classes want to maintain distance
            if closestEnemyDistance < 2 {
                score -= 20.0  // Too close!
            } else if closestEnemyDistance >= 3 && closestEnemyDistance <= 6 {
                score += 15.0  // Good casting distance
            }

            // Stay near allies for protection
            let allyCount = allies.filter { ally in
                guard let allyPos = ally.position else { return false }
                return destination.distance(to: allyPos) <= 2
            }.count

            score += Double(allyCount) * 5.0
        }

        // Terrain considerations
        if let tile = state.grid.tile(at: destination) {
            if tile.terrain.providesHalfCover {
                score += 10.0  // Cover is good
            }
        }

        return score
    }

    // MARK: - Attack Scoring

    private func scoreAttack(target: HexCoordinate, for unit: CombatUnit, in state: BattleState) -> Double {
        guard let targetUnit = state.unit(at: target) else { return 0.0 }

        var score = 30.0  // Base value for attacking

        // Target priority based on threat
        let threatScore = calculateThreat(targetUnit)
        score += threatScore * 0.3

        // Low HP target bonus (finish them off)
        let hpPercentage = targetUnit.hpPercentage
        if hpPercentage < 0.25 {
            score += 30.0  // Finish off low HP targets
        } else if hpPercentage < 0.5 {
            score += 15.0  // Bloodied targets
        }

        // Flanking bonus
        if let unitPos = unit.position {
            let allies = state.allies(for: unit)
            let allyPositions = allies.compactMap { $0.position }
            if HexPathfinder.isFlanked(target: target, by: unitPos, allies: allyPositions) {
                score += 20.0
            }
        }

        // Healer priority (high INT behavior)
        if targetUnit.abilities.contains(.cureWounds) || targetUnit.abilities.contains(.massHealing) {
            score += 15.0  // Focus healers
        }

        return score
    }

    // MARK: - Ability Scoring

    private func scoreAbility(_ ability: AbilityType, target: HexCoordinate, for unit: CombatUnit, in state: BattleState) -> Double {
        let data = ability.data
        var score = 0.0

        switch ability {
        // Healing abilities
        case .cureWounds:
            if let targetUnit = state.unit(at: target) {
                let missingHP = targetUnit.maxHP - targetUnit.currentHP
                let hpPercentage = targetUnit.hpPercentage

                // Heal low HP allies urgently
                if hpPercentage < 0.3 {
                    score += 60.0 + Double(missingHP) * 0.5
                } else if hpPercentage < 0.6 {
                    score += 30.0 + Double(missingHP) * 0.3
                } else {
                    score -= 10.0  // Don't overheal
                }
            }

        case .massHealing:
            // Count allies that would benefit
            let allies = state.allies(for: unit)
            var totalValue = 0.0
            for ally in allies {
                guard let allyPos = ally.position else { continue }
                if target.distance(to: allyPos) <= data.aoeRadius {
                    let missingHP = ally.maxHP - ally.currentHP
                    if ally.hpPercentage < 0.5 {
                        totalValue += Double(missingHP) * 0.5
                    }
                }
            }
            score += totalValue

        // Damage abilities
        case .fireball:
            // Count enemies in AOE
            let enemies = state.enemies(for: unit)
            var enemiesHit = 0
            for enemy in enemies {
                guard let enemyPos = enemy.position else { continue }
                if target.distance(to: enemyPos) <= data.aoeRadius {
                    enemiesHit += 1
                }
            }
            score += Double(enemiesHit) * 25.0

            // Penalize if would hit allies
            let allies = state.allies(for: unit)
            for ally in allies {
                guard let allyPos = ally.position else { continue }
                if target.distance(to: allyPos) <= data.aoeRadius {
                    score -= 40.0  // Don't hit allies!
                }
            }

        case .magicMissile:
            // Reliable damage, good against low HP
            if let targetUnit = state.unit(at: target) {
                score += 25.0
                if targetUnit.hpPercentage < 0.3 {
                    score += 20.0  // Finish them off
                }
            }

        // Buffs
        case .bless:
            let allies = state.allies(for: unit)
            let alliesInRange = allies.filter { ally in
                guard let allyPos = ally.position else { return false }
                return target.distance(to: allyPos) <= data.aoeRadius
            }
            score += Double(alliesInRange.count) * 15.0

        case .haste:
            // Best on high-damage dealers
            if let targetUnit = state.unit(at: target) {
                if targetUnit.character?.characterClass == .warrior ||
                   targetUnit.character?.characterClass == .rogue {
                    score += 40.0
                } else {
                    score += 20.0
                }
            }

        // Defensive
        case .shield:
            if unit.hpPercentage < 0.5 {
                score += 30.0  // Need protection
            } else {
                score += 10.0
            }

        case .hide:
            // Good for rogues not in melee
            let enemies = state.enemies(for: unit)
            let nearbyEnemies = enemies.filter { enemy in
                guard let enemyPos = enemy.position, let unitPos = unit.position else { return false }
                return unitPos.distance(to: enemyPos) <= 1
            }
            if nearbyEnemies.isEmpty {
                score += 35.0  // Safe to hide
            } else {
                score -= 20.0  // Can't hide in melee
            }

        default:
            score += 15.0  // Default moderate value
        }

        // Resource efficiency
        let resourcePercentage: Double
        switch data.resourceType {
        case .mana:
            resourcePercentage = Double(unit.currentMana) / Double(max(1, unit.maxMana))
        case .stamina:
            resourcePercentage = Double(unit.currentStamina) / Double(max(1, unit.maxStamina))
        default:
            resourcePercentage = 1.0
        }

        // Penalize using abilities when low on resources (except emergencies)
        if resourcePercentage < 0.3 {
            score *= 0.7
        }

        return score
    }

    // MARK: - Defend Scoring

    private func scoreDefend(for unit: CombatUnit, in state: BattleState) -> Double {
        var score = 5.0  // Base low value

        // Better when surrounded
        let enemies = state.enemies(for: unit)
        let adjacentEnemies = enemies.filter { enemy in
            guard let enemyPos = enemy.position, let unitPos = unit.position else { return false }
            return unitPos.distance(to: enemyPos) <= 1
        }.count

        score += Double(adjacentEnemies) * 10.0

        // Better when low HP
        if unit.hpPercentage < 0.3 {
            score += 20.0
        }

        return score
    }

    // MARK: - Threat Calculation

    private func calculateThreat(_ unit: CombatUnit) -> Double {
        var threat = 0.0

        // Base threat from damage potential
        if let enemy = unit.enemy {
            threat += enemy.attackDamage.average
        } else {
            // Estimate from class
            switch unit.character?.characterClass {
            case .warrior: threat += 15.0
            case .rogue: threat += 20.0  // High burst damage
            case .mage: threat += 25.0   // AOE potential
            case .cleric: threat += 30.0 // Healing makes fights longer
            case .none: threat += 10.0
            }
        }

        // Healers are high priority
        if unit.abilities.contains(.cureWounds) || unit.abilities.contains(.massHealing) {
            threat += 20.0
        }

        // Casters with mana are dangerous
        if unit.currentMana > 10 && unit.abilities.contains(.fireball) {
            threat += 15.0
        }

        return threat
    }

    // MARK: - INT Modifications

    private func applyINTModifications(_ options: [ScoredOption], unit: CombatUnit, state: BattleState) -> [ScoredOption] {
        let tier = unit.intelligenceTier

        return options.map { option in
            var modified = option

            switch tier {
            case .low:
                modified = applyLowINTBehavior(modified, unit: unit, state: state)
            case .medium:
                modified = applyMediumINTBehavior(modified, unit: unit, state: state)
            case .high:
                modified = applyHighINTBehavior(modified, unit: unit, state: state)
            }

            return modified
        }
    }

    private func applyLowINTBehavior(_ option: ScoredOption, unit: CombatUnit, state: BattleState) -> ScoredOption {
        var modified = option

        // Add random noise
        let noise = Double.random(in: -Self.lowINTNoise...Self.lowINTNoise) * 50.0
        modified.noise = noise

        // Mistakes: Attack nearest instead of optimal
        if case .attack(_) = option.action {
            if Double.random(in: 0...1) < Self.lowINTMistakeChance {
                // Just attack whoever is closest
                modified.noise += Double.random(in: -20...20)
            }
        }

        // Mistakes: Use abilities randomly
        if case .useAbility(_, _) = option.action {
            if Double.random(in: 0...1) < Self.lowINTMistakeChance {
                // Random use - might use heal when not needed
                modified.noise += Double.random(in: -30...30)
            }
        }

        // Ignore flanking opportunities
        if case .move(let dest) = option.action {
            // Don't get flanking bonus (can't see it)
            if let unitPos = unit.position {
                let enemies = state.enemies(for: unit)
                for enemy in enemies {
                    guard let enemyPos = enemy.position else { continue }
                    let allies = state.allies(for: unit)
                    let allyPositions = allies.compactMap { $0.position }
                    if HexPathfinder.isFlanked(target: enemyPos, by: dest, allies: allyPositions) {
                        modified.noise -= 25.0  // Doesn't recognize flanking value
                    }
                }
            }
        }

        return modified
    }

    private func applyMediumINTBehavior(_ option: ScoredOption, unit: CombatUnit, state: BattleState) -> ScoredOption {
        var modified = option

        // Moderate noise
        let noise = Double.random(in: -Self.mediumINTNoise...Self.mediumINTNoise) * 30.0
        modified.noise = noise

        // Medium INT recognizes basic threats but might miss optimal targets
        // No additional modifications - uses base scoring

        return modified
    }

    private func applyHighINTBehavior(_ option: ScoredOption, unit: CombatUnit, state: BattleState) -> ScoredOption {
        var modified = option

        // No noise - optimal play
        modified.noise = 0.0

        // High INT bonuses: Recognize captain commands, coordinate better
        // These would be applied in a more complete implementation

        return modified
    }
}

// MARK: - Supporting Types

/// An action the AI can take
enum AIAction: Equatable {
    case move(HexCoordinate)
    case attack(HexCoordinate)
    case useAbility(AbilityType, HexCoordinate)
    case defend
    case pass
}

/// Scored option for decision making
struct ScoredOption {
    let action: AIAction
    var baseScore: Double
    var noise: Double = 0.0
    var captainBonus: Double = 0.0

    var finalScore: Double {
        return baseScore + noise + captainBonus
    }
}

/// Battle state snapshot for AI decision making
struct BattleState {
    let grid: HexGrid
    let allUnits: [CombatUnit]
    let currentUnit: CombatUnit
    let hasMovedThisTurn: Bool
    let hasActedThisTurn: Bool
    let blockedHexes: Set<HexCoordinate>
    let captainCommand: CaptainCommand?

    func enemies(for unit: CombatUnit) -> [CombatUnit] {
        return allUnits.filter { $0.isPlayerControlled != unit.isPlayerControlled && $0.isAlive }
    }

    func allies(for unit: CombatUnit) -> [CombatUnit] {
        return allUnits.filter { $0.isPlayerControlled == unit.isPlayerControlled && $0.isAlive && $0.id != unit.id }
    }

    func unit(at position: HexCoordinate) -> CombatUnit? {
        return allUnits.first { $0.position == position && $0.isAlive }
    }
}

/// Captain commands that can influence AI behavior
enum CaptainCommand {
    case focusFire(targetId: UUID)      // Everyone attack this target
    case defensive                       // Stay back, don't overextend
    case protectAlly(allyId: UUID)      // Stay near and protect
    case advance                         // Move toward enemies
    case retreat                         // Fall back

    var description: String {
        switch self {
        case .focusFire: return "Focus Fire!"
        case .defensive: return "Hold the line!"
        case .protectAlly: return "Protect them!"
        case .advance: return "Advance!"
        case .retreat: return "Fall back!"
        }
    }
}
