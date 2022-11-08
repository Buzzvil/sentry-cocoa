#import <Foundation/Foundation.h>

@protocol BuzzSentryObjCRuntimeWrapper <NSObject>

- (const char **)copyClassNamesForImage:(const char *)image amount:(unsigned int *)outCount;

- (const char *)class_getImageName:(Class)cls;

@end
