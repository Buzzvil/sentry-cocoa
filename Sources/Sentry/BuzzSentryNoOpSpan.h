#import "SentryDefines.h"
#import "SentrySerializable.h"
#import "BuzzSentrySpanContext.h"
#import "BuzzSentrySpanProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryNoOpSpan : NSObject <BuzzSentrySpan, SentrySerializable>
SENTRY_NO_INIT

+ (instancetype)shared;

@property (nonatomic, readonly) BuzzSentrySpanContext *context;
@property (nullable, nonatomic, strong) NSDate *timestamp;
@property (nullable, nonatomic, strong) NSDate *startTimestamp;
@property (readonly) BOOL isFinished;
@property (nullable, readonly) NSDictionary<NSString *, id> *data;
@property (readonly) NSDictionary<NSString *, NSString *> *tags;

@end

NS_ASSUME_NONNULL_END
