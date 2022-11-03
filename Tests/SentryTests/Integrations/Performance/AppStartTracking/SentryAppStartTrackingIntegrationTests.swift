import XCTest

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
class BuzzSentryAppStartTrackingIntegrationTests: NotificationCenterTestCase {
    
    private class Fixture {
        let options = Options()
        let fileManager: SentryFileManager
        
        init() {
            options.tracesSampleRate = 0.1
            options.tracesSampler = { _ in return 0 } 
            options.dsn = TestConstants.dsnAsString(username: "BuzzSentryAppStartTrackingIntegrationTests")
            
            fileManager = try! SentryFileManager(options: options, andCurrentDateProvider: TestCurrentDateProvider())
        }
    }
    
    private var fixture: Fixture!
    private var sut: BuzzSentryAppStartTrackingIntegration!
    
    override func setUp() {
        super.setUp()
        fixture = Fixture()
        SentrySDK.setAppStartMeasurement(nil)
        sut = BuzzSentryAppStartTrackingIntegration()
    }

    override func tearDown() {
        super.tearDown()
        fixture.fileManager.deleteAppState()
        PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode = false
        SentrySDK.setAppStartMeasurement(nil)
        sut.stop()
    }
    
    func testAppStartMeasuringEnabledAndSampleRate_DoesUpdatesAppState() {
        sut.install(with: fixture.options)
        
        uiWindowDidBecomeVisible()
        
        XCTAssertNotNil(SentrySDK.getAppStartMeasurement())
    }
    
    func testNoSampleRate_DoesNotUpdatesAppState() {
        let options = fixture.options
        options.tracesSampleRate = 0.0
        options.tracesSampler = nil
        sut.install(with: options)
        
        uiWindowDidBecomeVisible()
        
        XCTAssertNil(SentrySDK.getAppStartMeasurement())
    }
    
    func testHybridSDKModeEnabled_DoesUpdatesAppState() {
        PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode = true
        
        let options = fixture.options
        options.tracesSampleRate = 0.0
        options.tracesSampler = nil
        sut.install(with: options)
        
        uiWindowDidBecomeVisible()
        
        XCTAssertNotNil(SentrySDK.getAppStartMeasurement())
    }
    
    func testOnlyAppStartMeasuringEnabled_DoesNotUpdatesAppState() {
        let options = fixture.options
        options.tracesSampleRate = 0.0
        options.tracesSampler = nil
        sut.install(with: options)
        
        uiWindowDidBecomeVisible()
        
        XCTAssertNil(SentrySDK.getAppStartMeasurement())
    }
    
    func testAutoPerformanceTrackingDisabled_DoesNotUpdatesAppState() {
        let options = fixture.options
        options.enableAutoPerformanceTracking = false
        sut.install(with: options)
        
        uiWindowDidBecomeVisible()
        
        XCTAssertNil(SentrySDK.getAppStartMeasurement())
    }
    
    func test_PerformanceTrackingDisabled() {
        let options = fixture.options
        options.enableAutoPerformanceTracking = false
        let result = sut.install(with: options)
        
        XCTAssertFalse(result)
    }
    
}
#endif
