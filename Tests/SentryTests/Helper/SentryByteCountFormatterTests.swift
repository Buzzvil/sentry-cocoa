import XCTest

class BuzzSentryByteCountFormatterTests: XCTestCase {

    func testBytesDescription() {
        assertDescription(baseValue: 1, unitName: "bytes")
    }
    
    func testKBDescription() {
        assertDescription(baseValue: 1_024, unitName: "KB")
    }
    
    func testMBDescription() {
        assertDescription(baseValue: 1_024 * 1_024, unitName: "MB")
    }
    
    func testGBDescription() {
        assertDescription(baseValue: 1_024 * 1_024 * 1_024, unitName: "GB")
    }
    
    func assertDescription(baseValue: UInt, unitName: String) {
        XCTAssertEqual("1 \(unitName)", BuzzSentryByteCountFormatter.bytesCountDescription(baseValue))
        XCTAssertEqual("512 \(unitName)", BuzzSentryByteCountFormatter.bytesCountDescription(baseValue * 512))
        XCTAssertEqual("1,023 \(unitName)", BuzzSentryByteCountFormatter.bytesCountDescription(baseValue * 1_024 - 1))
    }
    
}
