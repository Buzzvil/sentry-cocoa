import XCTest

class BuzzSentryOutOfMemoryIntegrationTests: XCTestCase {

    private class Fixture {
        let options: Options
        let client: TestClient!
        let crashWrapper: TestBuzzSentryCrashWrapper
        let currentDate = TestCurrentDateProvider()
        let fileManager: BuzzSentryFileManager
        
        init() {
            options = Options()
            
            client = TestClient(options: options)
            
            crashWrapper = TestBuzzSentryCrashWrapper.sharedInstance()
            SentryDependencyContainer.sharedInstance().crashWrapper = crashWrapper

            let hub = BuzzSentryHub(client: client, andScope: nil, andCrashWrapper: crashWrapper, andCurrentDateProvider: currentDate)
            BuzzSentrySDK.setCurrentHub(hub)
            
            fileManager = try! BuzzSentryFileManager(options: options, andCurrentDateProvider: currentDate)
        }
    }
    
    private var fixture: Fixture!
    private var sut: BuzzSentryOutOfMemoryTrackingIntegration!
    
    override func setUp() {
        super.setUp()
        
        fixture = Fixture()
        fixture.fileManager.store(TestData.appState)
    }
    
    override func tearDown() {
        sut?.uninstall()
        fixture.fileManager.deleteAllFolders()
        clearTestState()
        super.tearDown()
    }
    
    func testWhenUnitTests_TrackerNotInitialized() {
        let sut = BuzzSentryOutOfMemoryTrackingIntegration()
        sut.install(with: Options())
        
        XCTAssertNil(Dynamic(sut).tracker.asAnyObject)
    }
    
    func testWhenNoUnitTests_TrackerInitialized() {
        let sut = BuzzSentryOutOfMemoryTrackingIntegration()
        Dynamic(sut).setTestConfigurationFilePath(nil)
        sut.install(with: Options())
        
        XCTAssertNotNil(Dynamic(sut).tracker.asAnyObject)
    }
    
    func testTestConfigurationFilePath() {
        let sut = BuzzSentryOutOfMemoryTrackingIntegration()
        let path = Dynamic(sut).testConfigurationFilePath.asString
        XCTAssertEqual(path, ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"])
    }
    
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
    func testANRDetected_UpdatesAppStateToTrue_disabled() {
        givenInitializedTracker()
        
        Dynamic(sut).anrDetected()
        
        guard let appState = fixture.fileManager.readAppState() else {
            XCTFail("appState must not be nil")
            return
        }
        
        XCTAssertTrue(appState.isANROngoing)
    }
#endif
  
    func testANRStopped_UpdatesAppStateToFalse() {
        givenInitializedTracker()
        
        Dynamic(sut).anrStopped()
        
        guard let appState = fixture.fileManager.readAppState() else {
            XCTFail("appState must not be nil")
            return
        }
        XCTAssertFalse(appState.isANROngoing)
    }
    
    func test_OOMDisabled_RemovesEnabledIntegration() {
        givenInitializedTracker()
        let options = Options()
        options.enableOutOfMemoryTracking = false
        
        let sut = BuzzSentryOutOfMemoryTrackingIntegration()
        let result = sut.install(with: options)
        
        XCTAssertFalse(result)
    }
    
    private func givenInitializedTracker(isBeingTraced: Bool = false) {
        fixture.crashWrapper.internalIsBeingTraced = isBeingTraced
        sut = BuzzSentryOutOfMemoryTrackingIntegration()
        let options = Options()
        Dynamic(sut).setTestConfigurationFilePath(nil)
        sut.install(with: options)
    }
    
}
