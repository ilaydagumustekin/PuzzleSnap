import SwiftUI
import UIKit

@MainActor
@Observable
final class GameViewModel {
    let mode: PuzzleMode
    let image: UIImage
    /// Tile images indexed by tile id.
    let tileImages: [UIImage]

    private(set) var board: PuzzleBoard
    private(set) var isWon = false

    /// Tiles being dragged and how far the finger has moved.
    private(set) var draggingTiles: Set<Int> = []
    private(set) var dragOffset: CGSize = .zero
    /// Tiles that just snapped together, briefly highlighted.
    private(set) var flashingTiles: Set<Int> = []

    private var dragGroup: [GridPos] = []
    private var dragTileSize = CGSize(width: 1, height: 1)
    private let store: GameStore
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notify = UINotificationFeedbackGenerator()

    init(mode: PuzzleMode, store: GameStore) {
        self.mode = mode
        self.store = store
        image = PhotoLibrary.image(for: mode.photo)
        tileImages = Self.slice(image, rows: mode.rows, cols: mode.cols)
        board = store.savedBoard(for: mode) ?? Self.freshBoard(for: mode)
    }

    var moves: Int { board.moves }
    var progress: Double { Double(board.correctCount) / Double(board.count) }

    func beginDrag(at pos: GridPos, tileSize: CGSize) {
        guard !isWon, board.contains(pos) else { return }
        dragGroup = board.group(containing: pos)
        draggingTiles = Set(dragGroup.map { board.tile(at: $0) })
        dragTileSize = tileSize
        impact.prepare()
    }

    /// Follows the finger, but never lets the group leave the board.
    func updateDrag(_ translation: CGSize) {
        guard !dragGroup.isEmpty else { return }
        let range = board.moveRange(of: dragGroup)
        dragOffset = CGSize(
            width: min(max(translation.width, CGFloat(range.min.col) * dragTileSize.width), CGFloat(range.max.col) * dragTileSize.width),
            height: min(max(translation.height, CGFloat(range.min.row) * dragTileSize.height), CGFloat(range.max.row) * dragTileSize.height)
        )
    }

    /// Drops the dragged group on the slots nearest to where it is drawn.
    func endDrag() {
        guard !dragGroup.isEmpty else { return }
        let delta = GridPos(row: Int((dragOffset.height / dragTileSize.height).rounded()),
                            col: Int((dragOffset.width / dragTileSize.width).rounded()))
        let group = dragGroup
        cancelDrag()
        apply(group, by: board.clamp(delta, for: group))
    }

    /// Returns the dragged group to its slots; also used when the system interrupts a drag.
    func cancelDrag() {
        dragGroup = []
        draggingTiles = []
        dragOffset = .zero
    }

    /// Sends the biggest misplaced group straight home.
    func useHint() {
        guard !isWon else { return }
        let misplaced = board.groups().filter { g in g.contains { board.tile(at: $0) != board.index(of: $0) } }
        guard let group = misplaced.max(by: { $0.count < $1.count }), store.spendHint() else { return }
        let first = group[0]
        let delta = board.pos(of: board.tile(at: first)) - first
        apply(group, by: delta)
    }

    func restart() {
        board = Self.freshBoard(for: mode)
        isWon = false
        store.discardSave(for: mode)
    }

    private func apply(_ group: [GridPos], by delta: GridPos) {
        let before = board.joinedPairs
        guard board.move(group, by: delta) else { return }
        let newPairs = board.joinedPairs.subtracting(before)

        if board.isSolved {
            isWon = true
            store.recordWin(mode, moves: board.moves)
            notify.notificationOccurred(.success)
        } else {
            store.save(board, for: mode)
            if !newPairs.isEmpty { impact.impactOccurred() }
        }

        guard !newPairs.isEmpty else { return }
        let n = board.count
        let snapped = Set(newPairs.flatMap { [$0 / n, $0 % n] })
        flashingTiles = snapped
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.easeOut(duration: 0.3)) { self?.flashingTiles.subtract(snapped) }
        }
    }

    private static func freshBoard(for mode: PuzzleMode) -> PuzzleBoard {
        if let seed = mode.shuffleSeed {
            var rng = SeededRandom(seed: seed)
            return .shuffled(rows: mode.rows, cols: mode.cols, using: &rng)
        }
        var rng = SystemRandomNumberGenerator()
        return .shuffled(rows: mode.rows, cols: mode.cols, using: &rng)
    }

    private static func slice(_ image: UIImage, rows: Int, cols: Int) -> [UIImage] {
        guard let cg = image.cgImage else { return [] }
        let w = CGFloat(cg.width) / CGFloat(cols)
        let h = CGFloat(cg.height) / CGFloat(rows)
        var tiles: [UIImage] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let x0 = (CGFloat(c) * w).rounded(), x1 = (CGFloat(c + 1) * w).rounded()
                let y0 = (CGFloat(r) * h).rounded(), y1 = (CGFloat(r + 1) * h).rounded()
                let rect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
                tiles.append(cg.cropping(to: rect).map { UIImage(cgImage: $0) } ?? UIImage())
            }
        }
        return tiles
    }
}
