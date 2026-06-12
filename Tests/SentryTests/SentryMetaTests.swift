import BuzzSentry
import XCTest

class BuzzSentryMetaTest: XCTestCase {
    func testChangeVersion() {
        BuzzSentryMeta.versionString = "0.0.1"
        XCTAssertEqual(BuzzSentryMeta.versionString, "0.0.1")
    }

    func testChangeName() {
        BuzzSentryMeta.sdkName = "test"
        XCTAssertEqual(BuzzSentryMeta.sdkName, "test")
    }
}
