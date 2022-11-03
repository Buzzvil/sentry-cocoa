#import "BuzzSentryUserFeedback.h"
#import "BuzzSentryId.h"
#import <Foundation/Foundation.h>

@implementation BuzzSentryUserFeedback

- (instancetype)initWithEventId:(BuzzSentryId *)eventId
{
    if (self = [super init]) {
        _eventId = eventId;
        _email = @"";
        _name = @"";
        _comments = @"";
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serialize
{
    return @{
        @"event_id" : self.eventId.BuzzSentryIdString,
        @"email" : self.email,
        @"name" : self.name,
        @"comments" : self.comments
    };
}

@end
