//
//  CRContactsManager.h
//  
//
//  Created by Lee on 11/10/14.
//
//

#import <Foundation/Foundation.h>


NSString *const kLastChecked = @"last_checked";
NSString *const kLastUpdated = @"last_updated";
NSString *const kAdressbookReady = @"addressbook_ready";
//NSString *const kLastOpened = @"last_opened";

@interface CRContactsManager : NSObject
@property (nonatomic, strong) NSArray *recentContacts;
@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSDate *lastChecked;
@property (nonatomic, strong) NSDate *lastUpdated;

+ (CRContactsManager *)sharedManager;
- (NSArray *)newContactsSinceLastCheck;
@end
