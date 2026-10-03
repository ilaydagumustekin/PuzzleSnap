import SwiftUI

struct CollectionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: CompletedPuzzle?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 16) {
                HStack {
                    CircleButton(systemImage: "chevron.left") { dismiss() }
                    Spacer()
                    Text("Koleksiyon")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                if store.progress.completed.isEmpty {
                    Spacer()
                    ContentUnavailableView("Henüz resim yok", systemImage: "photo.on.rectangle.angled",
                                           description: Text("Tamamladığın bulmacalar burada toplanır."))
                        .foregroundStyle(.white)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.progress.completed.reversed()) { item in
                                if let photo = item.photo {
                                    Button { selected = item } label: {
                                        PhotoThumbnail(photo: photo, width: 300)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden()
        .sheet(item: $selected) { item in
            VStack(spacing: 16) {
                if let photo = item.photo {
                    PhotoThumbnail(photo: photo)
                    Text(photo.title).font(.title2.bold())
                }
                Text("\(item.title) · \(item.moves) hamle · \(item.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .presentationDetents([.large])
        }
    }
}
