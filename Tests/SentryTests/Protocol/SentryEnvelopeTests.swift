import XCTest

class BuzzSentryEnvelopeTests: XCTestCase {
    
    private class Fixture {
        let sdkVersion = "sdkVersion"
        let userFeedback: UserFeedback
        let path = "test.log"
        let data = "hello".data(using: .utf8)
        
        let maxAttachmentSize: UInt = 5 * 1_024 * 1_024
        let dataAllowed: Data
        let dataTooBig: Data
        
        init() {
            userFeedback = UserFeedback(eventId: SentryId())
            userFeedback.comments = "It doesn't work!"
            userFeedback.email = "john@me.com"
            userFeedback.name = "John Me"
            
            dataAllowed = Data([UInt8](repeating: 1, count: Int(maxAttachmentSize)))
            dataTooBig = Data([UInt8](repeating: 1, count: Int(maxAttachmentSize) + 1))
        }

        var breadcrumb: Breadcrumb {
            get {
                let crumb = Breadcrumb(level: SentryLevel.debug, category: "ui.lifecycle")
                crumb.message = "first breadcrumb"
                return crumb
            }
        }

        var event: Event {
            let event = Event()
            event.level = SentryLevel.info
            event.message = SentryMessage(formatted: "Don't do this")
            event.releaseName = "releaseName1.0.0"
            event.environment = "save the environment"
            event.sdk = ["version": sdkVersion, "date": Date()]
            return event
        }

        var eventWithContinousSerializationFailure: Event {
            let event = EventSerializationFailure()
            event.message = SentryMessage(formatted: "Failure")
            event.releaseName = "release"
            event.environment = "environment"
            event.platform = "platform"
            return event
        }
    }

    private let fixture = Fixture()

    override func setUp() {
        super.setUp()
        CurrentDate.setCurrentDateProvider(TestCurrentDateProvider())
    }
    
    override func tearDown() {
        super.tearDown()
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: fixture.path) {
                try fileManager.removeItem(atPath: fixture.path)
            }
        } catch {
            XCTFail("Couldn't delete files.")
        }
    }

    private let defaultSdkInfo = SentrySdkInfo(name: BuzzSentryMeta.sdkName, andVersion: BuzzSentryMeta.versionString)
    
    func testBuzzSentryEnvelopeFromEvent() {
        let event = Event()
        
        let item = BuzzSentryEnvelopeItem(event: event)
        let envelope = BuzzSentryEnvelope(id: event.eventId, singleItem: item)
        
        XCTAssertEqual(event.eventId, envelope.header.eventId)
        XCTAssertEqual(1, envelope.items.count)
        XCTAssertEqual("event", envelope.items[0].header.type)
        
        let json = try! JSONSerialization.data(withJSONObject: event.serialize(), options: JSONSerialization.WritingOptions(rawValue: 0))
        
        assertJsonIsEqual(actual: json, expected: envelope.items[0].data)
    }
    
    func testBuzzSentryEnvelopeWithExplicitInitMessages() {
        let attachment = "{}"
        let data = attachment.data(using: .utf8)!
        
        let itemHeader = BuzzSentryEnvelopeItemHeader(type: "attachment", length: UInt(data.count))
        let item = BuzzSentryEnvelopeItem(header: itemHeader, data: data)
        
        let envelopeId = SentryId()
        let header = BuzzSentryEnvelopeHeader(id: envelopeId)
        let envelope = BuzzSentryEnvelope(header: header, singleItem: item)
        
        XCTAssertEqual(envelopeId, envelope.header.eventId)
        XCTAssertEqual(1, envelope.items.count)
        XCTAssertEqual("attachment", envelope.items[0].header.type)
        XCTAssertEqual(attachment.count, Int(envelope.items[0].header.length))
        
        XCTAssertEqual(data, envelope.items[0].data)
    }
    
    func testBuzzSentryEnvelopeWithExplicitInitMessagesMultipleItems() {
        var items: [BuzzSentryEnvelopeItem] = []
        let itemCount = 3
        var attachment = ""
        attachment += UUID().uuidString

        for _ in 0..<itemCount {
            attachment += UUID().uuidString
            let data = attachment.data(using: .utf8)!
            let itemHeader = BuzzSentryEnvelopeItemHeader(type: "attachment", length: UInt(data.count))
            let item = BuzzSentryEnvelopeItem(header: itemHeader, data: data)
            items.append(item)
        }

        let envelopeId = SentryId()
        let envelope = BuzzSentryEnvelope(id: envelopeId, items: items)

        XCTAssertEqual(envelopeId, envelope.header.eventId)
        XCTAssertEqual(itemCount, envelope.items.count)

        for i in 0..<itemCount {
            XCTAssertEqual("attachment", envelope.items[i].header.type)
        }
    }
    
    func testInitBuzzSentryEnvelopeHeader_DefaultSdkInfoIsSet() {
        XCTAssertEqual(defaultSdkInfo, BuzzSentryEnvelopeHeader(id: nil).sdkInfo)
    }
    
    func testInitBuzzSentryEnvelopeHeader_IdAndSkInfoNil() {
        let allNil = BuzzSentryEnvelopeHeader(id: nil, sdkInfo: nil, traceContext: nil)
        XCTAssertNil(allNil.eventId)
        XCTAssertNil(allNil.sdkInfo)
        XCTAssertNil(allNil.traceContext)
    }
    
    func testInitBuzzSentryEnvelopeHeader_IdAndTraceStateNil() {
        let allNil = BuzzSentryEnvelopeHeader(id: nil, traceContext: nil)
        XCTAssertNil(allNil.eventId)
        XCTAssertNotNil(allNil.sdkInfo)
        XCTAssertNil(allNil.traceContext)
    }
    
    func testInitBuzzSentryEnvelopeHeader_SetIdAndSdkInfo() {
        let eventId = SentryId()
        let sdkInfo = SentrySdkInfo(name: "sdk", andVersion: "1.2.3-alpha.0")
        
        let envelopeHeader = BuzzSentryEnvelopeHeader(id: eventId, sdkInfo: sdkInfo, traceContext: nil)
        XCTAssertEqual(eventId, envelopeHeader.eventId)
        XCTAssertEqual(sdkInfo, envelopeHeader.sdkInfo)
    }
    
    func testInitBuzzSentryEnvelopeHeader_SetIdAndTraceState() {
        let eventId = SentryId()
        let traceContext = BuzzSentryTraceContext(trace: SentryId(), publicKey: "publicKey", releaseName: "releaseName", environment: "environment", transaction: "transaction", userSegment: nil, sampleRate: nil)
        
        let envelopeHeader = BuzzSentryEnvelopeHeader(id: eventId, traceContext: traceContext)
        XCTAssertEqual(eventId, envelopeHeader.eventId)
        XCTAssertEqual(traceContext, envelopeHeader.traceContext)
    }
    
    func testInitBuzzSentryEnvelopeWithSession_DefaultSdkInfoIsSet() {
        let envelope = BuzzSentryEnvelope(session: BuzzSentrySession(releaseName: "1.1.1"))
        
        XCTAssertEqual(defaultSdkInfo, envelope.header.sdkInfo)
    }

    func testInitWithEvent() throws {
        let event = fixture.event
        let envelope = BuzzSentryEnvelope(event: event)

        let expectedData = try SentrySerialization.data(withJSONObject: event.serialize())

        XCTAssertEqual(event.eventId, envelope.header.eventId)
        XCTAssertEqual(1, envelope.items.count)
        let actual = String(data: envelope.items.first?.data ?? Data(), encoding: .utf8)?.sorted()
        let expected = String(data: expectedData, encoding: .utf8)?.sorted()
        XCTAssertEqual(expected, actual)
    }

    func testInitWithEvent_SerializationFails_SendsEventWithSerializationFailure() {
        let event = fixture.eventWithContinousSerializationFailure
        let envelope = BuzzSentryEnvelope(event: event)

        XCTAssertEqual(1, envelope.items.count)
        XCTAssertNotNil(envelope.items.first?.data)
        if let data = envelope.items.first?.data {
            let json = String(data: data, encoding: .utf8) ?? ""

            // Asserting the description of the message doesn't work properly, because
            // the serialization adds \n. Therefore, we only check for bits of the
            // the description. The actual description is tested in the tests for the
            // SentryMessage
            json.assertContains("JSON conversion error for event with message: '<SentryMessage: ", "message")
            json.assertContains("formatted = \(event.message?.formatted ?? "")", "message")
            
            json.assertContains("warning", "level")
            json.assertContains(event.releaseName ?? "", "releaseName")
            json.assertContains(event.environment ?? "", "environment")
            
            json.assertContains(String(format: "%.0f", CurrentDate.date().timeIntervalSince1970), "timestamp")
        }
    }
    
    func testInitWithUserFeedback() throws {
        let userFeedback = fixture.userFeedback
        
        let envelope = BuzzSentryEnvelope(userFeedback: userFeedback)
        XCTAssertEqual(userFeedback.eventId, envelope.header.eventId)
        XCTAssertEqual(defaultSdkInfo, envelope.header.sdkInfo)
        
        XCTAssertEqual(1, envelope.items.count)
        let item = envelope.items.first
        XCTAssertEqual("user_report", item?.header.type)
        XCTAssertNotNil(item?.data)
        
        let expectedData = try SentrySerialization.data(withJSONObject: userFeedback.serialize())

        let actual = String(data: item?.data ?? Data(), encoding: .utf8)?.sorted()
        let expected = String(data: expectedData, encoding: .utf8)?.sorted()
        XCTAssertEqual(expected, actual)
    }
    
    func testInitWithDataAttachment() {
        let attachment = TestData.dataAttachment
        
        let envelopeItem = BuzzSentryEnvelopeItem(attachment: attachment, maxAttachmentSize: fixture.maxAttachmentSize)!
        
        XCTAssertEqual("attachment", envelopeItem.header.type)
        XCTAssertEqual(UInt(attachment.data?.count ?? 0), envelopeItem.header.length)
        XCTAssertEqual(attachment.filename, envelopeItem.header.filename)
        XCTAssertEqual(attachment.contentType, envelopeItem.header.contentType)
    }
    
    func testInitWithFileAttachment() {
        writeDataToFile(data: fixture.data ?? Data())
        
        let attachment = Attachment(path: fixture.path)
        
        let envelopeItem = BuzzSentryEnvelopeItem(attachment: attachment, maxAttachmentSize: fixture.maxAttachmentSize)!
        
        XCTAssertEqual("attachment", envelopeItem.header.type)
        XCTAssertEqual(UInt(fixture.data?.count ?? 0), envelopeItem.header.length)
        XCTAssertEqual(attachment.filename, envelopeItem.header.filename)
        XCTAssertEqual(attachment.contentType, envelopeItem.header.contentType)
    }
    
    func testInitWithNonExistentFileAttachment() {
        let attachment = Attachment(path: fixture.path)
        
        let envelopeItem = BuzzSentryEnvelopeItem(attachment: attachment, maxAttachmentSize: fixture.maxAttachmentSize)
        
        XCTAssertNil(envelopeItem)
    }
    
    func testInitWithFileAttachment_MaxAttachmentSize() {
        writeDataToFile(data: fixture.dataAllowed)
        XCTAssertNotNil(BuzzSentryEnvelopeItem(attachment: Attachment(path: fixture.path), maxAttachmentSize: fixture.maxAttachmentSize))
        
        writeDataToFile(data: fixture.dataTooBig)
        XCTAssertNil(BuzzSentryEnvelopeItem(attachment: Attachment(path: fixture.path), maxAttachmentSize: fixture.maxAttachmentSize))
    }
    
    func testInitWithDataAttachment_MaxAttachmentSize() {
        let attachmentTooBig = Attachment(data: fixture.dataTooBig, filename: "")
        XCTAssertNil(
            BuzzSentryEnvelopeItem(attachment: attachmentTooBig, maxAttachmentSize: fixture.maxAttachmentSize))
        
        let attachment = Attachment(data: fixture.dataAllowed, filename: "")
        XCTAssertNotNil(
            BuzzSentryEnvelopeItem(attachment: attachment, maxAttachmentSize: fixture.maxAttachmentSize))
    }
    
    private func writeDataToFile(data: Data) {
        do {
            try data.write(to: URL(fileURLWithPath: fixture.path))
        } catch {
            XCTFail("Failed to store attachment.")
        }
    }

    private func assertEventDoesNotContainContext(_ json: String) {
        XCTAssertFalse(json.contains("\"contexts\":{"))
    }

    private class EventSerializationFailure: Event {
        override func serialize() -> [String: Any] {
            return ["is going": ["to fail": Date()]]
        }
    }
}

fileprivate extension String {
    func assertContains(_ value: String, _ fieldName: String) {
        XCTAssertTrue(self.contains(value), "The JSON doesn't contain the \(fieldName): '\(value)' \n \(self)")
    }
}
