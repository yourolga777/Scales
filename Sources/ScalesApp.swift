import SwiftUI
import SwiftData

@main
struct ScalesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, WeightMeasurement.self])
    }
}
