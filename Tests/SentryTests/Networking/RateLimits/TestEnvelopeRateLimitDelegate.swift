import Foundation

class TestEnvelopeRateLimitDelegate: NSObject, BuzzSentryEnvelopeRateLimitDelegate {
    
    var envelopeItemsDropped = Invocations<SentryDataCategory>()
    func envelopeItemDropped(_ dataCategory: SentryDataCategory) {
        envelopeItemsDropped.record(dataCategory)
    }
}
