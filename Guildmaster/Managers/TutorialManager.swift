//
//  TutorialManager.swift
//  Guildmaster
//
//  Manages tutorial progression and onboarding hints
//

import Foundation
import SwiftUI
import Combine

// MARK: - Tutorial Steps

/// Individual tutorial steps the player can complete
enum TutorialStep: String, CaseIterable, Codable {
    // First-time experience
    case welcomeMessage = "welcome"
    case createGuild = "create_guild"
    case exploreGuildHall = "explore_guild_hall"

    // Recruitment
    case viewRecruits = "view_recruits"
    case understandStats = "understand_stats"
    case hireFirstAdventurer = "hire_first"
    case viewBarracks = "view_barracks"

    // Quests
    case viewQuestBoard = "view_quest_board"
    case selectQuest = "select_quest"
    case formParty = "form_party"
    case startQuest = "start_quest"

    // Combat
    case combatBasics = "combat_basics"
    case movementPhase = "movement_phase"
    case attackPhase = "attack_phase"
    case abilityUsage = "ability_usage"
    case turnOrder = "turn_order"
    case combatVictory = "combat_victory"

    // Management
    case viewLedger = "view_ledger"
    case manageEquipment = "manage_equipment"
    case useTraining = "use_training"
    case understandSatisfaction = "understand_satisfaction"

    // Advanced
    case captainSystem = "captain_system"
    case intDifferences = "int_differences"
    case personalityEffects = "personality_effects"
    case relationshipSystem = "relationship_system"

    var title: String {
        switch self {
        case .welcomeMessage: return "Welcome to Guild Master"
        case .createGuild: return "Create Your Guild"
        case .exploreGuildHall: return "The Guild Hall"
        case .viewRecruits: return "Recruitment Office"
        case .understandStats: return "Character Stats"
        case .hireFirstAdventurer: return "Hire an Adventurer"
        case .viewBarracks: return "The Barracks"
        case .viewQuestBoard: return "Contract Board"
        case .selectQuest: return "Choose a Quest"
        case .formParty: return "Form Your Party"
        case .startQuest: return "Begin the Quest"
        case .combatBasics: return "Combat Basics"
        case .movementPhase: return "Movement"
        case .attackPhase: return "Attacking"
        case .abilityUsage: return "Using Abilities"
        case .turnOrder: return "Turn Order"
        case .combatVictory: return "Victory!"
        case .viewLedger: return "Guild Finances"
        case .manageEquipment: return "Equipment"
        case .useTraining: return "Training Grounds"
        case .understandSatisfaction: return "Adventurer Morale"
        case .captainSystem: return "The Captain"
        case .intDifferences: return "Intelligence Matters"
        case .personalityEffects: return "Personality"
        case .relationshipSystem: return "Relationships"
        }
    }

    var message: String {
        switch self {
        case .welcomeMessage:
            return "Welcome, Guild Master! You are now in charge of a fledgling adventurer's guild. Your goal is to recruit capable adventurers, send them on quests, and build your guild's reputation."

        case .createGuild:
            return "First, give your guild a name. This will be your identity in the realm. Choose wisely!"

        case .exploreGuildHall:
            return "This is your Guild Hall, the center of operations. From here you can access the Contract Board, Barracks, Recruitment, and more."

        case .viewRecruits:
            return "The Recruitment Office shows available adventurers for hire. Each has different stats, classes, and personalities."

        case .understandStats:
            return "Stats range from 1-20. Pay special attention to INT (Intelligence) - it affects how well adventurers make decisions in combat!"

        case .hireFirstAdventurer:
            return "Hire your first adventurer! Consider their class, stats, and hiring cost. A balanced party needs different roles."

        case .viewBarracks:
            return "The Barracks shows all hired adventurers. You can view their details, manage equipment, and check their satisfaction."

        case .viewQuestBoard:
            return "The Contract Board displays available quests. Each quest shows difficulty, rewards, and recommended party level."

        case .selectQuest:
            return "Choose a quest that matches your party's strength. Starting with easier quests helps your team gain experience."

        case .formParty:
            return "Select up to 4 adventurers for the quest. Consider class composition - you'll want damage dealers, support, and maybe a healer."

        case .startQuest:
            return "Your party is ready! Once you begin, they'll face combat encounters. The outcome depends on their skills and intelligence."

        case .combatBasics:
            return "Combat is turn-based on a hex grid. Each character gets a turn based on their initiative. Plan your moves carefully!"

        case .movementPhase:
            return "On each turn, you can move your character. Blue hexes show valid movement range. Position matters for flanking and avoiding attacks!"

        case .attackPhase:
            return "After moving, you can attack enemies in range. Melee attacks work on adjacent hexes, ranged attacks can reach further."

        case .abilityUsage:
            return "Each class has special abilities. Warriors can Power Attack, Mages cast spells, Clerics heal, and Rogues use Sneak Attack!"

        case .turnOrder:
            return "Turn order is determined by Initiative (DEX + roll). You can see the turn order at the top of the combat screen."

        case .combatVictory:
            return "Victory! Your party gains XP and gold. Check the results screen to see who performed well."

        case .viewLedger:
            return "The Guild Ledger tracks your finances, quest history, and statistics. Keep an eye on your gold reserves!"

        case .manageEquipment:
            return "Equip your adventurers with weapons and armor from the Armory. Better equipment improves combat effectiveness."

        case .useTraining:
            return "The Training Grounds let adventurers improve skills between quests. Training takes time but provides permanent benefits."

        case .understandSatisfaction:
            return "Adventurers have satisfaction levels. Keep them happy with successful quests and rest, or they might leave!"

        case .captainSystem:
            return "The party member with the highest INT becomes Captain. They can issue commands that others may follow!"

        case .intDifferences:
            return "Intelligence affects combat AI. High INT characters make tactical decisions. Low INT ones... make interesting choices."

        case .personalityEffects:
            return "Personality traits like Brave, Cautious, and Greedy affect how characters behave in combat and respond to situations."

        case .relationshipSystem:
            return "Adventurers form relationships over time. Allies work better together, while rivals may cause problems!"
        }
    }

    var icon: String {
        switch self {
        case .welcomeMessage, .createGuild: return "star.fill"
        case .exploreGuildHall: return "building.2.fill"
        case .viewRecruits, .hireFirstAdventurer: return "person.badge.plus"
        case .understandStats: return "chart.bar.fill"
        case .viewBarracks: return "person.3.fill"
        case .viewQuestBoard, .selectQuest: return "scroll.fill"
        case .formParty: return "person.3.sequence.fill"
        case .startQuest: return "figure.walk"
        case .combatBasics, .movementPhase, .attackPhase: return "shield.fill"
        case .abilityUsage: return "sparkles"
        case .turnOrder: return "arrow.triangle.2.circlepath"
        case .combatVictory: return "trophy.fill"
        case .viewLedger: return "book.fill"
        case .manageEquipment: return "archivebox.fill"
        case .useTraining: return "figure.martial.arts"
        case .understandSatisfaction: return "heart.fill"
        case .captainSystem: return "crown.fill"
        case .intDifferences: return "brain"
        case .personalityEffects: return "theatermasks.fill"
        case .relationshipSystem: return "heart.circle.fill"
        }
    }

    /// The order in which tutorials should be shown
    var order: Int {
        switch self {
        case .welcomeMessage: return 0
        case .createGuild: return 1
        case .exploreGuildHall: return 2
        case .viewRecruits: return 3
        case .understandStats: return 4
        case .hireFirstAdventurer: return 5
        case .viewBarracks: return 6
        case .viewQuestBoard: return 7
        case .selectQuest: return 8
        case .formParty: return 9
        case .startQuest: return 10
        case .combatBasics: return 11
        case .movementPhase: return 12
        case .attackPhase: return 13
        case .abilityUsage: return 14
        case .turnOrder: return 15
        case .combatVictory: return 16
        case .viewLedger: return 20
        case .manageEquipment: return 21
        case .useTraining: return 22
        case .understandSatisfaction: return 23
        case .captainSystem: return 30
        case .intDifferences: return 31
        case .personalityEffects: return 32
        case .relationshipSystem: return 33
        }
    }
}

// MARK: - Tutorial Hint

/// A hint that can be shown to the player
struct TutorialHint: Identifiable {
    let id = UUID()
    let step: TutorialStep
    let position: HintPosition
    let arrowDirection: ArrowDirection?

    enum HintPosition {
        case top
        case center
        case bottom
    }

    enum ArrowDirection {
        case up
        case down
        case left
        case right
    }
}

// MARK: - Tutorial Manager

/// Singleton manager for tutorial state and progression
class TutorialManager: ObservableObject {
    static let shared = TutorialManager()

    // MARK: - Published Properties

    @Published var completedSteps: Set<TutorialStep> = []
    @Published var currentHint: TutorialHint?
    @Published var isTutorialEnabled: Bool = true
    @Published var showTutorialOverlay: Bool = false

    // MARK: - Private Properties

    private let saveKey = "tutorial_completed_steps"
    private var hintQueue: [TutorialHint] = []

    // MARK: - Initialization

    private init() {
        loadProgress()
    }

    // MARK: - Progress Management

    /// Check if a tutorial step has been completed
    func isCompleted(_ step: TutorialStep) -> Bool {
        return completedSteps.contains(step)
    }

    /// Mark a tutorial step as completed
    func completeStep(_ step: TutorialStep) {
        guard !completedSteps.contains(step) else { return }

        completedSteps.insert(step)
        saveProgress()

        // Dismiss current hint if it matches
        if currentHint?.step == step {
            dismissCurrentHint()
        }
    }

    /// Reset all tutorial progress
    func resetProgress() {
        completedSteps.removeAll()
        saveProgress()
    }

    /// Skip all tutorials
    func skipAllTutorials() {
        completedSteps = Set(TutorialStep.allCases)
        saveProgress()
    }

    // MARK: - Hint Display

    /// Show a tutorial hint if the step hasn't been completed
    func showHintIfNeeded(_ step: TutorialStep, position: TutorialHint.HintPosition = .center, arrow: TutorialHint.ArrowDirection? = nil) {
        guard isTutorialEnabled && !isCompleted(step) else { return }

        let hint = TutorialHint(step: step, position: position, arrowDirection: arrow)

        if currentHint == nil {
            currentHint = hint
            showTutorialOverlay = true
        } else {
            // Queue the hint for later
            hintQueue.append(hint)
        }
    }

    /// Dismiss the current hint and show the next queued one
    func dismissCurrentHint() {
        if let current = currentHint {
            completeStep(current.step)
        }

        if hintQueue.isEmpty {
            currentHint = nil
            showTutorialOverlay = false
        } else {
            currentHint = hintQueue.removeFirst()
        }
    }

    /// Force dismiss all hints
    func dismissAllHints() {
        currentHint = nil
        hintQueue.removeAll()
        showTutorialOverlay = false
    }

    // MARK: - Contextual Triggers

    /// Trigger tutorials based on game screen
    func onScreenAppear(_ screen: GameScreen) {
        switch screen {
        case .mainMenu:
            break // No tutorial on main menu
        case .guildHall:
            if GuildManager.shared.roster.isEmpty {
                showHintIfNeeded(.exploreGuildHall, position: .bottom)
            }
        case .recruitment:
            showHintIfNeeded(.viewRecruits, position: .top)
            if !isCompleted(.understandStats) {
                showHintIfNeeded(.understandStats, position: .center)
            }
        case .barracks:
            showHintIfNeeded(.viewBarracks, position: .top)
        case .questBoard:
            showHintIfNeeded(.viewQuestBoard, position: .top)
        case .partySelection:
            showHintIfNeeded(.formParty, position: .center)
        case .questFlow, .testCombat:
            showHintIfNeeded(.combatBasics, position: .center)
        case .questResult:
            showHintIfNeeded(.combatVictory, position: .center)
        case .inventory:
            showHintIfNeeded(.manageEquipment, position: .top)
        case .ledger:
            showHintIfNeeded(.viewLedger, position: .top)
        case .training:
            showHintIfNeeded(.useTraining, position: .top)
        }
    }

    /// Trigger tutorials based on game events
    func onGameEvent(_ event: TutorialTriggerEvent) {
        switch event {
        case .firstAdventurerHired:
            completeStep(.hireFirstAdventurer)
            showHintIfNeeded(.viewQuestBoard, position: .center)

        case .firstQuestSelected:
            completeStep(.selectQuest)

        case .firstQuestStarted:
            completeStep(.startQuest)

        case .firstCombatStarted:
            showHintIfNeeded(.movementPhase, position: .bottom)

        case .firstMovement:
            completeStep(.movementPhase)
            showHintIfNeeded(.attackPhase, position: .bottom)

        case .firstAttack:
            completeStep(.attackPhase)

        case .firstAbilityUsed:
            completeStep(.abilityUsage)

        case .firstCombatWon:
            completeStep(.combatVictory)

        case .captainIssuedCommand:
            completeStep(.captainSystem)

        case .viewedCharacterDetails:
            if !isCompleted(.personalityEffects) {
                showHintIfNeeded(.personalityEffects, position: .center)
            }

        case .viewedRelationships:
            showHintIfNeeded(.relationshipSystem, position: .center)
        }
    }

    // MARK: - Persistence

    private func saveProgress() {
        let stepStrings = completedSteps.map { $0.rawValue }
        UserDefaults.standard.set(stepStrings, forKey: saveKey)
    }

    private func loadProgress() {
        guard let stepStrings = UserDefaults.standard.stringArray(forKey: saveKey) else {
            return
        }

        completedSteps = Set(stepStrings.compactMap { TutorialStep(rawValue: $0) })
        isTutorialEnabled = UserDefaults.standard.object(forKey: "tutorialEnabled") as? Bool ?? true
    }

    // MARK: - Progress Stats

    /// Get the percentage of tutorials completed
    var completionPercentage: Double {
        return Double(completedSteps.count) / Double(TutorialStep.allCases.count)
    }

    /// Get the next uncompleted tutorial step
    var nextStep: TutorialStep? {
        return TutorialStep.allCases
            .sorted { $0.order < $1.order }
            .first { !completedSteps.contains($0) }
    }
}

// MARK: - Tutorial Trigger Events

/// Events that can trigger tutorial hints
enum TutorialTriggerEvent {
    case firstAdventurerHired
    case firstQuestSelected
    case firstQuestStarted
    case firstCombatStarted
    case firstMovement
    case firstAttack
    case firstAbilityUsed
    case firstCombatWon
    case captainIssuedCommand
    case viewedCharacterDetails
    case viewedRelationships
}

// MARK: - Tutorial Overlay View

/// Overlay view for displaying tutorial hints
struct TutorialOverlayView: View {
    @ObservedObject var tutorialManager = TutorialManager.shared

    var body: some View {
        if let hint = tutorialManager.currentHint, tutorialManager.showTutorialOverlay {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        tutorialManager.dismissCurrentHint()
                    }

                // Hint card
                VStack(spacing: 16) {
                    if hint.position == .bottom {
                        Spacer()
                    }

                    VStack(spacing: 12) {
                        // Icon and title
                        HStack {
                            Image(systemName: hint.step.icon)
                                .font(.title2)
                                .foregroundColor(.yellow)

                            Text(hint.step.title)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()
                        }

                        // Message
                        Text(hint.step.message)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)

                        // Continue button
                        Button(action: {
                            tutorialManager.dismissCurrentHint()
                        }) {
                            Text("Got it!")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.yellow)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    )
                    .padding(.horizontal)

                    if hint.position == .top {
                        Spacer()
                    }
                }
                .padding(.vertical, 60)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: tutorialManager.showTutorialOverlay)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Add tutorial overlay to any view
    func withTutorialOverlay() -> some View {
        ZStack {
            self
            TutorialOverlayView()
        }
    }
}
