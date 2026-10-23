import XCTest
@testable import Scales

final class OKOKAdvertisementParserTests: XCTestCase {

    // MARK: - Helpers

    private func manufacturerData(companyID: UInt16, payload: [UInt8]) -> Data {
        var d = Data()
        d.append(UInt8(companyID & 0xFF))
        d.append(UInt8(companyID >> 8))
        d.append(contentsOf: payload)
        return d
    }

    private func v20Payload(weightRaw: Int, impedanceRaw: Int, flags: UInt8) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: 19)
        p[6] = flags
        p[8] = UInt8((weightRaw >> 8) & 0xFF)
        p[9] = UInt8(weightRaw & 0xFF)
        p[10] = UInt8((impedanceRaw >> 8) & 0xFF)
        p[11] = UInt8(impedanceRaw & 0xFF)
        var cs = 0x20
        for i in 0..<12 { cs ^= Int(p[i]) }
        p[12] = UInt8(cs & 0xFF)
        return p
    }

    private func v11Payload(weightRaw: Int, props: UInt8) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: 23)
        p[3] = UInt8((weightRaw >> 8) & 0xFF)
        p[4] = UInt8(weightRaw & 0xFF)
        p[9] = props
        var cs = 0xCA ^ 0x11
        for i in 0..<16 { cs ^= Int(p[i]) }
        p[16] = UInt8(cs & 0xFF)
        return p
    }

    private func vf0Payload(weightRaw: Int) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: 4)
        p[3] = UInt8((weightRaw >> 8) & 0xFF)
        p[2] = UInt8(weightRaw & 0xFF)
        return p
    }

    private func c0Payload(weightRaw: Int, impedanceRaw: Int, attrib: UInt8) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: 13)
        p[0] = UInt8((weightRaw >> 8) & 0xFF)
        p[1] = UInt8(weightRaw & 0xFF)
        p[2] = UInt8((impedanceRaw >> 8) & 0xFF)
        p[3] = UInt8(impedanceRaw & 0xFF)
        p[6] = attrib
        return p
    }

    // MARK: - V20

    func testV20_parsesWeightAndImpedance() {
        let data = manufacturerData(
            companyID: 0x20CA,
            payload: v20Payload(weightRaw: 723, impedanceRaw: 5000, flags: 0x01)
        )
        let reading = OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "Yoda0")
        XCTAssertEqual(reading?.weightKg ?? 0, 72.3, accuracy: 0.001)
        XCTAssertEqual(reading?.impedanceOhm ?? 0, 500.0, accuracy: 0.001)
        XCTAssertEqual(reading?.isStable, true)
    }

    func testV20_divider100() {
        let data = manufacturerData(
            companyID: 0x20CA,
            payload: v20Payload(weightRaw: 7250, impedanceRaw: 5000, flags: 0x05)
        )
        let reading = OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "Yoda0")
        XCTAssertEqual(reading?.weightKg ?? 0, 72.5, accuracy: 0.001)
    }

    func testV20_rejectsBadChecksum() {
        var payload = v20Payload(weightRaw: 723, impedanceRaw: 5000, flags: 0x01)
        payload[12] ^= 0xFF
        let data = manufacturerData(companyID: 0x20CA, payload: payload)
        XCTAssertNil(OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "Yoda0"))
    }

    func testV20_ignoresNonFinal() {
        let data = manufacturerData(
            companyID: 0x20CA,
            payload: v20Payload(weightRaw: 723, impedanceRaw: 5000, flags: 0x00)
        )
        XCTAssertNil(OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "Yoda0"))
    }

    // MARK: - V11

    func testV11_parsesWeight() {
        let data = manufacturerData(
            companyID: 0x11CA,
            payload: v11Payload(weightRaw: 723, props: 0x00)
        )
        let reading = OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "Chipsea-BLE")
        XCTAssertEqual(reading?.weightKg ?? 0, 72.3, accuracy: 0.001)
        XCTAssertEqual(reading?.isStable, false)
    }

    // MARK: - VF0

    func testVF0_parsesWeight() {
        let data = manufacturerData(
            companyID: 0xF0FF,
            payload: vf0Payload(weightRaw: 725)
        )
        let reading = OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "ADV")
        XCTAssertEqual(reading?.weightKg ?? 0, 72.5, accuracy: 0.001)
    }

    // MARK: - C0

    func testC0_parsesWeightAndImpedance() {
        let data = manufacturerData(
            companyID: 0x04C0,
            payload: c0Payload(weightRaw: 723, impedanceRaw: 4500, attrib: 0x01)
        )
        let reading = OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "ADV")
        XCTAssertEqual(reading?.weightKg ?? 0, 72.3, accuracy: 0.001)
        XCTAssertEqual(reading?.impedanceOhm ?? 0, 450.0, accuracy: 0.001)
        XCTAssertEqual(reading?.isStable, true)
    }

    func testC0_requiresKnownName() {
        let data = manufacturerData(
            companyID: 0x04C0,
            payload: c0Payload(weightRaw: 723, impedanceRaw: 4500, attrib: 0x01)
        )
        XCTAssertNil(OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: "RandomScale"))
    }

    // MARK: - Unknown

    func testUnknownCompanyID_returnsNil() {
        let data = manufacturerData(companyID: 0x1234, payload: [UInt8](repeating: 0, count: 19))
        XCTAssertNil(OKOKAdvertisementParser.parse(manufacturerData: data, deviceName: nil))
    }
}
