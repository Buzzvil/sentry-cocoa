#import "BuzzSentryOptions.h"
#import "SentryError.h"
#import "BuzzSentrySDK.h"
#import "BuzzSentrySDKInfo.h"
#import "SentryTests-Swift.h"
#import <XCTest/XCTest.h>

@interface BuzzSentryOptionsTest : XCTestCase

@end

@implementation BuzzSentryOptionsTest

- (void)testEmptyDsn
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{} didFailWithError:&error];

    [self assertDsnNil:options andError:error];
}

- (void)testInvalidDsnBoolean
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{ @"dsn" : @YES }
                                                didFailWithError:&error];

    [self assertDsnNil:options andError:error];
}

- (void)assertDsnNil:(BuzzSentryOptions *)options andError:(NSError *)error
{
    XCTAssertNil(options.parsedDsn);
    XCTAssertEqual(NO, options.debug);
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
}

- (void)testInvalidDsn
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{ @"dsn" : @"https://sentry.io" }
                                                didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testRelease
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"release" : @"abc" }];
    XCTAssertEqualObjects(options.releaseName, @"abc");
}

- (void)testSetEmptyRelease
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"release" : @"" }];
    XCTAssertEqualObjects(options.releaseName, @"");
}

- (void)testSetReleaseToNonString
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"release" : @2 }];
    XCTAssertEqualObjects(options.releaseName, [self buildDefaultReleaseName]);
}

- (void)testNoReleaseSetUsesDefault
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertEqualObjects(options.releaseName, [self buildDefaultReleaseName]);
}

- (NSString *)buildDefaultReleaseName
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat:@"%@@%@+%@", infoDict[@"CFBundleIdentifier"],
                     infoDict[@"CFBundleShortVersionString"], infoDict[@"CFBundleVersion"]];
}

- (void)testEnvironment
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.environment);

    options = [self getValidOptions:@{ @"environment" : @"xxx" }];
    XCTAssertEqualObjects(options.environment, @"xxx");
}

- (void)testDist
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.dist);

    options = [self getValidOptions:@{ @"dist" : @"hhh" }];
    XCTAssertEqualObjects(options.dist, @"hhh");
}

- (void)testValidDebug
{
    [self testDebugWith:@YES expected:YES];
    [self testDebugWith:@"YES" expected:YES];
    [self testDebugWith:@(YES) expected:YES];
}

- (void)testInvalidDebug
{
    [self testDebugWith:@"Invalid" expected:NO];
    [self testDebugWith:@NO expected:NO];
    [self testDebugWith:@(NO) expected:NO];
}

- (void)testDebugWith:(NSObject *)debugValue expected:(BOOL)expectedDebugValue
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{
        @"dsn" : @"https://username:password@sentry.io/1",
        @"debug" : debugValue
    }
                                                didFailWithError:&error];

    XCTAssertNil(error);
    XCTAssertEqual(expectedDebugValue, options.debug);
}

- (void)testValidDiagnosticLevel
{
    [self testDiagnosticlevelWith:@"none" expected:kSentryLevelNone];
    [self testDiagnosticlevelWith:@"debug" expected:kSentryLevelDebug];
    [self testDiagnosticlevelWith:@"info" expected:kSentryLevelInfo];
    [self testDiagnosticlevelWith:@"warning" expected:kSentryLevelWarning];
    [self testDiagnosticlevelWith:@"error" expected:kSentryLevelError];
    [self testDiagnosticlevelWith:@"fatal" expected:kSentryLevelFatal];
}

- (void)testInvalidDiagnosticLevel
{
    [self testDiagnosticlevelWith:@"fatala" expected:kSentryLevelDebug];
    [self testDiagnosticlevelWith:@(YES) expected:kSentryLevelDebug];
}

- (void)testDiagnosticlevelWith:(NSObject *)level expected:(SentryLevel)expected
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"diagnosticLevel" : level }];

    XCTAssertEqual(expected, options.diagnosticLevel);
}

- (void)testValidEnabled
{
    [self testEnabledWith:@YES expected:YES];
    [self testEnabledWith:@"YES" expected:YES];
    [self testEnabledWith:@(YES) expected:YES];
}

- (void)testInvalidEnabled
{
    [self testEnabledWith:@"Invalid" expected:NO];
    [self testEnabledWith:@NO expected:NO];
    [self testEnabledWith:@(NO) expected:NO];
}

- (void)testEnabledWith:(NSObject *)enabledValue expected:(BOOL)expectedValue
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"enabled" : enabledValue }];

    XCTAssertEqual(expectedValue, options.enabled);
}

- (void)testMaxBreadcrumbs
{
    NSNumber *maxBreadcrumbs = @20;

    BuzzSentryOptions *options = [self getValidOptions:@{ @"maxBreadcrumbs" : maxBreadcrumbs }];

    XCTAssertEqual([maxBreadcrumbs unsignedIntValue], options.maxBreadcrumbs);
}

- (void)testEnableNetworkBreadcrumbs
{
    [self testBooleanField:@"enableNetworkBreadcrumbs"];
}

- (void)testEnableAutoBreadcrumbTracking
{
    [self testBooleanField:@"enableAutoBreadcrumbTracking"];
}

- (void)testEnableCoreDataTracking
{
    [self testBooleanField:@"enableCoreDataTracking" defaultValue:NO];
}

- (void)testSendClientReports
{
    [self testBooleanField:@"sendClientReports" defaultValue:YES];
}

- (void)testDefaultMaxBreadcrumbs
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual([@100 unsignedIntValue], options.maxBreadcrumbs);
}

- (void)testMaxBreadcrumbsGarbage
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"maxBreadcrumbs" : self }];

    XCTAssertEqual(100, options.maxBreadcrumbs);
}

- (void)testMaxCacheItems
{
    NSNumber *maxCacheItems = @20;

    BuzzSentryOptions *options = [self getValidOptions:@{ @"maxCacheItems" : maxCacheItems }];

    XCTAssertEqual([maxCacheItems unsignedIntValue], options.maxCacheItems);
}

- (void)testMaxCacheItemsGarbage
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"maxCacheItems" : self }];

    XCTAssertEqual(30, options.maxCacheItems);
}

- (void)testDefaultMaxCacheItems
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual([@30 unsignedIntValue], options.maxCacheItems);
}

- (void)testBeforeSend
{
    SentryBeforeSendEventCallback callback = ^(BuzzSentryEvent *event) { return event; };
    BuzzSentryOptions *options = [self getValidOptions:@{ @"beforeSend" : callback }];

    XCTAssertEqual(callback, options.beforeSend);
}

- (void)testDefaultBeforeSend
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.beforeSend);
}

- (void)testGarbageBeforeSend_ReturnsNil
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"beforeSend" : @"fault" }];

    XCTAssertNil(options.beforeSend);
}

- (void)testNSNullBeforeSend_ReturnsNil
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"beforeSend" : [NSNull null] }];

    XCTAssertFalse([options.beforeSend isEqual:[NSNull null]]);
}

- (void)testBeforeBreadcrumb
{
    SentryBeforeBreadcrumbCallback callback
        = ^(BuzzSentryBreadcrumb *breadcrumb) { return breadcrumb; };
    BuzzSentryOptions *options = [self getValidOptions:@{ @"beforeBreadcrumb" : callback }];

    XCTAssertEqual(callback, options.beforeBreadcrumb);
}

- (void)testDefaultBeforeBreadcrumb
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.beforeBreadcrumb);
}

- (void)testTracePropagationTargets
{
    BuzzSentryOptions *options =
        [self getValidOptions:@{ @"tracePropagationTargets" : @[ @"localhost" ] }];

    XCTAssertEqual(options.tracePropagationTargets.count, 1);
    XCTAssertEqual(options.tracePropagationTargets[0], @"localhost");
}

- (void)testTracePropagationTargetsInvalidInstanceDoesntCrash
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"tracePropagationTargets" : @[ @YES ] }];

    XCTAssertEqual(options.tracePropagationTargets.count, 1);
    XCTAssertEqual(options.tracePropagationTargets[0], @YES);
}

- (void)testGarbageBeforeBreadcrumb_ReturnsNil
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"beforeBreadcrumb" : @"fault" }];

    XCTAssertEqual(nil, options.beforeBreadcrumb);
}

- (void)testOnCrashedLastRun
{
    __block BOOL onCrashedLastRunCalled = NO;
    SentryOnCrashedLastRunCallback callback = ^(BuzzSentryEvent *event) {
        onCrashedLastRunCalled = YES;
        XCTAssertNotNil(event);
    };
    BuzzSentryOptions *options = [self getValidOptions:@{ @"onCrashedLastRun" : callback }];

    options.onCrashedLastRun([[BuzzSentryEvent alloc] init]);

    XCTAssertEqual(callback, options.onCrashedLastRun);
    XCTAssertTrue(onCrashedLastRunCalled);
}

- (void)testDefaultOnCrashedLastRun
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.onCrashedLastRun);
}

- (void)testGarbageOnCrashedLastRun_ReturnsNil
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"onCrashedLastRun" : @"fault" }];

    XCTAssertNil(options.onCrashedLastRun);
}

- (void)testIntegrations
{
    NSArray<NSString *> *integrations = @[ @"integration1", @"integration2" ];
    BuzzSentryOptions *options = [self getValidOptions:@{ @"integrations" : integrations }];

    [self assertArrayEquals:integrations actual:options.integrations];
}

- (void)testDefaultIntegrations
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertTrue([[BuzzSentryOptions defaultIntegrations] isEqualToArray:options.integrations],
        @"Default integrations are not set correctly");
}

- (void)testSampleRateWithDict
{
    NSNumber *sampleRate = @0.1;
    BuzzSentryOptions *options = [self getValidOptions:@{ @"sampleRate" : sampleRate }];
    XCTAssertEqual(sampleRate, options.sampleRate);
}

- (void)testSampleRate_SetToNil
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.sampleRate = nil;
    XCTAssertNil(options.sampleRate);
}

- (void)testSampleRateLowerBound
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.sampleRate = @0.5;

    NSNumber *sampleRateLowerBound = @0;
    options.sampleRate = sampleRateLowerBound;
    XCTAssertEqual(sampleRateLowerBound, options.sampleRate);

    options.sampleRate = @0.5;

    NSNumber *sampleRateTooLow = @-0.01;
    options.sampleRate = sampleRateTooLow;
    XCTAssertEqual(@1, options.sampleRate);
}

- (void)testSampleRateUpperBound
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.sampleRate = @0.5;

    NSNumber *upperBound = @1;
    options.sampleRate = upperBound;
    XCTAssertEqual(upperBound, options.sampleRate);

    options.sampleRate = @0.5;

    NSNumber *tooHigh = @1.01;
    options.sampleRate = tooHigh;
    XCTAssertEqual(@1, options.sampleRate);
}

- (void)testSampleRateNotSet
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual(@1, options.sampleRate);
}

- (void)testEnableAutoSessionTracking
{
    [self testBooleanField:@"enableAutoSessionTracking"];
}

- (void)testEnableOutOfMemoryTracking
{
    [self testBooleanField:@"enableOutOfMemoryTracking"];
}

- (void)testSessionTrackingIntervalMillis
{
    NSNumber *sessionTracking = @2000;
    BuzzSentryOptions *options =
        [self getValidOptions:@{ @"sessionTrackingIntervalMillis" : sessionTracking }];

    XCTAssertEqual([sessionTracking unsignedIntValue], options.sessionTrackingIntervalMillis);
}

- (void)testDefaultSessionTrackingIntervalMillis
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual([@30000 unsignedIntValue], options.sessionTrackingIntervalMillis);
}

- (void)testAttachStackTrace
{
    [self testBooleanField:@"attachStacktrace"];
}

- (void)testStitchAsyncCodeDisabledPerDefault
{
    [self testBooleanField:@"stitchAsyncCode" defaultValue:NO];
}

- (void)testEnableIOTracking
{
    [self testBooleanField:@"enableFileIOTracking" defaultValue:NO];
}

- (void)testEmptyConstructorSetsDefaultValues
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    XCTAssertNil(options.parsedDsn);
    [self assertDefaultValues:options];
}

- (void)testNSNull_SetsDefaultValue
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{
        @"dsn" : [NSNull null],
        @"enabled" : [NSNull null],
        @"debug" : [NSNull null],
        @"diagnosticLevel" : [NSNull null],
        @"release" : [NSNull null],
        @"environment" : [NSNull null],
        @"dist" : [NSNull null],
        @"maxBreadcrumbs" : [NSNull null],
        @"enableNetworkBreadcrumbs" : [NSNull null],
        @"maxCacheItems" : [NSNull null],
        @"beforeSend" : [NSNull null],
        @"beforeBreadcrumb" : [NSNull null],
        @"onCrashedLastRun" : [NSNull null],
        @"integrations" : [NSNull null],
        @"sampleRate" : [NSNull null],
        @"enableAutoSessionTracking" : [NSNull null],
        @"enableOutOfMemoryTracking" : [NSNull null],
        @"sessionTrackingIntervalMillis" : [NSNull null],
        @"attachStacktrace" : [NSNull null],
        @"stitchAsyncCode" : [NSNull null],
        @"maxAttachmentSize" : [NSNull null],
        @"sendDefaultPii" : [NSNull null],
        @"enableAutoPerformanceTracking" : [NSNull null],
#if SENTRY_HAS_UIKIT
        @"enableUIViewControllerTracking" : [NSNull null],
        @"attachScreenshot" : [NSNull null],
#endif
        @"enableAppHangTracking" : [NSNull null],
        @"appHangTimeoutInterval" : [NSNull null],
        @"enableNetworkTracking" : [NSNull null],
        @"enableAutoBreadcrumbTracking" : [NSNull null],
        @"tracesSampleRate" : [NSNull null],
        @"tracesSampler" : [NSNull null],
        @"inAppIncludes" : [NSNull null],
        @"inAppExcludes" : [NSNull null],
        @"urlSessionDelegate" : [NSNull null],
        @"enableSwizzling" : [NSNull null],
        @"enableIOTracking" : [NSNull null],
        @"sdk" : [NSNull null]
    }
                                                didFailWithError:nil];

    XCTAssertNotNil(options.parsedDsn);
    [self assertDefaultValues:options];
}

- (void)assertDefaultValues:(BuzzSentryOptions *)options
{
    XCTAssertEqual(YES, options.enabled);
    XCTAssertEqual(NO, options.debug);
    XCTAssertEqual(kSentryLevelDebug, options.diagnosticLevel);
    XCTAssertNil(options.environment);
    XCTAssertNil(options.dist);
    XCTAssertEqual(defaultMaxBreadcrumbs, options.maxBreadcrumbs);
    XCTAssertTrue(options.enableNetworkBreadcrumbs);
    XCTAssertEqual(30, options.maxCacheItems);
    XCTAssertNil(options.beforeSend);
    XCTAssertNil(options.beforeBreadcrumb);
    XCTAssertNil(options.onCrashedLastRun);
    XCTAssertTrue([[BuzzSentryOptions defaultIntegrations] isEqualToArray:options.integrations],
        @"Default integrations are not set correctly");
    XCTAssertEqual(@1, options.sampleRate);
    XCTAssertEqual(YES, options.enableAutoSessionTracking);
    XCTAssertEqual(YES, options.enableOutOfMemoryTracking);
    XCTAssertEqual([@30000 unsignedIntValue], options.sessionTrackingIntervalMillis);
    XCTAssertEqual(YES, options.attachStacktrace);
    XCTAssertEqual(NO, options.stitchAsyncCode);
    XCTAssertEqual(20 * 1024 * 1024, options.maxAttachmentSize);
    XCTAssertEqual(NO, options.sendDefaultPii);
    XCTAssertTrue(options.enableAutoPerformanceTracking);
#if SENTRY_HAS_UIKIT
    XCTAssertTrue(options.enableUIViewControllerTracking);
    XCTAssertFalse(options.attachScreenshot);
    XCTAssertEqual(3.0, options.idleTimeout);
#endif
    XCTAssertFalse(options.enableAppHangTracking);
    XCTAssertEqual(options.appHangTimeoutInterval, 2);
    XCTAssertEqual(YES, options.enableNetworkTracking);
    XCTAssertNil(options.tracesSampleRate);
    XCTAssertNil(options.tracesSampler);
    XCTAssertEqualObjects([self getDefaultInAppIncludes], options.inAppIncludes);
    XCTAssertEqual(@[], options.inAppExcludes);
    XCTAssertNil(options.urlSessionDelegate);
    XCTAssertEqual(YES, options.enableSwizzling);
    XCTAssertEqual(NO, options.enableFileIOTracking);
    XCTAssertEqual(YES, options.enableAutoBreadcrumbTracking);
    NSRegularExpression *regex = options.tracePropagationTargets[0];
    XCTAssertTrue([regex.pattern isEqualToString:@".*"]);
#if SENTRY_TARGET_PROFILING_SUPPORTED
#    pragma clang diagnostic push
#    pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(NO, options.enableProfiling);
#    pragma clang diagnostic pop
    XCTAssertNil(options.profilesSampleRate);
    XCTAssertNil(options.profilesSampler);
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(BuzzSentryMeta.sdkName, options.sdkInfo.name);
    XCTAssertEqual(BuzzSentryMeta.versionString, options.sdkInfo.version);
#pragma clang diagnostic pop
}

- (void)testSetValidDsn
{
    NSString *dsnAsString = @"https://username:password@sentry.io/1";
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.dsn = dsnAsString;
    options.enabled = NO;

    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:dsnAsString didFailWithError:nil];

    XCTAssertEqual(dsnAsString, options.dsn);
    XCTAssertTrue([dsn.url.absoluteString isEqualToString:options.parsedDsn.url.absoluteString]);
    XCTAssertEqual(NO, options.enabled);
}

- (void)testSetNilDsn
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];

    [options setDsn:nil];
    XCTAssertNil(options.dsn);
    XCTAssertNil(options.parsedDsn);
    XCTAssertEqual(YES, options.enabled);
}

- (void)testSetInvalidValidDsn
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];

    [options setDsn:@"https://username:passwordsentry.io/1"];
    XCTAssertNil(options.dsn);
    XCTAssertNil(options.parsedDsn);
    XCTAssertEqual(YES, options.enabled);
}

- (void)testSdkInfo
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    XCTAssertEqual(BuzzSentryMeta.sdkName, options.sdkInfo.name);
    XCTAssertEqual(BuzzSentryMeta.versionString, options.sdkInfo.version);
#pragma clang diagnostic pop
}

- (void)testSetCustomSdkInfo
{
    NSDictionary *dict = @{ @"name" : @"custom.sdk", @"version" : @"1.2.3-alpha.0" };

    NSError *error = nil;
    BuzzSentryOptions *options =
        [[BuzzSentryOptions alloc] initWithDict:@{ @"sdk" : dict, @"dsn" : @"https://a:b@c.d/1" }
                           didFailWithError:&error];

    XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(dict[@"name"], options.sdkInfo.name);
    XCTAssertEqual(dict[@"version"], options.sdkInfo.version);
#pragma clang diagnostic pop

    NSDictionary *info = [[NSBundle bundleForClass:[BuzzSentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    BuzzSentryMeta.versionString = version;
}

- (void)testSetCustomSdkName
{
    NSDictionary *dict = @{ @"name" : @"custom.sdk" };
    NSString *originalVersion = BuzzSentryMeta.versionString;

    NSError *error = nil;
    BuzzSentryOptions *options =
        [[BuzzSentryOptions alloc] initWithDict:@{ @"sdk" : dict, @"dsn" : @"https://a:b@c.d/1" }
                           didFailWithError:&error];

    XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(dict[@"name"], options.sdkInfo.name);
    // version stays unchanged
    XCTAssertEqual(BuzzSentryMeta.versionString, options.sdkInfo.version);
    XCTAssertEqual(BuzzSentryMeta.versionString, originalVersion);
#pragma clang diagnostic pop
}

- (void)testSetCustomSdkVersion
{
    NSDictionary *dict = @{ @"version" : @"1.2.3-alpha.0" };
    NSString *originalName = BuzzSentryMeta.sdkName;

    NSError *error = nil;
    BuzzSentryOptions *options =
        [[BuzzSentryOptions alloc] initWithDict:@{ @"sdk" : dict, @"dsn" : @"https://a:b@c.d/1" }
                           didFailWithError:&error];

    XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(dict[@"version"], options.sdkInfo.version);
    // name stays unchanged
    XCTAssertEqual(BuzzSentryMeta.sdkName, options.sdkInfo.name);
    XCTAssertEqual(BuzzSentryMeta.sdkName, originalName);
#pragma clang diagnostic pop

    NSDictionary *info = [[NSBundle bundleForClass:[BuzzSentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    BuzzSentryMeta.versionString = version;
}

- (void)testMaxAttachmentSize
{
    NSNumber *maxAttachmentSize = @21;
    BuzzSentryOptions *options = [self getValidOptions:@{ @"maxAttachmentSize" : maxAttachmentSize }];

    XCTAssertEqual([maxAttachmentSize unsignedIntValue], options.maxAttachmentSize);
}

- (void)testDefaultMaxAttachmentSize
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual(20 * 1024 * 1024, options.maxAttachmentSize);
}

- (void)testSendDefaultPii
{
    [self testBooleanField:@"sendDefaultPii" defaultValue:NO];
}

- (void)testEnableAutoPerformanceTracking
{
    [self testBooleanField:@"enableAutoPerformanceTracking"];
}

#if SENTRY_HAS_UIKIT
- (void)testEnableUIViewControllerTracking
{
    [self testBooleanField:@"enableUIViewControllerTracking"];
}

- (void)testAttachScreenshot
{
    [self testBooleanField:@"attachScreenshot" defaultValue:NO];
}

- (void)testEnableUserInteractionTracking
{
    [self testBooleanField:@"enableUserInteractionTracing" defaultValue:NO];
}

- (void)testIdleTimeout
{
    NSNumber *idleTimeout = @2.1;
    BuzzSentryOptions *options = [self getValidOptions:@{ @"idleTimeout" : idleTimeout }];

    XCTAssertEqual([idleTimeout doubleValue], options.idleTimeout);
}

#endif

- (void)testEnableAppHangTracking
{
    [self testBooleanField:@"enableAppHangTracking" defaultValue:NO];
}

- (void)testDefaultAppHangsTimeout
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertEqual(2, options.appHangTimeoutInterval);
}

- (void)testEnableNetworkTracking
{
    [self testBooleanField:@"enableNetworkTracking"];
}

- (void)testEnableSwizzling
{
    [self testBooleanField:@"enableSwizzling"];
}

- (void)testTracesSampleRate
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"tracesSampleRate" : @0.1 }];

    XCTAssertEqual(options.tracesSampleRate.doubleValue, 0.1);
}

- (void)testDefaultTracesSampleRate
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.tracesSampleRate);
}

- (void)testTracesSampleRate_SetToNil
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.tracesSampleRate = nil;
    XCTAssertNil(options.tracesSampleRate);
}

- (void)testTracesSampleRateLowerBound
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.tracesSampleRate = @0.5;

    NSNumber *lowerBound = @0;
    options.tracesSampleRate = lowerBound;
    XCTAssertEqual(lowerBound, options.tracesSampleRate);

    options.tracesSampleRate = @0.5;

    NSNumber *tooLow = @-0.01;
    options.tracesSampleRate = tooLow;
    XCTAssertNil(options.tracesSampleRate);
}

- (void)testTracesSampleRateUpperBound
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.tracesSampleRate = @0.5;

    NSNumber *lowerBound = @1;
    options.tracesSampleRate = lowerBound;
    XCTAssertEqual(lowerBound, options.tracesSampleRate);

    options.tracesSampleRate = @0.5;

    NSNumber *tooLow = @1.01;
    options.tracesSampleRate = tooLow;
    XCTAssertNil(options.tracesSampleRate);
}

- (double)tracesSamplerCallback:(NSDictionary *)context
{
    return 0.1;
}

- (void)testTracesSampler
{
    BuzzSentryTracesSamplerCallback sampler = ^(BuzzSentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @1.0;
    };

    BuzzSentryOptions *options = [self getValidOptions:@{ @"tracesSampler" : sampler }];

    BuzzSentrySamplingContext *context = [[BuzzSentrySamplingContext alloc] init];
    XCTAssertEqual(options.tracesSampler(context), @1.0);
}

- (void)testDefaultTracesSampler
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.tracesSampler);
}

- (void)testGarbageTracesSampler_ReturnsNil
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"tracesSampler" : @"fault" }];
    XCTAssertNil(options.tracesSampler);
}

- (void)testIsTracingEnabled_NothingSet_IsDisabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    XCTAssertFalse(options.isTracingEnabled);
}

- (void)testIsTracingEnabled_TracesSampleRateSetToZero_IsDisabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.tracesSampleRate = @0.00;
    XCTAssertFalse(options.isTracingEnabled);
}

- (void)testIsTracingEnabled_TracesSampleRateSet_IsEnabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.tracesSampleRate = @0.01;
    XCTAssertTrue(options.isTracingEnabled);
}

- (void)testIsTracingEnabled_TracesSamplerSet_IsEnabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.tracesSampler = ^(BuzzSentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @0.0;
    };
    XCTAssertTrue(options.isTracingEnabled);
}

#if SENTRY_TARGET_PROFILING_SUPPORTED
- (void)testEnableProfiling
{
    [self testBooleanField:@"enableProfiling" defaultValue:NO];
}

- (void)testProfilesSampleRate
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"profilesSampleRate" : @0.1 }];

    XCTAssertEqual(options.profilesSampleRate.doubleValue, 0.1);
}

- (void)testDefaultProfilesSampleRate
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.profilesSampleRate);
}

- (void)testProfilesSampleRate_SetToNil
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.profilesSampleRate = nil;
    XCTAssertNil(options.profilesSampleRate);
}

- (void)testProfilesSampleRateLowerBound
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.profilesSampleRate = @0.5;

    NSNumber *lowerBound = @0;
    options.profilesSampleRate = lowerBound;
    XCTAssertEqual(lowerBound, options.profilesSampleRate);

    options.profilesSampleRate = @0.5;

    NSNumber *tooLow = @-0.01;
    options.profilesSampleRate = tooLow;
    XCTAssertNil(options.profilesSampleRate);
}

- (void)testProfilesSampleRateUpperBound
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.profilesSampleRate = @0.5;

    NSNumber *lowerBound = @1;
    options.profilesSampleRate = lowerBound;
    XCTAssertEqual(lowerBound, options.profilesSampleRate);

    options.profilesSampleRate = @0.5;

    NSNumber *tooLow = @1.01;
    options.profilesSampleRate = tooLow;
    XCTAssertNil(options.profilesSampleRate);
}

- (void)testIsProfilingEnabled_NothingSet_IsDisabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    XCTAssertFalse(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_ProfilesSampleRateSetToZero_IsDisabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.profilesSampleRate = @0.00;
    XCTAssertFalse(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_ProfilesSampleRateSet_IsEnabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.profilesSampleRate = @0.01;
    XCTAssertTrue(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_ProfilesSamplerSet_IsEnabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    options.profilesSampler = ^(BuzzSentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @0.0;
    };
    XCTAssertTrue(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_EnableProfilingSet_IsEnabled
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
#    pragma clang diagnostic push
#    pragma clang diagnostic ignored "-Wdeprecated-declarations"
    options.enableProfiling = YES;
#    pragma clang diagnostic pop
    XCTAssertTrue(options.isProfilingEnabled);
}

- (double)profilesSamplerCallback:(NSDictionary *)context
{
    return 0.1;
}

- (void)testProfilesSampler
{
    BuzzSentryTracesSamplerCallback sampler = ^(BuzzSentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @1.0;
    };

    BuzzSentryOptions *options = [self getValidOptions:@{ @"profilesSampler" : sampler }];

    BuzzSentrySamplingContext *context = [[BuzzSentrySamplingContext alloc] init];
    XCTAssertEqual(options.profilesSampler(context), @1.0);
}

- (void)testDefaultProfilesSampler
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.profilesSampler);
}

- (void)testGarbageProfilesSampler_ReturnsNil
{
    BuzzSentryOptions *options = [self getValidOptions:@{ @"profilesSampler" : @"fault" }];
    XCTAssertNil(options.profilesSampler);
}
#endif

- (void)testInAppIncludes
{
    NSArray<NSString *> *expected = @[ @"iOS-Swift", @"BusinessLogic" ];
    NSArray *inAppIncludes = @[ @"iOS-Swift", @"BusinessLogic", @1 ];
    BuzzSentryOptions *options = [self getValidOptions:@{ @"inAppIncludes" : inAppIncludes }];

    NSString *bundleExecutable = [self getBundleExecutable];
    if (nil != bundleExecutable) {
        expected = [expected arrayByAddingObject:bundleExecutable];
    }

    [self assertArrayEquals:expected actual:options.inAppIncludes];
}

- (void)testAddInAppIncludes
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    [options addInAppInclude:@"App"];

    NSArray<NSString *> *expected = @[ @"App" ];
    NSString *bundleExecutable = [self getBundleExecutable];
    if (nil != bundleExecutable) {
        expected = [expected arrayByAddingObject:bundleExecutable];
    }

    [self assertArrayEquals:expected actual:options.inAppIncludes];
}

- (NSString *)getBundleExecutable
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    return infoDict[@"CFBundleExecutable"];
}

- (void)testDefaultInAppIncludes
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertEqualObjects([self getDefaultInAppIncludes], options.inAppIncludes);
}

- (void)testInAppExcludes
{
    NSArray<NSString *> *expected = @[ @"Sentry" ];
    NSArray *inAppExcludes = @[ @"Sentry", @2 ];

    BuzzSentryOptions *options = [self getValidOptions:@{ @"inAppExcludes" : inAppExcludes }];

    XCTAssertEqualObjects(expected, options.inAppExcludes);
}

- (void)testAddInAppExcludes
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    [options addInAppExclude:@"App"];
    XCTAssertEqualObjects(@[ @"App" ], options.inAppExcludes);
}

- (void)testDefaultInAppExcludes
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    XCTAssertEqualObjects(@[], options.inAppExcludes);
}

- (BuzzSentryOptions *)getValidOptions:(NSDictionary<NSString *, id> *)dict
{
    NSError *error = nil;

    NSMutableDictionary<NSString *, id> *options = [[NSMutableDictionary alloc] init];
    options[@"dsn"] = @"https://username:password@sentry.io/1";

    [options addEntriesFromDictionary:dict];

    BuzzSentryOptions *BuzzSentryOptions = [[BuzzSentryOptions alloc] initWithDict:options
                                                      didFailWithError:&error];
    XCTAssertNil(error);
    return BuzzSentryOptions;
}

- (void)testUrlSessionDelegate
{
    id<NSURLSessionDelegate> urlSessionDelegate = [[UrlSessionDelegateSpy alloc] init];

    BuzzSentryOptions *options = [self getValidOptions:@{ @"urlSessionDelegate" : urlSessionDelegate }];

    XCTAssertNotNil(options.urlSessionDelegate);
}

- (void)testSdkInfoChanges
{
    BuzzSentryOptions *options = [self getValidOptions:@{}];
    BuzzSentryMeta.sdkName = @"new name";
    BuzzSentryMeta.versionString = @"0.0.6";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(options.sdkInfo.name, BuzzSentryMeta.sdkName);
    XCTAssertEqual(options.sdkInfo.version, BuzzSentryMeta.versionString);
#pragma clang diagnostic pop
}

- (void)assertArrayEquals:(NSArray<NSString *> *)expected actual:(NSArray<NSString *> *)actual
{
    XCTAssertEqualObjects([expected sortedArrayUsingSelector:@selector(compare:)],
        [actual sortedArrayUsingSelector:@selector(compare:)]);
}

- (void)testBooleanField:(NSString *)property
{
    [self testBooleanField:property defaultValue:YES];
}

- (void)testBooleanField:(NSString *)property defaultValue:(BOOL)defaultValue
{
    // Opposite of default
    BuzzSentryOptions *options = [self getValidOptions:@{ property : @(!defaultValue) }];
    XCTAssertEqual(!defaultValue, [self getProperty:property of:options]);

    // Default
    options = [self getValidOptions:@{}];
    XCTAssertEqual(defaultValue, [self getProperty:property of:options]);

    // Garbage
    options = [self getValidOptions:@{ property : @"" }];
    XCTAssertEqual(NO, [self getProperty:property of:options]);
}

- (BOOL)getProperty:(NSString *)property of:(BuzzSentryOptions *)options
{
    SEL selector = NSSelectorFromString(property);
    NSAssert(
        [options respondsToSelector:selector], @"Options doesn't have a property '%@'", property);

    NSInvocation *invocation = [NSInvocation
        invocationWithMethodSignature:[[options class]
                                          instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:options];
    [invocation invoke];
    BOOL result;
    [invocation getReturnValue:&result];

    return result;
}

- (NSArray<NSString *> *)getDefaultInAppIncludes
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleExecutable = infoDict[@"CFBundleExecutable"];
    NSArray<NSString *> *result;
    if (nil == bundleExecutable) {
        result = @[];
    } else {
        result = @[ bundleExecutable ];
    }
    return result;
}

@end
