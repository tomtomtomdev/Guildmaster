//
//  KillTracker.swift
//  Guildmaster
//
//  Tracks kills, streaks, and multi-kills during combat
//

import Foundation
import Combine

/// Tracks combat statistics for kill announcements
class KillTracker: ObservableObject {

    // MARK: - Singleton

    static let shared = KillTracker()

    // MARK: - Published Properties

    /// Kills per unit ID this combat
    @Published var killsByUnit: [UUID: Int] = [:]

    /// Kill streak (consecutive kills without dying) per unit
    @Published var streakByUnit: [UUID: Int] = [:]

    /// Kills this turn per unit (for multi-kills)
    @Published var killsThisTurn: [UUID: Int] = [:]

    /// First blood - has anyone gotten a kill yet?
    @Published var firstBloodClaimed: Bool = false
    @Published var firstBloodUnit: UUID?

    /// Latest announcement to display
    @Published var latestAnnouncement: KillAnnouncement?

    // MARK: - Combat Stats

    /// Total damage dealt per unit
    @Published var damageDealt: [UUID: Int] = [:]

    /// Total damage taken per unit
    @Published var damageTaken: [UUID: Int] = [:]

    /// Total healing done per unit
    @Published var healingDone: [UUID: Int] = [:]

    /// Assists per unit (damaged enemy that someone else killed)
    @Published var assists: [UUID: Int] = [:]

    /// Deaths per unit
    @Published var deaths: [UUID: Int] = [:]

    // MARK: - Turn Tracking

    private var lastDamageDealer: [UUID: UUID] = [:] // victim -> last attacker

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Reset all tracking for new combat
    func reset() {
        killsByUnit.removeAll()
        streakByUnit.removeAll()
        killsThisTurn.removeAll()
        firstBloodClaimed = false
        firstBloodUnit = nil
        latestAnnouncement = nil
        damageDealt.removeAll()
        damageTaken.removeAll()
        healingDone.removeAll()
        assists.removeAll()
        deaths.removeAll()
        lastDamageDealer.removeAll()
    }

    /// Called when a new turn begins
    func newTurn() {
        killsThisTurn.removeAll()
    }

    /// Record damage dealt
    func recordDamage(attacker: UUID, victim: UUID, amount: Int) {
        damageDealt[attacker, default: 0] += amount
        damageTaken[victim, default: 0] += amount
        lastDamageDealer[victim] = attacker
    }

    /// Record healing done
    func recordHealing(healer: UUID, target: UUID, amount: Int) {
        healingDone[healer, default: 0] += amount
    }

    /// Record a kill
    func recordKill(killer: UUID, victim: UUID, killerName: String, victimName: String) {
        // Update kill counts
        killsByUnit[killer, default: 0] += 1
        streakByUnit[killer, default: 0] += 1
        killsThisTurn[killer, default: 0] += 1
        deaths[victim, default: 0] += 1

        // Reset victim's streak
        streakByUnit[victim] = 0

        var announcements: [KillAnnouncement] = []

        // Check for first blood
        if !firstBloodClaimed {
            firstBloodClaimed = true
            firstBloodUnit = killer
            announcements.append(KillAnnouncement(
                type: .firstBlood,
                unitId: killer,
                unitName: killerName,
                victimName: victimName,
                count: 1
            ))

            // Add to commentary
            CombatCommentary.shared.addEvent(.firstBlood(attacker: killerName, victim: victimName))
        }

        // Check for kill streak
        let streak = streakByUnit[killer] ?? 1
        if streak >= 2 {
            let (title, _) = KillStreakTitles.title(for: streak)
            announcements.append(KillAnnouncement(
                type: .streak,
                unitId: killer,
                unitName: killerName,
                victimName: nil,
                count: streak,
                title: title
            ))

            // Add to commentary
            CombatCommentary.shared.addEvent(.killStreak(unit: killerName, streak: streak))
        }

        // Check for multi-kill (same turn)
        let multiKill = killsThisTurn[killer] ?? 1
        if multiKill >= 2 {
            let title = MultiKillTitles.title(for: multiKill)
            announcements.append(KillAnnouncement(
                type: .multiKill,
                unitId: killer,
                unitName: killerName,
                victimName: nil,
                count: multiKill,
                title: title
            ))

            // Add to commentary
            CombatCommentary.shared.addEvent(.multiKill(unit: killerName, count: multiKill))
        }

        // Record assist for last person to damage the victim (if not the killer)
        if let lastAttacker = lastDamageDealer[victim], lastAttacker != killer {
            assists[lastAttacker, default: 0] += 1
        }

        // Set the most important announcement
        if let best = announcements.max(by: { $0.priority < $1.priority }) {
            latestAnnouncement = best
        }

        // Add death to commentary
        CombatCommentary.shared.addEvent(.death(victim: victimName, killer: killerName))
    }

    /// Record a death with no killer (environment, etc.)
    func recordDeath(victim: UUID, victimName: String) {
        deaths[victim, default: 0] += 1
        streakByUnit[victim] = 0

        CombatCommentary.shared.addEvent(.death(victim: victimName, killer: nil))
    }

    // MARK: - Statistics

    /// Get total kills for a unit
    func kills(for unitId: UUID) -> Int {
        return killsByUnit[unitId] ?? 0
    }

    /// Get current streak for a unit
    func streak(for unitId: UUID) -> Int {
        return streakByUnit[unitId] ?? 0
    }

    /// Get MVP candidate score
    func mvpScore(for unitId: UUID) -> Int {
        let kills = killsByUnit[unitId] ?? 0
        let damage = damageDealt[unitId] ?? 0
        let healing = healingDone[unitId] ?? 0
        let assistCount = assists[unitId] ?? 0

        // Weighted scoring
        return kills * 100 + damage + healing * 2 + assistCount * 50
    }

    /// Get combat summary for a unit
    func summary(for unitId: UUID) -> CombatSummary {
        return CombatSummary(
            kills: killsByUnit[unitId] ?? 0,
            deaths: deaths[unitId] ?? 0,
            assists: assists[unitId] ?? 0,
            damageDealt: damageDealt[unitId] ?? 0,
            damageTaken: damageTaken[unitId] ?? 0,
            healingDone: healingDone[unitId] ?? 0
        )
    }
}

// MARK: - Kill Announcement

/// A kill-related announcement to display
struct KillAnnouncement: Identifiable {
    let id = UUID()
    let type: AnnouncementType
    let unitId: UUID
    let unitName: String
    let victimName: String?
    let count: Int
    let title: String?
    let timestamp = Date()

    init(type: AnnouncementType, unitId: UUID, unitName: String, victimName: String?, count: Int, title: String? = nil) {
        self.type = type
        self.unitId = unitId
        self.unitName = unitName
        self.victimName = victimName
        self.count = count
        self.title = title
    }

    enum AnnouncementType: Int {
        case kill = 0
        case firstBlood = 3
        case streak = 1
        case multiKill = 2

        var priority: Int { rawValue }
    }

    var priority: Int { type.priority }

    var displayText: String {
        switch type {
        case .firstBlood:
            return "FIRST BLOOD!"
        case .streak:
            return title ?? "KILLING SPREE!"
        case .multiKill:
            return title ?? "MULTI KILL!"
        case .kill:
            return "\(unitName) killed \(victimName ?? "enemy")"
        }
    }
}

// MARK: - Combat Summary

/// Summary of a unit's combat performance
struct CombatSummary {
    let kills: Int
    let deaths: Int
    let assists: Int
    let damageDealt: Int
    let damageTaken: Int
    let healingDone: Int

    var kda: String {
        return "\(kills)/\(deaths)/\(assists)"
    }
}
