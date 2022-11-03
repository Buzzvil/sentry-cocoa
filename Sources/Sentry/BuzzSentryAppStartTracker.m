#import "BuzzSentryAppStartMeasurement.h"
#import "BuzzSentryAppStateManager.h"
#import "SentryLog.h"
#import "BuzzSentrySysctl.h"
#import <Foundation/Foundation.h>
#import <PrivateBuzzSentrySDKOnly.h>
#import <BuzzSentryAppStartTracker.h>
#import <BuzzSentryAppState.h>
#import <BuzzSentryCurrentDateProvider.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <BuzzSentryInternalNotificationNames.h>
#import <SentryLog.h>
#import <BuzzSentrySDK+Private.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>

static NSDate *runtimeInit = nil;
static BOOL isActivePrewarm = NO;

/**
 * The watchdog usually kicks in after an app hanging for 30 seconds. As the app could hang in
 * multiple stages during the launch we pick a higher threshold.
 */
static const NSTimeInterval SENTRY_APP_START_MAX_DURATION = 180.0;

@interface
BuzzSentryAppStartTracker ()

@property (nonatomic, strong) id<BuzzSentryCurrentDateProvider> currentDate;
@property (nonatomic, strong) BuzzSentryAppState *previousAppState;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueue;
@property (nonatomic, strong) BuzzSentryAppStateManager *appStateManager;
@property (nonatomic, strong) BuzzSentrySysctl *sysctl;
@property (nonatomic, assign) BOOL wasInBackground;
@property (nonatomic, strong) NSDate *didFinishLaunchingTimestamp;

@end

@implementation BuzzSentryAppStartTracker

+ (void)load
{
    // Invoked whenever this class is added to the Objective-C runtime.
    runtimeInit = [NSDate date];

    // The OS sets this environment variable if the app start is pre warmed. There are no official
    // docs for this. Found at https://eisel.me/startup. Investigations show that this variable is
    // deleted after UIApplicationDidFinishLaunchingNotification, so we have to check it here.
    isActivePrewarm =
        [[NSProcessInfo processInfo].environment[@"ActivePrewarm"] isEqualToString:@"1"];
}

- (instancetype)initWithCurrentDateProvider:(id<BuzzSentryCurrentDateProvider>)currentDateProvider
                       dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
                            appStateManager:(BuzzSentryAppStateManager *)appStateManager
                                     sysctl:(BuzzSentrySysctl *)sysctl
{
    if (self = [super init]) {
        self.currentDate = currentDateProvider;
        self.dispatchQueue = dispatchQueueWrapper;
        self.appStateManager = appStateManager;
        self.sysctl = sysctl;
        self.previousAppState = [self.appStateManager loadPreviousAppState];
        self.wasInBackground = NO;
        self.didFinishLaunchingTimestamp = [currentDateProvider date];
    }
    return self;
}

- (BOOL)isActivePrewarmAvailable
{
#    if TARGET_OS_IOS
    // Customer data suggest that app starts are also prewarmed on iOS 14 although this contradicts
    // with Apple docs.
    if (@available(iOS 14, *)) {
        return YES;
    } else {
        return NO;
    }
#    else
    return NO;
#    endif
}

- (void)start
{
    // It can happen that the OS posts the didFinishLaunching notification before we register for it
    // or we just don't receive it. In this case the didFinishLaunchingTimestamp would be nil. As
    // the SDK should be initialized in application:didFinishLaunchingWithOptions: or in the init of
    // @main of a SwiftUI  we set the timestamp here.
    self.didFinishLaunchingTimestamp = [self.currentDate date];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didFinishLaunching)
                                               name:UIApplicationDidFinishLaunchingNotification
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didBecomeVisible)
                                               name:UIWindowDidBecomeVisibleNotification
                                             object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didEnterBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];

    if (PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode) {
        [self buildAppStartMeasurement];
    }

#    if SENTRY_HAS_UIKIT
    [self.appStateManager start];
#    endif
}

- (void)buildAppStartMeasurement
{
    void (^block)(void) = ^(void) {
        [self stop];

        // Don't (yet) report pre warmed app starts.
        // Check if prewarm is available. Just to be safe to not drop app start data on earlier OS
        // verions.
        if ([self isActivePrewarmAvailable] && isActivePrewarm) {
            SENTRY_LOG_INFO(@"The app was prewarmed. Not measuring app start.");
            return;
        }

        BuzzSentryAppStartType appStartType = [self getStartType];

        if (appStartType == BuzzSentryAppStartTypeUnknown) {
            SENTRY_LOG_WARN(@"Unknown start type. Not measuring app start.");
            return;
        }

        if (self.wasInBackground) {
            // If the app was already running in the background it's not a cold or warm
            // start.
            SENTRY_LOG_INFO(@"App was in background. Not measuring app start.");
            return;
        }

        // According to a talk at WWDC about optimizing app launch
        // (https://devstreaming-cdn.apple.com/videos/wwdc/2019/423lzf3qsjedrzivc7/423/423_optimizing_app_launch.pdf?dl=1
        // slide 17) no process exists for cold and warm launches. Since iOS 15, though, the system
        // might decide to pre-warm your app before the user tries to open it. The process start
        // time returned valid values when testing with real devices if the app start is not
        // prewarmed. See:
        // https://developer.apple.com/documentation/uikit/app_and_environment/responding_to_the_launch_of_your_app/about_the_app_launch_sequence#3894431
        // https://developer.apple.com/documentation/metrickit/mxapplaunchmetric,
        // https://twitter.com/steipete/status/1466013492180312068,
        // https://github.com/MobileNativeFoundation/discussions/discussions/146

        NSTimeInterval appStartDuration =
            [[self.currentDate date] timeIntervalSinceDate:self.sysctl.processStartTimestamp];

        // Safety check to not report app starts that are completely off.
        if (appStartDuration >= SENTRY_APP_START_MAX_DURATION) {
            SENTRY_LOG_INFO(
                @"The app start exceeded the max duration of %f seconds. Not measuring app start.",
                SENTRY_APP_START_MAX_DURATION);
            return;
        }

        // On HybridSDKs, we miss the didFinishLaunchNotification and the
        // didBecomeVisibleNotification. Therefore, we can't set the
        // didFinishLaunchingTimestamp, and we can't calculate the appStartDuration. Instead,
        // the SDK provides the information we know and leaves the rest to the HybridSDKs.
        if (PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode) {
            self.didFinishLaunchingTimestamp =
                [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:0];

            appStartDuration = 0;
        }

        BuzzSentryAppStartMeasurement *appStartMeasurement = [[BuzzSentryAppStartMeasurement alloc]
                             initWithType:appStartType
                        appStartTimestamp:self.sysctl.processStartTimestamp
                                 duration:appStartDuration
                     runtimeInitTimestamp:runtimeInit
            moduleInitializationTimestamp:self.sysctl.moduleInitializationTimestamp
              didFinishLaunchingTimestamp:self.didFinishLaunchingTimestamp];

        BuzzSentrySDK.appStartMeasurement = appStartMeasurement;
    };

    // With only running this once we know that the process is a new one when the following
    // code is executed.
// We need to make sure the block runs on each test instead of only once
#    if TEST
    block();
#    else
    static dispatch_once_t once;
    [self.dispatchQueue dispatchOnce:&once block:block];
#    endif
}

/**
 * This is when the first frame is drawn.
 */
- (void)didBecomeVisible
{
    [self buildAppStartMeasurement];
}

- (BuzzSentryAppStartType)getStartType
{
    // App launched the first time
    if (self.previousAppState == nil) {
        return BuzzSentryAppStartTypeCold;
    }

    BuzzSentryAppState *currentAppState = [self.appStateManager buildCurrentAppState];

    // If the release name is different we assume it's an app upgrade
    if (![currentAppState.releaseName isEqualToString:self.previousAppState.releaseName]) {
        return BuzzSentryAppStartTypeCold;
    }

    NSTimeInterval intervalSincePreviousBootTime = [self.previousAppState.systemBootTimestamp
        timeIntervalSinceDate:currentAppState.systemBootTimestamp];

    // System rebooted, because the previous boot time is in the past.
    if (intervalSincePreviousBootTime < 0) {
        return BuzzSentryAppStartTypeCold;
    }

    // System didn't reboot, previous and current boot time are the same.
    if (intervalSincePreviousBootTime == 0) {
        return BuzzSentryAppStartTypeWarm;
    }

    // This should never be reached as we unsubscribe to didBecomeActive after it is called the
    // first time. If the previous boot time is in the future most likely the system time
    // changed and we can't to anything.
    return BuzzSentryAppStartTypeUnknown;
}

- (void)didFinishLaunching
{
    self.didFinishLaunchingTimestamp = [self.currentDate date];
}

- (void)didEnterBackground
{
    self.wasInBackground = YES;
}

- (void)stop
{
    // Remove the observers with the most specific detail possible, see
    // https://developer.apple.com/documentation/foundation/nsnotificationcenter/1413994-removeobserver
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidFinishLaunchingNotification
                                                object:nil];

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIWindowDidBecomeVisibleNotification
                                                object:nil];

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidEnterBackgroundNotification
                                                object:nil];

#    if SENTRY_HAS_UIKIT
    [self.appStateManager stop];
#    endif
}

- (void)dealloc
{
    [self stop];
    // In dealloc it's safe to unsubscribe for all, see
    // https://developer.apple.com/documentation/foundation/nsnotificationcenter/1413994-removeobserver
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

/**
 * Needed for testing, not public.
 */
- (void)setRuntimeInit:(NSDate *)value
{
    runtimeInit = value;
}

@end

#endif
