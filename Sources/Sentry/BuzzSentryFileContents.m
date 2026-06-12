#import "BuzzSentryFileContents.h"

@interface
BuzzSentryFileContents ()

@end

@implementation BuzzSentryFileContents

- (instancetype)initWithPath:(NSString *)path andContents:(NSData *)contents
{
    if (self = [super init]) {
        _path = path;
        _contents = contents;
    }
    return self;
}

@end
