//
//  LedgerView.swift
//  Guildmaster
//
//  Financial ledger and quest history view
//

import SwiftUI

/// View for tracking guild finances and quest history
struct LedgerView: View {
    @ObservedObject var guildManager = GuildManager.shared
    @Binding var currentScreen: GameScreen
    @State private var selectedTab: LedgerTab = .finances

    enum LedgerTab: String, CaseIterable {
        case finances = "Finances"
        case quests = "Quest Log"
        case statistics = "Statistics"
    }

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                tabSelector

                ScrollView {
                    switch selectedTab {
                    case .finances:
                        financesContent
                    case .quests:
                        questLogContent
                    case .statistics:
                        statisticsContent
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: { currentScreen = .guildHall }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.blue)
            }

            Spacer()

            Text("Guild Ledger")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Gold display
            HStack(spacing: 4) {
                Image(systemName: "coins")
                    .foregroundColor(.yellow)
                Text("\(guildManager.gold)g")
                    .foregroundColor(.yellow)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(LedgerTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .bold : .regular)
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.blue.opacity(0.3) : Color.clear)
                }
            }
        }
        .background(Color.black.opacity(0.2))
    }

    // MARK: - Finances Content

    private var financesContent: some View {
        VStack(spacing: 16) {
            // Current balance
            balanceSection

            // Weekly summary
            weeklySummarySection

            // Expense breakdown
            expenseBreakdownSection

            // Recent transactions
            recentTransactionsSection
        }
        .padding()
    }

    private var balanceSection: some View {
        VStack(spacing: 8) {
            Text("Treasury")
                .font(.headline)
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(guildManager.gold)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.yellow)
                Text("gold")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
            }

            // Financial health indicator
            let healthStatus = financialHealth
            HStack(spacing: 4) {
                Image(systemName: healthStatus.icon)
                    .foregroundColor(healthStatus.color)
                Text(healthStatus.message)
                    .font(.caption)
                    .foregroundColor(healthStatus.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var financialHealth: (icon: String, color: Color, message: String) {
        let weeklyExpense = calculateWeeklyExpenses()
        let weeksOfRunway = weeklyExpense > 0 ? guildManager.gold / weeklyExpense : 99

        if weeksOfRunway >= 10 {
            return ("checkmark.circle.fill", .green, "Healthy finances")
        } else if weeksOfRunway >= 4 {
            return ("exclamationmark.triangle.fill", .yellow, "Watch expenses")
        } else if weeksOfRunway >= 1 {
            return ("exclamationmark.octagon.fill", .orange, "Low funds!")
        } else {
            return ("xmark.octagon.fill", .red, "Critical! Bankruptcy imminent")
        }
    }

    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Summary")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                // Income
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("+\(calculateWeeklyIncome())g")
                        .font(.title3)
                        .foregroundColor(.green)
                }

                Spacer()

                // Expenses
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("-\(calculateWeeklyExpenses())g")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }

            Divider().background(Color.gray)

            // Net
            HStack {
                Text("Net")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                let net = calculateWeeklyIncome() - calculateWeeklyExpenses()
                Text("\(net >= 0 ? "+" : "")\(net)g")
                    .font(.headline)
                    .foregroundColor(net >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var expenseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expense Breakdown")
                .font(.headline)
                .foregroundColor(.white)

            expenseRow("Salaries", calculateSalaryCosts(), .blue)
            expenseRow("Upkeep", calculateUpkeepCost(), .orange)
            expenseRow("Repairs", 50, .red) // Placeholder

            Divider().background(Color.gray)

            HStack {
                Text("Total Weekly")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("-\(calculateWeeklyExpenses())g")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func expenseRow(_ label: String, _ amount: Int, _ color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Text("-\(amount)g")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .foregroundColor(.white)

            // Placeholder transactions
            transactionRow("Quest: Goblin Camp", "+250g", .green, "sword")
            transactionRow("Weekly Salaries", "-200g", .red, "person.3")
            transactionRow("Equipment Repair", "-50g", .red, "hammer")
            transactionRow("Item Sale", "+35g", .green, "bag")
            transactionRow("Recruitment Fee", "-100g", .red, "person.badge.plus")
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func transactionRow(_ description: String, _ amount: String, _ color: Color, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text(amount)
                .font(.subheadline)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Quest Log Content

    private var questLogContent: some View {
        VStack(spacing: 16) {
            // Quest statistics summary
            questSummarySection

            // Completed quests
            completedQuestsSection

            // Failed quests
            failedQuestsSection
        }
        .padding()
    }

    private var questSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quest Record")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                questStatItem("\(guildManager.stats.totalQuestsCompleted)", "Completed", .green)
                questStatItem("\(guildManager.stats.totalQuestsFailed)", "Failed", .red)
                questStatItem("\(successRate)%", "Success Rate", successRateColor)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var successRate: Int {
        let total = guildManager.stats.totalQuestsCompleted + guildManager.stats.totalQuestsFailed
        guard total > 0 else { return 100 }
        return (guildManager.stats.totalQuestsCompleted * 100) / total
    }

    private var successRateColor: Color {
        if successRate >= 80 { return .green }
        if successRate >= 60 { return .yellow }
        return .red
    }

    private func questStatItem(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var completedQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Quests")
                .font(.headline)
                .foregroundColor(.white)

            if guildManager.stats.totalQuestsCompleted == 0 {
                Text("No completed quests yet")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                // Placeholder entries
                ForEach(0..<min(5, guildManager.stats.totalQuestsCompleted), id: \.self) { index in
                    questLogEntry(
                        title: "Quest \(index + 1)",
                        type: "Extermination",
                        day: guildManager.currentDay - (index * 2),
                        success: true
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var failedQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Failed Quests")
                .font(.headline)
                .foregroundColor(.white)

            if guildManager.stats.totalQuestsFailed == 0 {
                Text("No failed quests - excellent record!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .italic()
            } else {
                ForEach(0..<min(3, guildManager.stats.totalQuestsFailed), id: \.self) { index in
                    questLogEntry(
                        title: "Failed Quest \(index + 1)",
                        type: "Rescue",
                        day: guildManager.currentDay - (index * 3) - 1,
                        success: false
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func questLogEntry(title: String, type: String, day: Int, success: Bool) -> some View {
        HStack {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(success ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(type)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("Day \(day)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Statistics Content

    private var statisticsContent: some View {
        VStack(spacing: 16) {
            // Guild statistics
            guildStatisticsSection

            // Combat statistics
            combatStatisticsSection

            // Records
            recordsSection
        }
        .padding()
    }

    private var guildStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guild Statistics")
                .font(.headline)
                .foregroundColor(.white)

            statRow("Current Day", "\(guildManager.currentDay)")
            statRow("Guild Members", "\(guildManager.roster.count)/\(guildManager.maxRosterSize)")
            statRow("Total Gold Earned", "\(guildManager.gold + (guildManager.stats.totalQuestsCompleted * 300))g")
            statRow("Adventurers Hired", "\(guildManager.roster.count)")
            statRow("Adventurers Lost", "0")
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var combatStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combat Statistics")
                .font(.headline)
                .foregroundColor(.white)

            let totalKills = guildManager.roster.reduce(0) { $0 + $1.totalKills }

            statRow("Total Enemies Slain", "\(totalKills)")
            statRow("Total Quests Attempted", "\(guildManager.stats.totalQuestsCompleted + guildManager.stats.totalQuestsFailed)")
            statRow("Perfect Victories", "0")
            statRow("Close Calls", "0")
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Records")
                .font(.headline)
                .foregroundColor(.white)

            // Find top killer
            let topKiller = guildManager.roster.max { $0.totalKills < $1.totalKills }

            if let killer = topKiller, killer.totalKills > 0 {
                recordRow("Most Kills", killer.name, "\(killer.totalKills)")
            }

            // Find highest level
            let highestLevel = guildManager.roster.max { $0.level < $1.level }

            if let champion = highestLevel {
                recordRow("Highest Level", champion.name, "Lv.\(champion.level)")
            }

            // Find most quests
            let mostQuests = guildManager.roster.max { $0.questsCompleted < $1.questsCompleted }

            if let veteran = mostQuests, veteran.questsCompleted > 0 {
                recordRow("Most Quests", veteran.name, "\(veteran.questsCompleted)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }

    private func recordRow(_ category: String, _ name: String, _ value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.yellow)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Calculations

    private func calculateWeeklyIncome() -> Int {
        // Approximate based on quests completed
        return guildManager.stats.totalQuestsCompleted > 0 ? 300 : 0
    }

    private func calculateWeeklyExpenses() -> Int {
        return calculateSalaryCosts() + calculateUpkeepCost() + 50
    }

    private func calculateSalaryCosts() -> Int {
        return guildManager.roster.count * 50
    }

    private func calculateUpkeepCost() -> Int {
        // Base upkeep scales with guild size
        return 100 + (guildManager.roster.count * 10)
    }
}

#Preview {
    LedgerView(currentScreen: .constant(.ledger))
}
