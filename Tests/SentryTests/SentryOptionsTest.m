#import "SentryOptions.h"
#import "SentryError.h"
#import "SentrySDK.h"
#import "SentrySdkInfo.h"
#import "SentryTests-Swift.h"
#import <XCTest/XCTest.h>

@interface SentryOptionsTest : XCTestCase

@end

@implementation SentryOptionsTest

- (void)testEmptyDsn
{
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithDict:@{} didFailWithError:&error];

    [self assertDsnNil:options andError:error];
}

- (void)testInvalidDsnBoolean
{
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithDict:@{ @"dsn" : @YES }
                                                didFailWithError:&error];

    [self assertDsnNil:options andError:error];
}

- (void)assertDsnNil:(SentryOptions *)options andError:(NSError *)error
{
    XCTAssertNil(options.parsedDsn);
    XCTAssertEqual(NO, options.debug);
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
}

- (void)testInvalidDsn
{
    NSError *error = nil;
    SentryOptions *options = [[SentryOptions alloc] initWithDict:@{ @"dsn" : @"https://sentry.io" }
                                                didFailWithError:&error];
    XCTAssertEqual(kSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testRelease
{
    SentryOptions *options = [self getValidOptions:@{ @"release" : @"abc" }];
    XCTAssertEqualObjects(options.releaseName, @"abc");
}

- (void)testSetEmptyRelease
{
    SentryOptions *options = [self getValidOptions:@{ @"release" : @"" }];
    XCTAssertEqualObjects(options.releaseName, @"");
}

- (void)testSetReleaseToNonString
{
    SentryOptions *options = [self getValidOptions:@{ @"release" : @2 }];
    XCTAssertEqualObjects(options.releaseName, [self buildDefaultReleaseName]);
}

- (void)testNoReleaseSetUsesDefault
{
    SentryOptions *options = [self getValidOptions:@{}];
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
    SentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.environment);

    options = [self getValidOptions:@{ @"environment" : @"xxx" }];
    XCTAssertEqualObjects(options.environment, @"xxx");
}

- (void)testDist
{
    SentryOptions *options = [self getValidOptions:@{}];
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
    SentryOptions *options = [[SentryOptions alloc] initWithDict:@{
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
    SentryOptions *options = [self getValidOptions:@{ @"diagnosticLevel" : level }];

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
    SentryOptions *options = [self getValidOptions:@{ @"enabled" : enabledValue }];

    XCTAssertEqual(expectedValue, options.enabled);
}

- (void)testMaxBreadcrumbs
{
    NSNumber *maxBreadcrumbs = @20;

    SentryOptions *options = [self getValidOptions:@{ @"maxBreadcrumbs" : maxBreadcrumbs }];

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
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual([@100 unsignedIntValue], options.maxBreadcrumbs);
}

- (void)testMaxBreadcrumbsGarbage
{
    SentryOptions *options = [self getValidOptions:@{ @"maxBreadcrumbs" : self }];

    XCTAssertEqual(100, options.maxBreadcrumbs);
}

- (void)testMaxCacheItems
{
    NSNumber *maxCacheItems = @20;

    SentryOptions *options = [self getValidOptions:@{ @"maxCacheItems" : maxCacheItems }];

    XCTAssertEqual([maxCacheItems unsignedIntValue], options.maxCacheItems);
}

- (void)testMaxCacheItemsGarbage
{
    SentryOptions *options = [self getValidOptions:@{ @"maxCacheItems" : self }];

    XCTAssertEqual(30, options.maxCacheItems);
}

- (void)testDefaultMaxCacheItems
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertEqual([@30 unsignedIntValue], options.maxCacheItems);
}

- (void)testBeforeSend
{
    SentryBeforeSendEventCallback callback = ^(SentryEvent *event) { return event; };
    SentryOptions *options = [self getValidOptions:@{ @"beforeSend" : callback }];

    XCTAssertEqual(callback, options.beforeSend);
}

- (void)testDefaultBeforeSend
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.beforeSend);
}

- (void)testGarbageBeforeSend_ReturnsNil
{
    SentryOptions *options = [self getValidOptions:@{ @"beforeSend" : @"fault" }];

    XCTAssertNil(options.beforeSend);
}

- (void)testNSNullBeforeSend_ReturnsNil
{
    SentryOptions *options = [self getValidOptions:@{ @"beforeSend" : [NSNull null] }];

    XCTAssertFalse([options.beforeSend isEqual:[NSNull null]]);
}

- (void)testBeforeBreadcrumb
{
    SentryBeforeBreadcrumbCallback callback
        = ^(SentryBreadcrumb *breadcrumb) { return breadcrumb; };
    SentryOptions *options = [self getValidOptions:@{ @"beforeBreadcrumb" : callback }];

    XCTAssertEqual(callback, options.beforeBreadcrumb);
}

- (void)testDefaultBeforeBreadcrumb
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.beforeBreadcrumb);
}

- (void)testTracePropagationTargets
{
    SentryOptions *options =
        [self getValidOptions:@{ @"tracePropagationTargets" : @[ @"localhost" ] }];

    XCTAssertEqual(options.tracePropagationTargets.count, 1);
    XCTAssertEqual(options.tracePropagationTargets[0], @"localhost");
}

- (void)testTracePropagationTargetsInvalidInstanceDoesntCrash
{
    SentryOptions *options = [self getValidOptions:@{ @"tracePropagationTargets" : @[ @YES ] }];

    XCTAssertEqual(options.tracePropagationTargets.count, 1);
    XCTAssertEqual(options.tracePropagationTargets[0], @YES);
}

- (void)testFailedRequestTargets
{
    SentryOptions *options =
        [self getValidOptions:@{ @"failedRequestTargets" : @[ @"localhost" ] }];

    XCTAssertEqual(options.failedRequestTargets.count, 1);
    XCTAssertEqual(options.failedRequestTargets[0], @"localhost");
}

- (void)testFailedRequestTargetsInvalidInstanceDoesntCrash
{
    SentryOptions *options = [self getValidOptions:@{ @"failedRequestTargets" : @[ @YES ] }];

    XCTAssertEqual(options.failedRequestTargets.count, 1);
    XCTAssertEqual(options.failedRequestTargets[0], @YES);
}

- (void)testEnableCaptureFailedRequests
{
    [self testBooleanField:@"enableCaptureFailedRequests" defaultValue:NO];
}

- (void)testFailedRequestStatusCodes
{
    SentryHttpStatusCodeRange *httpStatusCodeRange =
        [[SentryHttpStatusCodeRange alloc] initWithMin:400 max:599];
    SentryOptions *options =
        [self getValidOptions:@{ @"failedRequestStatusCodes" : @[ httpStatusCodeRange ] }];

    XCTAssertEqual(options.failedRequestStatusCodes.count, 1);
    XCTAssertEqual(options.failedRequestStatusCodes[0].min, 400);
    XCTAssertEqual(options.failedRequestStatusCodes[0].max, 599);
}

- (void)testGarbageBeforeBreadcrumb_ReturnsNil
{
    SentryOptions *options = [self getValidOptions:@{ @"beforeBreadcrumb" : @"fault" }];

    XCTAssertEqual(nil, options.beforeBreadcrumb);
}

- (void)testOnCrashedLastRun
{
    __block BOOL onCrashedLastRunCalled = NO;
    SentryOnCrashedLastRunCallback callback = ^(SentryEvent *event) {
        onCrashedLastRunCalled = YES;
        XCTAssertNotNil(event);
    };
    SentryOptions *options = [self getValidOptions:@{ @"onCrashedLastRun" : callback }];

    options.onCrashedLastRun([[SentryEvent alloc] init]);

    XCTAssertEqual(callback, options.onCrashedLastRun);
    XCTAssertTrue(onCrashedLastRunCalled);
}

- (void)testDefaultOnCrashedLastRun
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.onCrashedLastRun);
}

- (void)testGarbageOnCrashedLastRun_ReturnsNil
{
    SentryOptions *options = [self getValidOptions:@{ @"onCrashedLastRun" : @"fault" }];

    XCTAssertNil(options.onCrashedLastRun);
}

- (void)testIntegrations
{
    NSArray<NSString *> *integrations = @[ @"integration1", @"integration2" ];
    SentryOptions *options = [self getValidOptions:@{ @"integrations" : integrations }];

    [self assertArrayEquals:integrations actual:options.integrations];
}

- (void)testDefaultIntegrations
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertTrue([[SentryOptions defaultIntegrations] isEqualToArray:options.integrations],
        @"Default integrations are not set correctly");
}

- (void)testSampleRateWithDict
{
    NSNumber *sampleRate = @0.1;
    SentryOptions *options = [self getValidOptions:@{ @"sampleRate" : sampleRate }];
    XCTAssertEqual(sampleRate, options.sampleRate);
}

- (void)testSampleRate_SetToNil
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.sampleRate = nil;
    XCTAssertNil(options.sampleRate);
}

- (void)testSampleRateLowerBound
{
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryOptions *options = [self getValidOptions:@{}];

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
    SentryOptions *options =
        [self getValidOptions:@{ @"sessionTrackingIntervalMillis" : sessionTracking }];

    XCTAssertEqual([sessionTracking unsignedIntValue], options.sessionTrackingIntervalMillis);
}

- (void)testDefaultSessionTrackingIntervalMillis
{
    SentryOptions *options = [self getValidOptions:@{}];

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
    SentryOptions *options = [[SentryOptions alloc] init];
    XCTAssertNil(options.parsedDsn);
    [self assertDefaultValues:options];
}

- (void)testNSNull_SetsDefaultValue
{
    SentryOptions *options = [[SentryOptions alloc] initWithDict:@{
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
        @"sdk" : [NSNull null],
        @"enableCaptureFailedRequests" : [NSNull null],
        @"failedRequestStatusCodes" : [NSNull null],
    }
                                                didFailWithError:nil];

    XCTAssertNotNil(options.parsedDsn);
    [self assertDefaultValues:options];
}

- (void)assertDefaultValues:(SentryOptions *)options
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
    XCTAssertTrue([[SentryOptions defaultIntegrations] isEqualToArray:options.integrations],
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

    NSRegularExpression *regexTrace = options.tracePropagationTargets[0];
    XCTAssertTrue([regexTrace.pattern isEqualToString:@".*"]);

    NSRegularExpression *regexRequests = options.failedRequestTargets[0];
    XCTAssertTrue([regexRequests.pattern isEqualToString:@".*"]);

    XCTAssertEqual(NO, options.enableCaptureFailedRequests);

    SentryHttpStatusCodeRange *range = options.failedRequestStatusCodes[0];
    XCTAssertEqual(500, range.min);
    XCTAssertEqual(599, range.max);

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
    XCTAssertEqual(SentryMeta.sdkName, options.sdkInfo.name);
    XCTAssertEqual(SentryMeta.versionString, options.sdkInfo.version);
#pragma clang diagnostic pop
}

- (void)testSetValidDsn
{
    NSString *dsnAsString = @"https://username:password@sentry.io/1";
    SentryOptions *options = [[SentryOptions alloc] init];
    options.dsn = dsnAsString;
    options.enabled = NO;

    SentryDsn *dsn = [[SentryDsn alloc] initWithString:dsnAsString didFailWithError:nil];

    XCTAssertEqual(dsnAsString, options.dsn);
    XCTAssertTrue([dsn.url.absoluteString isEqualToString:options.parsedDsn.url.absoluteString]);
    XCTAssertEqual(NO, options.enabled);
}

- (void)testSetNilDsn
{
    SentryOptions *options = [[SentryOptions alloc] init];

    [options setDsn:nil];
    XCTAssertNil(options.dsn);
    XCTAssertNil(options.parsedDsn);
    XCTAssertEqual(YES, options.enabled);
}

- (void)testSetInvalidValidDsn
{
    SentryOptions *options = [[SentryOptions alloc] init];

    [options setDsn:@"https://username:passwordsentry.io/1"];
    XCTAssertNil(options.dsn);
    XCTAssertNil(options.parsedDsn);
    XCTAssertEqual(YES, options.enabled);
}

- (void)testSdkInfo
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SentryOptions *options = [[SentryOptions alloc] init];
    XCTAssertEqual(SentryMeta.sdkName, options.sdkInfo.name);
    XCTAssertEqual(SentryMeta.versionString, options.sdkInfo.version);
#pragma clang diagnostic pop
}

- (void)testSetCustomSdkInfo
{
    NSDictionary *dict = @{ @"name" : @"custom.sdk", @"version" : @"1.2.3-alpha.0" };

    NSError *error = nil;
    SentryOptions *options =
        [[SentryOptions alloc] initWithDict:@{ @"sdk" : dict, @"dsn" : @"https://a:b@c.d/1" }
                           didFailWithError:&error];

    XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(dict[@"name"], options.sdkInfo.name);
    XCTAssertEqual(dict[@"version"], options.sdkInfo.version);
#pragma clang diagnostic pop

    NSDictionary *info = [[NSBundle bundleForClass:[SentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    SentryMeta.versionString = version;
}

- (void)testSetCustomSdkName
{
    NSDictionary *dict = @{ @"name" : @"custom.sdk" };
    NSString *originalVersion = SentryMeta.versionString;

    NSError *error = nil;
    SentryOptions *options =
        [[SentryOptions alloc] initWithDict:@{ @"sdk" : dict, @"dsn" : @"https://a:b@c.d/1" }
                           didFailWithError:&error];

    XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(dict[@"name"], options.sdkInfo.name);
    // version stays unchanged
    XCTAssertEqual(SentryMeta.versionString, options.sdkInfo.version);
    XCTAssertEqual(SentryMeta.versionString, originalVersion);
#pragma clang diagnostic pop
}

- (void)testSetCustomSdkVersion
{
    NSDictionary *dict = @{ @"version" : @"1.2.3-alpha.0" };
    NSString *originalName = SentryMeta.sdkName;

    NSError *error = nil;
    SentryOptions *options =
        [[SentryOptions alloc] initWithDict:@{ @"sdk" : dict, @"dsn" : @"https://a:b@c.d/1" }
                           didFailWithError:&error];

    XCTAssertNil(error);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(dict[@"version"], options.sdkInfo.version);
    // name stays unchanged
    XCTAssertEqual(SentryMeta.sdkName, options.sdkInfo.name);
    XCTAssertEqual(SentryMeta.sdkName, originalName);
#pragma clang diagnostic pop

    NSDictionary *info = [[NSBundle bundleForClass:[SentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    SentryMeta.versionString = version;
}

- (void)testMaxAttachmentSize
{
    NSNumber *maxAttachmentSize = @21;
    SentryOptions *options = [self getValidOptions:@{ @"maxAttachmentSize" : maxAttachmentSize }];

    XCTAssertEqual([maxAttachmentSize unsignedIntValue], options.maxAttachmentSize);
}

- (void)testDefaultMaxAttachmentSize
{
    SentryOptions *options = [self getValidOptions:@{}];

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
    SentryOptions *options = [self getValidOptions:@{ @"idleTimeout" : idleTimeout }];

    XCTAssertEqual([idleTimeout doubleValue], options.idleTimeout);
}

#endif

- (void)testEnableAppHangTracking
{
    [self testBooleanField:@"enableAppHangTracking" defaultValue:NO];
}

- (void)testDefaultAppHangsTimeout
{
    SentryOptions *options = [self getValidOptions:@{}];
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
    SentryOptions *options = [self getValidOptions:@{ @"tracesSampleRate" : @0.1 }];

    XCTAssertEqual(options.tracesSampleRate.doubleValue, 0.1);
}

- (void)testDefaultTracesSampleRate
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.tracesSampleRate);
}

- (void)testTracesSampleRate_SetToNil
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.tracesSampleRate = nil;
    XCTAssertNil(options.tracesSampleRate);
}

- (void)testTracesSampleRateLowerBound
{
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryTracesSamplerCallback sampler = ^(SentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @1.0;
    };

    SentryOptions *options = [self getValidOptions:@{ @"tracesSampler" : sampler }];

    SentrySamplingContext *context = [[SentrySamplingContext alloc] init];
    XCTAssertEqual(options.tracesSampler(context), @1.0);
}

- (void)testDefaultTracesSampler
{
    SentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.tracesSampler);
}

- (void)testGarbageTracesSampler_ReturnsNil
{
    SentryOptions *options = [self getValidOptions:@{ @"tracesSampler" : @"fault" }];
    XCTAssertNil(options.tracesSampler);
}

- (void)testIsTracingEnabled_NothingSet_IsDisabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    XCTAssertFalse(options.isTracingEnabled);
}

- (void)testIsTracingEnabled_TracesSampleRateSetToZero_IsDisabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.tracesSampleRate = @0.00;
    XCTAssertFalse(options.isTracingEnabled);
}

- (void)testIsTracingEnabled_TracesSampleRateSet_IsEnabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.tracesSampleRate = @0.01;
    XCTAssertTrue(options.isTracingEnabled);
}

- (void)testIsTracingEnabled_TracesSamplerSet_IsEnabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.tracesSampler = ^(SentrySamplingContext *context) {
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
    SentryOptions *options = [self getValidOptions:@{ @"profilesSampleRate" : @0.1 }];

    XCTAssertEqual(options.profilesSampleRate.doubleValue, 0.1);
}

- (void)testDefaultProfilesSampleRate
{
    SentryOptions *options = [self getValidOptions:@{}];

    XCTAssertNil(options.profilesSampleRate);
}

- (void)testProfilesSampleRate_SetToNil
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.profilesSampleRate = nil;
    XCTAssertNil(options.profilesSampleRate);
}

- (void)testProfilesSampleRateLowerBound
{
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryOptions *options = [[SentryOptions alloc] init];
    XCTAssertFalse(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_ProfilesSampleRateSetToZero_IsDisabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.profilesSampleRate = @0.00;
    XCTAssertFalse(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_ProfilesSampleRateSet_IsEnabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.profilesSampleRate = @0.01;
    XCTAssertTrue(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_ProfilesSamplerSet_IsEnabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
    options.profilesSampler = ^(SentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @0.0;
    };
    XCTAssertTrue(options.isProfilingEnabled);
}

- (void)testIsProfilingEnabled_EnableProfilingSet_IsEnabled
{
    SentryOptions *options = [[SentryOptions alloc] init];
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
    SentryTracesSamplerCallback sampler = ^(SentrySamplingContext *context) {
        XCTAssertNotNil(context);
        return @1.0;
    };

    SentryOptions *options = [self getValidOptions:@{ @"profilesSampler" : sampler }];

    SentrySamplingContext *context = [[SentrySamplingContext alloc] init];
    XCTAssertEqual(options.profilesSampler(context), @1.0);
}

- (void)testDefaultProfilesSampler
{
    SentryOptions *options = [self getValidOptions:@{}];
    XCTAssertNil(options.profilesSampler);
}

- (void)testGarbageProfilesSampler_ReturnsNil
{
    SentryOptions *options = [self getValidOptions:@{ @"profilesSampler" : @"fault" }];
    XCTAssertNil(options.profilesSampler);
}
#endif

- (void)testInAppIncludes
{
    NSArray<NSString *> *expected = @[ @"iOS-Swift", @"BusinessLogic" ];
    NSArray *inAppIncludes = @[ @"iOS-Swift", @"BusinessLogic", @1 ];
    SentryOptions *options = [self getValidOptions:@{ @"inAppIncludes" : inAppIncludes }];

    NSString *bundleExecutable = [self getBundleExecutable];
    if (nil != bundleExecutable) {
        expected = [expected arrayByAddingObject:bundleExecutable];
    }

    [self assertArrayEquals:expected actual:options.inAppIncludes];
}

- (void)testAddInAppIncludes
{
    SentryOptions *options = [self getValidOptions:@{}];
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
    SentryOptions *options = [self getValidOptions:@{}];
    XCTAssertEqualObjects([self getDefaultInAppIncludes], options.inAppIncludes);
}

- (void)testInAppExcludes
{
    NSArray<NSString *> *expected = @[ @"Sentry" ];
    NSArray *inAppExcludes = @[ @"Sentry", @2 ];

    SentryOptions *options = [self getValidOptions:@{ @"inAppExcludes" : inAppExcludes }];

    XCTAssertEqualObjects(expected, options.inAppExcludes);
}

- (void)testAddInAppExcludes
{
    SentryOptions *options = [self getValidOptions:@{}];
    [options addInAppExclude:@"App"];
    XCTAssertEqualObjects(@[ @"App" ], options.inAppExcludes);
}

- (void)testDefaultInAppExcludes
{
    SentryOptions *options = [self getValidOptions:@{}];
    XCTAssertEqualObjects(@[], options.inAppExcludes);
}

- (SentryOptions *)getValidOptions:(NSDictionary<NSString *, id> *)dict
{
    NSError *error = nil;

    NSMutableDictionary<NSString *, id> *options = [[NSMutableDictionary alloc] init];
    options[@"dsn"] = @"https://username:password@sentry.io/1";

    [options addEntriesFromDictionary:dict];

    SentryOptions *sentryOptions = [[SentryOptions alloc] initWithDict:options
                                                      didFailWithError:&error];
    XCTAssertNil(error);
    return sentryOptions;
}

- (void)testUrlSessionDelegate
{
    id<NSURLSessionDelegate> urlSessionDelegate = [[UrlSessionDelegateSpy alloc] init];

    SentryOptions *options = [self getValidOptions:@{ @"urlSessionDelegate" : urlSessionDelegate }];

    XCTAssertNotNil(options.urlSessionDelegate);
}

- (void)testSdkInfoChanges
{
    SentryOptions *options = [self getValidOptions:@{}];
    SentryMeta.sdkName = @"new name";
    SentryMeta.versionString = @"0.0.6";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqual(options.sdkInfo.name, SentryMeta.sdkName);
    XCTAssertEqual(options.sdkInfo.version, SentryMeta.versionString);
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
    SentryOptions *options = [self getValidOptions:@{ property : @(!defaultValue) }];
    XCTAssertEqual(!defaultValue, [self getProperty:property of:options]);

    // Default
    options = [self getValidOptions:@{}];
    XCTAssertEqual(defaultValue, [self getProperty:property of:options]);

    // Garbage
    options = [self getValidOptions:@{ property : @"" }];
    XCTAssertEqual(NO, [self getProperty:property of:options]);
}

- (BOOL)getProperty:(NSString *)property of:(SentryOptions *)options
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
