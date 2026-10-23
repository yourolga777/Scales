import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int?
    var heightCm: Double?
    var gender: Gender
    var createdAt: Date

    init(name: String, age: Int? = nil, heightCm: Double? = nil, gender: Gender = .male) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.gender = gender
        self.createdAt = Date()
    }
}
