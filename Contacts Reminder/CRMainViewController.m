//
//  CRMainViewController.m
//  Contacts Reminder
//
//  Created by Lee on 11/9/14.
//  Copyright (c) 2014 Lee. All rights reserved.
//

#import "CRMainViewController.h"
#import "APAddressBook.h"
#import "APContact.h"
#import "NSDate+Extend.h"
@import AddressBook;

NSString *const kLastChecked = @"last_checked";

@interface CRMainViewController ()
@property APAddressBook *addressbook;
@property (nonatomic, strong) NSMutableArray *contacts_week;
@property (nonatomic, strong) NSMutableArray *contacts_month;
@property (nonatomic, strong) NSMutableArray *contacts_3months;
@property (nonatomic, strong) NSMutableArray *contacts_year;
@property (nonatomic, strong) NSMutableArray *contacts_older;
@property BOOL showFullHistory;
@property NSDate *lastChecked;
@end

@implementation CRMainViewController
@synthesize lastChecked = _lastChecked;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // load addressbook
    _addressbook = [[APAddressBook alloc] init];
    
    //check addressbook access
    switch([APAddressBook access])
    {
        case APAddressBookAccessUnknown:
            NSLog(@"Application didn't request address book access yet");
            [self requestForAddressBook];
            break;
            
        case APAddressBookAccessGranted:
            NSLog(@"Access granted");
            [self loadAddressBook];
            break;
            
        case APAddressBookAccessDenied:
            NSLog(@"Access denied or restricted by privacy settings");
            [self requestForAddressBook];
            break;
    }
    
    // start observing
    [_addressbook startObserveChangesWithCallback:^
    {
        NSLog(@"Address book changed!");
        [self loadAddressBook];
    }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    
    // stop observing
    [_addressbook stopObserveChanges];
}

#pragma mark - Address Book TOOLS
- (void)requestForAddressBook{
    CFErrorRef myError = NULL;
    ABAddressBookRef myAddressBook = ABAddressBookCreateWithOptions(NULL, &myError);
    ABAddressBookRequestAccessWithCompletion(myAddressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            _addressbook = [[APAddressBook alloc] init];
            [self loadAddressBook];
        } else {
            // Handle the case of being denied access and/or the error.
            NSLog(@"Failed to get addressbook: %@", error);
        }
        CFRelease(myAddressBook);
    });
}

- (void)loadAddressBook{
    NSDate *lastCheckedTime = self.lastChecked;
    __block CRMainViewController *weakSelf = self;
    if (_showFullHistory) {
        _addressbook.filterBlock = nil;
        [_addressbook loadContacts:^(NSArray *contacts, NSError *error) {
            if (error) {
                NSLog(@"Failed loading address book!");
            }else{
                for (APContact *contact in contacts) {
                    if ([[NSDate date] timeIntervalSinceDate:contact.creationDate] < 3600*24*7) {
                        [weakSelf.contacts_week addObject:contact];
                        
                    }else if ([[NSDate date] timeIntervalSinceDate:contact.creationDate] < 3600*24*30) {
                        [weakSelf.contacts_month addObject:contact];
                        
                    }else if ([[NSDate date] timeIntervalSinceDate:contact.creationDate] < 3600*24*90) {
                        [weakSelf.contacts_3months addObject:contact];
                        
                    }else if ([[NSDate date] timeIntervalSinceDate:contact.creationDate] < 3600*24*365) {
                        [weakSelf.contacts_year addObject:contact];
                        
                    }else{
                        [weakSelf.contacts_older addObject:contact];
                    }
                }
            }
            
            //reload table
            [self.tableView reloadData];
        }];
    }else{
        _addressbook.filterBlock = ^BOOL(APContact *contact)
        {
            return  [contact.creationDate timeIntervalSinceDate:weakSelf.lastChecked] > 0;
            
        };
        
        [_addressbook loadContacts:^(NSArray *contacts, NSError *error) {
            if (error) {
                NSLog(@"Failed loading address book!");
            }else{
                _contacts_week = contacts.mutableCopy;
            }
            
            //table reload
            [self.tableView reloadData];
        }];
    }
    
}

#pragma mark - time stamp
- (NSDate *)lastChecked{
    if (!_lastChecked) {
        _lastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:kLastChecked];
        if (!_lastChecked) {
            NSLog(@"first time check");
            self.lastChecked = [NSDate date];
        }
    }
    return _lastChecked;
}

- (void)setLastChecked:(NSDate *)lastChecked{
    _lastChecked = lastChecked;
    [[NSUserDefaults standardUserDefaults] setObject:lastChecked forKey:kLastChecked];
}

#pragma mark - navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    // 1 week, 1 month, 3 months, 1 year, 1yr+
    return self.showFullHistory?5:1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            //week
            return self.contacts_week.count;
            
        case 1:
            return self.contacts_month.count;
            
        case 2:
            return self.contacts_3months.count;
            
        case 3:
            return self.contacts_year.count;
            
        case 4:
            return self.contacts_older.count;
            
        default:
            break;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    APContact *contact;
    switch (indexPath.section) {
        case 0:
            //week
            contact = self.contacts_week[indexPath.row];
            break;
        case 1:
            contact = self.contacts_month[indexPath.row];
            break;
        case 2:
            contact = self.contacts_3months[indexPath.row];
            break;
        case 3:
            contact = self.contacts_year[indexPath.row];
            break;
        case 4:
            contact = self.contacts_older[indexPath.row];
            break;
        default:
            return cell;
    }
    
    cell.textLabel.text = contact.compositeName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Created on %@", contact.creationDate.date2dayString];
 
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
