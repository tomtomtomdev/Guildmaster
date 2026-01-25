//
//  QuestFlowView.swift
//  Guildmaster
//
//  View managing the quest flow between encounters
//

import SwiftUI

/// View that manages the flow between quest encounters
struct QuestFlowView: View {
    @ObservedObject var questManager = QuestManager.shared
    @ObservedObject var encounterManager = EncounterManager.shared
    @ObservedObject var combatManager = CombatManager.shared
    @ObservedObject var guildManager = GuildManager.shared
    @Binding var currentScreen: GameScreen

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.1, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            switch questManager.questFlowState {
            case .idle:
                // Should not normally be here
                Text("No active quest")
                    .foregroundColor(.gray)

            case .questStartDialogue:
                questStartView

            case .encounter:
                encounterView

            case .encounterComplete:
                encounterCompleteView

            case .victory:
                victoryView

            case .defeat:
                defeatView

            case .debrief:
                // Handled by QuestResultView
                EmptyView()
            }
        }
        .onAppear {
            if questManager.questFlowState == .questStartDialogue {
                // Auto-advance from dialogue after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    questManager.advanceQuestFlow()
                }
            }
        }
    }

    // MARK: - Quest Start

    private var questStartView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let quest = questManager.activeQuest {
                // Quest title
                Text(quest.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 0.5))

                // Quest type
                HStack {
                    Image(systemName: quest.type.icon)
                    Text(quest.type.rawValue)
                }
                .font(.headline)
                .foregroundColor(.orange)

                // Flavor text
                if !quest.flavorText.isEmpty {
                    Text(quest.flavorText)
                        .font(.body)
                        .italic()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Encounter count
                Text("\(quest.encounters.count) encounters ahead")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Begin button
            Button(action: { questManager.advanceQuestFlow() }) {
                Text("Begin Quest")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Encounter View

    private var encounterView: some View {
        Group {
            if combatManager.state == .inProgress {
                // Combat is active
                CombatView(combatManager: combatManager)
            } else if combatManager.state == .notInCombat || combatManager.state == .settingUp {
                // Need to start combat
                startEncounterView
            } else {
                // Combat finished - show result with continue button
                combatResultTransitionView
            }
        }
    }

    private var combatResultTransitionView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(combatManager.state == .victory ? "VICTORY!" : "DEFEAT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(combatManager.state == .victory ? .yellow : .red)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Enemies Defeated")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(combatManager.combatStats.enemiesKilled)")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Damage Dealt")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(combatManager.combatStats.totalDamageDealt)")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                Button(action: {
                    handleCombatResult()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(40)
        }
    }

    private var startEncounterView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let quest = questManager.activeQuest,
               let encounter = quest.currentEncounter {

                // Encounter number
                Text("Encounter \(quest.currentEncounterIndex + 1) of \(quest.encounters.count)")
                    .font(.headline)
                    .foregroundColor(.gray)

                // Boss indicator
                if encounter.isBoss {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("BOSS ENCOUNTER")
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                }

                // Enemy count
                Text("\(encounter.enemyTemplates.count) enemies")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }

            Spacer()

            // Start encounter button
            Button(action: startCurrentEncounter) {
                Text("Enter Combat")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Encounter Complete

    private var encounterCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Encounter Complete!")
                .font(.title)
                .foregroundColor(.white)

            if let quest = questManager.activeQuest {
                if quest.hasMoreEncounters {
                    Text("\(quest.encounters.count - quest.currentEncounterIndex - 1) encounters remaining")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // Party status
                    partyStatusPreview
                } else {
                    Text("Quest Complete!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            // Continue button
            Button(action: {
                if let quest = questManager.activeQuest, quest.hasMoreEncounters {
                    // Rest party between encounters
                    encounterManager.restPartyBetweenEncounters()
                    questManager.advanceQuestFlow()
                } else {
                    questManager.advanceQuestFlow()  // Go to victory
                }
            }) {
                Text(questManager.activeQuest?.hasMoreEncounters == true ? "Continue" : "Claim Rewards")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private var partyStatusPreview: some View {
        VStack(spacing: 8) {
            ForEach(encounterManager.partyMembers) { character in
                HStack {
                    Text(character.name)
                        .font(.caption)
                        .foregroundColor(character.isAlive ? .white : .red)

                    Spacer()

                    if character.isAlive {
                        HealthBar(
                            current: character.secondaryStats.hp,
                            max: character.secondaryStats.maxHP,
                            width: 80
                        )
                    } else {
                        Text("KO")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .padding(.horizontal, 40)
    }

    // MARK: - Victory/Defeat

    private var victoryView: some View {
        QuestResultView(
            quest: questManager.activeQuest!,
            isVictory: true,
            party: getPartyCharacters(),
            stats: combatManager.combatStats,
            currentScreen: $currentScreen
        )
    }

    private var defeatView: some View {
        QuestResultView(
            quest: questManager.activeQuest!,
            isVictory: false,
            party: getPartyCharacters(),
            stats: combatManager.combatStats,
            currentScreen: $currentScreen
        )
    }

    // MARK: - Actions

    private func startCurrentEncounter() {
        guard let encounter = questManager.currentEncounter else { return }

        let party = getPartyCharacters()
        encounterManager.startEncounter(encounter, party: party)
    }

    private func handleCombatResult() {
        switch combatManager.state {
        case .victory:
            questManager.completeCurrentEncounter(victory: true, stats: combatManager.combatStats)
        case .defeat:
            questManager.completeCurrentEncounter(victory: false, stats: combatManager.combatStats)
        default:
            break
        }
    }

    private func getPartyCharacters() -> [Character] {
        guard let quest = questManager.activeQuest else { return [] }
        return quest.assignedPartyIds.compactMap { guildManager.character(byId: $0) }
    }
}

#Preview {
    QuestFlowView(currentScreen: .constant(.questFlow))
}
