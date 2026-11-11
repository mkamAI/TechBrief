import SwiftUI

@main
struct TechBriefApp: App {
    @State private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
