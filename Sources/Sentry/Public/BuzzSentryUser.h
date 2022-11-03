#import "SentryDefines.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(User)
@interface BuzzSentryUser : NSObject <BuzzSentrySerializable, NSCopying>

/**
 * Optional: Id of the user
 */
@property (atomic, copy) NSString *_Nullable userId;

/**
 * Optional: Email of the user
 */
@property (atomic, copy) NSString *_Nullable email;

/**
 * Optional: Username
 */
@property (atomic, copy) NSString *_Nullable username;

/**
 * Optional: IP Address
 */
@property (atomic, copy) NSString *_Nullable ipAddress;

/**
 * The user segment, for apps that divide users in user segments.
 */
@property (atomic, copy) NSString *_Nullable segment;

/**
 * Optional: Additional data
 */
@property (atomic, strong) NSDictionary<NSString *, id> *_Nullable data;

/**
 * Initializes a BuzzSentryUser with the id
 * @param userId NSString
 * @return BuzzSentryUser
 */
- (instancetype)initWithUserId:(NSString *)userId;

- (instancetype)init;

- (BOOL)isEqual:(id _Nullable)other;

- (BOOL)isEqualToUser:(BuzzSentryUser *)user;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END