//
//  Item.swift
//  Guildmaster
//
//  Item model for equipment and consumables
//

import Foundation
import Combine

// MARK: - Item Type Enums

/// Category of item
enum ItemType: String, Codable, CaseIterable {
    case weapon = "Weapon"
    case armor = "Armor"
    case consumable = "Consumable"

    var icon: String {
        switch self {
        case .weapon: return "sword.fill"
        case .armor: return "shield.fill"
        case .consumable: return "flask.fill"
        }
    }
}

/// Equipment slot for equippable items
enum EquipmentSlot: String, Codable, CaseIterable {
    case mainHand = "Main Hand"
    case offHand = "Off Hand"
    case body = "Body"
    case none = "None"  // For consumables
}

/// Type of weapon
enum WeaponType: String, Codable, CaseIterable {
    case sword = "Sword"
    case axe = "Axe"
    case bow = "Bow"
    case staff = "Staff"
    case dagger = "Dagger"

    var preferredStat: StatType {
        switch self {
        case .sword, .axe: return .str
        case .bow, .dagger: return .dex
        case .staff: return .int
        }
    }

    var isRanged: Bool {
        return self == .bow
    }

    var isTwoHanded: Bool {
        switch self {
        case .bow, .staff: return true
        case .axe: return false  // Hand axe is one-handed, battle axe logic handled per-item
        default: return false
        }
    }
}

/// Type of armor
enum ArmorType: String, Codable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"
    case shield = "Shield"
    case robe = "Robe"

    var dexCapModifier: Int? {
        switch self {
        case .light: return nil  // No cap
        case .medium: return 2   // Max +2 DEX to AC
        case .heavy: return 0    // No DEX bonus
        case .shield: return nil
        case .robe: return nil
        }
    }

    var strengthRequirement: Int {
        switch self {
        case .heavy: return 13
        case .medium: return 11
        default: return 0
        }
    }
}

// MARK: - Consumable Effect

/// Effect applied when using a consumable
struct ConsumableEffect: Codable, Equatable {
    let effectType: ConsumableEffectType
    let value: Int
    let duration: Int  // 0 for instant effects

    enum ConsumableEffectType: String, Codable {
        case healing = "Healing"
        case manaRestore = "Mana Restore"
        case staminaRestore = "Stamina Restore"
        case curePoison = "Cure Poison"
        case damage = "Damage"          // Thrown weapons/bombs
        case buff = "Buff"              // Temporary stat boost
        case light = "Light"            // Illumination
        case sustenance = "Sustenance"  // Prevents hunger (future)
        case stealth = "Stealth"        // Invisibility
        case speed = "Speed"            // Movement boost
        case utility = "Utility"        // General utility items
        case holyDamage = "Holy Damage" // Damage to undead
    }

    static let minorHealing = ConsumableEffect(effectType: .healing, value: 10, duration: 0)
    static let healing = ConsumableEffect(effectType: .healing, value: 25, duration: 0)
    static let manaRestore = ConsumableEffect(effectType: .manaRestore, value: 15, duration: 0)
    static let staminaRestore = ConsumableEffect(effectType: .staminaRestore, value: 15, duration: 0)
    static let curePoison = ConsumableEffect(effectType: .curePoison, value: 0, duration: 0)
    static let throwingDamage = ConsumableEffect(effectType: .damage, value: 8, duration: 0)
    static let fireDamage = ConsumableEffect(effectType: .damage, value: 15, duration: 0)
    static let minorHealing5 = ConsumableEffect(effectType: .healing, value: 5, duration: 0)
    static let light = ConsumableEffect(effectType: .light, value: 3, duration: 10)
    static let sustenance = ConsumableEffect(effectType: .sustenance, value: 1, duration: 0)
    static let greaterHealing = ConsumableEffect(effectType: .healing, value: 50, duration: 0)
    static let strengthBuff = ConsumableEffect(effectType: .buff, value: 4, duration: 5)
    static let speedBuff = ConsumableEffect(effectType: .speed, value: 3, duration: 5)
    static let invisibility = ConsumableEffect(effectType: .stealth, value: 1, duration: 3)
    static let smoke = ConsumableEffect(effectType: .stealth, value: 0, duration: 2)
    static let oilDamage = ConsumableEffect(effectType: .damage, value: 10, duration: 0)
    static let holyDamage = ConsumableEffect(effectType: .holyDamage, value: 20, duration: 0)
    static let utility = ConsumableEffect(effectType: .utility, value: 1, duration: 0)
    static let poisonResist = ConsumableEffect(effectType: .buff, value: 10, duration: 10)
}

// MARK: - Item Data

/// Core item statistics and properties
struct ItemData: Codable, Equatable {
    let itemType: ItemType
    let slot: EquipmentSlot

    // Weapon properties
    let weaponType: WeaponType?
    let damage: DiceRoll?
    let attackRange: Int?
    let isTwoHanded: Bool

    // Armor properties
    let armorType: ArmorType?
    let armorBonus: Int

    // Consumable properties
    let effect: ConsumableEffect?
    let stackable: Bool
    let maxStack: Int

    // General
    let value: Int  // Gold value
    let weight: Int
    let description: String

    // Full initializer
    init(
        itemType: ItemType,
        slot: EquipmentSlot,
        weaponType: WeaponType?,
        damage: DiceRoll?,
        attackRange: Int?,
        isTwoHanded: Bool,
        armorType: ArmorType?,
        armorBonus: Int,
        effect: ConsumableEffect?,
        stackable: Bool,
        maxStack: Int,
        value: Int,
        weight: Int,
        description: String
    ) {
        self.itemType = itemType
        self.slot = slot
        self.weaponType = weaponType
        self.damage = damage
        self.attackRange = attackRange
        self.isTwoHanded = isTwoHanded
        self.armorType = armorType
        self.armorBonus = armorBonus
        self.effect = effect
        self.stackable = stackable
        self.maxStack = maxStack
        self.value = value
        self.weight = weight
        self.description = description
    }

    // Factory methods for creating item data
    static func weapon(
        type: WeaponType,
        damage: DiceRoll,
        range: Int = 1,
        twoHanded: Bool = false,
        value: Int,
        weight: Int,
        description: String
    ) -> ItemData {
        return ItemData(
            itemType: ItemType.weapon,
            slot: EquipmentSlot.mainHand,
            weaponType: type,
            damage: damage,
            attackRange: range,
            isTwoHanded: twoHanded,
            armorType: Optional<ArmorType>.none,
            armorBonus: 0,
            effect: Optional<ConsumableEffect>.none,
            stackable: false,
            maxStack: 1,
            value: value,
            weight: weight,
            description: description
        )
    }

    static func armor(
        type: ArmorType,
        bonus: Int,
        slot: EquipmentSlot = .body,
        value: Int,
        weight: Int,
        description: String
    ) -> ItemData {
        return ItemData(
            itemType: ItemType.armor,
            slot: slot,
            weaponType: Optional<WeaponType>.none,
            damage: Optional<DiceRoll>.none,
            attackRange: Optional<Int>.none,
            isTwoHanded: false,
            armorType: type,
            armorBonus: bonus,
            effect: Optional<ConsumableEffect>.none,
            stackable: false,
            maxStack: 1,
            value: value,
            weight: weight,
            description: description
        )
    }

    static func consumable(
        effect: ConsumableEffect,
        stackable: Bool = true,
        maxStack: Int = 10,
        value: Int,
        weight: Int,
        description: String
    ) -> ItemData {
        return ItemData(
            itemType: ItemType.consumable,
            slot: EquipmentSlot.none,
            weaponType: Optional<WeaponType>.none,
            damage: Optional<DiceRoll>.none,
            attackRange: Optional<Int>.none,
            isTwoHanded: false,
            armorType: Optional<ArmorType>.none,
            armorBonus: 0,
            effect: effect,
            stackable: stackable,
            maxStack: maxStack,
            value: value,
            weight: weight,
            description: description
        )
    }
}

// MARK: - Item Class

/// Represents an item instance in the game
class Item: Identifiable, Codable, ObservableObject {
    let id: UUID
    let templateId: String
    let name: String
    let data: ItemData

    @Published var quantity: Int

    enum CodingKeys: String, CodingKey {
        case id, templateId, name, data, quantity
    }

    init(templateId: String, name: String, data: ItemData, quantity: Int = 1) {
        self.id = UUID()
        self.templateId = templateId
        self.name = name
        self.data = data
        self.quantity = quantity
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        templateId = try container.decode(String.self, forKey: .templateId)
        name = try container.decode(String.self, forKey: .name)
        data = try container.decode(ItemData.self, forKey: .data)
        quantity = try container.decode(Int.self, forKey: .quantity)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(templateId, forKey: .templateId)
        try container.encode(name, forKey: .name)
        try container.encode(data, forKey: .data)
        try container.encode(quantity, forKey: .quantity)
    }

    /// Create a copy of this item
    func copy() -> Item {
        return Item(templateId: templateId, name: name, data: data, quantity: quantity)
    }

    /// Check if this item can stack with another
    func canStackWith(_ other: Item) -> Bool {
        return data.stackable && templateId == other.templateId
    }

    /// Display string for damage
    var damageString: String? {
        guard let damage = data.damage else { return nil }
        return damage.description
    }

    /// Item type icon
    var icon: String {
        if let weaponType = data.weaponType {
            switch weaponType {
            case .sword: return "sword"
            case .axe: return "axe"
            case .bow: return "bow.and.arrow"
            case .staff: return "wand.and.stars"
            case .dagger: return "scissors"
            }
        }
        if let armorType = data.armorType {
            switch armorType {
            case .shield: return "shield.lefthalf.filled"
            case .robe: return "tshirt.fill"
            default: return "shield.fill"
            }
        }
        if data.itemType == .consumable {
            if let effect = data.effect {
                switch effect.effectType {
                case .healing: return "cross.fill"
                case .manaRestore: return "drop.fill"
                case .staminaRestore: return "bolt.fill"
                case .curePoison: return "leaf.fill"
                case .damage: return "flame.fill"
                case .buff: return "arrow.up.circle.fill"
                case .light: return "flashlight.on.fill"
                case .sustenance: return "fork.knife"
                case .stealth: return "eye.slash.fill"
                case .speed: return "hare.fill"
                case .utility: return "wrench.fill"
                case .holyDamage: return "sun.max.fill"
                }
            }
        }
        return "questionmark.circle"
    }
}

// MARK: - Item Templates

/// Predefined item templates - factory pattern
enum ItemTemplate: String, CaseIterable, Codable {
    // Weapons (15)
    case rusty_sword
    case iron_sword
    case steel_sword
    case hand_axe
    case battle_axe
    case short_bow
    case long_bow
    case wooden_staff
    case oak_staff
    case dagger
    case mace
    case war_hammer
    case spear
    case crossbow
    case great_sword

    // Armor (15)
    case leather_armor
    case studded_leather
    case hide_armor
    case chain_shirt
    case chain_mail
    case scale_mail
    case robes
    case acolyte_vestments
    case shield
    case tower_shield
    case plate_mail
    case half_plate
    case brigandine
    case buckler
    case enchanted_robes

    // Consumables (20)
    case minor_healing_potion
    case healing_potion
    case stamina_potion
    case mana_potion
    case antidote
    case throwing_knife
    case alchemist_fire
    case bandage
    case torch
    case rations
    case greater_healing_potion
    case strength_potion
    case speed_potion
    case invisibility_potion
    case smoke_bomb
    case oil_flask
    case holy_water
    case lockpick
    case rope
    case antitoxin

    /// Create an Item instance from this template
    func createItem(quantity: Int = 1) -> Item {
        let (name, data) = itemDetails
        return Item(templateId: self.rawValue, name: name, data: data, quantity: quantity)
    }

    /// Display name for this template
    var displayName: String {
        return itemDetails.0
    }

    private var itemDetails: (String, ItemData) {
        switch self {
        // WEAPONS
        case .rusty_sword:
            return ("Rusty Sword", ItemData.weapon(
                type: .sword,
                damage: DiceRoll(count: 1, sides: 6, modifier: 0),
                value: 15,
                weight: 3,
                description: "A worn blade, pitted with rust. Still serviceable for a novice."
            ))

        case .iron_sword:
            return ("Iron Sword", ItemData.weapon(
                type: .sword,
                damage: DiceRoll(count: 1, sides: 8, modifier: 0),
                value: 50,
                weight: 3,
                description: "A standard iron longsword. Reliable and well-balanced."
            ))

        case .steel_sword:
            return ("Steel Sword", ItemData.weapon(
                type: .sword,
                damage: DiceRoll(count: 1, sides: 8, modifier: 2),
                value: 150,
                weight: 3,
                description: "Fine steel blade with excellent edge retention."
            ))

        case .hand_axe:
            return ("Hand Axe", ItemData.weapon(
                type: .axe,
                damage: DiceRoll(count: 1, sides: 6, modifier: 0),
                value: 30,
                weight: 2,
                description: "A versatile one-handed axe. Can also be thrown."
            ))

        case .battle_axe:
            return ("Battle Axe", ItemData.weapon(
                type: .axe,
                damage: DiceRoll(count: 1, sides: 10, modifier: 1),
                twoHanded: true,
                value: 100,
                weight: 4,
                description: "A fearsome two-handed axe that cleaves through armor."
            ))

        case .short_bow:
            return ("Short Bow", ItemData.weapon(
                type: .bow,
                damage: DiceRoll(count: 1, sides: 6, modifier: 0),
                range: 6,
                twoHanded: true,
                value: 40,
                weight: 2,
                description: "A compact bow suited for skirmishing and close-range archery."
            ))

        case .long_bow:
            return ("Long Bow", ItemData.weapon(
                type: .bow,
                damage: DiceRoll(count: 1, sides: 8, modifier: 1),
                range: 8,
                twoHanded: true,
                value: 80,
                weight: 2,
                description: "A powerful bow with excellent range and penetration."
            ))

        case .wooden_staff:
            return ("Wooden Staff", ItemData.weapon(
                type: .staff,
                damage: DiceRoll(count: 1, sides: 6, modifier: 0),
                twoHanded: true,
                value: 20,
                weight: 4,
                description: "A simple quarterstaff. Channels magical energy adequately."
            ))

        case .oak_staff:
            return ("Oak Staff", ItemData.weapon(
                type: .staff,
                damage: DiceRoll(count: 1, sides: 6, modifier: 2),
                twoHanded: true,
                value: 75,
                weight: 4,
                description: "A sturdy oak staff, etched with arcane runes."
            ))

        case .dagger:
            return ("Dagger", ItemData.weapon(
                type: .dagger,
                damage: DiceRoll(count: 1, sides: 4, modifier: 1),
                value: 25,
                weight: 1,
                description: "A sharp dagger. Quick and deadly in skilled hands."
            ))

        case .mace:
            return ("Mace", ItemData.weapon(
                type: .axe,  // Uses STR
                damage: DiceRoll(count: 1, sides: 6, modifier: 1),
                value: 40,
                weight: 4,
                description: "A heavy mace. Effective against armored foes."
            ))

        case .war_hammer:
            return ("War Hammer", ItemData.weapon(
                type: .axe,  // Uses STR
                damage: DiceRoll(count: 1, sides: 12, modifier: 2),
                twoHanded: true,
                value: 120,
                weight: 10,
                description: "A massive two-handed hammer. Crushes armor and bones alike."
            ))

        case .spear:
            return ("Spear", ItemData.weapon(
                type: .sword,
                damage: DiceRoll(count: 1, sides: 8, modifier: 0),
                range: 2,
                value: 35,
                weight: 3,
                description: "A long spear with reach. Can attack from behind allies."
            ))

        case .crossbow:
            return ("Crossbow", ItemData.weapon(
                type: .bow,
                damage: DiceRoll(count: 1, sides: 10, modifier: 0),
                range: 7,
                twoHanded: true,
                value: 100,
                weight: 6,
                description: "A mechanical crossbow. Powerful but slow to reload."
            ))

        case .great_sword:
            return ("Great Sword", ItemData.weapon(
                type: .sword,
                damage: DiceRoll(count: 2, sides: 6, modifier: 2),
                twoHanded: true,
                value: 200,
                weight: 6,
                description: "A massive two-handed sword. Devastating in battle."
            ))

        // ARMOR
        case .leather_armor:
            return ("Leather Armor", ItemData.armor(
                type: .light,
                bonus: 1,
                value: 45,
                weight: 10,
                description: "Cured leather offering basic protection without hindering movement."
            ))

        case .studded_leather:
            return ("Studded Leather", ItemData.armor(
                type: .light,
                bonus: 2,
                value: 90,
                weight: 13,
                description: "Leather reinforced with metal studs for improved defense."
            ))

        case .hide_armor:
            return ("Hide Armor", ItemData.armor(
                type: .medium,
                bonus: 2,
                value: 60,
                weight: 12,
                description: "Thick animal hides provide decent protection."
            ))

        case .chain_shirt:
            return ("Chain Shirt", ItemData.armor(
                type: .medium,
                bonus: 3,
                value: 150,
                weight: 20,
                description: "A shirt of interlocking metal rings worn under clothing."
            ))

        case .chain_mail:
            return ("Chain Mail", ItemData.armor(
                type: .heavy,
                bonus: 4,
                value: 200,
                weight: 40,
                description: "Full chain mail with coif and mittens. STR 13 required."
            ))

        case .scale_mail:
            return ("Scale Mail", ItemData.armor(
                type: .heavy,
                bonus: 5,
                value: 300,
                weight: 45,
                description: "Overlapping metal scales on a leather backing. STR 13 required."
            ))

        case .robes:
            return ("Robes", ItemData.armor(
                type: .robe,
                bonus: 0,
                value: 15,
                weight: 4,
                description: "Simple robes. Offer little protection but allow free movement."
            ))

        case .acolyte_vestments:
            return ("Acolyte Vestments", ItemData.armor(
                type: .robe,
                bonus: 1,
                value: 75,
                weight: 5,
                description: "Blessed vestments that provide minor magical protection."
            ))

        case .shield:
            return ("Shield", ItemData.armor(
                type: .shield,
                bonus: 2,
                slot: .offHand,
                value: 50,
                weight: 6,
                description: "A sturdy wooden shield with iron boss."
            ))

        case .tower_shield:
            return ("Tower Shield", ItemData.armor(
                type: .shield,
                bonus: 3,
                slot: .offHand,
                value: 100,
                weight: 15,
                description: "A massive shield providing excellent cover. Heavy and unwieldy."
            ))

        case .plate_mail:
            return ("Plate Mail", ItemData.armor(
                type: .heavy,
                bonus: 6,
                value: 500,
                weight: 55,
                description: "Full plate armor. Maximum protection. STR 15 required."
            ))

        case .half_plate:
            return ("Half Plate", ItemData.armor(
                type: .medium,
                bonus: 4,
                value: 350,
                weight: 30,
                description: "Plate armor covering vital areas. STR 12 required."
            ))

        case .brigandine:
            return ("Brigandine", ItemData.armor(
                type: .medium,
                bonus: 3,
                value: 180,
                weight: 25,
                description: "Cloth armor lined with metal plates. Good balance of protection and mobility."
            ))

        case .buckler:
            return ("Buckler", ItemData.armor(
                type: .shield,
                bonus: 1,
                slot: .offHand,
                value: 25,
                weight: 2,
                description: "A small, light shield. Easy to use but offers minimal protection."
            ))

        case .enchanted_robes:
            return ("Enchanted Robes", ItemData.armor(
                type: .robe,
                bonus: 2,
                value: 200,
                weight: 4,
                description: "Robes woven with protective enchantments. Favored by mages."
            ))

        // CONSUMABLES
        case .minor_healing_potion:
            return ("Minor Healing Potion", ItemData.consumable(
                effect: .minorHealing,
                value: 25,
                weight: 1,
                description: "A small vial of red liquid. Heals 10 HP."
            ))

        case .healing_potion:
            return ("Healing Potion", ItemData.consumable(
                effect: .healing,
                value: 50,
                weight: 1,
                description: "A potent healing draught. Heals 25 HP."
            ))

        case .stamina_potion:
            return ("Stamina Potion", ItemData.consumable(
                effect: .staminaRestore,
                value: 40,
                weight: 1,
                description: "An invigorating brew. Restores 15 Stamina."
            ))

        case .mana_potion:
            return ("Mana Potion", ItemData.consumable(
                effect: .manaRestore,
                value: 50,
                weight: 1,
                description: "A glowing blue liquid. Restores 15 Mana."
            ))

        case .antidote:
            return ("Antidote", ItemData.consumable(
                effect: .curePoison,
                value: 35,
                weight: 1,
                description: "Neutralizes most common poisons and venoms."
            ))

        case .throwing_knife:
            return ("Throwing Knife", ItemData.consumable(
                effect: .throwingDamage,
                value: 10,
                weight: 1,
                description: "A balanced throwing knife. Deals 8 damage at range."
            ))

        case .alchemist_fire:
            return ("Alchemist's Fire", ItemData.consumable(
                effect: .fireDamage,
                maxStack: 5,
                value: 50,
                weight: 1,
                description: "A flask of volatile liquid. Deals 15 fire damage on impact."
            ))

        case .bandage:
            return ("Bandage", ItemData.consumable(
                effect: .minorHealing5,
                value: 5,
                weight: 0,
                description: "Clean linen bandages. Heals 5 HP outside of combat."
            ))

        case .torch:
            return ("Torch", ItemData.consumable(
                effect: .light,
                value: 1,
                weight: 1,
                description: "A wooden torch soaked in pitch. Provides light for 10 turns."
            ))

        case .rations:
            return ("Rations", ItemData.consumable(
                effect: .sustenance,
                value: 5,
                weight: 2,
                description: "A day's worth of dried food. Prevents hunger penalties."
            ))

        case .greater_healing_potion:
            return ("Greater Healing Potion", ItemData.consumable(
                effect: .greaterHealing,
                value: 100,
                weight: 1,
                description: "A powerful healing elixir. Heals 50 HP."
            ))

        case .strength_potion:
            return ("Strength Potion", ItemData.consumable(
                effect: .strengthBuff,
                maxStack: 5,
                value: 75,
                weight: 1,
                description: "Grants +4 STR for 5 turns. The taste is terrible."
            ))

        case .speed_potion:
            return ("Speed Potion", ItemData.consumable(
                effect: .speedBuff,
                maxStack: 5,
                value: 60,
                weight: 1,
                description: "Grants +3 movement speed for 5 turns."
            ))

        case .invisibility_potion:
            return ("Invisibility Potion", ItemData.consumable(
                effect: .invisibility,
                maxStack: 3,
                value: 150,
                weight: 1,
                description: "Become invisible for 3 turns. Attacking ends the effect."
            ))

        case .smoke_bomb:
            return ("Smoke Bomb", ItemData.consumable(
                effect: .smoke,
                maxStack: 5,
                value: 30,
                weight: 1,
                description: "Creates a cloud of smoke, obscuring vision for 2 turns."
            ))

        case .oil_flask:
            return ("Oil Flask", ItemData.consumable(
                effect: .oilDamage,
                maxStack: 5,
                value: 20,
                weight: 1,
                description: "Flammable oil. Deals 10 damage and makes target vulnerable to fire."
            ))

        case .holy_water:
            return ("Holy Water", ItemData.consumable(
                effect: .holyDamage,
                maxStack: 5,
                value: 40,
                weight: 1,
                description: "Blessed water. Deals 20 radiant damage to undead and demons."
            ))

        case .lockpick:
            return ("Lockpick", ItemData.consumable(
                effect: .utility,
                maxStack: 10,
                value: 15,
                weight: 0,
                description: "A set of thieves' tools. Used to open locked containers."
            ))

        case .rope:
            return ("Rope", ItemData.consumable(
                effect: .utility,
                stackable: false,
                maxStack: 1,
                value: 10,
                weight: 5,
                description: "50 feet of hempen rope. Useful for climbing and binding."
            ))

        case .antitoxin:
            return ("Antitoxin", ItemData.consumable(
                effect: .poisonResist,
                maxStack: 5,
                value: 50,
                weight: 1,
                description: "Grants resistance to poison for 10 turns."
            ))
        }
    }
}

// MARK: - Item Creation Helpers

extension Item {
    /// Create an item from a template ID string
    static func create(templateId: String, quantity: Int = 1) -> Item? {
        guard let template = ItemTemplate(rawValue: templateId) else {
            return nil
        }
        return template.createItem(quantity: quantity)
    }
}
