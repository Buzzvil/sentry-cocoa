#import "BuzzSentryANRTracker.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryUIApplication.h"
#import <SentryAppStateManager.h>
#import <BuzzSentryClient+Private.h>
#import <SentryCrashWrapper.h>
#import <SentryDebugImageProvider.h>
#import <SentryDefaultCurrentDateProvider.h>
#import <SentryDependencyContainer.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <SentryHub.h>
#import <SentryNSNotificationCenterWrapper.h>
#import <BuzzSentrySDK+Private.h>
#import <BuzzSentryScreenshot.h>
#import <SentrySwizzleWrapper.h>
#import <SentrySysctl.h>
#import <SentryThreadWrapper.h>
#import <BuzzSentryViewHierarchy.h>

@implementation SentryDependencyContainer

static SentryDependencyContainer *instance;
static NSObject *sentryDependencyContainerLock;

+ (void)initialize
{
    if (self == [SentryDependencyContainer class]) {
        sentryDependencyContainerLock = [[NSObject alloc] init];
    }
}

+ (instancetype)sharedInstance
{
    @synchronized(sentryDependencyContainerLock) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
        return instance;
    }
}

+ (void)reset
{
    @synchronized(sentryDependencyContainerLock) {
        instance = nil;
    }
}

- (SentryFileManager *)fileManager
{
    @synchronized(sentryDependencyContainerLock) {
        if (_fileManager == nil) {
            _fileManager = [[[SentrySDK currentHub] getClient] fileManager];
        }
        return _fileManager;
    }
}

- (SentryAppStateManager *)appStateManager
{
    @synchronized(sentryDependencyContainerLock) {
        if (_appStateManager == nil) {
            BuzzSentryOptions *options = [[[SentrySDK currentHub] getClient] options];
            _appStateManager = [[SentryAppStateManager alloc]
                     initWithOptions:options
                        crashWrapper:self.crashWrapper
                         fileManager:self.fileManager
                 currentDateProvider:[SentryDefaultCurrentDateProvider sharedInstance]
                              sysctl:[[SentrySysctl alloc] init]
                dispatchQueueWrapper:self.dispatchQueueWrapper];
        }
        return _appStateManager;
    }
}

- (SentryCrashWrapper *)crashWrapper
{
    if (_crashWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_crashWrapper == nil) {
                _crashWrapper = [SentryCrashWrapper sharedInstance];
            }
        }
    }
    return _crashWrapper;
}

- (SentryThreadWrapper *)threadWrapper
{
    if (_threadWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_threadWrapper == nil) {
                _threadWrapper = [[SentryThreadWrapper alloc] init];
            }
        }
    }
    return _threadWrapper;
}

- (BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    @synchronized(sentryDependencyContainerLock) {
        if (_dispatchQueueWrapper == nil) {
            _dispatchQueueWrapper = [[BuzzSentryDispatchQueueWrapper alloc] init];
        }
        return _dispatchQueueWrapper;
    }
}

- (SentryNSNotificationCenterWrapper *)notificationCenterWrapper
{
    @synchronized(sentryDependencyContainerLock) {
        if (_notificationCenterWrapper == nil) {
            _notificationCenterWrapper = [[SentryNSNotificationCenterWrapper alloc] init];
        }
        return _notificationCenterWrapper;
    }
}

- (id<BuzzSentryRandom>)random
{
    if (_random == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_random == nil) {
                _random = [[BuzzSentryRandom alloc] init];
            }
        }
    }
    return _random;
}

#if SENTRY_HAS_UIKIT
- (BuzzSentryScreenshot *)screenshot
{
    if (_screenshot == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_screenshot == nil) {
                _screenshot = [[BuzzSentryScreenshot alloc] init];
            }
        }
    }
    return _screenshot;
}

- (BuzzSentryViewHierarchy *)viewHierarchy
{
    if (_viewHierarchy == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_viewHierarchy == nil) {
                _viewHierarchy = [[BuzzSentryViewHierarchy alloc] init];
            }
        }
    }
    return _viewHierarchy;
}

- (BuzzSentryUIApplication *)application
{
    if (_application == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_application == nil) {
                _application = [[BuzzSentryUIApplication alloc] init];
            }
        }
    }
    return _application;
}
#endif

- (SentrySwizzleWrapper *)swizzleWrapper
{
    if (_swizzleWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_swizzleWrapper == nil) {
                _swizzleWrapper = SentrySwizzleWrapper.sharedInstance;
            }
        }
    }
    return _swizzleWrapper;
}

- (SentryDebugImageProvider *)debugImageProvider
{
    if (_debugImageProvider == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_debugImageProvider == nil) {
                _debugImageProvider = [[SentryDebugImageProvider alloc] init];
            }
        }
    }

    return _debugImageProvider;
}

- (BuzzSentryANRTracker *)getANRTracker:(NSTimeInterval)timeout
{
    if (_anrTracker == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_anrTracker == nil) {
                _anrTracker = [[BuzzSentryANRTracker alloc]
                    initWithTimeoutInterval:timeout
                        currentDateProvider:[SentryDefaultCurrentDateProvider sharedInstance]
                               crashWrapper:self.crashWrapper
                       dispatchQueueWrapper:[[BuzzSentryDispatchQueueWrapper alloc] init]
                              threadWrapper:self.threadWrapper];
            }
        }
    }
    return _anrTracker;
}

@end
