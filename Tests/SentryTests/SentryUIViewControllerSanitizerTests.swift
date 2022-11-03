import XCTest

class BuzzSentryUIViewControllerSanitizerTests: XCTestCase {
    
    func testSanitizeViewControllerNameWithBaseObject() {
        let object = NSObject()
        let name = sanitize(object)
        
        XCTAssertEqual(name, "NSObject")
    }
    
    func testSanitizeViewControllerNameWithSentryObject() {
        let object = Options()
        let name = sanitize(object)
        
        XCTAssertEqual(name, "BuzzSentryOptions")
    }
    
    func testSanitizeViewControllerNameWithStrings() {
        XCTAssertEqual(
            "sentry_ios_cocoapods.ViewController", sanitize("<sentry_ios_cocoapods.ViewController: 0x7fd9201253c0>")
        )
        
        XCTAssertEqual(
            "sentry_ios_cocoapodsViewController: 0x7fd9201253c0", sanitize("sentry_ios_cocoapodsViewController: 0x7fd9201253c0")
        )
        
        XCTAssertEqual(
            "sentry_ios_cocoapods.ViewController.miau", sanitize("<sentry_ios_cocoapods.ViewController.miau: 0x7fd9201253c0>")
        )
        
    }
    
    private func sanitize(_ name: Any) -> String {
        return BuzzSentryUIViewControllerSanitizer.sanitizeViewControllerName(name)
    }
}
