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
#define kLastChecked		@"last_checked"//Last checked time
#define kLastUpdated		@"last_updated"//Last checked and had result time
#define kLastOpened			@"last_opened"//Last time app opened
#define kLastOpenedOld		@"last_opened_old"//Last second time app opened
//event
#define kAdressbookReady	@"addressbook_ready"
//notification category
#define kReminderCategory	@"quick_memo"
//OriginalCrated
#define kOriginalCreated	@"CR_created"
//notification
#define kCRAddressBookChangeCompleted	@"addressbook_change_completed"


#define TICK                            NSDate *startTime = [NSDate date];
#define TOCK                            NSLog(@"Time: %f", -[startTime timeIntervalSinceNow]);

@class RHPerson;

@interface CRContactsManager : NSObject

+ (CRContactsManager *)sharedManager;

#pragma mark - TIME
@property (nonatomic, strong, readonly) NSDate *lastChecked;//last checked time, keep updating
@property (nonatomic, strong, readonly) NSDate *lastUpdated;//last time checked and found new contacts.
@property (nonatomic, strong, readonly) NSDate *lastOpened;//last app opened time (at app going to background)

/**
 *  Lagging last opened time, it is updated on founding new contacts
 *  This is to make sure that closing the app doesn't move the timer pointer to the lastOpened, so that the next time user still can see the same recent contacts, if no new contacts are created.
 */
@property (nonatomic, strong, readonly) NSDate *lastOpenedOld;

#pragma mark - Perspectives
/**
 *  All contacts from address book. If set MERGE_LINKED_PERSON to yes, it merged into unique entity with in linked contacts.
 */
@property (nonatomic, strong, readonly) NSArray *allContacts;

/**
 *  Recent created contacts. Specifically, newer than lastOpenedOld.
 *
 *  @return list of recent contacts
 */
@property (nonatomic, strong, readonly) NSArray *recentContacts;

/**
 *  Contacts created that are newer than last checked time, meaning they should be notified.
 *	It is the slices of new contacts that are not repeating.
 *
 *  @return list of new contacts
 */
@property (nonatomic, strong, readonly) NSArray *newContactsSinceLastCheck;

@property (nonatomic, strong, readonly) NSMutableOrderedSet *duplicatedContacts;

#pragma mark - Actions
- (void)checkNewContactsAndNotifyWithCompletion:(void (^)(NSArray *newContacts))block;
- (BOOL)removeAllLinkedContact:(RHPerson *)contact;
- (BOOL)deleteContact:(RHPerson *)contact;
@end
