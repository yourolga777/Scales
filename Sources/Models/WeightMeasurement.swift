import Foundation
import SwiftData

@Model
final class WeightMeasurement {
    var id: UUID
    var date: Date
    var weightKg: Double
    var impedanceOhm: Double?
    var user: UserProfile?

    init(weightKg: Double, impedanceOhm: Double? = nil, date: Date = Date(), user: UserProfile? = nil) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.impedanceOhm = impedanceOhm
        self.user = user
    }
}
