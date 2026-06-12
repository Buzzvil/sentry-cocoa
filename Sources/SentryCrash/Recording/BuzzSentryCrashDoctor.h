//
//  BuzzSentryCrashDoctor.h
//  BuzzSentryCrash
//
//  Created by Karl Stenerud on 2012-11-10.
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BuzzSentryCrashDoctor : NSObject

+ (BuzzSentryCrashDoctor *)doctor;

- (NSString *)diagnoseCrash:(NSDictionary *)crashReport;

@end
