@testable import BuzzSentry
import XCTest

class BuzzSentryIdTests: XCTestCase {
    
    private class Fixture {
        let uuid: UUID
        let uuidV4String: String
        let expectedUUIDV4String: String
        let uuidString: String
        
        init() {
            uuid = UUID()
            uuidV4String = uuid.uuidString.replacingOccurrences(of: "-", with: "")
            expectedUUIDV4String = uuidV4String.lowercased()
            uuidString = uuid.uuidString
        }
    }
    
    private var fixture = Fixture()
    
    func testInit() {
        XCTAssertNotEqual(BuzzSentryId(), BuzzSentryId())
    }

    func testInitWithUUID_ValidIdString() {
        let BuzzSentryId = BuzzSentryId(uuid: fixture.uuid)
        
        XCTAssertEqual(fixture.expectedUUIDV4String, BuzzSentryId.buzzSentryIdString)
    }
    
    func testInitWithUUIDString_ValidIdString() {
        let BuzzSentryIdWithUUIDString = BuzzSentryId(uuidString: fixture.uuidString)
        let BuzzSentryIdWithUUID = BuzzSentryId(uuid: fixture.uuid)
        
        XCTAssertEqual(BuzzSentryIdWithUUID, BuzzSentryIdWithUUIDString)
    }
    
    func testInitWithUUIDV4String_ValidIdString() {
        let BuzzSentryIdWithUUIDString = BuzzSentryId(uuidString: fixture.uuidV4String)
        let BuzzSentryIdWithUUID = BuzzSentryId(uuid: fixture.uuid)
        
        XCTAssertEqual(BuzzSentryIdWithUUID, BuzzSentryIdWithUUIDString)
    }
    
    func testInitWithUUIDV4LowercaseString_ValidIdString() {
        let BuzzSentryIdWithUUIDString = BuzzSentryId(uuidString: fixture.expectedUUIDV4String)
        let BuzzSentryIdWithUUID = BuzzSentryId(uuid: fixture.uuid)
        
        XCTAssertEqual(BuzzSentryIdWithUUID, BuzzSentryIdWithUUIDString)
    }
    
    func testInitWithInvalidUUIDString_InvalidIdString() {
        XCTAssertEqual(BuzzSentryId.empty, BuzzSentryId(uuidString: "wrong"))
    }
    
    func testInitWithInvalidUUIDString36Chars_InvalidIdString() {
        XCTAssertEqual(BuzzSentryId.empty, BuzzSentryId(uuidString: "00000000-0000-0000-0000-0-0000000000"))
    }
    
    func testInitWithEmptyUUIDString_EmptyIdString() {
        XCTAssertEqual(BuzzSentryId.empty, BuzzSentryId(uuidString: ""))
    }
    
    func testIsEqualWithSameObject() {
        let BuzzSentryId = BuzzSentryId()
        XCTAssertEqual(BuzzSentryId, BuzzSentryId)
    }
    
    func testIsNotEqualWithDifferentClass() {
        let BuzzSentryId = BuzzSentryId()
        XCTAssertFalse(BuzzSentryId.isEqual(1))
    }
    
    func testHash_IsSameWhenObjectsAreEqual() {
        let uuid = UUID()
        XCTAssertEqual(BuzzSentryId(uuid: uuid).hash, BuzzSentryId(uuid: uuid).hash)
    }
    
    func testHash_IsDifferentWhenObjectsAreDifferent() {
        XCTAssertNotEqual(BuzzSentryId(uuid: UUID()).hash, BuzzSentryId(uuid: fixture.uuid).hash)
    }
}
