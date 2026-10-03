import Foundation

enum PuzzleMode: Codable, Hashable, Identifiable {
    case level(Int)
    case master(Int)
    /// `yyyy-MM-dd` in the player's time zone.
    case daily(String)

    var id: String { key }

    var key: String {
        switch self {
        case .level(let n): "level-\(n)"
        case .master(let n): "master-\(n)"
        case .daily(let day): "daily-\(day)"
        }
    }

    var rows: Int { grid.rows }
    var cols: Int { grid.cols }

    private var grid: (rows: Int, cols: Int) {
        switch self {
        case .level(let n):
            switch n {
            case ...2: (4, 3)
            case ...6: (5, 4)
            case ...12: (6, 4)
            case ...20: (6, 5)
            case ...35: (7, 5)
            default: (8, 6)
            }
        case .master(let n):
            n <= 10 ? (8, 6) : n <= 25 ? (9, 6) : (10, 7)
        case .daily:
            (6, 5)
        }
    }

    var photo: Photo {
        let photos = PhotoLibrary.all
        switch self {
        case .level(let n):
            return photos[(n - 1) % photos.count]
        case .master(let n):
            // Walk the list backwards so master puzzles start with pictures levels reach last.
            return photos[photos.count - 1 - (n - 1) % photos.count]
        case .daily(let day):
            return photos[Int(Self.stableHash(day) % UInt64(photos.count))]
        }
    }

    /// Daily puzzles shuffle the same way for everyone; the others differ on every play.
    var shuffleSeed: UInt64? {
        if case .daily(let day) = self { return Self.stableHash("shuffle-" + day) }
        return nil
    }

    var title: String {
        switch self {
        case .level(let n): "Seviye \(n)"
        case .master(let n): "Usta \(n)"
        case .daily(let day): "Günlük · \(Self.displayDate(day))"
        }
    }

    var next: PuzzleMode? {
        switch self {
        case .level(let n): .level(n + 1)
        case .master(let n): .master(n + 1)
        case .daily: nil
        }
    }

    static func today(_ date: Date = .now) -> PuzzleMode {
        .daily(dayFormatter.string(from: date))
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func displayDate(_ day: String) -> String {
        guard let date = dayFormatter.date(from: day) else { return day }
        return date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
    }

    /// FNV-1a; `String.hashValue` is randomised per launch, so it can't seed anything persistent.
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in s.utf8 {
            h ^= UInt64(byte)
            h &*= 0x100_0000_01B3
        }
        return h
    }
}
