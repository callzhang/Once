//
//  EWUIUtil.h
//  EarlyWorm
//
//  Created by shenslu on 13-8-3.
//  Copyright (c) 2013年 Shens. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "EWUtil.h"
#import "JGProgressHUD.h"
// 基本界面常量宏
#define kTabBarHeight           49

// 基本界面变量宏
#define EWScreenWidth           [EWUIUtil screenWidth]
#define EWScreenHeight          [EWUIUtil screenHeight]

#define EWMainWidth             EWScreenWidth
#define EWMainHeight            (EWScreenHeight - [EWUIUtil statusBarHeight])

#define EWContentWidth          EWScreenWidth
#define EWContentHeight         (EWMainHeight - [EWUIUtil navigationBarHeight])

#define kHexEdgeTag             246
#define kHexMaskTag             287
#define kHexShadowTag           299

// 基本标准界面常量宏
#define kStandardUITableViewCellHeight     44
#define kAlarmCellHeight        80

@interface EWUIUtil : NSObject
GCD_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(EWUIUtil)
+ (CGFloat)screenWidth;
+ (CGFloat)screenHeight;

+ (CGFloat)navigationBarHeight;

+ (CGFloat)statusBarHeight;

+ (void)OnSystemStatusBarFrameChange;

+ (BOOL)isMultitaskingSupported;

+ (NSString *)toString:(NSDictionary *)dic;

+ (CGFloat)distanceOfRectMid:(CGRect)rect1 toRectMid:(CGRect)rect2;

+ (CGFloat)distanceOfPoint:(CGPoint)point1 toPoint:(CGPoint)point2;

+ (void)addImage:(UIImage *)image toAlertView:(UIAlertView *)alert;

+ (void)applyHexagonSoftMaskForView:(UIView *)view;

+ (void)applyHexagonShadowToView:(UIView *)view;

+ (UIBezierPath *)getHexagonPath;

+ (void)applyShadow:(UIView *)view;

+ (void)applyAlphaGradientForView:(UIView *)view withEndPoints:(NSArray *)locations;

+ (UIImage *)resizeImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

//HUD
@property (nonatomic, strong) NSMutableArray *HUDs;
+ (JGProgressHUD *)showWatingHUB;
+ (JGProgressHUD *)showSuccessHUBWithString:(NSString *)string;
+ (JGProgressHUD *)showFailureHUBWithString:(NSString *)string;
+ (JGProgressHUD *)showWarningHUBWithString:(NSString *)string;
+ (void)dismissHUD;
+ (UIView *)topView;
+ (UIViewController *)topViewController;

//by geng
+ (NSString *)getTimeString:(NSDate *)date;
@end
