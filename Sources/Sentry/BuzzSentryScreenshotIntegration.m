#import "BuzzSentryScreenshotIntegration.h"
#import "BuzzSentryAttachment.h"
#import "SentryCrashC.h"
#import "BuzzSentryDependencyContainer.h"
#import "BuzzSentryEvent+Private.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentrySDK+Private.h"

#if SENTRY_HAS_UIKIT

void
saveScreenShot(const char *path)
{
    NSString *reportPath = [NSString stringWithUTF8String:path];
    [BuzzSentryDependencyContainer.sharedInstance.screenshot saveScreenShots:reportPath];
}

@implementation BuzzSentryScreenshotIntegration

- (BOOL)installWithOptions:(nonnull BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    BuzzSentryClient *client = [BuzzSentrySDK.currentHub getClient];
    [client addAttachmentProcessor:self];

    sentrycrash_setSaveScreenshots(&saveScreenShot);

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionAttachScreenshot;
}

- (void)uninstall
{
    sentrycrash_setSaveScreenshots(NULL);

    BuzzSentryClient *client = [BuzzSentrySDK.currentHub getClient];
    [client removeAttachmentProcessor:self];
}

- (NSArray<BuzzSentryAttachment *> *)processAttachments:(NSArray<BuzzSentryAttachment *> *)attachments
                                           forEvent:(nonnull BuzzSentryEvent *)event
{

    // We don't take screenshots if there is no exception/error.
    // We dont take screenshots if the event is a crash event.
    if ((event.exceptions == nil && event.error == nil) || event.isCrashEvent) {
        return attachments;
    }

    NSArray *screenshot = [BuzzSentryDependencyContainer.sharedInstance.screenshot appScreenshots];

    NSMutableArray *result =
        [NSMutableArray arrayWithCapacity:attachments.count + screenshot.count];
    [result addObjectsFromArray:attachments];

    for (int i = 0; i < screenshot.count; i++) {
        NSString *name
            = i == 0 ? @"screenshot.png" : [NSString stringWithFormat:@"screenshot-%i.png", i + 1];

        BuzzSentryAttachment *att = [[BuzzSentryAttachment alloc] initWithData:screenshot[i]
                                                              filename:name
                                                           contentType:@"image/png"];
        [result addObject:att];
    }

    return result;
}

@end
#endif
