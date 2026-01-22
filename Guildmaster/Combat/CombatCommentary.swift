//
//  CombatCommentary.swift
//  Guildmaster
//
//  Real-time combat commentary system with style variations
//

import Foundation
import Combine

/// Combat event types for commentary
enum CombatEventType {
    case attack(attacker: String, target: String, damage: Int, isCritical: Bool)
    case miss(attacker: String, target: String, isCriticalMiss: Bool)
    case abilityUsed(user: String, ability: AbilityType, target: String?)
    case healing(healer: String, target: String, amount: Int)
    case death(victim: String, killer: String?)
    case statusApplied(target: String, status: StatusEffectType, source: String?)
    case statusExpired(target: String, status: StatusEffectType)
    case movement(unit: String, description: String)
    case captainCommand(captain: String, command: CaptainCommand)
    case turnStart(unit: String)
    case combatStart
    case victory
    case defeat
    case lowINTMistake(unit: String, description: String)
    case flank(attacker: String, target: String)
    case firstBlood(attacker: String, victim: String)
    case killStreak(unit: String, streak: Int)
    case multiKill(unit: String, count: Int)
}

/// A single commentary message
struct CommentaryMessage: Identifiable {
    let id = UUID()
    let text: String
    let type: CommentaryMessageType
    let timestamp: Date
    let priority: CommentaryPriority

    init(text: String, type: CommentaryMessageType, priority: CommentaryPriority = .normal) {
        self.text = text
        self.type = type
        self.timestamp = Date()
        self.priority = priority
    }
}

/// Type of commentary message for styling
enum CommentaryMessageType {
    case normal
    case damage
    case critical
    case miss
    case healing
    case death
    case status
    case ability
    case captain
    case victory
    case defeat
    case lowINT
    case streak
}

/// Priority for message display
enum CommentaryPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: CommentaryPriority, rhs: CommentaryPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Combat commentary manager
class CombatCommentary: ObservableObject {

    // MARK: - Singleton

    static let shared = CombatCommentary()

    // MARK: - Published Properties

    @Published var messages: [CommentaryMessage] = []
    @Published var latestMessage: CommentaryMessage?

    // MARK: - Configuration

    let maxMessages = 50

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Clear all messages
    func clear() {
        messages.removeAll()
        latestMessage = nil
    }

    /// Add a combat event
    func addEvent(_ event: CombatEventType) {
        let message = generateMessage(for: event)
        addMessage(message)
    }

    /// Add a raw message
    func addMessage(_ message: CommentaryMessage) {
        messages.append(message)
        latestMessage = message

        // Trim old messages
        if messages.count > maxMessages {
            messages.removeFirst(messages.count - maxMessages)
        }
    }

    // MARK: - Message Generation

    private func generateMessage(for event: CombatEventType) -> CommentaryMessage {
        switch event {
        case .attack(let attacker, let target, let damage, let isCritical):
            return generateAttackMessage(attacker: attacker, target: target, damage: damage, isCritical: isCritical)

        case .miss(let attacker, let target, let isCriticalMiss):
            return generateMissMessage(attacker: attacker, target: target, isCriticalMiss: isCriticalMiss)

        case .abilityUsed(let user, let ability, let target):
            return generateAbilityMessage(user: user, ability: ability, target: target)

        case .healing(let healer, let target, let amount):
            return generateHealingMessage(healer: healer, target: target, amount: amount)

        case .death(let victim, let killer):
            return generateDeathMessage(victim: victim, killer: killer)

        case .statusApplied(let target, let status, let source):
            return generateStatusAppliedMessage(target: target, status: status, source: source)

        case .statusExpired(let target, let status):
            return generateStatusExpiredMessage(target: target, status: status)

        case .movement(let unit, let description):
            return CommentaryMessage(
                text: "\(unit) \(description)",
                type: .normal,
                priority: .low
            )

        case .captainCommand(let captain, let command):
            return generateCaptainMessage(captain: captain, command: command)

        case .turnStart(let unit):
            return CommentaryMessage(
                text: "\(unit)'s turn",
                type: .normal,
                priority: .low
            )

        case .combatStart:
            return CommentaryMessage(
                text: CombatStartTemplates.random,
                type: .normal,
                priority: .high
            )

        case .victory:
            return CommentaryMessage(
                text: VictoryTemplates.random,
                type: .victory,
                priority: .critical
            )

        case .defeat:
            return CommentaryMessage(
                text: DefeatTemplates.random,
                type: .defeat,
                priority: .critical
            )

        case .lowINTMistake(let unit, let description):
            return generateLowINTMessage(unit: unit, description: description)

        case .flank(let attacker, let target):
            return CommentaryMessage(
                text: FlankTemplates.random.replacing("{attacker}", with: attacker).replacing("{target}", with: target),
                type: .normal,
                priority: .normal
            )

        case .firstBlood(let attacker, let victim):
            return CommentaryMessage(
                text: "FIRST BLOOD! \(attacker) draws first blood against \(victim)!",
                type: .streak,
                priority: .high
            )

        case .killStreak(let unit, let streak):
            return generateStreakMessage(unit: unit, streak: streak)

        case .multiKill(let unit, let count):
            return generateMultiKillMessage(unit: unit, count: count)
        }
    }

    // MARK: - Attack Messages

    private func generateAttackMessage(attacker: String, target: String, damage: Int, isCritical: Bool) -> CommentaryMessage {
        if isCritical {
            let template = CriticalAttackTemplates.random
            let text = template
                .replacing("{attacker}", with: attacker)
                .replacing("{target}", with: target)
                .replacing("{damage}", with: "\(damage)")
            return CommentaryMessage(text: text, type: .critical, priority: .high)
        } else {
            let template = AttackTemplates.random
            let text = template
                .replacing("{attacker}", with: attacker)
                .replacing("{target}", with: target)
                .replacing("{damage}", with: "\(damage)")
            return CommentaryMessage(text: text, type: .damage, priority: .normal)
        }
    }

    // MARK: - Miss Messages

    private func generateMissMessage(attacker: String, target: String, isCriticalMiss: Bool) -> CommentaryMessage {
        if isCriticalMiss {
            let template = CriticalMissTemplates.random
            let text = template
                .replacing("{attacker}", with: attacker)
                .replacing("{target}", with: target)
            return CommentaryMessage(text: text, type: .miss, priority: .normal)
        } else {
            let template = MissTemplates.random
            let text = template
                .replacing("{attacker}", with: attacker)
                .replacing("{target}", with: target)
            return CommentaryMessage(text: text, type: .miss, priority: .low)
        }
    }

    // MARK: - Ability Messages

    private func generateAbilityMessage(user: String, ability: AbilityType, target: String?) -> CommentaryMessage {
        let targetText = target ?? "the area"
        let template = AbilityTemplates[ability] ?? "{user} uses {ability}!"
        let text = template
            .replacing("{user}", with: user)
            .replacing("{ability}", with: ability.rawValue)
            .replacing("{target}", with: targetText)
        return CommentaryMessage(text: text, type: .ability, priority: .normal)
    }

    // MARK: - Healing Messages

    private func generateHealingMessage(healer: String, target: String, amount: Int) -> CommentaryMessage {
        let template = HealingTemplates.random
        let text = template
            .replacing("{healer}", with: healer)
            .replacing("{target}", with: target)
            .replacing("{amount}", with: "\(amount)")
        return CommentaryMessage(text: text, type: .healing, priority: .normal)
    }

    // MARK: - Death Messages

    private func generateDeathMessage(victim: String, killer: String?) -> CommentaryMessage {
        if let killer = killer {
            let template = DeathTemplates.random
            let text = template
                .replacing("{victim}", with: victim)
                .replacing("{killer}", with: killer)
            return CommentaryMessage(text: text, type: .death, priority: .high)
        } else {
            return CommentaryMessage(
                text: "\(victim) has fallen!",
                type: .death,
                priority: .high
            )
        }
    }

    // MARK: - Status Messages

    private func generateStatusAppliedMessage(target: String, status: StatusEffectType, source: String?) -> CommentaryMessage {
        let statusText = StatusTemplates[status] ?? "is affected by \(status.rawValue)"
        let text = "\(target) \(statusText)!"
        return CommentaryMessage(text: text, type: .status, priority: .normal)
    }

    private func generateStatusExpiredMessage(target: String, status: StatusEffectType) -> CommentaryMessage {
        let text = "\(target) is no longer \(status.rawValue.lowercased())."
        return CommentaryMessage(text: text, type: .status, priority: .low)
    }

    // MARK: - Captain Messages

    private func generateCaptainMessage(captain: String, command: CaptainCommand) -> CommentaryMessage {
        let text = "\(captain) commands: \"\(command.description)\""
        return CommentaryMessage(text: text, type: .captain, priority: .high)
    }

    // MARK: - Low INT Messages

    private func generateLowINTMessage(unit: String, description: String) -> CommentaryMessage {
        let templates = [
            "\(unit) seems confused... \(description)",
            "\(unit) makes a questionable decision: \(description)",
            "What is \(unit) doing?! \(description)",
            "\(unit) doesn't quite get it... \(description)",
            "Hmm, \(unit) \(description)"
        ]
        let text = templates.randomElement() ?? "\(unit) \(description)"
        return CommentaryMessage(text: text, type: .lowINT, priority: .normal)
    }

    // MARK: - Streak Messages

    private func generateStreakMessage(unit: String, streak: Int) -> CommentaryMessage {
        let (title, _) = KillStreakTitles.title(for: streak)
        let text = "\(unit) is on a \(title)! (\(streak) kills)"
        return CommentaryMessage(text: text, type: .streak, priority: .high)
    }

    private func generateMultiKillMessage(unit: String, count: Int) -> CommentaryMessage {
        let title = MultiKillTitles.title(for: count)
        let text = "\(title)! \(unit) eliminates \(count) enemies!"
        return CommentaryMessage(text: text, type: .streak, priority: .high)
    }
}

// MARK: - Message Templates

private enum AttackTemplates {
    static let templates = [
        "{attacker} strikes {target} for {damage} damage!",
        "{attacker} hits {target}, dealing {damage} damage!",
        "{attacker} lands a blow on {target} for {damage}!",
        "{attacker}'s attack connects with {target} for {damage} damage!",
        "{target} takes {damage} damage from {attacker}'s attack!",
        "{attacker} wounds {target} for {damage}!",
        "{attacker} slashes {target} for {damage} damage!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum CriticalAttackTemplates {
    static let templates = [
        "CRITICAL HIT! {attacker} devastates {target} for {damage} damage!",
        "CRITICAL! {attacker}'s powerful blow deals {damage} to {target}!",
        "A devastating strike! {attacker} critically hits {target} for {damage}!",
        "CRITICAL HIT! {target} reels from {attacker}'s {damage} damage strike!",
        "{attacker} finds a weak spot! Critical hit for {damage} damage!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum MissTemplates {
    static let templates = [
        "{attacker} misses {target}!",
        "{attacker}'s attack goes wide!",
        "{target} dodges {attacker}'s attack!",
        "{attacker} swings and misses!",
        "{target} evades {attacker}'s strike!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum CriticalMissTemplates {
    static let templates = [
        "FUMBLE! {attacker} completely whiffs!",
        "{attacker} stumbles badly, missing entirely!",
        "A terrible miss! {attacker} nearly drops their weapon!",
        "{attacker}'s attack goes horribly wrong!",
        "What a blunder! {attacker} misses by a mile!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum HealingTemplates {
    static let templates = [
        "{healer} heals {target} for {amount} HP!",
        "{target} recovers {amount} HP from {healer}'s magic!",
        "Divine light restores {amount} HP to {target}!",
        "{healer}'s healing spell restores {target}'s health by {amount}!",
        "{target} is healed for {amount} by {healer}!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum DeathTemplates {
    static let templates = [
        "{victim} falls to {killer}!",
        "{killer} defeats {victim}!",
        "{victim} is slain by {killer}!",
        "{killer} strikes down {victim}!",
        "{victim} has been vanquished by {killer}!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum FlankTemplates {
    static let templates = [
        "{attacker} flanks {target}!",
        "{attacker} moves to flank {target}!",
        "{attacker} catches {target} from the side!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum CombatStartTemplates {
    static let templates = [
        "Combat begins!",
        "The battle is joined!",
        "Steel clashes!",
        "To arms!",
        "The fight begins!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum VictoryTemplates {
    static let templates = [
        "VICTORY!",
        "The battle is won!",
        "All enemies defeated!",
        "Triumph!",
        "The field is yours!"
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum DefeatTemplates {
    static let templates = [
        "DEFEAT...",
        "The party has fallen...",
        "All is lost...",
        "Darkness takes you...",
        "The battle is lost..."
    ]

    static var random: String {
        templates.randomElement() ?? templates[0]
    }
}

private enum AbilityTemplates {
    static let templates: [AbilityType: String] = [
        .powerAttack: "{user} channels power into a devastating strike!",
        .cleave: "{user} cleaves through enemies with brutal force!",
        .shieldBash: "{user} bashes {target} with their shield!",
        .secondWind: "{user} catches their breath and recovers!",
        .whirlwind: "{user} spins in a deadly whirlwind!",
        .sneakAttack: "{user} strikes from the shadows!",
        .hide: "{user} slips into the shadows...",
        .backstab: "{user} emerges from stealth to backstab {target}!",
        .poisonBlade: "{user} coats their blade with deadly poison!",
        .magicMissile: "{user} launches magic missiles at {target}!",
        .shield: "{user} conjures a magical shield!",
        .fireball: "{user} hurls a massive fireball!",
        .haste: "{user} accelerates {target} with arcane speed!",
        .counterspell: "{user} attempts to counter the enemy's magic!",
        .cureWounds: "{user} channels divine healing into {target}!",
        .bless: "{user} blesses the party with divine favor!",
        .turnUndead: "{user} channels holy power against the undead!",
        .divineSmite: "{user} smites {target} with divine wrath!",
        .massHealing: "{user} radiates healing light to all allies!",
        .defend: "{user} takes a defensive stance."
    ]

    static subscript(ability: AbilityType) -> String? {
        return templates[ability]
    }
}

private enum StatusTemplates {
    static let templates: [StatusEffectType: String] = [
        .stunned: "is stunned",
        .poisoned: "is poisoned",
        .hidden: "vanishes from sight",
        .poisonBlade: "coats their weapon with poison",
        .shielded: "is protected by a magical shield",
        .blessed: "is blessed",
        .hasted: "moves with supernatural speed",
        .turned: "flees in terror",
        .defending: "takes a defensive stance",
        .burning: "catches fire",
        .slowed: "is slowed",
        .frightened: "is frightened"
    ]

    static subscript(status: StatusEffectType) -> String? {
        return templates[status]
    }
}

// MARK: - Kill Streak Titles

enum KillStreakTitles {
    static func title(for streak: Int) -> (String, String) {
        switch streak {
        case 2:
            return ("DOUBLE KILL", "is on fire!")
        case 3:
            return ("TRIPLE KILL", "is unstoppable!")
        case 4:
            return ("QUAD KILL", "is dominating!")
        case 5:
            return ("RAMPAGE", "is on a rampage!")
        case 6:
            return ("KILLING SPREE", "can't be stopped!")
        case 7:
            return ("GODLIKE", "is godlike!")
        case 8...:
            return ("LEGENDARY", "is LEGENDARY!")
        default:
            return ("Kill", "scores a kill")
        }
    }
}

// MARK: - Multi-Kill Titles

enum MultiKillTitles {
    static func title(for count: Int) -> String {
        switch count {
        case 2:
            return "DOUBLE KILL"
        case 3:
            return "TRIPLE KILL"
        case 4:
            return "QUAD KILL"
        case 5...:
            return "PENTA KILL"
        default:
            return "KILL"
        }
    }
}
