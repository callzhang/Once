//
//  MBProgressHUD+Notification.h
//  EarlyWorm
//
//  Created by Lei on 3/31/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

@import UIKit;

typedef enum{
    hudStyleSuccess,
    hudStyleFailed,
    hudStyleWarning,
    HUDStyleInfo
}HUDStyle;
@class JGProgressHUD;
@interface UIView(HUD)

- (JGProgressHUD *)showNotification:(NSString *)alert WithStyle:(HUDStyle)style audoHide:(float)timeout;
- (JGProgressHUD *)showSuccessNotification:(NSString *)alert;
- (JGProgressHUD *)showFailureNotification:(NSString *)alert;
- (JGProgressHUD *)showLoopingWithTimeout:(float)timeout;
- (void)dismissHUD;
@end

@interface UIView (Sreenshot)
- (UIImage *)screenshot;
@end