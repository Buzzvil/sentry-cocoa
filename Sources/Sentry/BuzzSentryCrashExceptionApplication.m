#import "BuzzSentryCrashExceptionApplication.h"
#import "BuzzSentryCrash.h"
#import "BuzzSentrySDK.h"

@implementation BuzzSentryCrashExceptionApplication

#if TARGET_OS_OSX

- (void)reportException:(NSException *)exception
{
    [[NSUserDefaults standardUserDefaults]
        registerDefaults:@{ @"NSApplicationCrashOnExceptions" : @YES }];
    if (nil != BuzzSentryCrash.sharedInstance.uncaughtExceptionHandler && nil != exception) {
        BuzzSentryCrash.sharedInstance.uncaughtExceptionHandler(exception);
    }
    [super reportException:exception];
}

- (void)_crashOnException:(NSException *)exception
{
    [BuzzSentrySDK captureException:exception];
    abort();
}

#endif

@end
