#import "SentryHub.h"
#import "BuzzSentrySpan.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTransactionContext.h"
#import <XCTest/XCTest.h>

@interface BuzzSentryTracerObjCTests : XCTestCase

@end

@implementation BuzzSentryTracerObjCTests

/**
 * This test makes sure that the span has a weak reference to the tracer and doesn't call the
 * tracer#spanFinished method.
 */
- (void)testSpanFinishesAfterTracerReleased_NoCrash_TracerIsNil
{
    BuzzSentrySpan *child;
    // To make sure the tracer is deallocated.
    @autoreleasepool {
        SentryHub *hub = [[SentryHub alloc] initWithClient:nil andScope:nil];
        BuzzSentryTransactionContext *context =
            [[BuzzSentryTransactionContext alloc] initWithOperation:@""];
        BuzzSentryTracer *tracer = [[BuzzSentryTracer alloc] initWithTransactionContext:context
                                                                            hub:hub
                                                        profilesSamplerDecision:nil
                                                                waitForChildren:YES];
        [tracer finish];
        child = [tracer startChildWithOperation:@"child"];
    }

    XCTAssertNotNil(child);
    [child finish];
}

@end
