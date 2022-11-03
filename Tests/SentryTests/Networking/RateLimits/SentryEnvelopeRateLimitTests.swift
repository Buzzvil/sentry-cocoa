import XCTest

class BuzzSentryEnvelopeRateLimitTests: XCTestCase {
    
    private var rateLimits: TestRateLimits!
// swiftlint:disable weak_delegate
// Swiftlint automatically changes this to a weak reference,
// but we need a strong reference to make the test work.
    private var delegate: TestEnvelopeRateLimitDelegate!
// swiftlint:enable weak_delegate
    private var sut: EnvelopeRateLimit!
    
    override func setUp() {
        super.setUp()
        rateLimits = TestRateLimits()
        delegate = TestEnvelopeRateLimitDelegate()
        sut = EnvelopeRateLimit(rateLimits: rateLimits)
        sut.setDelegate(delegate)
    }
    
    func testNoLimitsActive() {
        let envelope = getEnvelope()
        
        let actual = sut.removeRateLimitedItems(envelope)
        
        XCTAssertEqual(envelope, actual)
    }
    
    func testLimitForErrorActive() {
        rateLimits.rateLimits = [BuzzSentryDataCategory.error]
        
        let envelope = getEnvelope()
        let actual = sut.removeRateLimitedItems(envelope)
        
        XCTAssertEqual(3, actual.items.count)
        for item in actual.items {
            XCTAssertEqual(BuzzSentryEnvelopeItemTypeSession, item.header.type)
        }
        XCTAssertEqual(envelope.header, actual.header)
        
        XCTAssertEqual(3, delegate.envelopeItemsDropped.count)
        let expected = [BuzzSentryDataCategory.error, BuzzSentryDataCategory.error, BuzzSentryDataCategory.error]
        XCTAssertEqual(expected, delegate.envelopeItemsDropped.invocations)
    }
    
    func testLimitForSessionActive() {
        rateLimits.rateLimits = [BuzzSentryDataCategory.session]
        
        let envelope = getEnvelope()
        let actual = sut.removeRateLimitedItems(envelope)
        
        XCTAssertEqual(3, actual.items.count)
        for item in actual.items {
            XCTAssertEqual(BuzzSentryEnvelopeItemTypeEvent, item.header.type)
        }
        XCTAssertEqual(envelope.header, actual.header)
        
        XCTAssertEqual(3, delegate.envelopeItemsDropped.count)
        let expected = [BuzzSentryDataCategory.session, BuzzSentryDataCategory.session, BuzzSentryDataCategory.session]
        XCTAssertEqual(expected, delegate.envelopeItemsDropped.invocations)
    }
    
    func testLimitForCustomType() {
        rateLimits.rateLimits = [BuzzSentryDataCategory.default]
        var envelopeItems = [BuzzSentryEnvelopeItem]()
        envelopeItems.append(BuzzSentryEnvelopeItem(event: Event()))
        
        let envelopeHeader = BuzzSentryEnvelopeItemHeader(type: "customType", length: 10)
        envelopeItems.append(BuzzSentryEnvelopeItem(header: envelopeHeader, data: Data()))
        envelopeItems.append(BuzzSentryEnvelopeItem(header: envelopeHeader, data: Data()))
        
        let envelope = BuzzSentryEnvelope(id: SentryId(), items: envelopeItems)
        
        let actual = sut.removeRateLimitedItems(envelope)
        
        XCTAssertEqual(1, actual.items.count)
        XCTAssertEqual(BuzzSentryEnvelopeItemTypeEvent, actual.items[0].header.type)
    }
    
    func getEnvelope() -> BuzzSentryEnvelope {
        var envelopeItems = [BuzzSentryEnvelopeItem]()
        for _ in 0...2 {
            let event = Event()
            envelopeItems.append(BuzzSentryEnvelopeItem(event: event))
        }
        
        for _ in 0...2 {
            let session = SentrySession(releaseName: "")
            envelopeItems.append(BuzzSentryEnvelopeItem(session: session))
        }
        
        return BuzzSentryEnvelope(id: SentryId(), items: envelopeItems)
    }
    
}
