//
//  GuildHallView.swift
//  Guildmaster
//
//  Main hub view for the guild
//

import SwiftUI

/// Main hub view where players manage their guild
struct GuildHallView: View {
    @ObservedObject var guildManager = GuildManager.shared
    @ObservedObject var questManager = QuestManager.shared

    @Binding var currentScreen: GameScreen

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: 0) {
                // Header
                headerView

                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Quest Board button
                        NavigationCard(
                            title: "Contract Board",
                            subtitle: "\(questManager.availableQuests.count) available quests",
                            icon: "scroll.fill",
                            badgeCount: questManager.availableQuests.count
                        ) {
                            currentScreen = .questBoard
                        }

                        // Barracks button
                        NavigationCard(
                            title: "Barracks",
                            subtitle: "\(guildManager.roster.count)/\(guildManager.maxRosterSize) adventurers",
                            icon: "person.3.fill",
                            badgeCount: nil
                        ) {
                            currentScreen = .barracks
                        }

                        // Recruitment button
                        NavigationCard(
                            title: "Recruitment",
                            subtitle: "\(RecruitmentManager.shared.recruitPool.count) candidates",
                            icon: "person.badge.plus",
                            badgeCount: nil
                        ) {
                            currentScreen = .recruitment
                        }

                        // Quick roster preview
                        rosterPreview
                    }
                    .padding()
                }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.12, blue: 0.1),
                Color(red: 0.2, green: 0.15, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(guildManager.guildName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))

                    Text("Day \(guildManager.currentDay)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Gold display
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(guildManager.gold)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
            }
            .padding()
            .background(Color.black.opacity(0.2))
        }
    }

    private var rosterPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Guild Roster")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button("View All") {
                    currentScreen = .barracks
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if guildManager.roster.isEmpty {
                Text("No adventurers hired yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(guildManager.roster.prefix(4)) { character in
                    CompactCharacterRow(character: character)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Navigation Card

struct NavigationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let badgeCount: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Badge or chevron
                if let count = badgeCount, count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(10)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Compact Character Row

struct CompactCharacterRow: View {
    let character: Character

    var body: some View {
        HStack(spacing: 12) {
            // Class indicator
            classIcon

            // Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(character.name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text("\(character.race.rawValue) \(character.characterClass.rawValue) Lv.\(character.level)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // HP bar
            HealthBar(
                current: character.secondaryStats.hp,
                max: character.secondaryStats.maxHP,
                width: 60
            )

            // Status indicator
            statusIndicator
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }

    private var classIcon: some View {
        ZStack {
            Circle()
                .fill(classColor.opacity(0.3))
                .frame(width: 32, height: 32)

            Text(String(character.characterClass.rawValue.prefix(1)))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(classColor)
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

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        if !character.isAlive {
            return .red
        } else if character.secondaryStats.hp < character.secondaryStats.maxHP / 3 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Health Bar

struct HealthBar: View {
    let current: Int
    let max: Int
    let width: CGFloat

    var body: some View {
        let percentage = max > 0 ? CGFloat(current) / CGFloat(max) : 0

        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: width, height: 6)

            // Fill
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor)
                .frame(width: width * percentage, height: 6)
        }
    }

    private var barColor: Color {
        let percentage = max > 0 ? Double(current) / Double(max) : 0
        if percentage > 0.5 {
            return .green
        } else if percentage > 0.25 {
            return .yellow
        } else {
            return .red
        }
    }
}

#Preview {
    GuildHallView(currentScreen: .constant(.guildHall))
}
