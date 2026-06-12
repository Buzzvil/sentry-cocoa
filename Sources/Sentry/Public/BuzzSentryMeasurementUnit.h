#import <BuzzSentry/BuzzSentryDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The unit of measurement of a metric value.
 *
 * Units augment metric values by giving them a magnitude and semantics. There are certain types
 * of units that are subdivided in their precision, such as the ``BuzzSentryMeasurementUnitDuration``
 * for time measurements. The following unit types are available: ``BuzzSentryMeasurementUnitDuration``,
 * ``BuzzSentryMeasurementUnitInformation``,  and``BuzzSentryMeasurementUnitFraction``.
 *
 * When using the units to custom measurements, Sentry will apply formatting to display
 * measurement values in the UI.
 */
NS_SWIFT_NAME(MeasurementUnit)
@interface BuzzSentryMeasurementUnit : NSObject <NSCopying>
SENTRY_NO_INIT

/**
 * Returns an initialized BuzzSentryMeasurementUnit with a custom measurement unit.
 *
 * @param unit Your own custom unit without built-in conversion in Sentry.
 */
- (instancetype)initWithUnit:(NSString *)unit;

/**
 * The NSString representation of the measurement unit.
 */
@property (readonly, copy) NSString *unit;

/** Untyped value without a unit. */
@property (class, readonly, copy) BuzzSentryMeasurementUnit *none;

@end

/**
 * Time duration units.
 */
NS_SWIFT_NAME(MeasurementUnitDuration)
@interface BuzzSentryMeasurementUnitDuration : BuzzSentryMeasurementUnit
SENTRY_NO_INIT

/** Nanosecond, 10^-9 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *nanosecond;

/** Microsecond , 10^-6 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *microsecond;

/** Millisecond, 10^-3 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *millisecond;

/** Full second. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *second;

/** Minute, 60 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *minute;

/** Hour, 3600 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *hour;

/** Day, 86,400 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *day;

/** Week, 604,800 seconds. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitDuration *week;

@end

/**
 * Size of information units derived from bytes.
 *
 * See also [Units of information](https://en.wikipedia.org/wiki/Units_of_information)
 */
NS_SWIFT_NAME(MeasurementUnitInformation)
@interface BuzzSentryMeasurementUnitInformation : BuzzSentryMeasurementUnit
SENTRY_NO_INIT

/** Bit, corresponding to 1/8 of a byte. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *bit;

/** Byte. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *byte;

/** Kilobyte, 10^3 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *kilobyte;

/** Kibibyte, 2^10 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *kibibyte;

/** Megabyte, 10^6 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *megabyte;

/** Mebibyte, 2^20 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *mebibyte;

/** Gigabyte, 10^9 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *gigabyte;

/** Gibibyte, 2^30 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *gibibyte;

/** Terabyte, 10^12 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *terabyte;

/** Tebibyte, 2^40 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *tebibyte;

/** Petabyte, 10^15 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *petabyte;

/** Pebibyte, 2^50 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *pebibyte;

/** Exabyte, 10^18 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *exabyte;

/** Exbibyte, 2^60 bytes. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitInformation *exbibyte;

@end

/**
 * Units of fraction.
 */
NS_SWIFT_NAME(MeasurementUnitFraction)
@interface BuzzSentryMeasurementUnitFraction : BuzzSentryMeasurementUnit
SENTRY_NO_INIT

/** Floating point fraction of `1`. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitFraction *ratio;

/** Ratio expressed as a fraction of `100`. `100%` equals a ratio of `1.0`. */
@property (class, readonly, copy) BuzzSentryMeasurementUnitFraction *percent;

@end

NS_ASSUME_NONNULL_END
