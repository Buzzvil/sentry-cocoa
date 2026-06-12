#import "BuzzSentryDebugImageProvider.h"
#import "BuzzSentryCrashDefaultBinaryImageProvider.h"
#import "BuzzSentryCrashDynamicLinker.h"
#import "BuzzSentryCrashUUIDConversion.h"
#import "BuzzSentryDebugMeta.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryHexAddressFormatter.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryThread.h"
#import <Foundation/Foundation.h>

@interface
BuzzSentryDebugImageProvider ()

@property (nonatomic, strong) id<BuzzSentryCrashBinaryImageProvider> binaryImageProvider;

@end

@implementation BuzzSentryDebugImageProvider

- (instancetype)init
{

    BuzzSentryCrashDefaultBinaryImageProvider *provider =
        [[BuzzSentryCrashDefaultBinaryImageProvider alloc] init];

    self = [self initWithBinaryImageProvider:provider];

    return self;
}

/** Internal constructor for testing */
- (instancetype)initWithBinaryImageProvider:(id<BuzzSentryCrashBinaryImageProvider>)binaryImageProvider
{
    if (self = [super init]) {
        self.binaryImageProvider = binaryImageProvider;
    }
    return self;
}

- (NSArray<BuzzSentryDebugMeta *> *)getDebugImagesForThreads:(NSArray<BuzzSentryThread *> *)threads
{
    NSMutableSet<NSString *> *imageAdresses = [[NSMutableSet alloc] init];

    for (BuzzSentryThread *thread in threads) {
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
        BuzzSentryCrashBinaryImage image = [self.binaryImageProvider getBinaryImage:i];
        BuzzSentryDebugMeta *debugMeta = [self fillDebugMetaFrom:image];
        [debugMetaArray addObject:debugMeta];
    }

    return debugMetaArray;
}

- (BuzzSentryDebugMeta *)fillDebugMetaFrom:(BuzzSentryCrashBinaryImage)image
{
    BuzzSentryDebugMeta *debugMeta = [[BuzzSentryDebugMeta alloc] init];
    debugMeta.uuid = [BuzzSentryDebugImageProvider convertUUID:image.uuid];
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
