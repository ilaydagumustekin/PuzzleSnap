import Foundation

struct GridPos: Hashable, Codable {
    var row: Int
    var col: Int

    static let zero = GridPos(row: 0, col: 0)
    static func + (l: GridPos, r: GridPos) -> GridPos { GridPos(row: l.row + r.row, col: l.col + r.col) }
    static func - (l: GridPos, r: GridPos) -> GridPos { GridPos(row: l.row - r.row, col: l.col - r.col) }
}

/// The puzzle state: a grid of slots, each holding one tile of the picture.
///
/// A tile's id is the index of the slot it belongs in, so the board is solved when `slots[i] == i`
/// everywhere. Two neighbouring tiles are *joined* when they sit in the same relative arrangement as
/// in the picture; joined tiles form a group that moves as one.
struct PuzzleBoard: Codable, Equatable {
    let rows: Int
    let cols: Int
    /// `slots[i]` is the id of the tile currently in slot `i`.
    private(set) var slots: [Int]
    private(set) var moves = 0

    init(rows: Int, cols: Int, slots: [Int]) {
        precondition(slots.count == rows * cols && Set(slots) == Set(0..<rows * cols))
        self.rows = rows
        self.cols = cols
        self.slots = slots
    }

    /// A random arrangement with as few tiles home or already joined as possible.
    static func shuffled<G: RandomNumberGenerator>(rows: Int, cols: Int, using rng: inout G) -> PuzzleBoard {
        let ids = Array(0..<rows * cols)
        var best = PuzzleBoard(rows: rows, cols: cols, slots: ids.shuffled(using: &rng))
        var bestPenalty = best.correctCount + best.joinCount
        for _ in 0..<500 where bestPenalty > 0 {
            let candidate = PuzzleBoard(rows: rows, cols: cols, slots: ids.shuffled(using: &rng))
            let penalty = candidate.correctCount + candidate.joinCount
            if penalty < bestPenalty {
                best = candidate
                bestPenalty = penalty
            }
        }
        return best
    }

    var count: Int { rows * cols }

    func index(of p: GridPos) -> Int { p.row * cols + p.col }
    func pos(of index: Int) -> GridPos { GridPos(row: index / cols, col: index % cols) }
    func contains(_ p: GridPos) -> Bool { p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols }
    func tile(at p: GridPos) -> Int { slots[index(of: p)] }

    /// Where each tile currently sits, indexed by tile id.
    var tilePositions: [GridPos] {
        var result = Array(repeating: GridPos.zero, count: count)
        for (i, tile) in slots.enumerated() { result[tile] = pos(of: i) }
        return result
    }

    var isSolved: Bool { slots.indices.allSatisfy { slots[$0] == $0 } }
    var correctCount: Int { slots.indices.filter { slots[$0] == $0 }.count }

    /// Whether the tiles in two adjacent slots are in their picture-relative arrangement.
    func isJoined(_ a: GridPos, _ b: GridPos) -> Bool {
        guard contains(a), contains(b) else { return false }
        return pos(of: tile(at: b)) - pos(of: tile(at: a)) == b - a
    }

    /// Joined neighbour pairs, as tile-id pairs `(smaller, larger)` encoded into one Int.
    var joinedPairs: Set<Int> {
        var pairs = Set<Int>()
        for i in 0..<count {
            let p = pos(of: i)
            for n in [p + GridPos(row: 0, col: 1), p + GridPos(row: 1, col: 0)] where isJoined(p, n) {
                let a = slots[i], b = tile(at: n)
                pairs.insert(min(a, b) * count + max(a, b))
            }
        }
        return pairs
    }

    var joinCount: Int { joinedPairs.count }

    static let directions = [GridPos(row: -1, col: 0), GridPos(row: 1, col: 0), GridPos(row: 0, col: -1), GridPos(row: 0, col: 1)]

    /// All slots in the group of joined tiles that includes `p`.
    func group(containing p: GridPos) -> [GridPos] {
        var seen: Set<GridPos> = [p]
        var stack = [p]
        while let cur = stack.popLast() {
            for d in Self.directions {
                let n = cur + d
                if !seen.contains(n), isJoined(cur, n) {
                    seen.insert(n)
                    stack.append(n)
                }
            }
        }
        return Array(seen)
    }

    func groups() -> [[GridPos]] {
        var seen = Set<GridPos>()
        var result: [[GridPos]] = []
        for i in 0..<count where !seen.contains(pos(of: i)) {
            let g = group(containing: pos(of: i))
            seen.formUnion(g)
            result.append(g)
        }
        return result
    }

    /// The furthest shifts, up/left and down/right, that keep every slot of `group` on the board.
    func moveRange(of group: [GridPos]) -> (min: GridPos, max: GridPos) {
        guard !group.isEmpty else { return (.zero, .zero) }
        let rowsUsed = group.map(\.row), colsUsed = group.map(\.col)
        return (GridPos(row: -rowsUsed.min()!, col: -colsUsed.min()!),
                GridPos(row: rows - 1 - rowsUsed.max()!, col: cols - 1 - colsUsed.max()!))
    }

    /// `d` pulled back onto the board, so overshooting an edge lands on the edge instead of failing.
    func clamp(_ d: GridPos, for group: [GridPos]) -> GridPos {
        let range = moveRange(of: group)
        return GridPos(row: min(max(d.row, range.min.row), range.max.row),
                       col: min(max(d.col, range.min.col), range.max.col))
    }

    func canMove(_ group: [GridPos], by d: GridPos) -> Bool {
        d != .zero && !group.isEmpty && group.allSatisfy { contains($0 + d) }
    }

    /// Slides `group` by `d`. Tiles it lands on flow back into the slots it vacated, keeping their
    /// own order along the direction of travel.
    @discardableResult
    mutating func move(_ group: [GridPos], by d: GridPos) -> Bool {
        guard canMove(group, by: d) else { return false }
        let source = Set(group)
        let target = Set(group.map { $0 + d })
        var next = slots
        for s in group {
            next[index(of: s + d)] = slots[index(of: s)]
        }
        for t in target where !source.contains(t) {
            // Walking back from a displaced tile always stays inside `source` and ends in a slot that
            // the group left empty; each such chain is disjoint, so every gap is filled exactly once.
            var free = t - d
            while target.contains(free) { free = free - d }
            next[index(of: free)] = slots[index(of: t)]
        }
        slots = next
        moves += 1
        return true
    }
}

/// Deterministic RNG (SplitMix64) so a seed always yields the same picture and daily shuffle.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
