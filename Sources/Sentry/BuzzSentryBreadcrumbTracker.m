#import "BuzzSentryBreadcrumbTracker.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient.h"
#import "BuzzSentryDefines.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryLog.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope.h"
#import "BuzzSentrySwizzle.h"
#import "BuzzSentrySwizzleWrapper.h"
#import "BuzzSentryUIViewControllerSanitizer.h"

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
#    import <Cocoa/Cocoa.h>
#endif

NS_ASSUME_NONNULL_BEGIN

static NSString *const BuzzSentryBreadcrumbTrackerSwizzleSendAction
    = @"BuzzSentryBreadcrumbTrackerSwizzleSendAction";

@interface
BuzzSentryBreadcrumbTracker ()

@property (nonatomic, strong) BuzzSentrySwizzleWrapper *swizzleWrapper;

@end

@implementation BuzzSentryBreadcrumbTracker

- (instancetype)initWithSwizzleWrapper:(BuzzSentrySwizzleWrapper *)swizzleWrapper
{
    if (self = [super init]) {
        self.swizzleWrapper = swizzleWrapper;
    }
    return self;
}

- (void)start
{
    [self addEnabledCrumb];
    [self trackApplicationUIKitNotifications];
}

- (void)startSwizzle
{
    [self swizzleSendAction];
    [self swizzleViewDidAppear];
}

- (void)stop
{
    // All breadcrumbs are guarded by checking the client of the current hub, which we remove when
    // uninstalling the SDK. Therefore, we don't clean up everything.
#if SENTRY_HAS_UIKIT
    [self.swizzleWrapper removeSwizzleSendActionForKey:BuzzSentryBreadcrumbTrackerSwizzleSendAction];
#endif
}

- (void)trackApplicationUIKitNotifications
{
#if SENTRY_HAS_UIKIT
    NSNotificationName foregroundNotificationName = UIApplicationDidBecomeActiveNotification;
    NSNotificationName backgroundNotificationName = UIApplicationDidEnterBackgroundNotification;
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    NSNotificationName foregroundNotificationName = NSApplicationDidBecomeActiveNotification;
    // Will resign Active notification is the nearest one to
    // UIApplicationDidEnterBackgroundNotification
    NSNotificationName backgroundNotificationName = NSApplicationWillResignActiveNotification;
#else
    SENTRY_LOG_DEBUG(@"NO UIKit, OSX and Catalyst -> [BuzzSentryBreadcrumbTracker "
                     @"trackApplicationUIKitNotifications] does nothing.");
#endif

    // not available for macOS
#if SENTRY_HAS_UIKIT
    [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) {
                    if (nil != [BuzzSentrySDK.currentHub getClient]) {
                        BuzzSentryBreadcrumb *crumb =
                            [[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelWarning
                                                           category:@"device.event"];
                        crumb.type = @"system";
                        crumb.data = @ { @"action" : @"LOW_MEMORY" };
                        crumb.message = @"Low memory";
                        [BuzzSentrySDK addBreadcrumb:crumb];
                    }
                }];
#endif

#if SENTRY_HAS_UIKIT || TARGET_OS_OSX || TARGET_OS_MACCATALYST
    [NSNotificationCenter.defaultCenter addObserverForName:backgroundNotificationName
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *notification) {
                                                    [self addBreadcrumbWithType:@"navigation"
                                                                   withCategory:@"app.lifecycle"
                                                                      withLevel:kSentryLevelInfo
                                                                    withDataKey:@"state"
                                                                  withDataValue:@"background"];
                                                }];

    [NSNotificationCenter.defaultCenter addObserverForName:foregroundNotificationName
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *notification) {
                                                    [self addBreadcrumbWithType:@"navigation"
                                                                   withCategory:@"app.lifecycle"
                                                                      withLevel:kSentryLevelInfo
                                                                    withDataKey:@"state"
                                                                  withDataValue:@"foreground"];
                                                }];
#endif
}

- (void)addBreadcrumbWithType:(NSString *)type
                 withCategory:(NSString *)category
                    withLevel:(SentryLevel)level
                  withDataKey:(NSString *)key
                withDataValue:(NSString *)value
{
    if (nil != [BuzzSentrySDK.currentHub getClient]) {
        BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:level category:category];
        crumb.type = type;
        crumb.data = @{ key : value };
        [BuzzSentrySDK addBreadcrumb:crumb];
    }
}

- (void)addEnabledCrumb
{
    BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelInfo
                                                             category:@"started"];
    crumb.type = @"debug";
    crumb.message = @"Breadcrumb Tracking";
    [BuzzSentrySDK addBreadcrumb:crumb];
}

- (void)swizzleSendAction
{
#if SENTRY_HAS_UIKIT

    [self.swizzleWrapper
        swizzleSendAction:^(NSString *action, id target, id sender, UIEvent *event) {
            if ([BuzzSentrySDK.currentHub getClient] == nil) {
                return;
            }

            NSDictionary *data = nil;
            for (UITouch *touch in event.allTouches) {
                if (touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded) {
                    data = [BuzzSentryBreadcrumbTracker extractDataFromView:touch.view];
                }
            }

            BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelInfo
                                                                     category:@"touch"];
            crumb.type = @"user";
            crumb.message = action;
            crumb.data = data;
            [BuzzSentrySDK addBreadcrumb:crumb];
        }
                   forKey:BuzzSentryBreadcrumbTrackerSwizzleSendAction];

#else
    SENTRY_LOG_DEBUG(@"NO UIKit -> [BuzzSentryBreadcrumbTracker swizzleSendAction] does nothing.");
#endif
}

- (void)swizzleViewDidAppear
{
#if SENTRY_HAS_UIKIT

    // BuzzSentrySwizzleInstanceMethod declaration shadows a local variable. The swizzling is working
    // fine and we accept this warning.
#    pragma clang diagnostic push
#    pragma clang diagnostic ignored "-Wshadow"

    static const void *swizzleViewDidAppearKey = &swizzleViewDidAppearKey;
    SEL selector = NSSelectorFromString(@"viewDidAppear:");
    BuzzSentrySwizzleInstanceMethod(UIViewController.class, selector, SentrySWReturnType(void),
        SentrySWArguments(BOOL animated), SentrySWReplacement({
            if (nil != [BuzzSentrySDK.currentHub getClient]) {
                BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelInfo
                                                                         category:@"ui.lifecycle"];
                crumb.type = @"navigation";
                crumb.data = [BuzzSentryBreadcrumbTracker fetchInfoAboutViewController:self];

                // Adding crumb via the SDK calls SentryBeforeBreadcrumbCallback
                [BuzzSentrySDK addBreadcrumb:crumb];
                [BuzzSentrySDK.currentHub configureScope:^(BuzzSentryScope *_Nonnull scope) {
                    [scope setExtraValue:crumb.data[@"screen"] forKey:@"__sentry_transaction"];
                }];
            }
            SentrySWCallOriginal(animated);
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, swizzleViewDidAppearKey);
#    pragma clang diagnostic pop
#else
    SENTRY_LOG_DEBUG(@"NO UIKit -> [BuzzSentryBreadcrumbTracker swizzleViewDidAppear] does nothing.");
#endif
}

#if SENTRY_HAS_UIKIT
+ (NSDictionary *)extractDataFromView:(UIView *)view
{
    NSMutableDictionary *result =
        @{ @"view" : [NSString stringWithFormat:@"%@", view] }.mutableCopy;

    if (view.tag > 0) {
        [result setValue:[NSNumber numberWithInteger:view.tag] forKey:@"tag"];
    }

    if (view.accessibilityIdentifier && ![view.accessibilityIdentifier isEqualToString:@""]) {
        [result setValue:view.accessibilityIdentifier forKey:@"accessibilityIdentifier"];
    }

    if ([view isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)view;
        if (button.currentTitle && ![button.currentTitle isEqual:@""]) {
            [result setValue:[button currentTitle] forKey:@"title"];
        }
    }

    return result;
}

+ (NSDictionary *)fetchInfoAboutViewController:(UIViewController *)controller
{
    NSMutableDictionary *info = @{}.mutableCopy;

    info[@"screen"] = [BuzzSentryUIViewControllerSanitizer
        sanitizeViewControllerName:[NSString stringWithFormat:@"%@", controller]];

    if ([controller.navigationItem.title length] != 0) {
        info[@"title"] = controller.navigationItem.title;
    } else if ([controller.title length] != 0) {
        info[@"title"] = controller.title;
    }

    info[@"beingPresented"] = controller.beingPresented ? @"true" : @"false";

    if (controller.presentingViewController != nil) {
        info[@"presentingViewController"] = [BuzzSentryUIViewControllerSanitizer
            sanitizeViewControllerName:controller.presentingViewController];
    }

    if (controller.parentViewController != nil) {
        info[@"parentViewController"] = [BuzzSentryUIViewControllerSanitizer
            sanitizeViewControllerName:controller.parentViewController];
    }

    if (controller.view.window != nil) {
        info[@"window"] = controller.view.window.description;
        info[@"window_isKeyWindow"] = controller.view.window.isKeyWindow ? @"true" : @"false";
        info[@"window_windowLevel"] =
            [NSString stringWithFormat:@"%f", controller.view.window.windowLevel];
        info[@"is_window_rootViewController"]
            = controller.view.window.rootViewController == controller ? @"true" : @"false";
    }

    return info;
}
#endif

@end

NS_ASSUME_NONNULL_END
