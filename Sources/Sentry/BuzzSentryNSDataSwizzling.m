#import "BuzzSentryNSDataSwizzling.h"
#import "BuzzSentryNSDataTracker.h"
#import "BuzzSentrySwizzle.h"
#import <BuzzSentryLog.h>
#import <objc/runtime.h>

@implementation BuzzSentryNSDataSwizzling

+ (void)start
{
    [BuzzSentryNSDataTracker.sharedInstance enable];
    [self swizzleNSData];
}

+ (void)stop
{
    [BuzzSentryNSDataTracker.sharedInstance disable];
}

// BuzzSentrySwizzleInstanceMethod declaration shadows a local variable. The swizzling is working
// fine and we accept this warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"
+ (void)swizzleNSData
{
    SEL writeToFileAtomicallySelector = NSSelectorFromString(@"writeToFile:atomically:");
    BuzzSentrySwizzleInstanceMethod(NSData.class, writeToFileAtomicallySelector,
        SentrySWReturnType(BOOL), SentrySWArguments(NSString * path, BOOL useAuxiliaryFile),
        SentrySWReplacement({
            return [BuzzSentryNSDataTracker.sharedInstance
                measureNSData:self
                  writeToFile:path
                   atomically:useAuxiliaryFile
                       method:^BOOL(NSString *_Nonnull filePath, BOOL isAtomically) {
                           return SentrySWCallOriginal(filePath, isAtomically);
                       }];
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)writeToFileAtomicallySelector);

    SEL writeToFileOptionsErrorSelector = NSSelectorFromString(@"writeToFile:options:error:");
    BuzzSentrySwizzleInstanceMethod(NSData.class, writeToFileOptionsErrorSelector,
        SentrySWReturnType(BOOL),
        SentrySWArguments(NSString * path, NSDataWritingOptions writeOptionsMask, NSError * *error),
        SentrySWReplacement({
            return [BuzzSentryNSDataTracker.sharedInstance
                measureNSData:self
                  writeToFile:path
                      options:writeOptionsMask
                        error:error
                       method:^BOOL(
                           NSString *filePath, NSDataWritingOptions options, NSError **outError) {
                           return SentrySWCallOriginal(filePath, options, outError);
                       }];
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)writeToFileOptionsErrorSelector);

    SEL initWithContentOfFileOptionsErrorSelector
        = NSSelectorFromString(@"initWithContentsOfFile:options:error:");
    BuzzSentrySwizzleInstanceMethod(NSData.class, initWithContentOfFileOptionsErrorSelector,
        SentrySWReturnType(NSData *),
        SentrySWArguments(NSString * path, NSDataReadingOptions options, NSError * *error),
        SentrySWReplacement({
            return [BuzzSentryNSDataTracker.sharedInstance
                measureNSDataFromFile:path
                              options:options
                                error:error
                               method:^NSData *(NSString *filePath, NSDataReadingOptions options,
                                   NSError **outError) {
                                   return SentrySWCallOriginal(filePath, options, outError);
                               }];
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses,
        (void *)initWithContentOfFileOptionsErrorSelector);

    SEL initWithContentsOfFileSelector = NSSelectorFromString(@"initWithContentsOfFile:");
    BuzzSentrySwizzleInstanceMethod(NSData.class, initWithContentsOfFileSelector,
        SentrySWReturnType(NSData *), SentrySWArguments(NSString * path), SentrySWReplacement({
            return [BuzzSentryNSDataTracker.sharedInstance
                measureNSDataFromFile:path
                               method:^NSData *(
                                   NSString *filePath) { return SentrySWCallOriginal(filePath); }];
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)initWithContentsOfFileSelector);

    SEL initWithContentsOfURLOptionsErrorSelector
        = NSSelectorFromString(@"initWithContentsOfURL:options:error:");
    BuzzSentrySwizzleInstanceMethod(NSData.class, initWithContentsOfURLOptionsErrorSelector,
        SentrySWReturnType(NSData *),
        SentrySWArguments(NSURL * url, NSDataReadingOptions options, NSError * *error),
        SentrySWReplacement({
            return [BuzzSentryNSDataTracker.sharedInstance
                measureNSDataFromURL:url
                             options:options
                               error:error
                              method:^NSData *(NSURL *fileUrl, NSDataReadingOptions options,
                                  NSError **outError) {
                                  return SentrySWCallOriginal(fileUrl, options, outError);
                              }];
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses,
        (void *)initWithContentsOfURLOptionsErrorSelector);
}
#pragma clang diagnostic pop
@end
