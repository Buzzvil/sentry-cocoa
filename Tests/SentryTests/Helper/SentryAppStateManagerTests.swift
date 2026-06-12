import XCTest

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
class BuzzSentryAppStateManagerTests: XCTestCase {
    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryOutOfMemoryTrackerTests")
    private static let dsn = TestConstants.dsn(username: "BuzzSentryOutOfMemoryTrackerTests")

    private class Fixture {

        let options: Options
        let fileManager: BuzzSentryFileManager
        let currentDate = TestCurrentDateProvider()

        init() {
            options = Options()
            options.dsn = BuzzSentryAppStateManagerTests.dsnAsString
            options.releaseName = TestData.appState.releaseName

            fileManager = try! BuzzSentryFileManager(options: options, andCurrentDateProvider: currentDate)
        }

        func getSut() -> BuzzSentryAppStateManager {
            return BuzzSentryAppStateManager(
                options: options,
                crashWrapper: TestBuzzSentryCrashWrapper.sharedInstance(),
                fileManager: fileManager,
                currentDateProvider: currentDate,
                sysctl: TestSysctl(),
                dispatchQueueWrapper: TestBuzzSentryDispatchQueueWrapper()
            )
        }
    }

    private var fixture: Fixture!
    private var sut: BuzzSentryAppStateManager!

    override func setUp() {
        super.setUp()

        fixture = Fixture()
        sut = fixture.getSut()
    }

    override func tearDown() {
        super.tearDown()
        fixture.fileManager.deleteAppState()
    }

    func testStartStoresAppState() {
        XCTAssertNil(fixture.fileManager.readAppState())

        sut.start()
        XCTAssertNotNil(fixture.fileManager.readAppState())
    }

    func testStartOnlyRunsLogicWhenStartCountBecomesOne() {
        XCTAssertNil(fixture.fileManager.readAppState())

        sut.start()
        XCTAssertNotNil(fixture.fileManager.readAppState())

        fixture.fileManager.deleteAppState()

        sut.start()
        XCTAssertNil(fixture.fileManager.readAppState())
    }

    func testStopDeletesAppState() {
        XCTAssertNil(fixture.fileManager.readAppState())

        sut.start()
        XCTAssertNotNil(fixture.fileManager.readAppState())

        sut.stop()
        XCTAssertNil(fixture.fileManager.readAppState())
    }

    func testStopOnlyRunsLogicWhenStartCountBecomesZero() {
        XCTAssertNil(fixture.fileManager.readAppState())

        sut.start()
        XCTAssertNotNil(fixture.fileManager.readAppState())

        sut.start()

        sut.stop()
        XCTAssertNotNil(fixture.fileManager.readAppState())

        sut.stop()
        XCTAssertNil(fixture.fileManager.readAppState())
    }

    func testStoreAndDeleteAppState() {
        XCTAssertNil(fixture.fileManager.readAppState())

        sut.storeCurrentAppState()
        XCTAssertNotNil(fixture.fileManager.readAppState())

        sut.deleteAppState()
        XCTAssertNil(fixture.fileManager.readAppState())
    }

    func testUpdateAppState() {
        sut.storeCurrentAppState()

        XCTAssertEqual(fixture.fileManager.readAppState()!.wasTerminated, false)

        sut.updateAppState { state in
            state.wasTerminated = true
        }

        XCTAssertEqual(fixture.fileManager.readAppState()!.wasTerminated, true)
    }
}
#endif
