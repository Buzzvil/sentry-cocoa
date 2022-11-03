#import "SentryDefines.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryAppState : NSObject <BuzzSentrySerializable>
SENTRY_NO_INIT

- (instancetype)initWithReleaseName:(NSString *)releaseName
                          osVersion:(NSString *)osVersion
                           vendorId:(NSString *)vendorId
                        isDebugging:(BOOL)isDebugging
                systemBootTimestamp:(NSDate *)systemBootTimestamp;

/**
 * Initializes BuzzSentryAppState from a JSON object.
 *
 * @param jsonObject The jsonObject containing the session.
 *
 * @return The BuzzSentrySession or nil if the JSONObject contains an error.
 */
- (nullable instancetype)initWithJSONObject:(NSDictionary *)jsonObject;

@property (readonly, nonatomic, copy) NSString *releaseName;

@property (readonly, nonatomic, copy) NSString *osVersion;

@property (readonly, nonatomic, copy) NSString *vendorId;

@property (readonly, nonatomic, assign) BOOL isDebugging;

/**
 * The boot time of the system rounded down to seconds. As the precision of the serialization is
 * only milliseconds and a precision of seconds is enough we round down to seconds. With this we
 * avoid getting different dates before and after serialization.
 */
@property (readonly, nonatomic, copy) NSDate *systemBootTimestamp;

@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, assign) BOOL wasTerminated;

@property (nonatomic, assign) BOOL isANROngoing;

@end

NS_ASSUME_NONNULL_END
