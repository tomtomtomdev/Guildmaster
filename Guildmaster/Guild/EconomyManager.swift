//
//  EconomyManager.swift
//  Guildmaster
//
//  Manages the guild economy: gold, costs, salaries
//

import Foundation
import Combine

/// Manages all economic calculations and tracking
class EconomyManager: ObservableObject {

    // MARK: - Singleton

    static let shared = EconomyManager()

    // MARK: - Constants

    /// Base weekly salary per adventurer
    let baseSalary: Int = 50

    /// Weekly guild upkeep cost
    let guildUpkeep: Int = 100

    /// Equipment repair cost per adventurer
    let repairCostPerCharacter: Int = 10

    // MARK: - Initialization

    private init() {}

    // MARK: - Cost Calculations

    /// Calculate total weekly costs
    func calculateWeeklyCosts(roster: [Character]) -> WeeklyCosts {
        let salaries = calculateSalaries(roster: roster)
        let repairs = calculateRepairs(roster: roster)

        return WeeklyCosts(
            salaries: salaries,
            upkeep: guildUpkeep,
            repairs: repairs,
            total: salaries + guildUpkeep + repairs
        )
    }

    /// Calculate total weekly salaries
    func calculateSalaries(roster: [Character]) -> Int {
        var total = 0

        for character in roster {
            var salary = baseSalary

            // Higher level = higher salary expectations
            salary += (character.level - 1) * 10

            // Greedy personality = higher salary
            if character.personality.greedy >= 7 {
                salary = Int(Double(salary) * 1.3)
            }

            // Loyal personality = accepts less
            if character.personality.loyal >= 8 {
                salary = Int(Double(salary) * 0.85)
            }

            total += salary
        }

        return total
    }

    /// Calculate equipment repair costs
    func calculateRepairs(roster: [Character]) -> Int {
        var total = 0

        for character in roster {
            // Injured characters cost more to maintain
            let hpPercent = Double(character.secondaryStats.hp) / Double(character.secondaryStats.maxHP)

            if hpPercent < 1.0 {
                // Base repair + extra for injuries
                let injuryMultiplier = 1.0 + (1.0 - hpPercent)
                total += Int(Double(repairCostPerCharacter) * injuryMultiplier)
            } else {
                total += repairCostPerCharacter
            }
        }

        return total
    }

    // MARK: - Quest Rewards

    /// Calculate adjusted quest rewards based on modifiers
    func calculateQuestReward(baseReward: QuestRewards, modifiers: RewardModifiers) -> QuestRewards {
        var gold = baseReward.gold
        var xp = baseReward.xp

        // Reputation bonus
        if modifiers.reputationBonus > 0 {
            gold = Int(Double(gold) * (1.0 + Double(modifiers.reputationBonus) / 100.0))
        }

        // Speed bonus (completed quickly)
        if modifiers.speedBonus {
            xp = Int(Double(xp) * 1.1)
        }

        // No casualties bonus
        if modifiers.noCasualties {
            gold += 50
            xp = Int(Double(xp) * 1.2)
        }

        return QuestRewards(
            gold: gold,
            xp: xp,
            itemIds: baseReward.itemIds,
            reputationChanges: baseReward.reputationChanges
        )
    }

    // MARK: - Financial Projections

    /// Project gold balance for upcoming weeks
    func projectBalance(currentGold: Int, roster: [Character], weeks: Int) -> [Int] {
        var projections: [Int] = []
        var balance = currentGold
        let weeklyCosts = calculateWeeklyCosts(roster: roster).total

        // Assume average quest income
        let averageQuestIncome = 250

        for _ in 0..<weeks {
            balance += averageQuestIncome
            balance -= weeklyCosts
            projections.append(balance)
        }

        return projections
    }

    /// Check if guild can afford a purchase
    func canAfford(cost: Int, currentGold: Int) -> Bool {
        return currentGold >= cost
    }

    /// Calculate how many weeks until bankruptcy at current rate
    func weeksUntilBankruptcy(currentGold: Int, roster: [Character]) -> Int? {
        let weeklyCosts = calculateWeeklyCosts(roster: roster).total
        let averageIncome = 250

        let netWeekly = averageIncome - weeklyCosts

        if netWeekly >= 0 {
            return nil  // Not going bankrupt
        }

        return currentGold / abs(netWeekly)
    }
}

// MARK: - Supporting Types

struct WeeklyCosts {
    let salaries: Int
    let upkeep: Int
    let repairs: Int
    let total: Int

    var breakdown: String {
        return """
        Salaries: \(salaries)g
        Guild Upkeep: \(upkeep)g
        Repairs: \(repairs)g
        ─────────────
        Total: \(total)g
        """
    }
}

struct RewardModifiers {
    var reputationBonus: Int = 0      // Percentage bonus from faction reputation
    var speedBonus: Bool = false       // Completed under par turns
    var noCasualties: Bool = false     // No party deaths
    var bonusObjectives: Int = 0       // Number of bonus objectives completed
}
