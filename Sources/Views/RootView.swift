import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ScaleView()
                .tabItem { Label("Весы", systemImage: "scalemass") }
            HistoryView()
                .tabItem { Label("История", systemImage: "chart.line.uptrend.xyaxis") }
            UsersView()
                .tabItem { Label("Профили", systemImage: "person.2") }
        }
    }
}
