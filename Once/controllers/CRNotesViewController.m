//
//  CRNotesViewController.m
//  Once
//
//  Created by Lee on 5/5/15.
//  Copyright (c) 2015 Lee. All rights reserved.
//

#import "CRNotesViewController.h"
#import "CRTransitionDelegate.h"
#import "NSDate+Extend.h"
#import "CRPresentationController.h"

#define kNotesPlaceholder   @"Add a note..."

@interface CRNotesViewController ()<UITextViewDelegate, UIViewControllerTransitioningDelegate>{
	id keyboardShowObserver;
	id keyboardHideObserver;
}
@property (weak, nonatomic) IBOutlet UITextView *notesView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstant;
@property (weak, nonatomic) IBOutlet UIImageView *profile;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *met;
@end

@implementation CRNotesViewController
#pragma mark - Lifecycle
- (void)awakeFromNib{
    [super awakeFromNib];
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    self.notesView.text = self.person.note ?: kNotesPlaceholder;
    if (self.person.originalImage) self.profile.image = self.person.originalImage;
    self.met.text = [NSString stringWithFormat:@"Met on %@", self.person.created.date2dayString];
    self.name.text = self.person.name;
    //initial state
    self.profile.layer.cornerRadius = self.profile.bounds.size.height/2;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    //initial state
    //self.profile.layer.cornerRadius = self.profile.bounds.size.height/2;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (size.height > size.width) {
        self.profile.layer.cornerRadius = 40;
    }else{
        self.profile.layer.cornerRadius = 15;
    }
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
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

#pragma mark - TransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source{
	UIPresentationController *pc = [[CRPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
	return pc;
}

#pragma mark - Text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:kNotesPlaceholder]) {
        textView.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if ([textView.text isEqualToString:@""]) {
        textView.text = kNotesPlaceholder;
    }
}

#pragma mark - UI

- (IBAction)close:(id)sender {
	if ([self.notesView.text isEqualToString:@""] || [self.notesView.text isEqualToString:kNotesPlaceholder]) {
		self.person.note = nil;
	} else if(![self.person.note isEqualToString:self.notesView.text]){
        self.person.note = self.notesView.text;
        [self.person save];
	}
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)updateLayout:(NSNotification *)note{
	NSDictionary *userInfo = note.userInfo;
	double animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	CGRect keyboardEndFrame = [(NSValue *)userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect convertedKeyboardEndFrame = [self.view convertRect:keyboardEndFrame fromView:self.view.window];
	NSInteger rawAnimationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] << 16;
	UIViewAnimationOptions animationCurve = rawAnimationCurve;
	self.bottomConstant.constant = MAX(120, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 10);
	[UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | animationCurve animations:^{
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		//
	}];
}

@end
