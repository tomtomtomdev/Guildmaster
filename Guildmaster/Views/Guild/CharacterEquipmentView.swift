//
//  CharacterEquipmentView.swift
//  Guildmaster
//
//  Character equipment management view
//

import SwiftUI

/// View for managing a character's equipment
struct CharacterEquipmentView: View {
    @ObservedObject var character: Character
    @ObservedObject var itemManager = ItemManager.shared

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSlot: EquipmentSlot?
    @State private var showingItemPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Character header
                        characterHeader

                        // Equipment slots
                        equipmentSlotsSection

                        // Combat stats
                        combatStatsSection

                        // Combat inventory
                        combatInventorySection
                    }
                    .padding()
                }
            }
            .navigationTitle("Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingItemPicker) {
            if let slot = selectedSlot {
                ItemPickerSheet(
                    character: character,
                    slot: slot
                )
            }
        }
    }

    private var characterHeader: some View {
        HStack(spacing: 16) {
            CharacterPortrait(character: character, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("Level \(character.level)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var equipmentSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 12) {
                // Main Hand
                EquipmentSlotRow(
                    slotName: "Main Hand",
                    icon: "hand.raised.fill",
                    item: character.equipment.mainHand
                ) {
                    selectedSlot = .mainHand
                    showingItemPicker = true
                } onUnequip: {
                    if let item = character.equipment.mainHand {
                        itemManager.unequipFromCharacter(item, character: character, slot: .mainHand)
                    }
                }

                // Off Hand
                EquipmentSlotRow(
                    slotName: "Off Hand",
                    icon: "hand.raised.fill",
                    item: character.equipment.offHand,
                    isDisabled: character.equipment.mainHand?.data.isTwoHanded == true
                ) {
                    selectedSlot = .offHand
                    showingItemPicker = true
                } onUnequip: {
                    if let item = character.equipment.offHand {
                        itemManager.unequipFromCharacter(item, character: character, slot: .offHand)
                    }
                }

                // Body
                EquipmentSlotRow(
                    slotName: "Body",
                    icon: "tshirt.fill",
                    item: character.equipment.body
                ) {
                    selectedSlot = .body
                    showingItemPicker = true
                } onUnequip: {
                    if let item = character.equipment.body {
                        itemManager.unequipFromCharacter(item, character: character, slot: .body)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var combatStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combat Stats")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 20) {
                StatColumn(label: "AC", value: "\(character.totalArmorClass)")
                StatColumn(label: "Damage", value: character.weaponDamage.description)
                StatColumn(label: "Range", value: "\(character.attackRange)")
                StatColumn(label: "Speed", value: "\(character.secondaryStats.movementSpeed)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var combatInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Combat Items")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(character.inventory.count)/\(character.maxInventorySize)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if character.inventory.isEmpty {
                Text("No combat items")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(character.inventory) { item in
                    ConsumableRow(item: item) {
                        if itemManager.takeConsumableFromCharacter(item, character: character) {
                            // Item returned to guild
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Equipment Slot Row

struct EquipmentSlotRow: View {
    let slotName: String
    let icon: String
    let item: Item?
    var isDisabled: Bool = false
    let onTap: () -> Void
    let onUnequip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Slot icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item != nil ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)

                if let item = item {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.5))
                }
            }

            // Slot info
            VStack(alignment: .leading, spacing: 2) {
                Text(slotName)
                    .font(.caption)
                    .foregroundColor(.gray)

                if let item = item {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                } else if isDisabled {
                    Text("(Two-handed weapon equipped)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Empty")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Actions
            if item != nil {
                Button(action: onUnequip) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red.opacity(0.8))
                }

                Button(action: onTap) {
                    Image(systemName: "arrow.triangle.swap")
                        .foregroundColor(.blue)
                }
            } else if !isDisabled {
                Button(action: onTap) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .opacity(isDisabled && item == nil ? 0.5 : 1.0)
    }
}

// MARK: - Stat Column

struct StatColumn: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Consumable Row

struct ConsumableRow: View {
    let item: Item
    let onReturn: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                if item.quantity > 1 {
                    Text("x\(item.quantity)")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }

            Spacer()

            Button(action: onReturn) {
                Text("Return")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Item Picker Sheet

struct ItemPickerSheet: View {
    let character: Character
    let slot: EquipmentSlot
    @ObservedObject var itemManager = ItemManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        if availableItems.isEmpty {
                            emptyState
                        } else {
                            ForEach(availableItems) { item in
                                ItemPickerRow(item: item, character: character) {
                                    if itemManager.equipToCharacter(item, character: character, slot: slot) {
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select \(slot.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var availableItems: [Item] {
        return itemManager.guildInventory.filter { item in
            // Must match slot
            guard item.data.slot == slot else {
                // Shields can go in offHand
                if slot == .offHand && item.data.armorType == .shield {
                    return true
                }
                return false
            }

            // Character must be able to equip
            return character.canEquip(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Items Available")
                .font(.headline)
                .foregroundColor(.gray)

            Text("No suitable items in guild inventory")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Item Picker Row

struct ItemPickerRow: View {
    let item: Item
    let character: Character
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(itemTypeColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.icon)
                        .foregroundColor(itemTypeColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    HStack {
                        if let damage = item.damageString {
                            Text(damage)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        if item.data.armorBonus > 0 {
                            Text("+\(item.data.armorBonus) AC")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
    }

    private var itemTypeColor: Color {
        switch item.data.itemType {
        case .weapon: return .orange
        case .armor: return .blue
        case .consumable: return .green
        }
    }
}

#Preview {
    CharacterEquipmentView(
        character: Character(name: "Test", race: .human, characterClass: .warrior)
    )
}
