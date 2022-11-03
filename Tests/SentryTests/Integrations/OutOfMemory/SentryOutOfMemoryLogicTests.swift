import XCTest

class BuzzSentryOutOfMemoryLogicTests: XCTestCase {

    private static let dsnAsString = TestConstants.dsnAsString(username: "BuzzSentryOutOfMemoryLogicTests")
    private static let dsn = TestConstants.dsn(username: "BuzzSentryOutOfMemoryLogicTests")
    
    private class Fixture {
        
        let options: Options
        let client: TestClient!
        let crashWrapper: TestBuzzSentryCrashWrapper
        let fileManager: SentryFileManager
        let currentDate = TestCurrentDateProvider()
        let sysctl = TestSysctl()
        let dispatchQueue = TestBuzzSentryDispatchQueueWrapper()
        
        init() {
            options = Options()
            options.dsn = BuzzSentryOutOfMemoryLogicTests.dsnAsString
            options.releaseName = TestData.appState.releaseName
            
            client = TestClient(options: options)
            
            crashWrapper = TestBuzzSentryCrashWrapper.sharedInstance()
            
            fileManager = try! SentryFileManager(options: options, andCurrentDateProvider: currentDate)
        }
        
        func getSut() -> BuzzSentryOutOfMemoryLogic {
            let appStateManager = SentryAppStateManager(options: options, crashWrapper: crashWrapper, fileManager: fileManager, currentDateProvider: currentDate, sysctl: sysctl, dispatchQueueWrapper: self.dispatchQueue)
            return BuzzSentryOutOfMemoryLogic(options: options, crashAdapter: crashWrapper, appStateManager: appStateManager)
        }
    }
    
    private var fixture: Fixture!
    private var sut: BuzzSentryOutOfMemoryLogic!
    
    override func setUp() {
        super.setUp()
        
        fixture = Fixture()
        sut = fixture.getSut()
    }
    
    override func tearDown() {
        super.tearDown()
        fixture.fileManager.deleteAllFolders()
    }

    func testExample() throws {

    }

}
