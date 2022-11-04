#import "BuzzSentryStacktraceBuilder.h"
#import "BuzzSentryCrashStackCursor.h"
#import "BuzzSentryCrashStackCursor_MachineContext.h"
#import "BuzzSentryCrashStackCursor_SelfThread.h"
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

- (BuzzSentryStacktrace *)retrieveStacktraceFromCursor:(BuzzSentryCrashStackCursor)stackCursor
{
    NSMutableArray<BuzzSentryFrame *> *frames = [NSMutableArray new];
    BuzzSentryFrame *frame = nil;
    while (stackCursor.advanceCursor(&stackCursor)) {
        if (stackCursor.symbolicate(&stackCursor)) {
            if (stackCursor.stackEntry.address == BuzzSentryCrashSC_ASYNC_MARKER) {
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

- (BuzzSentryStacktrace *)buildStackTraceFromStackEntries:(BuzzSentryCrashStackEntry *)entries
                                               amount:(unsigned int)amount
{
    NSMutableArray<BuzzSentryFrame *> *frames = [[NSMutableArray alloc] initWithCapacity:amount];
    BuzzSentryFrame *frame = nil;
    for (int i = 0; i < amount; i++) {
        BuzzSentryCrashStackEntry stackEntry = entries[i];
        if (stackEntry.address == BuzzSentryCrashSC_ASYNC_MARKER) {
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

- (BuzzSentryStacktrace *)buildStacktraceForThread:(BuzzSentryCrashThread)thread
                                       context:(struct BuzzSentryCrashMachineContext *)context
{
    sentrycrashmc_getContextForThread(thread, context, false);
    BuzzSentryCrashStackCursor stackCursor;
    sentrycrashsc_initWithMachineContext(&stackCursor, MAX_STACKTRACE_LENGTH, context);

    return [self retrieveStacktraceFromCursor:stackCursor];
}

- (BuzzSentryStacktrace *)buildStacktraceForCurrentThread
{
    BuzzSentryCrashStackCursor stackCursor;
    // We don't need to skip any frames, because we filter out non sentry frames below.
    NSInteger framesToSkip = 0;
    sentrycrashsc_initSelfThread(&stackCursor, (int)framesToSkip);

    return [self retrieveStacktraceFromCursor:stackCursor];
}

@end

NS_ASSUME_NONNULL_END