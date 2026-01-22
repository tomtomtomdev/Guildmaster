//
//  SettingsView.swift
//  Guildmaster
//
//  Settings and options view
//

import SwiftUI

/// Settings and options screen
struct SettingsView: View {
    @Binding var currentScreen: GameScreen
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var tutorialManager = TutorialManager.shared

    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        audioSection
                        tutorialSection
                        gameDataSection
                        creditsSection
                    }
                    .padding()
                }
            }
        }
        .alert("Reset Tutorial Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                tutorialManager.resetProgress()
            }
        } message: {
            Text("This will reset all tutorial hints. You'll see the tutorials again as you play.")
        }
        .alert("Delete Save Data", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                GuildManager.shared.deleteSaveData()
                currentScreen = .mainMenu
            }
        } message: {
            Text("This will permanently delete your save data. This action cannot be undone.")
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

            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Placeholder for alignment
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .opacity(0)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Audio Section

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Audio", icon: "speaker.wave.2.fill")

            // Music Toggle
            settingRow(
                title: "Music",
                subtitle: "Background music during gameplay",
                icon: "music.note"
            ) {
                Toggle("", isOn: $audioManager.isMusicEnabled)
                    .labelsHidden()
                    .tint(.blue)
            }

            // Music Volume
            if audioManager.isMusicEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Music Volume")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)
                        Slider(value: $audioManager.musicVolume, in: 0...1)
                            .tint(.blue)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.leading, 36)
            }

            Divider().background(Color.gray.opacity(0.3))

            // Sound Effects Toggle
            settingRow(
                title: "Sound Effects",
                subtitle: "Combat and UI sounds",
                icon: "waveform"
            ) {
                Toggle("", isOn: $audioManager.isSoundEnabled)
                    .labelsHidden()
                    .tint(.blue)
            }

            // Sound Volume
            if audioManager.isSoundEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sound Volume")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)
                        Slider(value: $audioManager.soundVolume, in: 0...1)
                            .tint(.blue)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.leading, 36)
            }
        }
        .sectionStyle()
    }

    // MARK: - Tutorial Section

    private var tutorialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Tutorials", icon: "questionmark.circle.fill")

            // Tutorial Toggle
            settingRow(
                title: "Show Tutorials",
                subtitle: "Display helpful hints while playing",
                icon: "lightbulb"
            ) {
                Toggle("", isOn: $tutorialManager.isTutorialEnabled)
                    .labelsHidden()
                    .tint(.blue)
            }

            Divider().background(Color.gray.opacity(0.3))

            // Tutorial Progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tutorial Progress")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text("\(tutorialManager.completedSteps.count)/\(TutorialStep.allCases.count) completed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                ProgressView(value: tutorialManager.completionPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 80)
            }
            .padding(.leading, 36)

            // Reset Tutorials Button
            Button(action: {
                showResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Tutorial Progress")
                }
                .font(.subheadline)
                .foregroundColor(.orange)
            }
            .padding(.leading, 36)
        }
        .sectionStyle()
    }

    // MARK: - Game Data Section

    private var gameDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Game Data", icon: "externaldrive.fill")

            // Save Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Save")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text("Guild: \(GuildManager.shared.guildName)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("Day \(GuildManager.shared.currentDay) | \(GuildManager.shared.roster.count) adventurers")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .padding(.leading, 36)

            Divider().background(Color.gray.opacity(0.3))

            // Delete Save Button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Save Data")
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }
            .padding(.leading, 36)
        }
        .sectionStyle()
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("About", icon: "info.circle.fill")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Version")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Alpha v0.3")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("Build")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("Phase 3 - Gold Master")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading, 36)

            Divider().background(Color.gray.opacity(0.3))

            Text("Guild Master is a tactical RPG where you manage a guild of adventurers. The twist: your party members have varying intelligence levels that affect their combat decisions!")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading, 36)
        }
        .sectionStyle()
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private func settingRow<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            content()
        }
    }
}

#Preview {
    SettingsView(currentScreen: .constant(.settings))
}
