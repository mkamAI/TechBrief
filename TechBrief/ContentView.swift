import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SearchView()
        }
        .tint(Color.accent)
    }
}

#Preview {
    ContentView()
        .environment(StoreManager())
}
