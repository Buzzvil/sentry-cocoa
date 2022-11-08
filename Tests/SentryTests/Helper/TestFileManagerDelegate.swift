import Foundation

class TestFileManagerDelegate: NSObject, BuzzSentryFileManagerDelegate {
    
    var envelopeItemsDeleted = Invocations<BuzzSentryDataCategory>()
    func envelopeItemDeleted(_ dataCategory: BuzzSentryDataCategory) {
        envelopeItemsDeleted.record(dataCategory)
    }
}
