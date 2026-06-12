#import <Foundation/Foundation.h>
#import <BuzzSentryAppState.h>
#import <BuzzSentryAppStateManager.h>
#import <BuzzSentryCrashWrapper.h>
#import <BuzzSentryOptions.h>
#import <BuzzSentryOutOfMemoryLogic.h>
#import <BuzzSentrySDK+Private.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#endif

@interface
BuzzSentryOutOfMemoryLogic ()

@property (nonatomic, strong) BuzzSentryOptions *options;
@property (nonatomic, strong) BuzzSentryCrashWrapper *crashAdapter;
@property (nonatomic, strong) BuzzSentryAppStateManager *appStateManager;

@end

@implementation BuzzSentryOutOfMemoryLogic

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                   crashAdapter:(BuzzSentryCrashWrapper *)crashAdapter
                appStateManager:(BuzzSentryAppStateManager *)appStateManager
{
    if (self = [super init]) {
        self.options = options;
        self.crashAdapter = crashAdapter;
        self.appStateManager = appStateManager;
    }
    return self;
}

- (BOOL)isOOM
{
    if (!self.options.enableOutOfMemoryTracking) {
        return NO;
    }

#if SENTRY_HAS_UIKIT
    BuzzSentryAppState *previousAppState = [self.appStateManager loadPreviousAppState];
    BuzzSentryAppState *currentAppState = [self.appStateManager buildCurrentAppState];

    // If there is no previous app state, we can't do anything.
    if (nil == previousAppState) {
        return NO;
    }

    if (self.crashAdapter.isSimulatorBuild) {
        return NO;
    }

    // If the release name is different we assume it's an upgrade
    if (![currentAppState.releaseName isEqualToString:previousAppState.releaseName]) {
        return NO;
    }

    // The OS was upgraded
    if (![currentAppState.osVersion isEqualToString:previousAppState.osVersion]) {
        return NO;
    }

    // This value can change when installing test builds using Xcode or when installing an app
    // on a device using ad-hoc distribution.
    if (![currentAppState.vendorId isEqualToString:previousAppState.vendorId]) {
        return NO;
    }

    // Restarting the app in development is a termination we can't catch and would falsely
    // report OOMs.
    if (previousAppState.isDebugging) {
        return NO;
    }

    // The app was terminated normally
    if (previousAppState.wasTerminated) {
        return NO;
    }

    // The app crashed on the previous run. No OOM.
    if (self.crashAdapter.crashedLastLaunch) {
        return NO;
    }

    // Was the app in foreground/active ?
    // If the app was in background we can't reliably tell if it was an OOM or not.
    if (!previousAppState.isActive) {
        return NO;
    }

    if (previousAppState.isANROngoing) {
        return NO;
    }

    // When calling BuzzSentrySDK.start twice we would wrongly report an OOM. We can only
    // report an OOM when the SDK is started the first time.
    if (BuzzSentrySDK.startInvocations != 1) {
        return NO;
    }

    return YES;
#else
    // We can only track OOMs for iOS, tvOS and macCatalyst. Therefore we return NO for other
    // platforms.
    return NO;
#endif
}

@end
