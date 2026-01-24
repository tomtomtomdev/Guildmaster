//
//  CombatView.swift
//  Guildmaster
//
//  Commentary-style combat screen — text feed with compact party HP bar
//

import SwiftUI

/// Main combat view showing commentary feed and party status
struct CombatView: View {
    @ObservedObject var combatManager = CombatManager.shared
    @ObservedObject var commentary = CombatCommentary.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header — round counter, current unit, phase
            CombatHeaderView(combatManager: combatManager)

            // Main commentary feed
            CommentaryFeedView(
                messages: commentary.messages,
                logEntries: combatManager.combatLog
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Compact party HP bar
            CompactPartyBarView(units: combatManager.playerUnits)
        }
        .background(Color(red: 0.12, green: 0.1, blue: 0.14))
        .overlay(combatResultOverlay)
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

// MARK: - Header

/// Header showing turn and round info
struct CombatHeaderView: View {
    @ObservedObject var combatManager: CombatManager

    var body: some View {
        HStack {
            Text("Round \(combatManager.turnManager.currentTurn)")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

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

            // Menu button placeholder
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

// MARK: - Commentary Feed

/// Full-screen scrolling commentary feed
struct CommentaryFeedView: View {
    let messages: [CommentaryMessage]
    let logEntries: [CombatLogEntry]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(logEntries) { entry in
                        CommentaryEntryView(entry: entry)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: logEntries.count) { _ in
                if let lastEntry = logEntries.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

/// Individual commentary entry with color-coding and styling
struct CommentaryEntryView: View {
    let entry: CombatLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Event type indicator
            Circle()
                .fill(colorFor(entry.type))
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(entry.message)
                .font(fontFor(entry.type))
                .foregroundColor(colorFor(entry.type))
                .fontWeight(weightFor(entry.type))
        }
        .padding(.vertical, 2)
    }

    private func colorFor(_ type: CombatLogType) -> Color {
        switch type {
        case .system: return .gray
        case .turnStart: return Color(red: 0.9, green: 0.85, blue: 0.5)
        case .movement: return Color(red: 0.5, green: 0.8, blue: 0.9)
        case .action: return .white
        case .damage: return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .heal: return Color(red: 0.3, green: 0.9, blue: 0.4)
        case .miss: return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .critical: return Color(red: 1.0, green: 0.7, blue: 0.1)
        case .death: return Color(red: 0.8, green: 0.2, blue: 0.9)
        }
    }

    private func fontFor(_ type: CombatLogType) -> Font {
        switch type {
        case .death, .critical:
            return .body.bold()
        case .system:
            return .callout.italic()
        case .turnStart:
            return .callout
        default:
            return .body
        }
    }

    private func weightFor(_ type: CombatLogType) -> Font.Weight {
        switch type {
        case .death, .critical: return .bold
        case .damage: return .medium
        default: return .regular
        }
    }
}

// MARK: - Compact Party HP Bar

/// Horizontal strip showing party member names and HP bars
struct CompactPartyBarView: View {
    let units: [CombatUnit]

    var body: some View {
        VStack(spacing: 4) {
            Divider()
                .background(Color.gray.opacity(0.5))

            // Arrange in rows of 2
            let rows = stride(from: 0, to: units.count, by: 2).map { i in
                Array(units[i..<min(i + 2, units.count)])
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.id) { unit in
                        CompactUnitHPView(unit: unit)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
    }
}

/// Single unit HP display — name + thin bar
struct CompactUnitHPView: View {
    let unit: CombatUnit

    var body: some View {
        HStack(spacing: 6) {
            Text(unit.name)
                .font(.caption)
                .foregroundColor(unit.isAlive ? .white : .gray)
                .lineLimit(1)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))

                    Rectangle()
                        .fill(hpColor)
                        .frame(width: geometry.size.width * hpFraction)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
    }

    private var hpFraction: CGFloat {
        guard unit.maxHP > 0 else { return 0 }
        return CGFloat(max(0, unit.currentHP)) / CGFloat(unit.maxHP)
    }

    private var hpColor: Color {
        let pct = Double(unit.currentHP) / Double(max(1, unit.maxHP))
        if pct > 0.5 { return .green }
        if pct > 0.25 { return .orange }
        return .red
    }
}

// MARK: - Combat Result

/// Victory/Defeat result screen
struct CombatResultView: View {
    let isVictory: Bool
    let stats: CombatStatistics

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(isVictory ? "VICTORY!" : "DEFEAT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isVictory ? .yellow : .red)

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

                Button(action: {}) {
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
