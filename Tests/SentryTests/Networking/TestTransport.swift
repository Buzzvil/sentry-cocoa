import Foundation

@objc
public class TestTransport: NSObject, Transport {
    
    var sentEnvelopes = Invocations<BuzzSentryEnvelope>()
    public func send(envelope: BuzzSentryEnvelope) {
        sentEnvelopes.record(envelope)
    }
    
    var recordLostEvents = Invocations<(category: BuzzSentryDataCategory, reason: BuzzSentryDiscardReason)>()
    public func recordLostEvent(_ category: BuzzSentryDataCategory, reason: BuzzSentryDiscardReason) {
        recordLostEvents.record((category, reason))
    }
    
    var flushInvocations = Invocations<TimeInterval>()
    public func flush(_ timeout: TimeInterval) -> Bool {
        flushInvocations.record(timeout)
        return true
    }
}
