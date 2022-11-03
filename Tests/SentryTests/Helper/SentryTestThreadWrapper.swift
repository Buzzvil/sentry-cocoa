import Foundation

class SentryTestThreadWrapper: BuzzSentryThreadWrapper {
    
    override func sleep(forTimeInterval timeInterval: TimeInterval) {
        // Don't sleep. Do nothing.
    }

}
