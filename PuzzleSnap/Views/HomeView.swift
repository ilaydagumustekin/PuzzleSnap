import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var showCollection = false
    /// Games run full screen rather than pushed, so no navigation swipe-back can steal tile drags.
    @State private var playing: PuzzleMode?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        levelCard
                        HStack(spacing: 14) {
                            dailyCard
                            masterCard
                        }
                        collectionButton
                    }
                    .padding(16)
                }
            }
            .navigationDestination(isPresented: $showCollection) { CollectionView() }
        }
        .fullScreenCover(item: $playing) { mode in
            GameView(mode: mode)
        }
    }

    private var header: some View {
        HStack {
            Text("PuzzleSnap")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Label("\(store.hints)", systemImage: "lightbulb.fill")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.card, in: Capsule())
        }
        .padding(.top, 8)
    }

    private var levelCard: some View {
        let mode = store.currentLevel
        return VStack(spacing: 16) {
            PhotoThumbnail(photo: mode.photo, width: 600)
                .frame(maxHeight: 360)
                .overlay(alignment: .topLeading) {
                    if store.savedBoard(for: mode) != nil {
                        Text("Devam ediyor")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.5), in: Capsule())
                            .foregroundStyle(.white)
                            .padding(10)
                    }
                }
            Button {
                playing = mode
            } label: {
                Label("\(mode.title) · Oyna", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 26))
    }

    private var dailyCard: some View {
        let mode = PuzzleMode.today()
        let done = store.isDailyDone(mode)
        return ModeCard(title: "Günlük", subtitle: done ? "Tamamlandı ✓" : "Bugünün bulmacası",
                        systemImage: "calendar", tint: .pink) {
            playing = mode
        }
    }

    private var masterCard: some View {
        ModeCard(title: "Usta", subtitle: "Seviye \(store.progress.masterLevel) · zor",
                 systemImage: "crown.fill", tint: .purple) {
            playing = store.currentMaster
        }
    }

    private var collectionButton: some View {
        Button {
            showCollection = true
        } label: {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                Text("Koleksiyon")
                Spacer()
                Text("\(store.progress.completed.count)")
                    .foregroundStyle(.white.opacity(0.7))
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .padding(18)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct ModeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 14))
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22))
        }
    }
}

struct PhotoThumbnail: View {
    let photo: Photo
    var width: CGFloat?

    var body: some View {
        Image(uiImage: PhotoLibrary.image(for: photo, width: width))
            .resizable()
            .aspectRatio(PhotoLibrary.aspect, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
