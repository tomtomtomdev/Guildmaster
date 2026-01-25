//
//  QuestBoardView.swift
//  Guildmaster
//
//  Quest selection view showing available contracts
//

import SwiftUI

/// View for selecting quests from the contract board
struct QuestBoardView: View {
    @ObservedObject var questManager = QuestManager.shared
    @Binding var currentScreen: GameScreen

    @State private var selectedQuest: Quest?

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Quest list
                ScrollView {
                    VStack(spacing: 16) {
                        // Tutorial quests
                        if !tutorialQuests.isEmpty {
                            questSection(title: "Tutorial", quests: tutorialQuests, color: .gray)
                        }

                        // Basic quests
                        if !basicQuests.isEmpty {
                            questSection(title: "Basic Contracts", quests: basicQuests, color: .green)
                        }

                        // Advanced quests
                        if !advancedQuests.isEmpty {
                            questSection(title: "Advanced Contracts", quests: advancedQuests, color: .orange)
                        }

                        if questManager.availableQuests.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedQuest) { quest in
            QuestDetailSheet(quest: quest, currentScreen: $currentScreen)
        }
    }

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

            Text("Contract Board")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Button(action: { questManager.refreshQuestBoard() }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var tutorialQuests: [Quest] {
        questManager.availableQuests.filter { $0.tier == .tutorial }
    }

    private var basicQuests: [Quest] {
        questManager.availableQuests.filter { $0.tier == .basic }
    }

    private var advancedQuests: [Quest] {
        questManager.availableQuests.filter { $0.tier == .advanced }
    }

    private func questSection(title: String, quests: [Quest], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)

                Spacer()

                Text("\(quests.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            ForEach(quests) { quest in
                QuestCard(quest: quest) {
                    selectedQuest = quest
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "scroll")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Contracts Available")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Check back tomorrow for new opportunities")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Quest Card

struct QuestCard: View {
    let quest: Quest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack {
                    // Quest type icon
                    Image(systemName: quest.type.icon)
                        .foregroundColor(tierColor)

                    Text(quest.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Difficulty badge
                    Text(quest.tier.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tierColor.opacity(0.3))
                        .foregroundColor(tierColor)
                        .cornerRadius(4)
                }

                // Description
                Text(quest.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)

                // Rewards row
                HStack(spacing: 16) {
                    // Gold
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.yellow)
                        Text("\(quest.rewards.gold)")
                            .foregroundColor(.white)
                    }
                    .font(.caption)

                    // XP
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.purple)
                        Text("\(quest.rewards.xp) XP")
                            .foregroundColor(.white)
                    }
                    .font(.caption)

                    Spacer()

                    // Recommended level
                    Text("Lv.\(quest.recommendedLevel)+")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Encounter count
                HStack {
                    Image(systemName: "flame")
                        .foregroundColor(.orange)
                    Text("\(quest.encounters.count) encounters")
                        .foregroundColor(.gray)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .font(.caption)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tierColor.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var tierColor: Color {
        switch quest.tier {
        case .tutorial: return .gray
        case .basic: return .green
        case .advanced: return .orange
        }
    }
}

// MARK: - Quest Detail Sheet

struct QuestDetailSheet: View {
    let quest: Quest
    @Binding var currentScreen: GameScreen
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Quest header
                        questHeader

                        // Description
                        descriptionSection

                        // Flavor text
                        if !quest.flavorText.isEmpty {
                            flavorTextSection
                        }

                        // Encounters preview
                        encountersSection

                        // Rewards
                        rewardsSection

                        // Accept button
                        acceptButton
                    }
                    .padding()
                }
            }
            .navigationTitle(quest.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var questHeader: some View {
        HStack {
            Image(systemName: quest.type.icon)
                .font(.title)
                .foregroundColor(tierColor)

            VStack(alignment: .leading) {
                Text(quest.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(quest.tier.rawValue)
                    .font(.headline)
                    .foregroundColor(tierColor)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Recommended")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("Level \(quest.recommendedLevel)+")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mission Brief")
                .font(.headline)
                .foregroundColor(.white)

            Text(quest.description)
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    private var flavorTextSection: some View {
        Text(quest.flavorText)
            .font(.caption)
            .italic()
            .foregroundColor(.gray.opacity(0.8))
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
    }

    private var encountersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Encounters")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(Array(quest.encounters.enumerated()), id: \.offset) { index, encounter in
                HStack {
                    Text("\(index + 1).")
                        .foregroundColor(.gray)

                    if encounter.isBoss {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Boss Encounter")
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                        Text("Combat")
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("\(encounter.enemyTemplates.count) enemies")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                // Gold
                VStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    Text("\(quest.rewards.gold)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Gold")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // XP
                VStack {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("\(quest.rewards.xp)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("XP each")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Items
                if !quest.rewards.itemIds.isEmpty {
                    VStack {
                        Image(systemName: "gift.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("\(quest.rewards.itemIds.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Items")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var acceptButton: some View {
        Button(action: acceptQuest) {
            Text("Select Party")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(tierColor)
                .cornerRadius(12)
        }
    }

    private var tierColor: Color {
        switch quest.tier {
        case .tutorial: return .gray
        case .basic: return .green
        case .advanced: return .orange
        }
    }

    private func acceptQuest() {
        // Store selected quest and navigate to party selection
        QuestManager.shared.activeQuest = quest
        dismiss()
        currentScreen = .partySelection
    }
}

#Preview {
    QuestBoardView(currentScreen: .constant(.questBoard))
}
