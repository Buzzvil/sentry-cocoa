import XCTest

class BuzzSentryNSNotificationCenterWrapperTests: XCTestCase {
    
    private var sut: BuzzSentryNSNotificationCenterWrapper!
    
    private var didBecomeActiveExpectation: XCTestExpectation!
    private var willResignActiveExpectation: XCTestExpectation!
    
    private let didBecomeActiveNotification = BuzzSentryNSNotificationCenterWrapper.didBecomeActiveNotificationName
    private let willResignActiveNotification = BuzzSentryNSNotificationCenterWrapper.willResignActiveNotificationName
    
    override func setUp() {
        super.setUp()
        
        sut = BuzzSentryNSNotificationCenterWrapper()
        
        didBecomeActiveExpectation = expectation(description: "didBecomeActive")
        willResignActiveExpectation = expectation(description: "willResignActive")
        willResignActiveExpectation.isInverted = true
    }
    
    override func tearDown() {
        sut.removeObserver(self)
        
        super.tearDown()
    }
    
    func testAddObserver() {
        sut.addObserver(self, selector: #selector(didBecomeActive), name: didBecomeActiveNotification)
        
        NotificationCenter.default.post(Notification(name: didBecomeActiveNotification))
        
        wait(for: [didBecomeActiveExpectation, willResignActiveExpectation], timeout: 0.5)
    }
    
    func testRemoveSpecificObserver() {
        sut.addObserver(self, selector: #selector(didBecomeActive), name: didBecomeActiveNotification)
        sut.addObserver(self, selector: #selector(willResignActive), name: willResignActiveNotification)
        
        sut.removeObserver(self, name: willResignActiveNotification)
        NotificationCenter.default.post(Notification(name: didBecomeActiveNotification))
        
        wait(for: [didBecomeActiveExpectation, willResignActiveExpectation], timeout: 0.5)
    }
    
    func testRemoveObserver() {
        didBecomeActiveExpectation.isInverted = true
        
        sut.addObserver(self, selector: #selector(didBecomeActive), name: didBecomeActiveNotification)
        sut.addObserver(self, selector: #selector(willResignActive), name: willResignActiveNotification)
        
        sut.removeObserver(self)
        NotificationCenter.default.post(Notification(name: didBecomeActiveNotification))
        
        wait(for: [didBecomeActiveExpectation, willResignActiveExpectation], timeout: 0.5)
    }
    
    func didBecomeActive() {
        didBecomeActiveExpectation.fulfill()
    }
    
    func willResignActive() {
        willResignActiveExpectation.fulfill()
    }
}
