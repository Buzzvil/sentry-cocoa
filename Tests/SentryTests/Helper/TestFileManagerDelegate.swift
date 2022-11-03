import Foundation

class TestFileManagerDelegate: NSObject, SentryFileManagerDelegate {
    
    var envelopeItemsDeleted = Invocations<BuzzSentryDataCategory>()
    func envelopeItemDeleted(_ dataCategory: BuzzSentryDataCategory) {
        envelopeItemsDeleted.record(dataCategory)
    }
}
