#import "BuzzSentryANRTracker.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryUIApplication.h"
#import <BuzzSentryAppStateManager.h>
#import <BuzzSentryClient+Private.h>
#import <BuzzSentryCrashWrapper.h>
#import <BuzzSentryDebugImageProvider.h>
#import <BuzzSentryDefaultCurrentDateProvider.h>
#import <SentryDependencyContainer.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <BuzzSentryHub.h>
#import <SentryNSNotificationCenterWrapper.h>
#import <BuzzSentrySDK+Private.h>
#import <BuzzSentryScreenshot.h>
#import <BuzzSentrySwizzleWrapper.h>
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

- (BuzzSentryFileManager *)fileManager
{
    @synchronized(sentryDependencyContainerLock) {
        if (_fileManager == nil) {
            _fileManager = [[[BuzzSentrySDK currentHub] getClient] fileManager];
        }
        return _fileManager;
    }
}

- (BuzzSentryAppStateManager *)appStateManager
{
    @synchronized(sentryDependencyContainerLock) {
        if (_appStateManager == nil) {
            BuzzSentryOptions *options = [[[BuzzSentrySDK currentHub] getClient] options];
            _appStateManager = [[BuzzSentryAppStateManager alloc]
                     initWithOptions:options
                        crashWrapper:self.crashWrapper
                         fileManager:self.fileManager
                 currentDateProvider:[BuzzSentryDefaultCurrentDateProvider sharedInstance]
                              sysctl:[[SentrySysctl alloc] init]
                dispatchQueueWrapper:self.dispatchQueueWrapper];
        }
        return _appStateManager;
    }
}

- (BuzzSentryCrashWrapper *)crashWrapper
{
    if (_crashWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_crashWrapper == nil) {
                _crashWrapper = [BuzzSentryCrashWrapper sharedInstance];
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

- (BuzzSentrySwizzleWrapper *)swizzleWrapper
{
    if (_swizzleWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_swizzleWrapper == nil) {
                _swizzleWrapper = BuzzSentrySwizzleWrapper.sharedInstance;
            }
        }
    }
    return _swizzleWrapper;
}

- (BuzzSentryDebugImageProvider *)debugImageProvider
{
    if (_debugImageProvider == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_debugImageProvider == nil) {
                _debugImageProvider = [[BuzzSentryDebugImageProvider alloc] init];
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
                        currentDateProvider:[BuzzSentryDefaultCurrentDateProvider sharedInstance]
                               crashWrapper:self.crashWrapper
                       dispatchQueueWrapper:[[BuzzSentryDispatchQueueWrapper alloc] init]
                              threadWrapper:self.threadWrapper];
            }
        }
    }
    return _anrTracker;
}

@end
