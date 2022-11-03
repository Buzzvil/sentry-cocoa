import XCTest

class BuzzSentrySerializationTests: XCTestCase {
    
    private class Fixture {
        static var invalidData = "hi".data(using: .utf8)!
        static var traceContext = BuzzSentryTraceContext(trace: BuzzSentryId(), publicKey: "PUBLIC_KEY", releaseName: "RELEASE_NAME", environment: "TEST", transaction: "transaction", userSegment: "some segment", sampleRate: "0.25")
    }

    func testBuzzSentryEnvelopeSerializer_WithSingleEvent() {
        // Arrange
        let event = Event()

        let item = BuzzSentryEnvelopeItem(event: event)
        let envelope = BuzzSentryEnvelope(id: event.eventId, singleItem: item)
        // Sanity check
        XCTAssertEqual(event.eventId, envelope.header.eventId)
        XCTAssertEqual(1, envelope.items.count)
        XCTAssertEqual("event", envelope.items[0].header.type)

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertEqual(envelope.header.eventId, deserializedEnvelope.header.eventId)
            assertDefaultSdkInfoSet(deserializedEnvelope: deserializedEnvelope)
            XCTAssertEqual(1, deserializedEnvelope.items.count)
            XCTAssertEqual("event", envelope.items[0].header.type)
            XCTAssertEqual(envelope.items[0].header.length, deserializedEnvelope.items[0].header.length)
            XCTAssertEqual(envelope.items[0].data, deserializedEnvelope.items[0].data)
            XCTAssertNil(deserializedEnvelope.header.traceContext)
        }
    }

    func testBuzzSentryEnvelopeSerializer_WithManyItems() {
        // Arrange
        let itemsCount = 15
        var items: [BuzzSentryEnvelopeItem] = []
        for i in 0..<itemsCount {
            let bodyChar = "\(i)"
            let bodyString = bodyChar.padding(
                    toLength: i + 1,
                    withPad: bodyChar,
                    startingAt: 0)

            let itemData = bodyString.data(using: .utf8)!
            let itemHeader = BuzzSentryEnvelopeItemHeader(type: bodyChar, length: UInt(itemData.count))
            let item = BuzzSentryEnvelopeItem(
                    header: itemHeader,
                    data: itemData)
            items.append(item)
        }

        let envelope = BuzzSentryEnvelope(id: nil, items: items)
        // Sanity check
        XCTAssertNil(envelope.header.eventId)
        XCTAssertEqual(itemsCount, Int(envelope.items.count))

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertNil(deserializedEnvelope.header.eventId)
            XCTAssertEqual(itemsCount, deserializedEnvelope.items.count)
            assertDefaultSdkInfoSet(deserializedEnvelope: deserializedEnvelope)

            for j in 0..<itemsCount {
                XCTAssertEqual("\(j)", envelope.items[j].header.type)
                XCTAssertEqual(
                        envelope.items[j].header.length,
                        deserializedEnvelope.items[j].header.length)
                XCTAssertEqual(envelope.items[j].data, deserializedEnvelope.items[j].data)
            }
        }
    }

    func testBuzzSentryEnvelopeSerializesWithZeroByteItem() {
        // Arrange
        let itemData = Data()
        let itemHeader = BuzzSentryEnvelopeItemHeader(type: "attachment", length: UInt(itemData.count))

        let item = BuzzSentryEnvelopeItem(header: itemHeader, data: itemData)
        let envelope = BuzzSentryEnvelope(id: nil, singleItem: item)

        // Sanity check
        XCTAssertEqual(1, envelope.items.count)
        XCTAssertEqual("attachment", envelope.items[0].header.type)
        XCTAssertEqual(0, Int(envelope.items[0].header.length))

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertEqual(1, deserializedEnvelope.items.count)
            XCTAssertEqual("attachment", deserializedEnvelope.items[0].header.type)
            XCTAssertEqual(0, deserializedEnvelope.items[0].header.length)
            XCTAssertEqual(0, deserializedEnvelope.items[0].data.count)
            assertDefaultSdkInfoSet(deserializedEnvelope: deserializedEnvelope)
        }
    }

    func testBuzzSentryEnvelopeSerializer_SdkInfo() {
        let sdkInfo = BuzzSentrySDKInfo(name: "sentry.cocoa", andVersion: "5.0.1")
        let envelopeHeader = BuzzSentryEnvelopeHeader(id: nil, sdkInfo: sdkInfo, traceContext: nil)
        let envelope = BuzzSentryEnvelope(header: envelopeHeader, singleItem: createItemWithEmptyAttachment())

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertEqual(sdkInfo, deserializedEnvelope.header.sdkInfo)
        }
    }
    
    func testBuzzSentryEnvelopeSerializer_TraceState() {
        let envelopeHeader = BuzzSentryEnvelopeHeader(id: nil, traceContext: Fixture.traceContext)
        let envelope = BuzzSentryEnvelope(header: envelopeHeader, singleItem: createItemWithEmptyAttachment())

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertNotNil(deserializedEnvelope.header.traceContext)
            assertTraceState(firstTrace: Fixture.traceContext, secondTrace: deserializedEnvelope.header.traceContext!)
        }
    }
    
    func testBuzzSentryEnvelopeSerializer_TraceStateWithoutUser() {
        let trace = BuzzSentryTraceContext(trace: BuzzSentryId(), publicKey: "PUBLIC_KEY", releaseName: "RELEASE_NAME", environment: "TEST", transaction: "transaction", userSegment: nil, sampleRate: nil)
        
        let envelopeHeader = BuzzSentryEnvelopeHeader(id: nil, traceContext: trace)
        let envelope = BuzzSentryEnvelope(header: envelopeHeader, singleItem: createItemWithEmptyAttachment())

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertNotNil(deserializedEnvelope.header.traceContext)
            assertTraceState(firstTrace: trace, secondTrace: deserializedEnvelope.header.traceContext!)
        }
    }
    
    func testBuzzSentryEnvelopeSerializer_SdkInfoIsNil() {
        let envelopeHeader = BuzzSentryEnvelopeHeader(id: nil, sdkInfo: nil, traceContext: nil)
        let envelope = BuzzSentryEnvelope(header: envelopeHeader, singleItem: createItemWithEmptyAttachment())

        assertEnvelopeSerialization(envelope: envelope) { deserializedEnvelope in
            XCTAssertNil(deserializedEnvelope.header.sdkInfo)
        }
    }

    func testBuzzSentryEnvelopeSerializer_ZeroByteItemReturnsEnvelope() {
        let itemData = "{}\n{\"length\":0,\"type\":\"attachment\"}\n".data(using: .utf8)!
        XCTAssertNotNil(BuzzSentrySerialization.envelope(with: itemData))
    }

    func testBuzzSentryEnvelopeSerializer_EnvelopeWithHeaderAndItemWithAttachmet() {
        let eventId = BuzzSentryId(uuidString: "12c2d058-d584-4270-9aa2-eca08bf20986")
        let payloadAsString = "helloworld"

        let itemData = """
                       {\"event_id\":\"\(eventId)\"}
                       {\"length\":10,\"type\":\"attachment\"}
                       \(payloadAsString)
                       """.data(using: .utf8)!

        if let envelope = BuzzSentrySerialization.envelope(with: itemData) {
            XCTAssertEqual(eventId, envelope.header.eventId!)

            XCTAssertEqual(1, envelope.items.count)
            let item = envelope.items[0]
            XCTAssertEqual(10, item.header.length)
            XCTAssertEqual("attachment", item.header.type)
            XCTAssertEqual(payloadAsString.data(using: .utf8), item.data)
        } else {
            XCTFail("Failed to deserialize envelope")
        }
    }

    func testBuzzSentryEnvelopeSerializer_ItemWithoutTypeReturnsNil() {
        let itemData = "{}\n{\"length\":0}".data(using: .utf8)!
        XCTAssertNil(BuzzSentrySerialization.envelope(with: itemData))
    }

    func testBuzzSentryEnvelopeSerializer_WithoutItemReturnsNil() {
        let itemData = "{}\n".data(using: .utf8)!
        XCTAssertNil(BuzzSentrySerialization.envelope(with: itemData))
    }

    func testBuzzSentryEnvelopeSerializer_WithoutLineBreak() {
        let itemData = "{}".data(using: .utf8)!
        XCTAssertNil(BuzzSentrySerialization.envelope(with: itemData))
    }
    
    func testSerializeSession() throws {
        let dict = BuzzSentrySession(releaseName: "1.0.0").serialize()
        let session = BuzzSentrySession(jsonObject: dict)!
        
        let data = try BuzzSentrySerialization.data(with: session)
        
        XCTAssertNotNil(BuzzSentrySerialization.session(with: data))
    }
    
    func testSerializeSessionWithNoReleaseName() throws {
        var dict = BuzzSentrySession(releaseName: "1.0.0").serialize()
        dict["attrs"] = nil // Remove release name
        let session = BuzzSentrySession(jsonObject: dict)!
        
        let data = try BuzzSentrySerialization.data(with: session)
        
        XCTAssertNil(BuzzSentrySerialization.session(with: data))
    }
    
    func testSerializeSessionWithEmptyReleaseName() throws {
        let dict = BuzzSentrySession(releaseName: "").serialize()
        let session = BuzzSentrySession(jsonObject: dict)!
        
        let data = try BuzzSentrySerialization.data(with: session)
        
        XCTAssertNil(BuzzSentrySerialization.session(with: data))
    }
    
    func testSerializeSessionWithGarbageInDict() throws {
        var dict = BuzzSentrySession(releaseName: "").serialize()
        dict["started"] = "20"
        let data = try BuzzSentrySerialization.data(withJSONObject: dict)
        
        XCTAssertNil(BuzzSentrySerialization.session(with: data))
    }
    
    func testSerializeSessionWithGarbage() throws {
        guard let data = "started".data(using: .ascii) else {
            XCTFail("Failed to create data"); return
        }
        
        XCTAssertNil(BuzzSentrySerialization.session(with: data))
    }
    
    func testLevelFromEventData() {
        let envelopeItem = BuzzSentryEnvelopeItem(event: TestData.event)
        
        let level = BuzzSentrySerialization.level(from: envelopeItem.data)
        XCTAssertEqual(TestData.event.level, level)
    }
    
    func testLevelFromEventData_WithGarbage() {
        let level = BuzzSentrySerialization.level(from: Fixture.invalidData)
        XCTAssertEqual(SentryLevel.error, level)
    }
    
    func testAppStateWithValidData_ReturnsValidAppState() throws {
        let appState = TestData.appState
        let appStateData = try BuzzSentrySerialization.data(withJSONObject: appState.serialize())
        
        let actual = BuzzSentrySerialization.appState(with: appStateData)
        
        XCTAssertEqual(appState, actual)
    }
    
    func testAppStateWithInvalidData_ReturnsNil() throws {
        let actual = BuzzSentrySerialization.appState(with: Fixture.invalidData)
        
        XCTAssertNil(actual)
    }

    func testDictionaryToBaggageEncoded() {
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value"]), "key=value")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value", "key2": "value2"]), "key2=value2,key=value")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value&"]), "key=value%26")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value="]), "key=value%3D")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value "]), "key=value%20")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value%"]), "key=value%25")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value-_"]), "key=value-_")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": "value\n\r"]), "key=value%0A%0D")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": ""]), "key=")
        
        let largeValue = String(repeating: "a", count: 8_188)
        
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["key": largeValue]), "key=\(largeValue)")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["AKey": "something", "BKey": largeValue]), "AKey=something")
        XCTAssertEqual(BuzzSentrySerialization.baggageEncodedDictionary(["AKey": "something", "BKey": largeValue, "CKey": "Other Value"]), "AKey=something,CKey=Other%20Value")
    }

    func testBaggageStringToDictionaryDecoded() {
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value"), ["key": "value"])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key2=value2,key=value"), ["key": "value", "key2": "value2"])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value%26"), ["key": "value&"])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value%3D"), ["key": "value="])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value%20"), ["key": "value "])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value%25"), ["key": "value%"])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value-_"), ["key": "value-_"])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key=value%0A%0D"), ["key": "value\n\r"])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage(""), [:])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key"), [:])
        XCTAssertEqual(BuzzSentrySerialization.decodeBaggage("key="), ["key": ""])
    }
    
    private func serializeEnvelope(envelope: BuzzSentryEnvelope) -> Data {
        var serializedEnvelope: Data = Data()
        do {
            serializedEnvelope = try BuzzSentrySerialization.data(with: envelope)
        } catch {
            XCTFail("Could not serialize envelope.")
        }
        return serializedEnvelope
    }

    private func createItemWithEmptyAttachment() -> BuzzSentryEnvelopeItem {
        let itemData = Data()
        let itemHeader = BuzzSentryEnvelopeItemHeader(type: "attachment", length: UInt(itemData.count))
        return BuzzSentryEnvelopeItem(header: itemHeader, data: itemData)
    }

    private func assertEnvelopeSerialization(
            envelope: BuzzSentryEnvelope,
            assert: (BuzzSentryEnvelope) -> Void
    ) {
        let serializedEnvelope = serializeEnvelope(envelope: envelope)

        if let deserializedEnvelope = BuzzSentrySerialization.envelope(with: serializedEnvelope) {
            assert(deserializedEnvelope)
        } else {
            XCTFail("Could not deserialize envelope.")
        }
    }

    private func assertDefaultSdkInfoSet(deserializedEnvelope: BuzzSentryEnvelope) {
        let sdkInfo = BuzzSentrySDKInfo(name: BuzzSentryMeta.sdkName, andVersion: BuzzSentryMeta.versionString)
        XCTAssertEqual(sdkInfo, deserializedEnvelope.header.sdkInfo)
    }
    
    func assertTraceState(firstTrace: BuzzSentryTraceContext, secondTrace: BuzzSentryTraceContext) {
        XCTAssertEqual(firstTrace.traceId, secondTrace.traceId)
        XCTAssertEqual(firstTrace.publicKey, secondTrace.publicKey)
        XCTAssertEqual(firstTrace.releaseName, secondTrace.releaseName)
        XCTAssertEqual(firstTrace.environment, secondTrace.environment)
        XCTAssertEqual(firstTrace.userSegment, secondTrace.userSegment)
        XCTAssertEqual(firstTrace.sampleRate, secondTrace.sampleRate)
    }
}
