import SwiftUI
import SwiftData

struct ScaleView: View {
    @StateObject private var scanner = ScaleScanner()
    @Environment(\.modelContext) private var context
    @Query(sort: \UserProfile.name) private var users: [UserProfile]
    @AppStorage("selectedUserId") private var selectedUserId = ""
    @State private var showUserPicker = false

    private var selectedUser: UserProfile? {
        users.first { $0.id.uuidString == selectedUserId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                if let reading = scanner.currentReading {
                    WeightDisplay(reading: reading)
                } else {
                    WeightPlaceholder()
                }

                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if users.isEmpty {
                    Text("Сначала создайте профиль на вкладке «Профили».")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button {
                    showUserPicker = true
                } label: {
                    Label(selectedUser?.name ?? "Выбрать профиль",
                          systemImage: "person.crop.circle")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Весы")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        scanner.state == .scanning ? scanner.stop() : scanner.start()
                    } label: {
                        Image(systemName: scanner.state == .scanning ? "pause.circle" : "play.circle")
                    }
                }
            }
        }
        .onAppear { scanner.start() }
        .onChange(of: scanner.stableEventCount) { _, _ in saveStableReading() }
        .sheet(isPresented: $showUserPicker) {
            UserPickerView(selectedUserId: $selectedUserId, users: users)
        }
    }

    private var statusText: String {
        switch scanner.state {
        case .idle: return "Ожидание"
        case .scanning: return "Сканирование… встаньте на весы"
        case .bluetoothOff: return "Bluetooth выключен"
        case .bluetoothUnavailable: return "Bluetooth недоступен"
        case .bluetoothUnauthorized: return "Нет разрешения на Bluetooth"
        }
    }

    private func saveStableReading() {
        guard let reading = scanner.stableReading else { return }
        let measurement = WeightMeasurement(
            weightKg: reading.weightKg,
            impedanceOhm: reading.impedanceOhm,
            user: selectedUser
        )
        context.insert(measurement)
        try? context.save()
    }
}

private struct WeightDisplay: View {
    let reading: OKOKReading

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", reading.weightKg))
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("кг")
                .font(.title2)
                .foregroundStyle(.secondary)
            if let impedance = reading.impedanceOhm {
                Text(String(format: "%.0f Ом", impedance))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WeightPlaceholder: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("--.-")
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
            Text("кг")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
