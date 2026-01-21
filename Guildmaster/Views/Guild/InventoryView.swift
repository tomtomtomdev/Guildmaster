//
//  InventoryView.swift
//  Guildmaster
//
//  Guild inventory management view
//

import SwiftUI

/// View for managing the guild's item inventory
struct InventoryView: View {
    @ObservedObject var itemManager = ItemManager.shared
    @Binding var currentScreen: GameScreen

    @State private var selectedCategory: ItemType? = nil
    @State private var selectedItem: Item?
    @State private var showingItemDetail = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.12, green: 0.1, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Category tabs
                categoryTabs

                // Item list
                ScrollView {
                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(filteredItems) { item in
                                ItemCard(item: item) {
                                    selectedItem = item
                                    showingItemDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingItemDetail) {
            if let item = selectedItem {
                ItemDetailSheet(item: item)
            }
        }
    }

    private var filteredItems: [Item] {
        if let category = selectedCategory {
            return itemManager.guildInventory.filter { $0.data.itemType == category }
        }
        return itemManager.guildInventory
    }

    private var headerView: some View {
        HStack {
            Button(action: { currentScreen = .guildHall }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.blue)
            }

            Spacer()

            Text("Armory")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Item count
            Text("\(itemManager.guildInventory.count) items")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var categoryTabs: some View {
        HStack(spacing: 0) {
            CategoryTab(
                title: "All",
                icon: "square.grid.2x2",
                isSelected: selectedCategory == nil
            ) {
                selectedCategory = nil
            }

            CategoryTab(
                title: "Weapons",
                icon: "sword",
                isSelected: selectedCategory == .weapon
            ) {
                selectedCategory = .weapon
            }

            CategoryTab(
                title: "Armor",
                icon: "shield.fill",
                isSelected: selectedCategory == .armor
            ) {
                selectedCategory = .armor
            }

            CategoryTab(
                title: "Items",
                icon: "flask.fill",
                isSelected: selectedCategory == .consumable
            ) {
                selectedCategory = .consumable
            }
        }
        .background(Color.black.opacity(0.2))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Items")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Complete quests to earn items")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? .blue : .gray)
            .background(
                isSelected ? Color.blue.opacity(0.1) : Color.clear
            )
        }
    }
}

// MARK: - Item Card

struct ItemCard: View {
    let item: Item
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(itemTypeColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(itemTypeColor)
                }

                // Name
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Quantity or stats
                if item.data.stackable && item.quantity > 1 {
                    Text("x\(item.quantity)")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                } else if let damage = item.damageString {
                    Text(damage)
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if item.data.armorBonus > 0 {
                    Text("+\(item.data.armorBonus) AC")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                // Value
                HStack(spacing: 2) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                    Text("\(item.data.value)")
                        .font(.caption2)
                }
                .foregroundColor(.yellow.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(itemTypeColor.opacity(0.3), lineWidth: 1)
            )
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

// MARK: - Item Detail Sheet

struct ItemDetailSheet: View {
    let item: Item
    @ObservedObject var guildManager = GuildManager.shared
    @ObservedObject var itemManager = ItemManager.shared

    @Environment(\.dismiss) private var dismiss
    @State private var showingEquipSheet = false
    @State private var selectedCharacter: Character?

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Item header
                        itemHeader

                        // Stats
                        statsSection

                        // Description
                        descriptionSection

                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingEquipSheet) {
            EquipToCharacterSheet(item: item)
        }
    }

    private var itemHeader: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(itemTypeColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: item.icon)
                    .font(.largeTitle)
                    .foregroundColor(itemTypeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.data.itemType.rawValue)
                    .font(.caption)
                    .foregroundColor(itemTypeColor)

                if item.data.stackable && item.quantity > 1 {
                    Text("Quantity: \(item.quantity)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(item.data.value) gold")
                        .foregroundColor(.white)
                }
                .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Properties")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 8) {
                if let damage = item.data.damage {
                    PropertyRow(label: "Damage", value: damage.description, color: .orange)
                }

                if let weaponType = item.data.weaponType {
                    PropertyRow(label: "Type", value: weaponType.rawValue, color: .gray)

                    if item.data.isTwoHanded {
                        PropertyRow(label: "Hands", value: "Two-Handed", color: .gray)
                    }

                    if let range = item.data.attackRange, range > 1 {
                        PropertyRow(label: "Range", value: "\(range) hexes", color: .blue)
                    }
                }

                if item.data.armorBonus > 0 {
                    PropertyRow(label: "Armor Bonus", value: "+\(item.data.armorBonus)", color: .blue)
                }

                if let armorType = item.data.armorType {
                    PropertyRow(label: "Armor Type", value: armorType.rawValue, color: .gray)

                    if armorType.strengthRequirement > 0 {
                        PropertyRow(label: "STR Required", value: "\(armorType.strengthRequirement)", color: .red)
                    }
                }

                if let effect = item.data.effect {
                    PropertyRow(label: "Effect", value: effect.effectType.rawValue, color: .green)
                    PropertyRow(label: "Value", value: "\(effect.value)", color: .green)
                }

                PropertyRow(label: "Weight", value: "\(item.data.weight) lbs", color: .gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.white)

            Text(item.data.description)
                .font(.body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if item.data.itemType == .weapon || item.data.itemType == .armor {
                Button(action: { showingEquipSheet = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Equip to Character")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
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

// MARK: - Property Row

struct PropertyRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Equip to Character Sheet

struct EquipToCharacterSheet: View {
    let item: Item
    @ObservedObject var guildManager = GuildManager.shared
    @ObservedObject var itemManager = ItemManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        Text("Select a character to equip \(item.name)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()

                        ForEach(guildManager.roster) { character in
                            CharacterEquipRow(
                                character: character,
                                item: item,
                                canEquip: character.canEquip(item: item)
                            ) {
                                if itemManager.equipToCharacter(item, character: character) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Equip Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Character Equip Row

struct CharacterEquipRow: View {
    let character: Character
    let item: Item
    let canEquip: Bool
    let onEquip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CharacterPortrait(character: character, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(character.name)
                    .font(.subheadline)
                    .foregroundColor(canEquip ? .white : .gray)

                Text("\(character.characterClass.rawValue)")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Show current equipment in this slot
                if let current = currentEquipment {
                    Text("Current: \(current)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            if canEquip {
                Button("Equip") {
                    onEquip()
                }
                .font(.caption)
                .foregroundColor(.blue)
            } else {
                Text("Can't equip")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(canEquip ? 0.05 : 0.02))
        .cornerRadius(8)
    }

    private var currentEquipment: String? {
        let slot = item.data.slot
        if let equipped = character.equipment.item(in: slot) {
            return equipped.name
        }
        return nil
    }
}

#Preview {
    InventoryView(currentScreen: .constant(.inventory))
}
