import Sentry
import XCTest

class BuzzSentryNoOpSpanTests: XCTestCase {

    func testIsOneInstance() {
        let first = BuzzSentryNoOpSpan.shared()
        let second = BuzzSentryNoOpSpan.shared()
        
        XCTAssertTrue(first === second)
    }
    
    func testStartChild_ReturnsSameInstance() {
        let sut = BuzzSentryNoOpSpan.shared()
        
        let child = sut.startChild(operation: "operation")
        XCTAssertNil(child.context.spanDescription)
        XCTAssertEqual("", child.context.operation)
        XCTAssertTrue(sut === child)
        
        let childWithDescription = sut.startChild(operation: "", description: "descr")
        
        XCTAssertTrue(sut === childWithDescription)
    }

    func testData_StaysNil() {
        let sut = BuzzSentryNoOpSpan.shared()
        XCTAssertNil(sut.data)
        sut.setData(value: "tet", key: "key")
        sut.setExtra(value: "tet", key: "key")
        sut.removeData(key: "any")
        XCTAssertNil(sut.data)
    }
    
    func testTagsStayEmpty_ReturnsEmptyDict() {
        let sut = BuzzSentryNoOpSpan.shared()
        XCTAssertTrue(sut.tags.isEmpty)
        sut.setTag(value: "value", key: "key")
        sut.removeTag(key: "any")
        XCTAssertTrue(sut.tags.isEmpty)
    }
    
    func testIsAlwaysNotFinished() {
        let sut = BuzzSentryNoOpSpan.shared()
        
        XCTAssertFalse(sut.isFinished)
        sut.finish()
        sut.finish(status: BuzzSentrySpanStatus.aborted)
        XCTAssertFalse(sut.isFinished)
    }
    
    func testSerialize_ReturnsEmptyDict() {
        XCTAssertTrue(BuzzSentryNoOpSpan.shared().serialize().isEmpty)
    }
    
    func testToTraceHeader() {
        let actual = BuzzSentryNoOpSpan.shared().toTraceHeader()
        
        XCTAssertEqual(BuzzSentryId.empty, actual.traceId)
        XCTAssertEqual(SpanId.empty, actual.spanId)
        XCTAssertEqual(BuzzSentrySampleDecision.undecided, actual.sampled)
    }
    
    func testContext() {
        let actual = BuzzSentryNoOpSpan.shared().context
        
        XCTAssertEqual(BuzzSentryId.empty, actual.traceId)
        XCTAssertEqual(SpanId.empty, actual.spanId)
        XCTAssertEqual(BuzzSentrySampleDecision.undecided, actual.sampled)
    }

}
