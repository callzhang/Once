//
//  CRContactsManager.m
//  
//
//  Created by Lee on 11/10/14.
//
//

#import "CRContactsManager.h"
#import "NSDate+Extend.h"
#import "RHAddressBook.h"
#import "RHPerson.h"
#import <AFNetworking/AFNetworking.h>
#import "EWUIUtil.h"
#import "RHSource.h"
#import "NSDate+Extend.h"
#import "AppDelegate.h"

#define TESTING                 NO
#define REDUCE_LINKED			NO
#define FIND_DUPLICATED			YES

@interface CRContactsManager()
@property (nonatomic, strong) RHAddressBook *addressbook;
@property (nonatomic, strong) NSDate *lastChecked;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSDate *lastOpened;
@property (nonatomic, strong) NSDate *lastOpenedOld;
@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSArray *recentContacts;
@property (nonatomic, strong) NSArray *newContactsSinceLastCheck;
@property (nonatomic, strong) NSMutableOrderedSet *duplicatedContacts;

@end

@implementation CRContactsManager
@synthesize lastUpdated = _lastUpdated;
@synthesize lastChecked = _lastChecked;
@synthesize lastOpened = _lastOpened;
@synthesize lastOpenedOld = _lastOpenedOld;

+ (CRContactsManager *)sharedManager{
    static CRContactsManager *manager;
    if (!manager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            manager = [[CRContactsManager alloc] init];
        });
    }
    return manager;
}

- (CRContactsManager *)init{
    self = [super init];
    if (self) {
        // load addressbook
        _addressbook = [[RHAddressBook alloc] init];
        
        //check addressbook access
        //query current status, pre iOS6 always returns Authorized
        if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
            
            //request authorization
            [_addressbook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
				[self clear];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
            }];
		}else if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusAuthorized){
			[[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
		}
			
        // start observing
        [[NSNotificationCenter defaultCenter]  addObserverForName:RHAddressBookExternalChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//			[self clear];
            //TODO:fixed by geng
            [self checkNewContactsAndNotifyWithCompletion:nil];
            
			_duplicatedContacts = [NSMutableOrderedSet new];
			//delay sending notification
			static NSTimer *timer;
			[timer invalidate];
			timer = [NSTimer bk_scheduledTimerWithTimeInterval:2 block:^(NSTimer *timer) {
				DDLogInfo(@"Observed changes to AddressBook");
				[[NSNotificationCenter defaultCenter] postNotificationName:kCRAddressBookChangeCompleted object:nil];
			} repeats:NO];
        }];
		
		//time stamp
		[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			DDLogInfo(@"App is going to background, save last opened date!");
			//update last opened
            self.lastOpened = [NSDate date];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}];
        
        //print out all times
        DDLogInfo(@"Last checked: %@", self.lastChecked.string);
        DDLogInfo(@"Last updated: %@", self.lastUpdated.string);
        DDLogInfo(@"Last opened: %@", self.lastOpened.string);
        DDLogInfo(@"Last second opened: %@", self.lastOpenedOld.string);
		
		if (TESTING) {
			[self testCheckNewContacts];
		}
        
        //data
        _duplicatedContacts = [NSMutableOrderedSet new];
    }
    
    return self;
}



#pragma mark - Perspective
- (NSArray *)allContacts{
    if (!_allContacts) {
        NSArray *contacts = _addressbook.defaultSource.people;
        if (contacts.count == 0){
			DDLogWarn(@"Got zero contact, try using all people");
            contacts = [_addressbook people];
        }
		
		if (REDUCE_LINKED) {
			NSArray *peopleWithoutCreationDate = [contacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"created = nil"]];
			for (RHPerson  *person in peopleWithoutCreationDate) {
				NSDate *lastMonth = [[NSDate date] dateByAddingTimeInterval:-3600*24*30];
				DDLogWarn(@"Found contacts %@ without created, assign %@", person.name, lastMonth.string);
				[person setBasicValue:(__bridge CFTypeRef)lastMonth forPropertyID:kABPersonCreationDateProperty error:nil];
			}
			
			//group linked user
			NSMutableDictionary *personMapping = [NSMutableDictionary new];
			for (RHPerson *person in contacts) {
				if (personMapping[@(person.recordID)]) {
					//linked person already mapped, skip
					continue;
				}
				NSArray *linked = person.linkedPeople;
				if (linked.count > 1) {
					RHPerson *originalPerson = [linked sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES]]].firstObject;
					for (RHPerson *linkedPerson in linked) {
						//check if that contact is in the same source
						if (linkedPerson.inSource == self.addressbook.defaultSource) {
							//Mapp all linked person id to oldest person
							personMapping[@(linkedPerson.recordID)] = originalPerson;
							//TODO: need to figure out how to merge person info
							//
						}
					}
				}else{
					personMapping[@(person.recordID)] = person;
				}
			}
			//set all contacts
			_allContacts = [NSSet setWithArray:personMapping.allValues].allObjects;
		} else {
			_allContacts = contacts;
		}
		
		
		
        if (FIND_DUPLICATED) {
			
			NSMutableDictionary *emailMapping = [NSMutableDictionary new];
			NSMutableDictionary *phoneMapping = [NSMutableDictionary new];
			NSMutableSet *others = [NSMutableSet new];
            for (RHPerson *person in _allContacts) {
                if (person.emails.values.count == 0 && person.phoneNumbers.values.count == 0) {
                    [others addObject:person];
                    continue;
                }
                
                //find email dup
                for (NSString *email in person.emails.values) {
                    RHPerson *duplicated = emailMapping[email];
					if (duplicated) {
						DDLogVerbose(@"Found duplicated %@ with email %@", person.name, email);
                        if ([duplicated.created timeIntervalSinceDate:person.created]>0) {
                            //this person is older
                            emailMapping[email] = person;
                        }
                        [self.duplicatedContacts addObjectsFromArray:@[duplicated, person]];
                        
                    }else{
                        emailMapping[email] = person;
                    }
                }
                //find phone dup
                for (NSString *phone in person.phoneNumbers.values) {
                    //transform to number only
                    NSCharacterSet *nonNumberSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                    NSString *phoneNumber = [[phone componentsSeparatedByCharactersInSet:nonNumberSet] componentsJoinedByString:@""];
                    RHPerson *duplicated = phoneMapping[phoneNumber];
					if (duplicated) {
						DDLogVerbose(@"Found duplicated %@ with phone %@", person.name, phone);
                        if ([duplicated.created timeIntervalSinceDate:person.created]>0) {
                            //this person is older
                            phoneMapping[phoneNumber] = person;
                        }
                        [self.duplicatedContacts addObjectsFromArray:@[duplicated, person]];
                        
                    }else{
                        phoneMapping[phoneNumber] = person;
                    }
                }
            }
            
            //union
//            NSMutableSet *allContacts = [NSMutableSet setWithArray:emailMapping.allValues];
//            [allContacts unionSet:[NSSet setWithArray:phoneMapping.allValues]];
//            [allContacts unionSet:others];
//            _allContacts = allContacts.allObjects;
            DDLogInfo(@"Found %lu duplicated person", (unsigned long)self.duplicatedContacts.count);
        }
    }
    
    return _allContacts;
}


//contacts added since last updates, used as default view
- (NSArray *)recentContacts{
	if (!_recentContacts) {
		NSDate *chekDate = [self.lastOpenedOld isEarlierThan:self.lastUpdated] ? self.lastOpenedOld : self.lastUpdated;
		DDLogVerbose(@"Searching for recent contacts since %@", chekDate.string);
		NSArray *contacts = [self.allContacts bk_select:^BOOL(RHPerson *person) {
			return [person.created timeIntervalSinceDate:chekDate] > 0;
		}];
		_recentContacts = contacts;
	}
    
    return _recentContacts;
}



- (NSArray *)newContactsSinceLastCheck{
	//if (!_newContactsSinceLastCheck) {
    NSDate *lastChecked = self.lastChecked;
    NSArray *newContacts = [self.allContacts bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:lastChecked] > 0;
    }];
    _newContactsSinceLastCheck = newContacts;
	//}
	
	return _newContactsSinceLastCheck;
}

- (NSMutableOrderedSet *)duplicatedContacts{
	if (!_allContacts) {
		DDLogWarn(@"Accessed duplicated contacts before all contacts is generated. (%ld)", (long)self.allContacts);
	}
	return _duplicatedContacts;
}

#pragma mark - Tools
- (NSArray *)findDuplicates:(NSArray *)contacts{
    DDLogVerbose(@"Checking contacts with same phone or email....");
    TICK
    NSMutableArray *unrelatedContacts = [NSMutableArray array];
    for (RHPerson *person in contacts) {
        //check email
        //TODO: use dictionary
        NSMutableSet *peopleWithSameEmail = [NSMutableSet new];
        for (NSString *email in person.emails.values) {
            NSArray *people = [_addressbook peopleWithEmail:email];
            [peopleWithSameEmail addObjectsFromArray:people];
        }
        [peopleWithSameEmail removeObject:person];
        DDLogInfo(@"Found %ld person with same email for person %@", (long)peopleWithSameEmail.count, person.name);
        
        //check phone
        //TODO: use dictionary
        NSMutableSet *peopleWithSamePhoneNumber = [NSMutableSet new];
        NSArray *numbers = person.phoneNumbers.values;
        for(RHPerson *person in _addressbook.people) {
            NSArray *phoneNumbers = [person.phoneNumbers values];
            for (NSString *phoneNumber in numbers) {
                if ([phoneNumbers containsObject:phoneNumber]){
                    [peopleWithSamePhoneNumber addObject:person];
                }
            }
        }
        [peopleWithSamePhoneNumber removeObject:person];
        DDLogInfo(@"Found %ld person with same email for person %@", (long)peopleWithSamePhoneNumber.count, person.name);
        //TODO: link person
        
        //order
        NSSet *possibleLinked = [peopleWithSameEmail setByAddingObjectsFromSet:peopleWithSamePhoneNumber];
        RHPerson *oldestPerson = [possibleLinked sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES]]].firstObject;
        if ([oldestPerson.created timeIntervalSinceDate:self.lastChecked] > 0) {
            [unrelatedContacts addObject:person];
        } else {
            DDLogInfo(@"Person %@ has linked person that was already created: %@", person.name, [possibleLinked valueForKey:@"name"]);
        }
    }
    TOCK
    return unrelatedContacts.copy;
}

- (NSArray *)filterOutExistingContactsFromNewContacts:(NSArray *)contacts withDate:(NSDate *)time{
	//check each new contact's linkedContacts, to make sure that they indeed are created new
	NSMutableArray *newContacts = [NSMutableArray arrayWithArray:contacts];
	NSMutableArray *existingPerson = [NSMutableArray new];
	for (RHPerson *person in newContacts) {
		NSArray *linked = person.linkedPeople;
		if (linked.count > 1) {
			RHPerson *originalPerson = [linked sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES]]].firstObject;
			if ([originalPerson.created isEarlierThan:time]) {
				[existingPerson addObject:person];
			}
		}
	}
	[newContacts removeObjectsInArray:existingPerson];
	DDLogInfo(@"Out of %ld contacts, found %ld exisitng contacts, resulting %ld new contacts", (long)contacts.count, (long)existingPerson.count, (long)newContacts.count);
	
	return newContacts.copy;
}

- (void)testCheckNewContacts{
    DDLogInfo(@"Start testing checking new contacts");
	self.lastChecked = [NSDate dateWithTimeIntervalSinceNow:-3600*8];
	NSArray *newContacts = [self newContactsSinceLastCheck];
	DDLogDebug(@"Found new contacts from 8 hours ago: %@", [newContacts valueForKey:@"name"]);
}

- (void)clear{
	self.allContacts = nil;
	self.recentContacts = nil;
	self.newContactsSinceLastCheck = nil;
}


#pragma mark - Actions
- (void)checkNewContactsAndNotifyWithCompletion:(void (^)(NSArray *newContacts))block{
    //clear first
    [self clear];
    //check
	NSArray *newContacts = [self newContactsSinceLastCheck];
    //update time
    self.lastChecked = [NSDate date];
    
    
	if (newContacts.count) {
		DDLogInfo(@"Found %ld new contacts since last checked %@", (unsigned long)newContacts.count, _lastChecked.string);
		NSDate *oldestCreated = [NSDate date];
        
        NSString*createdTimeString; //timeString
		for (RHPerson *person in newContacts) {
			if ([person.created isEarlierThan:oldestCreated]) {
				oldestCreated = person.created;
                createdTimeString = [EWUIUtil getTimeString:person.created];
                break;
			}
		}
		
        self.lastUpdated = oldestCreated;
		
        //move the lastOpened old time to real last opened time, so the user will see newly updated contacts
        self.lastOpenedOld = self.lastOpened;
        
		//name
		NSArray *names = [newContacts valueForKey:@"name"];
		NSString *reminderStr;
		if (names.count > 1) {
			reminderStr = [NSString stringWithFormat:@"You recently met %@ and %ld other people. Add a quick note?", names.firstObject, (long)names.count-1];
		} else {
			reminderStr = [NSString stringWithFormat:@"You recently met %@. Add a quick note?", names.firstObject];
		}
        
        //remove old notification
        for (UILocalNotification *note in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
            if ([note.userInfo[@"type"] isEqualToString:@"reminder"]) {
                if ([note.fireDate isEqualToDate:oldestCreated.nextNoon]) {
                    [[UIApplication sharedApplication] cancelLocalNotification:note];
                }
            }
        }
		
		//send notification
		UILocalNotification *note = [UILocalNotification new];
		note.alertTitle = names.count > 1 ? @"New Contacts" : @"New Contact";
		note.alertBody = reminderStr;
		note.soundName = @"reminder.caf";
		note.category = kReminderCategory;
		note.fireDate = [NSDate date].nextNoon;//TODO: use created time
        note.userInfo = @{@"type": @"reminder", @"names": names, @"created":createdTimeString};
		[[UIApplication sharedApplication] scheduleLocalNotification:note];
		
#ifdef DEBUG
		note.fireDate = [[NSDate date] dateByAddingTimeInterval:15];
		[[UIApplication sharedApplication] scheduleLocalNotification:note];
#endif
        
        //schedule on server push
		//[self sendNewContactsReminderPush:reminderStr];
        
	}
    
    if (block) {
        block(newContacts);
    }
}

//TODO:fixed by geng
- (void)cancelTakeNotesNotification:(NSDate*)oldestCreated
{
    for (UILocalNotification *note in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([note.userInfo[@"type"] isEqualToString:@"reminder"]) {
            if ([note.fireDate isEqualToDate:oldestCreated.nextNoon]) {
                [[UIApplication sharedApplication] cancelLocalNotification:note];
            }
        }
    }
}


- (void)sendNewContactsReminderPush:(NSString *)string{
    //schedule server push
    if (![PFInstallation currentInstallation].objectId) {
		[[PFInstallation currentInstallation] save];
        return;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:kParseApplicationId forHTTPHeaderField:@"X-Parse-Application-Id"];
    [manager.requestSerializer setValue:kParseRestAPIId forHTTPHeaderField:@"X-Parse-REST-API-Key"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDate *nextNoon = [NSDate date].nextNoon;
#ifdef DEBUG
    nextNoon = [[NSDate date] dateByAddingTimeInterval:10];
#endif
    NSDictionary *dic = @{@"where":@{@"objectId":[PFInstallation currentInstallation].objectId},
                          @"push_time":[NSNumber numberWithDouble:[nextNoon timeIntervalSince1970]],
                          @"data":@{@"alert": string,
                                    @"content-available":@1,
                                    @"category": kReminderCategory,
                                    @"sound": @"reminder.caf",
                                    @"bedge": @"Incremental"},
                          };
	DDLogVerbose(@"Schedule push with data: %@", dic);
    [manager POST:@"https://api.parse.com/1/push" parameters:dic
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              
              DDLogVerbose(@"SCHEDULED reminder PUSH success for time %@", nextNoon.string);
              
          }failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              
              DDLogError(@"Schedule Push Error: %@", error);
          }];
}


- (BOOL)removeAllLinkedContact:(RHPerson *)contact{
	NSParameterAssert(contact);
    DDLogInfo(@"Deleting contact %@ with %lu linked person", contact.name, (unsigned long)contact.linkedPeople.count);
    BOOL success;
    NSError *error;
    for (RHPerson *person in contact.linkedPeople) {
		if (person.inSource == self.addressbook.defaultSource) {
			success = [person remove];
			if (!success) DDLogError(@"Failed to remove contact: %@", person);
			[self clear];
		}
    }
    success = [self.addressbook saveWithError:&error];
    if (!success) {
        DDLogError(@"Failed to save addressBook: %@", error.localizedDescription);
    }
    return success;
}

- (BOOL)deleteContact:(RHPerson *)contact{
	DDLogInfo(@"Deleting contact %@", contact.name);
	BOOL success;
	NSError *error;
	success = [contact remove];
	if (!success) {
		DDLogError(@"Failed to remove contact: %@", contact);
	}
	success = [self.addressbook saveWithError:&error];
	if (!success) {
		DDLogError(@"Failed to save addressBook: %@", error.localizedDescription);
	}
	return success;
}

#pragma mark - time stamp
- (NSDate *)lastChecked{
    _lastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:kLastChecked];
    if (!_lastChecked) {
        DDLogInfo(@"first time check");
        self.lastChecked = [NSDate date];
    }
    return _lastChecked;
}

- (void)setLastChecked:(NSDate *)lastChecked{
    _lastChecked = lastChecked;
    [[NSUserDefaults standardUserDefaults] setObject:lastChecked forKey:kLastChecked];
}

- (NSDate *)lastUpdated{
    _lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUpdated];
    if (!_lastUpdated) {
        DDLogInfo(@"first time update");
        self.lastUpdated = [NSDate date];
    }
    return _lastUpdated;
}

- (void)setLastUpdated:(NSDate *)lastUpdate{
    _lastUpdated = lastUpdate;
    [[NSUserDefaults standardUserDefaults] setObject:lastUpdate forKey:kLastUpdated];
}

- (NSDate *)lastOpened{
	_lastOpened = [[NSUserDefaults standardUserDefaults] objectForKey:kLastOpened];
	if (!_lastOpened) {
        self.lastOpened = [NSDate date];
	}
	return _lastOpened;
}

- (void)setLastOpened:(NSDate *)lastOpened{
	DDLogInfo(@"Last opened set to: %@", lastOpened.string);
    _lastOpened = lastOpened;
	[[NSUserDefaults standardUserDefaults] setObject:_lastOpened forKey:kLastOpened];
}

- (NSDate *)lastOpenedOld{
    _lastOpenedOld = [[NSUserDefaults standardUserDefaults] objectForKey:kLastOpenedOld];
    if (!_lastOpenedOld) {
        self.lastOpenedOld = [NSDate date];
    }
	return _lastOpenedOld;
}

- (void)setLastOpenedOld:(NSDate *)lastOpenedOld{
    _lastOpenedOld = lastOpenedOld;
    DDLogInfo(@"Last opened old set to: %@", lastOpenedOld.string);
	[[NSUserDefaults standardUserDefaults] setObject:_lastOpenedOld forKey:kLastOpenedOld];
}
@end
