#import "BuzzSentrySwizzleWrapper.h"
#import "BuzzSentrySwizzle.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentrySwizzleWrapper

#if SENTRY_HAS_UIKIT
static NSMutableDictionary<NSString *, BuzzSentrySwizzleSendActionCallback>
    *BuzzSentrySwizzleSendActionCallbacks;
#endif

+ (BuzzSentrySwizzleWrapper *)sharedInstance
{
    static BuzzSentrySwizzleWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

+ (void)initialize
{
#if SENTRY_HAS_UIKIT
    if (self == [BuzzSentrySwizzleWrapper class]) {
        BuzzSentrySwizzleSendActionCallbacks = [NSMutableDictionary new];
    }
#endif
}

#if SENTRY_HAS_UIKIT
- (void)swizzleSendAction:(BuzzSentrySwizzleSendActionCallback)callback forKey:(NSString *)key
{
    // We need to make a copy of the block to avoid ARC of autoreleasing it.
    BuzzSentrySwizzleSendActionCallbacks[key] = [callback copy];

    if (BuzzSentrySwizzleSendActionCallbacks.count != 1) {
        return;
    }

#    pragma clang diagnostic push
#    pragma clang diagnostic ignored "-Wshadow"
    static const void *swizzleSendActionKey = &swizzleSendActionKey;
    SEL selector = NSSelectorFromString(@"sendAction:to:from:forEvent:");
    BuzzSentrySwizzleInstanceMethod(UIApplication.class, selector, SentrySWReturnType(BOOL),
        SentrySWArguments(SEL action, id target, id sender, UIEvent * event), SentrySWReplacement({
            [BuzzSentrySwizzleWrapper sendActionCalled:action target:target sender:sender event:event];
            return SentrySWCallOriginal(action, target, sender, event);
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, swizzleSendActionKey);
#    pragma clang diagnostic pop
}

- (void)removeSwizzleSendActionForKey:(NSString *)key
{
    [BuzzSentrySwizzleSendActionCallbacks removeObjectForKey:key];
}

/**
 * For testing. We want the swizzling block above to call a static function to avoid having a block
 * reference to an instance of this class.
 */
+ (void)sendActionCalled:(SEL)action target:(id)target sender:(id)sender event:(UIEvent *)event
{
    for (BuzzSentrySwizzleSendActionCallback callback in BuzzSentrySwizzleSendActionCallbacks.allValues) {
        callback([NSString stringWithFormat:@"%s", sel_getName(action)], target, sender, event);
    }
}

/**
 * For testing.
 */
- (NSDictionary<NSString *, BuzzSentrySwizzleSendActionCallback> *)swizzleSendActionCallbacks
{
    return BuzzSentrySwizzleSendActionCallbacks;
}
#endif

- (void)removeAllCallbacks
{
#if SENTRY_HAS_UIKIT
    [BuzzSentrySwizzleSendActionCallbacks removeAllObjects];
#endif
}

#if SENTRY_HAS_UIKIT
// For test purpose
+ (BOOL)hasCallbacks
{
    return BuzzSentrySwizzleSendActionCallbacks.count > 0;
}
#endif

@end

NS_ASSUME_NONNULL_END
