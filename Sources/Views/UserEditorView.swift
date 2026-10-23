import SwiftUI
import SwiftData

struct UserEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let user: UserProfile?

    @State private var name: String
    @State private var age: String
    @State private var height: String
    @State private var gender: Gender

    init(user: UserProfile?) {
        self.user = user
        _name = State(initialValue: user?.name ?? "")
        _age = State(initialValue: user?.age.map(String.init) ?? "")
        _height = State(initialValue: user?.heightCm.map { String(format: "%.0f", $0) } ?? "")
        _gender = State(initialValue: user?.gender ?? .male)
    }

    var body: some View {
        Form {
            Section("Имя") {
                TextField("Имя", text: $name)
            }

            Section("Параметры") {
                TextField("Возраст", text: $age)
                    .keyboardType(.numberPad)
                TextField("Рост (см)", text: $height)
                    .keyboardType(.decimalPad)
                Picker("Пол", selection: $gender) {
                    ForEach(Gender.allCases) { g in
                        Text(g.title).tag(g)
                    }
                }
            }
        }
        .navigationTitle(user == nil ? "Новый профиль" : "Профиль")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let user {
            user.name = trimmed
            user.age = Int(age)
            user.heightCm = Double(height.replacingOccurrences(of: ",", with: "."))
            user.gender = gender
        } else {
            let profile = UserProfile(
                name: trimmed,
                age: Int(age),
                heightCm: Double(height.replacingOccurrences(of: ",", with: ".")),
                gender: gender
            )
            context.insert(profile)
        }
        try? context.save()
        dismiss()
    }
}
