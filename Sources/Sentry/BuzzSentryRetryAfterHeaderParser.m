#import "BuzzSentryRetryAfterHeaderParser.h"
#import "SentryCurrentDate.h"
#import "BuzzSentryHttpDateParser.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryRetryAfterHeaderParser ()

@property (nonatomic, strong) BuzzSentryHttpDateParser *httpDateParser;

@end

@implementation BuzzSentryRetryAfterHeaderParser

- (instancetype)initWithHttpDateParser:(BuzzSentryHttpDateParser *)httpDateParser
{
    if (self = [super init]) {
        self.httpDateParser = httpDateParser;
    }
    return self;
}

- (NSDate *_Nullable)parse:(NSString *_Nullable)retryAfterHeader
{
    if (nil == retryAfterHeader || 0 == [retryAfterHeader length]) {
        return nil;
    }

    NSInteger retryAfterSeconds = [retryAfterHeader integerValue];
    if (0 != retryAfterSeconds) {
        return [[SentryCurrentDate date] dateByAddingTimeInterval:retryAfterSeconds];
    }

    // parsing as double/seconds failed, try to parse as date
    NSDate *retryAfterDate = [self.httpDateParser dateFromString:retryAfterHeader];

    return retryAfterDate;
}

@end

NS_ASSUME_NONNULL_END
