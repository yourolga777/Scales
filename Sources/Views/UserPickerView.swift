import SwiftUI
import SwiftData

struct UserPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUserId: String
    let users: [UserProfile]

    var body: some View {
        NavigationStack {
            List {
                ForEach(users) { user in
                    Button {
                        selectedUserId = user.id.uuidString
                        dismiss()
                    } label: {
                        HStack {
                            Text(user.name)
                            Spacer()
                            if user.id.uuidString == selectedUserId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выбор профиля")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}
