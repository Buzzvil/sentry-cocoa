#import "BuzzSentryStacktrace.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryLog.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryStacktrace

- (instancetype)initWithFrames:(NSArray<BuzzSentryFrame *> *)frames
                     registers:(NSDictionary<NSString *, NSString *> *)registers
{
    self = [super init];
    if (self) {
        self.registers = registers;
        self.frames = frames;
    }
    return self;
}

/// This function fixes duplicate frames and removes the first duplicate
/// https://github.com/kstenerud/KSCrash/blob/05cdc801cfc578d256f85de2e72ec7877cbe79f8/Source/KSCrash/Recording/Tools/KSStackCursor_MachineContext.c#L84
- (void)fixDuplicateFrames
{
    if (self.frames.count < 2 || nil == self.registers) {
        return;
    }

    BuzzSentryFrame *lastFrame = self.frames.lastObject;
    BuzzSentryFrame *beforeLastFrame = [self.frames objectAtIndex:self.frames.count - 2];

    if ([lastFrame.symbolAddress isEqualToString:beforeLastFrame.symbolAddress] &&
        [self.registers[@"lr"] isEqualToString:beforeLastFrame.instructionAddress]) {
        NSMutableArray *copyFrames = self.frames.mutableCopy;
        [copyFrames removeObjectAtIndex:self.frames.count - 2];
        self.frames = copyFrames;
        SENTRY_LOG_DEBUG(@"Found duplicate frame, removing one with link register");
    }
}

- (NSDictionary<NSString *, id> *)serialize
{
    NSMutableDictionary *serializedData = [NSMutableDictionary new];

    NSMutableArray *frames = [NSMutableArray new];
    for (BuzzSentryFrame *frame in self.frames) {
        NSDictionary *serialized = [frame serialize];
        if (serialized.allKeys.count > 0) {
            [frames addObject:[frame serialize]];
        }
    }
    if (frames.count > 0) {
        [serializedData setValue:frames forKey:@"frames"];
    }
    // This is here because we wanted to be conform with the old json
    if (self.registers.count > 0) {
        [serializedData setValue:self.registers forKey:@"registers"];
    }
    [serializedData setValue:self.snapshot forKey:@"snapshot"];

    return serializedData;
}

@end

NS_ASSUME_NONNULL_END
