#import "SentryTestObserver.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient.h"
#import "BuzzSentryCrashIntegration.h"
#import "BuzzSentryCrashWrapper.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryLog+TestInit.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentryScope.h"
#import "BuzzSentrySDK+Private.h"
#import "XCTest/XCTIssue.h"
#import "XCTest/XCTest.h"
#import "XCTest/XCTestCase.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
SentryTestObserver ()

@property (nonatomic, strong) BuzzSentryOptions *options;
@property (nonatomic, strong) BuzzSentryScope *scope;

@end

@implementation SentryTestObserver

+ (void)load
{
#if defined(TESTCI)
    [[XCTestObservationCenter sharedTestObservationCenter]
        addTestObserver:[[SentryTestObserver alloc] init]];
#endif
    [BuzzSentryLog configure:YES diagnosticLevel:kBuzzSentryLevelDebug];
}

- (instancetype)init
{
    if (self = [super init]) {
        BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
        options.dsn = @"https://6cc9bae94def43cab8444a99e0031c28@o447951.ingest.sentry.io/5428557";
        options.environment = @"unit-tests";
        options.debug = YES;
        options.enableAutoSessionTracking = NO;
        options.maxBreadcrumbs = 5000;

        // The BuzzSentryCrashIntegration enriches the scope. We need to install the integration
        // once to get the scope data.
        [BuzzSentrySDK startWithOptionsObject:options];

        self.scope = [[BuzzSentryScope alloc] init];
        [BuzzSentryCrashIntegration enrichScope:self.scope
                               crashWrapper:[BuzzSentryCrashWrapper sharedInstance]];

        self.options = options;
    }
    return self;
}

#pragma mark - XCTestObservation

- (void)testCaseWillStart:(XCTestCase *)testCase
{
    BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:kBuzzSentryLevelDebug
                                                             category:@"test.started"];
    [crumb setMessage:testCase.name];
    // The tests might have a different time set
    [crumb setTimestamp:[NSDate new]];
    [self.scope addBreadcrumb:crumb];
}

- (void)testBundleDidFinish:(NSBundle *)testBundle
{
    [BuzzSentrySDK flush:5.0];
}

- (void)testCase:(XCTestCase *)testCase didRecordIssue:(XCTIssue *)issue
{
    // Tests set a fixed time. We want to use the current time for sending
    // the test result to Sentry.
    id<BuzzSentryCurrentDateProvider> currentDateProvider = [BuzzSentryCurrentDate getCurrentDateProvider];
    [BuzzSentryCurrentDate setCurrentDateProvider:[BuzzSentryDefaultCurrentDateProvider sharedInstance]];

    // The tests might mess up the files or something else. Therefore, we create a fresh client and
    // hub to make sure the sending works.
    BuzzSentryClient *client = [[BuzzSentryClient alloc] initWithOptions:self.options];
    // We create our own hub here, because we don't know the state of the BuzzSentrySDK.
    BuzzSentryHub *hub = [[BuzzSentryHub alloc] initWithClient:client andScope:self.scope];
    NSException *exception = [[NSException alloc] initWithName:testCase.name
                                                        reason:issue.description
                                                      userInfo:nil];
    [hub captureException:exception withScope:hub.scope];

    [BuzzSentryCurrentDate setCurrentDateProvider:currentDateProvider];
}

@end

NS_ASSUME_NONNULL_END
