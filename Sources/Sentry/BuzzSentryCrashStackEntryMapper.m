#import "BuzzSentryCrashStackEntryMapper.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryHexAddressFormatter.h"
#import "BuzzSentryInAppLogic.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryCrashStackEntryMapper ()

@property (nonatomic, strong) BuzzSentryInAppLogic *inAppLogic;

@end

@implementation BuzzSentryCrashStackEntryMapper

- (instancetype)initWithInAppLogic:(BuzzSentryInAppLogic *)inAppLogic
{
    if (self = [super init]) {
        self.inAppLogic = inAppLogic;
    }
    return self;
}

- (BuzzSentryFrame *)sentryCrashStackEntryToBuzzSentryFrame:(SentryCrashStackEntry)stackEntry
{
    BuzzSentryFrame *frame = [[BuzzSentryFrame alloc] init];

    NSNumber *symbolAddress = @(stackEntry.symbolAddress);
    frame.symbolAddress = sentry_formatHexAddress(symbolAddress);

    NSNumber *instructionAddress = @(stackEntry.address);
    frame.instructionAddress = sentry_formatHexAddress(instructionAddress);

    NSNumber *imageAddress = @(stackEntry.imageAddress);
    frame.imageAddress = sentry_formatHexAddress(imageAddress);

    if (stackEntry.symbolName != NULL) {
        frame.function = [NSString stringWithCString:stackEntry.symbolName
                                            encoding:NSUTF8StringEncoding];
    }

    if (stackEntry.imageName != NULL) {
        NSString *imageName = [NSString stringWithCString:stackEntry.imageName
                                                 encoding:NSUTF8StringEncoding];
        frame.package = imageName;
        frame.inApp = @([self.inAppLogic isInApp:imageName]);
    }

    return frame;
}

- (BuzzSentryFrame *)mapStackEntryWithCursor:(SentryCrashStackCursor)stackCursor
{
    return [self sentryCrashStackEntryToBuzzSentryFrame:stackCursor.stackEntry];
}

@end

NS_ASSUME_NONNULL_END
