import Foundation

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "Мужской"
        case .female: return "Женский"
        }
    }
}
