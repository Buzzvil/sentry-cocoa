#import "BuzzSentrySessionCrashedHandler.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryCrashWrapper.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryFileManager.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryOutOfMemoryLogic.h"
#import "BuzzSentrySDK+Private.h"

@interface
BuzzSentrySessionCrashedHandler ()

@property (nonatomic, strong) BuzzSentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) BuzzSentryOutOfMemoryLogic *outOfMemoryLogic;

@end

@implementation BuzzSentrySessionCrashedHandler

- (instancetype)initWithCrashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                    outOfMemoryLogic:(BuzzSentryOutOfMemoryLogic *)outOfMemoryLogic;
{
    self = [self init];
    self.crashWrapper = crashWrapper;
    self.outOfMemoryLogic = outOfMemoryLogic;

    return self;
}

- (void)endCurrentSessionAsCrashedWhenCrashOrOOM
{
    if (self.crashWrapper.crashedLastLaunch || [self.outOfMemoryLogic isOOM]) {
        BuzzSentryFileManager *fileManager = [[[BuzzSentrySDK currentHub] getClient] fileManager];

        if (nil == fileManager) {
            return;
        }

        BuzzSentrySession *session = [fileManager readCurrentSession];
        if (nil == session) {
            return;
        }

        NSDate *timeSinceLastCrash = [[BuzzSentryCurrentDate date]
            dateByAddingTimeInterval:-self.crashWrapper.activeDurationSinceLastCrash];

        [session endSessionCrashedWithTimestamp:timeSinceLastCrash];
        [fileManager storeCrashedSession:session];
        [fileManager deleteCurrentSession];
    }
}

@end
