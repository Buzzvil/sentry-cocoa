#import "BuzzSentryViewHierarchyIntegration.h"
#import "BuzzSentryAttachment.h"
#import "SentryCrashC.h"
#import "BuzzSentryDependencyContainer.h"
#import "BuzzSentryEvent+Private.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryViewHierarchy.h"

#if SENTRY_HAS_UIKIT

void
saveViewHierarchy(const char *path)
{
    NSString *reportPath = [NSString stringWithUTF8String:path];
    [BuzzSentryDependencyContainer.sharedInstance.viewHierarchy saveViewHierarchy:reportPath];
}

@implementation BuzzSentryViewHierarchyIntegration

- (BOOL)installWithOptions:(nonnull BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    BuzzSentryClient *client = [BuzzSentrySDK.currentHub getClient];
    [client addAttachmentProcessor:self];

    sentrycrash_setSaveViewHierarchy(&saveViewHierarchy);

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionAttachViewHierarchy;
}

- (void)uninstall
{
    sentrycrash_setSaveViewHierarchy(NULL);

    BuzzSentryClient *client = [BuzzSentrySDK.currentHub getClient];
    [client removeAttachmentProcessor:self];
}

- (NSArray<BuzzSentryAttachment *> *)processAttachments:(NSArray<BuzzSentryAttachment *> *)attachments
                                           forEvent:(nonnull BuzzSentryEvent *)event
{
    // We don't attach the view hierarchy if there is no exception/error.
    // We dont attach the view hierarchy if the event is a crash event.
    if ((event.exceptions == nil && event.error == nil) || event.isCrashEvent) {
        return attachments;
    }

    NSArray *decriptions =
        [BuzzSentryDependencyContainer.sharedInstance.viewHierarchy fetchViewHierarchy];
    NSMutableArray *result =
        [NSMutableArray arrayWithCapacity:attachments.count + decriptions.count];
    [result addObjectsFromArray:attachments];

    [decriptions enumerateObjectsUsingBlock:^(NSString *decription, NSUInteger idx, BOOL *stop) {
        BuzzSentryAttachment *attachment = [[BuzzSentryAttachment alloc]
            initWithData:[decription dataUsingEncoding:NSUTF8StringEncoding]
                filename:[NSString stringWithFormat:@"view-hierarchy-%lu.txt", (unsigned long)idx]
             contentType:@"text/plain"];
        [result addObject:attachment];
    }];

    return result;
}

@end
#endif
