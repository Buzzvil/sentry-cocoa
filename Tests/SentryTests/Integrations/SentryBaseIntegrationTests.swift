import Sentry
import XCTest

class MyTestIntegration: BuzzSentryBaseIntegration {
    override func integrationOptions() -> SentryIntegrationOption {
        return .integrationOptionEnableAutoSessionTracking
    }
}

class BuzzSentryBaseIntegrationTests: XCTestCase {
    var logOutput: TestLogOutput!
    var oldDebug: Bool!
    var oldLevel: SentryLevel!
    var oldOutput: BuzzSentryLogOutput!

    override func setUp() {
        super.setUp()
        oldDebug = BuzzSentryLog.isDebug()
        oldLevel = BuzzSentryLog.diagnosticLevel()
        oldOutput = BuzzSentryLog.logOutput()
        BuzzSentryLog.configure(true, diagnosticLevel: SentryLevel.debug)
        logOutput = TestLogOutput()
        BuzzSentryLog.setLogOutput(logOutput)
    }

    override func tearDown() {
        super.tearDown()
        BuzzSentryLog.configure(oldDebug, diagnosticLevel: oldLevel)
        BuzzSentryLog.setLogOutput(oldOutput)
    }

    func testIntegrationName() {
        let sut = BuzzSentryBaseIntegration()
        XCTAssertEqual(sut.integrationName(), "BuzzSentryBaseIntegration")
    }

    func testInstall() {
        let sut = BuzzSentryBaseIntegration()
        let result = sut.install(with: .init())
        XCTAssertTrue(result)
    }

    func testInstall_FailingIntegrationOption() {
        let sut = MyTestIntegration()
        let options = Options()
        options.enableAutoSessionTracking = false
        let result = sut.install(with: options)
        XCTAssertFalse(result)
        XCTAssertFalse(logOutput.loggedMessages.filter({ $0.contains("Not going to enable SentryTests.MyTestIntegration because enableAutoSessionTracking is disabled.") }).isEmpty)
    }
}
