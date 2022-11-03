@testable import Sentry
import XCTest

class BuzzSentrySDKTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentrySDKTests")
    private static let dsn = TestConstants.dsn(username: "BuzzSentrySDKTests")
    
    private class Fixture {
    
        let options: Options
        let event: Event
        let scope: Scope
        let client: TestClient
        let hub: BuzzSentryHub
        let error: Error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Object does not exist"])
        let exception = NSException(name: NSExceptionName("My Custom exeption"), reason: "User clicked the button", userInfo: nil)
        let userFeedback: UserFeedback
        let currentDate = TestCurrentDateProvider()
        
        let scopeBlock: (Scope) -> Void = { scope in
            scope.setTag(value: "tag", key: "tag")
        }
        
        var scopeWithBlockApplied: Scope {
            get {
                let scope = self.scope
                scopeBlock(scope)
                return scope
            }
        }
        
        let message = "message"
        
        init() {
            CurrentDate.setCurrentDateProvider(currentDate)
            
            event = Event()
            event.message = BuzzSentryMessage(formatted: message)
            
            scope = Scope()
            scope.setTag(value: "value", key: "key")
            
            options = Options()
            options.dsn = BuzzSentrySDKTests.dsnAsString
            options.releaseName = "1.0.0"
            client = TestClient(options: options)!
            hub = BuzzSentryHub(client: client, andScope: scope, andCrashWrapper: TestBuzzSentryCrashWrapper.sharedInstance(), andCurrentDateProvider: currentDate)
            
            userFeedback = UserFeedback(eventId: BuzzSentryId())
            userFeedback.comments = "Again really?"
            userFeedback.email = "tim@apple.com"
            userFeedback.name = "Tim Apple"
        }
    }
    
    private var fixture: Fixture!
    
    override func setUp() {
        super.setUp()
        fixture = Fixture()
    }
    
    override func tearDown() {
        super.tearDown()
        
        givenSdkWithHubButNoClient()
        
        if let autoSessionTracking = BuzzSentrySDK.currentHub().installedIntegrations.first(where: { it in
            it is BuzzSentryAutoSessionTrackingIntegration
        }) as? BuzzSentryAutoSessionTrackingIntegration {
            autoSessionTracking.stop()
        }
        
        clearTestState()
    }
    
    // Repro for: https://github.com/getsentry/sentry-cocoa/issues/1325
    func testStartWithZeroMaxBreadcrumbsOptionsDoesNotCrash() {
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
            options.maxBreadcrumbs = 0
        }

        BuzzSentrySDK.addBreadcrumb(crumb: Breadcrumb(level: SentryLevel.warning, category: "test"))
        let breadcrumbs = Dynamic(BuzzSentrySDK.currentHub().scope).breadcrumbArray as [Breadcrumb]?
        XCTAssertEqual(0, breadcrumbs?.count)
    }

    func testStartWithConfigureOptions() {
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
            options.debug = true
            options.diagnosticLevel = SentryLevel.debug
            options.attachStacktrace = true
        }
        
        let hub = BuzzSentrySDK.currentHub()
        XCTAssertNotNil(hub)
        XCTAssertNotNil(hub.installedIntegrations)
        XCTAssertNotNil(hub.getClient()?.options)
        
        let options = hub.getClient()?.options
        XCTAssertNotNil(options)
        XCTAssertEqual(BuzzSentrySDKTests.dsnAsString, options?.dsn)
        XCTAssertEqual(SentryLevel.debug, options?.diagnosticLevel)
        XCTAssertEqual(true, options?.attachStacktrace)
        XCTAssertEqual(true, options?.enableAutoSessionTracking)

        assertIntegrationsInstalled(integrations: [
            "BuzzSentryCrashIntegration",
            "BuzzSentryAutoBreadcrumbTrackingIntegration",
            "BuzzSentryAutoSessionTrackingIntegration",
            "BuzzSentryNetworkTrackingIntegration"
        ])
    }
    
    func testStartWithConfigureOptions_NoDsn() throws {
        BuzzSentrySDK.start { options in
            options.debug = true
        }
        
        let options = BuzzSentrySDK.currentHub().getClient()?.options
        XCTAssertNotNil(options, "Options should not be nil")
        XCTAssertNil(options?.parsedDsn)
        XCTAssertTrue(options?.enabled ?? false)
        XCTAssertEqual(true, options?.debug)
    }
    
    func testStartWithConfigureOptions_WrongDsn() throws {
        BuzzSentrySDK.start { options in
            options.dsn = "wrong"
        }
        
        let options = BuzzSentrySDK.currentHub().getClient()?.options
        XCTAssertNotNil(options, "Options should not be nil")
        XCTAssertTrue(options?.enabled ?? false)
        XCTAssertNil(options?.parsedDsn)
    }
    
    func testStartWithConfigureOptions_BeforeSend() {
        var wasBeforeSendCalled = false
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
            options.beforeSend = { event in
                wasBeforeSendCalled = true
                return event
            }
        }
        
        BuzzSentrySDK.capture(message: "")
        
        XCTAssertTrue(wasBeforeSendCalled, "beforeSend was not called.")
    }
    
    func testCrashedLastRun() {
        XCTAssertEqual(SentryCrash.sharedInstance().crashedLastLaunch, BuzzSentrySDK.crashedLastRun) 
    }
    
    func testCaptureCrashEvent() {
        let hub = TestHub(client: nil, andScope: nil)
        BuzzSentrySDK.setCurrentHub(hub)
        
        let event = fixture.event
        BuzzSentrySDK.captureCrash(event)
    
        XCTAssertEqual(1, hub.sentCrashEvents.count)
        XCTAssertEqual(event.message, hub.sentCrashEvents.first?.message)
        XCTAssertEqual(event.eventId, hub.sentCrashEvents.first?.eventId)
    }
    
    func testCaptureEvent() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(event: fixture.event)
        
        assertEventCaptured(expectedScope: fixture.scope)
    }

    func testCaptureEventWithScope() {
        givenSdkWithHub()
        
        let scope = Scope()
        BuzzSentrySDK.capture(event: fixture.event, scope: scope)
    
        assertEventCaptured(expectedScope: scope)
    }
       
    func testCaptureEventWithScopeBlock_ScopePassedToHub() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(event: fixture.event, block: fixture.scopeBlock)
    
        assertEventCaptured(expectedScope: fixture.scopeWithBlockApplied)
    }
    
    func testCaptureEventWithScopeBlock_CreatesNewScope() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(event: fixture.event, block: fixture.scopeBlock)
    
        assertHubScopeNotChanged()
    }
    
    func testCaptureError() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(error: fixture.error)
        
        assertErrorCaptured(expectedScope: fixture.scope)
    }
    
    func testCaptureErrorWithScope() {
        givenSdkWithHub()
        
        let scope = Scope()
        BuzzSentrySDK.capture(error: fixture.error, scope: scope)
        
        assertErrorCaptured(expectedScope: scope)
    }
    
    func testCaptureErrorWithScopeBlock_ScopePassedToHub() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(error: fixture.error, block: fixture.scopeBlock)
        
        assertErrorCaptured(expectedScope: fixture.scopeWithBlockApplied)
    }
    
    func testCaptureErrorWithScopeBlock_CreatesNewScope() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(error: fixture.error, block: fixture.scopeBlock)
        
        assertHubScopeNotChanged()
    }
    
    func testCaptureException() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(exception: fixture.exception)
        
        assertExceptionCaptured(expectedScope: fixture.scope)
    }
    
    func testCaptureExceptionWithScope() {
        givenSdkWithHub()
        
        let scope = Scope()
        BuzzSentrySDK.capture(exception: fixture.exception, scope: scope)
        
        assertExceptionCaptured(expectedScope: scope)
    }
    
    func testCaptureExceptionWithScopeBlock_ScopePassedToHub() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(exception: fixture.exception, block: fixture.scopeBlock)
        
        assertExceptionCaptured(expectedScope: fixture.scopeWithBlockApplied)
    }
    
    func testCaptureExceptionWithScopeBlock_CreatesNewScope() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(exception: fixture.exception, block: fixture.scopeBlock)
        
        assertHubScopeNotChanged()
    }
    
    func testCaptureMessageWithScopeBlock_ScopePassedToHub() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(message: fixture.message, block: fixture.scopeBlock)
        
        assertMessageCaptured(expectedScope: fixture.scopeWithBlockApplied)
    }
    
    func testCaptureMessageWithScopeBlock_CreatesNewScope() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(message: fixture.message, block: fixture.scopeBlock)
        
        assertHubScopeNotChanged()
    }
    
    func testCaptureEnvelope() {
        givenSdkWithHub()
        
        let envelope = BuzzSentryEnvelope(event: TestData.event)
        BuzzSentrySDK.capture(envelope)
        
        XCTAssertEqual(1, fixture.client.captureEnvelopeInvocations.count)
        XCTAssertEqual(envelope.header.eventId, fixture.client.captureEnvelopeInvocations.first?.header.eventId)
    }
    
    func testStoreEnvelope() {
        givenSdkWithHub()
        
        let envelope = BuzzSentryEnvelope(event: TestData.event)
        BuzzSentrySDK.store(envelope)
        
        XCTAssertEqual(1, fixture.client.storedEnvelopeInvocations.count)
        XCTAssertEqual(envelope.header.eventId, fixture.client.storedEnvelopeInvocations.first?.header.eventId)
    }
    
    func testStoreEnvelope_WhenNoClient_NoCrash() {
        BuzzSentrySDK.store(BuzzSentryEnvelope(event: TestData.event))
        
        XCTAssertEqual(0, fixture.client.storedEnvelopeInvocations.count)
    }
    
    func testCaptureUserFeedback() {
        givenSdkWithHub()
        
        BuzzSentrySDK.capture(userFeedback: fixture.userFeedback)
        let client = fixture.client
        XCTAssertEqual(1, client.captureUserFeedbackInvocations.count)
        if let actual = client.captureUserFeedbackInvocations.first {
            let expected = fixture.userFeedback
            XCTAssertEqual(expected.eventId, actual.eventId)
            XCTAssertEqual(expected.name, actual.name)
            XCTAssertEqual(expected.email, actual.email)
            XCTAssertEqual(expected.comments, actual.comments)
        }
    }
    
    func testSetUser_SetsUserToScopeOfHub() {
        givenSdkWithHub()
        
        let user = TestData.user
        BuzzSentrySDK.setUser(user)
        
        let actualScope = BuzzSentrySDK.currentHub().scope
        let event = actualScope.apply(to: fixture.event, maxBreadcrumb: 10)
        XCTAssertEqual(event?.user, user)
    }
    
    func testStartTransaction() {
        givenSdkWithHub()
        
        let span = BuzzSentrySDK.startTransaction(name: "Some Transaction", operation: "Operations", bindToScope: true)
        let newSpan = BuzzSentrySDK.span
        
        XCTAssert(span === newSpan)
    }
    
    func testInstallIntegrations() {
        let options = Options()
        options.dsn = "mine"
        options.integrations = ["SentryTestIntegration", "SentryTestIntegration", "IDontExist"]
        
        BuzzSentrySDK.start(options: options)
        
        assertIntegrationsInstalled(integrations: ["SentryTestIntegration"])
        let integration = BuzzSentrySDK.currentHub().installedIntegrations.firstObject
        XCTAssertTrue(integration is SentryTestIntegration)
        if let testIntegration = integration as? SentryTestIntegration {
            XCTAssertEqual(options.dsn, testIntegration.options.dsn)
            XCTAssertEqual(options.integrations, testIntegration.options.integrations)
        }
    }
    
    func testInstallIntegrations_NoIntegrations() {
        BuzzSentrySDK.start { options in
            options.integrations = []
        }
        
        assertIntegrationsInstalled(integrations: [])
    }
    
    func testStartSession() {
        givenSdkWithHub()
        
        BuzzSentrySDK.startSession()
        
        XCTAssertEqual(1, fixture.client.captureSessionInvocations.count)
        
        let actual = fixture.client.captureSessionInvocations.first
        let expected = BuzzSentrySession(releaseName: fixture.options.releaseName ?? "")
        
        XCTAssertEqual(expected.flagInit, actual?.flagInit)
        XCTAssertEqual(expected.errors, actual?.errors)
        XCTAssertEqual(expected.sequence, actual?.sequence)
        XCTAssertEqual(expected.releaseName, actual?.releaseName)
        XCTAssertEqual(fixture.currentDate.date(), actual?.started)
        XCTAssertEqual(BuzzSentrySessionStatus.ok, actual?.status)
        XCTAssertNil(actual?.timestamp)
        XCTAssertNil(actual?.duration)
    }
    
    func testEndSession() {
        givenSdkWithHub()
        
        BuzzSentrySDK.startSession()
        advanceTime(bySeconds: 1)
        BuzzSentrySDK.endSession()
        
        XCTAssertEqual(2, fixture.client.captureSessionInvocations.count)
        
        let actual = fixture.client.captureSessionInvocations.invocations[1]
        
        XCTAssertNil(actual.flagInit)
        XCTAssertEqual(0, actual.errors)
        XCTAssertEqual(2, actual.sequence)
        XCTAssertEqual(BuzzSentrySessionStatus.exited, actual.status)
        XCTAssertEqual(fixture.options.releaseName ?? "", actual.releaseName)
        XCTAssertEqual(1, actual.duration)
        XCTAssertEqual(fixture.currentDate.date(), actual.timestamp)
    }
    
    func testGlobalOptions() {
        BuzzSentrySDK.setCurrentHub(fixture.hub)
        XCTAssertEqual(BuzzSentrySDK.options, fixture.options)
    }
    
    func testSetAppStartMeasurement_CallsPrivateSDKCallback() {
        let appStartMeasurement = TestData.getAppStartMeasurement(type: .warm)
        
        var callbackCalled = false
        PrivateBuzzSentrySDKOnly.onAppStartMeasurementAvailable = { measurement in
            XCTAssertEqual(appStartMeasurement, measurement)
            callbackCalled = true
        }
        
        BuzzSentrySDK.setAppStartMeasurement(appStartMeasurement)
        XCTAssertTrue(callbackCalled)
    }
    
    func testSetAppStartMeasurement_NoCallback_CallbackNotCalled() {
        let appStartMeasurement = TestData.getAppStartMeasurement(type: .warm)
        
        BuzzSentrySDK.setAppStartMeasurement(appStartMeasurement)
        
        XCTAssertEqual(BuzzSentrySDK.getAppStartMeasurement(), appStartMeasurement)
    }
    
    func testSDKStartInvocations() {
        XCTAssertEqual(0, BuzzSentrySDK.startInvocations)
        
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
        }
        
        XCTAssertEqual(1, BuzzSentrySDK.startInvocations)
    }
    
    func testIsEnabled() {
        XCTAssertFalse(BuzzSentrySDK.isEnabled)
        
        BuzzSentrySDK.capture(message: "message")
        XCTAssertFalse(BuzzSentrySDK.isEnabled)
        
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
        }
        XCTAssertTrue(BuzzSentrySDK.isEnabled)
        
        BuzzSentrySDK.close()
        XCTAssertFalse(BuzzSentrySDK.isEnabled)
        
        BuzzSentrySDK.capture(message: "message")
        XCTAssertFalse(BuzzSentrySDK.isEnabled)
        
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
        }
        XCTAssertTrue(BuzzSentrySDK.isEnabled)
    }
    
    func testClose_ResetsDependencyContainer() {
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
        }
        
        let first = BuzzSentryDependencyContainer.sharedInstance()
        
        BuzzSentrySDK.close()
        
        let second = BuzzSentryDependencyContainer.sharedInstance()
        
        XCTAssertNotEqual(first, second)
    }
    
    func testFlush_CallsFlushCorrectlyOnTransport() {
        BuzzSentrySDK.start { options in
            options.dsn = BuzzSentrySDKTests.dsnAsString
        }
        
        let transport = TestTransport()
        let client = Client(options: fixture.options)
        Dynamic(client).transportAdapter = TestTransportAdapter(transport: transport, options: fixture.options)
        BuzzSentrySDK.currentHub().bindClient(client)
        
        let flushTimeout = 10.0
        BuzzSentrySDK.flush(timeout: flushTimeout)
        
        XCTAssertEqual(flushTimeout, transport.flushInvocations.first)
    }
    
    // Although we only run this test above the below specified versions, we expect the
    // implementation to be thread safe
    @available(tvOS 10.0, *)
    @available(OSX 10.12, *)
    @available(iOS 10.0, *)
    func testSetpAppStartMeasurementConcurrently_() {
        func setAppStartMeasurement(_ queue: DispatchQueue, _ i: Int) {
            group.enter()
            queue.async {
                let timestamp = self.fixture.currentDate.date().addingTimeInterval( TimeInterval(i))
                let appStartMeasurement = TestData.getAppStartMeasurement(type: .warm, appStartTimestamp: timestamp)
                BuzzSentrySDK.setAppStartMeasurement(appStartMeasurement)
                group.leave()
            }
        }
        
        func createQueue() -> DispatchQueue {
            return DispatchQueue(label: "BuzzSentrySDKTests", qos: .userInteractive, attributes: [.initiallyInactive])
        }
        
        let queue1 = createQueue()
        let queue2 = createQueue()
        let group = DispatchGroup()
        
        let amount = 100
        
        for i in 0...amount {
            setAppStartMeasurement(queue1, i)
            setAppStartMeasurement(queue2, i)
        }
        
        queue1.activate()
        queue2.activate()
        group.waitWithTimeout(timeout: 100)
        
        let timestamp = self.fixture.currentDate.date().addingTimeInterval(TimeInterval(amount))
        XCTAssertEqual(timestamp, BuzzSentrySDK.getAppStartMeasurement()?.appStartTimestamp)
    }
    
    private func givenSdkWithHub() {
        BuzzSentrySDK.setCurrentHub(fixture.hub)
    }
    
    private func givenSdkWithHubButNoClient() {
        BuzzSentrySDK.setCurrentHub(BuzzSentryHub(client: nil, andScope: nil))
    }
    
    private func assertIntegrationsInstalled(integrations: [String]) {
        integrations.forEach { integration in
            if let integrationClass = NSClassFromString(integration) {
                XCTAssertTrue(BuzzSentrySDK.currentHub().isIntegrationInstalled(integrationClass), "\(integration) not installed")
            } else {
                XCTFail("Integration \(integration) not installed.")
            }
        }
    }
    
    private func assertEventCaptured(expectedScope: Scope) {
        let client = fixture.client
        XCTAssertEqual(1, client.captureEventWithScopeInvocations.count)
        XCTAssertEqual(fixture.event, client.captureEventWithScopeInvocations.first?.event)
        XCTAssertEqual(expectedScope, client.captureEventWithScopeInvocations.first?.scope)
    }
    
    private func assertErrorCaptured(expectedScope: Scope) {
        let client = fixture.client
        XCTAssertEqual(1, client.captureErrorWithScopeInvocations.count)
        XCTAssertEqual(fixture.error.localizedDescription, client.captureErrorWithScopeInvocations.first?.error.localizedDescription)
        XCTAssertEqual(expectedScope, client.captureErrorWithScopeInvocations.first?.scope)
    }
    
    private func assertExceptionCaptured(expectedScope: Scope) {
        let client = fixture.client
        XCTAssertEqual(1, client.captureExceptionWithScopeInvocations.count)
        XCTAssertEqual(fixture.exception, client.captureExceptionWithScopeInvocations.first?.exception)
        XCTAssertEqual(expectedScope, client.captureExceptionWithScopeInvocations.first?.scope)
    }
    
    private func assertMessageCaptured(expectedScope: Scope) {
        let client = fixture.client
        XCTAssertEqual(1, client.captureMessageWithScopeInvocations.count)
        XCTAssertEqual(fixture.message, client.captureMessageWithScopeInvocations.first?.message)
        XCTAssertEqual(expectedScope, client.captureMessageWithScopeInvocations.first?.scope)
    }
    
    private func assertHubScopeNotChanged() {
        let hubScope = BuzzSentrySDK.currentHub().scope
        XCTAssertEqual(fixture.scope, hubScope)
    }
    
    private func advanceTime(bySeconds: TimeInterval) {
        fixture.currentDate.setDate(date: fixture.currentDate.date().addingTimeInterval(bySeconds))
    }
}
