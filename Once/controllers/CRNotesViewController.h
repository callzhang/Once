//
//  CRNotesViewController.h
//  Once
//
//  Created by Lee on 5/5/15.
//  Copyright (c) 2015 Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RHPerson.h"

@interface CRNotesViewController : UIViewController//<UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) RHPerson *person;
@end