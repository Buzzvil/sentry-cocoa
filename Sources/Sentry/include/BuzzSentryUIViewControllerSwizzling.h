#import "SentryDefines.h"
#import "BuzzSentryObjCRuntimeWrapper.h"
#import <Foundation/Foundation.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryOptions, BuzzSentryDispatchQueueWrapper, BuzzSentrySubClassFinder;

/**
 * This is a protocol to define which properties and methods the swizzler required from
 * UIApplication. This way, instead of relying on UIApplication, we can test with a mock class.
 */
@protocol BuzzSentryUIApplication

@property (nullable, nonatomic, assign) id<UIApplicationDelegate> delegate;

@end

/**
 * Class is responsible to swizzle UI key methods
 * so Sentry can track UI performance.
 */
@interface BuzzSentryUIViewControllerSwizzling : NSObject
SENTRY_NO_INIT

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                  dispatchQueue:(BuzzSentryDispatchQueueWrapper *)dispatchQueue
             objcRuntimeWrapper:(id<BuzzSentryObjCRuntimeWrapper>)objcRuntimeWrapper
                 subClassFinder:(BuzzSentrySubClassFinder *)subClassFinder;

- (void)start;

@end
NS_ASSUME_NONNULL_END

#endif
