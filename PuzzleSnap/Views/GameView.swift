import SwiftUI

struct GameView: View {
    let mode: PuzzleMode

    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Built on appear rather than in `init`, so parent re-renders don't regenerate the puzzle.
    @State private var game: GameViewModel?
    @State private var showWin = false
    @State private var peeking = false
    @State private var confirmRestart = false

    var body: some View {
        ZStack {
            AppBackground()
            if let game {
                content(game)
            } else {
                ProgressView().tint(.white)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if game == nil { game = GameViewModel(mode: mode, store: store) }
        }
    }

    private func content(_ game: GameViewModel) -> some View {
        VStack(spacing: 14) {
            header(game)
            ProgressView(value: game.progress)
                .tint(Palette.accent)
                .animation(.easeOut, value: game.progress)
            BoardView(game: game)
                .overlay {
                    if peeking {
                        Image(uiImage: game.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.opacity)
                    }
                }
            footer(game)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .overlay {
            if showWin {
                WinOverlay(game: game, onNext: { next(after: game) }, onHome: { dismiss() })
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onChange(of: game.isWon) { _, won in
            guard won else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.spring) { showWin = true }
            }
        }
        .confirmationDialog("Bulmacayı yeniden karıştır?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Yeniden Başlat", role: .destructive) {
                withAnimation(.spring) { game.restart() }
            }
        }
    }

    private func header(_ game: GameViewModel) -> some View {
        HStack {
            CircleButton(systemImage: "chevron.left") { dismiss() }
            Spacer()
            VStack(spacing: 2) {
                Text(game.mode.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Text("\(game.moves) hamle · \(game.mode.rows)×\(game.mode.cols)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            Spacer()
            CircleButton(systemImage: "arrow.triangle.2.circlepath") { confirmRestart = true }
                .disabled(game.isWon)
        }
    }

    private func footer(_ game: GameViewModel) -> some View {
        HStack(spacing: 14) {
            // Hold to see the finished picture.
            PillLabel(title: "Önizle", systemImage: "eye.fill")
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !peeking { withAnimation(.easeOut(duration: 0.15)) { peeking = true } } }
                        .onEnded { _ in withAnimation(.easeOut(duration: 0.2)) { peeking = false } }
                )
            PillButton(title: "İpucu (\(store.hints))", systemImage: "lightbulb.fill") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { game.useHint() }
            }
            .disabled(store.hints == 0 || game.isWon)
            .opacity(store.hints == 0 ? 0.5 : 1)
        }
    }

    private func next(after game: GameViewModel) {
        guard let next = game.mode.next else {
            dismiss()
            return
        }
        withAnimation(.easeInOut) {
            showWin = false
            self.game = GameViewModel(mode: next, store: store)
        }
    }
}

struct WinOverlay: View {
    let game: GameViewModel
    let onNext: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 18) {
                Text("Tebrikler!")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                Image(uiImage: game.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 10)
                Text(game.mode.photo.title)
                    .font(.headline)
                Text("\(game.moves) hamlede tamamladın · +\(GameStore.hintsPerWin) ipucu")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                if game.mode.next != nil {
                    Button(action: onNext) {
                        Label("Sonraki Bulmaca", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Button("Ana Menü", action: onHome)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .padding(24)
            .background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 28))
            .environment(\.colorScheme, .dark)
            .padding(28)
        }
    }
}
