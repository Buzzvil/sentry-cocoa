#import "BuzzSentryNSDataTracker.h"
#import "BuzzSentryByteCountFormatter.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryFileManager.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryLog.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope+Private.h"
#import "BuzzSentrySpanProtocol.h"

const NSString *SENTRY_TRACKING_COUNTER_KEY = @"SENTRY_TRACKING_COUNTER_KEY";

@interface
BuzzSentryNSDataTracker ()

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, strong) NSMutableSet<NSData *> *processingData;

@end

@implementation BuzzSentryNSDataTracker

+ (BuzzSentryNSDataTracker *)sharedInstance
{
    static BuzzSentryNSDataTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.isEnabled = NO;
    }
    return self;
}

- (void)enable
{
    @synchronized(self) {
        self.isEnabled = YES;
    }
}

- (void)disable
{
    @synchronized(self) {
        self.isEnabled = NO;
    }
}

- (BOOL)measureNSData:(NSData *)data
          writeToFile:(NSString *)path
           atomically:(BOOL)useAuxiliaryFile
               method:(BOOL (^)(NSString *, BOOL))method
{
    id<BuzzSentrySpan> span = [self startTrackingWritingNSData:data filePath:path];

    BOOL result = method(path, useAuxiliaryFile);

    if (span != nil) {
        [self finishTrackingNSData:data span:span];
    }
    return result;
}

- (BOOL)measureNSData:(NSData *)data
          writeToFile:(NSString *)path
              options:(NSDataWritingOptions)writeOptionsMask
                error:(NSError **)error
               method:(BOOL (^)(NSString *, NSDataWritingOptions, NSError **))method
{
    id<BuzzSentrySpan> span = [self startTrackingWritingNSData:data filePath:path];

    BOOL result = method(path, writeOptionsMask, error);

    if (span != nil) {
        [self finishTrackingNSData:data span:span];
    }

    return result;
}

- (NSData *)measureNSDataFromFile:(NSString *)path method:(NSData * (^)(NSString *))method
{
    id<BuzzSentrySpan> span = [self startTrackingReadingFilePath:path];

    NSData *result = method(path);

    if (span != nil) {
        [self finishTrackingNSData:result span:span];
    }

    [self endTrackingFile];
    return result;
}

- (NSData *)measureNSDataFromFile:(NSString *)path
                          options:(NSDataReadingOptions)readOptionsMask
                            error:(NSError **)error
                           method:(NSData * (^)(NSString *, NSDataReadingOptions, NSError **))method
{
    id<BuzzSentrySpan> span = [self startTrackingReadingFilePath:path];

    NSData *result = method(path, readOptionsMask, error);

    if (span != nil) {
        [self finishTrackingNSData:result span:span];
    }

    [self endTrackingFile];
    return result;
}

- (NSData *)measureNSDataFromURL:(NSURL *)url
                         options:(NSDataReadingOptions)readOptionsMask
                           error:(NSError **)error
                          method:(NSData * (^)(NSURL *, NSDataReadingOptions, NSError **))method
{

    // We dont track reads from a url that is not a file url
    // because these reads are handled by NSURLSession and
    // BuzzSentryNetworkTracker will create spans in these cases.
    if (![url.scheme isEqualToString:NSURLFileScheme])
        return method(url, readOptionsMask, error);

    id<BuzzSentrySpan> span = [self startTrackingReadingFilePath:url.path];

    NSData *result = method(url, readOptionsMask, error);

    if (span != nil) {
        [self finishTrackingNSData:result span:span];
    }

    [self endTrackingFile];
    return result;
}

- (nullable id<BuzzSentrySpan>)spanForPath:(NSString *)path
                             operation:(NSString *)operation
                                  size:(NSUInteger)size
{
    @synchronized(self) {
        if (!self.isEnabled) {
            return nil;
        }
    }

    if ([self ignoreFile:path]) {
        return nil;
    }

    if ([self ignoreFile:path]) {
        return nil;
    }

    __block id<BuzzSentrySpan> ioSpan;
    [BuzzSentrySDK.currentHub.scope useSpan:^(id<BuzzSentrySpan> _Nullable span) {
        ioSpan = [span startChildWithOperation:operation
                                   description:[self transactionDescriptionForFile:path
                                                                          fileSize:size]];
    }];

    if (ioSpan == nil) {
        SENTRY_LOG_DEBUG(@"No transaction bound to scope. Won't track file IO operation.");
        return nil;
    }

    SENTRY_LOG_DEBUG(
        @"BuzzSentryNSDataTracker automatically started a new span with description: %@, operation: %@",
        ioSpan.description, operation);

    [ioSpan setDataValue:path forKey:@"file.path"];

    return ioSpan;
}

- (nullable id<BuzzSentrySpan>)startTrackingWritingNSData:(NSData *)data filePath:(NSString *)path
{
    return [self spanForPath:path operation:SENTRY_FILE_WRITE_OPERATION size:data.length];
}

- (nullable id<BuzzSentrySpan>)startTrackingReadingFilePath:(NSString *)path
{
    // Some iOS versions nest constructors calls. This counter help us avoid create more than one
    // span for the same operation.
    NSNumber *count =
        [[NSThread currentThread].threadDictionary objectForKey:SENTRY_TRACKING_COUNTER_KEY];
    [[NSThread currentThread].threadDictionary setObject:[NSNumber numberWithInt:count.intValue + 1]
                                                  forKey:SENTRY_TRACKING_COUNTER_KEY];

    if (count)
        return nil;

    return [self spanForPath:path operation:SENTRY_FILE_READ_OPERATION size:0];
}

- (void)endTrackingFile
{
    NSNumber *count =
        [[NSThread currentThread].threadDictionary objectForKey:SENTRY_TRACKING_COUNTER_KEY];
    if (!count)
        return;

    if (count.intValue <= 1) {
        [[NSThread currentThread].threadDictionary removeObjectForKey:SENTRY_TRACKING_COUNTER_KEY];
    } else {
        [[NSThread currentThread].threadDictionary
            setObject:[NSNumber numberWithInt:count.intValue - 1]
               forKey:SENTRY_TRACKING_COUNTER_KEY];
    }
}

- (void)finishTrackingNSData:(NSData *)data span:(id<BuzzSentrySpan>)span
{
    [span setDataValue:[NSNumber numberWithUnsignedInteger:data.length] forKey:@"file.size"];
    [span finish];

    SENTRY_LOG_DEBUG(@"BuzzSentryNSDataTracker automatically finished span %@", span.description);
}

- (BOOL)ignoreFile:(NSString *)path
{
    BuzzSentryFileManager *fileManager = [BuzzSentrySDK.currentHub getClient].fileManager;
    return fileManager.sentryPath != nil && [path hasPrefix:fileManager.sentryPath];
}

- (NSString *)transactionDescriptionForFile:(NSString *)path fileSize:(NSUInteger)size
{
    return size > 0 ? [NSString stringWithFormat:@"%@ (%@)", [path lastPathComponent],
                                [BuzzSentryByteCountFormatter bytesCountDescription:size]]
                    : [NSString stringWithFormat:@"%@", [path lastPathComponent]];
}

@end