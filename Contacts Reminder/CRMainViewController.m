//
//  CRMainViewController.m
//  Contacts Reminder
//
//  Created by Lee on 11/9/14.
//  Copyright (c) 2014 Lee. All rights reserved.
//

#import "CRMainViewController.h"
#import <RHAddressBook.h>
#import "NSDate+Extend.h"
#import "RHAddressBook.h"
#import "RHPerson.h"
@import AddressBook;

NSString *const kLastChecked = @"last_checked";

@interface CRMainViewController ()
@property RHAddressBook *addressbook;
@property (nonatomic, strong) NSMutableArray *contacts_recent;
@property (nonatomic, strong) NSMutableArray *contacts_month;
@property (nonatomic, strong) NSMutableArray *contacts_earlier;
@property BOOL showFullHistory;
@property NSDate *lastChecked;
@end

@implementation CRMainViewController
@synthesize lastChecked = _lastChecked;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contacts_recent = [NSMutableArray new];
    self.contacts_month = [NSMutableArray new];
    self.contacts_earlier = [NSMutableArray new];
    
    // load addressbook
    RHAddressBook *ab = [[RHAddressBook alloc] init];
    
    //check addressbook access
    //query current status, pre iOS6 always returns Authorized
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
        
        //request authorization
        [ab requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
            _addressbook = ab;
            [self loadAddressBook];
        }];
    }else if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusAuthorized){
        _addressbook = ab;
        [self loadAddressBook];
    }
    
    // start observing
    [[NSNotificationCenter defaultCenter]  addObserverForName:RHAddressBookExternalChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        
        [self loadAddressBook];
        
    }];
    
    
}


- (void)dealloc{
    
    // stop observing
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated{
    //add show history button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"History" style:UIBarButtonItemStylePlain target:self action:@selector(showHistory:)];
}

#pragma mark - Address Book TOOLS
- (void)requestForAddressBook{
    CFErrorRef myError = NULL;
    ABAddressBookRef myAddressBook = ABAddressBookCreateWithOptions(NULL, &myError);
    ABAddressBookRequestAccessWithCompletion(myAddressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            _addressbook = [[RHAddressBook alloc] init];
            [self loadAddressBook];
        } else {
            // Handle the case of being denied access and/or the error.
            NSLog(@"Failed to get addressbook: %@", error);
        }
        CFRelease(myAddressBook);
    });
}

- (void)loadAddressBook{
    NSArray *contacts = [_addressbook people];
    
    for (RHPerson *contact in contacts) {
        if (!_showFullHistory) {
            if ([contact.created timeIntervalSinceDate:self.lastChecked] < 0) {
                continue;
            }
        }
        if (!contact.created) {
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
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"MainViewCellIdentifier"];
    }
    
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
    
    cell.textLabel.text = contact.compositeName ?: [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Created on %@", contact.created.date2dayString];
 
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


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
