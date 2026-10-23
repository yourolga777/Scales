import Foundation

/// Разбор manufacturer-specific data из BLE-рекламы OKOK-совместимых весов.
/// Формат задокументирован в PROTOCOL.md.
enum OKOKAdvertisementParser {

    static func parse(manufacturerData: Data, deviceName: String?) -> OKOKReading? {
        guard manufacturerData.count >= 3 else { return nil }

        // Company ID в рекламе лежит в little-endian (первые 2 байта).
        let companyID = UInt16(manufacturerData[manufacturerData.startIndex])
            | (UInt16(manufacturerData[manufacturerData.startIndex + 1]) << 8)
        let payload = [UInt8](manufacturerData.dropFirst(2))

        if companyID == 0x20CA { return parseV20(payload) }
        if companyID == 0x11CA { return parseV11(payload) }
        if companyID == 0xF0FF { return parseVF0(payload) }
        if (companyID & 0x00FF) == 0x00C0, isKnownDeviceName(deviceName) {
            return parseC0(payload)
        }
        return nil
    }

    // MARK: - V20 (0x20CA)

    private static func parseV20(_ p: [UInt8]) -> OKOKReading? {
        guard p.count == 19 else { return nil }
        let flags = Int(p[6])
        guard (flags & 0x01) != 0 else { return nil }

        var checksum = 0x20
        for i in 0..<12 { checksum ^= Int(p[i]) }
        guard checksum == Int(p[12]) else { return nil }

        let divider: Double = (flags & 0x04) != 0 ? 100 : 10
        let weightRaw = u16be(p, hi: 8, lo: 9)
        let impedanceRaw = u16be(p, hi: 10, lo: 11)
        return OKOKReading(
            weightKg: Double(weightRaw) / divider,
            impedanceOhm: Double(impedanceRaw) / 10,
            isStable: true
        )
    }

    // MARK: - V11 (0x11CA)

    private static func parseV11(_ p: [UInt8]) -> OKOKReading? {
        guard p.count == 23 else { return nil }

        var checksum = 0xCA ^ 0x11
        for i in 0..<16 { checksum ^= Int(p[i]) }
        guard checksum == Int(p[16]) else { return nil }

        let props = Int(p[9])
        let divider = resolutionDivider((props >> 1) & 0x3)
        let weightRaw = u16be(p, hi: 3, lo: 4)
        guard let weight = weightKg(weightRaw, divider: divider, unit: (props >> 3) & 0x3) else {
            return nil
        }
        return OKOKReading(weightKg: weight, impedanceOhm: nil, isStable: false)
    }

    // MARK: - VF0 (0xF0FF)

    private static func parseVF0(_ p: [UInt8]) -> OKOKReading? {
        guard p.count >= 4 else { return nil }
        let weightRaw = u16be(p, hi: 3, lo: 2)
        return OKOKReading(weightKg: Double(weightRaw) / 10, impedanceOhm: nil, isStable: false)
    }

    // MARK: - C0 (company ID low byte == 0xC0)

    private static func parseC0(_ p: [UInt8]) -> OKOKReading? {
        guard p.count >= 13 else { return nil }
        let attrib = Int(p[6])
        guard (attrib & 0x01) != 0 else { return nil }

        let divider = resolutionDivider((attrib >> 1) & 0x3)
        let weightRaw = u16be(p, hi: 0, lo: 1)
        guard let weight = weightKg(weightRaw, divider: divider, unit: (attrib >> 3) & 0x3) else {
            return nil
        }
        let impedanceRaw = u16be(p, hi: 2, lo: 3)
        return OKOKReading(
            weightKg: weight,
            impedanceOhm: Double(impedanceRaw) / 10,
            isStable: true
        )
    }

    // MARK: - Helpers

    private static func u16be(_ p: [UInt8], hi: Int, lo: Int) -> Int {
        (Int(p[hi]) << 8) | Int(p[lo])
    }

    private static func resolutionDivider(_ bits: Int) -> Double {
        switch bits {
        case 0: return 10
        case 1: return 1
        case 2: return 100
        default: return 10
        }
    }

    /// Единица измерения: 0 = кг, 1 = цзинь, 2 = фунты, 3 = стоуны:фунты.
    private static func weightKg(_ raw: Int, divider: Double, unit: Int) -> Double? {
        switch unit {
        case 0:
            return Double(raw) / divider
        case 1:
            return Double(raw) / (divider * 2)
        case 2:
            return (Double(raw) / divider) * 0.45359237
        case 3:
            let stones = raw >> 8
            let pounds = Double(raw & 0xFF) / divider
            return Double(stones) * 6.350293 + pounds * 0.453592
        default:
            return nil
        }
    }

    private static func isKnownDeviceName(_ name: String?) -> Bool {
        guard let name, !name.isEmpty else { return true }
        if name == "ADV" || name == "Chipsea-BLE" { return true }
        let lower = name.lowercased()
        return lower.hasPrefix("yoda0") || lower.hasPrefix("yoda1")
    }
}
