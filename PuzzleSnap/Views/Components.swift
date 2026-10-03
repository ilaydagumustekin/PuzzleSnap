import SwiftUI

enum Palette {
    static let top = Color(red: 0.11, green: 0.16, blue: 0.33)
    static let bottom = Color(red: 0.05, green: 0.36, blue: 0.42)
    static let accent = Color(red: 1.0, green: 0.72, blue: 0.27)
    static let card = Color.white.opacity(0.12)
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(colors: [Palette.top, Palette.bottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct CircleButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Palette.card, in: Circle())
        }
    }
}

struct PillLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.card, in: Capsule())
            .contentShape(Capsule())
    }
}

struct PillButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { PillLabel(title: title, systemImage: systemImage) }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(Color(red: 0.25, green: 0.15, blue: 0.0))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Palette.accent, in: Capsule())
            .shadow(color: Palette.accent.opacity(0.4), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ConfettiView: View {
    private struct Piece {
        let x: CGFloat
        let delay: Double
        let speed: CGFloat
        let drift: CGFloat
        let spin: Double
        let size: CGSize
        let color: Color
    }

    @State private var start = Date.now
    @State private var pieces: [Piece] = (0..<120).map { _ in
        Piece(x: .random(in: 0...1), delay: .random(in: 0...0.8), speed: .random(in: 180...420),
              drift: .random(in: -60...60), spin: .random(in: 2...8),
              size: CGSize(width: .random(in: 6...11), height: .random(in: 10...18)),
              color: [.yellow, .pink, .mint, .orange, .cyan, .purple, .red].randomElement()!)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                for p in pieces {
                    let life = t - p.delay
                    guard life > 0 else { continue }
                    let y = -20 + p.speed * life + 60 * life * life
                    guard y < size.height + 30 else { continue }
                    let x = p.x * size.width + sin(life * 2 + p.x * 10) * p.drift
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(life * p.spin))
                    c.fill(Path(CGRect(origin: CGPoint(x: -p.size.width / 2, y: -p.size.height / 2), size: p.size)), with: .color(p.color))
                }
            }
        }
    }
}
