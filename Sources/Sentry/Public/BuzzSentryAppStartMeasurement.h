#import "BuzzSentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BuzzSentryAppStartType) {
    BuzzSentryAppStartTypeWarm,
    BuzzSentryAppStartTypeCold,
    BuzzSentryAppStartTypeUnknown,
};

@interface BuzzSentryAppStartMeasurement : NSObject
SENTRY_NO_INIT

/**
 * Initializes BuzzSentryAppStartMeasurement with the given parameters.
 */
- (instancetype)initWithType:(BuzzSentryAppStartType)type
              appStartTimestamp:(NSDate *)appStartTimestamp
                       duration:(NSTimeInterval)duration
           runtimeInitTimestamp:(NSDate *)runtimeInitTimestamp
    didFinishLaunchingTimestamp:(NSDate *)didFinishLaunchingTimestamp
    DEPRECATED_MSG_ATTRIBUTE("Use "
                             "initWithType:appStartTimestamp:duration:mainTimestamp:"
                             "runtimeInitTimestamp:didFinishLaunchingTimestamp instead.");

/**
 * Initializes BuzzSentryAppStartMeasurement with the given parameters.
 */
- (instancetype)initWithType:(BuzzSentryAppStartType)type
                appStartTimestamp:(NSDate *)appStartTimestamp
                         duration:(NSTimeInterval)duration
             runtimeInitTimestamp:(NSDate *)runtimeInitTimestamp
    moduleInitializationTimestamp:(NSDate *)moduleInitializationTimestamp
      didFinishLaunchingTimestamp:(NSDate *)didFinishLaunchingTimestamp;

/**
 * The type of the app start.
 */
@property (readonly, nonatomic, assign) BuzzSentryAppStartType type;

/**
 * How long the app start took. From appStartTimestamp to when the SDK creates the
 * AppStartMeasurement, which is done when the OS posts UIWindowDidBecomeVisibleNotification.
 */
@property (readonly, nonatomic, assign) NSTimeInterval duration;

/**
 * The timestamp when the app started, which is the process start timestamp.
 */
@property (readonly, nonatomic, strong) NSDate *appStartTimestamp;

/**
 * When the runtime was initialized / when BuzzSentryAppStartTracker is added to the Objective-C runtime
 */
@property (readonly, nonatomic, strong) NSDate *runtimeInitTimestamp;

/**
 * When application main function is called.
 */
@property (readonly, nonatomic, strong) NSDate *moduleInitializationTimestamp;

/**
 * When OS posts UIApplicationDidFinishLaunchingNotification.
 */
@property (readonly, nonatomic, strong) NSDate *didFinishLaunchingTimestamp;

@end

NS_ASSUME_NONNULL_END
