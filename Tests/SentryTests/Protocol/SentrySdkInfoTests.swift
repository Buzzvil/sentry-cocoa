import XCTest

class BuzzSentrySDKInfoTests: XCTestCase {
    
    private let sdkName = "sentry.cocoa"
    
    func testWithPatchLevelSuffix() {
        let version = "50.10.20-beta1"
        let actual = BuzzSentrySDKInfo(name: sdkName, andVersion: version)
        
        XCTAssertEqual(sdkName, actual.name)
        XCTAssertEqual(version, actual.version)
    }
    
    func testWithAnyVersion() {
        let version = "anyVersion"
        let actual = BuzzSentrySDKInfo(name: sdkName, andVersion: version)
        
        XCTAssertEqual(sdkName, actual.name)
        XCTAssertEqual(version, actual.version)
    }
    
    func testSerialization() {
        let version = "5.2.0"
        let actual = BuzzSentrySDKInfo(name: sdkName, andVersion: version).serialize()
        
        if let sdkInfo = actual["sdk"] as? [String: Any] {
            XCTAssertEqual(2, sdkInfo.count)
            XCTAssertEqual(sdkName, sdkInfo["name"] as? String)
            XCTAssertEqual(version, sdkInfo["version"] as? String)
        } else {
            XCTFail("Serialization of SdkInfo doesn't contain sdk")
        }
    }
    
    func testInitWithDict_SdkInfo() {
        let version = "10.3.1"
        let expected = BuzzSentrySDKInfo(name: sdkName, andVersion: version)
        
        let dict = ["sdk": [ "name": sdkName, "version": version]]
        
        XCTAssertEqual(expected, BuzzSentrySDKInfo(dict: dict))
    }
    
    func testInitWithDict_AllNil() {
        let dict = ["sdk": [ "name": nil, "version": nil]]
        
        assertEmptySdkInfo(actual: BuzzSentrySDKInfo(dict: dict))
    }
    
    func testInitWithDict_WrongTypes() {
        let dict = ["sdk": [ "name": 0, "version": 0]]
        
        assertEmptySdkInfo(actual: BuzzSentrySDKInfo(dict: dict))
    }
    
    func testInitWithDict_SdkInfoIsString() {
        let dict = ["sdk": ""]
        
        assertEmptySdkInfo(actual: BuzzSentrySDKInfo(dict: dict))
    }
    
    private func assertEmptySdkInfo(actual: BuzzSentrySDKInfo) {
        XCTAssertEqual(BuzzSentrySDKInfo(name: "", andVersion: ""), actual)
    }
}
