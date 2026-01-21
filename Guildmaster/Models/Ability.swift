//
//  Ability.swift
//  Guildmaster
//
//  Combat abilities for all classes
//

import Foundation

/// All ability types in the game
enum AbilityType: String, CaseIterable, Codable, Identifiable {
    // Warrior abilities
    case powerAttack = "Power Attack"
    case cleave = "Cleave"
    case shieldBash = "Shield Bash"
    case secondWind = "Second Wind"
    case whirlwind = "Whirlwind"

    // Rogue abilities
    case sneakAttack = "Sneak Attack"
    case hide = "Hide"
    case backstab = "Backstab"
    case evasion = "Evasion"
    case poisonBlade = "Poison Blade"

    // Mage abilities
    case magicMissile = "Magic Missile"
    case shield = "Shield"
    case fireball = "Fireball"
    case haste = "Haste"
    case counterspell = "Counterspell"

    // Cleric abilities
    case cureWounds = "Cure Wounds"
    case bless = "Bless"
    case turnUndead = "Turn Undead"
    case divineSmite = "Divine Smite"
    case massHealing = "Mass Healing"

    // Basic actions (always available)
    case basicAttack = "Attack"
    case defend = "Defend"
    case move = "Move"

    var id: String { rawValue }

    /// Get full ability data
    var data: AbilityData {
        return AbilityData.all[self] ?? AbilityData.defaultAbility
    }
}

/// Resource type used by abilities
enum ResourceType: String, Codable {
    case none
    case stamina
    case mana
    case usesPerQuest  // Limited uses that refresh between quests
}

/// Targeting type for abilities
enum TargetType: String, Codable {
    case selfOnly       // Only affects caster
    case singleEnemy    // One enemy target
    case singleAlly     // One ally target
    case allAdjacent    // All adjacent hexes
    case areaOfEffect   // Radius around point
    case line           // Line from caster
    case cone           // Cone from caster
}

/// Complete ability data
struct AbilityData: Codable {
    let type: AbilityType
    let description: String
    let resourceType: ResourceType
    let resourceCost: Int
    let targetType: TargetType
    let range: Int              // In hexes (0 = self/melee)
    let aoeRadius: Int          // For AOE abilities
    let damage: DiceRoll?       // Damage dice if applicable
    let healing: DiceRoll?      // Healing dice if applicable
    let attackModifier: Int     // Modifier to hit
    let damageModifier: Int     // Modifier to damage
    let statusEffect: StatusEffectType?  // Applied status
    let statusDuration: Int     // Turns the status lasts
    let isPassive: Bool         // Passive abilities don't use actions
    let usesPerQuest: Int       // For limited-use abilities (0 = unlimited)
    let levelRequired: Int      // Minimum level to learn

    static let defaultAbility = AbilityData(
        type: .basicAttack,
        description: "A basic weapon attack.",
        resourceType: .none,
        resourceCost: 0,
        targetType: .singleEnemy,
        range: 1,
        aoeRadius: 0,
        damage: DiceRoll(count: 1, sides: 6, modifier: 0),
        healing: nil,
        attackModifier: 0,
        damageModifier: 0,
        statusEffect: nil,
        statusDuration: 0,
        isPassive: false,
        usesPerQuest: 0,
        levelRequired: 1
    )

    /// All ability definitions
    static let all: [AbilityType: AbilityData] = [
        // WARRIOR ABILITIES
        .powerAttack: AbilityData(
            type: .powerAttack,
            description: "A powerful but inaccurate strike. -2 to hit, +5 damage.",
            resourceType: .stamina,
            resourceCost: 5,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 1, sides: 8, modifier: 5),
            healing: nil,
            attackModifier: -2,
            damageModifier: 5,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .cleave: AbilityData(
            type: .cleave,
            description: "If this attack kills, immediately attack an adjacent enemy.",
            resourceType: .stamina,
            resourceCost: 10,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 1, sides: 8, modifier: 0),
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 3
        ),
        .shieldBash: AbilityData(
            type: .shieldBash,
            description: "Bash with shield, dealing damage and stunning for 1 turn.",
            resourceType: .stamina,
            resourceCost: 5,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 1, sides: 6, modifier: 0),
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .stunned,
            statusDuration: 1,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 3
        ),
        .secondWind: AbilityData(
            type: .secondWind,
            description: "Catch your breath and recover 25% of max HP.",
            resourceType: .usesPerQuest,
            resourceCost: 1,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,  // Special: percentage based
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 1,
            levelRequired: 5
        ),
        .whirlwind: AbilityData(
            type: .whirlwind,
            description: "Attack all adjacent enemies in a spinning strike.",
            resourceType: .stamina,
            resourceCost: 15,
            targetType: .allAdjacent,
            range: 1,
            aoeRadius: 1,
            damage: DiceRoll(count: 1, sides: 8, modifier: 0),
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 7
        ),

        // ROGUE ABILITIES
        .sneakAttack: AbilityData(
            type: .sneakAttack,
            description: "Deal +2d6 damage when attacking from stealth or flanking. (Passive)",
            resourceType: .none,
            resourceCost: 0,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 2, sides: 6, modifier: 0),
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: true,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .hide: AbilityData(
            type: .hide,
            description: "Enter stealth if not in melee range of an enemy.",
            resourceType: .stamina,
            resourceCost: 5,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .hidden,
            statusDuration: 99,  // Until broken
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .backstab: AbilityData(
            type: .backstab,
            description: "Attack from stealth for triple damage.",
            resourceType: .stamina,
            resourceCost: 10,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 3, sides: 6, modifier: 0),  // Triple base damage
            healing: nil,
            attackModifier: 2,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 3
        ),
        .evasion: AbilityData(
            type: .evasion,
            description: "Take half damage from area effects. (Passive)",
            resourceType: .none,
            resourceCost: 0,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: true,
            usesPerQuest: 0,
            levelRequired: 5
        ),
        .poisonBlade: AbilityData(
            type: .poisonBlade,
            description: "Coat your weapon with poison. Next attack poisons for 1d4/turn for 3 turns.",
            resourceType: .stamina,
            resourceCost: 15,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .poisonBlade,
            statusDuration: 1,  // Lasts until next attack
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 5
        ),

        // MAGE ABILITIES
        .magicMissile: AbilityData(
            type: .magicMissile,
            description: "Fire 3 magical bolts that automatically hit for 1d4+1 each.",
            resourceType: .mana,
            resourceCost: 5,
            targetType: .singleEnemy,
            range: 12,
            aoeRadius: 0,
            damage: DiceRoll(count: 3, sides: 4, modifier: 3),  // 3d4+3 total
            healing: nil,
            attackModifier: 99,  // Auto-hit
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .shield: AbilityData(
            type: .shield,
            description: "Create a magical barrier granting +5 AC until your next turn.",
            resourceType: .mana,
            resourceCost: 5,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .shielded,
            statusDuration: 1,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .fireball: AbilityData(
            type: .fireball,
            description: "Hurl an explosive ball of fire. 6d6 fire damage in a 4-hex radius.",
            resourceType: .mana,
            resourceCost: 15,
            targetType: .areaOfEffect,
            range: 15,
            aoeRadius: 4,
            damage: DiceRoll(count: 6, sides: 6, modifier: 0),
            healing: nil,
            attackModifier: 0,  // DEX save for half
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 3
        ),
        .haste: AbilityData(
            type: .haste,
            description: "Grant an ally 2 actions per turn for 3 turns.",
            resourceType: .mana,
            resourceCost: 20,
            targetType: .singleAlly,
            range: 6,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .hasted,
            statusDuration: 3,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 5
        ),
        .counterspell: AbilityData(
            type: .counterspell,
            description: "Attempt to cancel an enemy's spell. INT check vs caster.",
            resourceType: .mana,
            resourceCost: 10,
            targetType: .singleEnemy,
            range: 12,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 5
        ),

        // CLERIC ABILITIES
        .cureWounds: AbilityData(
            type: .cureWounds,
            description: "Heal an ally for 1d8 + WIS modifier.",
            resourceType: .mana,
            resourceCost: 5,
            targetType: .singleAlly,
            range: 1,
            aoeRadius: 0,
            damage: nil,
            healing: DiceRoll(count: 1, sides: 8, modifier: 0),  // + WIS mod added at runtime
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .bless: AbilityData(
            type: .bless,
            description: "Grant all allies +1d4 to attack rolls and saves for 5 turns.",
            resourceType: .mana,
            resourceCost: 10,
            targetType: .areaOfEffect,
            range: 6,
            aoeRadius: 6,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .blessed,
            statusDuration: 5,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .turnUndead: AbilityData(
            type: .turnUndead,
            description: "Force undead enemies to flee. WIS check vs targets.",
            resourceType: .mana,
            resourceCost: 15,
            targetType: .areaOfEffect,
            range: 0,
            aoeRadius: 6,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .turned,
            statusDuration: 3,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 3
        ),
        .divineSmite: AbilityData(
            type: .divineSmite,
            description: "Channel divine power through your weapon for +2d8 radiant damage.",
            resourceType: .mana,
            resourceCost: 10,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 2, sides: 8, modifier: 0),  // Added to weapon damage
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 3
        ),
        .massHealing: AbilityData(
            type: .massHealing,
            description: "Heal all allies within range for 2d8 + WIS modifier.",
            resourceType: .mana,
            resourceCost: 25,
            targetType: .areaOfEffect,
            range: 0,
            aoeRadius: 6,
            damage: nil,
            healing: DiceRoll(count: 2, sides: 8, modifier: 0),
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 5
        ),

        // BASIC ACTIONS
        .basicAttack: AbilityData(
            type: .basicAttack,
            description: "A basic weapon attack.",
            resourceType: .none,
            resourceCost: 0,
            targetType: .singleEnemy,
            range: 1,
            aoeRadius: 0,
            damage: DiceRoll(count: 1, sides: 6, modifier: 0),
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .defend: AbilityData(
            type: .defend,
            description: "Take a defensive stance, gaining +2 AC until your next turn.",
            resourceType: .none,
            resourceCost: 0,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: .defending,
            statusDuration: 1,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        ),
        .move: AbilityData(
            type: .move,
            description: "Move to another hex within your movement range.",
            resourceType: .none,
            resourceCost: 0,
            targetType: .selfOnly,
            range: 0,
            aoeRadius: 0,
            damage: nil,
            healing: nil,
            attackModifier: 0,
            damageModifier: 0,
            statusEffect: nil,
            statusDuration: 0,
            isPassive: false,
            usesPerQuest: 0,
            levelRequired: 1
        )
    ]
}

/// Dice roll representation
struct DiceRoll: Codable {
    let count: Int      // Number of dice
    let sides: Int      // Sides per die (d4, d6, d8, d10, d12, d20)
    let modifier: Int   // Flat modifier added

    /// Roll the dice
    func roll() -> Int {
        var total = modifier
        for _ in 0..<count {
            total += Int.random(in: 1...sides)
        }
        return total
    }

    /// Expected average value
    var average: Double {
        return Double(count) * (Double(sides + 1) / 2.0) + Double(modifier)
    }

    /// String representation (e.g., "2d6+3")
    var description: String {
        if modifier == 0 {
            return "\(count)d\(sides)"
        } else if modifier > 0 {
            return "\(count)d\(sides)+\(modifier)"
        } else {
            return "\(count)d\(sides)\(modifier)"
        }
    }
}

/// Status effects that can be applied to characters
enum StatusEffectType: String, Codable {
    case stunned = "Stunned"           // Cannot act
    case poisoned = "Poisoned"         // Takes damage each turn
    case hidden = "Hidden"             // In stealth
    case poisonBlade = "Poison Blade"  // Next attack poisons
    case shielded = "Shielded"         // +5 AC
    case blessed = "Blessed"           // +1d4 to attacks/saves
    case hasted = "Hasted"             // 2 actions per turn
    case turned = "Turned"             // Fleeing (undead)
    case defending = "Defending"       // +2 AC
    case burning = "Burning"           // Fire DOT
    case slowed = "Slowed"             // Half movement
    case frightened = "Frightened"     // Disadvantage on attacks
}

/// Active status effect on a character
struct StatusEffect: Codable, Identifiable {
    let id: UUID
    let type: StatusEffectType
    var remainingDuration: Int
    let source: UUID?  // Character who applied it

    init(type: StatusEffectType, duration: Int, source: UUID? = nil) {
        self.id = UUID()
        self.type = type
        self.remainingDuration = duration
        self.source = source
    }
}
