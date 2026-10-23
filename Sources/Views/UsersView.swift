import SwiftUI
import SwiftData

struct UsersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UserProfile.name) private var users: [UserProfile]

    var body: some View {
        NavigationStack {
            List {
                ForEach(users) { user in
                    NavigationLink {
                        UserEditorView(user: user)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.headline)
                            Text(subtitle(for: user))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Профили")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        UserEditorView(user: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func subtitle(for user: UserProfile) -> String {
        var parts: [String] = [user.gender.title]
        if let age = user.age { parts.append("\(age) лет") }
        if let height = user.heightCm { parts.append(String(format: "%.0f см", height)) }
        return parts.joined(separator: " · ")
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(users[index])
        }
    }
}
