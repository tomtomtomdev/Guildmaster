//
//  TrainingView.swift
//  Guildmaster
//
//  View for managing character training activities
//

import SwiftUI

/// View for training guild members
struct TrainingView: View {
    @ObservedObject var guildManager = GuildManager.shared
    @ObservedObject var trainingManager = TrainingManager.shared
    @Binding var currentScreen: GameScreen

    @State private var selectedCharacter: Character?
    @State private var selectedActivity: TrainingActivity?
    @State private var showingActivitySelection = false

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                // Training slots status
                trainingSlotsHeader

                ScrollView {
                    VStack(spacing: 16) {
                        // Currently training section
                        if !trainingManager.trainingSlots.isEmpty {
                            currentlyTrainingSection
                        }

                        // Available characters section
                        availableCharactersSection

                        // Training activities reference
                        trainingActivitiesReference
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingActivitySelection) {
            if let character = selectedCharacter {
                ActivitySelectionSheet(
                    character: character,
                    onSelect: { activity in
                        startTraining(character: character, activity: activity)
                        showingActivitySelection = false
                    }
                )
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

            Text("Training Grounds")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Day counter
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text("Day \(guildManager.currentDay)")
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var trainingSlotsHeader: some View {
        HStack {
            Text("Training Slots")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text("\(trainingManager.trainingSlots.count)/\(trainingManager.maxSlots)")
                .font(.headline)
                .foregroundColor(slotsColor)

            ProgressView(value: Double(trainingManager.trainingSlots.count),
                        total: Double(trainingManager.maxSlots))
                .progressViewStyle(LinearProgressViewStyle(tint: slotsColor))
                .frame(width: 80)
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }

    private var slotsColor: Color {
        let ratio = Double(trainingManager.trainingSlots.count) / Double(trainingManager.maxSlots)
        if ratio >= 1.0 { return .red }
        if ratio >= 0.75 { return .orange }
        return .green
    }

    // MARK: - Currently Training Section

    private var currentlyTrainingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently Training")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(trainingManager.trainingSlots) { slot in
                TrainingSlotCard(slot: slot, onCancel: {
                    trainingManager.cancelTraining(for: slot.characterId)
                })
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Available Characters Section

    private var availableCharactersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available for Training")
                .font(.headline)
                .foregroundColor(.white)

            let availableCharacters = guildManager.roster.filter { !trainingManager.isTraining($0) }

            if availableCharacters.isEmpty {
                Text("All adventurers are busy")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.vertical, 20)
            } else {
                ForEach(availableCharacters) { character in
                    AvailableForTrainingCard(character: character) {
                        selectedCharacter = character
                        showingActivitySelection = true
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Training Activities Reference

    private var trainingActivitiesReference: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Activities")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(TrainingActivity.allCases, id: \.self) { activity in
                ActivityInfoRow(activity: activity)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func startTraining(character: Character, activity: TrainingActivity) {
        _ = trainingManager.startTraining(character: character, activity: activity)
        selectedCharacter = nil
        selectedActivity = nil
    }
}

// MARK: - Training Slot Card

struct TrainingSlotCard: View {
    let slot: TrainingSlot
    let onCancel: () -> Void

    @ObservedObject var guildManager = GuildManager.shared

    var body: some View {
        if let character = guildManager.character(byId: slot.characterId) {
            HStack(spacing: 12) {
                CharacterPortrait(character: character, size: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: slot.activity.icon)
                            .foregroundColor(.blue)
                        Text(slot.activity.rawValue)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Progress
                    ProgressView(value: slot.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 60)

                    Text("\(slot.daysRemaining) day\(slot.daysRemaining == 1 ? "" : "s") left")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Available For Training Card

struct AvailableForTrainingCard: View {
    let character: Character
    let onTrain: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CharacterPortrait(character: character, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Status indicators
                HStack(spacing: 8) {
                    if character.stress > 50 {
                        Label("Stressed", systemImage: "brain.head.profile")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    if character.secondaryStats.hp < character.secondaryStats.maxHP {
                        Label("Injured", systemImage: "bandage")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            Button(action: onTrain) {
                Text("Train")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Activity Info Row

struct ActivityInfoRow: View {
    let activity: TrainingActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(activity.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(activity.duration) day\(activity.duration == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(resultText)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private var resultText: String {
        let result = activity.baseResult
        switch result.type {
        case .xpGain:
            return "+\(result.value) XP"
        case .statBoost:
            return "+\(result.value) stat"
        case .stressReduction:
            return "-\(result.value) stress"
        case .healing:
            return "+\(result.value) HP"
        case .satisfactionGain:
            return "+\(result.value)% happy"
        default:
            return "Various"
        }
    }
}

// MARK: - Activity Selection Sheet

struct ActivitySelectionSheet: View {
    let character: Character
    let onSelect: (TrainingActivity) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var trainingManager = TrainingManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Character header
                        HStack(spacing: 12) {
                            CharacterPortrait(character: character, size: 60)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(character.name)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Select a training activity")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Activity options
                        ForEach(TrainingActivity.allCases, id: \.self) { activity in
                            ActivitySelectionCard(
                                activity: activity,
                                isAvailable: meetsRequirements(activity),
                                onSelect: { onSelect(activity) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func meetsRequirements(_ activity: TrainingActivity) -> Bool {
        switch activity {
        case .soloPractice, .rest, .meditation:
            return true
        case .sparring:
            let availablePartners = GuildManager.shared.roster.filter {
                $0.id != character.id && !trainingManager.isTraining($0)
            }
            return !availablePartners.isEmpty
        case .study:
            return character.stats.int >= 8
        case .physicalConditioning:
            return character.secondaryStats.hp > character.secondaryStats.maxHP / 2
        }
    }
}

// MARK: - Activity Selection Card

struct ActivitySelectionCard: View {
    let activity: TrainingActivity
    let isAvailable: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            if isAvailable { onSelect() }
        }) {
            HStack(spacing: 12) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundColor(isAvailable ? .blue : .gray)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.rawValue)
                        .font(.headline)
                        .foregroundColor(isAvailable ? .white : .gray)

                    Text(activity.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 16) {
                        Label("\(activity.duration) days", systemImage: "clock")
                        Label(resultLabel, systemImage: "arrow.up.circle")
                    }
                    .font(.caption2)
                    .foregroundColor(isAvailable ? .blue : .gray)
                }

                Spacer()

                if isAvailable {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                } else {
                    Text("Unavailable")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(isAvailable ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAvailable ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(!isAvailable)
    }

    private var resultLabel: String {
        let result = activity.baseResult
        switch result.type {
        case .xpGain: return "+\(result.value) XP"
        case .statBoost: return "+\(result.value) stat"
        case .stressReduction: return "-\(result.value) stress"
        case .healing: return "+\(result.value) HP"
        case .satisfactionGain: return "+\(result.value)% happy"
        default: return "Various"
        }
    }
}

#Preview {
    TrainingView(currentScreen: .constant(.training))
}
