#import "BuzzSentryANRTracker.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryUIApplication.h"
#import <BuzzSentryAppStateManager.h>
#import <BuzzSentryClient+Private.h>
#import <BuzzSentryCrashWrapper.h>
#import <BuzzSentryDebugImageProvider.h>
#import <BuzzSentryDefaultCurrentDateProvider.h>
#import <BuzzSentryDependencyContainer.h>
#import <BuzzSentryDispatchQueueWrapper.h>
#import <BuzzSentryHub.h>
#import <BuzzSentryNSNotificationCenterWrapper.h>
#import <BuzzSentrySDK+Private.h>
#import <BuzzSentryScreenshot.h>
#import <BuzzSentrySwizzleWrapper.h>
#import <BuzzSentrySysctl.h>
#import <BuzzSentryThreadWrapper.h>
#import <BuzzSentryViewHierarchy.h>

@implementation BuzzSentryDependencyContainer

static BuzzSentryDependencyContainer *instance;
static NSObject *BuzzSentryDependencyContainerLock;

+ (void)initialize
{
    if (self == [BuzzSentryDependencyContainer class]) {
        BuzzSentryDependencyContainerLock = [[NSObject alloc] init];
    }
}

+ (instancetype)sharedInstance
{
    @synchronized(BuzzSentryDependencyContainerLock) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
        return instance;
    }
}

+ (void)reset
{
    @synchronized(BuzzSentryDependencyContainerLock) {
        instance = nil;
    }
}

- (BuzzSentryFileManager *)fileManager
{
    @synchronized(BuzzSentryDependencyContainerLock) {
        if (_fileManager == nil) {
            _fileManager = [[[BuzzSentrySDK currentHub] getClient] fileManager];
        }
        return _fileManager;
    }
}

- (BuzzSentryAppStateManager *)appStateManager
{
    @synchronized(BuzzSentryDependencyContainerLock) {
        if (_appStateManager == nil) {
            BuzzSentryOptions *options = [[[BuzzSentrySDK currentHub] getClient] options];
            _appStateManager = [[BuzzSentryAppStateManager alloc]
                     initWithOptions:options
                        crashWrapper:self.crashWrapper
                         fileManager:self.fileManager
                 currentDateProvider:[BuzzSentryDefaultCurrentDateProvider sharedInstance]
                              sysctl:[[BuzzSentrySysctl alloc] init]
                dispatchQueueWrapper:self.dispatchQueueWrapper];
        }
        return _appStateManager;
    }
}

- (BuzzSentryCrashWrapper *)crashWrapper
{
    if (_crashWrapper == nil) {
        @synchronized(BuzzSentryDependencyContainerLock) {
            if (_crashWrapper == nil) {
                _crashWrapper = [BuzzSentryCrashWrapper sharedInstance];
            }
        }
    }
    return _crashWrapper;
}

- (BuzzSentryThreadWrapper *)threadWrapper
{
    if (_threadWrapper == nil) {
        @synchronized(BuzzSentryDependencyContainerLock) {
            if (_threadWrapper == nil) {
                _threadWrapper = [[BuzzSentryThreadWrapper alloc] init];
            }
        }
    }
    return _threadWrapper;
}

- (BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    @synchronized(BuzzSentryDependencyContainerLock) {
        if (_dispatchQueueWrapper == nil) {
            _dispatchQueueWrapper = [[BuzzSentryDispatchQueueWrapper alloc] init];
        }
        return _dispatchQueueWrapper;
    }
}

- (BuzzSentryNSNotificationCenterWrapper *)notificationCenterWrapper
{
    @synchronized(BuzzSentryDependencyContainerLock) {
        if (_notificationCenterWrapper == nil) {
            _notificationCenterWrapper = [[BuzzSentryNSNotificationCenterWrapper alloc] init];
        }
        return _notificationCenterWrapper;
    }
}

- (id<BuzzSentryRandom>)random
{
    if (_random == nil) {
        @synchronized(BuzzSentryDependencyContainerLock) {
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
        @synchronized(BuzzSentryDependencyContainerLock) {
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
        @synchronized(BuzzSentryDependencyContainerLock) {
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
        @synchronized(BuzzSentryDependencyContainerLock) {
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
        @synchronized(BuzzSentryDependencyContainerLock) {
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
        @synchronized(BuzzSentryDependencyContainerLock) {
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
        @synchronized(BuzzSentryDependencyContainerLock) {
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
