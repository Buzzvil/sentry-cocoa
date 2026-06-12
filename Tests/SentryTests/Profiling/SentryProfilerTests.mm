#import "BuzzSentryProfilingConditionals.h"

#if SENTRY_TARGET_PROFILING_SUPPORTED

#    import "BuzzSentryProfiler.h"
#    import <XCTest/XCTest.h>
#    import <execinfo.h>

@interface BuzzSentryProfilerTests : XCTestCase
@end

@implementation BuzzSentryProfilerTests

- (void)testParseFunctionNameWithFixedInput
{
    const auto functionName = parseBacktraceSymbolsFunctionName(
        "2   UIKitCore                           0x00000001850d97ac -[UIFieldEditor "
        "_fullContentInsetsFromFonts] + 160");
    XCTAssertEqualObjects(functionName, @"-[UIFieldEditor _fullContentInsetsFromFonts]");
}

- (void)testParseFunctionNameWithBacktraceSymbolsInput
{
    void *buffer[64];
    const auto nptrs = backtrace(buffer, 64);
    if (nptrs <= 0) {
        XCTFail("Failed to collect a backtrace");
        return;
    }

    const auto symbols = backtrace_symbols(buffer, nptrs);
    XCTAssertEqualObjects(parseBacktraceSymbolsFunctionName(symbols[0]),
        @"-[BuzzSentryProfilerTests testParseFunctionNameWithBacktraceSymbolsInput]");
}

- (void)testProfilerCanBeInitializedOnMainThread
{
    XCTAssertNotNil([[BuzzSentryProfiler alloc] init]);
}

- (void)testProfilerCanBeInitializedOffMainThread
{
    const auto expectation = [self expectationWithDescription:@"background initializing profiler"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        XCTAssertNotNil([[BuzzSentryProfiler alloc] init]);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0
                                 handler:^(NSError *_Nullable error) { NSLog(@"%@", error); }];
}

@end

#endif
