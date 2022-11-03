#import "SentryDebugImageProvider.h"
#import "SentryCrashDefaultBinaryImageProvider.h"
#import "SentryCrashDynamicLinker.h"
#import "SentryCrashUUIDConversion.h"
#import "BuzzSentryDebugMeta.h"
#import "BuzzSentryFrame.h"
#import "SentryHexAddressFormatter.h"
#import "SentryLog.h"
#import "BuzzSentryStacktrace.h"
#import "SentryThread.h"
#import <Foundation/Foundation.h>

@interface
SentryDebugImageProvider ()

@property (nonatomic, strong) id<SentryCrashBinaryImageProvider> binaryImageProvider;

@end

@implementation SentryDebugImageProvider

- (instancetype)init
{

    SentryCrashDefaultBinaryImageProvider *provider =
        [[SentryCrashDefaultBinaryImageProvider alloc] init];

    self = [self initWithBinaryImageProvider:provider];

    return self;
}

/** Internal constructor for testing */
- (instancetype)initWithBinaryImageProvider:(id<SentryCrashBinaryImageProvider>)binaryImageProvider
{
    if (self = [super init]) {
        self.binaryImageProvider = binaryImageProvider;
    }
    return self;
}

- (NSArray<BuzzSentryDebugMeta *> *)getDebugImagesForThreads:(NSArray<SentryThread *> *)threads
{
    NSMutableSet<NSString *> *imageAdresses = [[NSMutableSet alloc] init];

    for (SentryThread *thread in threads) {
        for (BuzzSentryFrame *frame in thread.stacktrace.frames) {
            if (frame.imageAddress && ![imageAdresses containsObject:frame.imageAddress]) {
                [imageAdresses addObject:frame.imageAddress];
            }
        }
    }

    NSMutableArray<BuzzSentryDebugMeta *> *result = [NSMutableArray new];

    NSArray<BuzzSentryDebugMeta *> *binaryImages = [self getDebugImages];

    for (BuzzSentryDebugMeta *sourceImage in binaryImages) {
        if ([imageAdresses containsObject:sourceImage.imageAddress]) {
            [result addObject:sourceImage];
        }
    }

    return result;
}

- (NSArray<BuzzSentryDebugMeta *> *)getDebugImages
{
    NSMutableArray<BuzzSentryDebugMeta *> *debugMetaArray = [NSMutableArray new];

    NSInteger imageCount = [self.binaryImageProvider getImageCount];
    for (NSInteger i = 0; i < imageCount; i++) {
        SentryCrashBinaryImage image = [self.binaryImageProvider getBinaryImage:i];
        BuzzSentryDebugMeta *debugMeta = [self fillDebugMetaFrom:image];
        [debugMetaArray addObject:debugMeta];
    }

    return debugMetaArray;
}

- (BuzzSentryDebugMeta *)fillDebugMetaFrom:(SentryCrashBinaryImage)image
{
    BuzzSentryDebugMeta *debugMeta = [[BuzzSentryDebugMeta alloc] init];
    debugMeta.uuid = [SentryDebugImageProvider convertUUID:image.uuid];
    debugMeta.type = @"apple";

    if (image.vmAddress > 0) {
        NSNumber *imageVmAddress = [NSNumber numberWithUnsignedLongLong:image.vmAddress];
        debugMeta.imageVmAddress = sentry_formatHexAddress(imageVmAddress);
    }

    NSNumber *imageAddress = [NSNumber numberWithUnsignedLongLong:image.address];
    debugMeta.imageAddress = sentry_formatHexAddress(imageAddress);

    debugMeta.imageSize = @(image.size);

    if (nil != image.name) {
        debugMeta.name = [[NSString alloc] initWithUTF8String:image.name];
    }

    return debugMeta;
}

+ (NSString *_Nullable)convertUUID:(const unsigned char *const)value
{
    if (nil == value) {
        return nil;
    }

    char uuidBuffer[37];
    sentrycrashdl_convertBinaryImageUUID(value, uuidBuffer);
    return [[NSString alloc] initWithCString:uuidBuffer encoding:NSASCIIStringEncoding];
}

@end
