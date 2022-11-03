#import "BuzzSentryMeasurementUnit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryMeasurementUnit

- (instancetype)initWithUnit:(NSString *)unit
{
    if (self = [super init]) {
        _unit = unit;
    }
    return self;
}

+ (BuzzSentryMeasurementUnit *)none
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@""];
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithUnit:self.unit];
}

@end

@implementation BuzzSentryMeasurementUnitDuration

+ (BuzzSentryMeasurementUnitDuration *)nanosecond
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"nanosecond"];
}

+ (BuzzSentryMeasurementUnitDuration *)microsecond
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"microsecond"];
}

+ (BuzzSentryMeasurementUnitDuration *)millisecond
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"millisecond"];
}

+ (BuzzSentryMeasurementUnitDuration *)second
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"second"];
}

+ (BuzzSentryMeasurementUnitDuration *)minute
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"minute"];
}

+ (BuzzSentryMeasurementUnitDuration *)hour
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"hour"];
}

+ (BuzzSentryMeasurementUnitDuration *)day
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"day"];
}

+ (BuzzSentryMeasurementUnitDuration *)week
{
    return [[BuzzSentryMeasurementUnitDuration alloc] initWithUnit:@"week"];
}

@end

@implementation BuzzSentryMeasurementUnitInformation

+ (BuzzSentryMeasurementUnitInformation *)bit
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"bit"];
}

+ (BuzzSentryMeasurementUnitInformation *)byte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"byte"];
}

+ (BuzzSentryMeasurementUnitInformation *)kilobyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"kilobyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)kibibyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"kibibyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)megabyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"megabyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)mebibyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"mebibyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)gigabyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"gigabyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)gibibyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"gibibyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)terabyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"terabyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)tebibyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"tebibyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)petabyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"petabyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)pebibyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"pebibyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)exabyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"exabyte"];
}

+ (BuzzSentryMeasurementUnitInformation *)exbibyte
{
    return [[BuzzSentryMeasurementUnitInformation alloc] initWithUnit:@"exbibyte"];
}

@end

@implementation BuzzSentryMeasurementUnitFraction

+ (BuzzSentryMeasurementUnitFraction *)ratio
{
    return [[BuzzSentryMeasurementUnitFraction alloc] initWithUnit:@"ratio"];
}

+ (BuzzSentryMeasurementUnitFraction *)percent
{
    return [[BuzzSentryMeasurementUnitFraction alloc] initWithUnit:@"percent"];
}

@end

NS_ASSUME_NONNULL_END
