import CoreData
import XCTest

class BuzzSentryCoreDataTrackingIntegrationTests: XCTestCase {

    private class Fixture {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let options: Options
        let coreDataStack = TestCoreDataStack()
        
        init() {
            options = Options()
            options.enableCoreDataTracking = true
            options.tracesSampleRate = 1
        }
        
        func getSut() -> BuzzSentryCoreDataTrackingIntegration {
            return BuzzSentryCoreDataTrackingIntegration()
        }
    }
    
    private var fixture: Fixture!
    
    override func setUp() {
        super.setUp()
        fixture = Fixture()
    }
    
    override func tearDown() {
        super.tearDown()
        fixture.coreDataStack.reset()
        clearTestState()
    }
    
    func test_InstallAndUninstall() {
        let sut = fixture.getSut()
        
        XCTAssertNil(BuzzSentryCoreDataSwizzling.sharedInstance.middleware)
        sut.install(with: fixture.options)
        XCTAssertNotNil(BuzzSentryCoreDataSwizzling.sharedInstance.middleware)
        sut.uninstall()
        XCTAssertNil(BuzzSentryCoreDataSwizzling.sharedInstance.middleware)
    }
    
    func test_Install_swizzlingDisabled() {
        assert_DontInstall { $0.enableSwizzling = false }
    }
    
    func test_Install_autoPerformanceDisabled() {
        assert_DontInstall { $0.enableAutoPerformanceTracking = false }
    }
    
    func test_Install_coreDataTrackingDisabled() {
        assert_DontInstall { $0.enableCoreDataTracking = false }
    }
    
    func test_Fetch() {
        BuzzSentrySDK.start(options: fixture.options)
        let stack = fixture.coreDataStack
        let fetch = NSFetchRequest<TestEntity>(entityName: "TestEntity")
        let transaction = startTransaction()
        var _ = try? stack.managedObjectContext.fetch(fetch)
        XCTAssertEqual(transaction.children.count, 1)
    }
    
    func test_Save() {
        BuzzSentrySDK.start(options: fixture.options)
        let stack = fixture.coreDataStack
        let transaction = startTransaction()
        let newEntity: TestEntity = stack.getEntity()
        newEntity.field1 = "Some Update"
        try? stack.managedObjectContext.save()
        
        XCTAssertEqual(transaction.children.count, 1)
        XCTAssertEqual(transaction.children[0].context.operation, "db.sql.transaction")
    }
    
    func test_Save_noChanges() {
        BuzzSentrySDK.start(options: fixture.options)
        let stack = fixture.coreDataStack
        let transaction = startTransaction()
        
        try? stack.managedObjectContext.save()
        
        XCTAssertEqual(transaction.children.count, 0)
    }
    
    func test_Fetch_StoppedSwizzling() {
        BuzzSentrySDK.start(options: fixture.options)
        let stack = fixture.coreDataStack
        let fetch = NSFetchRequest<TestEntity>(entityName: "TestEntity")
        let transaction = startTransaction()
        BuzzSentryCoreDataSwizzling.sharedInstance.stop()
        var _ = try? stack.managedObjectContext.fetch(fetch)
        XCTAssertEqual(transaction.children.count, 0)
    }
    
    func test_Save_StoppedSwizzling() {
        BuzzSentrySDK.start(options: fixture.options)
        let stack = fixture.coreDataStack
        let transaction = startTransaction()
        let newEntity: TestEntity = stack.getEntity()
        newEntity.field1 = "Some Update"
        BuzzSentryCoreDataSwizzling.sharedInstance.stop()
        try? stack.managedObjectContext.save()
        XCTAssertEqual(transaction.children.count, 0)
    }
    
    private func assert_DontInstall(_ confOptions: ((Options) -> Void)) {
        let sut = fixture.getSut()
        confOptions(fixture.options)
        XCTAssertNil(BuzzSentryCoreDataSwizzling.sharedInstance.middleware)
        sut.install(with: fixture.options)
        XCTAssertNil(BuzzSentryCoreDataSwizzling.sharedInstance.middleware)
    }
    
    private func startTransaction() -> BuzzSentryTracer {
        return BuzzSentrySDK.startTransaction(name: "TestTransaction", operation: "TestTransaction", bindToScope: true) as! BuzzSentryTracer
    }
}
