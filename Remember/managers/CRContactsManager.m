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

#define TESTING                 NO

@interface CRContactsManager()
@property (nonatomic, strong) RHAddressBook *addressbook;
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
        
        //setting
        self.useDefaultSource = YES;
        
        //check addressbook access
        //query current status, pre iOS6 always returns Authorized
        if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
            
            //request authorization
            [_addressbook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
                _allContacts = nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
            }];
		}else if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusAuthorized){
			[[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
		}
			
        // start observing
        [[NSNotificationCenter defaultCenter]  addObserverForName:RHAddressBookExternalChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			DDLogInfo(@"Observed changes to AddressBook");
            _allContacts = nil;
			_duplicatedContacts = [NSMutableOrderedSet new];
			//delay sending notification
			static NSTimer *timer;
			[timer invalidate];
			timer = [NSTimer bk_scheduledTimerWithTimeInterval:1.5 block:^(NSTimer *timer) {
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
        NSArray *contacts;
        if (self.useDefaultSource) {
            contacts = _addressbook.defaultSource.people;
        }
        else{
            contacts = [_addressbook people];
        }
        
        NSArray *peopleWithoutCreationDate = [contacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"created = nil"]];
        for (RHPerson  *person in peopleWithoutCreationDate) {
            NSDate *lastWeek = [[NSDate date] dateByAddingTimeInterval:-3600*24*30*6];
            DDLogVerbose(@"Found contacts %@ without created, assign %@", person.name, lastWeek.string);
            [person setBasicValue:(__bridge CFTypeRef)lastWeek forPropertyID:kABPersonCreationDateProperty error:nil];
        }
        
        //group linked user
        NSMutableDictionary *personMapping = [NSMutableDictionary new];
        NSMutableDictionary *emailMapping = [NSMutableDictionary new];
        NSMutableDictionary *phoneMapping = [NSMutableDictionary new];
        NSMutableSet *others = [NSMutableSet new];
        for (RHPerson *person in contacts) {
            if (personMapping[@(person.recordID)]) {
                continue;
            }
            NSArray *linked = person.linkedPeople;
            if (linked.count > 1) {
                RHPerson *originalPerson = [linked sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES]]].firstObject;
                for (RHPerson *linkedPerson in linked) {
                    personMapping[@(linkedPerson.recordID)] = originalPerson;
                    //TODO: need to figure out how to merge person info
                }
            }else{
                personMapping[@(person.recordID)] = person;
            }
        }
        //remove duplicates
        _allContacts = [NSSet setWithArray:personMapping.allValues].allObjects;
        
        
        if (self.findDuplicates) {
            TICK
            for (RHPerson *person in _allContacts) {
                if (person.emails.values.count == 0 && person.phoneNumbers.values.count == 0) {
                    [others addObject:person];
                    continue;
                }
                
                //find email dup
                for (NSString *email in person.emails.values) {
                    RHPerson *duplicated = emailMapping[email];
                    if (duplicated) {
                        if ([duplicated.created timeIntervalSinceDate:person.created]>0) {
                            //this person is older
                            emailMapping[email] = person;
                        } else {
							//DDLogVerbose(@"Found duplicated %@ with email %@", person.name, email);
                            [self.duplicatedContacts addObjectsFromArray:@[duplicated, person]];
                        }
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
                        if ([duplicated.created timeIntervalSinceDate:person.created]>0) {
                            //this person is older
                            phoneMapping[phoneNumber] = person;
                        } else {
							//DDLogVerbose(@"Found duplicated %@ with phone %@", person.name, phone);
                            [self.duplicatedContacts addObjectsFromArray:@[duplicated, person]];
                        }
                    }else{
                        phoneMapping[phoneNumber] = person;
                    }
                }
            }
            
            //union
            NSMutableSet *allContacts = [NSMutableSet setWithArray:emailMapping.allValues];
            [allContacts intersectSet:[NSSet setWithArray:phoneMapping.allValues]];
            [allContacts unionSet:others];
            _allContacts = allContacts.allObjects;
            DDLogInfo(@"Found %lu duplicated person", (unsigned long)_duplicatedContacts.count);
            TOCK
        }
        
    }
    
    return _allContacts;
}


//contacts added since last updates, used as default view
- (NSArray *)recentContacts{
	NSDate *chekDate = [self.lastOpenedOld isEarlierThan:self.lastUpdated] ? self.lastOpenedOld : self.lastUpdated;
	DDLogVerbose(@"Searching for recent contacts since %@", chekDate.string);
    NSArray *newContacts = [self.allContacts bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:chekDate] > 0;
	}];
    
    return newContacts.sortedByCreated;
}



- (NSArray *)newContactsSinceLastCheck{
    NSDate *lastChecked = self.lastChecked;
    NSArray *newContacts = [self.allContacts bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:lastChecked] > 0;
    }];
	
	return newContacts;
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
	//self.lastChecked = [NSDate dateWithTimeIntervalSinceNow:-3600*8];
    self.lastChecked = [NSDate dateWithTimeIntervalSinceNow:-60];
	NSArray *newContacts = [self newContactsSinceLastCheck];
	DDLogDebug(@"Found new contacts from 8 hours ago: %@", [newContacts valueForKey:@"name"]);
}


#pragma mark - Actions
- (void)checkNewContactsAndNotifyWithCompletion:(void (^)(NSArray *newContacts))block{
    //check
	NSArray *newContacts = [self newContactsSinceLastCheck];
    //update time
    self.lastChecked = [NSDate date];
    
    
	if (newContacts.count) {
		DDLogInfo(@"Found %ld new contacts since last checked %@", (unsigned long)newContacts.count, _lastChecked.string);
		NSDate *oldestCreated = [NSDate date];
		for (RHPerson *person in newContacts) {
			if ([person.created isEarlierThan:oldestCreated]) {
				oldestCreated = person.created;
			}
		}
		
        self.lastUpdated = oldestCreated;
		
        //move the lastOpened old time to real last opened time, so the user will see newly updated contacts
        self.lastOpenedOld = self.lastOpened;
        [[NSUserDefaults standardUserDefaults] synchronize];
        
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
            if ([note.userInfo[@"type"] isEqualToString:@"remember"]) {
                if ([note.fireDate isEqualToDate:oldestCreated.nextNoon]) {
                    [[UIApplication sharedApplication] cancelLocalNotification:note];
                }
            }
        }
		
		//send notification
		UILocalNotification *note = [UILocalNotification new];
		note.alertBody = reminderStr;
		note.soundName = @"reminder.caf";
		note.category = kReminderCategory;
		note.fireDate = oldestCreated.nextNoon;//TODO: use created time
        note.userInfo = @{@"type": @"remember"};

		[[UIApplication sharedApplication] scheduleLocalNotification:note];
        
        //schedule on server push
        [self sendNewContactsReminderPush:reminderStr];
        
        
        
	}
    
    if (block) {
        block(newContacts);
    }
}

- (void)sendNewContactsReminderPush:(NSString *)string{
    //schedule server push
    if (![PFInstallation currentInstallation].objectId) {
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
    
    [manager POST:@"https://api.parse.com/1/push" parameters:dic
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              
              NSLog(@"SCHEDULED reminder PUSH success for time %@", nextNoon.string);
              
          }failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              
              NSLog(@"Schedule Push Error: %@", error);
          }];
}


- (BOOL)removeAllLinkedContact:(RHPerson *)contact{
    DDLogInfo(@"Deleting contact %@ with %lu linked person", contact.name, (unsigned long)contact.linkedPeople.count);
    BOOL success;
    NSError *error;
    for (RHPerson *person in contact.linkedPeople) {
        success = [person remove];
        if (!success) {
            DDLogError(@"Failed to remove contact: %@", person);
        }
        
        self.allContacts = nil;
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
