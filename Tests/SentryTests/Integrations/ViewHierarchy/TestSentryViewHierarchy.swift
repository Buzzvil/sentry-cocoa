import Foundation

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
class TestBuzzSentryViewHierarchy: BuzzSentryViewHierarchy {

    var result: [String] = []

    override func fetch() -> [String] {
        return result
    }
}
#endif
