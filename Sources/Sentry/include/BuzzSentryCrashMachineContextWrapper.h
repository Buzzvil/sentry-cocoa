#import "BuzzSentryCrashMachineContext.h"
#import "BuzzSentryCrashThread.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** A wrapper around BuzzSentryCrashMachineContext for testability.
 */
@protocol BuzzSentryCrashMachineContextWrapper <NSObject>

- (void)fillContextForCurrentThread:(struct BuzzSentryCrashMachineContext *)context;

- (int)getThreadCount:(struct BuzzSentryCrashMachineContext *)context;

- (BuzzSentryCrashThread)getThread:(struct BuzzSentryCrashMachineContext *)context withIndex:(int)index;

- (void)getThreadName:(const BuzzSentryCrashThread)thread
            andBuffer:(char *const)buffer
         andBufLength:(int)bufLength;

- (BOOL)isMainThread:(BuzzSentryCrashThread)thread;

@end

NS_ASSUME_NONNULL_END
