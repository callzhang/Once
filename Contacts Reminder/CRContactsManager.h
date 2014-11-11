//
//  CRContactsManager.h
//  
//
//  Created by Lee on 11/10/14.
//
//

#import <Foundation/Foundation.h>

#define kParseApplicationId	@"xqiXF3hnqiLXFFkcE3pYs3b2oBORjSdJRiQdKCPK"
#define kParseClientKey		@"NOT06QA8LdXXLQjUmGKBHs6RWO1qPvrEyJUURxOI"
#define kParseRestAPIId		@"NTWLFE2HunWRIeGGKjBwT29Gm4QahR6Gpztiugxt"
//time
#define kLastChecked		@"last_checked"
#define kLastUpdated		@"last_updated"
#define kLastOpened			@"last_opened"
#define kLastOpenedOld		@"last_opened_old"
//event
#define kAdressbookReady	@"addressbook_ready"
//notification category
#define kReminderCategory	@"quick_memo"
//local notification user info
#define kReactivateLocalNotification	@"reactivate"

@interface CRContactsManager : NSObject
@property (nonatomic, strong) NSArray *recentContacts;
@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSDate *lastChecked;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSDate *lastOpened;
@property (nonatomic, strong) NSDate *lastOpenedOld;

+ (CRContactsManager *)sharedManager;
//- (NSArray *)newContactsSinceLastCheck;
- (void)checkNewContactsAndNotifyWithCompletion:(void (^)(UIBackgroundFetchResult result))block;
- (void)scheduleReactivateLocalNotification;
@end
