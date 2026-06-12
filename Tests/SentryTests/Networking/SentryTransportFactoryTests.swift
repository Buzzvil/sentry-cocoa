import BuzzSentry
import XCTest

class BuzzSentryTransportFactoryTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryTransportFactoryTests")

    func testIntegration_UrlSessionDelegate_PassedToRequestManager() {
        let urlSessionDelegateSpy = UrlSessionDelegateSpy()
        
        let expect = expectation(description: "UrlSession Delegate of Options called in RequestManager")
        urlSessionDelegateSpy.delegateCallback = {
            expect.fulfill()
        }
        
        let options = Options()
        options.dsn = BuzzSentryTransportFactoryTests.dsnAsString
        options.urlSessionDelegate = urlSessionDelegateSpy
        
        let fileManager = try! BuzzSentryFileManager(options: options, andCurrentDateProvider: TestCurrentDateProvider())
        let transport = TransportInitializer.initTransport(options, buzzSentryFileManager: fileManager)
        let requestManager = Dynamic(transport).requestManager.asObject as! BuzzSentryQueueableRequestManager
        
        let imgUrl = URL(string: "https://github.com")!
        let request = URLRequest(url: imgUrl)
        
        requestManager.add(request) { _, _ in /* We don't care about the result */ }
        wait(for: [expect], timeout: 10)
    }
}
