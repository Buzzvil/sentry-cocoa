import Foundation

public class TestRateLimits: NSObject, RateLimits {
    
    public var responses: [HTTPURLResponse] = []
    public var isLimitForAllActive: Bool = false
    public var rateLimits: [BuzzSentryDataCategory] = []
    
    public func isRateLimitActive(_ category: BuzzSentryDataCategory) -> Bool {
        return isLimitForAllActive || rateLimits.contains(category)
    }
    
    public func update(_ response: HTTPURLResponse) {
        responses.append(response)
    }
}
