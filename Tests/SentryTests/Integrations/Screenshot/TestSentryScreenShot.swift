import Foundation

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
class TestBuzzSentryScreenshot: BuzzSentryScreenshot {
    
    var result: [Data]?
        
    override func appScreenshots() -> [Data]? {
        return result
    }
    
}
#endif
