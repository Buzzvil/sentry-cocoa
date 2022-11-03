
#import "BuzzSentryCoreDataSwizzling.h"
#import "BuzzSentrySwizzle.h"

@interface
BuzzSentryCoreDataSwizzling ()

@property (nonatomic, strong) id<BuzzSentryCoreDataMiddleware> middleware;

@end

@implementation BuzzSentryCoreDataSwizzling

+ (BuzzSentryCoreDataSwizzling *)sharedInstance
{
    static BuzzSentryCoreDataSwizzling *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (void)startWithMiddleware:(id<BuzzSentryCoreDataMiddleware>)middleware
{
    // We just need to swizzle once, than we can control execution with the middleware.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ [self swizzleCoreData]; });

    self.middleware = middleware;
}

- (void)stop
{
    self.middleware = nil;
}

// BuzzSentrySwizzleInstanceMethod declaration shadows a local variable. The swizzling is working
// fine and we accept this warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"

- (void)swizzleCoreData
{
    SEL fetchSelector = NSSelectorFromString(@"executeFetchRequest:error:");

    BuzzSentrySwizzleInstanceMethod(NSManagedObjectContext.class, fetchSelector,
        SentrySWReturnType(NSArray *),
        SentrySWArguments(NSFetchRequest * originalRequest, NSError * *error), SentrySWReplacement({
            NSArray *result;

            id<BuzzSentryCoreDataMiddleware> middleware
                = BuzzSentryCoreDataSwizzling.sharedInstance.middleware;

            if (middleware) {
                result = [middleware
                    managedObjectContext:self
                     executeFetchRequest:originalRequest
                                   error:error
                             originalImp:^NSArray *(NSFetchRequest *request, NSError **outError) {
                                 return SentrySWCallOriginal(request, outError);
                             }];
            } else {
                result = SentrySWCallOriginal(originalRequest, error);
            }

            return result;
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)fetchSelector);

    SEL saveSelector = NSSelectorFromString(@"save:");
    BuzzSentrySwizzleInstanceMethod(NSManagedObjectContext.class, saveSelector,
        SentrySWReturnType(BOOL), SentrySWArguments(NSError * *error), SentrySWReplacement({
            BOOL result;
            id<BuzzSentryCoreDataMiddleware> middleware
                = BuzzSentryCoreDataSwizzling.sharedInstance.middleware;

            if (middleware) {
                result = [middleware managedObjectContext:self
                                                     save:error
                                              originalImp:^BOOL(NSError **outError) {
                                                  return SentrySWCallOriginal(outError);
                                              }];
            } else {
                result = SentrySWCallOriginal(error);
            }

            return result;
        }),
        BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)saveSelector);
}

#pragma clang diagnostic pop

@end
