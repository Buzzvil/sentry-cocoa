import XCTest

class BuzzSentryMessageTests: XCTestCase {
    
    private class Fixture {
        let stringMaxCount = 8_192
        let maximumCount: String
        let tooLong: String
        let message: BuzzSentryMessage
        
        init() {
            maximumCount = String(repeating: "a", count: stringMaxCount)
            tooLong = String(repeating: "a", count: stringMaxCount + 1)
            
            message = BuzzSentryMessage(formatted: "A message my params")
            message.message = "A message %s %s"
            message.params = ["my", "params"]
        }
        
    }
    
    private let fixture = Fixture()
    
    func testTruncateFormatted() {
        let message = BuzzSentryMessage(formatted: "aaaaa")
        XCTAssertEqual(5, message.formatted.count)
        
        XCTAssertEqual(fixture.stringMaxCount, BuzzSentryMessage(formatted: fixture.maximumCount).formatted.count)
        
        XCTAssertEqual(fixture.stringMaxCount, BuzzSentryMessage(formatted: fixture.tooLong).formatted.count)
    }
    
    func testTruncateMessage() {
        let message = BuzzSentryMessage(formatted: "")
        message.message = "aaaaa %s"
        
        XCTAssertEqual(8, message.message?.count)
        
        message.message = fixture.maximumCount
        XCTAssertEqual(fixture.stringMaxCount, message.message?.count)
        
        message.message = fixture.tooLong
        XCTAssertEqual(fixture.stringMaxCount, message.message?.count)
    }
    
    func testSerialize() {
        let message = fixture.message
        
        let actual = message.serialize()
        
        XCTAssertEqual(message.formatted, actual["formatted"] as? String)
        XCTAssertEqual(message.message, actual["message"] as? String)
        XCTAssertEqual(message.params, actual["params"] as? [String])
    }
    
    func testDescription() {
        let message = fixture.message
        
        let actual = message.description
        
        let beginning = String(format: "<BuzzSentryMessage: %p, ", message)
        let expected = "\(beginning){\n    formatted = \"\(message.formatted)\";\n    message = \"\(message.message ?? "")\";\n    params =     (\n        my,\n        params\n    );\n}>"
        XCTAssertEqual(expected, actual)
    }
    
    func testDescription_WithoutMessageAndParams() {
        let message = fixture.message
        message.message = nil
        message.params = nil
        
        let actual = message.description
        
        let beginning = String(format: "<BuzzSentryMessage: %p, ", message)
        let expected = "\(beginning){\n    formatted = \"\(message.formatted)\";\n}>"
        XCTAssertEqual(expected, actual)
    }
}
