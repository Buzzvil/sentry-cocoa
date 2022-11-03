#import "ViewController.h"

@import Sentry;

@interface
ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [BuzzSentrySDK configureScope:^(BuzzSentryScope *_Nonnull scope) {
        [scope setEnvironment:@"debug"];
        [scope setTagValue:@"objc" forKey:@"language"];
        [scope setExtraValue:[NSString stringWithFormat:@"%@", self]
                      forKey:@"currentViewController"];
        BuzzSentryUser *user = [[BuzzSentryUser alloc] initWithUserId:@"1"];
        user.email = @"tony@example.com";
        [scope setUser:user];

        NSString *path = [[NSBundle mainBundle] pathForResource:@"Tongariro" ofType:@"jpg"];
        [scope addAttachment:[[BuzzSentryAttachment alloc] initWithPath:path
                                                           filename:@"Tongariro.jpg"
                                                        contentType:@"image/jpeg"]];

        [scope addAttachment:[[BuzzSentryAttachment alloc]
                                 initWithData:[@"hello" dataUsingEncoding:NSUTF8StringEncoding]
                                     filename:@"log.txt"]];
    }];
    // Also works
    BuzzSentryUser *user = [[BuzzSentryUser alloc] initWithUserId:@"1"];
    user.email = @"tony@example.com";
    [BuzzSentrySDK setUser:user];

    // Load an image just for HTTP swizzling
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURL *url = [[NSURL alloc]
        initWithString:@"https://sentry-brand.storage.googleapis.com/sentry-logo-black.png"];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url];
    [task resume];
}

- (IBAction)addBreadcrumb:(id)sender
{
    BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] init];
    crumb.message = @"tapped addBreadcrumb";
    [BuzzSentrySDK addBreadcrumb:crumb];
}

- (IBAction)captureMessage:(id)sender
{
    BuzzSentryId *eventId = [BuzzSentrySDK captureMessage:@"Yeah captured a message"];
    // Returns eventId in case of successful processed event
    // otherwise emptyId
    NSLog(@"%@", eventId);
}

- (IBAction)captureUserFeedback:(id)sender
{
    NSError *error =
        [[NSError alloc] initWithDomain:@"UserFeedbackErrorDomain"
                                   code:0
                               userInfo:@{ NSLocalizedDescriptionKey : @"This never happens." }];
    BuzzSentryId *eventId = [BuzzSentrySDK
          captureError:error
        withScopeBlock:^(BuzzSentryScope *_Nonnull scope) { [scope setLevel:kSentryLevelFatal]; }];

    BuzzSentryUserFeedback *userFeedback = [[BuzzSentryUserFeedback alloc] initWithEventId:eventId];
    userFeedback.comments = @"It broke on iOS-ObjectiveC. I don't know why, but this happens.";
    userFeedback.email = @"john@me.com";
    userFeedback.name = @"John Me";
    [BuzzSentrySDK captureUserFeedback:userFeedback];
}

- (IBAction)captureError:(id)sender
{
    NSError *error =
        [[NSError alloc] initWithDomain:@"SampleErrorDomain"
                                   code:0
                               userInfo:@{ NSLocalizedDescriptionKey : @"Object does not exist" }];
    [BuzzSentrySDK captureError:error
             withScopeBlock:^(BuzzSentryScope *_Nonnull scope) {
                 // Changes in here will only be captured for this event
                 // The scope in this callback is a clone of the current scope
                 // It contains all data but mutations only influence the event
                 // being sent
                 [scope setTagValue:@"value" forKey:@"myTag"];
             }];
}

- (IBAction)captureException:(id)sender
{
    NSException *exception = [[NSException alloc] initWithName:@"My Custom exception"
                                                        reason:@"User clicked the button"
                                                      userInfo:nil];

    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setLevel:kSentryLevelFatal];
    // !!!: By explicity just passing the scope, only the data in this scope object will be added to
    // the event; the global scope (calls to configureScope) will be ignored. If you do that, be
    // careful–a lot of useful info is lost. If you just want to mutate what's in the scope use the
    // callback, see: captureError.
    [BuzzSentrySDK captureException:exception withScope:scope];
}

- (IBAction)captureTransaction:(id)sender
{
    __block id<BuzzSentrySpan> fakeTransaction = [BuzzSentrySDK startTransactionWithName:@"Some Transaction"
                                                                       operation:@"some operation"];

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random_uniform(100) + 400 * NSEC_PER_MSEC)),
        dispatch_get_main_queue(), ^{ [fakeTransaction finish]; });
}

- (IBAction)crash:(id)sender
{
    [BuzzSentrySDK crash];
}

- (IBAction)asyncCrash:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{ [self asyncCrash1]; });
}

- (void)asyncCrash1
{
    dispatch_async(dispatch_get_main_queue(), ^{ [self asyncCrash2]; });
}

- (void)asyncCrash2
{
    dispatch_async(dispatch_get_main_queue(), ^{ [BuzzSentrySDK crash]; });
}

- (IBAction)oomCrash:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger megaByte = 1024 * 1024;
        NSUInteger memoryPageSize = NSPageSize();
        NSUInteger memoryPages = megaByte / memoryPageSize;

        while (1) {
            // Allocate one MB and set one element of each memory page to something.
            volatile char *ptr = malloc(megaByte);
            for (int i = 0; i < memoryPages; i++) {
                ptr[i * memoryPageSize] = 'b';
            }
        }
    });
}

@end
