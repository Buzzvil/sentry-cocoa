import Foundation

class TestEnvelopeRateLimitDelegate: NSObject, BuzzSentryEnvelopeRateLimitDelegate {
    
    var envelopeItemsDropped = Invocations<BuzzSentryDataCategory>()
    func envelopeItemDropped(_ dataCategory: BuzzSentryDataCategory) {
        envelopeItemsDropped.record(dataCategory)
    }
}
