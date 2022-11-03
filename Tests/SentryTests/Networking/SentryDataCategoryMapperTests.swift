@testable import Sentry
import XCTest

class BuzzSentryDataCategoryMapperTests: XCTestCase {
    func testEnvelopeItemType() {
        XCTAssertEqual(.error, BuzzSentryDataCategoryForEnvelopItemType("event"))
        XCTAssertEqual(.session, BuzzSentryDataCategoryForEnvelopItemType("session"))
        XCTAssertEqual(.transaction, BuzzSentryDataCategoryForEnvelopItemType("transaction"))
        XCTAssertEqual(.attachment, BuzzSentryDataCategoryForEnvelopItemType("attachment"))
        XCTAssertEqual(.profile, BuzzSentryDataCategoryForEnvelopItemType("profile"))
        XCTAssertEqual(.default, BuzzSentryDataCategoryForEnvelopItemType("unknown item type"))
    }

    func testMapIntegerToCategory() {
        XCTAssertEqual(.all, BuzzSentryDataCategoryForNSUInteger(0))
        XCTAssertEqual(.default, BuzzSentryDataCategoryForNSUInteger(1))
        XCTAssertEqual(.error, BuzzSentryDataCategoryForNSUInteger(2))
        XCTAssertEqual(.session, BuzzSentryDataCategoryForNSUInteger(3))
        XCTAssertEqual(.transaction, BuzzSentryDataCategoryForNSUInteger(4))
        XCTAssertEqual(.attachment, BuzzSentryDataCategoryForNSUInteger(5))
        XCTAssertEqual(.userFeedback, BuzzSentryDataCategoryForNSUInteger(6))
        XCTAssertEqual(.profile, BuzzSentryDataCategoryForNSUInteger(7))
        XCTAssertEqual(.unknown, BuzzSentryDataCategoryForNSUInteger(8))

        XCTAssertEqual(.unknown, BuzzSentryDataCategoryForNSUInteger(9), "Failed to map unknown category number to case .unknown")
    }
    
    func testMapStringToCategory() {
        XCTAssertEqual(.all, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameAll))
        XCTAssertEqual(.default, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameDefault))
        XCTAssertEqual(.error, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameError))
        XCTAssertEqual(.session, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameSession))
        XCTAssertEqual(.transaction, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameTransaction))
        XCTAssertEqual(.attachment, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameAttachment))
        XCTAssertEqual(.userFeedback, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameUserFeedback))
        XCTAssertEqual(.profile, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameProfile))
        XCTAssertEqual(.unknown, BuzzSentryDataCategoryForString(kBuzzSentryDataCategoryNameUnknown))

        XCTAssertEqual(.unknown, BuzzSentryDataCategoryForString("gdfagdfsa"), "Failed to map unknown category name to case .unknown")
    }

    func testMapCategoryToString() {
        XCTAssertEqual(kBuzzSentryDataCategoryNameAll, nameForBuzzSentryDataCategory(.all))
        XCTAssertEqual(kBuzzSentryDataCategoryNameDefault, nameForBuzzSentryDataCategory(.default))
        XCTAssertEqual(kBuzzSentryDataCategoryNameError, nameForBuzzSentryDataCategory(.error))
        XCTAssertEqual(kBuzzSentryDataCategoryNameSession, nameForBuzzSentryDataCategory(.session))
        XCTAssertEqual(kBuzzSentryDataCategoryNameTransaction, nameForBuzzSentryDataCategory(.transaction))
        XCTAssertEqual(kBuzzSentryDataCategoryNameAttachment, nameForBuzzSentryDataCategory(.attachment))
        XCTAssertEqual(kBuzzSentryDataCategoryNameUserFeedback, nameForBuzzSentryDataCategory(.userFeedback))
        XCTAssertEqual(kBuzzSentryDataCategoryNameProfile, nameForBuzzSentryDataCategory(.profile))
        XCTAssertEqual(kBuzzSentryDataCategoryNameUnknown, nameForBuzzSentryDataCategory(.unknown))
    }
}
