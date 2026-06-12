#import "BuzzSentryFrameRemover.h"
#import "BuzzSentryFrame.h"
#import <Foundation/Foundation.h>

@implementation BuzzSentryFrameRemover

+ (NSArray<BuzzSentryFrame *> *)removeNonSdkFrames:(NSArray<BuzzSentryFrame *> *)frames
{
    NSUInteger indexOfFirstNonBuzzSentryFrame = [frames indexOfObjectPassingTest:^BOOL(
        BuzzSentryFrame *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *package = [obj.package lowercaseString];
        package = [package stringByReplacingOccurrencesOfString:@"users/sentry" withString:@""];
        return ![package containsString:@"sentry"];
    }];

    if (indexOfFirstNonBuzzSentryFrame == NSNotFound) {
        return frames;
    } else {
        return [frames subarrayWithRange:NSMakeRange(indexOfFirstNonBuzzSentryFrame,
                                             frames.count - indexOfFirstNonBuzzSentryFrame)];
    }
}

@end
