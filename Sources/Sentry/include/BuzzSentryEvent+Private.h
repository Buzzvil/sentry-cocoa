#import "BuzzSentryEvent.h"
#import <Foundation/Foundation.h>

@interface
BuzzSentryEvent (Private)

/**
 * This indicates whether this event is a result of a crash.
 */
@property (nonatomic) BOOL isCrashEvent;

@end
