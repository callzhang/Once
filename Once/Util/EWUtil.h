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

#ifndef iPad
#define iPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#endif

#ifndef NSFoundationVersionNumber_iOS_7_0
#define NSFoundationVersionNumber_iOS_7_0 1047.20
#endif

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_iOS_8_0 1134.10
#endif

#ifndef iOS7
#define iOS7 (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0)
#endif

#ifndef iOS8
#define iOS8 (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0)
#endif

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


@interface UIView(Extend)
- (void)rounden;
@end

@interface NSArray(Sort)
- (NSArray *)sortedByCreated;
@end



CGFloat ENExpectedLabelHeight(UILabel *label, CGFloat width);