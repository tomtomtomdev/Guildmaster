//
//  QuestResultView.swift
//  Guildmaster
//
//  View showing quest completion results
//

import SwiftUI

/// View displaying quest results (victory or defeat)
struct QuestResultView: View {
    let quest: Quest
    let isVictory: Bool
    let party: [Character]
    let stats: CombatStatistics
    @Binding var currentScreen: GameScreen

    /// Convert item IDs to display names
    private var itemNames: [String] {
        quest.rewards.itemIds.compactMap { itemId in
            ItemTemplate(rawValue: itemId)?.displayName
        }
    }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: 24) {
                Spacer()

                // Result banner
                resultBanner

                // Quest info
                questInfoSection

                // Party results
                partyResultsSection

                // Statistics
                statisticsSection

                // Rewards (if victory)
                if isVictory {
                    rewardsSection
                }

                Spacer()

                // Continue button
                continueButton
            }
            .padding()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: isVictory ?
                [Color(red: 0.1, green: 0.2, blue: 0.1), Color(red: 0.15, green: 0.25, blue: 0.15)] :
                [Color(red: 0.2, green: 0.1, blue: 0.1), Color(red: 0.25, green: 0.15, blue: 0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var resultBanner: some View {
        VStack(spacing: 8) {
            Text(isVictory ? "VICTORY" : "DEFEAT")
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(isVictory ? .yellow : .red)

            if isVictory {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            } else {
                Image(systemName: "xmark.octagon.fill")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }

    private var questInfoSection: some View {
        HStack {
            Image(systemName: quest.type.icon)
                .foregroundColor(.orange)

            Text(quest.title)
                .font(.headline)
                .foregroundColor(.white)

            Text("(\(quest.tier.rawValue))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }

    private var partyResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Party Results")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(party) { character in
                PartyMemberResult(character: character, stats: characterStats(for: character))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func characterStats(for character: Character) -> CharacterCombatStats {
        // In a full implementation, these would be tracked per-character
        return CharacterCombatStats(
            kills: stats.enemiesKilled / max(1, party.filter { $0.isAlive }.count),
            damageDealt: stats.totalDamageDealt / max(1, party.count),
            healingDone: stats.totalHealing / max(1, party.count),
            survived: character.isAlive
        )
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combat Statistics")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatBox(label: "Turns", value: "\(stats.turnsElapsed)")
                StatBox(label: "Enemies Slain", value: "\(stats.enemiesKilled)")
                StatBox(label: "Damage Dealt", value: "\(stats.totalDamageDealt)")
                StatBox(label: "Healing Done", value: "\(stats.totalHealing)")
                StatBox(label: "Critical Hits", value: "\(stats.criticalHits)")
                StatBox(label: "Abilities Used", value: "\(stats.abilitiesUsed)")
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

            HStack(spacing: 24) {
                // Gold
                VStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    Text("+\(quest.rewards.gold)")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    Text("Gold")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // XP
                VStack {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("+\(quest.rewards.xp)")
                        .font(.headline)
                        .foregroundColor(.purple)
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
                            .foregroundColor(.blue)
                        Text("Items")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            // Item list
            if !quest.rewards.itemIds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(itemNames, id: \.self) { name in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private var continueButton: some View {
        Button(action: {
            QuestManager.shared.advanceQuestFlow()
            currentScreen = .guildHall
        }) {
            Text("Return to Guild Hall")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(.bottom)
    }
}

// MARK: - Party Member Result

struct PartyMemberResult: View {
    let character: Character
    let stats: CharacterCombatStats

    var body: some View {
        HStack(spacing: 12) {
            // Portrait with status
            ZStack {
                CharacterPortrait(character: character, size: 44)

                if !stats.survived {
                    Color.black.opacity(0.5)
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)

                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
            }

            // Name and class
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(character.name)
                        .font(.subheadline)
                        .foregroundColor(stats.survived ? .white : .gray)

                    if !stats.survived {
                        Text("(KO)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("\(character.characterClass.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                VStack {
                    Text("\(stats.kills)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Text("Kills")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                VStack {
                    Text("\(stats.damageDealt)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Text("Dmg")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                if stats.healingDone > 0 {
                    VStack {
                        Text("\(stats.healingDone)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("Heal")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Character Combat Stats

struct CharacterCombatStats {
    let kills: Int
    let damageDealt: Int
    let healingDone: Int
    let survived: Bool
}

#Preview {
    QuestResultView(
        quest: Quest.goblinCamp(),
        isVictory: true,
        party: [
            Character(name: "Test Warrior", race: .human, characterClass: .warrior),
            Character(name: "Test Mage", race: .elf, characterClass: .mage)
        ],
        stats: CombatStatistics(
            totalDamageDealt: 250,
            totalHealing: 45,
            kills: 6,
            criticalHits: 3,
            misses: 2,
            abilitiesUsed: 12,
            turnsElapsed: 8,
            enemiesKilled: 6,
            partyDeaths: 0
        ),
        currentScreen: .constant(.questResult)
    )
}
