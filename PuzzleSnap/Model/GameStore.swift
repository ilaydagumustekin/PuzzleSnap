import Foundation
import Observation

struct CompletedPuzzle: Codable, Hashable, Identifiable {
    var photoID: Int
    var title: String
    var moves: Int
    var date: Date

    var id: Int { photoID }
    var photo: Photo? { PhotoLibrary.photo(id: photoID) }
}

/// Player progress, persisted as JSON in `UserDefaults`.
@MainActor
@Observable
final class GameStore {
    struct Progress: Codable {
        var level = 1
        var masterLevel = 1
        var hints = 3
        var completed: [CompletedPuzzle] = []
        var dailyDone: Set<String> = []
        /// In-progress boards keyed by `PuzzleMode.key`, so leaving mid-puzzle never loses work.
        var saved: [String: PuzzleBoard] = [:]
    }

    static let hintsPerWin = 1

    private(set) var progress: Progress
    private let defaults: UserDefaults
    private let storageKey = "PuzzleSnap.progress.v2"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Progress.self, from: data) {
            progress = decoded
        } else {
            progress = Progress()
        }
    }

    var currentLevel: PuzzleMode { .level(progress.level) }
    var currentMaster: PuzzleMode { .master(progress.masterLevel) }
    var hints: Int { progress.hints }

    func isDailyDone(_ mode: PuzzleMode) -> Bool {
        if case .daily(let day) = mode { return progress.dailyDone.contains(day) }
        return false
    }

    func savedBoard(for mode: PuzzleMode) -> PuzzleBoard? {
        guard let board = progress.saved[mode.key], board.rows == mode.rows, board.cols == mode.cols else { return nil }
        return board
    }

    func save(_ board: PuzzleBoard, for mode: PuzzleMode) {
        progress.saved[mode.key] = board
        persist()
    }

    func discardSave(for mode: PuzzleMode) {
        progress.saved[mode.key] = nil
        persist()
    }

    func spendHint() -> Bool {
        guard progress.hints > 0 else { return false }
        progress.hints -= 1
        persist()
        return true
    }

    func recordWin(_ mode: PuzzleMode, moves: Int) {
        progress.saved[mode.key] = nil
        progress.hints += Self.hintsPerWin
        switch mode {
        case .level(let n): progress.level = max(progress.level, n + 1)
        case .master(let n): progress.masterLevel = max(progress.masterLevel, n + 1)
        case .daily(let day): progress.dailyDone.insert(day)
        }
        if !progress.completed.contains(where: { $0.photoID == mode.photo.id }) {
            progress.completed.append(CompletedPuzzle(photoID: mode.photo.id, title: mode.title, moves: moves, date: .now))
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
