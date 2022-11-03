import Foundation

class TestClient: Client {
    let BuzzSentryFileManager: BuzzSentryFileManager
    let queue = DispatchQueue(label: "TestClient", attributes: .concurrent)

    override init?(options: Options) {
        BuzzSentryFileManager = try! BuzzSentryFileManager(options: options, andCurrentDateProvider: TestCurrentDateProvider())
        super.init(options: options, permissionsObserver: TestBuzzSentryPermissionsObserver())
    }

    // Without this override we get a fatal error: use of unimplemented initializer
    // see https://stackoverflow.com/questions/28187261/ios-swift-fatal-error-use-of-unimplemented-initializer-init
    override init(options: Options, transportAdapter: BuzzSentryTransportAdapter, fileManager: BuzzSentryFileManager, threadInspector: BuzzSentryThreadInspector, random: BuzzSentryRandomProtocol, crashWrapper: BuzzSentryCrashWrapper, permissionsObserver: BuzzSentryPermissionsObserver, deviceWrapper: BuzzSentryUIDeviceWrapper, locale: Locale, timezone: TimeZone) {
        BuzzSentryFileManager = try! BuzzSentryFileManager(options: options, andCurrentDateProvider: TestCurrentDateProvider())
        super.init(
            options: options,
            transportAdapter: transportAdapter,
            fileManager: fileManager,
            threadInspector: threadInspector,
            random: random,
            crashWrapper: crashWrapper,
            permissionsObserver: permissionsObserver,
            deviceWrapper: deviceWrapper,
            locale: locale,
            timezone: timezone
        )
    }

    override func fileManager() -> BuzzSentryFileManager {
        BuzzSentryFileManager
    }
    
    var captureSessionInvocations = Invocations<BuzzSentrySession>()
    override func capture(session: BuzzSentrySession) {
        captureSessionInvocations.record(session)
    }
    
    var captureEventInvocations = Invocations<Event>()
    override func capture(event: Event) -> BuzzSentryId {
        captureEventInvocations.record(event)
        return event.eventId
    }
    
    var captureEventWithScopeInvocations = Invocations<(event: Event, scope: Scope, additionalEnvelopeItems: [BuzzSentryEnvelopeItem])>()
    override func capture(event: Event, scope: Scope, additionalEnvelopeItems: [BuzzSentryEnvelopeItem]) -> BuzzSentryId {
        captureEventWithScopeInvocations.record((event, scope, additionalEnvelopeItems))
        return event.eventId
    }
    
    var captureMessageInvocations = Invocations<String>()
    override func capture(message: String) -> BuzzSentryId {
        self.captureMessageInvocations.record(message)
        return BuzzSentryId()
    }
    
    var captureMessageWithScopeInvocations = Invocations<(message: String, scope: Scope)>()
    override func capture(message: String, scope: Scope) -> BuzzSentryId {
        captureMessageWithScopeInvocations.record((message, scope))
        return BuzzSentryId()
    }
    
    var captureErrorInvocations = Invocations<Error>()
    override func capture(error: Error) -> BuzzSentryId {
        captureErrorInvocations.record(error)
        return BuzzSentryId()
    }
    
    var captureErrorWithScopeInvocations = Invocations<(error: Error, scope: Scope)>()
    override func capture(error: Error, scope: Scope) -> BuzzSentryId {
        captureErrorWithScopeInvocations.record((error, scope))
        return BuzzSentryId()
    }
    
    var captureExceptionInvocations = Invocations<NSException>()
    override func capture(exception: NSException) -> BuzzSentryId {
        captureExceptionInvocations.record(exception)
        return BuzzSentryId()
    }
    
    var captureExceptionWithScopeInvocations = Invocations<(exception: NSException, scope: Scope)>()
    override func capture(exception: NSException, scope: Scope) -> BuzzSentryId {
        captureExceptionWithScopeInvocations.record((exception, scope))
        return BuzzSentryId()
    }
    
    var captureErrorWithSessionInvocations = Invocations<(error: Error, session: BuzzSentrySession, scope: Scope)>()
    override func captureError(_ error: Error, with session: BuzzSentrySession, with scope: Scope) -> BuzzSentryId {
        captureErrorWithSessionInvocations.record((error, session, scope))
        return BuzzSentryId()
    }
    
    var captureExceptionWithSessionInvocations = Invocations<(exception: NSException, session: BuzzSentrySession, scope: Scope)>()
    override func capture(_ exception: NSException, with session: BuzzSentrySession, with scope: Scope) -> BuzzSentryId {
        captureExceptionWithSessionInvocations.record((exception, session, scope))
        return BuzzSentryId()
    }
    
    var captureCrashEventInvocations = Invocations<(event: Event, scope: Scope)>()
    override func captureCrash(_ event: Event, with scope: Scope) -> BuzzSentryId {
        captureCrashEventInvocations.record((event, scope))
        print("### Captured")
        return BuzzSentryId()
    }
    
    var captureCrashEventWithSessionInvocations = Invocations<(event: Event, session: BuzzSentrySession, scope: Scope)>()
    override func captureCrash(_ event: Event, with session: BuzzSentrySession, with scope: Scope) -> BuzzSentryId {
        captureCrashEventWithSessionInvocations.record((event, session, scope))
        return BuzzSentryId()
    }
    
    var captureUserFeedbackInvocations = Invocations<UserFeedback>()
    override func capture(userFeedback: UserFeedback) {
        captureUserFeedbackInvocations.record(userFeedback)
    }
    
    var captureEnvelopeInvocations = Invocations<BuzzSentryEnvelope>()
    override func capture(envelope: BuzzSentryEnvelope) {
        captureEnvelopeInvocations.record(envelope)
    }
    
    var storedEnvelopeInvocations = Invocations<BuzzSentryEnvelope>()
    override func store(_ envelope: BuzzSentryEnvelope) {
        storedEnvelopeInvocations.record(envelope)
    }
    
    var recordLostEvents = Invocations<(category: BuzzSentryDataCategory, reason: BuzzSentryDiscardReason)>()
    override func recordLostEvent(_ category: BuzzSentryDataCategory, reason: BuzzSentryDiscardReason) {
        recordLostEvents.record((category, reason))
    }
    
    var flushInvoctions = Invocations<TimeInterval>()
    override func flush(timeout: TimeInterval) {
        flushInvoctions.record(timeout)
    }
}

class TestFileManager: BuzzSentryFileManager {
    var timestampLastInForeground: Date?
    var readTimestampLastInForegroundInvocations: Int = 0
    var storeTimestampLastInForegroundInvocations: Int = 0
    var deleteTimestampLastInForegroundInvocations: Int = 0

    override func readTimestampLastInForeground() -> Date? {
        readTimestampLastInForegroundInvocations += 1
        return timestampLastInForeground
    }

    override func storeTimestampLast(inForeground: Date) {
        storeTimestampLastInForegroundInvocations += 1
        timestampLastInForeground = inForeground
    }

    override func deleteTimestampLastInForeground() {
        deleteTimestampLastInForegroundInvocations += 1
        timestampLastInForeground = nil
    }
    
    var readAppStateInvocations = Invocations<Void>()
    override func readAppState() -> BuzzSentryAppState? {
        readAppStateInvocations.record(Void())
        return nil
    }

    var readPreviousAppStateInvocations = Invocations<Void>()
    override func readPreviousAppState() -> BuzzSentryAppState? {
        readPreviousAppStateInvocations.record(Void())
        return nil
    }
}
