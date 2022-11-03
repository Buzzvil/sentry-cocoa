#import "SentryDefines.h"
#import "BuzzSentrySerializable.h"

@class BuzzSentryUser;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BuzzSentrySessionStatus) {
    kBuzzSentrySessionStatusOk = 0,
    kBuzzSentrySessionStatusExited = 1,
    kBuzzSentrySessionStatusCrashed = 2,
    kBuzzSentrySessionStatusAbnormal = 3,
};

/**
 * The SDK uses BuzzSentrySession to inform Sentry about release and project associated project health.
 */
@interface BuzzSentrySession : NSObject <BuzzSentrySerializable, NSCopying>
SENTRY_NO_INIT

- (instancetype)initWithReleaseName:(NSString *)releaseName;

/**
 * Initializes BuzzSentrySession from a JSON object.
 *
 * @param jsonObject The jsonObject containing the session.
 *
 * @return The BuzzSentrySession or nil if the JSONObject contains an error.
 */
- (nullable instancetype)initWithJSONObject:(NSDictionary *)jsonObject;

- (void)endSessionExitedWithTimestamp:(NSDate *)timestamp;
- (void)endSessionCrashedWithTimestamp:(NSDate *)timestamp;
- (void)endSessionAbnormalWithTimestamp:(NSDate *)timestamp;

- (void)incrementErrors;

@property (nonatomic, readonly, strong) NSUUID *sessionId;
@property (nonatomic, readonly, strong) NSDate *started;
@property (nonatomic, readonly) enum BuzzSentrySessionStatus status;
@property (nonatomic, readonly) NSUInteger errors;
@property (nonatomic, readonly) NSUInteger sequence;
@property (nonatomic, readonly, strong) NSString *distinctId;
/**
  We can't use init because it overlaps with NSObject.init
 */
@property (nonatomic, readonly, copy) NSNumber *_Nullable flagInit;
@property (nonatomic, readonly, strong) NSDate *_Nullable timestamp;
@property (nonatomic, readonly, strong) NSNumber *_Nullable duration;

@property (nonatomic, readonly, copy) NSString *_Nullable releaseName;
@property (nonatomic, copy) NSString *_Nullable environment;
@property (nonatomic, copy) BuzzSentryUser *_Nullable user;

- (NSDictionary<NSString *, id> *)serialize;

@end

NS_ASSUME_NONNULL_END