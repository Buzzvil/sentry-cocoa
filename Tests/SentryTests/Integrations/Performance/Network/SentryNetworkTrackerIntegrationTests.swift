import BuzzSentry
import SwiftUI
import XCTest

class BuzzSentryNetworkTrackerIntegrationTests: XCTestCase {
    
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryNetworkTrackerIntegrationTests")
    private static let testBaggageURL = URL(string: "http://localhost:8080/echo-baggage-header")!
    private static let testTraceURL = URL(string: "http://localhost:8080/echo-sentry-trace")!
    private static let clientErrorTraceURL = URL(string: "http://localhost:8080/http-client-error")!
    private static let transactionName = "TestTransaction"
    private static let transactionOperation = "Test"
    
    private class Fixture {
        let dateProvider = TestCurrentDateProvider()
        let options: Options
        
        init() {
            options = Options()
            options.dsn = BuzzSentryNetworkTrackerIntegrationTests.dsnAsString
            options.tracesSampleRate = 1.0
        }
    }
    
    private var fixture: Fixture!
    
    override func setUp() {
        super.setUp()
        fixture = Fixture()
    }

    override func tearDown() {
        super.tearDown()
        clearTestState()
    }
    
    func testNSURLSessionConfiguration_NoActiveSpan_NoHeadersAdded() {
        startSDK()
        
        let configuration = URLSessionConfiguration.default
        
        XCTAssertNil(configuration.httpAdditionalHeaders)
    }
    
    func testNetworkTrackerDisabled_WhenNetworkTrackingDisabled() {
        asserrtNetworkTrackerDisabled { options in
            options.enableNetworkTracking = false
        }
    }
    
    func testNetworkTrackerDisabled_WhenAutoPerformanceTrackingDisabled() {
        asserrtNetworkTrackerDisabled { options in
            options.enableAutoPerformanceTracking = false
        }
    }
    
    func testNetworkTrackerDisabled_WhenTracingDisabled() {
        asserrtNetworkTrackerDisabled { options in
            options.tracesSampleRate = 0.0
        }
    }
    
    func testNetworkTrackerDisabled_WhenSwizzlingDisabled() {
        asserrtNetworkTrackerDisabled { options in
            options.enableSwizzling = false
        }
    }
    
    func test_TracingAndBreadcrumbsDisabled_RemovesEnabledIntegration() {
        let options = Options()
        options.tracesSampleRate = 0.0
        options.enableNetworkBreadcrumbs = false
                
        assertRemovedIntegration(options)
    }
    
    func test_SwizzingDisabled_RemovesEnabledIntegration() {
        let options = Options()
        options.enableSwizzling = false
        
        assertRemovedIntegration(options)
    }
    
    func testBreadcrumbDisabled_WhenSwizzlingDisabled() {
        fixture.options.enableSwizzling = false
        startSDK()
        
        XCTAssertFalse(BuzzSentryNetworkTracker.sharedInstance.isNetworkBreadcrumbEnabled)
    }
    
    func testBreadcrumbDisabled() {
        fixture.options.enableNetworkBreadcrumbs = false
        startSDK()
        
        XCTAssertFalse(BuzzSentryNetworkTracker.sharedInstance.isNetworkBreadcrumbEnabled)
    }
    
    func testBreadcrumbEnabled() {
        startSDK()
        XCTAssertTrue(BuzzSentryNetworkTracker.sharedInstance.isNetworkBreadcrumbEnabled)
    }
    
    /**
     * Reproduces https://github.com/getsentry/sentry-cocoa/issues/1288
     */
    func testCustomURLProtocol_BlocksAllRequests() {
        startSDK()
        
        let expect = expectation(description: "Callback Expectation")
        
        let customConfiguration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        customConfiguration.protocolClasses?.insert(BlockAllRequestsProtocol.self, at: 0)
        let session = URLSession(configuration: customConfiguration)
        
        let dataTask = session.dataTask(with: BuzzSentryNetworkTrackerIntegrationTests.testBaggageURL) { (_, _, error) in
            
            if let error = (error as NSError?) {
                XCTAssertEqual(BlockAllRequestsProtocol.error.domain, error.domain)
                XCTAssertEqual(BlockAllRequestsProtocol.error.code, error.code)
            } else {
                XCTFail("Error expected")
            }
            expect.fulfill()
        }
        
        dataTask.resume()
        wait(for: [expect], timeout: 5)
    }
    
    func flaky_testWhenTaskCancelledOrSuspended_OnlyOneBreadcrumb() {
        startSDK()
        
        let expect = expectation(description: "Callback Expectation")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let dataTask = session.dataTask(with: BuzzSentryNetworkTrackerIntegrationTests.testBaggageURL) { (_, _, _) in
            expect.fulfill()
        }
        
        //There is no way to predict what will happen calling this order of events
        dataTask.resume()
        dataTask.suspend()
        dataTask.resume()
        dataTask.cancel()
        
        wait(for: [expect], timeout: 5)
        
        let scope = BuzzSentrySDK.currentHub().scope
        let breadcrumbs = Dynamic(scope).breadcrumbArray as [Breadcrumb]?
        XCTAssertEqual(1, breadcrumbs?.count)
    }
    
    func testGetRequest_SpanCreatedAndBaggageHeaderAdded_disabled() {
        startSDK()
        let transaction = BuzzSentrySDK.startTransaction(name: "Test Transaction", operation: "TEST", bindToScope: true) as! BuzzSentryTracer
        let expect = expectation(description: "Request completed")
        let session = URLSession(configuration: URLSessionConfiguration.default)

        let dataTask = session.dataTask(with: BuzzSentryNetworkTrackerIntegrationTests.testBaggageURL) { (data, _, _) in
            let response = String(data: data ?? Data(), encoding: .utf8) ?? ""
            
            let expectedBaggageHeader = transaction.traceContext.toBaggage().toHTTPHeader()
            XCTAssertEqual(expectedBaggageHeader, response)

            expect.fulfill()
        }
        
        dataTask.resume()
        wait(for: [expect], timeout: 5)
        
        let children = Dynamic(transaction).children as [Span]?
        
        XCTAssertEqual(children?.count, 1) //Span was created in task resume swizzle.
        let networkSpan = children![0]
        XCTAssertTrue(networkSpan.isFinished) //Span was finished in task setState swizzle.
        XCTAssertEqual(SENTRY_NETWORK_REQUEST_OPERATION, networkSpan.context.operation)
        XCTAssertEqual("GET \(BuzzSentryNetworkTrackerIntegrationTests.testBaggageURL)", networkSpan.context.spanDescription)
        
        XCTAssertEqual("200", networkSpan.tags["http.status_code"])
    }

    func testGetRequest_CompareSentryTraceHeader() {
        startSDK()
        let transaction = BuzzSentrySDK.startTransaction(name: "Test Transaction", operation: "TEST", bindToScope: true) as! BuzzSentryTracer
        let expect = expectation(description: "Request completed")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        var response: String?
        let dataTask = session.dataTask(with: BuzzSentryNetworkTrackerIntegrationTests.testTraceURL) { (data, _, _) in
            response = String(data: data ?? Data(), encoding: .utf8) ?? ""
            expect.fulfill()
        }

        dataTask.resume()
        wait(for: [expect], timeout: 5)

        let children = Dynamic(transaction).children as [BuzzSentrySpan]?

        XCTAssertEqual(children?.count, 1) //Span was created in task resume swizzle.
        let networkSpan = children![0]

        let expectedTraceHeader = networkSpan.toTraceHeader().value()
        XCTAssertEqual(expectedTraceHeader, response)
    }
    
    func testCaptureFailedRequestsDisabled_WhenSwizzlingDisabled() {
        fixture.options.enableSwizzling = false
        fixture.options.enableCaptureFailedRequests = true
        startSDK()

        XCTAssertFalse(SentryNetworkTracker.sharedInstance.isCaptureFailedRequestsEnabled)
    }
    
    func testCaptureFailedRequestsDisabled() {
        startSDK()

        XCTAssertFalse(SentryNetworkTracker.sharedInstance.isCaptureFailedRequestsEnabled)
    }
    
    func testCaptureFailedRequestsEnabled() {
        fixture.options.enableCaptureFailedRequests = true
        startSDK()

        XCTAssertTrue(SentryNetworkTracker.sharedInstance.isCaptureFailedRequestsEnabled)
    }
    
    func testGetCaptureFailedRequestsEnabled() {
        let expect = expectation(description: "Request completed")

        var sentryEvent: Event?

        fixture.options.enableCaptureFailedRequests = true
        fixture.options.failedRequestStatusCodes = [ HttpStatusCodeRange(statusCode: 400) ]
        fixture.options.beforeSend = { event in
            sentryEvent = event
            expect.fulfill()
            return event
        }

        startSDK()

        let session = URLSession(configuration: URLSessionConfiguration.default)

        let dataTask = session.dataTask(with: SentryNetworkTrackerIntegrationTests.clientErrorTraceURL) { (_, _, _) in }

        dataTask.resume()
        wait(for: [expect], timeout: 5)
        
        XCTAssertNotNil(sentryEvent)
        XCTAssertNotNil(sentryEvent!.request)
        
        let sentryResponse = sentryEvent!.context?["response"]

        XCTAssertEqual(sentryResponse?["status_code"] as? NSNumber, 400)
    }
    
    private func asserrtNetworkTrackerDisabled(configureOptions: (Options) -> Void) {
        configureOptions(fixture.options)
        
        startSDK()
        
        let configuration = URLSessionConfiguration.default
        _ = startTransactionBoundToScope()
        XCTAssertNil(configuration.httpAdditionalHeaders)
    }
        
    private func startSDK() {
        BuzzSentrySDK.start(options: self.fixture.options)
    }
    
    private func startTransactionBoundToScope() -> BuzzSentryTracer {
        return BuzzSentrySDK.startTransaction(name: "Test", operation: "test", bindToScope: true) as! BuzzSentryTracer
    }
    
    private func assertRemovedIntegration(_ options: Options) {
        let sut = BuzzSentryNetworkTrackingIntegration()
        let result = sut.install(with: options)
        
        XCTAssertFalse(result)
    }
}

class BlockAllRequestsProtocol: URLProtocol {
    
    static let error = NSError(domain: "network.issue", code: 10, userInfo: nil)
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if client != nil {
            client?.urlProtocol(self, didFailWithError: BlockAllRequestsProtocol.error )
        } else {
            XCTFail("Couldn't block request because client was nil.")
        }
    }

    override func stopLoading() {

    }
}
