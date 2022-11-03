#import "BuzzSentrySessionCrashedHandler.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrashWrapper.h"
#import "SentryCurrentDate.h"
#import "SentryFileManager.h"
#import "SentryHub.h"
#import "SentryOutOfMemoryLogic.h"
#import "BuzzSentrySDK+Private.h"

@interface
BuzzSentrySessionCrashedHandler ()

@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryOutOfMemoryLogic *outOfMemoryLogic;

@end

@implementation BuzzSentrySessionCrashedHandler

- (instancetype)initWithCrashWrapper:(SentryCrashWrapper *)crashWrapper
                    outOfMemoryLogic:(SentryOutOfMemoryLogic *)outOfMemoryLogic;
{
    self = [self init];
    self.crashWrapper = crashWrapper;
    self.outOfMemoryLogic = outOfMemoryLogic;

    return self;
}

- (void)endCurrentSessionAsCrashedWhenCrashOrOOM
{
    if (self.crashWrapper.crashedLastLaunch || [self.outOfMemoryLogic isOOM]) {
        SentryFileManager *fileManager = [[[SentrySDK currentHub] getClient] fileManager];

        if (nil == fileManager) {
            return;
        }

        BuzzSentrySession *session = [fileManager readCurrentSession];
        if (nil == session) {
            return;
        }

        NSDate *timeSinceLastCrash = [[SentryCurrentDate date]
            dateByAddingTimeInterval:-self.crashWrapper.activeDurationSinceLastCrash];

        [session endSessionCrashedWithTimestamp:timeSinceLastCrash];
        [fileManager storeCrashedSession:session];
        [fileManager deleteCurrentSession];
    }
}

@end
