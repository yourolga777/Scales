import Foundation
import CoreBluetooth

final class ScaleScanner: NSObject, ObservableObject {
    @Published private(set) var state: State = .idle
    @Published private(set) var currentReading: OKOKReading?
    @Published private(set) var stableReading: OKOKReading?
    @Published private(set) var stableEventCount = 0

    enum State: Equatable {
        case idle
        case scanning
        case bluetoothOff
        case bluetoothUnavailable
        case bluetoothUnauthorized
    }

    private var central: CBCentralManager?
    private var sessionSaved = false
    private var stableCount = 0
    private var lastWeight: Double?

    func start() {
        guard let central else {
            self.central = CBCentralManager(delegate: self, queue: .main)
            return
        }
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        state = .scanning
    }

    func stop() {
        central?.stopScan()
        state = .idle
    }
}

extension ScaleScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            state = .scanning
        case .poweredOff:
            state = .bluetoothOff
        case .unsupported:
            state = .bluetoothUnavailable
        case .unauthorized:
            state = .bluetoothUnauthorized
        default:
            state = .idle
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else { return }
        guard let reading = OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: peripheral.name) else {
            return
        }

        if reading.weightKg > 0 {
            currentReading = reading
            updateStability(reading)
        } else {
            sessionSaved = false
            stableCount = 0
            lastWeight = nil
        }
    }

    private func updateStability(_ reading: OKOKReading) {
        let weight = reading.weightKg
        if let last = lastWeight, abs(weight - last) < 0.05 {
            stableCount += 1
        } else {
            stableCount = 0
        }
        lastWeight = weight

        let isFinal = reading.isStable || stableCount >= 3
        if isFinal, !sessionSaved {
            sessionSaved = true
            stableReading = reading
            stableEventCount += 1
        }
    }
}
