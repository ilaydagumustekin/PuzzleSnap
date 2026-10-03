import XCTest
@testable import PuzzleSnap

final class PuzzleBoardTests: XCTestCase {
    private func isPermutation(_ b: PuzzleBoard) -> Bool { b.slots.sorted() == Array(0..<b.count) }

    func testSolvedBoardIsOneGroup() {
        let board = PuzzleBoard(rows: 3, cols: 3, slots: Array(0..<9))
        XCTAssertTrue(board.isSolved)
        XCTAssertEqual(board.groups().count, 1)
    }

    func testSingleTileMoveSwaps() {
        // 0 1 / 2 3 with 0 and 1 swapped.
        var board = PuzzleBoard(rows: 2, cols: 2, slots: [1, 0, 2, 3])
        XCTAssertTrue(board.move([GridPos(row: 0, col: 0)], by: GridPos(row: 0, col: 1)))
        XCTAssertEqual(board.slots, [0, 1, 2, 3])
        XCTAssertTrue(board.isSolved)
        XCTAssertEqual(board.moves, 1)
    }

    func testGroupMovesTogetherAndDisplacedTilesFillGap() {
        // Row of 4: tiles 2,3 joined at slots 0,1; slide them right by 2.
        var board = PuzzleBoard(rows: 1, cols: 4, slots: [2, 3, 0, 1])
        let group = board.group(containing: GridPos(row: 0, col: 0))
        XCTAssertEqual(Set(group), [GridPos(row: 0, col: 0), GridPos(row: 0, col: 1)])
        XCTAssertTrue(board.move(group, by: GridPos(row: 0, col: 2)))
        XCTAssertEqual(board.slots, [0, 1, 2, 3])
    }

    func testOverlappingShiftKeepsPermutation() {
        var board = PuzzleBoard(rows: 1, cols: 5, slots: [4, 0, 1, 2, 3])
        // 0,1,2,3 are joined at slots 1...4; shift left by one.
        let group = board.group(containing: GridPos(row: 0, col: 2))
        XCTAssertEqual(group.count, 4)
        XCTAssertTrue(board.move(group, by: GridPos(row: 0, col: -1)))
        XCTAssertEqual(board.slots, [0, 1, 2, 3, 4])
    }

    func testOutOfBoundsMoveIsRejected() {
        var board = PuzzleBoard(rows: 2, cols: 2, slots: [3, 2, 1, 0])
        XCTAssertFalse(board.move([GridPos(row: 0, col: 0)], by: GridPos(row: -1, col: 0)))
        XCTAssertFalse(board.move([GridPos(row: 0, col: 0)], by: .zero))
        XCTAssertEqual(board.moves, 0)
    }

    func testRandomMovesAlwaysKeepPermutation() {
        var rng = SeededRandom(seed: 42)
        var board = PuzzleBoard.shuffled(rows: 6, cols: 5, using: &rng)
        for _ in 0..<2000 {
            let start = GridPos(row: Int.random(in: 0..<6, using: &rng), col: Int.random(in: 0..<5, using: &rng))
            let delta = GridPos(row: Int.random(in: -3...3, using: &rng), col: Int.random(in: -3...3, using: &rng))
            board.move(board.group(containing: start), by: delta)
            XCTAssertTrue(isPermutation(board))
        }
    }

    func testShuffleHasNothingSolved() {
        var rng = SeededRandom(seed: 7)
        let board = PuzzleBoard.shuffled(rows: 5, cols: 4, using: &rng)
        XCTAssertEqual(board.correctCount, 0)
        XCTAssertEqual(board.joinCount, 0)
    }

    func testDailySeedIsStable() {
        XCTAssertEqual(PuzzleMode.daily("2026-10-03").photo, PuzzleMode.daily("2026-10-03").photo)
        XCTAssertNotEqual(PuzzleMode.stableHash("2026-10-03"), PuzzleMode.stableHash("2026-10-04"))
    }
}

extension PuzzleBoardTests {
    func testOvershootIsClampedToEdge() {
        let board = PuzzleBoard(rows: 2, cols: 4, slots: [0, 1, 2, 3, 4, 5, 6, 7])
        // Single tile in column 1 flung five columns left lands in column 0.
        XCTAssertEqual(board.clamp(GridPos(row: 0, col: -5), for: [GridPos(row: 0, col: 1)]), GridPos(row: 0, col: -1))
        // Two-wide group starting at column 0 can move at most two to the right.
        let group = [GridPos(row: 1, col: 0), GridPos(row: 1, col: 1)]
        XCTAssertEqual(board.clamp(GridPos(row: 3, col: 9), for: group), GridPos(row: 0, col: 2))
    }

    func testEveryPhotoIsBundled() {
        for photo in PhotoLibrary.all {
            XCTAssertGreaterThan(PhotoLibrary.image(for: photo).size.width, 0, "missing photo-\(photo.id).jpg")
        }
    }
}
