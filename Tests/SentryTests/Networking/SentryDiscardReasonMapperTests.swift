import Foundation
import XCTest

class BuzzSentryDiscardReasonMapperTests: XCTestCase {
    func testMapReasonToName() {
        XCTAssertEqual(kBuzzSentryDiscardReasonNameBeforeSend, nameForBuzzSentryDiscardReason(.beforeSend))
        XCTAssertEqual(kBuzzSentryDiscardReasonNameEventProcessor, nameForBuzzSentryDiscardReason(.eventProcessor))
        XCTAssertEqual(kBuzzSentryDiscardReasonNameSampleRate, nameForBuzzSentryDiscardReason(.sampleRate))
        XCTAssertEqual(kBuzzSentryDiscardReasonNameNetworkError, nameForBuzzSentryDiscardReason(.networkError))
        XCTAssertEqual(kBuzzSentryDiscardReasonNameQueueOverflow, nameForBuzzSentryDiscardReason(.queueOverflow))
        XCTAssertEqual(kBuzzSentryDiscardReasonNameCacheOverflow, nameForBuzzSentryDiscardReason(.cacheOverflow))
        XCTAssertEqual(kBuzzSentryDiscardReasonNameRateLimitBackoff, nameForBuzzSentryDiscardReason(.rateLimitBackoff))
    }
}
