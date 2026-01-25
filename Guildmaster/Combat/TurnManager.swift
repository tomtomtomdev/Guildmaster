//
//  TurnManager.swift
//  Guildmaster
//
//  Manages turn order and combat flow
//

import Foundation
import SwiftUI
import Combine

/// Manages the turn-based combat system
class TurnManager: ObservableObject {

    // MARK: - Published State

    @Published var currentTurn: Int = 0
    @Published var currentPhase: TurnPhase = .notStarted
    @Published var turnOrder: [CombatUnit] = []
    @Published var currentUnitIndex: Int = 0

    @Published var hasMovedThisTurn: Bool = false
    @Published var hasActedThisTurn: Bool = false

    // MARK: - Computed Properties

    var currentUnit: CombatUnit? {
        guard currentUnitIndex >= 0 && currentUnitIndex < turnOrder.count else { return nil }
        return turnOrder[currentUnitIndex]
    }

    var isPlayerTurn: Bool {
        return currentUnit?.isPlayerControlled ?? false
    }

    var isCombatActive: Bool {
        return currentPhase != .notStarted && currentPhase != .combatEnded
    }

    // MARK: - Combat Units

    private var allUnits: [CombatUnit] = []
    private var deadUnits: [UUID] = []

    // MARK: - Callbacks

    var onTurnStart: ((CombatUnit) -> Void)?
    var onTurnEnd: ((CombatUnit) -> Void)?
    var onRoundStart: ((Int) -> Void)?
    var onCombatEnd: ((CombatResult) -> Void)?
    var onUnitDiedFromDOT: ((CombatUnit, StatusEffectType) -> Void)?

    // MARK: - Initialization

    init() {}

    // MARK: - Combat Setup

    /// Initialize combat with participating units
    func setupCombat(playerParty: [Character], enemies: [Enemy]) {
        allUnits = []
        deadUnits = []
        currentTurn = 0
        currentUnitIndex = 0

        // Create combat units for player characters
        for character in playerParty where character.isAlive {
            let unit = CombatUnit(character: character)
            allUnits.append(unit)
        }

        // Create combat units for enemies
        for enemy in enemies where enemy.isAlive {
            let unit = CombatUnit(enemy: enemy)
            allUnits.append(unit)
        }

        // Roll initiative and sort
        rollInitiative()
        currentPhase = .roundStart
    }

    /// Roll initiative for all units and sort turn order
    private func rollInitiative() {
        for i in 0..<allUnits.count {
            let dexMod = allUnits[i].dexterityModifier
            let roll = Int.random(in: 1...20)
            allUnits[i].initiativeRoll = roll + dexMod
            allUnits[i].initiativeTiebreaker = Int.random(in: 0...999)
        }

        // Sort by initiative (highest first), with stable tiebreaker
        turnOrder = allUnits.sorted { lhs, rhs in
            if lhs.initiativeRoll == rhs.initiativeRoll {
                return lhs.initiativeTiebreaker > rhs.initiativeTiebreaker
            }
            return lhs.initiativeRoll > rhs.initiativeRoll
        }
    }

    // MARK: - Turn Flow

    /// Start the next round
    func startRound() {
        currentTurn += 1
        currentUnitIndex = 0
        currentPhase = .roundStart

        // Reset round-based effects
        for unit in turnOrder where !deadUnits.contains(unit.id) {
            unit.hasActedThisRound = false
        }

        onRoundStart?(currentTurn)

        // Move to first unit's turn
        startNextTurn()
    }

    /// Start the current unit's turn
    func startNextTurn() {
        // Skip dead units
        while currentUnitIndex < turnOrder.count && deadUnits.contains(turnOrder[currentUnitIndex].id) {
            currentUnitIndex += 1
        }

        // Check if round is over
        if currentUnitIndex >= turnOrder.count {
            endRound()
            return
        }

        guard let unit = currentUnit else { return }

        // Reset turn state
        hasMovedThisTurn = false
        hasActedThisTurn = false

        // Process start-of-turn effects
        processStartOfTurn(unit)

        // Check if stunned or otherwise unable to act
        if unit.isStunned {
            endTurn()
            return
        }

        // Update phase
        currentPhase = unit.isPlayerControlled ? .playerTurn : .enemyTurn

        onTurnStart?(unit)
    }

    /// Process start-of-turn effects (DOTs, status ticks, etc.)
    private func processStartOfTurn(_ unit: CombatUnit) {
        // Tick status effect durations
        unit.tickStatusEffects()

        // Apply DOT damage
        if unit.isPoisoned {
            let poisonDamage = DiceRoll(count: 1, sides: 4, modifier: 0).roll()
            unit.takeDamage(poisonDamage)
            if !unit.isAlive {
                onUnitDiedFromDOT?(unit, .poisoned)
                markUnitDead(unit)
                return
            }
        }

        if unit.isBurning {
            let burnDamage = DiceRoll(count: 1, sides: 6, modifier: 0).roll()
            unit.takeDamage(burnDamage)
            if !unit.isAlive {
                onUnitDiedFromDOT?(unit, .burning)
                markUnitDead(unit)
                return
            }
        }
    }

    /// Record that the current unit has moved
    func recordMovement() {
        hasMovedThisTurn = true
    }

    /// Record that the current unit has taken an action
    func recordAction() {
        hasActedThisTurn = true
    }

    /// End the current unit's turn
    func endTurn() {
        // Process end-of-turn effects if unit exists
        if let unit = currentUnit {
            processEndOfTurn(unit)
            onTurnEnd?(unit)
        }

        // Always advance to next unit, even if current is nil
        currentUnitIndex += 1
        startNextTurn()
    }

    /// Process end-of-turn effects
    private func processEndOfTurn(_ unit: CombatUnit) {
        unit.hasActedThisRound = true

        // Clear defending status at end of turn
        // (Defending lasts until your next turn)
    }

    /// End the current round
    private func endRound() {
        currentPhase = .roundEnd

        // Check for combat end conditions
        if let result = checkCombatEnd() {
            endCombat(result: result)
        } else {
            // Start next round
            startRound()
        }
    }

    /// Check if combat should end
    private func checkCombatEnd() -> CombatResult? {
        let livingAllies = turnOrder.filter { $0.isPlayerControlled && !deadUnits.contains($0.id) }
        let livingEnemies = turnOrder.filter { !$0.isPlayerControlled && !deadUnits.contains($0.id) }

        if livingEnemies.isEmpty {
            return .victory
        }

        if livingAllies.isEmpty {
            return .defeat
        }

        // Check for max turns (prevent infinite combat)
        if currentTurn >= 50 {
            return .stalemate
        }

        return nil
    }

    /// End combat with a result
    func endCombat(result: CombatResult) {
        currentPhase = .combatEnded
        onCombatEnd?(result)
    }

    // MARK: - Unit Management

    /// Mark a unit as dead
    func markUnitDead(_ unit: CombatUnit) {
        guard !deadUnits.contains(unit.id) else { return }
        deadUnits.append(unit.id)

        // Check if combat should end
        if let result = checkCombatEnd() {
            endCombat(result: result)
        }
    }

    /// Get living units on a team
    func livingUnits(playerControlled: Bool) -> [CombatUnit] {
        return turnOrder.filter { $0.isPlayerControlled == playerControlled && !deadUnits.contains($0.id) }
    }

    /// Get all living units
    var livingUnits: [CombatUnit] {
        return turnOrder.filter { !deadUnits.contains($0.id) }
    }

    /// Check if a unit is dead
    func isDead(_ unit: CombatUnit) -> Bool {
        return deadUnits.contains(unit.id)
    }

    // MARK: - Haste Support

    /// Grant an extra action to the current unit (for Haste)
    func grantExtraAction() {
        hasActedThisTurn = false
    }
}

// MARK: - Turn Phase

/// Current phase of combat
enum TurnPhase: String {
    case notStarted = "Not Started"
    case roundStart = "Round Start"
    case playerTurn = "Player Turn"
    case enemyTurn = "Enemy Turn"
    case roundEnd = "Round End"
    case combatEnded = "Combat Ended"
}

// MARK: - Combat Result

/// Result of combat encounter
enum CombatResult {
    case victory       // All enemies defeated
    case defeat        // All allies defeated
    case retreat       // Party retreated
    case stalemate     // Too many turns, forced end

    var isVictory: Bool {
        return self == .victory
    }
}

// MARK: - Combat Unit

/// Wrapper for characters/enemies in combat
class CombatUnit: Identifiable, ObservableObject {
    let id: UUID
    let name: String
    let isPlayerControlled: Bool

    // Source reference
    weak var character: Character?
    var enemy: Enemy?

    // Combat stats (copied from source for manipulation during combat)
    @Published var currentHP: Int
    @Published var maxHP: Int
    @Published var currentStamina: Int
    @Published var maxStamina: Int
    @Published var currentMana: Int
    @Published var maxMana: Int
    @Published var armorClass: Int
    @Published var position: HexCoordinate?
    @Published var statusEffects: [StatusEffect] = []

    // Turn tracking
    var initiativeRoll: Int = 0
    var initiativeTiebreaker: Int = 0
    var hasActedThisRound: Bool = false

    // Stats
    let dexterityModifier: Int
    let intelligenceTier: IntelligenceTier
    let movementSpeed: Int

    // Abilities
    let abilities: [AbilityType]

    // MARK: - Initialization

    init(character: Character) {
        self.id = character.id
        self.name = character.name
        self.isPlayerControlled = true
        self.character = character

        self.currentHP = character.secondaryStats.hp
        self.maxHP = character.secondaryStats.maxHP
        self.currentStamina = character.secondaryStats.stamina
        self.maxStamina = character.secondaryStats.maxStamina
        self.currentMana = character.secondaryStats.mana
        self.maxMana = character.secondaryStats.maxMana
        self.armorClass = character.secondaryStats.armorClass
        self.position = character.combatPosition

        self.dexterityModifier = character.modifier(for: .dex)
        self.intelligenceTier = character.intelligenceTier
        self.movementSpeed = character.secondaryStats.movementSpeed

        self.abilities = character.abilities
        self.statusEffects = character.statusEffects
    }

    init(enemy: Enemy) {
        self.id = enemy.id
        self.name = enemy.name
        self.isPlayerControlled = false
        self.enemy = enemy

        self.currentHP = enemy.hp
        self.maxHP = enemy.maxHP
        self.currentStamina = 30  // Default for enemies
        self.maxStamina = 30
        self.currentMana = enemy.mana
        self.maxMana = enemy.maxMana
        self.armorClass = enemy.armorClass
        self.position = enemy.position

        self.dexterityModifier = StatBlock.modifier(for: enemy.stats.dex)
        self.intelligenceTier = enemy.intelligenceTier
        self.movementSpeed = enemy.movementSpeed

        self.abilities = enemy.abilities
        self.statusEffects = []
    }

    // MARK: - Computed Properties

    var isAlive: Bool { currentHP > 0 }
    var isBloodied: Bool { currentHP < maxHP / 2 }
    var isCritical: Bool { currentHP < (maxHP * 3) / 10 }
    var hpPercentage: Double { Double(currentHP) / Double(maxHP) }

    // Status checks
    var isStunned: Bool { statusEffects.contains { $0.type == .stunned } }
    var isPoisoned: Bool { statusEffects.contains { $0.type == .poisoned } }
    var isBurning: Bool { statusEffects.contains { $0.type == .burning } }
    var isHidden: Bool { statusEffects.contains { $0.type == .hidden } }
    var isHasted: Bool { statusEffects.contains { $0.type == .hasted } }
    var isDefending: Bool { statusEffects.contains { $0.type == .defending } }

    var effectiveAC: Int {
        var ac = armorClass
        if isDefending { ac += 2 }
        if statusEffects.contains(where: { $0.type == .shielded }) { ac += 5 }
        return ac
    }

    // MARK: - Actions

    func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)

        // Sync back to source
        character?.secondaryStats.hp = currentHP
        enemy?.hp = currentHP
    }

    func heal(_ amount: Int) {
        currentHP = min(maxHP, currentHP + amount)
        character?.secondaryStats.hp = currentHP
        enemy?.hp = currentHP
    }

    func applyStatus(_ effect: StatusEffect) {
        if let index = statusEffects.firstIndex(where: { $0.type == effect.type }) {
            if effect.remainingDuration > statusEffects[index].remainingDuration {
                statusEffects[index].remainingDuration = effect.remainingDuration
            }
        } else {
            statusEffects.append(effect)
        }
    }

    func removeStatus(_ type: StatusEffectType) {
        statusEffects.removeAll { $0.type == type }
    }

    func tickStatusEffects() {
        statusEffects = statusEffects.compactMap { effect in
            var updated = effect
            updated.remainingDuration -= 1
            return updated.remainingDuration > 0 ? updated : nil
        }
    }

    func spendStamina(_ amount: Int) {
        currentStamina = max(0, currentStamina - amount)
        character?.secondaryStats.stamina = currentStamina
    }

    func spendMana(_ amount: Int) {
        currentMana = max(0, currentMana - amount)
        character?.secondaryStats.mana = currentMana
        enemy?.mana = currentMana
    }
}
