#import "BuzzSentrySpanId.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const emptyUUIDString = @"0000000000000000";

@interface
BuzzSentrySpanId ()

@property (nonatomic, strong) NSString *value;

@end

@implementation BuzzSentrySpanId

static BuzzSentrySpanId *_empty = nil;

- (instancetype)init
{
    return [self initWithUUID:[NSUUID UUID]];
}

- (instancetype)initWithUUID:(NSUUID *)uuid
{
    return [self initWithValue:[[uuid.UUIDString.lowercaseString
                                   stringByReplacingOccurrencesOfString:@"-"
                                                             withString:@""] substringToIndex:16]];
}

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [super init]) {
        if (value.length != 16)
            return [BuzzSentrySpanId empty];
        value = value.lowercaseString;

        self.value = value;
    }

    return self;
}

- (NSString *)buzzSentrySpanIdString;
{
    return self.value;
}

- (NSString *)description
{
    return [self buzzSentrySpanIdString];
}

- (BOOL)isEqual:(id _Nullable)object
{
    if (object == self) {
        return YES;
    }
    if ([self class] != [object class]) {
        return NO;
    }

    BuzzSentrySpanId *otherBuzzSentryId = (BuzzSentrySpanId *)object;

    return [self.value isEqual:otherBuzzSentryId.value];
}

- (NSUInteger)hash
{
    return [self.value hash];
}

+ (BuzzSentrySpanId *)empty
{
    if (nil == _empty) {
        _empty = [[BuzzSentrySpanId alloc] initWithValue:emptyUUIDString];
    }
    return _empty;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[BuzzSentrySpanId alloc] initWithValue:self.value];
}

@end

NS_ASSUME_NONNULL_END
