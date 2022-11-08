#import "BuzzSentrySerialization.h"
#import "BuzzSentryAppState.h"
#import "BuzzSentryEnvelope.h"
#import "BuzzSentryEnvelopeItemType.h"
#import "BuzzSentryError.h"
#import "BuzzSentryId.h"
#import "BuzzSentryLevelMapper.h"
#import "BuzzSentryLog.h"
#import "BuzzSentrySDKInfo.h"
#import "BuzzSentrySession.h"
#import "BuzzSentryTraceContext.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentrySerialization

+ (NSData *_Nullable)dataWithJSONObject:(NSDictionary *)dictionary
                                  error:(NSError *_Nullable *_Nullable)error
{
    NSData *data = nil;
    if ([NSJSONSerialization isValidJSONObject:dictionary] != NO) {
        data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:error];
    } else {
        SENTRY_LOG_ERROR(@"Invalid JSON.");
        if (error) {
            *error = NSErrorFromBuzzSentryError(
                kBuzzSentryErrorJsonConversionError, @"Event cannot be converted to JSON");
        }
    }

    return data;
}

+ (NSData *_Nullable)dataWithEnvelope:(BuzzSentryEnvelope *)envelope
                                error:(NSError *_Nullable *_Nullable)error
{

    NSMutableData *envelopeData = [[NSMutableData alloc] init];
    NSMutableDictionary *serializedData = [NSMutableDictionary new];
    if (nil != envelope.header.eventId) {
        [serializedData setValue:[envelope.header.eventId buzzSentryIdString] forKey:@"event_id"];
    }

    BuzzSentrySDKInfo *sdkInfo = envelope.header.sdkInfo;
    if (nil != sdkInfo) {
        [serializedData addEntriesFromDictionary:[sdkInfo serialize]];
    }

    BuzzSentryTraceContext *traceContext = envelope.header.traceContext;
    if (traceContext != nil) {
        [serializedData setValue:[traceContext serialize] forKey:@"trace"];
    }

    NSData *header = [BuzzSentrySerialization dataWithJSONObject:serializedData error:error];
    if (nil == header) {
        SENTRY_LOG_ERROR(@"Envelope header cannot be converted to JSON.");
        if (error) {
            *error = NSErrorFromBuzzSentryError(
                kBuzzSentryErrorJsonConversionError, @"Envelope header cannot be converted to JSON");
        }
        return nil;
    }
    [envelopeData appendData:header];

    for (int i = 0; i < envelope.items.count; ++i) {
        [envelopeData appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSMutableDictionary *serializedItemHeaderData = [NSMutableDictionary new];
        if (nil != envelope.items[i].header) {
            if (nil != envelope.items[i].header.type) {
                [serializedItemHeaderData setValue:envelope.items[i].header.type forKey:@"type"];
            }

            NSString *filename = envelope.items[i].header.filename;
            if (nil != filename) {
                [serializedItemHeaderData setValue:filename forKey:@"filename"];
            }

            NSString *contentType = envelope.items[i].header.contentType;
            if (nil != contentType) {
                [serializedItemHeaderData setValue:contentType forKey:@"content_type"];
            }

            [serializedItemHeaderData
                setValue:[NSNumber numberWithUnsignedInteger:envelope.items[i].header.length]
                  forKey:@"length"];
        }
        NSData *itemHeader = [BuzzSentrySerialization dataWithJSONObject:serializedItemHeaderData
                                                               error:error];
        if (nil == itemHeader) {
            SENTRY_LOG_ERROR(@"Envelope item header cannot be converted to JSON.");
            if (error) {
                *error = NSErrorFromBuzzSentryError(kBuzzSentryErrorJsonConversionError,
                    @"Envelope item header cannot be converted to JSON");
            }
            return nil;
        }
        [envelopeData appendData:itemHeader];
        [envelopeData appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [envelopeData appendData:envelope.items[i].data];
    }

    return envelopeData;
}

+ (NSString *)baggageEncodedDictionary:(NSDictionary *)dictionary
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:dictionary.count];

    NSMutableCharacterSet *allowedSet = [NSCharacterSet.alphanumericCharacterSet mutableCopy];
    [allowedSet addCharactersInString:@"-_."];
    NSInteger currentSize = 0;

    for (id key in dictionary.allKeys) {
        id value = dictionary[key];
        NSString *keyDescription =
            [[key description] stringByAddingPercentEncodingWithAllowedCharacters:allowedSet];
        NSString *valueDescription =
            [[value description] stringByAddingPercentEncodingWithAllowedCharacters:allowedSet];

        NSString *item = [NSString stringWithFormat:@"%@=%@", keyDescription, valueDescription];
        if (item.length + currentSize <= SENTRY_BAGGAGE_MAX_SIZE) {
            currentSize += item.length
                + 1; // +1 is to account for the comma that will be added for each extra itemapp
            [items addObject:item];
        }
    }

    return [[items sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }] componentsJoinedByString:@","];
}

+ (NSDictionary<NSString *, NSString *> *)decodeBaggage:(NSString *)baggage
{
    if (baggage == nil || baggage.length == 0) {
        return @{};
    }

    NSMutableDictionary *decoded = [[NSMutableDictionary alloc] init];

    NSArray<NSString *> *properties = [baggage componentsSeparatedByString:@","];

    for (NSString *property in properties) {
        NSArray<NSString *> *parts = [property componentsSeparatedByString:@"="];
        if (parts.count != 2) {
            continue;
        }
        NSString *key = parts[0];
        NSString *value = [parts[1] stringByRemovingPercentEncoding];
        decoded[key] = value;
    }

    return decoded.copy;
}

+ (BuzzSentryEnvelope *_Nullable)envelopeWithData:(NSData *)data
{
    BuzzSentryEnvelopeHeader *envelopeHeader = nil;
    const unsigned char *bytes = [data bytes];
    int envelopeHeaderIndex = 0;

    for (int i = 0; i < data.length; ++i) {
        if (bytes[i] == '\n') {
            envelopeHeaderIndex = i;
            // Envelope header end
            NSData *headerData = [NSData dataWithBytes:bytes length:i];
#ifdef DEBUG
            NSString *headerString = [[NSString alloc] initWithData:headerData
                                                           encoding:NSUTF8StringEncoding];
            SENTRY_LOG_DEBUG(@"Header %@", headerString);
#endif
            NSError *error = nil;
            NSDictionary *headerDictionary = [NSJSONSerialization JSONObjectWithData:headerData
                                                                             options:0
                                                                               error:&error];
            if (nil != error) {
                SENTRY_LOG_ERROR(@"Failed to parse envelope header %@", error);
            } else {
                BuzzSentryId *eventId = nil;
                NSString *eventIdAsString = headerDictionary[@"event_id"];
                if (nil != eventIdAsString) {
                    eventId = [[BuzzSentryId alloc] initWithUUIDString:eventIdAsString];
                }

                BuzzSentrySDKInfo *sdkInfo = nil;
                if (nil != headerDictionary[@"sdk"]) {
                    sdkInfo = [[BuzzSentrySDKInfo alloc] initWithDict:headerDictionary];
                }

                BuzzSentryTraceContext *traceContext = nil;
                if (nil != headerDictionary[@"trace"]) {
                    traceContext =
                        [[BuzzSentryTraceContext alloc] initWithDict:headerDictionary[@"trace"]];
                }

                envelopeHeader = [[BuzzSentryEnvelopeHeader alloc] initWithId:eventId
                                                                  sdkInfo:sdkInfo
                                                             traceContext:traceContext];
            }
            break;
        }
    }

    if (nil == envelopeHeader) {
        SENTRY_LOG_ERROR(@"Invalid envelope. No header found.");
        return nil;
    }

    NSAssert(envelopeHeaderIndex > 0, @"EnvelopeHeader was parsed, its index is expected.");
    if (envelopeHeaderIndex == 0) {
        NSLog(@"EnvelopeHeader was parsed, its index is expected.");
        return nil;
    }

    // Parse items
    NSInteger itemHeaderStart = envelopeHeaderIndex + 1;

    NSMutableArray<BuzzSentryEnvelopeItem *> *items = [NSMutableArray new];
    NSUInteger endOfEnvelope = data.length - 1;
    for (NSInteger i = itemHeaderStart; i <= endOfEnvelope; ++i) {
        if (bytes[i] == '\n' || i == endOfEnvelope) {
            if (endOfEnvelope == i) {
                i++; // 0 byte attachment
            }

            NSData *itemHeaderData =
                [data subdataWithRange:NSMakeRange(itemHeaderStart, i - itemHeaderStart)];
#ifdef DEBUG
            NSString *itemHeaderString = [[NSString alloc] initWithData:itemHeaderData
                                                               encoding:NSUTF8StringEncoding];
            [BuzzSentryLog
                logWithMessage:[NSString stringWithFormat:@"Item Header %@", itemHeaderString]
                      andLevel:kBuzzSentryLevelDebug];
#endif
            NSError *error = nil;
            NSDictionary *headerDictionary = [NSJSONSerialization JSONObjectWithData:itemHeaderData
                                                                             options:0
                                                                               error:&error];
            if (nil != error) {
                [BuzzSentryLog
                    logWithMessage:[NSString
                                       stringWithFormat:@"Failed to parse envelope item header %@",
                                       error]
                          andLevel:kBuzzSentryLevelError];
                return nil;
            }
            NSString *_Nullable type = [headerDictionary valueForKey:@"type"];
            if (nil == type) {
                [BuzzSentryLog
                    logWithMessage:[NSString stringWithFormat:@"Envelope item type is required."]
                          andLevel:kBuzzSentryLevelError];
                break;
            }
            NSNumber *bodyLengthNumber = [headerDictionary valueForKey:@"length"];
            NSUInteger bodyLength = [bodyLengthNumber unsignedIntegerValue];
            if (endOfEnvelope == i && bodyLength != 0) {
                [BuzzSentryLog
                    logWithMessage:[NSString
                                       stringWithFormat:@"Envelope item has no data but header "
                                                        @"indicates it's length is %d.",
                                       (int)bodyLength]
                          andLevel:kBuzzSentryLevelError];
                break;
            }

            NSString *_Nullable filename = [headerDictionary valueForKey:@"filename"];
            NSString *_Nullable contentType = [headerDictionary valueForKey:@"content_type"];

            BuzzSentryEnvelopeItemHeader *itemHeader;
            if (nil != filename && nil != contentType) {
                itemHeader = [[BuzzSentryEnvelopeItemHeader alloc] initWithType:type
                                                                     length:bodyLength
                                                                  filenname:filename
                                                                contentType:contentType];
            } else {
                itemHeader = [[BuzzSentryEnvelopeItemHeader alloc] initWithType:type length:bodyLength];
            }

            NSData *itemBody = [data subdataWithRange:NSMakeRange(i + 1, bodyLength)];
#ifdef DEBUG
            if ([BuzzSentryEnvelopeItemTypeEvent isEqual:type] ||
                [BuzzSentryEnvelopeItemTypeSession isEqual:type]) {
                NSString *event = [[NSString alloc] initWithData:itemBody
                                                        encoding:NSUTF8StringEncoding];
                SENTRY_LOG_DEBUG(@"Event %@", event);
            }
#endif
            BuzzSentryEnvelopeItem *envelopeItem = [[BuzzSentryEnvelopeItem alloc] initWithHeader:itemHeader
                                                                                     data:itemBody];
            [items addObject:envelopeItem];
            i = itemHeaderStart = i + 1 + [bodyLengthNumber integerValue];
        }
    }

    if (items.count == 0) {
        SENTRY_LOG_ERROR(@"Envelope has no items.");
        return nil;
    }

    BuzzSentryEnvelope *envelope = [[BuzzSentryEnvelope alloc] initWithHeader:envelopeHeader items:items];
    return envelope;
}

+ (NSData *_Nullable)dataWithSession:(BuzzSentrySession *)session
                               error:(NSError *_Nullable *_Nullable)error
{
    return [self dataWithJSONObject:[session serialize] error:error];
}

+ (BuzzSentrySession *_Nullable)sessionWithData:(NSData *)sessionData
{
    NSError *error = nil;
    NSDictionary *sessionDictionary = [NSJSONSerialization JSONObjectWithData:sessionData
                                                                      options:0
                                                                        error:&error];
    if (nil != error) {
        [BuzzSentryLog
            logWithMessage:[NSString
                               stringWithFormat:@"Failed to deserialize session data %@", error]
                  andLevel:kBuzzSentryLevelError];
        return nil;
    }
    BuzzSentrySession *session = [[BuzzSentrySession alloc] initWithJSONObject:sessionDictionary];

    if (nil == session) {
        SENTRY_LOG_ERROR(@"Failed to initialize session from dictionary. Dropping it.");
        return nil;
    }

    if (nil == session.releaseName || [session.releaseName isEqualToString:@""]) {
        [BuzzSentryLog
            logWithMessage:@"Deserialized session doesn't contain a release name. Dropping it."
                  andLevel:kBuzzSentryLevelError];
        return nil;
    }

    return session;
}

+ (BuzzSentryAppState *_Nullable)appStateWithData:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *appSateDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:&error];
    if (nil != error) {
        [BuzzSentryLog
            logWithMessage:[NSString
                               stringWithFormat:@"Failed to deserialize app state data %@", error]
                  andLevel:kBuzzSentryLevelError];
        return nil;
    }

    return [[BuzzSentryAppState alloc] initWithJSONObject:appSateDictionary];
}

+ (BuzzSentryLevel)levelFromData:(NSData *)eventEnvelopeItemData
{
    NSError *error = nil;
    NSDictionary *eventDictionary = [NSJSONSerialization JSONObjectWithData:eventEnvelopeItemData
                                                                    options:0
                                                                      error:&error];
    if (nil != error) {
        [BuzzSentryLog
            logWithMessage:
                [NSString
                    stringWithFormat:@"Failed to retrieve event level from envelope item data: %@",
                    error]
                  andLevel:kBuzzSentryLevelError];
        return kBuzzSentryLevelError;
    }

    return sentryLevelForString(eventDictionary[@"level"]);
}

@end

NS_ASSUME_NONNULL_END
