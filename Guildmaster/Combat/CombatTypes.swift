//
//  CombatTypes.swift
//  Guildmaster
//
//  Type aliases and extensions for combat systems
//

import Foundation

// MARK: - Type Aliases

/// Alias for CombatStatistics used in views
typealias CombatStats = CombatStatistics

// MARK: - Combat Statistics Extensions

extension CombatStatistics {
    /// Total damage taken by party (approximate)
    var totalDamageTaken: Int {
        // Estimate damage taken from party deaths and healing needed
        return totalHealing + (partyDeaths * 50)
    }
}

// MARK: - Character Extensions for Victory/Defeat Screens

extension Character {
    /// Convenience accessor for current HP
    var hp: Int {
        get { secondaryStats.hp }
        set { secondaryStats.hp = newValue }
    }

    /// Convenience accessor for max HP
    var maxHP: Int {
        get { secondaryStats.maxHP }
        set { secondaryStats.maxHP = newValue }
    }

    /// Convenience accessor for HP percentage
    var hpPercentage: Double {
        secondaryStats.hpPercentage
    }
}
