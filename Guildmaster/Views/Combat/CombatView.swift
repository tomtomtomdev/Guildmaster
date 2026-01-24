//
//  CombatView.swift
//  Guildmaster
//
//  Main combat screen UI
//

import SwiftUI

/// Main combat view containing grid and action UI
struct CombatView: View {
    @ObservedObject var combatManager = CombatManager.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top bar - Turn info
                CombatHeaderView(combatManager: combatManager)

                // Main content
                if geometry.size.width > geometry.size.height {
                    // Landscape layout
                    HStack(spacing: 0) {
                        // Grid
                        HexGridView(
                            grid: combatManager.grid,
                            combatManager: combatManager,
                            onHexTapped: handleHexTap
                        )
                        .frame(maxWidth: .infinity)

                        // Side panel
                        CombatSidePanel(combatManager: combatManager)
                            .frame(width: 200)
                    }
                } else {
                    // Portrait layout
                    VStack(spacing: 0) {
                        // Grid
                        HexGridView(
                            grid: combatManager.grid,
                            combatManager: combatManager,
                            onHexTapped: handleHexTap
                        )
                        .frame(maxHeight: geometry.size.height * 0.55)

                        // Bottom panel
                        CombatBottomPanel(combatManager: combatManager)
                    }
                }
            }
            .background(Color(red: 0.2, green: 0.15, blue: 0.1))
        }
        .overlay(
            // Victory/Defeat overlay
            combatResultOverlay
        )
    }

    private func handleHexTap(_ coordinate: HexCoordinate) {
        // Combat is fully autonomous - tapping hexes selects them for viewing
        combatManager.grid.selectedHex = coordinate
    }

    @ViewBuilder
    private var combatResultOverlay: some View {
        if combatManager.state == .victory {
            CombatResultView(isVictory: true, stats: combatManager.combatStats)
        } else if combatManager.state == .defeat {
            CombatResultView(isVictory: false, stats: combatManager.combatStats)
        }
    }
}

/// Header showing turn and round info
struct CombatHeaderView: View {
    @ObservedObject var combatManager: CombatManager

    var body: some View {
        HStack {
            // Turn counter
            Text("Round \(combatManager.turnManager.currentTurn)")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Current phase
            Text(phaseText)
                .font(.subheadline)
                .foregroundColor(phaseColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(phaseColor.opacity(0.2))
                )

            Spacer()

            // Menu button
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
    }

    private var phaseText: String {
        if let unit = combatManager.turnManager.currentUnit {
            return unit.name + "'s Turn"
        }
        return combatManager.turnManager.currentPhase.rawValue
    }

    private var phaseColor: Color {
        return combatManager.turnManager.isPlayerTurn ? .blue : .red
    }
}

/// Side panel for landscape layout
struct CombatSidePanel: View {
    @ObservedObject var combatManager: CombatManager

    var body: some View {
        VStack(spacing: 12) {
            // Current unit info
            if let unit = combatManager.turnManager.currentUnit {
                CurrentUnitView(unit: unit)
            }

            Divider()
                .background(Color.gray)

            Spacer()

            // Combat log
            CombatLogView(entries: combatManager.combatLog)
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
    }
}

/// Bottom panel for portrait layout
struct CombatBottomPanel: View {
    @ObservedObject var combatManager: CombatManager

    var body: some View {
        VStack(spacing: 8) {
            // Current unit info
            if let unit = combatManager.turnManager.currentUnit {
                CurrentUnitView(unit: unit)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
    }
}

/// Current unit info display
struct CurrentUnitView: View {
    let unit: CombatUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name and class
            Text(unit.name)
                .font(.headline)
                .foregroundColor(.white)

            // HP bar
            HStack {
                Text("HP")
                    .font(.caption)
                    .foregroundColor(.gray)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))

                        Rectangle()
                            .fill(hpColor)
                            .frame(width: geometry.size.width * CGFloat(unit.currentHP) / CGFloat(unit.maxHP))
                    }
                }
                .frame(height: 12)
                .cornerRadius(4)

                Text("\(unit.currentHP)/\(unit.maxHP)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .trailing)
            }

            // Resources (if applicable)
            if unit.maxMana > 0 {
                HStack {
                    Text("MP")
                        .font(.caption)
                        .foregroundColor(.gray)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(unit.currentMana) / CGFloat(max(1, unit.maxMana)))
                        }
                    }
                    .frame(height: 12)
                    .cornerRadius(4)

                    Text("\(unit.currentMana)/\(unit.maxMana)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 60, alignment: .trailing)
                }
            }

            if unit.maxStamina > 0 {
                HStack {
                    Text("ST")
                        .font(.caption)
                        .foregroundColor(.gray)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))

                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * CGFloat(unit.currentStamina) / CGFloat(max(1, unit.maxStamina)))
                        }
                    }
                    .frame(height: 12)
                    .cornerRadius(4)

                    Text("\(unit.currentStamina)/\(unit.maxStamina)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding(8)
    }

    private var hpColor: Color {
        let percentage = Double(unit.currentHP) / Double(unit.maxHP)
        if percentage > 0.5 { return .green }
        if percentage > 0.25 { return .orange }
        return .red
    }
}

/// Action buttons for combat
struct ActionButtonsView: View {
    @ObservedObject var combatManager: CombatManager

    var body: some View {
        VStack(spacing: 8) {
            // Basic actions row
            HStack(spacing: 8) {
                ActionButton(title: "Attack", icon: "sword", color: .red) {
                    combatManager.selectAbility(.basicAttack)
                }
                .disabled(combatManager.turnManager.hasActedThisTurn)

                ActionButton(title: "Defend", icon: "shield", color: .blue) {
                    combatManager.defend()
                }
                .disabled(combatManager.turnManager.hasActedThisTurn)
            }

            // Abilities row (if unit has abilities)
            if let unit = combatManager.turnManager.currentUnit {
                let usableAbilities = unit.abilities.filter { ability in
                    ability != .basicAttack && ability != .defend && ability != .move
                }

                if !usableAbilities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(usableAbilities, id: \.self) { ability in
                                AbilityButton(ability: ability) {
                                    combatManager.selectAbility(ability)
                                }
                                .disabled(combatManager.turnManager.hasActedThisTurn || !canUseAbility(ability, unit: unit))
                            }
                        }
                    }
                }
            }
        }
    }

    private func canUseAbility(_ ability: AbilityType, unit: CombatUnit) -> Bool {
        let data = ability.data
        switch data.resourceType {
        case .stamina:
            return unit.currentStamina >= data.resourceCost
        case .mana:
            return unit.currentMana >= data.resourceCost
        default:
            return true
        }
    }
}

/// Generic action button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 70, height: 60)
            .background(color.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 2)
            )
        }
    }

    private var iconName: String {
        switch icon {
        case "sword": return "figure.fencing"
        case "shield": return "shield.fill"
        default: return "star.fill"
        }
    }
}

/// Ability button with cost display
struct AbilityButton: View {
    let ability: AbilityType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(ability.rawValue)
                    .font(.caption)
                    .lineLimit(1)

                Text(costText)
                    .font(.caption2)
                    .foregroundColor(costColor)
            }
            .frame(width: 80, height: 50)
            .background(Color.purple.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(6)
        }
    }

    private var costText: String {
        let data = ability.data
        switch data.resourceType {
        case .stamina:
            return "\(data.resourceCost) ST"
        case .mana:
            return "\(data.resourceCost) MP"
        default:
            return ""
        }
    }

    private var costColor: Color {
        let data = ability.data
        switch data.resourceType {
        case .stamina:
            return .orange
        case .mana:
            return .blue
        default:
            return .gray
        }
    }
}

/// Combat log view
struct CombatLogView: View {
    let entries: [CombatLogEntry]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(entries.suffix(20).reversed()) { entry in
                    Text(entry.message)
                        .font(.caption)
                        .foregroundColor(colorFor(entry.type))
                }
            }
        }
        .frame(maxHeight: 150)
    }

    private func colorFor(_ type: CombatLogType) -> Color {
        switch type {
        case .system: return .gray
        case .turnStart: return .yellow
        case .movement: return .cyan
        case .action: return .white
        case .damage: return .red
        case .heal: return .green
        case .miss: return .gray
        case .critical: return .orange
        case .death: return .purple
        }
    }
}

/// Victory/Defeat result screen
struct CombatResultView: View {
    let isVictory: Bool
    let stats: CombatStatistics

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Title
                Text(isVictory ? "VICTORY!" : "DEFEAT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isVictory ? .yellow : .red)

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(label: "Enemies Defeated", value: "\(stats.enemiesKilled)")
                    StatRow(label: "Damage Dealt", value: "\(stats.totalDamageDealt)")
                    StatRow(label: "Healing Done", value: "\(stats.totalHealing)")
                    StatRow(label: "Critical Hits", value: "\(stats.criticalHits)")

                    if stats.partyDeaths > 0 {
                        StatRow(label: "Fallen Allies", value: "\(stats.partyDeaths)")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Continue button
                Button(action: {
                    // Return to guild hall
                }) {
                    Text("Continue")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(40)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

#Preview {
    CombatView()
}
