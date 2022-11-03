#import "BuzzSentryTraceContext.h"
#import "BuzzSentryBaggage.h"
#import "BuzzSentryDsn.h"
#import "SentryLog.h"
#import "BuzzSentryOptions+Private.h"
#import "SentryScope+Private.h"
#import "SentrySerialization.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTransactionContext.h"
#import "BuzzSentryUser.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryTraceContext

- (instancetype)initWithTraceId:(SentryId *)traceId
                      publicKey:(NSString *)publicKey
                    releaseName:(nullable NSString *)releaseName
                    environment:(nullable NSString *)environment
                    transaction:(nullable NSString *)transaction
                    userSegment:(nullable NSString *)userSegment
                     sampleRate:(nullable NSString *)sampleRate
{
    if (self = [super init]) {
        _traceId = traceId;
        _publicKey = publicKey;
        _environment = environment;
        _releaseName = releaseName;
        _transaction = transaction;
        _userSegment = userSegment;
        _sampleRate = sampleRate;
    }
    return self;
}

- (nullable instancetype)initWithScope:(SentryScope *)scope options:(BuzzSentryOptions *)options
{
    BuzzSentryTracer *tracer = [BuzzSentryTracer getTracer:scope.span];
    if (tracer == nil) {
        return nil;
    } else {
        return [self initWithTracer:tracer scope:scope options:options];
    }
}

- (nullable instancetype)initWithTracer:(BuzzSentryTracer *)tracer
                                  scope:(nullable SentryScope *)scope
                                options:(BuzzSentryOptions *)options
{
    if (tracer.context.traceId == nil || options.parsedDsn == nil)
        return nil;

    NSString *userSegment;

    if (scope.userObject.segment) {
        userSegment = scope.userObject.segment;
    }

    NSString *sampleRate = nil;
    if ([tracer.context isKindOfClass:[BuzzSentryTransactionContext class]]) {
        sampleRate = [NSString
            stringWithFormat:@"%@", [(BuzzSentryTransactionContext *)tracer.context sampleRate]];
    }

    return [self initWithTraceId:tracer.context.traceId
                       publicKey:options.parsedDsn.url.user
                     releaseName:options.releaseName
                     environment:options.environment
                     transaction:tracer.transactionContext.name
                     userSegment:userSegment
                      sampleRate:sampleRate];
}

- (nullable instancetype)initWithDict:(NSDictionary<NSString *, id> *)dictionary
{
    SentryId *traceId = [[SentryId alloc] initWithUUIDString:dictionary[@"trace_id"]];
    NSString *publicKey = dictionary[@"public_key"];
    if (traceId == nil || publicKey == nil)
        return nil;

    NSString *userSegment;
    if (dictionary[@"user"] != nil) {
        NSDictionary *userInfo = dictionary[@"user"];
        if ([userInfo[@"segment"] isKindOfClass:[NSString class]])
            userSegment = userInfo[@"segment"];
    } else {
        userSegment = dictionary[@"user_segment"];
    }

    return [self initWithTraceId:traceId
                       publicKey:publicKey
                     releaseName:dictionary[@"release"]
                     environment:dictionary[@"environment"]
                     transaction:dictionary[@"transaction"]
                     userSegment:userSegment
                      sampleRate:dictionary[@"sample_rate"]];
}

- (BuzzSentryBaggage *)toBaggage
{
    BuzzSentryBaggage *result = [[BuzzSentryBaggage alloc] initWithTraceId:_traceId
                                                         publicKey:_publicKey
                                                       releaseName:_releaseName
                                                       environment:_environment
                                                       transaction:_transaction
                                                       userSegment:_userSegment
                                                        sampleRate:_sampleRate];
    return result;
}

- (NSDictionary<NSString *, id> *)serialize
{
    NSMutableDictionary *result =
        @{ @"trace_id" : _traceId.sentryIdString, @"public_key" : _publicKey }.mutableCopy;

    if (_releaseName != nil) {
        [result setValue:_releaseName forKey:@"release"];
    }

    if (_environment != nil) {
        [result setValue:_environment forKey:@"environment"];
    }

    if (_transaction != nil) {
        [result setValue:_transaction forKey:@"transaction"];
    }

    if (_userSegment != nil) {
        [result setValue:_userSegment forKey:@"user_segment"];
    }

    if (_sampleRate != nil) {
        [result setValue:_sampleRate forKey:@"sample_rate"];
    }

    return result;
}

@end

NS_ASSUME_NONNULL_END
