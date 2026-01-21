//
//  Quest.swift
//  Guildmaster
//
//  Quest data model for the quest system
//

import Foundation
import Combine

/// Types of quests available
enum QuestType: String, Codable, CaseIterable {
    case extermination = "Extermination"
    case rescue = "Rescue"
    case escort = "Escort"

    var description: String {
        switch self {
        case .extermination:
            return "Clear the location of all enemies"
        case .rescue:
            return "Save the captive and defeat the captors"
        case .escort:
            return "Protect the client through dangerous territory"
        }
    }

    var icon: String {
        switch self {
        case .extermination: return "flame.fill"
        case .rescue: return "person.fill.badge.plus"
        case .escort: return "figure.walk"
        }
    }
}

/// Difficulty tiers for quests
enum DifficultyTier: String, Codable, CaseIterable {
    case tutorial = "Tutorial"
    case basic = "Basic"
    case advanced = "Advanced"

    var color: String {
        switch self {
        case .tutorial: return "gray"
        case .basic: return "green"
        case .advanced: return "orange"
        }
    }

    var recommendedLevelRange: ClosedRange<Int> {
        switch self {
        case .tutorial: return 1...1
        case .basic: return 1...3
        case .advanced: return 4...7
        }
    }

    var baseGoldReward: Int {
        switch self {
        case .tutorial: return 100
        case .basic: return 250
        case .advanced: return 450
        }
    }

    var baseXPReward: Int {
        switch self {
        case .tutorial: return 50
        case .basic: return 150
        case .advanced: return 300
        }
    }
}

/// Status of a quest
enum QuestStatus: String, Codable {
    case available      // On the board, can be taken
    case inProgress     // Currently being attempted
    case completed      // Successfully finished
    case failed         // Party wiped or objective failed
    case expired        // Time ran out (not implemented yet)
}

/// Rewards for completing a quest
struct QuestRewards: Codable {
    var gold: Int
    var xp: Int
    var itemIds: [String]
    var reputationChanges: [String: Int]

    static func standard(for tier: DifficultyTier) -> QuestRewards {
        return QuestRewards(
            gold: tier.baseGoldReward,
            xp: tier.baseXPReward,
            itemIds: [],
            reputationChanges: [:]
        )
    }
}

/// An encounter within a quest
struct QuestEncounter: Identifiable, Codable {
    let id: UUID
    let enemyTemplates: [EnemyTemplate]
    let terrain: TerrainType
    let isBoss: Bool
    var isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id, enemyTemplates, terrain, isBoss, isCompleted
    }

    init(enemyTemplates: [EnemyTemplate], terrain: TerrainType = .ground, isBoss: Bool = false) {
        self.id = UUID()
        self.enemyTemplates = enemyTemplates
        self.terrain = terrain
        self.isBoss = isBoss
        self.isCompleted = false
    }

    /// Generate Enemy instances from the templates
    func generateEnemies() -> [Enemy] {
        return enemyTemplates.map { Enemy.create(type: $0) }
    }
}

/// Represents a quest that can be taken by the guild
class Quest: Identifiable, Codable, ObservableObject {
    let id: UUID
    let title: String
    let type: QuestType
    let tier: DifficultyTier
    let description: String
    let flavorText: String
    let recommendedLevel: Int

    @Published var status: QuestStatus
    @Published var rewards: QuestRewards
    @Published var encounters: [QuestEncounter]
    @Published var currentEncounterIndex: Int

    // Party assigned to this quest
    @Published var assignedPartyIds: [UUID]

    // Quest tracking
    @Published var turnsElapsed: Int
    @Published var totalDamageDealt: Int
    @Published var totalDamageTaken: Int
    @Published var enemiesKilled: Int

    enum CodingKeys: String, CodingKey {
        case id, title, type, tier, description, flavorText, recommendedLevel
        case status, rewards, encounters, currentEncounterIndex
        case assignedPartyIds
        case turnsElapsed, totalDamageDealt, totalDamageTaken, enemiesKilled
    }

    init(
        title: String,
        type: QuestType,
        tier: DifficultyTier,
        description: String,
        flavorText: String = "",
        recommendedLevel: Int,
        rewards: QuestRewards,
        encounters: [QuestEncounter]
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.tier = tier
        self.description = description
        self.flavorText = flavorText
        self.recommendedLevel = recommendedLevel
        self.status = .available
        self.rewards = rewards
        self.encounters = encounters
        self.currentEncounterIndex = 0
        self.assignedPartyIds = []
        self.turnsElapsed = 0
        self.totalDamageDealt = 0
        self.totalDamageTaken = 0
        self.enemiesKilled = 0
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        type = try container.decode(QuestType.self, forKey: .type)
        tier = try container.decode(DifficultyTier.self, forKey: .tier)
        description = try container.decode(String.self, forKey: .description)
        flavorText = try container.decode(String.self, forKey: .flavorText)
        recommendedLevel = try container.decode(Int.self, forKey: .recommendedLevel)
        status = try container.decode(QuestStatus.self, forKey: .status)
        rewards = try container.decode(QuestRewards.self, forKey: .rewards)
        encounters = try container.decode([QuestEncounter].self, forKey: .encounters)
        currentEncounterIndex = try container.decode(Int.self, forKey: .currentEncounterIndex)
        assignedPartyIds = try container.decode([UUID].self, forKey: .assignedPartyIds)
        turnsElapsed = try container.decode(Int.self, forKey: .turnsElapsed)
        totalDamageDealt = try container.decode(Int.self, forKey: .totalDamageDealt)
        totalDamageTaken = try container.decode(Int.self, forKey: .totalDamageTaken)
        enemiesKilled = try container.decode(Int.self, forKey: .enemiesKilled)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(tier, forKey: .tier)
        try container.encode(description, forKey: .description)
        try container.encode(flavorText, forKey: .flavorText)
        try container.encode(recommendedLevel, forKey: .recommendedLevel)
        try container.encode(status, forKey: .status)
        try container.encode(rewards, forKey: .rewards)
        try container.encode(encounters, forKey: .encounters)
        try container.encode(currentEncounterIndex, forKey: .currentEncounterIndex)
        try container.encode(assignedPartyIds, forKey: .assignedPartyIds)
        try container.encode(turnsElapsed, forKey: .turnsElapsed)
        try container.encode(totalDamageDealt, forKey: .totalDamageDealt)
        try container.encode(totalDamageTaken, forKey: .totalDamageTaken)
        try container.encode(enemiesKilled, forKey: .enemiesKilled)
    }

    // MARK: - Quest Flow

    var currentEncounter: QuestEncounter? {
        guard currentEncounterIndex < encounters.count else { return nil }
        return encounters[currentEncounterIndex]
    }

    var hasMoreEncounters: Bool {
        return currentEncounterIndex < encounters.count - 1
    }

    var isComplete: Bool {
        return encounters.allSatisfy { $0.isCompleted }
    }

    func advanceToNextEncounter() {
        if currentEncounterIndex < encounters.count {
            encounters[currentEncounterIndex].isCompleted = true
        }
        currentEncounterIndex += 1
    }

    func markCompleted() {
        status = .completed
    }

    func markFailed() {
        status = .failed
    }
}

// MARK: - Quest Templates

extension Quest {

    /// Tutorial quest - Clear the Basement
    static func clearTheBasement() -> Quest {
        return Quest(
            title: "Clear the Basement",
            type: .extermination,
            tier: .tutorial,
            description: "The tavern's basement has been overrun by rats. Clear them out before they spoil the ale!",
            flavorText: "\"Those blasted vermin are eating through my profits!\" - Barkeep Magnus",
            recommendedLevel: 1,
            rewards: QuestRewards(
                gold: 100,
                xp: 50,
                itemIds: ["minor_healing_potion"],
                reputationChanges: ["tavern": 5]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.giantRat, .giantRat], terrain: .ground),
                QuestEncounter(enemyTemplates: [.giantRat, .giantRat, .giantRat], terrain: .ground)
            ]
        )
    }

    /// Basic quest - Goblin Camp
    static func goblinCamp() -> Quest {
        return Quest(
            title: "Goblin Camp",
            type: .extermination,
            tier: .basic,
            description: "A goblin raiding party has set up camp near the trade road. Eliminate them before they attack more merchants.",
            flavorText: "\"Their scouts were spotted near the old mill. Strike fast!\"",
            recommendedLevel: 2,
            rewards: QuestRewards(
                gold: 250,
                xp: 150,
                itemIds: ["iron_sword"],
                reputationChanges: ["merchants": 10]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.goblinScout, .goblinScout], terrain: .forest),
                QuestEncounter(enemyTemplates: [.goblinScout, .goblinScout, .goblinScout], terrain: .forest),
                QuestEncounter(enemyTemplates: [.goblinScout, .goblinScout, .goblinShaman], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Basic quest - Bandit Hideout
    static func banditHideout() -> Quest {
        return Quest(
            title: "Bandit Hideout",
            type: .extermination,
            tier: .basic,
            description: "Local bandits have been waylaying travelers. Find their hideout and put an end to their crimes.",
            flavorText: "\"The reward is substantial. Dead or alive - preferably dead.\"",
            recommendedLevel: 2,
            rewards: QuestRewards(
                gold: 300,
                xp: 175,
                itemIds: ["leather_armor"],
                reputationChanges: ["guard": 15]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.bandit, .bandit], terrain: .ground),
                QuestEncounter(enemyTemplates: [.bandit, .bandit, .bandit], terrain: .ground),
                QuestEncounter(enemyTemplates: [.bandit, .bandit, .banditLord], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Basic quest - Missing Merchant (Rescue)
    static func missingMerchant() -> Quest {
        return Quest(
            title: "Missing Merchant",
            type: .rescue,
            tier: .basic,
            description: "A wealthy merchant was captured by bandits. Rescue him before they demand ransom - or worse.",
            flavorText: "\"My husband was taken three days ago. Please, bring him home!\"",
            recommendedLevel: 3,
            rewards: QuestRewards(
                gold: 350,
                xp: 200,
                itemIds: ["healing_potion", "healing_potion"],
                reputationChanges: ["merchants": 20]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.bandit, .bandit], terrain: .forest),
                QuestEncounter(enemyTemplates: [.bandit, .goblinScout, .goblinScout], terrain: .forest),
                QuestEncounter(enemyTemplates: [.bandit, .bandit, .bandit], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Basic quest - Caravan Guard (Escort)
    static func caravanGuard() -> Quest {
        return Quest(
            title: "Caravan Guard",
            type: .escort,
            tier: .basic,
            description: "Protect a merchant caravan traveling through wolf-infested wilderness.",
            flavorText: "\"The last caravan lost half their goods to those beasts. We need capable guards.\"",
            recommendedLevel: 2,
            rewards: QuestRewards(
                gold: 275,
                xp: 150,
                itemIds: ["rations", "rations", "rations"],
                reputationChanges: ["merchants": 15]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.wolf, .wolf], terrain: .forest),
                QuestEncounter(enemyTemplates: [.wolf, .wolf, .wolf], terrain: .forest),
                QuestEncounter(enemyTemplates: [.bandit, .bandit, .wolf], terrain: .ground)
            ]
        )
    }

    /// Basic quest - Crypt Cleanup
    static func cryptCleanup() -> Quest {
        return Quest(
            title: "Crypt Cleanup",
            type: .extermination,
            tier: .basic,
            description: "The dead have risen in the old cemetery. Put them back to rest permanently.",
            flavorText: "\"Dark magic stirs beneath the graves. The temple requests your aid.\"",
            recommendedLevel: 3,
            rewards: QuestRewards(
                gold: 300,
                xp: 175,
                itemIds: ["holy_water"],
                reputationChanges: ["temple": 20]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.skeleton, .skeleton], terrain: .ground),
                QuestEncounter(enemyTemplates: [.skeleton, .skeleton, .skeleton], terrain: .ground),
                QuestEncounter(enemyTemplates: [.skeleton, .skeleton, .darkCultist], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Advanced quest - Orc Warband
    static func orcWarband() -> Quest {
        return Quest(
            title: "Orc Warband",
            type: .extermination,
            tier: .advanced,
            description: "An orc warband threatens the frontier. Defeat their warlord to scatter the horde.",
            flavorText: "\"The orcs grow bold. Their warlord must fall, or the villages will burn.\"",
            recommendedLevel: 5,
            rewards: QuestRewards(
                gold: 500,
                xp: 350,
                itemIds: ["battle_axe", "chain_mail"],
                reputationChanges: ["frontier": 30]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.orcWarrior, .orcWarrior], terrain: .ground),
                QuestEncounter(enemyTemplates: [.orcWarrior, .orcWarrior, .goblinShaman], terrain: .ground),
                QuestEncounter(enemyTemplates: [.orcWarrior, .orcWarrior, .orcWarlord], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Advanced quest - Cultist Ritual
    static func cultistRitual() -> Quest {
        return Quest(
            title: "Cultist Ritual",
            type: .rescue,
            tier: .advanced,
            description: "Dark cultists plan to sacrifice an innocent. Stop the ritual and save the victim.",
            flavorText: "\"The ritual begins at midnight. You must act quickly!\"",
            recommendedLevel: 5,
            rewards: QuestRewards(
                gold: 450,
                xp: 325,
                itemIds: ["acolyte_vestments", "mana_potion"],
                reputationChanges: ["temple": 25]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.darkCultist, .skeleton], terrain: .ground),
                QuestEncounter(enemyTemplates: [.darkCultist, .darkCultist, .skeleton], terrain: .ground),
                QuestEncounter(enemyTemplates: [.darkCultist, .darkCultist, .darkPriest], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Advanced quest - Troll Cave
    static func trollCave() -> Quest {
        return Quest(
            title: "Troll Cave",
            type: .extermination,
            tier: .advanced,
            description: "A troll has claimed a cave near the mountain pass. Bring fire - they regenerate.",
            flavorText: "\"The beast heals faster than we can wound it. You'll need fire or acid.\"",
            recommendedLevel: 6,
            rewards: QuestRewards(
                gold: 550,
                xp: 400,
                itemIds: ["alchemist_fire", "alchemist_fire", "steel_sword"],
                reputationChanges: ["frontier": 25]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.wolf, .wolf, .wolf], terrain: .ground),
                QuestEncounter(enemyTemplates: [.troll], terrain: .ground),
                QuestEncounter(enemyTemplates: [.trollKing], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Advanced quest - Merchant Prince (Escort)
    static func merchantPrince() -> Quest {
        return Quest(
            title: "The Merchant Prince",
            type: .escort,
            tier: .advanced,
            description: "Escort a wealthy merchant prince through dangerous territory to the capital.",
            flavorText: "\"My cargo is worth a fortune. I expect it - and myself - to arrive intact.\"",
            recommendedLevel: 5,
            rewards: QuestRewards(
                gold: 600,
                xp: 350,
                itemIds: ["healing_potion", "healing_potion", "gold_ring"],
                reputationChanges: ["merchants": 30, "nobility": 15]
            ),
            encounters: [
                QuestEncounter(enemyTemplates: [.bandit, .bandit, .bandit], terrain: .forest),
                QuestEncounter(enemyTemplates: [.orcWarrior, .goblinScout, .goblinScout], terrain: .ground),
                QuestEncounter(enemyTemplates: [.bandit, .bandit, .banditLord], terrain: .ground, isBoss: true)
            ]
        )
    }

    /// Get all available quest templates
    static var allTemplates: [Quest] {
        return [
            clearTheBasement(),
            goblinCamp(),
            banditHideout(),
            missingMerchant(),
            caravanGuard(),
            cryptCleanup(),
            orcWarband(),
            cultistRitual(),
            trollCave(),
            merchantPrince()
        ]
    }
}
