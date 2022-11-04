#import "BuzzSentryDefines.h"

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if SENTRY_HAS_UIKIT
typedef void (^BuzzSentrySwizzleSendActionCallback)(
    NSString *actionName, _Nullable id target, _Nullable id sender, UIEvent *_Nullable event);
#endif

/**
 * A wrapper around swizzling for testability and to only swizzle once when multiple implementations
 * need to be called for the same swizzled method.
 */
@interface BuzzSentrySwizzleWrapper : NSObject

@property (class, readonly, nonatomic) BuzzSentrySwizzleWrapper *sharedInstance;

#if SENTRY_HAS_UIKIT
- (void)swizzleSendAction:(BuzzSentrySwizzleSendActionCallback)callback forKey:(NSString *)key;

- (void)removeSwizzleSendActionForKey:(NSString *)key;
#endif

/**
 * For testing purposes.
 */
- (void)removeAllCallbacks;

@end

NS_ASSUME_NONNULL_END