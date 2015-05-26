//
//  CRTransitionDelegate.m
//  Once
//
//  Created by Lei Zhang on 5/25/15.
//  Copyright (c) 2015 Lee. All rights reserved.
//

#import "CRTransitionDelegate.h"
#import "CRPresentationController.h"

@implementation CRTransitionDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    UIPresentationController *pc = [[CRPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    return pc;
}
@end
