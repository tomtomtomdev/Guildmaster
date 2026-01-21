//
//  ItemManager.swift
//  Guildmaster
//
//  Manages the guild's item inventory and equipment
//

import Foundation
import Combine

/// Manages the guild's inventory and character equipment
class ItemManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ItemManager()

    // MARK: - Published State

    /// Items stored in the guild's inventory
    @Published var guildInventory: [Item] = []

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {}

    // MARK: - Inventory Management

    /// Add an item to the guild inventory
    func addItem(_ item: Item) {
        // Check if we can stack with existing item
        if item.data.stackable {
            if let existingIndex = guildInventory.firstIndex(where: { $0.templateId == item.templateId }) {
                guildInventory[existingIndex].quantity += item.quantity
                return
            }
        }

        guildInventory.append(item)
        NotificationCenter.default.post(name: .itemAdded, object: nil, userInfo: ["item": item])
    }

    /// Add multiple items from template IDs
    func addItems(templateIds: [String]) {
        var addedItems: [Item] = []

        // Group by template ID for stacking
        var templateCounts: [String: Int] = [:]
        for id in templateIds {
            templateCounts[id, default: 0] += 1
        }

        for (templateId, count) in templateCounts {
            if let item = Item.create(templateId: templateId, quantity: count) {
                addItem(item)
                addedItems.append(item)
            }
        }

        if !addedItems.isEmpty {
            NotificationCenter.default.post(
                name: .itemsAwarded,
                object: nil,
                userInfo: ["items": addedItems]
            )
        }
    }

    /// Remove an item from the guild inventory
    func removeItem(_ item: Item, quantity: Int = 1) {
        guard let index = guildInventory.firstIndex(where: { $0.id == item.id }) else { return }

        if guildInventory[index].quantity <= quantity {
            guildInventory.remove(at: index)
        } else {
            guildInventory[index].quantity -= quantity
        }
    }

    /// Remove an item by ID
    func removeItem(byId id: UUID, quantity: Int = 1) {
        guard let item = guildInventory.first(where: { $0.id == id }) else { return }
        removeItem(item, quantity: quantity)
    }

    /// Get item by ID
    func item(byId id: UUID) -> Item? {
        return guildInventory.first { $0.id == id }
    }

    /// Get items filtered by type
    func items(ofType type: ItemType) -> [Item] {
        return guildInventory.filter { $0.data.itemType == type }
    }

    /// Get all weapons in inventory
    var weapons: [Item] {
        return items(ofType: .weapon)
    }

    /// Get all armor in inventory
    var armor: [Item] {
        return items(ofType: .armor)
    }

    /// Get all consumables in inventory
    var consumables: [Item] {
        return items(ofType: .consumable)
    }

    // MARK: - Equipment Management

    /// Equip an item from guild inventory to a character
    func equipToCharacter(_ item: Item, character: Character, slot: EquipmentSlot? = nil) -> Bool {
        // Verify item is in guild inventory
        guard guildInventory.contains(where: { $0.id == item.id }) else { return false }

        // Check if character can equip
        guard character.canEquip(item: item) else { return false }

        // Determine slot
        let targetSlot = slot ?? item.data.slot
        guard targetSlot != .none else { return false }

        // Unequip existing item in slot first
        if let existingItem = character.equipment.item(in: targetSlot) {
            unequipFromCharacter(existingItem, character: character, slot: targetSlot)
        }

        // If two-handed weapon, also clear off-hand
        if item.data.isTwoHanded && targetSlot == .mainHand {
            if let offHandItem = character.equipment.offHand {
                unequipFromCharacter(offHandItem, character: character, slot: .offHand)
            }
        }

        // Remove from guild inventory
        removeItem(item, quantity: 1)

        // Equip to character
        character.equip(item: item, to: targetSlot)

        return true
    }

    /// Unequip an item from a character back to guild inventory
    func unequipFromCharacter(_ item: Item, character: Character, slot: EquipmentSlot) {
        // Remove from character equipment
        character.unequip(slot: slot)

        // Add back to guild inventory
        addItem(item)
    }

    /// Give a consumable to character's combat inventory
    func giveConsumableToCharacter(_ item: Item, character: Character, quantity: Int = 1) -> Bool {
        guard item.data.itemType == .consumable else { return false }
        guard guildInventory.contains(where: { $0.id == item.id }) else { return false }
        guard character.inventory.count < character.maxInventorySize else { return false }

        // Check if character already has this item
        if let existingIndex = character.inventory.firstIndex(where: { $0.templateId == item.templateId }) {
            // Add to existing stack
            let toAdd = min(quantity, item.quantity)
            character.inventory[existingIndex].quantity += toAdd
            removeItem(item, quantity: toAdd)
        } else {
            // Create new stack for character
            let toGive = min(quantity, item.quantity)
            let charItem = Item(
                templateId: item.templateId,
                name: item.name,
                data: item.data,
                quantity: toGive
            )
            character.inventory.append(charItem)
            removeItem(item, quantity: toGive)
        }

        return true
    }

    /// Take a consumable from character back to guild inventory
    func takeConsumableFromCharacter(_ item: Item, character: Character, quantity: Int = 1) -> Bool {
        guard let index = character.inventory.firstIndex(where: { $0.id == item.id }) else { return false }

        let toTake = min(quantity, character.inventory[index].quantity)

        if character.inventory[index].quantity <= toTake {
            character.inventory.remove(at: index)
        } else {
            character.inventory[index].quantity -= toTake
        }

        // Add to guild inventory
        let guildItem = Item(
            templateId: item.templateId,
            name: item.name,
            data: item.data,
            quantity: toTake
        )
        addItem(guildItem)

        return true
    }

    // MARK: - Save/Load

    func save() -> ItemManagerSaveData {
        return ItemManagerSaveData(guildInventory: guildInventory)
    }

    func load(from data: ItemManagerSaveData) {
        guildInventory = data.guildInventory
    }

    /// Reset inventory (for new game)
    func reset() {
        guildInventory = []
    }
}

// MARK: - Save Data

struct ItemManagerSaveData: Codable {
    let guildInventory: [Item]
}

// MARK: - Notifications

extension Notification.Name {
    static let itemAdded = Notification.Name("itemAdded")
    static let itemsAwarded = Notification.Name("itemsAwarded")
    static let itemEquipped = Notification.Name("itemEquipped")
    static let itemUnequipped = Notification.Name("itemUnequipped")
}
