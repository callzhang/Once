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

@interface CRMainViewController ()
@property (nonatomic, strong) NSMutableArray *contacts_recent;
@property (nonatomic, strong) NSMutableArray *contacts_month;
@property (nonatomic, strong) NSMutableArray *contacts_earlier;
@property (nonatomic) BOOL showHistory;
@property (nonatomic, strong) CRContactsManager *manager;
@end

@implementation CRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _manager = [CRContactsManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserverForName:kAdressbookReady object:nil queue:nil usingBlock:^(NSNotification *note) {
        DDLogInfo(@"AddressBook ready");
        [self loadData];
    }];
	
    //tableview
	//[self.tableView registerClass:[ENPersonCell class] forCellReuseIdentifier:@"personCell"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    //data
    [self setMode];
    [self loadData];
    
    //observe application state
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        DDLogInfo(@"Application will enter foreground, refresh the view");
        [self setMode];
        [self loadData];
    }];
}

- (void)setMode{
    
    if ([CRContactsManager sharedManager].recentContacts.count) {
        self.showHistory = NO;
        self.navigationItem.rightBarButtonItem.title = @"History";
    } else {
        self.showHistory = YES;
        self.navigationItem.rightBarButtonItem.title = @"Recent";
    }
}


- (void)loadData{
    
    self.contacts_recent = [NSMutableArray new];
    self.contacts_month = [NSMutableArray new];
    self.contacts_earlier = [NSMutableArray new];
    
    
    if (!_showHistory) {
        self.contacts_recent = _manager.recentContacts.mutableCopy;
    }
    else{
        NSArray *contacts = _manager.allContacts;
        for (RHPerson *contact in contacts) {
            if ([[NSDate date] timeIntervalSinceDate:contact.created] < 3600*24*7) {
                [self.contacts_recent addObject:contact];
                
            }
            else if ([[NSDate date] timeIntervalSinceDate:contact.created] < 3600*24*30) {
                [self.contacts_month addObject:contact];
                
            }
            else{
                [self.contacts_earlier addObject:contact];
            }
        }
    }
    //reload table
    [self.tableView reloadData];
    
}


#pragma mark - UI

- (IBAction)showHistory:(id)sender{
    self.showHistory = !self.showHistory;
    if (_showHistory) {
        self.navigationItem.rightBarButtonItem.title = @"Recent";
    }else{
        self.navigationItem.rightBarButtonItem.title = @"History";
    }
    [self loadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    // 1 week, 1 month, 3 months, 1 year, 1yr+
    return self.showHistory?3:1;
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
    switch (section) {
        case 0:
            if (_showHistory) {
                title.text = @"Recent Week";
            }else{
                title.text = @"Since last view";
            }
            
            break;
        case 1:
            title.text = @"Recent Month";
            break;
        case 2:
            title.text = @"Earlier";
            break;
        default:
            break;
    }
    return secionHeader;
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
	ENPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"personCell"];
	//UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainViewCellIdentifier"];
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
    
    NSString *notes = contact.note;
    
//    cell.textLabel.text = contact.compositeName ?: [NSString stringWithFormat:@"%@", contact.name];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"Met on %@", contact.created.date2dayString];
//	cell.imageView.image = contact.thumbnail ?: [UIImage imageNamed:@"profileImage"];
    
    cell.title.text = contact.compositeName ?: [NSString stringWithFormat:@"%@", contact.name];
    cell.detail.text = notes ?: [NSString stringWithFormat:@"Met on %@", contact.created.date2dayString];
    cell.profile.image = contact.thumbnail ?: [UIImage imageNamed:@"profileImage"];
	[cell.disclosure addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    //
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
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
        //remove from view with animation
        [[CRContactsManager sharedManager] removeContact:contact];
        [self.contacts_recent removeObject:contact];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self loadData];
        });
    }
}


#pragma mark - ABAdressbookViewController delegate
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
	return YES;
}



@end
