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
        
        //check addressbook access
        //query current status, pre iOS6 always returns Authorized
        if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
            
            //request authorization
            [_addressbook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
            }];
		}else if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusAuthorized){
			[[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
		}
			
        // start observing
        [[NSNotificationCenter defaultCenter]  addObserverForName:RHAddressBookExternalChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			NSLog(@"Observed changes to AddressBook");
            _allContacts = nil;
			[self checkNewContactsAndNotifyWithCompletion:nil];
            
        }];
		
		//time stamp
		[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			//update last opened
			[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastOpened];
		}];
    }
    
    return self;
}


- (NSArray *)allContacts{
    if (!_allContacts) {
        _allContacts = [[_addressbook people] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]]];
    }
    return _allContacts;
}


//contacts added since last updates, used as default view
- (NSArray *)recentContacts{
    NSDate *lastUpdated = self.lastUpdated;
    NSArray *recents = [[_addressbook people] bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:lastUpdated] > 0;
    }];
    
    return [recents sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]]];
}


#pragma mark - Check new
- (void)checkNewContactsAndNotifyWithCompletion:(void (^)(UIBackgroundFetchResult result))block{
	NSArray *newContacts = [self newContactsSinceLastCheck];
	if (newContacts.count) {
		//name
		NSArray *names = [newContacts valueForKey:@"firstName"];
		NSString *reminderStr;
		if (names.count > 1) {
			reminderStr = [NSString stringWithFormat:@"You recently met %@ and %ld other people. Add a quick memo?", names.firstObject, names.count-1];
		} else {
			reminderStr = [NSString stringWithFormat:@"You recently met %@. Add a quick memo?", names.firstObject];
		}
		
		//send notification
		UILocalNotification *note = [UILocalNotification new];
		note.alertBody = reminderStr;
		note.soundName = @"reminder.caf";
		note.category = kReminderCategory;
		note.fireDate = [NSDate date].nextNoon;
#ifdef DEBUG
		note.fireDate = [[NSDate date] dateByAddingTimeInterval:10];
#endif
		[[UIApplication sharedApplication] scheduleLocalNotification:note];
		
		//schedule server push
		
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
							  @"data":@{@"alert": reminderStr,
										@"content-available":@1,
										@"category": kReminderCategory,
										@"sound": @"reminder.caf",
										@"bedge": @"Incremental"},
							  };
		
		[manager POST:@"https://api.parse.com/1/push" parameters:dic
			  success:^(AFHTTPRequestOperation *operation,id responseObject) {
				  
				  NSLog(@"SCHEDULED reminder PUSH success for time %@", nextNoon.date2detailDateString);
				  if (block) {
					  block(UIBackgroundFetchResultNewData);
				  }
			  }failure:^(AFHTTPRequestOperation *operation,NSError *error) {
				  
				  NSLog(@"Schedule Push Error: %@", error);
				  if (block) {
					  block(UIBackgroundFetchResultFailed);
				  }
			  }];
	}else{
		if (block) {
			block(UIBackgroundFetchResultNoData);
		}
	}
}

- (NSArray *)newContactsSinceLastCheck{
    NSDate *lastChecked = self.lastChecked;
    NSArray *newContacts = [[_addressbook people] bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:lastChecked] > 0;
    }];
	
    if (newContacts.count > 0) {
		NSLog(@"Found %ld new contacts", (unsigned long)newContacts.count);
        self.lastUpdated = [NSDate date];
		//move the lastOpened old time to real last opened time
		self.lastOpenedOld = self.lastOpened;
		[[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.lastChecked = [NSDate date];
    
    return newContacts;
}

#pragma mark - reactivate
- (void)scheduleReactivateLocalNotification{
	UIApplication *app = [UIApplication sharedApplication];
	for (UILocalNotification *note in app.scheduledLocalNotifications) {
		if ([note.userInfo[@"type"] isEqual:kReactivateLocalNotification]) {
			[app cancelLocalNotification:note];
		}
	}
	UILocalNotification *note = [UILocalNotification new];
	note.alertAction = @"Activate me";
	note.alertBody = @"Activate me";
	note.fireDate = [[NSDate date] dateByAddingTimeInterval:3600*24];
	note.userInfo = @{@"type": kReactivateLocalNotification};
	[app scheduleLocalNotification:note];
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
    [[NSUserDefaults standardUserDefaults] setObject:lastChecked forKey:kLastUpdated];
}

- (NSDate *)lastUpdated{
    if (!_lastUpdated) {
        _lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUpdated];
        if (!_lastUpdated) {
            NSLog(@"first time update");
            self.lastUpdated = [NSDate date];
        }
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
	NSLog(@"Last opened set to: %@", lastOpened.date2detailDateString);
    _lastOpened = lastOpened;
	[[NSUserDefaults standardUserDefaults] setObject:_lastOpened forKey:kLastOpened];
}

- (NSDate *)lastOpenedOld{
	
	if (!_lastOpenedOld) {
		_lastOpenedOld = [[NSUserDefaults standardUserDefaults] objectForKey:kLastOpenedOld];
		NSLog(@"Last opened old: %@", _lastOpenedOld.date2detailDateString);
		if (!_lastOpenedOld) {
			self.lastOpenedOld = [NSDate date];
		}
	}
	return _lastOpenedOld;
}

- (void)setLastOpenedOld:(NSDate *)lastOpenedOld{
    _lastOpenedOld = [NSDate date];
	[[NSUserDefaults standardUserDefaults] setObject:_lastOpenedOld forKey:kLastOpenedOld];
}
@end
