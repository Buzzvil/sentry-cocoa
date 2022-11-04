import BuzzSentry
import XCTest

class BuzzSentryTransportAdapterTests: XCTestCase {
    
    private class Fixture {

        let transport = TestTransport()
        let options = Options()
        let faultyAttachment = Attachment(path: "")
        let attachment = Attachment(data: Data(), filename: "test.txt")
        
        var sut: BuzzSentryTransportAdapter {
            get {
                return BuzzSentryTransportAdapter(transport: transport, options: options)
            }
        }
    }

    private var fixture: Fixture!
    private var sut: BuzzSentryTransportAdapter!

    override func setUp() {
        super.setUp()
        
        CurrentDate.setCurrentDateProvider(TestCurrentDateProvider())

        fixture = Fixture()
        sut = fixture.sut
    }
    
    func testSendEventWithSession_SendsCorrectEnvelope() throws {
        let session = BuzzSentrySession(releaseName: "1.0.1")
        let event = TestData.event
        sut.send(event, session: session, attachments: [fixture.attachment])
        
        let expectedEnvelope = BuzzSentryEnvelope(id: event.eventId, items: [
            BuzzSentryEnvelopeItem(event: event),
            BuzzSentryEnvelopeItem(attachment: fixture.attachment, maxAttachmentSize: fixture.options.maxAttachmentSize)!,
            BuzzSentryEnvelopeItem(session: session)
        ])
        
        assertEnvelope(expected: expectedEnvelope)
    }

    func testSendFaultyAttachment_FaultyAttachmentGetsDropped() {
        let event = TestData.event
        sut.send(event: event, attachments: [fixture.faultyAttachment, fixture.attachment])
        
        let expectedEnvelope = BuzzSentryEnvelope(id: event.eventId, items: [
            BuzzSentryEnvelopeItem(event: event),
            BuzzSentryEnvelopeItem(attachment: fixture.attachment, maxAttachmentSize: fixture.options.maxAttachmentSize)!
        ])
        
        assertEnvelope(expected: expectedEnvelope)
    }
    
    func testSendUserFeedback_SendsUserFeedbackEnvelope() {
        let userFeedback = TestData.userFeedback
        sut.send(userFeedback: userFeedback)
        
        let expectedEnvelope = BuzzSentryEnvelope(userFeedback: userFeedback)
        
        assertEnvelope(expected: expectedEnvelope)
    }
    
    private func assertEnvelope(expected: BuzzSentryEnvelope) {
        XCTAssertEqual(1, fixture.transport.sentEnvelopes.count)
        let actual = fixture.transport.sentEnvelopes.first!
        XCTAssertNotNil(actual)
        
        XCTAssertEqual(expected.header.eventId, actual.header.eventId)
        XCTAssertEqual(expected.header.sdkInfo, actual.header.sdkInfo)
        XCTAssertEqual(expected.items.count, actual.items.count)
        
        expected.items.forEach { expectedItem in
            let expectedHeader = expectedItem.header
            let containsHeader = actual.items.contains { _ in
                expectedHeader.type == expectedItem.header.type &&
                expectedHeader.contentType == expectedItem.header.contentType
            }
            
            XCTAssertTrue(containsHeader, "Envelope doesn't contain item with type:\(expectedHeader.type).")

            let containsData = actual.items.contains { actualItem in
                actualItem.data == expectedItem.data
            }
            
            XCTAssertTrue(containsData, "Envelope data with type:\(expectedHeader.type) doesn't match.")
        }
        
        XCTAssertEqual(try BuzzSentrySerialization.data(with: expected), try BuzzSentrySerialization.data(with: actual))
    }
}
