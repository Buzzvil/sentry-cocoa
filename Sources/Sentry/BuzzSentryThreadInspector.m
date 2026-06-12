#import "BuzzSentryThreadInspector.h"
#import "BuzzSentryCrashStackCursor.h"
#include "BuzzSentryCrashStackCursor_MachineContext.h"
#include "BuzzSentryCrashSymbolicator.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryStacktraceBuilder.h"
#import "BuzzSentryThread.h"
#include <pthread.h>

@interface
BuzzSentryThreadInspector ()

@property (nonatomic, strong) BuzzSentryStacktraceBuilder *stacktraceBuilder;
@property (nonatomic, strong) id<BuzzSentryCrashMachineContextWrapper> machineContextWrapper;

@end

typedef struct {
    BuzzSentryCrashThread thread;
    BuzzSentryCrashStackEntry stackEntries[MAX_STACKTRACE_LENGTH];
    int stackLength;
} BuzzSentryThreadInfo;

// We need a C function to retrieve information from the stack trace in order to avoid
// calling into not async-signal-safe code while there are suspended threads.
unsigned int
getStackEntriesFromThread(BuzzSentryCrashThread thread, struct BuzzSentryCrashMachineContext *context,
    BuzzSentryCrashStackEntry *buffer, unsigned int maxEntries)
{
    sentrycrashmc_getContextForThread(thread, context, false);
    BuzzSentryCrashStackCursor stackCursor;
    sentrycrashsc_initWithMachineContext(&stackCursor, MAX_STACKTRACE_LENGTH, context);

    unsigned int entries = 0;
    while (stackCursor.advanceCursor(&stackCursor)) {
        if (entries == maxEntries)
            break;
        if (stackCursor.symbolicate(&stackCursor)) {
            buffer[entries] = stackCursor.stackEntry;
            entries++;
        }
    }
    sentrycrash_async_backtrace_decref(stackCursor.async_caller);

    return entries;
}

@implementation BuzzSentryThreadInspector

- (id)initWithStacktraceBuilder:(BuzzSentryStacktraceBuilder *)stacktraceBuilder
       andMachineContextWrapper:(id<BuzzSentryCrashMachineContextWrapper>)machineContextWrapper
{
    if (self = [super init]) {
        self.stacktraceBuilder = stacktraceBuilder;
        self.machineContextWrapper = machineContextWrapper;
    }
    return self;
}

- (NSArray<BuzzSentryThread *> *)getCurrentThreads
{
    NSMutableArray<BuzzSentryThread *> *threads = [NSMutableArray new];

    BuzzSentryCrashMC_NEW_CONTEXT(context);
    BuzzSentryCrashThread currentThread = sentrycrashthread_self();

    [self.machineContextWrapper fillContextForCurrentThread:context];
    int threadCount = [self.machineContextWrapper getThreadCount:context];

    for (int i = 0; i < threadCount; i++) {
        BuzzSentryCrashThread thread = [self.machineContextWrapper getThread:context withIndex:i];
        BuzzSentryThread *sentryThread = [[BuzzSentryThread alloc] initWithThreadId:@(i)];

        sentryThread.name = [self getThreadName:thread];

        sentryThread.crashed = @NO;
        bool isCurrent = thread == currentThread;
        sentryThread.current = @(isCurrent);

        if (isCurrent) {
            sentryThread.stacktrace = [self.stacktraceBuilder buildStacktraceForCurrentThread];
        }

        // We need to make sure the main thread is always the first thread in the result
        if ([self.machineContextWrapper isMainThread:thread])
            [threads insertObject:sentryThread atIndex:0];
        else
            [threads addObject:sentryThread];
    }

    return threads;
}

/**
 * We are not sharing code with 'getCurrentThreads' because both methods use different approaches.
 * This method retrieves thread information from the suspend method
 * while the other retrieves information from the machine context.
 * Having both approaches in the same method can lead to inconsistency between the number of
 * threads, and while there is suspended threads we can't call into obj-c, so the previous approach
 * wont work for retrieving stacktrace information for every thread.
 */
- (NSArray<BuzzSentryThread *> *)getCurrentThreadsWithStackTrace
{
    NSMutableArray<BuzzSentryThread *> *threads = [NSMutableArray new];

    @synchronized(self) {
        BuzzSentryCrashMC_NEW_CONTEXT(context);
        BuzzSentryCrashThread currentThread = sentrycrashthread_self();

        thread_act_array_t suspendedThreads = NULL;
        mach_msg_type_number_t numSuspendedThreads = 0;

        sentrycrashmc_suspendEnvironment(&suspendedThreads, &numSuspendedThreads);
        // DANGER: Do not try to allocate memory in the heap or call Objective-C code in this
        // section Doing so when the threads are suspended may lead to deadlocks or crashes.

        BuzzSentryThreadInfo threadsInfos[numSuspendedThreads];

        for (int i = 0; i < numSuspendedThreads; i++) {
            if (suspendedThreads[i] != currentThread) {
                int numberOfEntries = getStackEntriesFromThread(suspendedThreads[i], context,
                    threadsInfos[i].stackEntries, MAX_STACKTRACE_LENGTH);
                threadsInfos[i].stackLength = numberOfEntries;
            } else {
                // We can't use 'getStackEntriesFromThread' to retrieve stack frames from the
                // current thread. We are using the stackTraceBuilder to retrieve this information
                // later.
                threadsInfos[i].stackLength = 0;
            }
            threadsInfos[i].thread = suspendedThreads[i];
        }

        sentrycrashmc_resumeEnvironment(suspendedThreads, numSuspendedThreads);
        // DANGER END: You may call Objective-C code again or allocate memory.

        for (int i = 0; i < numSuspendedThreads; i++) {
            BuzzSentryThread *sentryThread = [[BuzzSentryThread alloc] initWithThreadId:@(i)];

            sentryThread.name = [self getThreadName:threadsInfos[i].thread];

            sentryThread.crashed = @NO;
            bool isCurrent = threadsInfos[i].thread == currentThread;
            sentryThread.current = @(isCurrent);

            if (isCurrent) {
                sentryThread.stacktrace = [self.stacktraceBuilder buildStacktraceForCurrentThread];
            } else {
                sentryThread.stacktrace = [self.stacktraceBuilder
                    buildStackTraceFromStackEntries:threadsInfos[i].stackEntries
                                             amount:threadsInfos[i].stackLength];
            }

            // We need to make sure the main thread is always the first thread in the result
            if ([self.machineContextWrapper isMainThread:threadsInfos[i].thread])
                [threads insertObject:sentryThread atIndex:0];
            else
                [threads addObject:sentryThread];
        }
    }

    return threads;
}

- (NSString *)getThreadName:(BuzzSentryCrashThread)thread
{
    char buffer[128];
    char *const pBuffer = buffer;
    [self.machineContextWrapper getThreadName:thread andBuffer:pBuffer andBufLength:128];

    NSString *threadName = [NSString stringWithCString:pBuffer encoding:NSUTF8StringEncoding];
    if (nil == threadName) {
        threadName = @"";
    }
    return threadName;
}

@end
