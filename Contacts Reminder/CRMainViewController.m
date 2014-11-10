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
    
    _manager = [CRContactsManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserverForName:kAdressbookReady object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadAddressBook];
    }];
    
}


- (void)viewDidAppear:(BOOL)animated{
    //add show history button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"History" style:UIBarButtonItemStylePlain target:self action:@selector(showHistory:)];
}


- (void)loadAddressBook{
    
    self.contacts_recent = [NSMutableArray new];
    self.contacts_month = [NSMutableArray new];
    self.contacts_earlier = [NSMutableArray new];
    
    NSArray *contacts = _manager.allContacts;
    
    for (RHPerson *contact in contacts) {
        if (!_showFullHistory) {
            if ([contact.created timeIntervalSinceDate:_manager.lastUpdated] < 0) {
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
    
    cell.textLabel.text = contact.compositeName ?: [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Created on %@", contact.created.date2dayString];
 
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *header;
    switch (section) {
        case 0:
            header = @"Recent";
            break;
            
            
        case 1:
            header = @"Last 30 days";
            break;
            
        case 2:
            header = @"Earlier";
            break;
            
        default:
            break;
    }
    return header;
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
