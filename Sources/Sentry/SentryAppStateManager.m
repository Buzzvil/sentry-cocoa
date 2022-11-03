#import "SentryCrashSysCtl.h"
#import "SentrySysctl.h"
#import <Foundation/Foundation.h>
#import <SentryAppState.h>
#import <SentryAppStateManager.h>
#import <BuzzSentryCrashWrapper.h>
#import <SentryCurrentDateProvider.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <SentryFileManager.h>
#import <BuzzSentryOptions.h>

#if SENTRY_HAS_UIKIT
#    import <BuzzSentryInternalNotificationNames.h>
#    import <SentryNSNotificationCenterWrapper.h>
#    import <UIKit/UIKit.h>
#endif

@interface
SentryAppStateManager ()

@property (nonatomic, strong) BuzzSentryOptions *options;
@property (nonatomic, strong) BuzzSentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryFileManager *fileManager;
@property (nonatomic, strong) id<SentryCurrentDateProvider> currentDate;
@property (nonatomic, strong) SentrySysctl *sysctl;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueue;
@property (nonatomic) NSInteger startCount;

@end

@implementation SentryAppStateManager

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
                   crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                    fileManager:(SentryFileManager *)fileManager
            currentDateProvider:(id<SentryCurrentDateProvider>)currentDateProvider
                         sysctl:(SentrySysctl *)sysctl
           dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    if (self = [super init]) {
        self.options = options;
        self.crashWrapper = crashWrapper;
        self.fileManager = fileManager;
        self.currentDate = currentDateProvider;
        self.sysctl = sysctl;
        self.dispatchQueue = dispatchQueueWrapper;
        self.startCount = 0;
    }
    return self;
}

#if SENTRY_HAS_UIKIT

- (void)start
{
    if (self.startCount == 0) {
        [NSNotificationCenter.defaultCenter
            addObserver:self
               selector:@selector(didBecomeActive)
                   name:SentryNSNotificationCenterWrapper.didBecomeActiveNotificationName
                 object:nil];

        [NSNotificationCenter.defaultCenter
            addObserver:self
               selector:@selector(didBecomeActive)
                   name:SentryHybridSdkDidBecomeActiveNotificationName
                 object:nil];

        [NSNotificationCenter.defaultCenter
            addObserver:self
               selector:@selector(willResignActive)
                   name:SentryNSNotificationCenterWrapper.willResignActiveNotificationName
                 object:nil];

        [NSNotificationCenter.defaultCenter
            addObserver:self
               selector:@selector(willTerminate)
                   name:SentryNSNotificationCenterWrapper.willTerminateNotificationName
                 object:nil];

        [self storeCurrentAppState];
    }

    self.startCount += 1;
}

- (void)stop
{
    if (self.startCount <= 0) {
        return;
    }

    self.startCount -= 1;

    if (self.startCount == 0) {
        // Remove the observers with the most specific detail possible, see
        // https://developer.apple.com/documentation/foundation/nsnotificationcenter/1413994-removeobserver
        [NSNotificationCenter.defaultCenter
            removeObserver:self
                      name:SentryNSNotificationCenterWrapper.didBecomeActiveNotificationName
                    object:nil];

        [NSNotificationCenter.defaultCenter
            removeObserver:self
                      name:SentryHybridSdkDidBecomeActiveNotificationName
                    object:nil];

        [NSNotificationCenter.defaultCenter
            removeObserver:self
                      name:SentryNSNotificationCenterWrapper.willResignActiveNotificationName
                    object:nil];

        [NSNotificationCenter.defaultCenter
            removeObserver:self
                      name:SentryNSNotificationCenterWrapper.willTerminateNotificationName
                    object:nil];

        [self deleteAppState];
    }
}

- (void)dealloc
{
    // In dealloc it's safe to unsubscribe for all, see
    // https://developer.apple.com/documentation/foundation/nsnotificationcenter/1413994-removeobserver
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self deleteAppState];
}

/**
 * It is called when an app is receiving events / it is in the foreground and when we receive a
 * SentryHybridSdkDidBecomeActiveNotification.
 *
 * This also works when using SwiftUI or Scenes, as UIKit posts a didBecomeActiveNotification
 * regardless of whether your app uses scenes, see
 * https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622956-applicationdidbecomeactive.
 */
- (void)didBecomeActive
{
    [self updateAppStateInBackground:^(SentryAppState *appState) { appState.isActive = YES; }];
}

/**
 * The app is about to lose focus / going to the background. This is only called when an app was
 * receiving events / was is in the foreground.
 */
- (void)willResignActive
{
    [self updateAppStateInBackground:^(SentryAppState *appState) { appState.isActive = NO; }];
}

- (void)willTerminate
{
    // The app is terminating so it is fine to do this on the main thread.
    // Furthermore, so users can manually post UIApplicationWillTerminateNotification and then call
    // exit(0), to avoid getting false OOM when using exit(0), see GH-1252.
    [self updateAppState:^(SentryAppState *appState) { appState.wasTerminated = YES; }];
}

- (void)updateAppStateInBackground:(void (^)(SentryAppState *))block
{
    // We accept the tradeoff that the app state might not be 100% up to date over blocking the main
    // thread.
    [self.dispatchQueue dispatchAsyncWithBlock:^{ [self updateAppState:block]; }];
}

- (void)updateAppState:(void (^)(SentryAppState *))block
{
    @synchronized(self) {
        SentryAppState *appState = [self.fileManager readAppState];
        if (nil != appState) {
            block(appState);
            [self.fileManager storeAppState:appState];
        }
    }
}

- (SentryAppState *)buildCurrentAppState
{
    // Is the current process being traced or not? If it is a debugger is attached.
    bool isDebugging = self.crashWrapper.isBeingTraced;

    NSString *vendorId = [UIDevice.currentDevice.identifierForVendor UUIDString];

    return [[SentryAppState alloc] initWithReleaseName:self.options.releaseName
                                             osVersion:UIDevice.currentDevice.systemVersion
                                              vendorId:vendorId
                                           isDebugging:isDebugging
                                   systemBootTimestamp:self.sysctl.systemBootTimestamp];
}

- (SentryAppState *)loadPreviousAppState
{
    return [self.fileManager readPreviousAppState];
}

- (void)storeCurrentAppState
{
    [self.fileManager storeAppState:[self buildCurrentAppState]];
}

- (void)deleteAppState
{
    [self.fileManager deleteAppState];
}

#endif

@end
