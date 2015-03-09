//
//  MBProgressHUD+Notification.m
//  EarlyWorm
//
//  Created by Lei on 3/31/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "UIView+Extend.h"
#import "JGProgressHUD.h"
#import "JGProgressHUDSuccessIndicatorView.h"
#import "JGProgressHUDErrorIndicatorView.h"
#import "JGProgressHUDFadeZoomAnimation.h"

@implementation UIView(HUD)

- (JGProgressHUD *)showNotification:(NSString *)alert WithStyle:(HUDStyle)style audoHide:(float)timeout{
    for (JGProgressHUD *hud in [JGProgressHUD allProgressHUDsInView:self]) {
        [hud dismiss];
    }
    JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        JGProgressHUDFadeZoomAnimation *an = [JGProgressHUDFadeZoomAnimation animation];
        hud.animation = an;
        hud.textLabel.text = alert;
        switch (style) {
            case hudStyleSuccess:
                hud.indicatorView = [JGProgressHUDSuccessIndicatorView new];
                break;
                
            case hudStyleFailed:
                hud.indicatorView = [JGProgressHUDErrorIndicatorView new];
                break;
                
            case hudStyleWarning:
                hud.indicatorView = [JGProgressHUDErrorIndicatorView new];
                break;
                
            default:
                break;
        }
        [hud showInView:self];
        if (timeout > 0) {
            [hud dismissAfterDelay:timeout];
        }

    });
    return hud;
}

- (JGProgressHUD *)showSuccessNotification:(NSString *)alert{
    return [self showNotification:alert WithStyle:hudStyleSuccess audoHide:2];
}

- (JGProgressHUD *)showFailureNotification:(NSString *)alert{
    return [self showNotification:alert WithStyle:hudStyleFailed audoHide:2];
}

- ( JGProgressHUD*)showLoopingWithTimeout:(float)timeout{
    JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    hud.interactionType = JGProgressHUDInteractionTypeBlockTouchesOnHUDView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud showInView:self];
        if (timeout > 0) {
            [hud dismissAfterDelay:timeout];
        }
    });
    
    return hud;
}

- (void)dismissHUD{
    NSArray *huds = [JGProgressHUD allProgressHUDsInView:self];
    for (JGProgressHUD *hud in huds) {
        [hud dismiss];
    }
}

@end


@implementation UIView (Sreenshot)

- (UIImage *)screenshot{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
	
	//DDLogVerbose(@"Window scale: %f", self.window.screen.scale);
    /* iOS 7 */
    BOOL visible = !self.hidden && self.superview;
    CGFloat alpha = self.alpha;
    BOOL animating = self.layer.animationKeys != nil;
    BOOL success = YES;
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]){
        //only works when visible
        if (!animating && alpha == 1 && visible) {
            success = [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
        }else{
            self.alpha = 1;
            success = [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
            self.alpha = alpha;
        }
    }
    if(!success){ /* iOS 6 */
        self.alpha = 1;
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        self.alpha = alpha;
    }
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

@end
