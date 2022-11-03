#import "BuzzSentrySessionCrashedHandler.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrashWrapper.h"
#import "SentryCurrentDate.h"
#import "SentryFileManager.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryOutOfMemoryLogic.h"
#import "BuzzSentrySDK+Private.h"

@interface
BuzzSentrySessionCrashedHandler ()

@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) BuzzSentryOutOfMemoryLogic *outOfMemoryLogic;

@end

@implementation BuzzSentrySessionCrashedHandler

- (instancetype)initWithCrashWrapper:(SentryCrashWrapper *)crashWrapper
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
        SentryFileManager *fileManager = [[[BuzzSentrySDK currentHub] getClient] fileManager];

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
