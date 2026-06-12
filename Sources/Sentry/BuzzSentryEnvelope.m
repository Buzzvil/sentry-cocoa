#import "BuzzSentryEnvelope.h"
#import "BuzzSentryAttachment.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClientReport.h"
#import "BuzzSentryEnvelopeItemType.h"
#import "BuzzSentryEvent.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryMessage.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentrySDKInfo.h"
#import "BuzzSentrySerialization.h"
#import "BuzzSentrySession.h"
#import "BuzzSentryTransaction.h"
#import "BuzzSentryUserFeedback.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryEnvelopeHeader

// id can be null if no event in the envelope or attachment related to event
- (instancetype)initWithId:(BuzzSentryId *_Nullable)eventId
{
    self = [self initWithId:eventId traceContext:nil];
    return self;
}

- (instancetype)initWithId:(nullable BuzzSentryId *)eventId
              traceContext:(nullable BuzzSentryTraceContext *)traceContext
{
    BuzzSentrySDKInfo *sdkInfo = [[BuzzSentrySDKInfo alloc] initWithName:BuzzSentryMeta.sdkName
                                                      andVersion:BuzzSentryMeta.versionString];
    self = [self initWithId:eventId sdkInfo:sdkInfo traceContext:traceContext];
    return self;
}

- (instancetype)initWithId:(nullable BuzzSentryId *)eventId
                   sdkInfo:(nullable BuzzSentrySDKInfo *)sdkInfo
              traceContext:(nullable BuzzSentryTraceContext *)traceContext
{
    if (self = [super init]) {
        _eventId = eventId;
        _sdkInfo = sdkInfo;
        _traceContext = traceContext;
    }

    return self;
}

@end

@implementation BuzzSentryEnvelopeItemHeader

- (instancetype)initWithType:(NSString *)type length:(NSUInteger)length
{
    if (self = [super init]) {
        _type = type;
        _length = length;
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type
                      length:(NSUInteger)length
                   filenname:(NSString *)filename
                 contentType:(NSString *)contentType
{
    if (self = [self initWithType:type length:length]) {
        _filename = filename;
        _contentType = contentType;
    }
    return self;
}

@end

@implementation BuzzSentryEnvelopeItem

- (instancetype)initWithHeader:(BuzzSentryEnvelopeItemHeader *)header data:(NSData *)data
{
    if (self = [super init]) {
        _header = header;
        _data = data;
    }
    return self;
}

- (instancetype)initWithEvent:(BuzzSentryEvent *)event
{
    NSError *error;
    NSData *json = [BuzzSentrySerialization dataWithJSONObject:[event serialize] error:&error];

    if (nil != error) {
        // We don't know what caused the serialization to fail.
        BuzzSentryEvent *errorEvent = [[BuzzSentryEvent alloc] initWithLevel:kBuzzSentryLevelWarning];

        // Add some context to the event. We can only set simple properties otherwise we
        // risk that the conversion fails again.
        NSString *message = [NSString
            stringWithFormat:@"JSON conversion error for event with message: '%@'", event.message];

        errorEvent.message = [[BuzzSentryMessage alloc] initWithFormatted:message];
        errorEvent.releaseName = event.releaseName;
        errorEvent.environment = event.environment;
        errorEvent.platform = event.platform;
        errorEvent.timestamp = event.timestamp;

        // We accept the risk that this simple serialization fails. Therefore we ignore the
        // error on purpose.
        json = [BuzzSentrySerialization dataWithJSONObject:[errorEvent serialize] error:nil];
    }

    // event.type can be nil and the server infers error if there's a stack trace, otherwise
    // default. In any case in the envelope type it should be event. Except for transactions
    NSString *envelopeType = [event.type isEqualToString:BuzzSentryEnvelopeItemTypeTransaction]
        ? BuzzSentryEnvelopeItemTypeTransaction
        : BuzzSentryEnvelopeItemTypeEvent;

    return [self initWithHeader:[[BuzzSentryEnvelopeItemHeader alloc] initWithType:envelopeType
                                                                        length:json.length]
                           data:json];
}

- (instancetype)initWithSession:(BuzzSentrySession *)session
{
    NSData *json = [NSJSONSerialization dataWithJSONObject:[session serialize]
                                                   options:0
                                                     // TODO: handle error
                                                     error:nil];
    return [self
        initWithHeader:[[BuzzSentryEnvelopeItemHeader alloc] initWithType:BuzzSentryEnvelopeItemTypeSession
                                                               length:json.length]
                  data:json];
}

- (instancetype)initWithUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:[userFeedback serialize]
                                                   options:0
                                                     error:&error];

    if (nil != error) {
        SENTRY_LOG_ERROR(@"Couldn't serialize user feedback.");
        json = [NSData new];
    }

    return [self initWithHeader:[[BuzzSentryEnvelopeItemHeader alloc]
                                    initWithType:BuzzSentryEnvelopeItemTypeUserFeedback
                                          length:json.length]
                           data:json];
}

- (instancetype)initWithClientReport:(BuzzSentryClientReport *)clientReport
{
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:[clientReport serialize]
                                                   options:0
                                                     error:&error];

    if (nil != error) {
        SENTRY_LOG_ERROR(@"Couldn't serialize client report.");
        json = [NSData new];
    }

    return [self initWithHeader:[[BuzzSentryEnvelopeItemHeader alloc]
                                    initWithType:BuzzSentryEnvelopeItemTypeClientReport
                                          length:json.length]
                           data:json];
}

- (_Nullable instancetype)initWithAttachment:(BuzzSentryAttachment *)attachment
                           maxAttachmentSize:(NSUInteger)maxAttachmentSize
{
    NSData *data = nil;
    if (nil != attachment.data) {
        if (attachment.data.length > maxAttachmentSize) {
            SENTRY_LOG_DEBUG(
                @"Dropping attachment with filename '%@', because the size of the passed data with "
                @"%lu bytes is bigger than the maximum allowed attachment size of %lu bytes.",
                attachment.filename, (unsigned long)attachment.data.length,
                (unsigned long)maxAttachmentSize);
            return nil;
        }

        data = attachment.data;
    } else if (nil != attachment.path) {

        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary<NSFileAttributeKey, id> *attr =
            [fileManager attributesOfItemAtPath:attachment.path error:&error];

        if (nil != error) {
            SENTRY_LOG_ERROR(@"Couldn't check file size of attachment with path: %@. Error: %@",
                attachment.path, error.localizedDescription);

            return nil;
        }

        unsigned long long fileSize = [attr fileSize];

        if (fileSize > maxAttachmentSize) {
            SENTRY_LOG_DEBUG(
                @"Dropping attachment, because the size of the it located at '%@' with %llu bytes "
                @"is bigger than the maximum allowed attachment size of %lu bytes.",
                attachment.path, fileSize, (unsigned long)maxAttachmentSize);
            return nil;
        }

        data = [[NSFileManager defaultManager] contentsAtPath:attachment.path];
    }

    if (nil == data) {
        SENTRY_LOG_ERROR(@"Couldn't init Attachment.");
        return nil;
    }

    BuzzSentryEnvelopeItemHeader *itemHeader =
        [[BuzzSentryEnvelopeItemHeader alloc] initWithType:BuzzSentryEnvelopeItemTypeAttachment
                                                length:data.length
                                             filenname:attachment.filename
                                           contentType:attachment.contentType];

    return [self initWithHeader:itemHeader data:data];
}

@end

@implementation BuzzSentryEnvelope

- (instancetype)initWithSession:(BuzzSentrySession *)session
{
    BuzzSentryEnvelopeItem *item = [[BuzzSentryEnvelopeItem alloc] initWithSession:session];
    return [self initWithHeader:[[BuzzSentryEnvelopeHeader alloc] initWithId:nil] singleItem:item];
}

- (instancetype)initWithSessions:(NSArray<BuzzSentrySession *> *)sessions
{
    NSMutableArray *envelopeItems = [[NSMutableArray alloc] initWithCapacity:sessions.count];
    for (int i = 0; i < sessions.count; ++i) {
        BuzzSentryEnvelopeItem *item =
            [[BuzzSentryEnvelopeItem alloc] initWithSession:[sessions objectAtIndex:i]];
        [envelopeItems addObject:item];
    }
    return [self initWithHeader:[[BuzzSentryEnvelopeHeader alloc] initWithId:nil] items:envelopeItems];
}

- (instancetype)initWithEvent:(BuzzSentryEvent *)event
{
    BuzzSentryEnvelopeItem *item = [[BuzzSentryEnvelopeItem alloc] initWithEvent:event];
    return [self initWithHeader:[[BuzzSentryEnvelopeHeader alloc] initWithId:event.eventId]
                     singleItem:item];
}

- (instancetype)initWithUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    BuzzSentryEnvelopeItem *item = [[BuzzSentryEnvelopeItem alloc] initWithUserFeedback:userFeedback];

    return [self initWithHeader:[[BuzzSentryEnvelopeHeader alloc] initWithId:userFeedback.eventId]
                     singleItem:item];
}

- (instancetype)initWithId:(BuzzSentryId *_Nullable)id singleItem:(BuzzSentryEnvelopeItem *)item
{
    return [self initWithHeader:[[BuzzSentryEnvelopeHeader alloc] initWithId:id] singleItem:item];
}

- (instancetype)initWithId:(BuzzSentryId *_Nullable)id items:(NSArray<BuzzSentryEnvelopeItem *> *)items
{
    return [self initWithHeader:[[BuzzSentryEnvelopeHeader alloc] initWithId:id] items:items];
}

- (instancetype)initWithHeader:(BuzzSentryEnvelopeHeader *)header singleItem:(BuzzSentryEnvelopeItem *)item
{
    return [self initWithHeader:header items:@[ item ]];
}

- (instancetype)initWithHeader:(BuzzSentryEnvelopeHeader *)header
                         items:(NSArray<BuzzSentryEnvelopeItem *> *)items
{
    if (self = [super init]) {
        _header = header;
        _items = items;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
