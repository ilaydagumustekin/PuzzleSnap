import SwiftUI

@main
struct PuzzleSnapApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}
