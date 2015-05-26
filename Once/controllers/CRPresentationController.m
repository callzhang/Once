//
//  CRPresentationController.m
//  Once
//
//  Created by Lei Zhang on 5/25/15.
//  Copyright (c) 2015 Lee. All rights reserved.
//

#import "CRPresentationController.h"
@interface CRPresentationController()
@property (nonatomic, strong) UIView *dimming;
@end

@implementation CRPresentationController
- (void)presentationTransitionWillBegin{
    [super presentationTransitionWillBegin];
    //create dimming view
    CGFloat h = MAX(self.containerView.frame.size.height, self.containerView.frame.size.width);
    CGRect frame = CGRectMake(0, 0, h, h);
    UIView *dim = [[UIView alloc] initWithFrame:frame];
    dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.dimming = dim;
    dim.alpha  = 0;
    [self.containerView insertSubview:self.dimming atIndex:0];
    //animate
    id <UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        dim.alpha = 1;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //
    }];
}

- (void)presentationTransitionDidEnd:(BOOL)completed{
    if (!completed) {
        [self.dimming removeFromSuperview];
    }
}

- (void)dismissalTransitionWillBegin{
    id <UIViewControllerTransitionCoordinator> transitionCoordinator = self.presentingViewController.transitionCoordinator;
    [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.dimming.alpha = 0;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.dimming removeFromSuperview];
    }];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed{
    if (!completed) {
        self.dimming.alpha = 1;
    }
}
@end
