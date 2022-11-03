@testable import Sentry
import XCTest

class BuzzSentryNSURLRequestTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryNSURLRequestTests")
    private static let dsn = TestConstants.dsn(username: "BuzzSentryNSURLRequestTests")
    
    func testRequestWithEnvelopeEndpoint() {
        let request = try! BuzzSentryNSURLRequest(envelopeRequestWith: BuzzSentryNSURLRequestTests.dsn, andData: Data())
        XCTAssertTrue(request.url!.absoluteString.hasSuffix("/envelope/"))
    }
    func testRequestWithStoreEndpoint() {
        let request = try! BuzzSentryNSURLRequest(storeRequestWith: BuzzSentryNSURLRequestTests.dsn, andData: Data())
        XCTAssertTrue(request.url!.absoluteString.hasSuffix("/store/"))
    }
}
