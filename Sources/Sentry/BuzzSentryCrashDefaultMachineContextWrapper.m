#import "BuzzSentryCrashDefaultMachineContextWrapper.h"
#import "SentryCrashDynamicLinker.h"
#import "SentryCrashMachineContext.h"
#import "BuzzSentryCrashMachineContextWrapper.h"
#import "SentryCrashStackCursor.h"
#import "SentryCrashStackCursor_SelfThread.h"
#import "SentryCrashThread.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryHexAddressFormatter.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryStacktraceBuilder.h"
#import "BuzzSentryThread.h"
#import <Foundation/Foundation.h>
#include <execinfo.h>
#include <pthread.h>

NS_ASSUME_NONNULL_BEGIN

SentryCrashThread mainThreadID;

@implementation BuzzSentryCrashDefaultMachineContextWrapper

+ (void)load
{
    mainThreadID = pthread_mach_thread_np(pthread_self());
}

- (void)fillContextForCurrentThread:(struct SentryCrashMachineContext *)context
{
    sentrycrashmc_getContextForThread(sentrycrashthread_self(), context, true);
}

- (int)getThreadCount:(struct SentryCrashMachineContext *)context
{
    return sentrycrashmc_getThreadCount(context);
}

- (SentryCrashThread)getThread:(struct SentryCrashMachineContext *)context withIndex:(int)index
{
    SentryCrashThread thread = sentrycrashmc_getThreadAtIndex(context, index);
    return thread;
}

- (void)getThreadName:(const SentryCrashThread)thread
            andBuffer:(char *const)buffer
         andBufLength:(int)bufLength;
{
    sentrycrashthread_getThreadName(thread, buffer, bufLength);
}

- (BOOL)isMainThread:(SentryCrashThread)thread
{
    return thread == mainThreadID;
}

@end

NS_ASSUME_NONNULL_END
