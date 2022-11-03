#import "BuzzSentryStacktraceBuilder.h"
#import "SentryCrashStackCursor.h"
#import "SentryCrashStackCursor_MachineContext.h"
#import "SentryCrashStackCursor_SelfThread.h"
#import "BuzzSentryCrashStackEntryMapper.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryFrameRemover.h"
#import "BuzzSentryStacktrace.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryStacktraceBuilder ()

@property (nonatomic, strong) BuzzSentryCrashStackEntryMapper *crashStackEntryMapper;

@end

@implementation BuzzSentryStacktraceBuilder

- (id)initWithCrashStackEntryMapper:(BuzzSentryCrashStackEntryMapper *)crashStackEntryMapper
{
    if (self = [super init]) {
        self.crashStackEntryMapper = crashStackEntryMapper;
    }
    return self;
}

- (BuzzSentryStacktrace *)retrieveStacktraceFromCursor:(SentryCrashStackCursor)stackCursor
{
    NSMutableArray<BuzzSentryFrame *> *frames = [NSMutableArray new];
    BuzzSentryFrame *frame = nil;
    while (stackCursor.advanceCursor(&stackCursor)) {
        if (stackCursor.symbolicate(&stackCursor)) {
            if (stackCursor.stackEntry.address == SentryCrashSC_ASYNC_MARKER) {
                if (frame != nil) {
                    frame.stackStart = @(YES);
                }
                // skip the marker frame
                continue;
            }
            frame = [self.crashStackEntryMapper mapStackEntryWithCursor:stackCursor];
            [frames addObject:frame];
        }
    }
    sentrycrash_async_backtrace_decref(stackCursor.async_caller);

    NSArray<BuzzSentryFrame *> *framesCleared = [BuzzSentryFrameRemover removeNonSdkFrames:frames];

    // The frames must be ordered from caller to callee, or oldest to youngest
    NSArray<BuzzSentryFrame *> *framesReversed = [[framesCleared reverseObjectEnumerator] allObjects];

    BuzzSentryStacktrace *stacktrace = [[BuzzSentryStacktrace alloc] initWithFrames:framesReversed
                                                                  registers:@{}];

    return stacktrace;
}

- (BuzzSentryStacktrace *)buildStackTraceFromStackEntries:(SentryCrashStackEntry *)entries
                                               amount:(unsigned int)amount
{
    NSMutableArray<BuzzSentryFrame *> *frames = [[NSMutableArray alloc] initWithCapacity:amount];
    BuzzSentryFrame *frame = nil;
    for (int i = 0; i < amount; i++) {
        SentryCrashStackEntry stackEntry = entries[i];
        if (stackEntry.address == SentryCrashSC_ASYNC_MARKER) {
            if (frame != nil) {
                frame.stackStart = @(YES);
            }
            // skip the marker frame
            continue;
        }
        frame = [self.crashStackEntryMapper sentryCrashStackEntryToBuzzSentryFrame:stackEntry];
        [frames addObject:frame];
    }

    NSArray<BuzzSentryFrame *> *framesCleared = [BuzzSentryFrameRemover removeNonSdkFrames:frames];

    // The frames must be ordered from caller to callee, or oldest to youngest
    NSArray<BuzzSentryFrame *> *framesReversed = [[framesCleared reverseObjectEnumerator] allObjects];

    return [[BuzzSentryStacktrace alloc] initWithFrames:framesReversed registers:@{}];
}

- (BuzzSentryStacktrace *)buildStacktraceForThread:(SentryCrashThread)thread
                                       context:(struct SentryCrashMachineContext *)context
{
    sentrycrashmc_getContextForThread(thread, context, false);
    SentryCrashStackCursor stackCursor;
    sentrycrashsc_initWithMachineContext(&stackCursor, MAX_STACKTRACE_LENGTH, context);

    return [self retrieveStacktraceFromCursor:stackCursor];
}

- (BuzzSentryStacktrace *)buildStacktraceForCurrentThread
{
    SentryCrashStackCursor stackCursor;
    // We don't need to skip any frames, because we filter out non sentry frames below.
    NSInteger framesToSkip = 0;
    sentrycrashsc_initSelfThread(&stackCursor, (int)framesToSkip);

    return [self retrieveStacktraceFromCursor:stackCursor];
}

@end

NS_ASSUME_NONNULL_END
