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

@interface CRContactsManager()
@property (nonatomic, strong) RHAddressBook *addressbook;
@end

@implementation CRContactsManager
@synthesize lastUpdated = _lastUpdated;
@synthesize lastChecked = _lastChecked;

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
        RHAddressBook *ab = [[RHAddressBook alloc] init];
        
        //check addressbook access
        //query current status, pre iOS6 always returns Authorized
        if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
            
            //request authorization
            [ab requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
                _addressbook = ab;
                //[self loadAddressBook];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kAdressbookReady object:nil];
            }];
        }
        
        // start observing
        [[NSNotificationCenter defaultCenter]  addObserverForName:RHAddressBookExternalChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            
            _allContacts = nil;
            
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
    NSDate *lastUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUpdated];
    NSArray *recents = [[_addressbook people] bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:lastUpdated] > 0;
    }];
    
    return [recents sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]]];
}



- (NSArray *)newContactsSinceLastCheck{
    NSDate *lastChecked = self.lastChecked;
    NSArray *newContacts = [[_addressbook people] bk_select:^BOOL(RHPerson *person) {
        return [person.created timeIntervalSinceDate:lastChecked] > 0;
    }];
    
    if (newContacts.count > 0) {
        self.lastUpdated = [NSDate date];
    }
    
    self.lastChecked = [NSDate date];
    
    return newContacts;
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
    return _lastChecked;
}

- (void)setLastUpdated:(NSDate *)lastUpdate{
    _lastUpdated = lastUpdate;
    [[NSUserDefaults standardUserDefaults] setObject:lastUpdate forKey:kLastUpdated];
}
@end
