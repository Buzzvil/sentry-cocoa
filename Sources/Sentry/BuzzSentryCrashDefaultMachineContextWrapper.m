#import "BuzzSentryCrashDefaultMachineContextWrapper.h"
#import "BuzzSentryCrashDynamicLinker.h"
#import "BuzzSentryCrashMachineContext.h"
#import "BuzzSentryCrashMachineContextWrapper.h"
#import "BuzzSentryCrashStackCursor.h"
#import "BuzzSentryCrashStackCursor_SelfThread.h"
#import "BuzzSentryCrashThread.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryHexAddressFormatter.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryStacktraceBuilder.h"
#import "BuzzSentryThread.h"
#import <Foundation/Foundation.h>
#include <execinfo.h>
#include <pthread.h>

NS_ASSUME_NONNULL_BEGIN

BuzzSentryCrashThread mainThreadID;

@implementation BuzzSentryCrashDefaultMachineContextWrapper

+ (void)load
{
    mainThreadID = pthread_mach_thread_np(pthread_self());
}

- (void)fillContextForCurrentThread:(struct BuzzSentryCrashMachineContext *)context
{
    sentrycrashmc_getContextForThread(sentrycrashthread_self(), context, true);
}

- (int)getThreadCount:(struct BuzzSentryCrashMachineContext *)context
{
    return sentrycrashmc_getThreadCount(context);
}

- (BuzzSentryCrashThread)getThread:(struct BuzzSentryCrashMachineContext *)context withIndex:(int)index
{
    BuzzSentryCrashThread thread = sentrycrashmc_getThreadAtIndex(context, index);
    return thread;
}

- (void)getThreadName:(const BuzzSentryCrashThread)thread
            andBuffer:(char *const)buffer
         andBufLength:(int)bufLength;
{
    sentrycrashthread_getThreadName(thread, buffer, bufLength);
}

- (BOOL)isMainThread:(BuzzSentryCrashThread)thread
{
    return thread == mainThreadID;
}

@end

NS_ASSUME_NONNULL_END
