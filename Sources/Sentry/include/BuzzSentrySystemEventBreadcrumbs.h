#import "BuzzSentryCurrentDateProvider.h"
#import "BuzzSentryFileManager.h"
#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#    import <UIKit/UIKit.h>
#endif

@interface BuzzSentrySystemEventBreadcrumbs : NSObject
SENTRY_NO_INIT

- (instancetype)initWithFileManager:(BuzzSentryFileManager *)fileManager
             andCurrentDateProvider:(id<BuzzSentryCurrentDateProvider>)currentDateProvider;

- (void)start;

#if TARGET_OS_IOS
- (void)start:(UIDevice *)currentDevice;
- (void)timezoneEventTriggered;
#endif

- (void)stop;

@end
