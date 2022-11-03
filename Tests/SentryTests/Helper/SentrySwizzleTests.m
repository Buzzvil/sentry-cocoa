#import "BuzzSentrySwizzle.h"
#import <Sentry/BuzzSentry.h>
#import <XCTest/XCTest.h>

#pragma mark - HELPER CLASSES -

@interface SentryTestsLog : NSObject
+ (void)log:(NSString *)string;

+ (void)clear;

+ (BOOL)is:(NSString *)compareString;

+ (NSString *)logString;
@end

@implementation SentryTestsLog

static NSMutableString *_logString = nil;

+ (void)log:(NSString *)string
{
    if (!_logString) {
        _logString = [NSMutableString new];
    }
    [_logString appendString:string];
    NSLog(@"%@", string);
}

+ (void)clear
{
    _logString = [NSMutableString new];
}

+ (BOOL)is:(NSString *)compareString
{
    return [compareString isEqualToString:_logString];
}

+ (NSString *)logString
{
    return _logString;
}

@end

#define ASSERT_LOG_IS(STRING)                                                                      \
    XCTAssertTrue([SentryTestsLog is:STRING], @"LOG IS @\"%@\" INSTEAD", [SentryTestsLog logString])
#define CLEAR_LOG() ([SentryTestsLog clear])
#define SentryTestsLog(STRING) [SentryTestsLog log:STRING]

@interface BuzzSentrySwizzleTestClass_A : NSObject
@end

@implementation BuzzSentrySwizzleTestClass_A
- (int)calc:(int)num
{
    return num;
}

- (BOOL)methodReturningBOOL
{
    return YES;
};
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (void)methodWithArgument:(id)arg
{
};
#pragma GCC diagnostic pop
- (void)methodForAlwaysSwizzling
{
};

- (void)methodForSwizzlingOncePerClass
{
};

- (void)methodForSwizzlingOncePerClassOrSuperClasses
{
};

- (void)methodForSwizzlingWithoutCallOriginal
{
};

- (NSString *)string
{
    return @"ABC";
}

+ (NSNumber *)sumFloat:(float)floatSummand withDouble:(double)doubleSummand
{
    return @(floatSummand + doubleSummand);
}
@end

@interface BuzzSentrySwizzleTestClass_B : BuzzSentrySwizzleTestClass_A
@end

@implementation BuzzSentrySwizzleTestClass_B
@end

@interface BuzzSentrySwizzleTestClass_C : BuzzSentrySwizzleTestClass_B
@end

@implementation BuzzSentrySwizzleTestClass_C

- (void)dealloc
{
    SentryTestsLog(@"C-");
};

- (int)calc:(int)num
{
    return [super calc:num] * 3;
}
@end

@interface BuzzSentrySwizzleTestClass_D : BuzzSentrySwizzleTestClass_C
@end

@implementation BuzzSentrySwizzleTestClass_D
@end

@interface BuzzSentrySwizzleTestClass_D2 : BuzzSentrySwizzleTestClass_C
@end

@implementation BuzzSentrySwizzleTestClass_D2
@end

#pragma mark - HELPER FUNCTIONS -

static void
swizzleVoidMethod(Class classToSwizzle, SEL selector, dispatch_block_t blockBefore,
    BuzzSentrySwizzleMode mode, const void *key)
{
    BuzzSentrySwizzleInstanceMethod(classToSwizzle, selector, SentrySWReturnType(void),
        SentrySWArguments(), SentrySWReplacement({
            blockBefore();
            SentrySWCallOriginal();
        }),
        mode, key);
}

static void
swizzleDealloc(Class classToSwizzle, dispatch_block_t blockBefore)
{
    SEL selector = NSSelectorFromString(@"dealloc");
    swizzleVoidMethod(classToSwizzle, selector, blockBefore, BuzzSentrySwizzleModeAlways, NULL);
}

static void
swizzleNumber(Class classToSwizzle, int (^transformationBlock)(int))
{
    BuzzSentrySwizzleInstanceMethod(classToSwizzle, @selector(calc:), SentrySWReturnType(int),
        SentrySWArguments(int num), SentrySWReplacement({
            int res = SentrySWCallOriginal(num);
            return transformationBlock(res);
        }),
        BuzzSentrySwizzleModeAlways, NULL);
}

@interface BuzzSentrySwizzleTests : XCTestCase

@end

@implementation BuzzSentrySwizzleTests

+ (void)setUp
{
    [self swizzleDeallocs];
    [self swizzleCalc];
}

- (void)setUp
{
    [super setUp];
    CLEAR_LOG();
}

+ (void)swizzleDeallocs
{
    // 1) Swizzling a class that does not implement the method...
    swizzleDealloc([BuzzSentrySwizzleTestClass_D class], ^{ SentryTestsLog(@"d-"); });
    // ...should not break swizzling of its superclass.
    swizzleDealloc([BuzzSentrySwizzleTestClass_C class], ^{ SentryTestsLog(@"c-"); });
    // 2) Swizzling a class that does not implement the method
    // should not affect classes with the same superclass.
    swizzleDealloc([BuzzSentrySwizzleTestClass_D2 class], ^{ SentryTestsLog(@"d2-"); });

    // 3) We should be able to swizzle classes several times...
    swizzleDealloc([BuzzSentrySwizzleTestClass_D class], ^{ SentryTestsLog(@"d'-"); });
    // ...and nothing should be breaked up.
    swizzleDealloc([BuzzSentrySwizzleTestClass_C class], ^{ SentryTestsLog(@"c'-"); });

    // 4) Swizzling a class inherited from NSObject and does not
    // implementing the method.
    swizzleDealloc([BuzzSentrySwizzleTestClass_A class], ^{ SentryTestsLog(@"a"); });
}

- (void)testDeallocSwizzling
{
    @autoreleasepool {
        id object = [BuzzSentrySwizzleTestClass_D new];
        object = nil;
        XCTAssertNil(object);
    }
    ASSERT_LOG_IS(@"d'-d-c'-c-C-a");
}

#pragma mark - Calc: Swizzling

+ (void)swizzleCalc
{

    swizzleNumber([BuzzSentrySwizzleTestClass_C class], ^int(int num) { return num + 17; });

    swizzleNumber([BuzzSentrySwizzleTestClass_D class], ^int(int num) { return num * 11; });
    swizzleNumber([BuzzSentrySwizzleTestClass_C class], ^int(int num) { return num * 5; });
    swizzleNumber([BuzzSentrySwizzleTestClass_D class], ^int(int num) { return num - 20; });

    swizzleNumber([BuzzSentrySwizzleTestClass_A class], ^int(int num) { return num * -1; });
}

- (void)testCalcSwizzling
{
    BuzzSentrySwizzleTestClass_D *object = [BuzzSentrySwizzleTestClass_D new];
    int res = [object calc:2];
    XCTAssertTrue(res == ((2 * (-1) * 3) + 17) * 5 * 11 - 20, @"%d", res);
}

#pragma mark - String Swizzling

- (void)testStringSwizzling
{
    SEL selector = @selector(string);
    BuzzSentrySwizzleTestClass_A *a = [BuzzSentrySwizzleTestClass_A new];

    BuzzSentrySwizzleInstanceMethod([a class], selector, SentrySWReturnType(NSString *),
        SentrySWArguments(), SentrySWReplacement({
            NSString *res = SentrySWCallOriginal();
            return [res stringByAppendingString:@"DEF"];
        }),
        BuzzSentrySwizzleModeAlways, NULL);

    XCTAssertTrue([[a string] isEqualToString:@"ABCDEF"]);
}

#pragma mark - Class Swizzling

- (void)testClassSwizzling
{
    BuzzSentrySwizzleClassMethod([BuzzSentrySwizzleTestClass_B class], @selector(sumFloat:withDouble:),
        SentrySWReturnType(NSNumber *), SentrySWArguments(float floatSummand, double doubleSummand),
        SentrySWReplacement({
            NSNumber *result = SentrySWCallOriginal(floatSummand, doubleSummand);
            return @([result doubleValue] * 2.);
        }));

    XCTAssertEqualObjects(@(2.), [BuzzSentrySwizzleTestClass_A sumFloat:0.5 withDouble:1.5]);
    XCTAssertEqualObjects(@(4.), [BuzzSentrySwizzleTestClass_B sumFloat:0.5 withDouble:1.5]);
    XCTAssertEqualObjects(@(4.), [BuzzSentrySwizzleTestClass_C sumFloat:0.5 withDouble:1.5]);
}

#pragma mark - Test Assertions
#if !defined(NS_BLOCK_ASSERTIONS)

- (void)testThrowsOnSwizzlingNonexistentMethod
{
    SEL selector = NSSelectorFromString(@"nonexistent");
    BuzzSentrySwizzleImpFactoryBlock factoryBlock = ^id(BuzzSentrySwizzleInfo *swizzleInfo) {
        return ^(__unsafe_unretained id self) {
            void (*originalIMP)(__unsafe_unretained id, SEL);
            originalIMP = (__typeof(originalIMP))[swizzleInfo getOriginalImplementation];
            originalIMP(self, selector);
        };
    };
    XCTAssertThrows([BuzzSentrySwizzle swizzleInstanceMethod:selector
                                                 inClass:[BuzzSentrySwizzleTestClass_A class]
                                           newImpFactory:factoryBlock
                                                    mode:BuzzSentrySwizzleModeAlways
                                                     key:NULL]);
}

#endif

#pragma mark - Mode tests

- (void)testAlwaysSwizzlingMode
{
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod(
            [BuzzSentrySwizzleTestClass_A class], @selector(methodForAlwaysSwizzling),
            ^{ SentryTestsLog(@"A"); }, BuzzSentrySwizzleModeAlways, NULL);
        swizzleVoidMethod(
            [BuzzSentrySwizzleTestClass_B class], @selector(methodForAlwaysSwizzling),
            ^{ SentryTestsLog(@"B"); }, BuzzSentrySwizzleModeAlways, NULL);
    }

    BuzzSentrySwizzleTestClass_B *object = [BuzzSentrySwizzleTestClass_B new];
    [object methodForAlwaysSwizzling];
    ASSERT_LOG_IS(@"BBBAAA");
}

- (void)testSwizzleOncePerClassMode
{
    static void *key = &key;
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod(
            [BuzzSentrySwizzleTestClass_A class], @selector(methodForSwizzlingOncePerClass),
            ^{ SentryTestsLog(@"A"); }, BuzzSentrySwizzleModeOncePerClass, key);
        swizzleVoidMethod(
            [BuzzSentrySwizzleTestClass_B class], @selector(methodForSwizzlingOncePerClass),
            ^{ SentryTestsLog(@"B"); }, BuzzSentrySwizzleModeOncePerClass, key);
    }
    BuzzSentrySwizzleTestClass_B *object = [BuzzSentrySwizzleTestClass_B new];
    [object methodForSwizzlingOncePerClass];
    ASSERT_LOG_IS(@"BA");
}

- (void)testSwizzleOncePerClassOrSuperClassesMode
{
    static void *key = &key;
    for (int i = 3; i > 0; --i) {
        swizzleVoidMethod(
            [BuzzSentrySwizzleTestClass_A class],
            @selector(methodForSwizzlingOncePerClassOrSuperClasses), ^{ SentryTestsLog(@"A"); },
            BuzzSentrySwizzleModeOncePerClassAndSuperclasses, key);
        swizzleVoidMethod(
            [BuzzSentrySwizzleTestClass_B class],
            @selector(methodForSwizzlingOncePerClassOrSuperClasses), ^{ SentryTestsLog(@"B"); },
            BuzzSentrySwizzleModeOncePerClassAndSuperclasses, key);
    }
    BuzzSentrySwizzleTestClass_B *object = [BuzzSentrySwizzleTestClass_B new];
    [object methodForSwizzlingOncePerClassOrSuperClasses];
    ASSERT_LOG_IS(@"A");
}

- (void)testSwizzleDontCallOriginalImplementation
{
    SEL selector = @selector(methodForSwizzlingWithoutCallOriginal);
    BuzzSentrySwizzleTestClass_A *a = [BuzzSentrySwizzleTestClass_A new];

    BuzzSentrySwizzleInstanceMethod([a class], selector, SentrySWReturnType(void), SentrySWArguments(),
        SentrySWReplacement({
            return;
            SentrySWCallOriginal();
            // We need to use SentrySWCallOriginal in SentrySWReplacement, otherwise the code does
            // not compile But a wrong logic can prevent it to be called
        }),
        BuzzSentrySwizzleModeAlways, NULL);

    XCTAssertThrows([a methodForSwizzlingWithoutCallOriginal]);
}

@end
