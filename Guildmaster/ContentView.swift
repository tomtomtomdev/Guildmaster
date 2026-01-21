//
//  ContentView.swift
//  Guildmaster
//
//  Main entry point view
//

import SwiftUI

struct ContentView: View {
    @State private var currentScreen: GameScreen = .mainMenu
    @StateObject private var guildManager = GuildManager.shared

    var body: some View {
        switch currentScreen {
        case .mainMenu:
            MainMenuView(
                currentScreen: $currentScreen,
                guildManager: guildManager
            )

        case .guildHall:
            GuildHallView(currentScreen: $currentScreen)

        case .questBoard:
            QuestBoardView(currentScreen: $currentScreen)

        case .partySelection:
            PartySelectionView(currentScreen: $currentScreen)

        case .questFlow:
            QuestFlowView(currentScreen: $currentScreen)

        case .questResult:
            if let quest = QuestManager.shared.activeQuest {
                QuestResultView(
                    quest: quest,
                    isVictory: QuestManager.shared.questFlowState == .victory,
                    party: getPartyCharacters(),
                    stats: CombatManager.shared.combatStats,
                    currentScreen: $currentScreen
                )
            } else {
                GuildHallView(currentScreen: $currentScreen)
            }

        case .barracks:
            BarracksView(currentScreen: $currentScreen)

        case .recruitment:
            RecruitmentView(currentScreen: $currentScreen)

        case .testCombat:
            TestCombatView(onExit: {
                currentScreen = .mainMenu
            })

        case .inventory:
            InventoryView(currentScreen: $currentScreen)
        }
    }

    private func getPartyCharacters() -> [Character] {
        guard let quest = QuestManager.shared.activeQuest else { return [] }
        return quest.assignedPartyIds.compactMap { guildManager.character(byId: $0) }
    }
}

/// All game screens
enum GameScreen {
    case mainMenu
    case guildHall
    case questBoard
    case partySelection
    case questFlow
    case questResult
    case barracks
    case recruitment
    case testCombat
    case inventory
}

/// Main menu view
struct MainMenuView: View {
    @Binding var currentScreen: GameScreen
    @ObservedObject var guildManager: GuildManager

    @State private var showingNewGameAlert = false
    @State private var guildNameInput = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.15, blue: 0.1),
                    Color(red: 0.3, green: 0.2, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("GUILD MASTER")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.4))

                    Text("Manage Your Adventurers")
                        .font(.system(size: 16, design: .serif))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Menu buttons
                VStack(spacing: 16) {
                    MenuButton(title: "New Game", icon: "plus.circle") {
                        showingNewGameAlert = true
                    }

                    MenuButton(title: "Continue", icon: "play.circle") {
                        // Load saved game and go to guild hall
                        currentScreen = .guildHall
                    }
                    .disabled(guildManager.roster.isEmpty)

                    MenuButton(title: "Test Combat", icon: "figure.fencing") {
                        currentScreen = .testCombat
                    }

                    MenuButton(title: "Settings", icon: "gearshape") {
                        // TODO: Settings
                    }
                    .disabled(true)
                }

                Spacer()

                // Version
                Text("Alpha v0.2 - Quest & Guild Update")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .alert("Create New Guild", isPresented: $showingNewGameAlert) {
            TextField("Guild Name", text: $guildNameInput)
            Button("Cancel", role: .cancel) {
                guildNameInput = ""
            }
            Button("Create") {
                let name = guildNameInput.isEmpty ? "The Iron Wolves" : guildNameInput
                guildManager.startNewGame(guildName: name)
                guildNameInput = ""
                currentScreen = .guildHall
            }
        } message: {
            Text("Enter a name for your adventurer's guild")
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 30)

                Text(title)
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isEnabled ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(isEnabled ? 0.3 : 0.1), lineWidth: 1)
            )
            .foregroundColor(isEnabled ? .white : .gray)
        }
    }
}

/// Test combat view for Sprint 1 testing
struct TestCombatView: View {
    let onExit: () -> Void
    @StateObject private var combatManager = CombatManager.shared

    @State private var combatStarted = false

    var body: some View {
        ZStack {
            if combatStarted {
                CombatView(combatManager: combatManager)
            } else {
                // Setup screen
                VStack(spacing: 30) {
                    Text("Test Combat")
                        .font(.largeTitle)
                        .foregroundColor(.white)

                    Text("This will start a test battle with generated characters.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        Text("Your Party:")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(testParty) { character in
                            CharacterRow(character: character)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    VStack(spacing: 12) {
                        Text("Enemies:")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(testEnemies) { enemy in
                            EnemyRow(enemy: enemy)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)

                    HStack(spacing: 20) {
                        Button("Back") {
                            onExit()
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Start Battle") {
                            startCombat()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
        }
        .background(Color(red: 0.15, green: 0.1, blue: 0.1).ignoresSafeArea())
    }

    // Test party generation
    private var testParty: [Character] {
        [
            Character(name: "Grimjaw", race: .orc, characterClass: .warrior),
            Character(name: "Elara", race: .elf, characterClass: .mage),
            Character(name: "Thornwick", race: .dwarf, characterClass: .cleric),
            Character(name: "Shadow", race: .human, characterClass: .rogue)
        ]
    }

    // Test enemies generation
    private var testEnemies: [Enemy] {
        [
            Enemy.create(type: .goblinScout),
            Enemy.create(type: .goblinScout),
            Enemy.create(type: .goblinShaman),
            Enemy.create(type: .bandit)
        ]
    }

    private func startCombat() {
        combatManager.startCombat(
            playerParty: testParty,
            enemies: testEnemies
        )
        combatStarted = true
    }
}

struct CharacterRow: View {
    let character: Character

    var body: some View {
        HStack {
            // Class icon
            Text(String(character.characterClass.rawValue.prefix(1)))
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.blue))
                .foregroundColor(.white)

            VStack(alignment: .leading) {
                Text(character.name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("INT: \(character.stats.int)")
                .font(.caption)
                .foregroundColor(intColor(character.stats.int))
        }
    }

    private func intColor(_ int: Int) -> Color {
        if int <= 8 { return .red }
        if int <= 14 { return .yellow }
        return .green
    }
}

struct EnemyRow: View {
    let enemy: Enemy

    var body: some View {
        HStack {
            // Enemy icon
            Text(String(enemy.name.prefix(1)))
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.red))
                .foregroundColor(.white)

            VStack(alignment: .leading) {
                Text(enemy.name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text("HP: \(enemy.maxHP) | AC: \(enemy.armorClass)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(enemy.tier.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(tierColor.opacity(0.3))
                .foregroundColor(tierColor)
                .cornerRadius(4)
        }
    }

    private var tierColor: Color {
        switch enemy.tier {
        case .minion: return .gray
        case .common: return .white
        case .elite: return .orange
        case .boss: return .red
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

#Preview {
    ContentView()
}
