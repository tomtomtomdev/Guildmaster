//
//  HexGrid.swift
//  Guildmaster
//
//  Hex grid coordinate system using cube coordinates
//  Reference: https://www.redblobgames.com/grids/hexagons/
//

import Foundation
import SwiftUI
import Combine

/// Cube coordinate for hexagonal grids
/// Uses the constraint: q + r + s = 0
struct HexCoordinate: Hashable, Codable, Equatable {
    let q: Int  // Column
    let r: Int  // Row
    var s: Int { -q - r }  // Computed from constraint

    /// Create from cube coordinates
    init(q: Int, r: Int) {
        self.q = q
        self.r = r
    }

    /// Create from offset coordinates (even-q offset)
    init(col: Int, row: Int) {
        self.q = col
        self.r = row - (col + (col & 1)) / 2
    }

    /// Convert to offset coordinates (even-q offset)
    var offsetCoordinates: (col: Int, row: Int) {
        let col = q
        let row = r + (q + (q & 1)) / 2
        return (col, row)
    }

    // MARK: - Neighbor Directions

    /// The six hexagonal directions in cube coordinates
    static let directions: [HexCoordinate] = [
        HexCoordinate(q: 1, r: 0),   // East
        HexCoordinate(q: 1, r: -1),  // Northeast
        HexCoordinate(q: 0, r: -1),  // Northwest
        HexCoordinate(q: -1, r: 0),  // West
        HexCoordinate(q: -1, r: 1),  // Southwest
        HexCoordinate(q: 0, r: 1)    // Southeast
    ]

    /// Get neighbor in a specific direction (0-5)
    func neighbor(direction: Int) -> HexCoordinate {
        let dir = HexCoordinate.directions[direction % 6]
        return self + dir
    }

    /// Get all six neighbors
    var neighbors: [HexCoordinate] {
        return HexCoordinate.directions.map { self + $0 }
    }

    // MARK: - Distance

    /// Manhattan distance in cube coordinates
    func distance(to other: HexCoordinate) -> Int {
        return (abs(q - other.q) + abs(r - other.r) + abs(s - other.s)) / 2
    }

    /// Get all hexes within a certain range
    func hexesInRange(_ range: Int) -> [HexCoordinate] {
        var results: [HexCoordinate] = []
        for dq in -range...range {
            for dr in max(-range, -dq - range)...min(range, -dq + range) {
                results.append(HexCoordinate(q: q + dq, r: r + dr))
            }
        }
        return results
    }

    /// Get hexes in a ring at exactly the given distance
    func hexesInRing(radius: Int) -> [HexCoordinate] {
        guard radius > 0 else { return [self] }

        var results: [HexCoordinate] = []
        var hex = self + HexCoordinate.directions[4].scaled(by: radius)  // Start SW

        for direction in 0..<6 {
            for _ in 0..<radius {
                results.append(hex)
                hex = hex.neighbor(direction: direction)
            }
        }

        return results
    }

    /// Scale the coordinate by a factor
    func scaled(by factor: Int) -> HexCoordinate {
        return HexCoordinate(q: q * factor, r: r * factor)
    }

    // MARK: - Line Drawing

    /// Get all hexes in a line to another hex
    func line(to other: HexCoordinate) -> [HexCoordinate] {
        let distance = self.distance(to: other)
        guard distance > 0 else { return [self] }

        var results: [HexCoordinate] = []
        for i in 0...distance {
            let t = Double(i) / Double(distance)
            results.append(lerp(to: other, t: t))
        }
        return results
    }

    /// Linear interpolation between hexes
    private func lerp(to other: HexCoordinate, t: Double) -> HexCoordinate {
        let q = Double(self.q) + (Double(other.q) - Double(self.q)) * t
        let r = Double(self.r) + (Double(other.r) - Double(self.r)) * t
        return HexCoordinate.round(q: q, r: r)
    }

    /// Round floating point cube coordinates to nearest hex
    static func round(q: Double, r: Double) -> HexCoordinate {
        let s = -q - r

        var rq = Darwin.round(q)
        var rr = Darwin.round(r)
        let rs = Darwin.round(s)

        let qDiff = abs(rq - q)
        let rDiff = abs(rr - r)
        let sDiff = abs(rs - s)

        if qDiff > rDiff && qDiff > sDiff {
            rq = -rr - rs
        } else if rDiff > sDiff {
            rr = -rq - rs
        }

        return HexCoordinate(q: Int(rq), r: Int(rr))
    }

    // MARK: - Operators

    static func + (lhs: HexCoordinate, rhs: HexCoordinate) -> HexCoordinate {
        return HexCoordinate(q: lhs.q + rhs.q, r: lhs.r + rhs.r)
    }

    static func - (lhs: HexCoordinate, rhs: HexCoordinate) -> HexCoordinate {
        return HexCoordinate(q: lhs.q - rhs.q, r: lhs.r - rhs.r)
    }

    // MARK: - Description

    var description: String {
        return "(\(q), \(r), \(s))"
    }
}

// MARK: - Hex Grid

/// Represents the combat hex grid
class HexGrid: ObservableObject {
    let width: Int   // Number of columns
    let height: Int  // Number of rows

    /// Layout configuration
    let hexSize: CGFloat  // Size of each hex (center to corner)
    let orientation: HexOrientation

    /// Grid data
    @Published var tiles: [HexCoordinate: HexTile]

    /// Currently highlighted hexes (for movement range, etc.)
    @Published var highlightedHexes: Set<HexCoordinate> = []
    @Published var highlightColor: Color = .blue.opacity(0.3)

    /// Selected hex
    @Published var selectedHex: HexCoordinate?

    /// Path being displayed
    @Published var currentPath: [HexCoordinate] = []

    init(width: Int = 10, height: Int = 12, hexSize: CGFloat = 40, orientation: HexOrientation = .pointyTop) {
        self.width = width
        self.height = height
        self.hexSize = hexSize
        self.orientation = orientation
        self.tiles = [:]

        // Initialize all tiles
        for col in 0..<width {
            for row in 0..<height {
                let coord = HexCoordinate(col: col, row: row)
                tiles[coord] = HexTile(coordinate: coord)
            }
        }
    }

    /// Check if coordinate is within grid bounds
    func isValidCoordinate(_ coord: HexCoordinate) -> Bool {
        let (col, row) = coord.offsetCoordinates
        return col >= 0 && col < width && row >= 0 && row < height
    }

    /// Get tile at coordinate
    func tile(at coord: HexCoordinate) -> HexTile? {
        return tiles[coord]
    }

    /// Convert hex coordinate to screen position
    func hexToPixel(_ coord: HexCoordinate) -> CGPoint {
        let (col, row) = coord.offsetCoordinates

        switch orientation {
        case .pointyTop:
            let x = hexSize * sqrt(3) * (Double(col) + 0.5 * Double(row & 1))
            let y = hexSize * 3/2 * Double(row)
            return CGPoint(x: x + hexSize, y: y + hexSize)

        case .flatTop:
            let x = hexSize * 3/2 * Double(col)
            let y = hexSize * sqrt(3) * (Double(row) + 0.5 * Double(col & 1))
            return CGPoint(x: x + hexSize, y: y + hexSize)
        }
    }

    /// Convert screen position to hex coordinate
    func pixelToHex(_ point: CGPoint) -> HexCoordinate {
        let adjustedX = point.x - hexSize
        let adjustedY = point.y - hexSize

        switch orientation {
        case .pointyTop:
            let q = (sqrt(3)/3 * adjustedX - 1/3 * adjustedY) / hexSize
            let r = (2/3 * adjustedY) / hexSize
            return HexCoordinate.round(q: q, r: r)

        case .flatTop:
            let q = (2/3 * adjustedX) / hexSize
            let r = (-1/3 * adjustedX + sqrt(3)/3 * adjustedY) / hexSize
            return HexCoordinate.round(q: q, r: r)
        }
    }

    /// Get total grid size in pixels
    var gridSize: CGSize {
        switch orientation {
        case .pointyTop:
            let w = hexSize * sqrt(3) * Double(width) + hexSize
            let h = hexSize * 3/2 * Double(height) + hexSize
            return CGSize(width: w, height: h)

        case .flatTop:
            let w = hexSize * 3/2 * Double(width) + hexSize
            let h = hexSize * sqrt(3) * Double(height) + hexSize
            return CGSize(width: w, height: h)
        }
    }

    /// Get corner points for drawing a hex
    func hexCorners(at coord: HexCoordinate) -> [CGPoint] {
        let center = hexToPixel(coord)
        var corners: [CGPoint] = []

        for i in 0..<6 {
            let angle: Double
            switch orientation {
            case .pointyTop:
                angle = Double.pi / 180 * (60 * Double(i) - 30)
            case .flatTop:
                angle = Double.pi / 180 * (60 * Double(i))
            }
            let x = center.x + hexSize * cos(angle)
            let y = center.y + hexSize * sin(angle)
            corners.append(CGPoint(x: x, y: y))
        }

        return corners
    }

    // MARK: - Movement & Pathfinding

    /// Get all hexes reachable within movement range
    func reachableHexes(from start: HexCoordinate, movement: Int, blockedHexes: Set<HexCoordinate>) -> Set<HexCoordinate> {
        var visited: Set<HexCoordinate> = [start]
        var frontier: [(HexCoordinate, Int)] = [(start, 0)]

        while !frontier.isEmpty {
            let (current, cost) = frontier.removeFirst()

            for neighbor in current.neighbors {
                guard isValidCoordinate(neighbor) else { continue }
                guard !visited.contains(neighbor) else { continue }
                guard !blockedHexes.contains(neighbor) else { continue }

                let tile = self.tile(at: neighbor)
                let moveCost = tile?.movementCost ?? 1

                if cost + moveCost <= movement {
                    visited.insert(neighbor)
                    frontier.append((neighbor, cost + moveCost))
                }
            }
        }

        return visited
    }

    /// Highlight hexes for movement range
    func highlightMovementRange(from start: HexCoordinate, movement: Int, blockedHexes: Set<HexCoordinate>) {
        highlightedHexes = reachableHexes(from: start, movement: movement, blockedHexes: blockedHexes)
        highlightColor = .blue.opacity(0.3)
    }

    /// Highlight hexes for attack range
    func highlightAttackRange(from start: HexCoordinate, range: Int) {
        highlightedHexes = Set(start.hexesInRange(range).filter { isValidCoordinate($0) && $0 != start })
        highlightColor = .red.opacity(0.3)
    }

    /// Clear all highlights
    func clearHighlights() {
        highlightedHexes.removeAll()
        currentPath.removeAll()
        selectedHex = nil
    }
}

/// Hex orientation type
enum HexOrientation {
    case pointyTop  // Pointy side faces up
    case flatTop    // Flat side faces up
}

/// Represents a single tile in the hex grid
struct HexTile: Identifiable {
    let id: UUID
    let coordinate: HexCoordinate
    var terrain: TerrainType
    var isBlocked: Bool
    var occupant: UUID?  // Character ID occupying this tile

    var movementCost: Int {
        terrain.movementCost
    }

    init(coordinate: HexCoordinate, terrain: TerrainType = .ground) {
        self.id = UUID()
        self.coordinate = coordinate
        self.terrain = terrain
        self.isBlocked = terrain == .wall
        self.occupant = nil
    }
}

/// Terrain types that affect movement and combat
enum TerrainType: String, Codable {
    case ground = "Ground"          // Normal terrain
    case water = "Water"            // Difficult terrain, 2x move cost
    case forest = "Forest"          // Cover (+2 AC), 2x move cost
    case wall = "Wall"              // Impassable
    case pit = "Pit"                // Hazard, fall damage
    case lava = "Lava"              // Hazard, fire damage

    var movementCost: Int {
        switch self {
        case .ground: return 1
        case .water, .forest: return 2
        case .wall, .pit, .lava: return 999  // Impassable
        }
    }

    var providesHalfCover: Bool {
        return self == .forest
    }

    var color: Color {
        switch self {
        case .ground: return Color(red: 0.85, green: 0.75, blue: 0.55)  // Parchment
        case .water: return .blue.opacity(0.5)
        case .forest: return .green.opacity(0.5)
        case .wall: return .gray
        case .pit: return .black.opacity(0.7)
        case .lava: return .orange
        }
    }
}
