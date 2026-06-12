import Foundation

class TestThreadInspector: BuzzSentryThreadInspector {
    
    var allThreads: [BuzzSentry.Thread]?
    
    static var instance: TestThreadInspector {
        // We need something to pass to the super initializer, because the empty initializer has been marked unavailable.
        let inAppLogic = BuzzSentryInAppLogic(inAppIncludes: [], inAppExcludes: [])
        let crashStackEntryMapper = BuzzSentryCrashStackEntryMapper(inAppLogic: inAppLogic)
        let stacktraceBuilder = BuzzSentryStacktraceBuilder(crashStackEntryMapper: crashStackEntryMapper)
        return TestThreadInspector(stacktraceBuilder: stacktraceBuilder, andMachineContextWrapper: BuzzSentryCrashDefaultMachineContextWrapper())
    }
    
    override func getCurrentThreads() -> [BuzzSentry.Thread] {
        return allThreads ?? [TestData.thread]
    }

    override func getCurrentThreadsWithStackTrace() -> [BuzzSentry.Thread] {
        return allThreads ?? [TestData.thread]
    }

}
