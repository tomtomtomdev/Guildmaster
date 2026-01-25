//
//  BarracksView.swift
//  Guildmaster
//
//  View for managing the guild roster
//

import SwiftUI

/// View for viewing and managing hired adventurers
struct BarracksView: View {
    @ObservedObject var guildManager = GuildManager.shared
    @Binding var currentScreen: GameScreen

    @State private var selectedCharacter: Character?
    @State private var showingCharacterDetail = false
    @State private var showingDismissConfirmation = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Roster capacity
                capacityBar

                // Character list
                ScrollView {
                    VStack(spacing: 12) {
                        if guildManager.roster.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(guildManager.roster) { character in
                                CharacterCard(character: character) {
                                    selectedCharacter = character
                                    showingCharacterDetail = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingCharacterDetail) {
            if let character = selectedCharacter {
                CharacterDetailSheet(
                    character: character,
                    onDismiss: {
                        selectedCharacter = character
                        showingDismissConfirmation = true
                    },
                    onRest: {
                        guildManager.restCharacter(character)
                    }
                )
            }
        }
        .alert("Dismiss Adventurer?", isPresented: $showingDismissConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Dismiss", role: .destructive) {
                if let character = selectedCharacter {
                    guildManager.dismissCharacter(character)
                }
            }
        } message: {
            if let character = selectedCharacter {
                Text("\(character.name) will leave the guild permanently.")
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

            Text("Barracks")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Placeholder for symmetry
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
    }

    private var capacityBar: some View {
        HStack {
            Text("Roster")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text("\(guildManager.roster.count)/\(guildManager.maxRosterSize)")
                .font(.headline)
                .foregroundColor(capacityColor)

            // Progress bar
            ProgressView(value: Double(guildManager.roster.count), total: Double(guildManager.maxRosterSize))
                .progressViewStyle(LinearProgressViewStyle(tint: capacityColor))
                .frame(width: 100)
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }

    private var capacityColor: Color {
        let ratio = Double(guildManager.roster.count) / Double(guildManager.maxRosterSize)
        if ratio >= 1.0 { return .red }
        if ratio >= 0.8 { return .orange }
        return .green
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Adventurers")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Visit recruitment to hire adventurers")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))

            Button("Go to Recruitment") {
                currentScreen = .recruitment
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Character Card

struct CharacterCard: View {
    let character: Character
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main info row
                HStack(spacing: 12) {
                    // Portrait placeholder
                    CharacterPortrait(character: character, size: 60)

                    // Name and class
                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            Text("Lv.\(character.level)")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text("INT: \(character.stats.int)")
                                .font(.caption)
                                .foregroundColor(intColor)
                        }
                    }

                    Spacer()

                    // Status
                    VStack(alignment: .trailing, spacing: 4) {
                        statusBadge

                        // Satisfaction
                        HStack(spacing: 2) {
                            Image(systemName: satisfactionIcon)
                                .foregroundColor(satisfactionColor)
                            Text("\(character.satisfaction)%")
                                .foregroundColor(satisfactionColor)
                        }
                        .font(.caption2)
                    }
                }
                .padding()

                // Health and resource bars
                HStack(spacing: 16) {
                    // HP
                    ResourceBar(
                        label: "HP",
                        current: character.secondaryStats.hp,
                        max: character.secondaryStats.maxHP,
                        color: .red
                    )

                    // Stamina/Mana based on class
                    if character.characterClass == .mage || character.characterClass == .cleric {
                        ResourceBar(
                            label: "MP",
                            current: character.secondaryStats.mana,
                            max: character.secondaryStats.maxMana,
                            color: .blue
                        )
                    } else {
                        ResourceBar(
                            label: "ST",
                            current: character.secondaryStats.stamina,
                            max: character.secondaryStats.maxStamina,
                            color: .yellow
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private var intColor: Color {
        if character.stats.int <= 8 { return .red }
        if character.stats.int <= 14 { return .yellow }
        return .green
    }

    private var statusBadge: some View {
        Group {
            if !character.isAlive {
                Text("DEAD")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            } else if character.daysSinceRest > 7 {
                Text("TIRED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            } else {
                Text("READY")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(4)
            }
        }
    }

    private var satisfactionIcon: String {
        if character.satisfaction >= 70 { return "face.smiling" }
        if character.satisfaction >= 40 { return "face.dashed" }
        return "face.dashed.fill"
    }

    private var satisfactionColor: Color {
        if character.satisfaction >= 70 { return .green }
        if character.satisfaction >= 40 { return .yellow }
        return .red
    }
}

// MARK: - Character Portrait

struct CharacterPortrait: View {
    let character: Character
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(classColor.opacity(0.2))
                .frame(width: size, height: size)

            // Class letter
            Text(String(character.characterClass.rawValue.prefix(1)))
                .font(.system(size: size * 0.4))
                .fontWeight(.bold)
                .foregroundColor(classColor)

            // Level badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(character.level)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: size * 0.35, height: size * 0.35)
                        .background(Circle().fill(Color.blue))
                }
            }
            .frame(width: size, height: size)
        }
    }

    private var classColor: Color {
        switch character.characterClass {
        case .warrior: return .red
        case .rogue: return .purple
        case .mage: return .blue
        case .cleric: return .yellow
        }
    }
}

// MARK: - Resource Bar

struct ResourceBar: View {
    let label: String
    let current: Int
    let max: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(current)/\(max)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))

                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: max > 0 ? geometry.size.width * CGFloat(current) / CGFloat(max) : 0)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Character Detail Sheet

struct CharacterDetailSheet: View {
    let character: Character
    let onDismiss: () -> Void
    let onRest: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingEquipment = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Portrait and basic info
                        characterHeader

                        // Equipment section
                        equipmentSection

                        // Stats
                        statsSection

                        // Combat info
                        combatSection

                        // History
                        historySection

                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(character.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingEquipment) {
            CharacterEquipmentView(character: character)
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equipment")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: { showingEquipment = true }) {
                    Text("Manage")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 16) {
                EquipmentSlotPreview(
                    label: "Weapon",
                    item: character.equipment.mainHand
                )

                EquipmentSlotPreview(
                    label: "Off-Hand",
                    item: character.equipment.offHand
                )

                EquipmentSlotPreview(
                    label: "Armor",
                    item: character.equipment.body
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var characterHeader: some View {
        HStack(spacing: 16) {
            CharacterPortrait(character: character, size: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("Level \(character.level)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // XP progress
                let xpNeeded = Character.xpForLevel(character.level + 1) - Character.xpForLevel(character.level)
                let xpProgress = character.xp - Character.xpForLevel(character.level)

                ProgressView(value: Double(xpProgress), total: Double(xpNeeded))
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))

                Text("\(xpProgress)/\(xpNeeded) XP")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attributes")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatDisplay(name: "STR", value: character.stats.str)
                StatDisplay(name: "DEX", value: character.stats.dex)
                StatDisplay(name: "CON", value: character.stats.con)
                StatDisplay(name: "INT", value: character.stats.int)
                StatDisplay(name: "WIS", value: character.stats.wis)
                StatDisplay(name: "CHA", value: character.stats.cha)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var combatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combat")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 16) {
                CombatStatDisplay(name: "HP", value: "\(character.secondaryStats.hp)/\(character.secondaryStats.maxHP)")
                CombatStatDisplay(name: "AC", value: "\(character.secondaryStats.armorClass)")
                CombatStatDisplay(name: "Init", value: "+\(character.secondaryStats.initiative)")
                CombatStatDisplay(name: "Speed", value: "\(character.secondaryStats.movementSpeed)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                VStack(alignment: .leading) {
                    Text("\(character.questsCompleted)")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Quests Done")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("\(character.questsFailed)")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("Quests Failed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("\(character.totalKills)")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Total Kills")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Rest button
            Button(action: onRest) {
                HStack {
                    Image(systemName: "bed.double.fill")
                    Text("Rest Character")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(character.daysSinceRest == 0)

            // Dismiss button
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "person.badge.minus")
                    Text("Dismiss from Guild")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Stat Display

struct StatDisplay: View {
    let name: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)

            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(statColor)

            Text(modifierText)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }

    private var statColor: Color {
        if value <= 8 { return .red }
        if value <= 12 { return .white }
        if value <= 16 { return .green }
        return .yellow
    }

    private var modifierText: String {
        let mod = (value - 10) / 2
        return mod >= 0 ? "+\(mod)" : "\(mod)"
    }
}

// MARK: - Combat Stat Display

struct CombatStatDisplay: View {
    let name: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Equipment Slot Preview

struct EquipmentSlotPreview: View {
    let label: String
    let item: Item?

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item != nil ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                if let item = item {
                    Image(systemName: item.icon)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "questionmark")
                        .foregroundColor(.gray.opacity(0.5))
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)

            if let item = item {
                Text(item.name)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BarracksView(currentScreen: .constant(.barracks))
}
