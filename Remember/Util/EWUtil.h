//
//  EWUtil.h
//  EarlyWorm
//
//  Created by Lei on 8/19/13.
//  Copyright (c) 2013 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CrashlyticsLogger.h>
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

@interface EWUtil : NSObject
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWUtil)
+ (NSString *)UUID;
+ (void)clearMemory;
/**
 Parse number into dictionary.
 E.g.
 8.30 would translate to: dic<hour: 8, minute: 30>
 */
+ (NSDictionary *)timeFromNumber:(double)number;
+ (double)numberFromTime:(NSDictionary *)dic;
+ (BOOL) isMultitaskingSupported;

//logging
+ (void)initLogging;

@end

@interface NSArray(Extend)
- (NSString *)string;
@end
