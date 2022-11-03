#import "SentryDefines.h"
#import "BuzzSentryMeasurementUnit.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryMeasurementValue : NSObject <BuzzSentrySerializable>
SENTRY_NO_INIT

- (instancetype)initWithValue:(NSNumber *)value;

- (instancetype)initWithValue:(NSNumber *)value unit:(BuzzSentryMeasurementUnit *)unit;

@property (nonatomic, copy, readonly) NSNumber *value;
@property (nullable, readonly, copy) BuzzSentryMeasurementUnit *unit;

@end

NS_ASSUME_NONNULL_END
