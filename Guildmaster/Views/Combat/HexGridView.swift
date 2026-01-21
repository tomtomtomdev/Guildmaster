//
//  HexGridView.swift
//  Guildmaster
//
//  SwiftUI view for rendering the hex grid
//

import SwiftUI

/// Main hex grid view for combat
struct HexGridView: View {
    @ObservedObject var grid: HexGrid
    @ObservedObject var combatManager: CombatManager

    let onHexTapped: (HexCoordinate) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Background
                    Color(red: 0.85, green: 0.75, blue: 0.55)
                        .frame(width: grid.gridSize.width, height: grid.gridSize.height)

                    // Hex tiles
                    ForEach(Array(grid.tiles.values)) { tile in
                        HexTileView(
                            tile: tile,
                            grid: grid,
                            isHighlighted: grid.highlightedHexes.contains(tile.coordinate),
                            highlightColor: grid.highlightColor,
                            isSelected: grid.selectedHex == tile.coordinate,
                            unit: getUnit(at: tile.coordinate)
                        )
                        .position(grid.hexToPixel(tile.coordinate))
                        .onTapGesture {
                            onHexTapped(tile.coordinate)
                        }
                    }

                    // Path overlay
                    if !grid.currentPath.isEmpty {
                        PathOverlayView(path: grid.currentPath, grid: grid)
                    }
                }
                .frame(width: grid.gridSize.width, height: grid.gridSize.height)
            }
        }
    }

    private func getUnit(at coordinate: HexCoordinate) -> CombatUnit? {
        return combatManager.turnManager.livingUnits.first { $0.position == coordinate }
    }
}

/// Individual hex tile view
struct HexTileView: View {
    let tile: HexTile
    let grid: HexGrid
    let isHighlighted: Bool
    let highlightColor: Color
    let isSelected: Bool
    let unit: CombatUnit?

    var body: some View {
        ZStack {
            // Hex shape
            HexShape()
                .fill(backgroundColor)
                .overlay(
                    HexShape()
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                )
                .frame(width: grid.hexSize * 2 * 0.9, height: grid.hexSize * 2 * 0.9)

            // Highlight overlay
            if isHighlighted {
                HexShape()
                    .fill(highlightColor)
                    .frame(width: grid.hexSize * 2 * 0.85, height: grid.hexSize * 2 * 0.85)
            }

            // Unit display
            if let unit = unit {
                UnitTokenView(unit: unit, size: grid.hexSize * 1.4)
            }
        }
    }

    private var backgroundColor: Color {
        if tile.terrain == .wall {
            return .gray.opacity(0.8)
        }
        return tile.terrain.color
    }

    private var borderColor: Color {
        if isSelected {
            return .yellow
        }
        return Color(red: 0.4, green: 0.3, blue: 0.2)
    }
}

/// Hexagonal shape for drawing hexes
struct HexShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = CGFloat.pi / 3 * CGFloat(i) - CGFloat.pi / 6
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

/// Unit token displayed on hex
struct UnitTokenView: View {
    let unit: CombatUnit
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(unit.isPlayerControlled ? Color.blue.opacity(0.8) : Color.red.opacity(0.8))
                .frame(width: size, height: size)

            // Border
            Circle()
                .stroke(borderColor, lineWidth: 2)
                .frame(width: size, height: size)

            // Class icon or initial
            Text(classInitial)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)

            // HP bar
            VStack {
                Spacer()
                HPBarView(current: unit.currentHP, max: unit.maxHP, width: size * 0.8)
            }
            .frame(height: size)
        }
        .overlay(
            // Current turn indicator
            unit.id == CombatManager.shared.turnManager.currentUnit?.id ?
            Circle()
                .stroke(Color.yellow, lineWidth: 3)
                .frame(width: size + 6, height: size + 6)
            : nil
        )
    }

    private var classInitial: String {
        if let character = unit.character {
            return String(character.characterClass.rawValue.prefix(1))
        } else if let enemy = unit.enemy {
            return String(enemy.name.prefix(1))
        }
        return "?"
    }

    private var borderColor: Color {
        if unit.isBloodied {
            return .orange
        }
        if unit.isCritical {
            return .red
        }
        return .white
    }
}

/// HP bar view
struct HPBarView: View {
    let current: Int
    let max: Int
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.5))
                .frame(width: width, height: 6)

            // HP fill
            RoundedRectangle(cornerRadius: 2)
                .fill(hpColor)
                .frame(width: width * hpPercentage, height: 6)
        }
    }

    private var hpPercentage: CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(current) / CGFloat(max)
    }

    private var hpColor: Color {
        if hpPercentage > 0.5 {
            return .green
        } else if hpPercentage > 0.25 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Path overlay showing movement path
struct PathOverlayView: View {
    let path: [HexCoordinate]
    let grid: HexGrid

    var body: some View {
        Path { p in
            guard path.count > 1 else { return }

            let start = grid.hexToPixel(path[0])
            p.move(to: start)

            for coord in path.dropFirst() {
                let point = grid.hexToPixel(coord)
                p.addLine(to: point)
            }
        }
        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, dash: [5, 3]))
    }
}

// MARK: - Preview

#Preview {
    let grid = HexGrid(width: 8, height: 8, hexSize: 35)
    let combatManager = CombatManager.shared

    return HexGridView(
        grid: grid,
        combatManager: combatManager,
        onHexTapped: { coord in
            print("Tapped: \(coord)")
        }
    )
}
