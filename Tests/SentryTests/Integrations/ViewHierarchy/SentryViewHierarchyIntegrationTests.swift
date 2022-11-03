import Sentry
import XCTest

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
class BuzzSentryViewHierarchyIntegrationTests: XCTestCase {

    private class Fixture {
        let viewHierarchy: TestBuzzSentryViewHierarchy

        init() {
            let testViewHierarchy = TestBuzzSentryViewHierarchy()
            testViewHierarchy.result = ["view hierarchy"]
            viewHierarchy = testViewHierarchy
        }

        func getSut() -> BuzzSentryViewHierarchyIntegration {
            let result = BuzzSentryViewHierarchyIntegration()
            return result
        }
    }

    private var fixture: Fixture!

    override func setUp() {
        super.setUp()
        fixture = Fixture()

        SentryDependencyContainer.sharedInstance().viewHierarchy = fixture.viewHierarchy
    }

    override func tearDown() {
        super.tearDown()
        clearTestState()
    }

    func test_attachViewHierarchy_disabled() {
        BuzzSentrySDK.start { $0.attachViewHierarchy = false }
        XCTAssertEqual(BuzzSentrySDK.currentHub().getClient()?.attachmentProcessors.count, 0)
        XCTAssertFalse(sentrycrash_hasSaveViewHierarchyCallback())
    }

    func test_attachViewHierarchy_enabled() {
        BuzzSentrySDK.start { $0.attachViewHierarchy = true }
        XCTAssertEqual(BuzzSentrySDK.currentHub().getClient()?.attachmentProcessors.count, 1)
        XCTAssertTrue(sentrycrash_hasSaveViewHierarchyCallback())
    }

    func test_uninstall() {
        BuzzSentrySDK.start { $0.attachViewHierarchy = true }
        BuzzSentrySDK.close()
        XCTAssertNil(BuzzSentrySDK.currentHub().getClient()?.attachmentProcessors)
        XCTAssertFalse(sentrycrash_hasSaveViewHierarchyCallback())
    }

    func test_noViewHierarchy_attachment() {
        let sut = fixture.getSut()
        let event = Event()

        let newAttachmentList = sut.processAttachments([], for: event)

        XCTAssertEqual(newAttachmentList?.count, 0)
    }

    func test_noViewHierarchy_CrashEvent() {
        let sut = fixture.getSut()
        let event = Event(error: NSError(domain: "", code: -1))
        event.isCrashEvent = true

        let newAttachmentList = sut.processAttachments([], for: event)

        XCTAssertEqual(newAttachmentList?.count, 0)
    }

    func test_noViewHierarchy_keepAttachment() {
        let sut = fixture.getSut()
        let event = Event()

        let attachment = Attachment(data: Data(), filename: "Some Attachment")

        let newAttachmentList = sut.processAttachments([attachment], for: event)

        XCTAssertEqual(newAttachmentList?.count, 1)
        XCTAssertEqual(newAttachmentList?.first, attachment)
    }

    func test_attachments() {
        let sut = fixture.getSut()
        let event = Event(error: NSError(domain: "", code: -1))
        fixture.viewHierarchy.result = ["view hierarchy for window zero", "view hierarchy for window one"]

        let newAttachmentList = sut.processAttachments([], for: event) ?? []

        XCTAssertEqual(newAttachmentList.count, 2)
        XCTAssertEqual(newAttachmentList[0].filename, "view-hierarchy-0.txt")
        XCTAssertEqual(newAttachmentList[1].filename, "view-hierarchy-1.txt")

        XCTAssertEqual(newAttachmentList[0].contentType, "text/plain")
        XCTAssertEqual(newAttachmentList[1].contentType, "text/plain")

        XCTAssertEqual(newAttachmentList[0].data?.count, "view hierarchy for window zero".lengthOfBytes(using: .utf8))
        XCTAssertEqual(newAttachmentList[1].data?.count, "view hierarchy for window one".lengthOfBytes(using: .utf8))

    }

}
#endif
