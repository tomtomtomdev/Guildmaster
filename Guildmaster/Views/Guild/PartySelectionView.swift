//
//  PartySelectionView.swift
//  Guildmaster
//
//  View for selecting party members for a quest
//

import SwiftUI

/// View for selecting party members before starting a quest
struct PartySelectionView: View {
    @ObservedObject var guildManager = GuildManager.shared
    @ObservedObject var questManager = QuestManager.shared
    @Binding var currentScreen: GameScreen

    @State private var selectedCharacterIds: Set<UUID> = []
    @State private var showingConfirmation = false

    private let maxPartySize = 4

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                if let quest = questManager.activeQuest {
                    // Quest info
                    questInfoBar(quest: quest)

                    // Party selection
                    ScrollView {
                        VStack(spacing: 16) {
                            // Selected party
                            selectedPartySection

                            Divider()
                                .background(Color.gray.opacity(0.3))

                            // Available roster
                            availableRosterSection
                        }
                        .padding()
                    }

                    // Start button
                    startButtonSection
                } else {
                    // No quest selected
                    noQuestView
                }
            }
        }
        .alert("Begin Quest?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Start Quest") {
                startQuest()
            }
        } message: {
            Text("Your party of \(selectedCharacterIds.count) will embark on this quest.")
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: { currentScreen = .questBoard }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.blue)
            }

            Spacer()

            Text("Select Party")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Clear selection
            Button("Clear") {
                selectedCharacterIds.removeAll()
            }
            .foregroundColor(.red)
            .opacity(selectedCharacterIds.isEmpty ? 0.5 : 1)
            .disabled(selectedCharacterIds.isEmpty)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private func questInfoBar(quest: Quest) -> some View {
        HStack {
            Image(systemName: quest.type.icon)
                .foregroundColor(.orange)

            Text(quest.title)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            Text("Lv.\(quest.recommendedLevel)+")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }

    private var selectedPartySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Party")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(selectedCharacterIds.count)/\(maxPartySize)")
                    .font(.caption)
                    .foregroundColor(selectedCharacterIds.count > 0 ? .green : .gray)
            }

            if selectedCharacterIds.isEmpty {
                Text("Select up to \(maxPartySize) adventurers")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(selectedCharacters) { character in
                    SelectableCharacterRow(
                        character: character,
                        isSelected: true,
                        onToggle: { toggleSelection(character) }
                    )
                }
            }
        }
    }

    private var availableRosterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Adventurers")
                .font(.headline)
                .foregroundColor(.white)

            if availableCharacters.isEmpty {
                Text("No available adventurers")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(availableCharacters) { character in
                    SelectableCharacterRow(
                        character: character,
                        isSelected: selectedCharacterIds.contains(character.id),
                        onToggle: { toggleSelection(character) }
                    )
                }
            }
        }
    }

    private var startButtonSection: some View {
        VStack(spacing: 8) {
            // Party summary
            if !selectedCharacters.isEmpty {
                partySummary
            }

            // Start button
            Button(action: { showingConfirmation = true }) {
                HStack {
                    Image(systemName: "flag.fill")
                    Text("Begin Quest")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canStartQuest ? Color.green : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canStartQuest)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var partySummary: some View {
        HStack(spacing: 16) {
            // Average level
            VStack {
                Text("\(averageLevel)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Avg Lv")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            // Average INT
            VStack {
                Text("\(averageINT)")
                    .font(.headline)
                    .foregroundColor(intColor)
                Text("Avg INT")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            // Class composition
            HStack(spacing: 4) {
                ForEach(selectedCharacters) { character in
                    classIcon(for: character.characterClass)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var noQuestView: some View {
        VStack(spacing: 16) {
            Image(systemName: "scroll")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Quest Selected")
                .font(.headline)
                .foregroundColor(.gray)

            Button("Select a Quest") {
                currentScreen = .questBoard
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var selectedCharacters: [Character] {
        guildManager.roster.filter { selectedCharacterIds.contains($0.id) }
    }

    private var availableCharacters: [Character] {
        guildManager.roster.filter {
            $0.isAlive && !selectedCharacterIds.contains($0.id)
        }
    }

    private var canStartQuest: Bool {
        return !selectedCharacterIds.isEmpty && selectedCharacterIds.count <= maxPartySize
    }

    private var averageLevel: Int {
        guard !selectedCharacters.isEmpty else { return 0 }
        return selectedCharacters.reduce(0) { $0 + $1.level } / selectedCharacters.count
    }

    private var averageINT: Int {
        guard !selectedCharacters.isEmpty else { return 0 }
        return selectedCharacters.reduce(0) { $0 + $1.stats.int } / selectedCharacters.count
    }

    private var intColor: Color {
        if averageINT <= 8 { return .red }
        if averageINT <= 14 { return .yellow }
        return .green
    }

    // MARK: - Actions

    private func toggleSelection(_ character: Character) {
        if selectedCharacterIds.contains(character.id) {
            selectedCharacterIds.remove(character.id)
        } else if selectedCharacterIds.count < maxPartySize {
            selectedCharacterIds.insert(character.id)
        }
    }

    private func classIcon(for characterClass: CharacterClass) -> some View {
        let color: Color
        switch characterClass {
        case .warrior: color = .red
        case .rogue: color = .purple
        case .mage: color = .blue
        case .cleric: color = .yellow
        }

        return Text(String(characterClass.rawValue.prefix(1)))
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(color))
    }

    private func startQuest() {
        guard let quest = questManager.activeQuest else { return }

        let party = selectedCharacters
        questManager.startQuest(quest, party: party)

        // Navigate to quest flow
        currentScreen = .questFlow
    }
}

// MARK: - Selectable Character Row

struct SelectableCharacterRow: View {
    let character: Character
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)

                // Class icon
                classIcon

                // Character info
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Lv.\(character.level)")
                        .font(.caption)
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Text("INT:")
                            .foregroundColor(.gray)
                        Text("\(character.stats.int)")
                            .foregroundColor(intColor)
                    }
                    .font(.caption2)
                }

                // HP indicator
                HealthBar(
                    current: character.secondaryStats.hp,
                    max: character.secondaryStats.maxHP,
                    width: 40
                )
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }

    private var classIcon: some View {
        let color: Color
        switch character.characterClass {
        case .warrior: color = .red
        case .rogue: color = .purple
        case .mage: color = .blue
        case .cleric: color = .yellow
        }

        return ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 36, height: 36)

            Text(String(character.characterClass.rawValue.prefix(1)))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }

    private var intColor: Color {
        if character.stats.int <= 8 { return .red }
        if character.stats.int <= 14 { return .yellow }
        return .green
    }
}

#Preview {
    PartySelectionView(currentScreen: .constant(.partySelection))
}
