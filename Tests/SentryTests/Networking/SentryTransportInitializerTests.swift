@testable import Sentry
import XCTest

class BuzzSentryTransportInitializerTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryTransportInitializerTests")
    private static let dsn = TestConstants.dsn(username: "BuzzSentryTransportInitializerTests")
    
    private var fileManager: SentryFileManager!
    
    override func setUp() {
        super.setUp()
        do {
            let options = Options()
            options.dsn = BuzzSentryTransportInitializerTests.dsnAsString
            fileManager = try SentryFileManager(options: options, andCurrentDateProvider: TestCurrentDateProvider())
        } catch {
            XCTFail("BuzzSentryDsn could not be created")
        }
    }

    func testDefault() throws {
        let options = try Options(dict: ["dsn": BuzzSentryTransportInitializerTests.dsnAsString])
        
        let result = TransportInitializer.initTransport(options, sentryFileManager: fileManager)
        
        XCTAssertTrue(result.isKind(of: BuzzSentryHttpTransport.self))
    }
}
