import XCTest

class BuzzSentryDispatchQueueWrapperTests: XCTestCase {

    func testDispatchOnce() {
        var a = 0
        
        var firstWasCalled = false
        var secondWasCalled = false
        var thirdWasCalled = false
        
        let sut = BuzzSentryDispatchQueueWrapper()
        sut.dispatchOnce(&a) {
            firstWasCalled = true
        }
        sut.dispatchOnce(&a) {
            secondWasCalled = true
        }
        
        var b = 0
        sut.dispatchOnce(&b) {
            thirdWasCalled = true
        }
        
        XCTAssertTrue(firstWasCalled)
        XCTAssertFalse(secondWasCalled)
        XCTAssertTrue(thirdWasCalled)
    }
}
