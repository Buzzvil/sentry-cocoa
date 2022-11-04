#import "BuzzSentryCrashIntegration.h"
#import "BuzzSentryCrashInstallationReporter.h"
#import "BuzzSentryCrashWrapper.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryEvent.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryInAppLogic.h"
#import "BuzzSentryOutOfMemoryLogic.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope+Private.h"
#import "BuzzSentrySessionCrashedHandler.h"
#import <BuzzSentryAppStateManager.h>
#import <BuzzSentryClient+Private.h>
#import <BuzzSentryCrashScopeObserver.h>
#import <BuzzSentryDefaultCurrentDateProvider.h>
#import <BuzzSentryDependencyContainer.h>
#import <BuzzSentrySDK+Private.h>
#import <BuzzSentrySysctl.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#endif

static dispatch_once_t installationToken = 0;
static BuzzSentryCrashInstallationReporter *installation = nil;

static NSString *const DEVICE_KEY = @"device";
static NSString *const LOCALE_KEY = @"locale";

@interface
BuzzSentryCrashIntegration ()

@property (nonatomic, weak) BuzzSentryOptions *options;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, strong) BuzzSentryCrashWrapper *crashAdapter;
@property (nonatomic, strong) BuzzSentrySessionCrashedHandler *crashedSessionHandler;
@property (nonatomic, strong) BuzzSentryCrashScopeObserver *scopeObserver;

@end

@implementation BuzzSentryCrashIntegration

- (instancetype)init
{
    self = [self initWithCrashAdapter:[BuzzSentryCrashWrapper sharedInstance]
              andDispatchQueueWrapper:[[BuzzSentryDispatchQueueWrapper alloc] init]];

    return self;
}

/** Internal constructor for testing */
- (instancetype)initWithCrashAdapter:(BuzzSentryCrashWrapper *)crashAdapter
             andDispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    if (self = [super init]) {
        self.crashAdapter = crashAdapter;
        self.dispatchQueueWrapper = dispatchQueueWrapper;
    }

    return self;
}

- (BOOL)installWithOptions:(nonnull BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    self.options = options;

    BuzzSentryAppStateManager *appStateManager =
        [BuzzSentryDependencyContainer sharedInstance].appStateManager;
    BuzzSentryOutOfMemoryLogic *logic =
        [[BuzzSentryOutOfMemoryLogic alloc] initWithOptions:options
                                           crashAdapter:self.crashAdapter
                                        appStateManager:appStateManager];
    self.crashedSessionHandler =
        [[BuzzSentrySessionCrashedHandler alloc] initWithCrashWrapper:self.crashAdapter
                                                 outOfMemoryLogic:logic];

    self.scopeObserver =
        [[BuzzSentryCrashScopeObserver alloc] initWithMaxBreadcrumbs:options.maxBreadcrumbs];

    [self startCrashHandler];

    if (options.stitchAsyncCode) {
        [self.crashAdapter installAsyncHooks];
    }

    [self configureScope];

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableCrashHandler;
}

- (void)startCrashHandler
{
    void (^block)(void) = ^{
        BOOL canSendReports = NO;
        if (installation == nil) {
            BuzzSentryInAppLogic *inAppLogic =
                [[BuzzSentryInAppLogic alloc] initWithInAppIncludes:self.options.inAppIncludes
                                                  inAppExcludes:self.options.inAppExcludes];

            installation = [[BuzzSentryCrashInstallationReporter alloc]
                initWithInAppLogic:inAppLogic
                      crashWrapper:self.crashAdapter
                     dispatchQueue:self.dispatchQueueWrapper];

            canSendReports = YES;
        }

        [installation install];

        // We need to send the crashed event together with the crashed session in the same envelope
        // to have proper statistics in release health. To achieve this we need both synchronously
        // in the hub. The crashed event is converted from a BuzzSentryCrashReport to an event in
        // BuzzSentryCrashReportSink and then passed to the SDK on a background thread. This process is
        // started with installing this integration. We need to end and delete the previous session
        // before being able to start a new session for the AutoSessionTrackingIntegration. The
        // BuzzSentryCrashIntegration is installed before the AutoSessionTrackingIntegration so there is
        // no guarantee if the crashed event is created before or after the
        // AutoSessionTrackingIntegration. By ending the previous session and storing it as crashed
        // in here we have the guarantee once the crashed event is sent to the hub it is already
        // there and the AutoSessionTrackingIntegration can work properly.
        //
        // This is a pragmatic and not the most optimal place for this logic.
        [self.crashedSessionHandler endCurrentSessionAsCrashedWhenCrashOrOOM];

        // We only need to send all reports on the first initialization of BuzzSentryCrash. If
        // SenryCrash was deactivated there are no new reports to send. Furthermore, the
        // g_reportsPath in BuzzSentryCrashReportsStore gets set when BuzzSentryCrash is installed. In
        // production usage, this path is not supposed to change. When testing, this path can
        // change, and therefore, the initial set g_reportsPath can be deleted. sendAllReports calls
        // deleteAllReports, which fails it can't access g_reportsPath. We could fix BuzzSentryCrash or
        // just not call sendAllReports as it doesn't make sense to call it twice as described
        // above.
        if (canSendReports) {
            [BuzzSentryCrashIntegration sendAllBuzzSentryCrashReports];
        }
    };
    [self.dispatchQueueWrapper dispatchOnce:&installationToken block:block];
}

/**
 * Internal, only needed for testing.
 */
+ (void)sendAllBuzzSentryCrashReports
{
    [installation sendAllReports];
}

- (void)uninstall
{
    if (nil != installation) {
        [self.crashAdapter close];
        installationToken = 0;
    }

    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:NSCurrentLocaleDidChangeNotification
                                                object:nil];
}

- (void)configureScope
{
    // We need to make sure to set always the scope to KSCrash so we have it in
    // case of a crash
    [BuzzSentrySDK.currentHub configureScope:^(BuzzSentryScope *_Nonnull outerScope) {
        [BuzzSentryCrashIntegration enrichScope:outerScope crashWrapper:self.crashAdapter];

        NSMutableDictionary<NSString *, id> *userInfo =
            [[NSMutableDictionary alloc] initWithDictionary:[outerScope serialize]];
        // BuzzSentryCrashReportConverter.convertReportToEvent needs the release name and
        // the dist of the BuzzSentryOptions in the UserInfo. When BuzzSentryCrash records a
        // crash it writes the UserInfo into BuzzSentryCrashField_User of the report.
        // BuzzSentryCrashReportConverter.initWithReport loads the contents of
        // BuzzSentryCrashField_User into self.userContext and convertReportToEvent can map
        // the release name and dist to the BuzzSentryEvent. Fixes GH-581
        userInfo[@"release"] = self.options.releaseName;
        userInfo[@"dist"] = self.options.dist;

        [BuzzSentryCrash.sharedInstance setUserInfo:userInfo];

        [outerScope addObserver:self.scopeObserver];
    }];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(currentLocaleDidChange)
                                               name:NSCurrentLocaleDidChangeNotification
                                             object:nil];
}

+ (void)enrichScope:(BuzzSentryScope *)scope crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
{
    // OS
    NSMutableDictionary *osData = [NSMutableDictionary new];

#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
    [osData setValue:@"macOS" forKey:@"name"];
#elif TARGET_OS_IOS
    [osData setValue:@"iOS" forKey:@"name"];
#elif TARGET_OS_TV
    [osData setValue:@"tvOS" forKey:@"name"];
#elif TARGET_OS_WATCH
    [osData setValue:@"watchOS" forKey:@"name"];
#endif

    // For MacCatalyst the UIDevice returns the current version of MacCatalyst and not the
    // macOSVersion. Therefore we have to use NSProcessInfo.
#if SENTRY_HAS_UIDEVICE && !TARGET_OS_MACCATALYST
    [osData setValue:[UIDevice currentDevice].systemVersion forKey:@"version"];
#else
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
    NSString *systemVersion = [NSString stringWithFormat:@"%d.%d.%d", (int)version.majorVersion,
                                        (int)version.minorVersion, (int)version.patchVersion];
    [osData setValue:systemVersion forKey:@"version"];

#endif

    NSDictionary *systemInfo = [crashWrapper systemInfo];

    // SystemInfo should only be nil when BuzzSentryCrash has not been installed
    if (systemInfo != nil && systemInfo.count != 0) {
        [osData setValue:systemInfo[@"osVersion"] forKey:@"build"];
        [osData setValue:systemInfo[@"kernelVersion"] forKey:@"kernel_version"];
        [osData setValue:systemInfo[@"isJailbroken"] forKey:@"rooted"];
    }

    [scope setContextValue:osData forKey:@"os"];

    // SystemInfo should only be nil when BuzzSentryCrash has not been installed
    if (systemInfo == nil || systemInfo.count == 0) {
        return;
    }

    // DEVICE

    NSMutableDictionary *deviceData = [NSMutableDictionary new];

#if TARGET_OS_SIMULATOR
    [deviceData setValue:@(YES) forKey:@"simulator"];
#else
    [deviceData setValue:@(NO) forKey:@"simulator"];
#endif

    NSString *family = [[systemInfo[@"systemName"]
        componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] firstObject];

#if TARGET_OS_MACCATALYST
    // This would be iOS. Set it to macOS instead.
    family = @"macOS";
#endif

    [deviceData setValue:family forKey:@"family"];
    [deviceData setValue:systemInfo[@"cpuArchitecture"] forKey:@"arch"];
    [deviceData setValue:systemInfo[@"machine"] forKey:@"model"];
    [deviceData setValue:systemInfo[@"model"] forKey:@"model_id"];
    [deviceData setValue:systemInfo[@"freeMemorySize"] forKey:BuzzSentryDeviceContextFreeMemoryKey];
    [deviceData setValue:systemInfo[@"usableMemorySize"] forKey:@"usable_memory"];
    [deviceData setValue:systemInfo[@"memorySize"] forKey:@"memory_size"];
    [deviceData setValue:systemInfo[@"totalStorageSize"] forKey:@"storage_size"];
    [deviceData setValue:systemInfo[@"freeStorageSize"] forKey:@"free_storage"];
    [deviceData setValue:systemInfo[@"bootTime"] forKey:@"boot_time"];

    NSString *locale = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleIdentifier];
    [deviceData setValue:locale forKey:LOCALE_KEY];

#if SENTRY_HAS_UIDEVICE && !defined(TESTCI)
    // Acessessing UIScreen.mainScreen fails when using SentryTestObserver.
    // It's a bug with the iOS 15 and 16 simulator, it runs fine with iOS 14.
    [deviceData setValue:@(UIScreen.mainScreen.bounds.size.height) forKey:@"screen_height_pixels"];
    [deviceData setValue:@(UIScreen.mainScreen.bounds.size.width) forKey:@"screen_width_pixels"];
#endif

    [scope setContextValue:deviceData forKey:DEVICE_KEY];

    // APP
    NSMutableDictionary *appData = [NSMutableDictionary new];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];

    [appData setValue:infoDict[@"CFBundleIdentifier"] forKey:@"app_identifier"];
    [appData setValue:infoDict[@"CFBundleName"] forKey:@"app_name"];
    [appData setValue:infoDict[@"CFBundleVersion"] forKey:@"app_build"];
    [appData setValue:infoDict[@"CFBundleShortVersionString"] forKey:@"app_version"];

    [appData setValue:systemInfo[@"appStartTime"] forKey:@"app_start_time"];
    [appData setValue:systemInfo[@"deviceAppHash"] forKey:@"device_app_hash"];
    [appData setValue:systemInfo[@"appID"] forKey:@"app_id"];
    [appData setValue:systemInfo[@"buildType"] forKey:@"build_type"];

    [scope setContextValue:appData forKey:@"app"];
}

- (void)currentLocaleDidChange
{
    [BuzzSentrySDK.currentHub configureScope:^(BuzzSentryScope *_Nonnull scope) {
        NSMutableDictionary<NSString *, id> *device;
        if (scope.contextDictionary != nil && scope.contextDictionary[DEVICE_KEY] != nil) {
            device = [[NSMutableDictionary alloc]
                initWithDictionary:scope.contextDictionary[DEVICE_KEY]];
        } else {
            device = [NSMutableDictionary new];
        }

        NSString *locale = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleIdentifier];
        device[LOCALE_KEY] = locale;

        [scope setContextValue:device forKey:DEVICE_KEY];
    }];
}

@end