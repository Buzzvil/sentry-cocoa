@testable import BuzzSentry
import XCTest

@available(OSX 10.10, *)
class BuzzSentryCrashInstallationReporterTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryCrashInstallationReporterTests")
    
    private var testClient: TestClient!
    private var sut: BuzzSentryCrashInstallationReporter!
    
    override func setUp() {
        super.setUp()
        sut = BuzzSentryCrashInstallationReporter(inAppLogic: BuzzSentryInAppLogic(inAppIncludes: [], inAppExcludes: []), crashWrapper: TestBuzzSentryCrashWrapper.sharedInstance(), dispatchQueue: TestBuzzSentryDispatchQueueWrapper())
        sut.install()
        // Works only if BuzzSentryCrash is installed
        sentrycrash_deleteAllReports()
    }
    
    override func tearDown() {
        super.tearDown()
        sentrycrash_deleteAllReports()
        clearTestState()
    }
    
    func testFaultyReportIsNotSentAndDeleted() throws {
        sdkStarted()
        
        try givenStoredBuzzSentryCrashReport(resource: "Resources/Crash-faulty-report")

        sut.sendAllReports()
        
        // We need to wait a bit until BuzzSentryCrash is finished processing reports.
        // It is not optimal to block, but we would need to change the internals
        // of BuzzSentryCrash a lot to be able to avoid this delay. As we would
        // like to replace BuzzSentryCrash anyway it's not worth the effort right now.
        delayNonBlocking()
        
        assertNoEventsSent()
        assertNoReportsStored()
    }
    
    private func sdkStarted() {
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentryCrashInstallationReporterTests.dsnAsString
        }
        let options = Options()
        options.dsn = BuzzSentryCrashInstallationReporterTests.dsnAsString
        testClient = TestClient(options: options)!
        let hub = BuzzSentryHub(client: testClient, andScope: nil)
        BuzzSentrySDK.setCurrentHub(hub)
    }
    
    private func assertNoEventsSent() {
        XCTAssertEqual(0, testClient.captureEventWithScopeInvocations.count)
    }
    
    private func assertNoReportsStored() {
        XCTAssertEqual(0, sentrycrash_getReportCount())
    }
}
