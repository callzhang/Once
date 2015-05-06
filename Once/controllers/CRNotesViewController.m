//
//  CRNotesViewController.m
//  Once
//
//  Created by Lee on 5/5/15.
//  Copyright (c) 2015 Lee. All rights reserved.
//

#import "CRNotesViewController.h"
#import "Once-Swift.h"

@interface CRNotesViewController (){
	id keyboardShowObserver;
	id keyboardHideObserver;
}
@property (weak, nonatomic) IBOutlet UITextView *notesView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstant;

@end

@implementation CRNotesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	self.notesView.text = self.person.note;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayout:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayout:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source{
//	CustomPresentationController *presentationController = [[CustomPresentationController alloc] init];
//	return presentationController;
//}

- (IBAction)close:(id)sender {
	self.person.note = self.notesView.text;
	[self.person save];
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)updateLayout:(NSNotification *)note{
	NSDictionary *userInfo = note.userInfo;
	double animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	CGRect keyboardEndFrame = [(NSValue *)userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect convertedKeyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.window];
	NSInteger rawAnimationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] << 16;
	UIViewAnimationOptions animationCurve = rawAnimationCurve;
	self.bottomConstant.constant = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 20;
	[UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | animationCurve animations:^{
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		//
	}];
}

@end
