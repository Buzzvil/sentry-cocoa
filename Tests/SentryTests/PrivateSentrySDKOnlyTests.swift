import XCTest

class PrivateBuzzSentrySDKOnlyTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        clearTestState()
    }

    func testStoreEnvelope() {
        let client = TestClient(options: Options())
        SentrySDK.setCurrentHub(TestHub(client: client, andScope: nil))
        
        let envelope = TestConstants.envelope
        PrivateBuzzSentrySDKOnly.store(envelope)
        
        XCTAssertEqual(1, client?.storedEnvelopeInvocations.count)
        XCTAssertEqual(envelope, client?.storedEnvelopeInvocations.first)
    }
    
    func testCaptureEnvelope() {
        let client = TestClient(options: Options())
        SentrySDK.setCurrentHub(TestHub(client: client, andScope: nil))
        
        let envelope = TestConstants.envelope
        PrivateBuzzSentrySDKOnly.capture(envelope)
        
        XCTAssertEqual(1, client?.captureEnvelopeInvocations.count)
        XCTAssertEqual(envelope, client?.captureEnvelopeInvocations.first)
    }

    func testSetSdkName() {
        let originalName = PrivateBuzzSentrySDKOnly.getSdkName()
        let name = "Some SDK name"
        let originalVersion = BuzzSentryMeta.versionString
        XCTAssertNotEqual(originalVersion, "")
        
        PrivateBuzzSentrySDKOnly.setSdkName(name)
        XCTAssertEqual(BuzzSentryMeta.sdkName, name)
        XCTAssertEqual(BuzzSentryMeta.versionString, originalVersion)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkName(), name)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkVersionString(), originalVersion)
        
        PrivateBuzzSentrySDKOnly.setSdkName(originalName)
        XCTAssertEqual(BuzzSentryMeta.sdkName, originalName)
        XCTAssertEqual(BuzzSentryMeta.versionString, originalVersion)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkName(), originalName)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkVersionString(), originalVersion)
    }
    
    func testSetSdkNameAndVersion() {
        let originalName = PrivateBuzzSentrySDKOnly.getSdkName()
        let originalVersion = PrivateBuzzSentrySDKOnly.getSdkVersionString()
        let name = "Some SDK name"
        let version = "1.2.3.4"

        PrivateBuzzSentrySDKOnly.setSdkName(name, andVersionString: version)
        XCTAssertEqual(BuzzSentryMeta.sdkName, name)
        XCTAssertEqual(BuzzSentryMeta.versionString, version)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkName(), name)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkVersionString(), version)
        
        PrivateBuzzSentrySDKOnly.setSdkName(originalName, andVersionString: originalVersion)
        XCTAssertEqual(BuzzSentryMeta.sdkName, originalName)
        XCTAssertEqual(BuzzSentryMeta.versionString, originalVersion)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkName(), originalName)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.getSdkVersionString(), originalVersion)
        
    }
    
    func testEnvelopeWithData() throws {
        let itemData = "{}\n{\"length\":0,\"type\":\"attachment\"}\n".data(using: .utf8)!
        XCTAssertNotNil(PrivateBuzzSentrySDKOnly.envelope(with: itemData))
    }
    
    func testGetDebugImages() {
        let images = PrivateBuzzSentrySDKOnly.getDebugImages()
        
        // Only make sure we get some images. The actual tests are in
        // SentryDebugImageProviderTests
        XCTAssertGreaterThan(images.count, 100)
    }
    
    func testGetAppStartMeasurement() {
        let appStartMeasurement = TestData.getAppStartMeasurement(type: .warm)
        SentrySDK.setAppStartMeasurement(appStartMeasurement)
        
        XCTAssertEqual(appStartMeasurement, PrivateBuzzSentrySDKOnly.appStartMeasurement)
        
        SentrySDK.setAppStartMeasurement(nil)
        XCTAssertNil(PrivateBuzzSentrySDKOnly.appStartMeasurement)
    }
    
    func testGetInstallationId() {
        XCTAssertEqual(SentryInstallation.id(), PrivateBuzzSentrySDKOnly.installationID)
    }
    
    func testSendAppStartMeasurement() {
        XCTAssertFalse(PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode)
        
        PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode = true
        XCTAssertTrue(PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode)
    }

    func testOptions() {
        let options = Options()
        options.dsn = TestConstants.dsnAsString(username: "BuzzSentryFramesTrackingIntegrationTests")
        let client = TestClient(options: options)
        SentrySDK.setCurrentHub(TestHub(client: client, andScope: nil))

        XCTAssertEqual(PrivateBuzzSentrySDKOnly.options, options)
    }

    func testDefaultOptions() {
        XCTAssertNotNil(PrivateBuzzSentrySDKOnly.options)
        XCTAssertNil(PrivateBuzzSentrySDKOnly.options.dsn)
        XCTAssertEqual(PrivateBuzzSentrySDKOnly.options.enabled, true)
    }
    
    #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
    
    func testIsFramesTrackingRunning() {
        XCTAssertFalse(PrivateBuzzSentrySDKOnly.isFramesTrackingRunning)
        BuzzSentryFramesTracker.sharedInstance().start()
        XCTAssertTrue(PrivateBuzzSentrySDKOnly.isFramesTrackingRunning)
    }
    
    func testGetFrames() {
        let tracker = BuzzSentryFramesTracker.sharedInstance()
        let displayLink = TestDiplayLinkWrapper()
        
        tracker.setDisplayLinkWrapper(displayLink)
        tracker.start()
        displayLink.call()
        
        let slow = 2
        let frozen = 1
        let normal = 100
        displayLink.givenFrames(slow, frozen, normal)
        
        let currentFrames = PrivateBuzzSentrySDKOnly.currentScreenFrames
        XCTAssertEqual(UInt(slow + frozen + normal), currentFrames.total)
        XCTAssertEqual(UInt(frozen), currentFrames.frozen)
        XCTAssertEqual(UInt(slow), currentFrames.slow)
    }

    #endif
}
