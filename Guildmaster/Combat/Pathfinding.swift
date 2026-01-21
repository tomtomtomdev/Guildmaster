//
//  Pathfinding.swift
//  Guildmaster
//
//  A* pathfinding implementation for hex grids
//

import Foundation

/// A* pathfinding for hex grids
class HexPathfinder {

    /// Find the shortest path between two hexes
    /// - Parameters:
    ///   - start: Starting hex coordinate
    ///   - goal: Destination hex coordinate
    ///   - grid: The hex grid to pathfind on
    ///   - blockedHexes: Set of hexes that cannot be traversed
    ///   - maxCost: Maximum movement cost (optional)
    /// - Returns: Array of hex coordinates forming the path, or nil if no path exists
    static func findPath(
        from start: HexCoordinate,
        to goal: HexCoordinate,
        on grid: HexGrid,
        blockedHexes: Set<HexCoordinate> = [],
        maxCost: Int? = nil
    ) -> [HexCoordinate]? {

        // Priority queue using a simple array (could optimize with heap)
        var openSet: [PathNode] = [PathNode(coord: start, gCost: 0, hCost: start.distance(to: goal))]
        var closedSet: Set<HexCoordinate> = []
        var cameFrom: [HexCoordinate: HexCoordinate] = [:]
        var gCosts: [HexCoordinate: Int] = [start: 0]

        while !openSet.isEmpty {
            // Get node with lowest f-cost
            openSet.sort { $0.fCost < $1.fCost }
            let current = openSet.removeFirst()

            // Check if we've reached the goal
            if current.coord == goal {
                return reconstructPath(from: start, to: goal, cameFrom: cameFrom)
            }

            closedSet.insert(current.coord)

            // Examine neighbors
            for neighbor in current.coord.neighbors {
                // Skip invalid coordinates
                guard grid.isValidCoordinate(neighbor) else { continue }

                // Skip already evaluated nodes
                guard !closedSet.contains(neighbor) else { continue }

                // Skip blocked hexes
                guard !blockedHexes.contains(neighbor) else { continue }

                // Get movement cost for this tile
                let tile = grid.tile(at: neighbor)
                let moveCost = tile?.movementCost ?? 1

                // Skip impassable terrain
                guard moveCost < 100 else { continue }

                // Calculate tentative g-cost
                let tentativeG = current.gCost + moveCost

                // Check max cost limit
                if let max = maxCost, tentativeG > max {
                    continue
                }

                // Check if this is a better path
                let existingG = gCosts[neighbor] ?? Int.max
                if tentativeG < existingG {
                    // This path is better
                    cameFrom[neighbor] = current.coord
                    gCosts[neighbor] = tentativeG

                    let hCost = neighbor.distance(to: goal)
                    let newNode = PathNode(coord: neighbor, gCost: tentativeG, hCost: hCost)

                    // Add to open set if not already there
                    if !openSet.contains(where: { $0.coord == neighbor }) {
                        openSet.append(newNode)
                    } else {
                        // Update existing node
                        if let index = openSet.firstIndex(where: { $0.coord == neighbor }) {
                            openSet[index] = newNode
                        }
                    }
                }
            }
        }

        // No path found
        return nil
    }

    /// Reconstruct path from start to goal using came-from map
    private static func reconstructPath(
        from start: HexCoordinate,
        to goal: HexCoordinate,
        cameFrom: [HexCoordinate: HexCoordinate]
    ) -> [HexCoordinate] {
        var path: [HexCoordinate] = [goal]
        var current = goal

        while current != start {
            guard let previous = cameFrom[current] else { break }
            path.insert(previous, at: 0)
            current = previous
        }

        return path
    }

    /// Check if there is a valid path between two hexes
    static func hasPath(
        from start: HexCoordinate,
        to goal: HexCoordinate,
        on grid: HexGrid,
        blockedHexes: Set<HexCoordinate> = []
    ) -> Bool {
        return findPath(from: start, to: goal, on: grid, blockedHexes: blockedHexes) != nil
    }

    /// Get the movement cost of a path
    static func pathCost(
        _ path: [HexCoordinate],
        on grid: HexGrid
    ) -> Int {
        guard path.count > 1 else { return 0 }

        var cost = 0
        for coord in path.dropFirst() {
            let tile = grid.tile(at: coord)
            cost += tile?.movementCost ?? 1
        }
        return cost
    }

    /// Find all hexes reachable within a movement budget using Dijkstra's algorithm
    static func findReachableHexes(
        from start: HexCoordinate,
        movement: Int,
        on grid: HexGrid,
        blockedHexes: Set<HexCoordinate> = []
    ) -> [HexCoordinate: Int] {  // Returns hex -> cost to reach

        var costs: [HexCoordinate: Int] = [start: 0]
        var frontier: [(HexCoordinate, Int)] = [(start, 0)]

        while !frontier.isEmpty {
            // Sort by cost (simple priority queue)
            frontier.sort { $0.1 < $1.1 }
            let (current, currentCost) = frontier.removeFirst()

            for neighbor in current.neighbors {
                guard grid.isValidCoordinate(neighbor) else { continue }
                guard !blockedHexes.contains(neighbor) else { continue }

                let tile = grid.tile(at: neighbor)
                let moveCost = tile?.movementCost ?? 1

                guard moveCost < 100 else { continue }

                let newCost = currentCost + moveCost
                guard newCost <= movement else { continue }

                let existingCost = costs[neighbor] ?? Int.max
                if newCost < existingCost {
                    costs[neighbor] = newCost
                    frontier.append((neighbor, newCost))
                }
            }
        }

        return costs
    }
}

/// Node for A* pathfinding
private struct PathNode {
    let coord: HexCoordinate
    let gCost: Int  // Cost from start to this node
    let hCost: Int  // Heuristic cost from this node to goal

    var fCost: Int { gCost + hCost }
}

// MARK: - Line of Sight

extension HexPathfinder {

    /// Check if there is clear line of sight between two hexes
    static func hasLineOfSight(
        from start: HexCoordinate,
        to target: HexCoordinate,
        on grid: HexGrid,
        blockedHexes: Set<HexCoordinate> = []
    ) -> Bool {
        let line = start.line(to: target)

        // Check each hex in the line (excluding start and target)
        for hex in line.dropFirst().dropLast() {
            // Check if blocked by terrain
            if let tile = grid.tile(at: hex), tile.terrain == .wall {
                return false
            }

            // Check if blocked by another character (optional - depends on game rules)
            if blockedHexes.contains(hex) {
                return false
            }
        }

        return true
    }

    /// Get all hexes that can be seen from a position
    static func visibleHexes(
        from start: HexCoordinate,
        range: Int,
        on grid: HexGrid,
        blockedHexes: Set<HexCoordinate> = []
    ) -> Set<HexCoordinate> {
        var visible: Set<HexCoordinate> = [start]

        for hex in start.hexesInRange(range) {
            guard grid.isValidCoordinate(hex) else { continue }

            if hasLineOfSight(from: start, to: hex, on: grid, blockedHexes: blockedHexes) {
                visible.insert(hex)
            }
        }

        return visible
    }
}

// MARK: - Flanking Detection

extension HexPathfinder {

    /// Check if a target is being flanked (enemies on opposite sides)
    static func isFlanked(
        target: HexCoordinate,
        by attacker: HexCoordinate,
        allies: [HexCoordinate]
    ) -> Bool {
        // Get direction from target to attacker
        let attackerDirection = directionIndex(from: target, to: attacker)
        guard let attackerDir = attackerDirection else { return false }

        // Opposite direction is +3 (or -3) in hex coordinates
        let oppositeDir = (attackerDir + 3) % 6
        let oppositeHex = target.neighbor(direction: oppositeDir)

        // Check if any ally is in the opposite position
        return allies.contains(oppositeHex)
    }

    /// Get the direction index (0-5) from one hex to an adjacent hex
    private static func directionIndex(from: HexCoordinate, to: HexCoordinate) -> Int? {
        let diff = to - from
        return HexCoordinate.directions.firstIndex(of: diff)
    }

    /// Count enemies adjacent to a hex
    static func adjacentEnemyCount(
        to hex: HexCoordinate,
        enemies: [HexCoordinate]
    ) -> Int {
        return hex.neighbors.filter { enemies.contains($0) }.count
    }
}
