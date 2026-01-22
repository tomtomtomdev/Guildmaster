//
//  StoryManager.swift
//  Guildmaster
//
//  Linear story campaign with 5 beats and 2 endings
//

import Foundation
import Combine

// MARK: - Story Manager

/// Manages the main story campaign
class StoryManager: ObservableObject {

    // MARK: - Singleton

    static let shared = StoryManager()

    // MARK: - Published Properties

    @Published var currentBeat: StoryBeat = .introduction
    @Published var progress: StoryProgress = StoryProgress()
    @Published var isStoryActive: Bool = false
    @Published var currentDialogue: StoryDialogue?
    @Published var pendingChoice: StoryChoice?

    // MARK: - Story State

    private var storyFlags: [String: Bool] = [:]
    private var storyVariables: [String: Int] = [:]

    // MARK: - Initialization

    private init() {
        setupInitialState()
    }

    private func setupInitialState() {
        progress = StoryProgress()
        storyFlags = [:]
        storyVariables = [:]
    }

    // MARK: - Public Methods

    /// Start the story campaign
    func startCampaign() {
        isStoryActive = true
        currentBeat = .introduction
        progress.currentBeatIndex = 0
        triggerBeat(.introduction)
    }

    /// Check if story quest is available
    func isStoryQuestAvailable(beat: StoryBeat) -> Bool {
        // Must have completed prerequisite quests
        guard beat.prerequisites.allSatisfy({ progress.completedQuests.contains($0) }) else {
            return false
        }

        // Must have reached the right beat
        return currentBeat.rawValue >= beat.rawValue
    }

    /// Complete a story beat
    func completeBeat(_ beat: StoryBeat, choice: String? = nil) {
        // Record the choice if any
        if let choice = choice {
            progress.choices[beat] = choice

            // Handle story-altering choices
            switch beat {
            case .climax:
                if choice == "alliance" {
                    storyFlags["allied_with_enemy"] = true
                } else {
                    storyFlags["defeated_enemy"] = false
                }
            default:
                break
            }
        }

        // Mark beat complete
        progress.completedBeats.insert(beat)
        progress.currentBeatIndex = beat.rawValue + 1

        // Advance to next beat
        if let next = beat.nextBeat {
            currentBeat = next
            triggerBeat(next)
        } else {
            // Story complete - determine ending
            completeStory()
        }
    }

    /// Get the current story quest
    func getCurrentStoryQuest() -> Quest? {
        return currentBeat.storyQuest
    }

    /// Record a choice for a story beat
    func recordChoice(_ choice: StoryChoice) {
        progress.choices[currentBeat] = choice.id
        pendingChoice = nil

        // Apply choice effects
        for effect in choice.effects {
            applyEffect(effect)
        }
    }

    private func applyEffect(_ effect: StoryEffect) {
        switch effect {
        case .setFlag(let flag, let value):
            storyFlags[flag] = value
        case .modifyVariable(let variable, let delta):
            storyVariables[variable, default: 0] += delta
        case .unlockQuest(let questId):
            progress.unlockedQuests.insert(questId)
        case .giveReward(let goldAmount, let items):
            GuildManager.shared.gold += goldAmount
            ItemManager.shared.addItems(templateIds: items)
        }
    }

    private func triggerBeat(_ beat: StoryBeat) {
        // Show initial dialogue
        currentDialogue = beat.openingDialogue
    }

    private func completeStory() {
        // Determine ending based on choices
        let ending = determineEnding()
        progress.ending = ending
        isStoryActive = false

        // Show ending dialogue
        currentDialogue = ending.dialogue
    }

    private func determineEnding() -> StoryEnding {
        // Check flags for ending determination
        if storyFlags["allied_with_enemy"] == true {
            return .alliance
        }
        return .victory
    }

    /// Check a story flag
    func checkFlag(_ flag: String) -> Bool {
        return storyFlags[flag] ?? false
    }

    /// Get a story variable value
    func getVariable(_ variable: String) -> Int {
        return storyVariables[variable] ?? 0
    }

    // MARK: - Save/Load

    func save() -> StorySaveData {
        return StorySaveData(
            currentBeat: currentBeat,
            progress: progress,
            storyFlags: storyFlags,
            storyVariables: storyVariables
        )
    }

    func load(from data: StorySaveData) {
        currentBeat = data.currentBeat
        progress = data.progress
        storyFlags = data.storyFlags
        storyVariables = data.storyVariables
        isStoryActive = !progress.completedBeats.contains(.resolution)
    }

    func reset() {
        setupInitialState()
        currentBeat = .introduction
        isStoryActive = false
        currentDialogue = nil
        pendingChoice = nil
    }
}

// MARK: - Story Beat

/// The 5 story beats
enum StoryBeat: Int, CaseIterable, Codable {
    case introduction = 0   // Guild gets first major contract
    case risingAction = 1   // Uncover the conspiracy
    case midpoint = 2       // Major revelation, ally or enemy revealed
    case climax = 3         // Final confrontation approaches
    case resolution = 4     // Aftermath and ending

    var name: String {
        switch self {
        case .introduction: return "A Dark Beginning"
        case .risingAction: return "Shadows Gather"
        case .midpoint: return "The Truth Revealed"
        case .climax: return "Final Stand"
        case .resolution: return "New Dawn"
        }
    }

    var description: String {
        switch self {
        case .introduction:
            return "Your guild receives its first major contract - investigate disappearances in the nearby village of Thornwood."
        case .risingAction:
            return "The trail leads to an abandoned mine where dark rituals are taking place."
        case .midpoint:
            return "You discover the cultists serve the Shadowmancer, an ancient evil thought long defeated."
        case .climax:
            return "The Shadowmancer's fortress awaits. Choose your path - alliance or destruction."
        case .resolution:
            return "With the threat ended, the realm must rebuild. Your guild's legend grows."
        }
    }

    var prerequisites: [String] {
        switch self {
        case .introduction: return []
        case .risingAction: return ["story_1_thornwood"]
        case .midpoint: return ["story_2_mine"]
        case .climax: return ["story_3_revelation"]
        case .resolution: return ["story_4_climax"]
        }
    }

    var nextBeat: StoryBeat? {
        switch self {
        case .introduction: return .risingAction
        case .risingAction: return .midpoint
        case .midpoint: return .climax
        case .climax: return .resolution
        case .resolution: return nil
        }
    }

    var openingDialogue: StoryDialogue {
        switch self {
        case .introduction:
            return StoryDialogue(
                speaker: "Guild Master",
                portrait: "guildmaster",
                text: "A messenger arrived at dawn. The village of Thornwood is plagued by disappearances. The mayor offers a substantial reward for anyone who can investigate.",
                responses: [
                    StoryResponse(text: "We'll take the contract.", next: nil),
                    StoryResponse(text: "Tell me more about these disappearances.", next: StoryDialogue(
                        speaker: "Guild Master",
                        portrait: "guildmaster",
                        text: "Six villagers have vanished in two weeks. No bodies, no traces. The last was the blacksmith's daughter, taken in broad daylight.",
                        responses: []
                    ))
                ]
            )

        case .risingAction:
            return StoryDialogue(
                speaker: "Survivor",
                portrait: "villager",
                text: "They came from the old Ironvein Mine! Cloaked figures, chanting in a tongue I've never heard. They spoke of... offerings.",
                responses: [
                    StoryResponse(text: "We'll investigate the mine.", next: nil)
                ]
            )

        case .midpoint:
            return StoryDialogue(
                speaker: "Captured Cultist",
                portrait: "cultist",
                text: "You're too late! The Shadowmancer awakens! Your pitiful guild cannot stop what has already begun!",
                responses: [
                    StoryResponse(text: "Who is this Shadowmancer?", next: StoryDialogue(
                        speaker: "Captured Cultist",
                        portrait: "cultist",
                        text: "An ancient mage who conquered death itself! He was banished long ago, but the ritual is nearly complete...",
                        responses: []
                    ))
                ]
            )

        case .climax:
            return StoryDialogue(
                speaker: "Shadowmancer",
                portrait: "shadowmancer",
                text: "You stand at the precipice of history. I offer you a choice - join me and share in ultimate power, or face annihilation.",
                responses: [
                    StoryResponse(text: "We will never serve darkness!", next: nil),
                    StoryResponse(text: "What would this... alliance entail?", next: StoryDialogue(
                        speaker: "Shadowmancer",
                        portrait: "shadowmancer",
                        text: "Your guild would be my enforcers. Wealth, power, immortality - all could be yours. The choice is simple.",
                        responses: []
                    ))
                ]
            )

        case .resolution:
            return StoryDialogue(
                speaker: "Guild Master",
                portrait: "guildmaster",
                text: "It is done. The realm owes your guild a debt that can never be repaid. Songs will be sung of this day.",
                responses: []
            )
        }
    }

    var storyQuest: Quest? {
        switch self {
        case .introduction:
            return Quest.storyQuest(
                id: "story_1_thornwood",
                title: "Darkness in Thornwood",
                description: "Investigate the mysterious disappearances in Thornwood village.",
                tier: .basic,
                enemies: [.goblinScout, .goblinScout, .wolf, .darkCultist]
            )
        case .risingAction:
            return Quest.storyQuest(
                id: "story_2_mine",
                title: "The Ironvein Mine",
                description: "Delve into the abandoned mine and uncover the source of the evil.",
                tier: .basic,
                enemies: [.darkCultist, .darkCultist, .skeleton, .skeleton, .orcWarrior]
            )
        case .midpoint:
            return Quest.storyQuest(
                id: "story_3_revelation",
                title: "The Shadowmancer's Secret",
                description: "Confront the cultist leadership and learn the truth.",
                tier: .advanced,
                enemies: [.darkCultist, .darkPriest, .skeleton, .skeleton]
            )
        case .climax:
            return Quest.storyQuest(
                id: "story_4_climax",
                title: "The Final Confrontation",
                description: "Storm the Shadowmancer's fortress and end the threat.",
                tier: .advanced,
                enemies: [.darkCultist, .darkCultist, .orcWarlord, .trollKing]
            )
        case .resolution:
            return nil  // Resolution is dialogue only
        }
    }
}

// MARK: - Story Dialogue

/// Dialogue for story scenes
struct StoryDialogue: Codable {
    let speaker: String
    let portrait: String
    let text: String
    let responses: [StoryResponse]
}

struct StoryResponse: Codable {
    let text: String
    let next: StoryDialogue?  // nil means end dialogue
    var skillCheck: SkillCheckRequirement?
}

struct SkillCheckRequirement: Codable {
    let skill: SkillType
    let dc: Int
    let successText: String
    let failureText: String
}

// MARK: - Story Choice

/// A significant story choice
struct StoryChoice: Identifiable, Codable {
    let id: String
    let text: String
    let description: String
    let effects: [StoryEffect]
}

/// Effects of a story choice
enum StoryEffect: Codable {
    case setFlag(String, Bool)
    case modifyVariable(String, Int)
    case unlockQuest(String)
    case giveReward(gold: Int, items: [String])
}

// MARK: - Story Progress

/// Tracks overall story progress
struct StoryProgress: Codable {
    var currentBeatIndex: Int = 0
    var completedBeats: Set<StoryBeat> = []
    var completedQuests: Set<String> = []
    var unlockedQuests: Set<String> = []
    var choices: [StoryBeat: String] = [:]
    var ending: StoryEnding?
}

// MARK: - Story Ending

/// The two possible endings
enum StoryEnding: String, Codable {
    case victory = "Victory"     // Defeated the Shadowmancer
    case alliance = "Alliance"   // Joined the Shadowmancer

    var name: String {
        switch self {
        case .victory: return "Dawn of Heroes"
        case .alliance: return "Servants of Shadow"
        }
    }

    var description: String {
        switch self {
        case .victory:
            return "The Shadowmancer is defeated and the realm is saved. Your guild becomes legendary heroes, forever remembered in song and story."
        case .alliance:
            return "You have joined forces with darkness. Your guild now serves the Shadowmancer, powerful but forever tainted by shadow."
        }
    }

    var dialogue: StoryDialogue {
        switch self {
        case .victory:
            return StoryDialogue(
                speaker: "Guild Master",
                portrait: "guildmaster",
                text: "The Shadowmancer is destroyed! The realm is free once more. Your names will be remembered for generations!",
                responses: []
            )
        case .alliance:
            return StoryDialogue(
                speaker: "Shadowmancer",
                portrait: "shadowmancer",
                text: "Wise choice. Together, we shall reshape this world. Your guild will be the enforcers of a new order.",
                responses: []
            )
        }
    }

    var rewards: (gold: Int, reputation: Int) {
        switch self {
        case .victory: return (1000, 50)
        case .alliance: return (2000, -30)  // More gold but reputation loss
        }
    }
}

// MARK: - Quest Extension for Story Quests

extension Quest {
    static func storyQuest(id: String, title: String, description: String, tier: DifficultyTier, enemies: [EnemyTemplate]) -> Quest {
        let encounters = [
            QuestEncounter(enemyTemplates: Array(enemies.prefix(2))),
            QuestEncounter(enemyTemplates: Array(enemies.dropFirst(2).prefix(2))),
            QuestEncounter(enemyTemplates: [enemies.last ?? .goblinScout], isBoss: true)
        ]

        let rewards = QuestRewards.standard(for: tier)

        return Quest(
            title: title,
            type: .extermination,
            tier: tier,
            description: description,
            flavorText: "A story quest.",
            recommendedLevel: tier == .basic ? 2 : 5,
            rewards: rewards,
            encounters: encounters
        )
    }
}

// MARK: - Save Data

struct StorySaveData: Codable {
    let currentBeat: StoryBeat
    let progress: StoryProgress
    let storyFlags: [String: Bool]
    let storyVariables: [String: Int]
}
