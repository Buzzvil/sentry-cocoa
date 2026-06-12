import Foundation
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
class TestBuzzSentrySwizzleWrapper: BuzzSentrySwizzleWrapper {
    
    var callbacks = [String: BuzzSentrySwizzleSendActionCallback]()
        
    override func swizzleSendAction(_ callback: @escaping BuzzSentrySwizzleSendActionCallback, forKey key: String) {
        callbacks[key] = callback
    }

    override func removeSwizzleSendAction(forKey key: String) {
        callbacks.removeValue(forKey: key)
    }
    
    override func removeAllCallbacks() {
        callbacks.removeAll()
    }
    
    func execute(action: String, target: Any?, sender: Any?, event: UIEvent?) {
        callbacks.values.forEach { $0(action, target, sender, event) }
    }
}
#endif
