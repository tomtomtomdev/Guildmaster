//
//  Character.swift
//  Guildmaster
//
//  Core character model representing adventurers
//

import Foundation
import Combine

/// Represents an adventurer in the guild
class Character: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var name: String
    let race: Race
    let characterClass: CharacterClass

    // Stats
    @Published var stats: StatBlock
    @Published var secondaryStats: SecondaryStats

    // Progression
    @Published var level: Int
    @Published var xp: Int

    // Personality & Satisfaction
    let personality: Personality
    @Published var satisfaction: Int      // 0-100
    @Published var stress: Int            // 0-100
    @Published var morale: Int            // 0-100

    // Combat state
    @Published var abilities: [AbilityType]
    @Published var statusEffects: [StatusEffect]
    @Published var abilityUsesRemaining: [AbilityType: Int]  // For per-quest abilities

    // Guild tracking
    @Published var questsCompleted: Int
    @Published var questsFailed: Int
    @Published var totalKills: Int
    @Published var daysSinceRest: Int
    @Published var hireCost: Int
    @Published var hireDate: Int  // Game day hired

    // Position in combat (nil when not in combat)
    @Published var combatPosition: HexCoordinate?

    // Traits
    let racialTrait: RacialTrait
    let classTrait: ClassTrait
    @Published var acquiredTraits: [String]  // IDs of earned traits

    // Equipment
    @Published var equipment: CharacterEquipment = CharacterEquipment()
    @Published var inventory: [Item] = []  // Combat consumables
    let maxInventorySize: Int = 6

    // Coding keys for Codable
    enum CodingKeys: String, CodingKey {
        case id, name, race, characterClass
        case stats, secondaryStats
        case level, xp
        case personality, satisfaction, stress, morale
        case abilities, statusEffects, abilityUsesRemaining
        case questsCompleted, questsFailed, totalKills, daysSinceRest
        case hireCost, hireDate
        case combatPosition
        case racialTrait, classTrait, acquiredTraits
        case equipment, inventory
    }

    init(
        name: String,
        race: Race,
        characterClass: CharacterClass,
        stats: StatBlock? = nil,
        personality: Personality? = nil,
        level: Int = 1
    ) {
        self.id = UUID()
        self.name = name
        self.race = race
        self.characterClass = characterClass

        // Generate or use provided stats
        let baseStats = stats ?? StatBlock.rollStats()
        let racialStats = baseStats.applying(race.statModifiers)

        // Apply class primary stat boost (+2)
        var finalStats = racialStats
        switch characterClass.primaryStat {
        case .str: finalStats.str += 2
        case .dex: finalStats.dex += 2
        case .con: finalStats.con += 2
        case .int: finalStats.int += 2
        case .wis: finalStats.wis += 2
        case .cha: finalStats.cha += 2
        }
        let computedStats = finalStats.clamped()
        self.stats = computedStats

        // Progression
        self.level = level
        self.xp = 0

        // Personality
        let computedPersonality = personality ?? Personality.random()
        self.personality = computedPersonality
        self.satisfaction = 50
        self.stress = 0
        self.morale = 50

        // Abilities
        self.abilities = characterClass.abilitiesForLevel(level)
        self.statusEffects = []
        self.abilityUsesRemaining = [:]

        // Tracking - must initialize all stored properties before using self
        self.questsCompleted = 0
        self.questsFailed = 0
        self.totalKills = 0
        self.daysSinceRest = 0
        self.hireDate = 0

        // Calculate hire cost based on stats and personality
        self.hireCost = Self.calculateHireCost(stats: computedStats, personality: computedPersonality)

        // Combat
        self.combatPosition = nil

        // Traits
        self.racialTrait = race.racialTrait
        self.classTrait = characterClass.classTrait
        self.acquiredTraits = []

        // Calculate secondary stats - now all stored properties initialized
        self.secondaryStats = SecondaryStats.calculate(
            from: computedStats,
            characterClass: characterClass,
            race: race,
            level: level
        )

        // Reset ability uses now that all properties are initialized
        resetAbilityUses()
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        race = try container.decode(Race.self, forKey: .race)
        characterClass = try container.decode(CharacterClass.self, forKey: .characterClass)
        stats = try container.decode(StatBlock.self, forKey: .stats)
        secondaryStats = try container.decode(SecondaryStats.self, forKey: .secondaryStats)
        level = try container.decode(Int.self, forKey: .level)
        xp = try container.decode(Int.self, forKey: .xp)
        personality = try container.decode(Personality.self, forKey: .personality)
        satisfaction = try container.decode(Int.self, forKey: .satisfaction)
        stress = try container.decode(Int.self, forKey: .stress)
        morale = try container.decode(Int.self, forKey: .morale)
        abilities = try container.decode([AbilityType].self, forKey: .abilities)
        statusEffects = try container.decode([StatusEffect].self, forKey: .statusEffects)
        abilityUsesRemaining = try container.decode([AbilityType: Int].self, forKey: .abilityUsesRemaining)
        questsCompleted = try container.decode(Int.self, forKey: .questsCompleted)
        questsFailed = try container.decode(Int.self, forKey: .questsFailed)
        totalKills = try container.decode(Int.self, forKey: .totalKills)
        daysSinceRest = try container.decode(Int.self, forKey: .daysSinceRest)
        hireCost = try container.decode(Int.self, forKey: .hireCost)
        hireDate = try container.decode(Int.self, forKey: .hireDate)
        combatPosition = try container.decodeIfPresent(HexCoordinate.self, forKey: .combatPosition)
        racialTrait = try container.decode(RacialTrait.self, forKey: .racialTrait)
        classTrait = try container.decode(ClassTrait.self, forKey: .classTrait)
        acquiredTraits = try container.decode([String].self, forKey: .acquiredTraits)
        equipment = try container.decodeIfPresent(CharacterEquipment.self, forKey: .equipment) ?? CharacterEquipment()
        inventory = try container.decodeIfPresent([Item].self, forKey: .inventory) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(race, forKey: .race)
        try container.encode(characterClass, forKey: .characterClass)
        try container.encode(stats, forKey: .stats)
        try container.encode(secondaryStats, forKey: .secondaryStats)
        try container.encode(level, forKey: .level)
        try container.encode(xp, forKey: .xp)
        try container.encode(personality, forKey: .personality)
        try container.encode(satisfaction, forKey: .satisfaction)
        try container.encode(stress, forKey: .stress)
        try container.encode(morale, forKey: .morale)
        try container.encode(abilities, forKey: .abilities)
        try container.encode(statusEffects, forKey: .statusEffects)
        try container.encode(abilityUsesRemaining, forKey: .abilityUsesRemaining)
        try container.encode(questsCompleted, forKey: .questsCompleted)
        try container.encode(questsFailed, forKey: .questsFailed)
        try container.encode(totalKills, forKey: .totalKills)
        try container.encode(daysSinceRest, forKey: .daysSinceRest)
        try container.encode(hireCost, forKey: .hireCost)
        try container.encode(hireDate, forKey: .hireDate)
        try container.encodeIfPresent(combatPosition, forKey: .combatPosition)
        try container.encode(racialTrait, forKey: .racialTrait)
        try container.encode(classTrait, forKey: .classTrait)
        try container.encode(acquiredTraits, forKey: .acquiredTraits)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(inventory, forKey: .inventory)
    }

    // MARK: - Hire Cost

    static func calculateHireCost(stats: StatBlock, personality: Personality) -> Int {
        // Base cost by stat total (60 = average for 6 stats of 10)
        let statTotal = stats.total
        var baseCost = (statTotal - 60) * 20 + 200

        // Personality modifiers
        if personality.greedy >= 7 {
            baseCost = Int(Double(baseCost) * 1.3)  // Greedy = costs more
        }
        if personality.loyal >= 7 {
            baseCost = Int(Double(baseCost) * 0.9)  // Loyal = accepts less
        }
        if personality.brave >= 8 {
            baseCost = Int(Double(baseCost) * 1.1)  // Brave = knows their worth
        }

        return max(100, baseCost)  // Minimum 100 gold
    }

    // MARK: - Combat Helpers

    /// Check if character is alive
    var isAlive: Bool {
        return secondaryStats.isAlive
    }

    /// Get stat modifier for a specific stat
    func modifier(for stat: StatType) -> Int {
        return stats.modifier(for: stat)
    }

    /// Get Intelligence tier for AI behavior
    var intelligenceTier: IntelligenceTier {
        if stats.int <= 8 {
            return .low
        } else if stats.int <= 14 {
            return .medium
        } else {
            return .high
        }
    }

    /// Captain rating (INT + CHA) / 2
    var captainRating: Int {
        return (stats.int + stats.cha) / 2
    }

    /// Reset per-quest ability uses
    func resetAbilityUses() {
        for ability in abilities {
            let data = ability.data
            if data.usesPerQuest > 0 {
                abilityUsesRemaining[ability] = data.usesPerQuest
            }
        }
    }

    /// Check if character can use an ability
    func canUse(ability: AbilityType) -> Bool {
        let data = ability.data

        // Check resource cost
        switch data.resourceType {
        case .none:
            break
        case .stamina:
            if secondaryStats.stamina < data.resourceCost { return false }
        case .mana:
            if secondaryStats.mana < data.resourceCost { return false }
        case .usesPerQuest:
            if (abilityUsesRemaining[ability] ?? 0) <= 0 { return false }
        }

        // Check if has ability
        if !abilities.contains(ability) && !isBasicAction(ability) { return false }

        return true
    }

    private func isBasicAction(_ ability: AbilityType) -> Bool {
        return ability == .basicAttack || ability == .defend || ability == .move
    }

    /// Pay the cost for using an ability
    func payCost(for ability: AbilityType) {
        let data = ability.data

        switch data.resourceType {
        case .none:
            break
        case .stamina:
            secondaryStats.stamina -= data.resourceCost
        case .mana:
            secondaryStats.mana -= data.resourceCost
        case .usesPerQuest:
            if let remaining = abilityUsesRemaining[ability] {
                abilityUsesRemaining[ability] = remaining - 1
            }
        }
    }

    /// Take damage
    func takeDamage(_ amount: Int) {
        secondaryStats.hp = max(0, secondaryStats.hp - amount)
    }

    /// Heal
    func heal(_ amount: Int) {
        secondaryStats.hp = min(secondaryStats.maxHP, secondaryStats.hp + amount)
    }

    /// Apply a status effect
    func applyStatus(_ effect: StatusEffect) {
        // Check for duplicate
        if let index = statusEffects.firstIndex(where: { $0.type == effect.type }) {
            // Refresh duration if longer
            if effect.remainingDuration > statusEffects[index].remainingDuration {
                statusEffects[index].remainingDuration = effect.remainingDuration
            }
        } else {
            statusEffects.append(effect)
        }
    }

    /// Remove a status effect
    func removeStatus(_ type: StatusEffectType) {
        statusEffects.removeAll { $0.type == type }
    }

    /// Check if has a status effect
    func hasStatus(_ type: StatusEffectType) -> Bool {
        return statusEffects.contains { $0.type == type }
    }

    /// Tick status effects at start of turn
    func tickStatusEffects() {
        statusEffects = statusEffects.compactMap { effect in
            var updated = effect
            updated.remainingDuration -= 1
            return updated.remainingDuration > 0 ? updated : nil
        }
    }

    // MARK: - Progression

    /// XP required for next level
    static func xpForLevel(_ level: Int) -> Int {
        switch level {
        case 1: return 0
        case 2: return 300
        case 3: return 900
        case 4: return 2100
        case 5: return 4500
        case 6: return 9300
        case 7: return 16500
        case 8: return 26500
        case 9: return 41500
        case 10: return 61500
        default: return 61500 + (level - 10) * 25000
        }
    }

    /// Add XP and check for level up
    func addXP(_ amount: Int) {
        xp += amount

        // Check for level up
        while xp >= Self.xpForLevel(level + 1) && level < 10 {
            levelUp()
        }
    }

    /// Level up the character
    private func levelUp() {
        level += 1

        // HP increase (roll hit die + CON modifier, minimum 1)
        let conMod = modifier(for: .con)
        let hpRoll = Int.random(in: 1...characterClass.hitDie)
        let hpGain = max(1, hpRoll + conMod)
        secondaryStats.maxHP += hpGain
        secondaryStats.hp = secondaryStats.maxHP  // Full heal on level up

        // Learn new abilities
        let newAbilities = characterClass.abilitiesForLevel(level)
        for ability in newAbilities where !abilities.contains(ability) {
            abilities.append(ability)
        }

        // Recalculate secondary stats
        secondaryStats = SecondaryStats.calculate(
            from: stats,
            characterClass: characterClass,
            race: race,
            level: level
        )
        secondaryStats.hp = secondaryStats.maxHP

        // Reset ability uses
        resetAbilityUses()
    }

    // MARK: - Satisfaction

    /// Update satisfaction after a quest
    func updateSatisfaction(questSuccess: Bool, partyDeaths: Int, daysRested: Bool) {
        var change = 0

        // Quest outcome
        if questSuccess {
            change += 10
        } else {
            change -= 15
            change -= partyDeaths * 10  // Worse if allies died
        }

        // Rest
        if daysRested {
            daysSinceRest = 0
        } else {
            daysSinceRest += 1
            if daysSinceRest > 7 {
                change -= 3 * (daysSinceRest - 7)
            }
        }

        // Injuries
        if secondaryStats.isCritical {
            change -= 5
        }

        // Apply change
        satisfaction = min(100, max(0, satisfaction + change))
    }

    /// Check if character might desert
    func checkDesertion() -> Bool {
        guard satisfaction < 30 else { return false }

        let loyaltyBonus = personality.loyal * 5
        let threshold = satisfaction + loyaltyBonus
        let roll = Int.random(in: 1...100)

        return roll > threshold
    }
}

/// Intelligence tier for AI behavior selection
enum IntelligenceTier: String, Codable {
    case low = "Low"        // INT 1-8: Makes obvious mistakes
    case medium = "Medium"  // INT 9-14: Basic tactics
    case high = "High"      // INT 15-20: Optimal decisions

    var description: String {
        switch self {
        case .low:
            return "Makes tactical errors, poor target selection"
        case .medium:
            return "Recognizes threats, uses abilities situationally"
        case .high:
            return "Optimizes decisions, coordinates with allies"
        }
    }
}

// MARK: - Character Generation

extension Character {
    /// Generate a random adventurer
    static func generateRandom(
        forClass preferredClass: CharacterClass? = nil,
        level: Int = 1
    ) -> Character {
        // Choose class
        let characterClass = preferredClass ?? CharacterClass.allCases.randomElement()!

        // Choose race weighted by class synergy
        let race = weightedRandomRace(for: characterClass)

        // Generate name
        let name = NameGenerator.generate(for: race)

        return Character(
            name: name,
            race: race,
            characterClass: characterClass,
            level: level
        )
    }

    /// Get race weighted by class synergy
    private static func weightedRandomRace(for characterClass: CharacterClass) -> Race {
        let weights: [Race: Double]

        switch characterClass {
        case .warrior:
            weights = [.human: 1.0, .elf: 0.5, .dwarf: 1.5, .orc: 1.5]
        case .rogue:
            weights = [.human: 1.0, .elf: 1.5, .dwarf: 0.5, .orc: 0.3]
        case .mage:
            weights = [.human: 1.0, .elf: 1.5, .dwarf: 0.3, .orc: 0.2]
        case .cleric:
            weights = [.human: 1.2, .elf: 0.8, .dwarf: 1.2, .orc: 0.5]
        }

        let totalWeight = weights.values.reduce(0, +)
        var roll = Double.random(in: 0..<totalWeight)

        for (race, weight) in weights {
            roll -= weight
            if roll <= 0 {
                return race
            }
        }

        return .human  // Fallback
    }
}

// MARK: - Equipment Methods

extension Character {

    /// Check if character can equip an item
    func canEquip(item: Item) -> Bool {
        // Check item type
        guard item.data.itemType == .weapon || item.data.itemType == .armor else {
            return false
        }

        // Check strength requirement for heavy armor
        if let armorType = item.data.armorType {
            if stats.str < armorType.strengthRequirement {
                return false
            }
        }

        // Check class weapon restrictions (optional - warriors can use all, etc.)
        // For now, allow all classes to use any weapon

        return true
    }

    /// Equip an item to a slot
    func equip(item: Item, to slot: EquipmentSlot) {
        switch slot {
        case .mainHand:
            equipment.mainHand = item
        case .offHand:
            equipment.offHand = item
        case .body:
            equipment.body = item
        case .none:
            break
        }

        // Recalculate stats with new equipment
        recalculateSecondaryStats()
    }

    /// Unequip from a slot
    func unequip(slot: EquipmentSlot) {
        switch slot {
        case .mainHand:
            equipment.mainHand = nil
        case .offHand:
            equipment.offHand = nil
        case .body:
            equipment.body = nil
        case .none:
            break
        }

        // Recalculate stats
        recalculateSecondaryStats()
    }

    /// Recalculate secondary stats (call after equipment changes)
    func recalculateSecondaryStats() {
        let currentHP = secondaryStats.hp
        let currentStamina = secondaryStats.stamina
        let currentMana = secondaryStats.mana

        secondaryStats = SecondaryStats.calculate(
            from: stats,
            characterClass: characterClass,
            race: race,
            level: level,
            equipment: equipment
        )

        // Preserve current resource values (don't heal on equip change)
        secondaryStats.hp = min(currentHP, secondaryStats.maxHP)
        secondaryStats.stamina = min(currentStamina, secondaryStats.maxStamina)
        secondaryStats.mana = min(currentMana, secondaryStats.maxMana)
    }

    /// Total armor class including equipment
    var totalArmorClass: Int {
        var ac = secondaryStats.armorClass

        // Add armor bonus
        if let armor = equipment.body {
            ac += armor.data.armorBonus
        }

        // Add shield bonus
        if let shield = equipment.offHand, shield.data.armorType == .shield {
            ac += shield.data.armorBonus
        }

        return ac
    }

    /// Weapon damage dice
    var weaponDamage: DiceRoll {
        if let weapon = equipment.mainHand, let damage = weapon.data.damage {
            return damage
        }
        // Unarmed damage
        return DiceRoll(count: 1, sides: 4, modifier: modifier(for: .str))
    }

    /// Weapon attack range
    var attackRange: Int {
        if let weapon = equipment.mainHand {
            return weapon.data.attackRange ?? 1
        }
        return 1
    }
}

// MARK: - Character Equipment

/// Equipment slots for a character
struct CharacterEquipment: Codable, Equatable {
    var mainHand: Item?
    var offHand: Item?
    var body: Item?

    init(mainHand: Item? = nil, offHand: Item? = nil, body: Item? = nil) {
        self.mainHand = mainHand
        self.offHand = offHand
        self.body = body
    }

    /// Get item in a specific slot
    func item(in slot: EquipmentSlot) -> Item? {
        switch slot {
        case .mainHand: return mainHand
        case .offHand: return offHand
        case .body: return body
        case .none: return nil
        }
    }

    /// Check if a slot is empty
    func isEmpty(_ slot: EquipmentSlot) -> Bool {
        return item(in: slot) == nil
    }

    /// Total armor bonus from equipment
    var totalArmorBonus: Int {
        var bonus = 0
        if let armor = body {
            bonus += armor.data.armorBonus
        }
        if let shield = offHand, shield.data.armorType == .shield {
            bonus += shield.data.armorBonus
        }
        return bonus
    }

    /// All equipped items
    var allItems: [Item] {
        return [mainHand, offHand, body].compactMap { $0 }
    }

    // Custom Equatable since Item is a class
    static func == (lhs: CharacterEquipment, rhs: CharacterEquipment) -> Bool {
        return lhs.mainHand?.id == rhs.mainHand?.id &&
               lhs.offHand?.id == rhs.offHand?.id &&
               lhs.body?.id == rhs.body?.id
    }
}
