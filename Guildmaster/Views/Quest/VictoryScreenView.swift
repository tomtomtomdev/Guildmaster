//
//  VictoryScreenView.swift
//  Guildmaster
//
//  Full victory screen with MVP selection, combat stats, and rewards
//

import SwiftUI
import Combine

/// Types of special victory conditions
enum VictoryType: String {
    case standard = "Victory"
    case flawless = "Flawless Victory"   // No damage taken
    case pyrrhic = "Pyrrhic Victory"     // Lost party members
    case swift = "Swift Victory"         // Under 5 turns
    case dominant = "Dominant Victory"   // High kill differential
}

/// MVP title categories
enum MVPTitle: String, CaseIterable {
    case slayer = "Slayer"              // Most kills
    case destroyer = "Destroyer"        // Most damage dealt
    case lifebringer = "Lifebringer"    // Most healing done
    case guardian = "Guardian"          // Most damage taken (tank)
    case tactician = "Tactician"        // Most assists
    case survivor = "Survivor"          // Survived with lowest HP
    case untouchable = "Untouchable"    // Took no damage
    case executioner = "Executioner"    // Most finishing blows on low HP enemies

    var description: String {
        switch self {
        case .slayer: return "Most enemy kills"
        case .destroyer: return "Highest damage dealt"
        case .lifebringer: return "Most healing performed"
        case .guardian: return "Absorbed the most damage"
        case .tactician: return "Most kill assists"
        case .survivor: return "Survived against all odds"
        case .untouchable: return "Took no damage"
        case .executioner: return "Finished the most enemies"
        }
    }

    var icon: String {
        switch self {
        case .slayer: return "flame.fill"
        case .destroyer: return "bolt.fill"
        case .lifebringer: return "heart.fill"
        case .guardian: return "shield.fill"
        case .tactician: return "brain.head.profile"
        case .survivor: return "figure.stand"
        case .untouchable: return "sparkles"
        case .executioner: return "xmark.circle.fill"
        }
    }
}

/// Victory quotes by class
enum VictoryQuotes {
    static func quote(for characterClass: CharacterClass, personality: Personality? = nil) -> String {
        let quotes: [CharacterClass: [String]] = [
            .warrior: [
                "Another glorious battle!",
                "They fell before my blade!",
                "Victory is ours!",
                "My sword arm grows weary... but satisfied."
            ],
            .rogue: [
                "Quick and clean, just how I like it.",
                "They never saw me coming.",
                "Easy pickings.",
                "I'll be counting my coins tonight."
            ],
            .mage: [
                "The arcane arts triumph once more.",
                "Knowledge is power.",
                "A calculated victory.",
                "My spells proved most effective."
            ],
            .cleric: [
                "The light guides us to victory!",
                "We are blessed this day.",
                "Thanks be to the divine.",
                "Our faith was rewarded."
            ]
        ]

        return quotes[characterClass]?.randomElement() ?? "Victory!"
    }
}

/// View model for victory screen
class VictoryScreenViewModel: ObservableObject {
    let party: [Character]
    let combatStats: CombatStats
    let quest: Quest
    let victoryType: VictoryType
    let rewards: QuestRewards

    @Published var mvp: Character?
    @Published var mvpTitle: MVPTitle = .slayer
    @Published var partyPerformance: [CharacterPerformance] = []

    init(party: [Character], combatStats: CombatStats, quest: Quest) {
        self.party = party
        self.combatStats = combatStats
        self.quest = quest
        self.rewards = quest.rewards
        self.victoryType = Self.determineVictoryType(stats: combatStats, party: party)

        calculatePerformance()
        selectMVP()
    }

    private func calculatePerformance() {
        partyPerformance = party.map { character in
            let summary = KillTracker.shared.summary(for: character.id)
            return CharacterPerformance(
                character: character,
                kills: summary.kills,
                damage: summary.damageDealt,
                healing: summary.healingDone,
                damageTaken: summary.damageTaken,
                assists: summary.assists
            )
        }
    }

    private func selectMVP() {
        guard !partyPerformance.isEmpty else { return }

        // Find top performer in each category
        let topKiller = partyPerformance.max { $0.kills < $1.kills }
        let topDamage = partyPerformance.max { $0.damage < $1.damage }
        let topHealer = partyPerformance.max { $0.healing < $1.healing }
        let topTank = partyPerformance.max { $0.damageTaken < $1.damageTaken }
        let topAssist = partyPerformance.max { $0.assists < $1.assists }

        // Check for special titles
        let untouchable = partyPerformance.first { $0.damageTaken == 0 }

        // Priority: Untouchable > Slayer > Destroyer > Lifebringer > Guardian
        if let u = untouchable, u.kills > 0 {
            mvp = u.character
            mvpTitle = .untouchable
        } else if let k = topKiller, k.kills >= 2 {
            mvp = k.character
            mvpTitle = .slayer
        } else if let d = topDamage, d.damage > 0 {
            mvp = d.character
            mvpTitle = .destroyer
        } else if let h = topHealer, h.healing > 20 {
            mvp = h.character
            mvpTitle = .lifebringer
        } else if let t = topTank, t.damageTaken > 30 {
            mvp = t.character
            mvpTitle = .guardian
        } else if let a = topAssist, a.assists > 0 {
            mvp = a.character
            mvpTitle = .tactician
        } else {
            mvp = party.first
            mvpTitle = .survivor
        }
    }

    private static func determineVictoryType(stats: CombatStats, party: [Character]) -> VictoryType {
        // Flawless: No damage taken
        if stats.totalDamageTaken == 0 {
            return .flawless
        }

        // Swift: Under 5 turns
        if stats.turnsElapsed < 5 {
            return .swift
        }

        // Pyrrhic: Lost party members
        let casualties = party.filter { $0.hp <= 0 }.count
        if casualties > 0 {
            return .pyrrhic
        }

        // Dominant: High kill count with low damage taken
        if stats.enemiesKilled >= 5 && stats.totalDamageTaken < 20 {
            return .dominant
        }

        return .standard
    }
}

/// Individual character performance data
struct CharacterPerformance: Identifiable {
    let id = UUID()
    let character: Character
    let kills: Int
    let damage: Int
    let healing: Int
    let damageTaken: Int
    let assists: Int

    var score: Int {
        return kills * 100 + damage + healing * 2 + assists * 50
    }
}

/// Full victory screen view
struct VictoryScreenView: View {
    @ObservedObject var viewModel: VictoryScreenViewModel
    let onContinue: () -> Void

    @State private var showRewards = false
    @State private var animationPhase = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.1),
                    Color(red: 0.15, green: 0.2, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Victory Banner
                    victoryBanner

                    // Combat Summary
                    combatSummaryCard

                    // MVP Section
                    if let mvp = viewModel.mvp {
                        mvpCard(mvp)
                    }

                    // Party Performance
                    partyPerformanceCard

                    // Rewards
                    if showRewards {
                        rewardsCard
                    }

                    // Continue Button
                    Button("Continue") {
                        onContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Victory Banner

    private var victoryBanner: some View {
        VStack(spacing: 8) {
            Text(viewModel.victoryType.rawValue.uppercased())
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(victoryColor)
                .shadow(color: victoryColor.opacity(0.5), radius: 10)

            Text(viewModel.quest.title)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))

            if viewModel.victoryType != .standard {
                Text(victoryTypeDescription)
                    .font(.subheadline)
                    .foregroundColor(victoryColor.opacity(0.8))
                    .italic()
            }
        }
        .padding(.vertical, 20)
    }

    private var victoryColor: Color {
        switch viewModel.victoryType {
        case .flawless: return .yellow
        case .swift: return .cyan
        case .pyrrhic: return .orange
        case .dominant: return .purple
        case .standard: return .green
        }
    }

    private var victoryTypeDescription: String {
        switch viewModel.victoryType {
        case .flawless: return "Not a scratch!"
        case .swift: return "Lightning fast!"
        case .pyrrhic: return "A costly victory..."
        case .dominant: return "Total domination!"
        case .standard: return ""
        }
    }

    // MARK: - Combat Summary

    private var combatSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combat Summary")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                statItem(label: "Turns", value: "\(viewModel.combatStats.turnsElapsed)")
                statItem(label: "Enemies", value: "\(viewModel.combatStats.enemiesKilled)")
                statItem(label: "Damage", value: "\(viewModel.combatStats.totalDamageDealt)")
                statItem(label: "Taken", value: "\(viewModel.combatStats.totalDamageTaken)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - MVP Card

    private func mvpCard(_ mvp: Character) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("MVP")
                    .font(.headline)
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }

            HStack(spacing: 16) {
                // MVP Portrait placeholder
                ZStack {
                    Circle()
                        .fill(classColor(mvp.characterClass))
                        .frame(width: 70, height: 70)

                    Text(String(mvp.characterClass.rawValue.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mvp.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: viewModel.mvpTitle.icon)
                            .foregroundColor(.yellow)
                        Text(viewModel.mvpTitle.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }

                    Text(viewModel.mvpTitle.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // MVP Quote
            Text("\"\(VictoryQuotes.quote(for: mvp.characterClass))\"")
                .font(.subheadline.italic())
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                )
        )
    }

    // MARK: - Party Performance

    private var partyPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Party Results")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(viewModel.partyPerformance.sorted { $0.score > $1.score }) { perf in
                performanceRow(perf)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    private func performanceRow(_ perf: CharacterPerformance) -> some View {
        HStack(spacing: 12) {
            // Portrait
            ZStack {
                Circle()
                    .fill(classColor(perf.character.characterClass))
                    .frame(width: 40, height: 40)

                Text(String(perf.character.characterClass.rawValue.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(perf.character.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text("\(perf.character.race.rawValue) \(perf.character.characterClass.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                miniStat(icon: "flame.fill", value: perf.kills, color: .red)
                miniStat(icon: "bolt.fill", value: perf.damage, color: .orange)
                if perf.healing > 0 {
                    miniStat(icon: "heart.fill", value: perf.healing, color: .green)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func miniStat(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text("\(value)")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }

    // MARK: - Rewards

    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                // Gold
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("+\(viewModel.rewards.gold)")
                            .font(.title3.bold())
                            .foregroundColor(.yellow)
                        Text("Gold")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // XP
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("+\(viewModel.rewards.xp)")
                            .font(.title3.bold())
                            .foregroundColor(.purple)
                        Text("XP each")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            // Items
            if !viewModel.rewards.itemIds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Items Found:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ForEach(viewModel.rewards.itemIds, id: \.self) { itemId in
                        if let template = ItemTemplate(rawValue: itemId) {
                            HStack {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.cyan)
                                Text(template.displayName)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Helpers

    private func classColor(_ characterClass: CharacterClass) -> Color {
        switch characterClass {
        case .warrior: return .red
        case .rogue: return .purple
        case .mage: return .blue
        case .cleric: return .yellow
        }
    }

    private func startAnimations() {
        // Delay rewards reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showRewards = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let party = [
        Character(name: "Grimjaw", race: .orc, characterClass: .warrior),
        Character(name: "Elara", race: .elf, characterClass: .mage)
    ]

    let stats = CombatStats()

    let quest = Quest.goblinCamp()

    let viewModel = VictoryScreenViewModel(
        party: party,
        combatStats: stats,
        quest: quest
    )

    return VictoryScreenView(viewModel: viewModel) {
        print("Continue")
    }
}
