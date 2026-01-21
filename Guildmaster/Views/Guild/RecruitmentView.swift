//
//  RecruitmentView.swift
//  Guildmaster
//
//  View for hiring new adventurers
//

import SwiftUI

/// View for browsing and hiring new adventurers
struct RecruitmentView: View {
    @ObservedObject var recruitmentManager = RecruitmentManager.shared
    @ObservedObject var guildManager = GuildManager.shared
    @Binding var currentScreen: GameScreen

    @State private var selectedRecruit: Character?
    @State private var showingHireConfirmation = false
    @State private var sortOption: SortOption = .quality
    @State private var filterClass: CharacterClass?

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Gold and capacity
                statusBar

                // Filters
                filterBar

                // Recruit list
                ScrollView {
                    VStack(spacing: 12) {
                        if filteredRecruits.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(sortedRecruits) { recruit in
                                RecruitCard(
                                    recruit: recruit,
                                    canAfford: guildManager.gold >= recruit.hireCost,
                                    canHire: guildManager.roster.count < guildManager.maxRosterSize
                                ) {
                                    selectedRecruit = recruit
                                    showingHireConfirmation = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .alert("Hire \(selectedRecruit?.name ?? "Adventurer")?", isPresented: $showingHireConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Hire") {
                hireSelectedRecruit()
            }
        } message: {
            if let recruit = selectedRecruit {
                Text("Cost: \(recruit.hireCost) gold\n\nThis will add \(recruit.name) to your roster.")
            }
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

            Text("Recruitment")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Button(action: { recruitmentManager.refreshPool() }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var statusBar: some View {
        HStack {
            // Gold
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(guildManager.gold)")
                    .foregroundColor(.white)
            }

            Spacer()

            // Roster capacity
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("\(guildManager.roster.count)/\(guildManager.maxRosterSize)")
                    .foregroundColor(guildManager.roster.count >= guildManager.maxRosterSize ? .red : .white)
            }
        }
        .font(.subheadline)
        .padding()
        .background(Color.black.opacity(0.2))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Sort picker
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            sortOption = option
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }

                Divider()
                    .frame(height: 20)

                // Class filters
                FilterChip(title: "All", isSelected: filterClass == nil) {
                    filterClass = nil
                }

                ForEach(CharacterClass.allCases, id: \.self) { charClass in
                    FilterChip(title: charClass.rawValue, isSelected: filterClass == charClass) {
                        filterClass = charClass
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Recruits Available")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Check back later for new candidates")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))

            Button("Refresh Pool") {
                recruitmentManager.refreshPool()
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Computed Properties

    private var filteredRecruits: [Character] {
        if let filterClass = filterClass {
            return recruitmentManager.recruitPool.filter { $0.characterClass == filterClass }
        }
        return recruitmentManager.recruitPool
    }

    private var sortedRecruits: [Character] {
        switch sortOption {
        case .quality:
            return filteredRecruits.sorted { $0.stats.total > $1.stats.total }
        case .cost:
            return filteredRecruits.sorted { $0.hireCost < $1.hireCost }
        case .intelligence:
            return filteredRecruits.sorted { $0.stats.int > $1.stats.int }
        case .name:
            return filteredRecruits.sorted { $0.name < $1.name }
        }
    }

    // MARK: - Actions

    private func hireSelectedRecruit() {
        guard let recruit = selectedRecruit else { return }

        if guildManager.hireCharacter(recruit) {
            recruitmentManager.removeFromPool(recruit)
        }
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable {
    case quality = "Quality"
    case cost = "Cost"
    case intelligence = "INT"
    case name = "Name"
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(16)
        }
    }
}

// MARK: - Recruit Card

struct RecruitCard: View {
    let recruit: Character
    let canAfford: Bool
    let canHire: Bool
    let onHire: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main info
            HStack(spacing: 12) {
                // Portrait
                CharacterPortrait(character: recruit, size: 50)

                // Name and class
                VStack(alignment: .leading, spacing: 2) {
                    Text(recruit.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(recruit.race.rawValue) \(recruit.characterClass.rawValue)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Hire button
                Button(action: onHire) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                        Text("\(recruit.hireCost)")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!canAfford || !canHire)
            }
            .padding()

            // Stats preview
            HStack(spacing: 8) {
                StatMini(name: "STR", value: recruit.stats.str)
                StatMini(name: "DEX", value: recruit.stats.dex)
                StatMini(name: "CON", value: recruit.stats.con)
                StatMini(name: "INT", value: recruit.stats.int, highlight: true)
                StatMini(name: "WIS", value: recruit.stats.wis)
                StatMini(name: "CHA", value: recruit.stats.cha)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // Personality traits
            HStack(spacing: 8) {
                if recruit.personality.greedy >= 7 {
                    TraitBadge(text: "Greedy", color: .orange)
                }
                if recruit.personality.loyal >= 7 {
                    TraitBadge(text: "Loyal", color: .green)
                }
                if recruit.personality.brave >= 7 {
                    TraitBadge(text: "Brave", color: .blue)
                }
                if recruit.personality.cautious >= 7 {
                    TraitBadge(text: "Cautious", color: .purple)
                }

                Spacer()

                // INT tier indicator
                Text(recruit.intelligenceTier.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(intTierColor.opacity(0.2))
                    .foregroundColor(intTierColor)
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var buttonColor: Color {
        if !canHire { return .gray }
        if !canAfford { return .red.opacity(0.5) }
        return .green
    }

    private var borderColor: Color {
        if recruit.stats.total >= 75 { return .yellow.opacity(0.5) }  // High quality
        return Color.white.opacity(0.1)
    }

    private var intTierColor: Color {
        switch recruit.intelligenceTier {
        case .low: return .red
        case .medium: return .yellow
        case .high: return .green
        }
    }
}

// MARK: - Stat Mini

struct StatMini: View {
    let name: String
    let value: Int
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 8))
                .foregroundColor(.gray)

            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(highlight ? highlightColor : statColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var statColor: Color {
        if value <= 8 { return .red.opacity(0.7) }
        if value <= 12 { return .white.opacity(0.7) }
        if value <= 16 { return .green.opacity(0.7) }
        return .yellow
    }

    private var highlightColor: Color {
        if value <= 8 { return .red }
        if value <= 14 { return .yellow }
        return .green
    }
}

// MARK: - Trait Badge

struct TraitBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

#Preview {
    RecruitmentView(currentScreen: .constant(.recruitment))
}
