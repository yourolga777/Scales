import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WeightMeasurement.date, order: .reverse)
    private var measurements: [WeightMeasurement]

    var body: some View {
        NavigationStack {
            Group {
                if measurements.isEmpty {
                    ContentUnavailableView(
                        "Нет замеров",
                        systemImage: "scalemass",
                        description: Text("Замеры появятся после первого взвешивания.")
                    )
                } else {
                    List {
                        ForEach(measurements) { measurement in
                            MeasurementRow(measurement: measurement)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("История")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            measurements[index].modelContext?.delete(measurements[index])
        }
    }
}

private struct MeasurementRow: View {
    let measurement: WeightMeasurement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f кг", measurement.weightKg))
                    .font(.headline)
                if let user = measurement.user {
                    Text(user.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(measurement.date, format: .dateTime.day().month().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
