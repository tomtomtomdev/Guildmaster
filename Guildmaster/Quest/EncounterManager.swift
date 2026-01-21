//
//  EncounterManager.swift
//  Guildmaster
//
//  Manages individual combat encounters within quests
//

import Foundation
import Combine

/// Manages encounter flow and state
class EncounterManager: ObservableObject {

    // MARK: - Singleton

    static let shared = EncounterManager()

    // MARK: - Published State

    @Published var currentEncounter: QuestEncounter?
    @Published var encounterState: EncounterState = .notStarted

    /// Party members for this encounter
    @Published var partyMembers: [Character] = []

    /// Enemies for this encounter
    @Published var enemies: [Enemy] = []

    /// Encounter statistics
    @Published var encounterStats: EncounterStatistics = EncounterStatistics()

    // MARK: - Private State

    private var combatManager: CombatManager { CombatManager.shared }
    private var questManager: QuestManager { QuestManager.shared }
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupCombatObservers()
    }

    private func setupCombatObservers() {
        // Observe combat state changes
        combatManager.$state
            .sink { [weak self] state in
                self?.handleCombatStateChange(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Encounter Flow

    /// Start an encounter with the given party
    func startEncounter(_ encounter: QuestEncounter, party: [Character]) {
        currentEncounter = encounter
        partyMembers = party
        enemies = encounter.generateEnemies()
        encounterState = .starting
        encounterStats = EncounterStatistics()

        // Select terrain template based on encounter
        let terrain = selectTerrain(for: encounter)

        // Start combat
        combatManager.startCombat(
            playerParty: party,
            enemies: enemies,
            terrain: terrain
        )

        encounterState = .inProgress
    }

    /// Select appropriate terrain template
    private func selectTerrain(for encounter: QuestEncounter) -> TerrainTemplate {
        switch encounter.terrain {
        case .forest:
            return .forestClearing
        case .ground:
            return .basicArena
        case .wall:
            return .dungeonCorridor
        default:
            return .basicArena
        }
    }

    /// Handle combat state changes
    private func handleCombatStateChange(_ state: CombatState) {
        switch state {
        case .victory:
            encounterState = .victory
            collectEncounterStats()
            questManager.completeCurrentEncounter(victory: true, stats: combatManager.combatStats)

        case .defeat:
            encounterState = .defeat
            collectEncounterStats()
            questManager.completeCurrentEncounter(victory: false, stats: combatManager.combatStats)

        default:
            break
        }
    }

    /// Collect statistics from the completed encounter
    private func collectEncounterStats() {
        encounterStats = EncounterStatistics(
            turnsElapsed: combatManager.combatStats.turnsElapsed,
            damageDealt: combatManager.combatStats.totalDamageDealt,
            damageTaken: combatManager.combatStats.totalDamageDealt,  // Would track separately
            healingDone: combatManager.combatStats.totalHealing,
            enemiesKilled: combatManager.combatStats.enemiesKilled,
            partyDeaths: combatManager.combatStats.partyDeaths,
            criticalHits: combatManager.combatStats.criticalHits,
            abilitiesUsed: combatManager.combatStats.abilitiesUsed
        )
    }

    /// Cleanup after encounter
    func cleanupEncounter() {
        currentEncounter = nil
        partyMembers = []
        enemies = []
        encounterState = .notStarted
    }

    // MARK: - Party Status

    /// Get surviving party members
    var survivingParty: [Character] {
        return partyMembers.filter { $0.isAlive }
    }

    /// Check if any party member is alive
    var partyAlive: Bool {
        return partyMembers.contains { $0.isAlive }
    }

    /// Heal party between encounters (partial heal)
    func restPartyBetweenEncounters() {
        for character in partyMembers where character.isAlive {
            // Heal 25% of missing HP between encounters
            let missingHP = character.secondaryStats.maxHP - character.secondaryStats.hp
            let healAmount = missingHP / 4
            character.heal(healAmount)

            // Restore some stamina/mana
            character.secondaryStats.stamina = min(
                character.secondaryStats.maxStamina,
                character.secondaryStats.stamina + 10
            )
            character.secondaryStats.mana = min(
                character.secondaryStats.maxMana,
                character.secondaryStats.mana + 5
            )
        }
    }
}

// MARK: - Encounter State

enum EncounterState {
    case notStarted
    case starting
    case inProgress
    case victory
    case defeat
}

// MARK: - Encounter Statistics

struct EncounterStatistics {
    var turnsElapsed: Int = 0
    var damageDealt: Int = 0
    var damageTaken: Int = 0
    var healingDone: Int = 0
    var enemiesKilled: Int = 0
    var partyDeaths: Int = 0
    var criticalHits: Int = 0
    var abilitiesUsed: Int = 0

    var mvpCharacterId: UUID?  // Most valuable player
}
