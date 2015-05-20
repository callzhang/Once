//
//  CRMainViewController.m
//  Contacts Reminder
//
//  Created by Lee on 11/9/14.
//  Copyright (c) 2014 Lee. All rights reserved.
//

#import "CRMainViewController.h"
#import "RHPerson.h"
#import "CRContactsManager.h"
#import "NSDate+Extend.h"
#import "ENPersonCell.h"
#import "RHAddressBook.h"
#import "EWUIUtil.h"
#import "NSTimer+BlocksKit.h"
#import "EWUtil.h"
#import "UIActionSheet+BlocksKit.h"
#import "CRNotificationsViewController.h"
#import "BlocksKit+UIKit.h"
#import "CRNotesViewController.h"
#import "NSDate+MTDates.h"
#import "TMAlertController.h"

typedef NS_ENUM(NSInteger, CRContactsViewType){
	CRContactsViewTypeHistory,
	CRContactsViewTypeDuplicated
};

@interface CRMainViewController ()
@property (nonatomic, strong) NSMutableDictionary *contactsMonthly;
@property (nonatomic, strong) NSMutableOrderedSet *orderedMonths;
@property (nonatomic, strong) NSMutableArray *duplicated;
@property (nonatomic, strong) CRContactsManager *manager;
@property (nonatomic, assign) BOOL addressBookChanged;
@property (nonatomic, assign) CRContactsViewType contactsViewType;
@end

@implementation CRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _manager = [CRContactsManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserverForName:kAdressbookReady object:nil queue:nil usingBlock:^(NSNotification *note) {
        [EWUIUtil showWatingHUB];
        DDLogInfo(@"AddressBook ready");
        [self loadData];
        [EWUIUtil dismissHUD];
    }];
	
    //tableview
	//[self.tableView registerClass:[ENPersonCell class] forCellReuseIdentifier:@"personCell"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    //data
    [self loadData];
	self.contactsViewType = CRContactsViewTypeHistory;
	
    //observe application state
//    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//        if (self.addressBookChanged == YES) {
//            self.addressBookChanged = NO;
//            DDLogInfo(@"Application will enter foreground, refresh the view");
//            
//            [self loadData];
//			//[self setMode];
//            
//            //reload table
//            [self.tableView reloadData];
//        }
//    }];
	
    // start observing
    [[NSNotificationCenter defaultCenter] addObserverForName:kCRAddressBookChangeCompleted object:nil queue:nil usingBlock:^(NSNotification *note) {
        DDLogVerbose(@"Addressbook change completed");
		//self.addressBookChanged = YES;
		[self loadData];
		[EWUIUtil dismissHUD];
		[self.tableView reloadData];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAdressbookReady object:nil queue:nil usingBlock:^(NSNotification *note) {
        //self.addressBookChanged = YES;
        [self loadData];
        [EWUIUtil dismissHUD];
        [self.tableView reloadData];
    }];
}


- (void)loadData{
	self.contactsMonthly = [NSMutableDictionary new];
	NSArray *contacts = _manager.allContacts;
	self.duplicated = _manager.duplicatedContacts.mutableCopy;
	self.orderedMonths = [NSMutableOrderedSet new];
    //data array
    for (RHPerson *contact in contacts) {
		NSDate *startOfMonth = contact.created.mt_startOfCurrentMonth;
		NSMutableArray *contactsOfMonth = self.contactsMonthly[startOfMonth] ?: [NSMutableArray array];
		[contactsOfMonth addObject:contact];
		self.contactsMonthly[startOfMonth] = contactsOfMonth;
		[self.orderedMonths addObject:startOfMonth];
    }
	
	[self.orderedMonths sortUsingComparator:^NSComparisonResult(NSDate *obj1, NSDate *obj2) {
		return -[obj1 compare:obj2];
	}];
}

#pragma mark - UI

- (IBAction)showHistory:(id)sender{
	UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:@"More"];
	if (self.contactsViewType != CRContactsViewTypeHistory) {
		[sheet bk_addButtonWithTitle:@"History" handler:^{
			self.contactsViewType = CRContactsViewTypeHistory;
			[self.tableView reloadData];
		}];
	}
	if (self.contactsViewType != CRContactsViewTypeDuplicated) {
		[sheet bk_addButtonWithTitle:@"Duplicated" handler:^{
			self.contactsViewType = CRContactsViewTypeDuplicated;
			[self.tableView reloadData];
		}];
	}
#ifdef DEBUG
    if (!self.presentedViewController) {
        [sheet bk_addButtonWithTitle:@"Local Notifications" handler:^{
            CRNotificationsViewController *VC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CRNotificationsViewController"];
            [self.navigationController pushViewController:VC animated:YES];
        }];
    }
#endif
	[sheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
	[sheet showInView:self.view];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    // 1 week, 1 month, 3 months, 1 year, 1yr+
	switch (_contactsViewType) {
		case CRContactsViewTypeHistory:
			return self.contactsMonthly.count;
		case CRContactsViewTypeDuplicated:
			return 1;
	}
	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UITableViewCell *secionHeader = [tableView dequeueReusableCellWithIdentifier:@"sectionHeader"];
    UILabel *title = (UILabel *)[secionHeader viewWithTag:89];
	switch (_contactsViewType) {
		case CRContactsViewTypeHistory:{
			NSDate *month = _orderedMonths[section];
			title.text = [NSString stringWithFormat:@"%@ %ld", month.mt_stringFromDateWithFullMonth, (long)month.mt_year];
			break;
		}
		case CRContactsViewTypeDuplicated:
			title.text = @"Duplicated";
			break;
		default:
			title.text = @"???";
			break;
	}
    return secionHeader.contentView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch (_contactsViewType) {
		case CRContactsViewTypeHistory:{
			NSDate *month = _orderedMonths[section];
			NSArray *contactsOfMonth = _contactsMonthly[month];
			return contactsOfMonth.count;
		}
			
		case CRContactsViewTypeDuplicated:
			return self.duplicated.count;
	}
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ENPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"personCell"];
	//UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainViewCellIdentifier"];
    RHPerson *contact;
			switch (_contactsViewType) {
				case CRContactsViewTypeHistory:{
					NSDate *month = _orderedMonths[indexPath.section];
					NSArray *contactsOfMonth = _contactsMonthly[month];
					contact = contactsOfMonth[indexPath.row];
					break;
				}
				case CRContactsViewTypeDuplicated:
					contact = self.duplicated[indexPath.row];
					break;
			}
    
    NSString *notes = contact.note;
	BOOL recent = [_manager.recentContacts containsObject:contact];
    
    cell.title.text = contact.compositeName ?: [NSString stringWithFormat:@"%@", contact.name];
    cell.detail.text = notes ?: [NSString stringWithFormat:@"Met on %@", contact.created.date2dayString];
    cell.profile.image = contact.thumbnail ?: [UIImage imageNamed:@"profileImage"];
	//[cell.disclosure addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
	
	
	UIButton *addNotesButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
	if (recent) {
		[addNotesButton setImage:[UIImage imageNamed:@"addBtn2"] forState:UIControlStateNormal];
	} else {
		[addNotesButton setImage:[UIImage imageNamed:@"addBtn"] forState:UIControlStateNormal];
	}
	
	[addNotesButton bk_addEventHandler:^(id sender) {
		
		TMAlertController *alertController = [TMAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Write a note for %@", contact.name] message:@"" preferredStyle:TMAlertControllerStyleTextField];
		
		[alertController addAction:[TMAlertAction actionWithTitle:@"Done" style:TMAlertActionStyleDefault handler:^(TMAlertAction *action) {
			[self dismissViewControllerAnimated:YES completion:nil];
		}]];
		
		alertController.iconStyle = TMAlertControllerIconStyleNote;
		
		[self presentViewController:alertController animated:YES completion:nil];
	} forControlEvents:UIControlEventTouchUpInside];
	cell.accessoryView = addNotesButton;

    return cell;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	if ([cell isKindOfClass:[ENPersonCell class]]) {
		ENPersonCell *personCell = (ENPersonCell *)cell;
		[personCell.profile rounden];
	}else{
		[cell.imageView rounden];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    RHPerson *contact;
	switch (_contactsViewType) {
		case CRContactsViewTypeHistory:{
			NSDate *month = _orderedMonths[indexPath.section];
			NSArray *contactsOfMonth = _contactsMonthly[month];
			contact = contactsOfMonth[indexPath.row];
			break;
		}
		case CRContactsViewTypeDuplicated:
			contact = self.duplicated[indexPath.row];
			break;
	}
    ABRecordRef personRef = contact.recordRef;
    if (personRef) {
        ABPersonViewController *picker = [[ABPersonViewController alloc] init];
        //tell the view controller to user our underlying address book
        [contact.addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
            picker.addressBook = addressBookRef;
        } waitUntilDone:YES];
        picker.personViewDelegate = self;
        picker.displayedPerson = personRef;
        // Allow users to edit the person’s information
        picker.allowsEditing = YES;
        [self.navigationController pushViewController:picker animated:YES];
    }
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
	NSDate *month = _orderedMonths[indexPath.section];
	NSArray *contactsOfMonth = _contactsMonthly[month];
	RHPerson *contact = contactsOfMonth[indexPath.row];
	
	TMAlertController *alertController = [TMAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Write a note for %@", contact.name] message:@"" preferredStyle:TMAlertControllerStyleTextField];
	
	[alertController addAction:[TMAlertAction actionWithTitle:@"Done" style:TMAlertActionStyleDefault handler:^(TMAlertAction *action) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}]];
	
	alertController.iconStyle = TMAlertControllerIconStyleNote;
	
	[self presentViewController:alertController animated:YES completion:nil];

}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RHPerson *contact;
		switch (_contactsViewType) {
			case CRContactsViewTypeHistory:{
				NSDate *month = _orderedMonths[indexPath.section];
				NSMutableArray *contactsOfMonth = _contactsMonthly[month];
				contact = contactsOfMonth[indexPath.row];
				[contactsOfMonth removeObjectAtIndex:indexPath.row];
				break;
			}
			case CRContactsViewTypeDuplicated:
				contact = self.duplicated[indexPath.row];
				[self.duplicated removeObject:contact];
				break;
		}
        //remove from view with animation
		if (_contactsViewType == CRContactsViewTypeDuplicated) {
			[_manager deleteContact:contact];
            [EWUIUtil showWatingHUB];
		}else{
			[_manager removeAllLinkedContact:contact];
		}
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[EWUIUtil dismissHUD];
        });
    }
}


#pragma mark - ABAdressbookViewController delegate
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
	return YES;
}



@end
