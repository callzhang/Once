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

@interface CRMainViewController ()
@property (nonatomic, strong) NSMutableArray *contacts_recent;
@property (nonatomic, strong) NSMutableArray *contacts_month;
@property (nonatomic, strong) NSMutableArray *contacts_earlier;
@property (nonatomic) BOOL showFullHistory;
@property (nonatomic, strong) CRContactsManager *manager;
@end

@implementation CRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Remember";
    
    _manager = [CRContactsManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserverForName:kAdressbookReady object:nil queue:nil usingBlock:^(NSNotification *note) {
        DDLogInfo(@"AddressBook ready");
        [self loadAddressBook];
    }];
	
	//show history in default
	self.showFullHistory = YES;
	
	//load regardless
	[self loadAddressBook];
}


- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
    //add show history button
	//self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"History" style:UIBarButtonItemStylePlain target:self action:@selector(showHistory:)];
}


- (void)loadAddressBook{
    
    self.contacts_recent = [NSMutableArray new];
    self.contacts_month = [NSMutableArray new];
    self.contacts_earlier = [NSMutableArray new];
    
    NSArray *contacts = _manager.allContacts;
    
    for (RHPerson *contact in contacts) {
        if (!_showFullHistory) {
            if ([contact.created timeIntervalSinceDate:_manager.lastOpenedOld] < 0) {
                continue;
			}else{
				[self.contacts_recent addObject:contact];
			}
        }
        else if (!contact.created) {
            NSDate *lastWeek = [[NSDate date] dateByAddingTimeInterval:-3600*24*30];
            NSError *err;
            [contact setBasicValue:(__bridge CFTypeRef)lastWeek forPropertyID:kABPersonCreationDateProperty error:&err];
            if (err) {
                NSLog(@"Error in saving created: %@", err);
            }
            [self.contacts_earlier addObject:contact];
        }
        else if ([[NSDate date] timeIntervalSinceDate:contact.created] < 3600*24*7) {
            [self.contacts_recent addObject:contact];
            
        }
        else if ([[NSDate date] timeIntervalSinceDate:contact.created] < 3600*24*30) {
            [self.contacts_month addObject:contact];
            
        }
        else{
            [self.contacts_earlier addObject:contact];
        }
    }
    //reload table
    [self.tableView reloadData];
    
}


#pragma mark - UI
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)showHistory:(id)sender{
    self.showFullHistory = !self.showFullHistory;
    [self loadAddressBook];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    // 1 week, 1 month, 3 months, 1 year, 1yr+
    return self.showFullHistory?3:1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            //week
            return self.contacts_recent.count;
            
        case 1:
            return self.contacts_month.count;
            
        case 2:
            return self.contacts_earlier.count;
            
        default:
            break;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainViewCellIdentifier"];
    
    RHPerson *contact;
    switch (indexPath.section) {
        case 0:
            //week
            contact = self.contacts_recent[indexPath.row];
            break;
        case 1:
            contact = self.contacts_month[indexPath.row];
            break;
        case 2:
            contact = self.contacts_earlier[indexPath.row];
            break;
        default:
            return cell;
    }
    
    cell.textLabel.text = contact.compositeName ?: [NSString stringWithFormat:@"%@", contact.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Created on %@", contact.created.date2dayString];
	cell.imageView.image = contact.thumbnail ?: [UIImage imageNamed:@"profileImage"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	[cell.imageView rounden];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *header;
    switch (section) {
        case 0:
            header = @"Recent week";
            break;
            
            
        case 1:
            header = @"Recent month";
            break;
            
        case 2:
            header = @"Earlier";
            break;
            
        default:
            break;
    }
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	RHPerson *contact;
	switch (indexPath.section) {
		case 0:
			contact = self.contacts_recent[indexPath.row];
			break;
		case 1:
			contact = self.contacts_month[indexPath.row];
			break;
		case 2:
			contact = self.contacts_earlier[indexPath.row];
			break;
		default:
			return;
	}
	ABRecordRef personRef = contact.recordRef;
	if (personRef) {
		ABPersonViewController *picker = [[ABPersonViewController alloc] init];
		picker.personViewDelegate = self;
		picker.displayedPerson = personRef;
		// Allow users to edit the person’s information
		picker.allowsEditing = YES;
		[self.navigationController pushViewController:picker animated:YES];
	}
}

- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
	return NO;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
