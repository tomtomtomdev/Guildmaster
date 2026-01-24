//
//  CombatManager.swift
//  Guildmaster
//
//  Central manager for all combat operations
//

import Foundation
import SwiftUI
import Combine

/// Manages combat state, actions, and resolution
class CombatManager: ObservableObject {

    // MARK: - Singleton

    static let shared = CombatManager()

    // MARK: - Published State

    @Published var state: CombatState = .notInCombat
    @Published var grid: HexGrid
    @Published var turnManager: TurnManager

    // Combat participants
    @Published var playerUnits: [CombatUnit] = []
    @Published var enemyUnits: [CombatUnit] = []

    // UI state
    @Published var selectedAbility: AbilityType?
    @Published var targetingMode: TargetingMode = .none
    @Published var validTargets: [HexCoordinate] = []
    @Published var combatLog: [CombatLogEntry] = []

    // Combat statistics
    @Published var combatStats: CombatStatistics = CombatStatistics()

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        self.grid = HexGrid()
        self.turnManager = TurnManager()
        setupTurnManagerCallbacks()
        setupAISystems()
    }

    private func setupTurnManagerCallbacks() {
        turnManager.onTurnStart = { [weak self] unit in
            self?.handleTurnStart(unit)
        }

        turnManager.onTurnEnd = { [weak self] unit in
            self?.handleTurnEnd(unit)
        }

        turnManager.onCombatEnd = { [weak self] result in
            self?.handleCombatEnd(result)
        }

        turnManager.onUnitDiedFromDOT = { [weak self] unit, effectType in
            let cause = effectType == .poisoned ? "poison" : "burning"
            self?.addLogEntry("\(unit.name) succumbs to \(cause)!", type: .death)
            self?.combatStats.kills += 1
            if unit.isPlayerControlled {
                self?.combatStats.partyDeaths += 1
            } else {
                self?.combatStats.enemiesKilled += 1
            }
            if let pos = unit.position, var tile = self?.grid.tiles[pos] {
                tile.occupant = nil
                self?.grid.tiles[pos] = tile
            }
        }
    }

    // MARK: - Combat Setup

    /// Start a new combat encounter
    func startCombat(
        playerParty: [Character],
        enemies: [Enemy],
        terrain: TerrainTemplate = .basicArena
    ) {
        // Reset state
        state = .settingUp
        combatLog.removeAll()
        combatStats = CombatStatistics()

        // Setup grid with terrain
        grid = HexGrid(width: terrain.width, height: terrain.height)
        applyTerrain(terrain)

        // Position combatants
        positionPlayerParty(playerParty)
        positionEnemies(enemies)

        // Initialize turn manager
        turnManager.setupCombat(playerParty: playerParty, enemies: enemies)

        // Cache units
        playerUnits = turnManager.livingUnits(playerControlled: true)
        enemyUnits = turnManager.livingUnits(playerControlled: false)

        // Select captains for each team
        enemyCaptainSystem.selectCaptain(from: enemyUnits)
        playerCaptainSystem.selectCaptain(from: playerUnits)

        // Start combat
        state = .inProgress
        addLogEntry("Combat begins!", type: .system)
        turnManager.startRound()
    }

    private func applyTerrain(_ template: TerrainTemplate) {
        for (coord, terrain) in template.terrainOverrides {
            if var tile = grid.tiles[coord] {
                tile.terrain = terrain
                tile.isBlocked = terrain == .wall
                grid.tiles[coord] = tile
            }
        }
    }

    private func positionPlayerParty(_ party: [Character]) {
        let startPositions = [
            HexCoordinate(col: 1, row: 5),
            HexCoordinate(col: 1, row: 6),
            HexCoordinate(col: 2, row: 5),
            HexCoordinate(col: 2, row: 6)
        ]

        for (index, character) in party.prefix(4).enumerated() {
            let pos = startPositions[index]
            character.combatPosition = pos
            if var tile = grid.tiles[pos] {
                tile.occupant = character.id
                grid.tiles[pos] = tile
            }
        }
    }

    private func positionEnemies(_ enemies: [Enemy]) {
        let startPositions = [
            HexCoordinate(col: 8, row: 5),
            HexCoordinate(col: 8, row: 6),
            HexCoordinate(col: 7, row: 5),
            HexCoordinate(col: 7, row: 6),
            HexCoordinate(col: 8, row: 4),
            HexCoordinate(col: 8, row: 7)
        ]

        for (index, enemy) in enemies.prefix(6).enumerated() {
            let pos = startPositions[index]
            enemy.position = pos
            if var tile = grid.tiles[pos] {
                tile.occupant = enemy.id
                grid.tiles[pos] = tile
            }
        }
    }

    // MARK: - Turn Handling

    private func handleTurnStart(_ unit: CombatUnit) {
        addLogEntry("\(unit.name)'s turn", type: .turnStart)

        // Clear previous highlights
        grid.clearHighlights()

        // All units are AI-controlled, with INT determining decision quality
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.executeAITurn(unit)
        }
    }

    private func handleTurnEnd(_ unit: CombatUnit) {
        // Update cached unit lists
        playerUnits = turnManager.livingUnits(playerControlled: true)
        enemyUnits = turnManager.livingUnits(playerControlled: false)
    }

    private func handleCombatEnd(_ result: CombatResult) {
        state = result.isVictory ? .victory : .defeat

        switch result {
        case .victory:
            addLogEntry("Victory! All enemies defeated.", type: .system)
        case .defeat:
            addLogEntry("Defeat... Your party has fallen.", type: .system)
        case .retreat:
            addLogEntry("Your party retreats from battle.", type: .system)
        case .stalemate:
            addLogEntry("The battle ends in a stalemate.", type: .system)
        }
    }

    // MARK: - Player Actions

    /// Move the current unit to a hex
    func moveCurrentUnit(to destination: HexCoordinate) {
        guard let unit = turnManager.currentUnit,
              turnManager.isPlayerTurn,
              !turnManager.hasMovedThisTurn else { return }

        guard grid.highlightedHexes.contains(destination) else { return }

        // Find path
        let blockedHexes = getBlockedHexes(excluding: unit.id)
        guard let path = HexPathfinder.findPath(
            from: unit.position!,
            to: destination,
            on: grid,
            blockedHexes: blockedHexes,
            maxCost: unit.movementSpeed
        ) else { return }

        // Execute move
        executeMove(unit: unit, path: path)
        turnManager.recordMovement()

        // Clear highlights and show new movement range if hasn't acted
        grid.clearHighlights()
        if !turnManager.hasActedThisTurn {
            showAttackRange(for: unit)
        }
    }

    /// Select an ability to use
    func selectAbility(_ ability: AbilityType) {
        guard let unit = turnManager.currentUnit,
              turnManager.isPlayerTurn,
              !turnManager.hasActedThisTurn else { return }

        selectedAbility = ability

        // Enter targeting mode based on ability
        let data = ability.data
        switch data.targetType {
        case .selfOnly:
            // Execute immediately
            executeAbility(ability, by: unit, at: unit.position!)
        case .singleEnemy:
            targetingMode = .selectEnemy
            highlightEnemyTargets(from: unit.position!, range: data.range)
        case .singleAlly:
            targetingMode = .selectAlly
            highlightAllyTargets(from: unit.position!, range: data.range)
        case .areaOfEffect:
            targetingMode = .selectArea
            highlightAOERange(from: unit.position!, range: data.range)
        default:
            targetingMode = .selectEnemy
            highlightEnemyTargets(from: unit.position!, range: data.range)
        }
    }

    /// Select a target for the current ability
    func selectTarget(_ target: HexCoordinate) {
        guard let unit = turnManager.currentUnit,
              let ability = selectedAbility,
              targetingMode != .none else { return }

        // Validate target
        guard validTargets.contains(target) else { return }

        // Execute ability
        executeAbility(ability, by: unit, at: target)

        // Reset targeting
        selectedAbility = nil
        targetingMode = .none
        validTargets = []
        grid.clearHighlights()

        // Record action
        turnManager.recordAction()

        // Auto-end turn if moved and acted
        if turnManager.hasMovedThisTurn {
            endTurn()
        }
    }

    /// Defend action
    func defend() {
        guard let unit = turnManager.currentUnit,
              turnManager.isPlayerTurn,
              !turnManager.hasActedThisTurn else { return }

        unit.applyStatus(StatusEffect(type: .defending, duration: 1))
        addLogEntry("\(unit.name) takes a defensive stance.", type: .action)

        turnManager.recordAction()
        endTurn()
    }

    /// End the current turn
    func endTurn() {
        grid.clearHighlights()
        selectedAbility = nil
        targetingMode = .none
        turnManager.endTurn()
    }

    // MARK: - Combat Resolution

    /// Execute a movement
    private func executeMove(unit: CombatUnit, path: [HexCoordinate]) {
        guard let start = unit.position,
              let end = path.last else { return }

        // Update grid
        if var startTile = grid.tiles[start] {
            startTile.occupant = nil
            grid.tiles[start] = startTile
        }

        if var endTile = grid.tiles[end] {
            endTile.occupant = unit.id
            grid.tiles[end] = endTile
        }

        // Update unit position
        unit.position = end
        unit.character?.combatPosition = end
        unit.enemy?.position = end

        addLogEntry("\(unit.name) moves to \(end.offsetCoordinates)", type: .movement)
    }

    /// Execute an ability
    private func executeAbility(_ ability: AbilityType, by attacker: CombatUnit, at target: HexCoordinate) {
        let data = ability.data

        // Pay resource cost
        switch data.resourceType {
        case .stamina:
            attacker.spendStamina(data.resourceCost)
        case .mana:
            attacker.spendMana(data.resourceCost)
        default:
            break
        }

        // Handle by ability type
        switch ability {
        case .basicAttack, .powerAttack, .backstab, .divineSmite:
            executeAttack(ability, by: attacker, at: target)
        case .cureWounds, .massHealing:
            executeHealing(ability, by: attacker, at: target)
        case .fireball:
            executeAOEDamage(ability, by: attacker, at: target)
        case .shield, .defend:
            executeSelfBuff(ability, by: attacker)
        case .bless, .haste:
            executeBuff(ability, by: attacker, at: target)
        case .hide:
            attacker.applyStatus(StatusEffect(type: .hidden, duration: 99))
            addLogEntry("\(attacker.name) hides in the shadows.", type: .action)
        default:
            addLogEntry("\(attacker.name) uses \(ability.rawValue).", type: .action)
        }

        // Combat statistics
        combatStats.abilitiesUsed += 1
    }

    /// Execute a basic attack or attack ability
    private func executeAttack(_ ability: AbilityType, by attacker: CombatUnit, at target: HexCoordinate) {
        guard let defender = getUnit(at: target) else { return }

        let data = ability.data

        // Roll to hit (d20 + STR/DEX modifier + attack modifier)
        let attackRoll = Int.random(in: 1...20)
        let isCritical = attackRoll == 20
        let isMiss = attackRoll == 1

        // Use DEX for ranged/finesse, STR for melee
        let attackMod = data.range > 1 ? attacker.dexterityModifier :
                        StatBlock.modifier(for: attacker.character?.stats.str ?? 10)

        let totalAttack = attackRoll + attackMod + data.attackModifier

        // Auto-hit abilities (magic missile)
        let autoHit = data.attackModifier >= 50

        if isMiss && !autoHit {
            addLogEntry("\(attacker.name) misses \(defender.name)!", type: .miss)
            combatStats.misses += 1
            return
        }

        let targetAC = defender.effectiveAC

        if totalAttack >= targetAC || isCritical || autoHit {
            // Hit! Calculate damage
            var damage = data.damage?.roll() ?? 0

            // Add stat modifier
            if data.range <= 1 {
                damage += StatBlock.modifier(for: attacker.character?.stats.str ?? 10)
            }

            // Critical doubles damage
            if isCritical {
                damage *= 2
                addLogEntry("Critical hit!", type: .critical)
                combatStats.criticalHits += 1
            }

            // Sneak attack bonus
            if attacker.isHidden || checkFlanking(attacker: attacker, defender: defender) {
                if attacker.abilities.contains(.sneakAttack) {
                    let sneakDamage = DiceRoll(count: 2, sides: 6, modifier: 0).roll()
                    damage += sneakDamage
                    addLogEntry("Sneak attack!", type: .action)
                }
            }

            // Apply damage
            defender.takeDamage(damage)
            combatStats.totalDamageDealt += damage

            addLogEntry("\(attacker.name) hits \(defender.name) for \(damage) damage!", type: .damage)

            // Check for death
            if !defender.isAlive {
                handleDeath(defender, killedBy: attacker)
            }

            // Remove hidden status after attacking
            attacker.removeStatus(.hidden)
        } else {
            addLogEntry("\(attacker.name)'s attack misses \(defender.name).", type: .miss)
            combatStats.misses += 1
        }
    }

    /// Execute a healing ability
    private func executeHealing(_ ability: AbilityType, by healer: CombatUnit, at target: HexCoordinate) {
        let data = ability.data

        // For mass healing, heal all allies in range
        if ability == .massHealing {
            let positions = target.hexesInRange(data.aoeRadius)
            for pos in positions {
                if let ally = getUnit(at: pos), ally.isPlayerControlled == healer.isPlayerControlled {
                    let healAmount = data.healing?.roll() ?? 0
                    ally.heal(healAmount)
                    combatStats.totalHealing += healAmount
                    addLogEntry("\(healer.name) heals \(ally.name) for \(healAmount)!", type: .heal)
                }
            }
        } else {
            guard let patient = getUnit(at: target) else { return }
            let healAmount = data.healing?.roll() ?? 0
            patient.heal(healAmount)
            combatStats.totalHealing += healAmount
            addLogEntry("\(healer.name) heals \(patient.name) for \(healAmount)!", type: .heal)
        }
    }

    /// Execute an AOE damage ability
    private func executeAOEDamage(_ ability: AbilityType, by caster: CombatUnit, at center: HexCoordinate) {
        let data = ability.data
        let affectedHexes = center.hexesInRange(data.aoeRadius)

        addLogEntry("\(caster.name) casts \(ability.rawValue)!", type: .action)

        for hex in affectedHexes {
            guard let target = getUnit(at: hex) else { continue }

            // Don't hit allies (usually)
            if target.isPlayerControlled == caster.isPlayerControlled { continue }

            var damage = data.damage?.roll() ?? 0

            // DEX save for half damage
            let saveRoll = Int.random(in: 1...20) + target.dexterityModifier
            if saveRoll >= 15 {
                damage /= 2
                addLogEntry("\(target.name) partially avoids the blast.", type: .action)
            }

            // Evasion
            if target.abilities.contains(.evasion) && saveRoll >= 15 {
                damage = 0
                addLogEntry("\(target.name) evades completely!", type: .action)
            }

            if damage > 0 {
                target.takeDamage(damage)
                combatStats.totalDamageDealt += damage
                addLogEntry("\(target.name) takes \(damage) damage!", type: .damage)

                if !target.isAlive {
                    handleDeath(target, killedBy: caster)
                }
            }
        }
    }

    /// Execute a self-buff ability
    private func executeSelfBuff(_ ability: AbilityType, by caster: CombatUnit) {
        let data = ability.data
        if let statusType = data.statusEffect {
            caster.applyStatus(StatusEffect(type: statusType, duration: data.statusDuration))
            addLogEntry("\(caster.name) uses \(ability.rawValue).", type: .action)
        }
    }

    /// Execute a buff on a target
    private func executeBuff(_ ability: AbilityType, by caster: CombatUnit, at target: HexCoordinate) {
        guard let targetUnit = getUnit(at: target) else { return }
        let data = ability.data

        if let statusType = data.statusEffect {
            targetUnit.applyStatus(StatusEffect(type: statusType, duration: data.statusDuration))
            addLogEntry("\(caster.name) casts \(ability.rawValue) on \(targetUnit.name).", type: .action)
        }
    }

    /// Handle unit death
    private func handleDeath(_ unit: CombatUnit, killedBy killer: CombatUnit) {
        addLogEntry("\(unit.name) has been slain!", type: .death)

        combatStats.kills += 1
        if unit.isPlayerControlled {
            combatStats.partyDeaths += 1
        } else {
            combatStats.enemiesKilled += 1
        }

        // Clear from grid
        if let pos = unit.position, var tile = grid.tiles[pos] {
            tile.occupant = nil
            grid.tiles[pos] = tile
        }

        turnManager.markUnitDead(unit)
    }

    // MARK: - AI Systems

    private let combatAI = CombatAI()
    @Published var enemyCaptainSystem = CaptainSystem()
    @Published var playerCaptainSystem = CaptainSystem()

    private func setupAISystems() {
        combatAI.enemyCaptainSystem = enemyCaptainSystem
        combatAI.playerCaptainSystem = playerCaptainSystem
    }

    // MARK: - AI Turn Execution

    private func executeAITurn(_ unit: CombatUnit) {
        guard let battleState = createBattleState() else {
            endTurn()
            return
        }

        // Phase 1: Decide and execute movement
        let moveAction = combatAI.decideAction(for: unit, in: battleState)

        if case .move(let destination) = moveAction {
            logAIDecision(unit: unit, action: moveAction)
            let blockedHexes = getBlockedHexes(excluding: unit.id)
            if let path = HexPathfinder.findPath(
                from: unit.position!,
                to: destination,
                on: grid,
                blockedHexes: blockedHexes,
                maxCost: unit.movementSpeed
            ) {
                executeMove(unit: unit, path: path)
                turnManager.recordMovement()
            }
        }

        // Phase 2: Decide and execute action (with updated state after move)
        guard let postMoveState = createBattleState() else {
            endTurn()
            return
        }

        let actionDecision = combatAI.decideAction(for: unit, in: postMoveState)

        switch actionDecision {
        case .move:
            // Already moved, skip
            break

        case .attack(let target):
            logAIDecision(unit: unit, action: actionDecision)
            executeAttack(.basicAttack, by: unit, at: target)
            turnManager.recordAction()

        case .useAbility(let ability, let target):
            logAIDecision(unit: unit, action: actionDecision)
            executeAbility(ability, by: unit, at: target)
            turnManager.recordAction()

        case .defend:
            logAIDecision(unit: unit, action: actionDecision)
            unit.applyStatus(StatusEffect(type: .defending, duration: 1))
            addLogEntry("\(unit.name) defends.", type: .action)
            turnManager.recordAction()

        case .pass:
            // Only log pass if we also didn't move
            if case .move = moveAction {} else {
                logAIDecision(unit: unit, action: actionDecision)
            }
        }

        // End AI turn after a delay for visibility
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.endTurn()
        }
    }

    /// Create a battle state snapshot for AI decision making
    private func createBattleState() -> BattleState? {
        guard let currentUnit = turnManager.currentUnit else { return nil }
        let captainSystem = currentUnit.isPlayerControlled ? playerCaptainSystem : enemyCaptainSystem
        return BattleState(
            grid: grid,
            allUnits: turnManager.livingUnits,
            currentUnit: currentUnit,
            hasMovedThisTurn: turnManager.hasMovedThisTurn,
            hasActedThisTurn: turnManager.hasActedThisTurn,
            blockedHexes: getBlockedHexes(excluding: currentUnit.id),
            captainCommand: captainSystem.currentCommand
        )
    }

    /// Log AI decision with flavor text based on INT tier
    private func logAIDecision(unit: CombatUnit, action: AIAction) {
        let tier = unit.intelligenceTier

        switch action {
        case .attack(let target):
            if let targetUnit = getUnit(at: target) {
                switch tier {
                case .low:
                    let messages = [
                        "\(unit.name) charges at \(targetUnit.name)!",
                        "\(unit.name) attacks \(targetUnit.name) wildly!",
                        "\(unit.name) lunges at \(targetUnit.name)!"
                    ]
                    addLogEntry(messages.randomElement()!, type: .action)
                case .medium:
                    addLogEntry("\(unit.name) attacks \(targetUnit.name).", type: .action)
                case .high:
                    addLogEntry("\(unit.name) strikes at \(targetUnit.name) precisely.", type: .action)
                }
            }

        case .useAbility(let ability, _):
            switch tier {
            case .low:
                if Double.random(in: 0...1) < 0.3 {
                    addLogEntry("\(unit.name) fumbles with \(ability.rawValue)...", type: .action)
                }
            case .medium:
                break
            case .high:
                addLogEntry("\(unit.name) strategically uses \(ability.rawValue).", type: .action)
            }

        case .defend:
            switch tier {
            case .low:
                addLogEntry("\(unit.name) cowers defensively.", type: .action)
            case .medium:
                addLogEntry("\(unit.name) takes a defensive stance.", type: .action)
            case .high:
                addLogEntry("\(unit.name) expertly guards against attacks.", type: .action)
            }

        case .move(let dest):
            switch tier {
            case .low:
                // Low INT might not move optimally
                if Double.random(in: 0...1) < 0.2 {
                    addLogEntry("\(unit.name) wanders around...", type: .action)
                }
            case .high:
                // High INT explains tactical movement
                let enemies = enemyUnits.compactMap { $0.position }
                for enemyPos in enemies {
                    if dest.distance(to: enemyPos) == 1 {
                        addLogEntry("\(unit.name) moves to flank position.", type: .action)
                        break
                    }
                }
            default:
                break
            }

        case .pass:
            switch tier {
            case .low:
                let messages = [
                    "\(unit.name) looks confused...",
                    "\(unit.name) scratches their head.",
                    "\(unit.name) hesitates uncertainly."
                ]
                addLogEntry(messages.randomElement()!, type: .action)
            case .medium:
                addLogEntry("\(unit.name) waits for an opportunity.", type: .action)
            case .high:
                addLogEntry("\(unit.name) holds position strategically.", type: .action)
            }
        }
    }

    // MARK: - Helper Methods

    private func getBlockedHexes(excluding unitId: UUID) -> Set<HexCoordinate> {
        var blocked: Set<HexCoordinate> = []
        for (coord, tile) in grid.tiles {
            if tile.isBlocked || (tile.occupant != nil && tile.occupant != unitId) {
                blocked.insert(coord)
            }
        }
        return blocked
    }

    private func getUnit(at position: HexCoordinate) -> CombatUnit? {
        return turnManager.livingUnits.first { $0.position == position }
    }

    private func showMovementRange(for unit: CombatUnit) {
        guard let position = unit.position else { return }
        let blockedHexes = getBlockedHexes(excluding: unit.id)
        grid.highlightMovementRange(from: position, movement: unit.movementSpeed, blockedHexes: blockedHexes)
    }

    private func showAttackRange(for unit: CombatUnit) {
        guard let position = unit.position else { return }
        let maxRange = unit.abilities
            .filter { !$0.data.isPassive }
            .map { $0.data.range }
            .max() ?? 1
        grid.highlightAttackRange(from: position, range: maxRange)
    }

    private func highlightEnemyTargets(from position: HexCoordinate, range: Int) {
        let enemies = turnManager.currentUnit?.isPlayerControlled == true ? enemyUnits : playerUnits
        validTargets = enemies.compactMap { enemy -> HexCoordinate? in
            guard let pos = enemy.position,
                  position.distance(to: pos) <= range,
                  !turnManager.isDead(enemy) else { return nil }
            return pos
        }
        grid.highlightedHexes = Set(validTargets)
        grid.highlightColor = .red.opacity(0.4)
    }

    private func highlightAllyTargets(from position: HexCoordinate, range: Int) {
        let allies = turnManager.currentUnit?.isPlayerControlled == true ? playerUnits : enemyUnits
        validTargets = allies.compactMap { ally -> HexCoordinate? in
            guard let pos = ally.position,
                  position.distance(to: pos) <= range,
                  !turnManager.isDead(ally) else { return nil }
            return pos
        }
        grid.highlightedHexes = Set(validTargets)
        grid.highlightColor = .green.opacity(0.4)
    }

    private func highlightAOERange(from position: HexCoordinate, range: Int) {
        validTargets = position.hexesInRange(range).filter { grid.isValidCoordinate($0) }
        grid.highlightedHexes = Set(validTargets)
        grid.highlightColor = .orange.opacity(0.4)
    }

    private func checkFlanking(attacker: CombatUnit, defender: CombatUnit) -> Bool {
        guard let attackerPos = attacker.position,
              let defenderPos = defender.position else { return false }

        let allies = attacker.isPlayerControlled ? playerUnits : enemyUnits
        let allyPositions = allies.compactMap { $0.position }

        return HexPathfinder.isFlanked(target: defenderPos, by: attackerPos, allies: allyPositions)
    }

    private func addLogEntry(_ message: String, type: CombatLogType) {
        let entry = CombatLogEntry(message: message, type: type)
        combatLog.append(entry)

        // Keep log manageable
        if combatLog.count > 100 {
            combatLog.removeFirst()
        }
    }
}

// MARK: - Supporting Types

enum CombatState {
    case notInCombat
    case settingUp
    case inProgress
    case victory
    case defeat
}

enum TargetingMode {
    case none
    case selectEnemy
    case selectAlly
    case selectArea
    case selectHex
}

enum AIDecision {
    case move(HexCoordinate)
    case attack(HexCoordinate)
    case useAbility(AbilityType, HexCoordinate)
    case defend
    case pass
}

struct CombatLogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let message: String
    let type: CombatLogType
}

enum CombatLogType {
    case system
    case turnStart
    case movement
    case action
    case damage
    case heal
    case miss
    case critical
    case death
}

struct CombatStatistics {
    var totalDamageDealt: Int = 0
    var totalHealing: Int = 0
    var kills: Int = 0
    var criticalHits: Int = 0
    var misses: Int = 0
    var abilitiesUsed: Int = 0
    var turnsElapsed: Int = 0
    var enemiesKilled: Int = 0
    var partyDeaths: Int = 0
}

/// Terrain templates for different encounter types
struct TerrainTemplate {
    let width: Int
    let height: Int
    let terrainOverrides: [HexCoordinate: TerrainType]

    static let basicArena = TerrainTemplate(
        width: 10,
        height: 12,
        terrainOverrides: [:]
    )

    static let forestClearing = TerrainTemplate(
        width: 10,
        height: 12,
        terrainOverrides: [
            HexCoordinate(col: 3, row: 3): .forest,
            HexCoordinate(col: 3, row: 4): .forest,
            HexCoordinate(col: 6, row: 7): .forest,
            HexCoordinate(col: 6, row: 8): .forest,
            HexCoordinate(col: 7, row: 7): .forest
        ]
    )

    static let dungeonCorridor = TerrainTemplate(
        width: 12,
        height: 8,
        terrainOverrides: [
            HexCoordinate(col: 0, row: 0): .wall,
            HexCoordinate(col: 0, row: 1): .wall,
            HexCoordinate(col: 0, row: 6): .wall,
            HexCoordinate(col: 0, row: 7): .wall,
            HexCoordinate(col: 11, row: 0): .wall,
            HexCoordinate(col: 11, row: 1): .wall,
            HexCoordinate(col: 11, row: 6): .wall,
            HexCoordinate(col: 11, row: 7): .wall
        ]
    )
}
