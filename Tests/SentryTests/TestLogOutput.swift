import Foundation

class TestLogOutput: BuzzSentryLogOutput {
    var loggedMessages: [String] = []
    override func log(_ message: String) {
        loggedMessages.append(message)
    }
}
