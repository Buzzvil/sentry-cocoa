import XCTest

class BuzzSentryLogTests: XCTestCase {
    var oldDebug: Bool!
    var oldLevel: SentryLevel!
    var oldOutput: BuzzSentryLogOutput!

    override func setUp() {
        super.setUp()
        oldDebug = BuzzSentryLog.isDebug()
        oldLevel = BuzzSentryLog.diagnosticLevel()
        oldOutput = BuzzSentryLog.logOutput()
    }

    override func tearDown() {
        super.tearDown()
        BuzzSentryLog.configure(oldDebug, diagnosticLevel: oldLevel)
        BuzzSentryLog.setLogOutput(oldOutput)
    }

    func testDefault_PrintsFatalAndError() {
        let logOutput = TestLogOutput()
        BuzzSentryLog.setLogOutput(logOutput)
        BuzzSentryLog.configure(true, diagnosticLevel: .error)
        
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.fatal)
        BuzzSentryLog.log(withMessage: "1", andLevel: SentryLevel.error)
        BuzzSentryLog.log(withMessage: "2", andLevel: SentryLevel.warning)
        BuzzSentryLog.log(withMessage: "3", andLevel: SentryLevel.none)
        
        XCTAssertEqual(["[Sentry] [fatal] 0", "[Sentry] [error] 1"], logOutput.loggedMessages)
    }
    
    func testDefaultInitOfLogoutPut() {
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.error)
    }
    
    func testConfigureWithoutDebug_PrintsNothing() {
        let logOutput = TestLogOutput()
        BuzzSentryLog.setLogOutput(logOutput)
        
        BuzzSentryLog.configure(false, diagnosticLevel: SentryLevel.none)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.fatal)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.error)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.warning)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.info)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.debug)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.none)
        
        XCTAssertEqual(0, logOutput.loggedMessages.count)
    }
    
    func testLevelNone_PrintsEverythingExceptNone() {
        let logOutput = TestLogOutput()
        BuzzSentryLog.setLogOutput(logOutput)
        
        BuzzSentryLog.configure(true, diagnosticLevel: SentryLevel.none)
        BuzzSentryLog.log(withMessage: "0", andLevel: SentryLevel.fatal)
        BuzzSentryLog.log(withMessage: "1", andLevel: SentryLevel.error)
        BuzzSentryLog.log(withMessage: "2", andLevel: SentryLevel.warning)
        BuzzSentryLog.log(withMessage: "3", andLevel: SentryLevel.info)
        BuzzSentryLog.log(withMessage: "4", andLevel: SentryLevel.debug)
        BuzzSentryLog.log(withMessage: "5", andLevel: SentryLevel.none)
        
        XCTAssertEqual(["[Sentry] [fatal] 0",
                        "[Sentry] [error] 1",
                        "[Sentry] [warning] 2",
                        "[Sentry] [info] 3",
                        "[Sentry] [debug] 4"], logOutput.loggedMessages)
    }
}
