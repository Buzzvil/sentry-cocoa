import XCTest

class BuzzSentryAutoSessionTrackingIntegrationTests: XCTestCase {

    func test_AutoSessionTrackingEnabled_TrackerInitialized() {
        let sut = BuzzSentryAutoSessionTrackingIntegration()
        sut.install(with: Options())
        
        XCTAssertNotNil(Dynamic(sut).tracker.asAnyObject)
    }
    
    func test_AutoSessionTracking_Disabled() {
        let options = Options()
        options.enableAutoSessionTracking = false
        
        let sut = BuzzSentryAutoSessionTrackingIntegration()
        let result = sut.install(with: options)
        
        XCTAssertFalse(result)
    }
}
