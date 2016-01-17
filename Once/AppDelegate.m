//
//  AppDelegate.m
//  Contacts Reminder
//
//  Created by Lee on 11/9/14.
//  Copyright (c) 2014 Lee. All rights reserved.
//

#import "AppDelegate.h"
#import "NSDate+Extend.h"
#import "CRContactsManager.h"
//#import <MagicalRecord/CoreData+MagicalRecord.h>
//#import "CRContactsManager.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //logging
    [EWUtil initLogging];
    
    //core data
    //[MagicalRecord setupCoreDataStack];
	//[MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelWarn];
	
    //parse
    [Parse setApplicationId:kParseApplicationId clientKey:kParseClientKey];
    
    //background fetch
#ifdef DEBUG
	[application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
#else
    [application setMinimumBackgroundFetchInterval:3600*2];
#endif
    //manager
    [CRContactsManager sharedManager];
    //push
	[self setupInteractiveNotifications];
    
    //TESTING
//    [self scheduleLocalNotificationWithUserInfo:@{@"type": @"reminder", @"names": @[@"tsing"]} inDate:[[NSDate date] dateByAddingTimeInterval:15]];
    
    return YES;
}



#pragma mark - Background fetch method (this is called periodocially)
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogDebug(@"======== Launched in background due to background fetch event ==========");
    CRContactsManager *manager = [CRContactsManager sharedManager];
	//[manager scheduleReactivateLocalNotification];
    [manager checkNewContactsAndNotifyWithCompletion:^(NSArray *newContacts) {
		//log info
        NSMutableString *str = [NSMutableString stringWithFormat:@"=====> Remember checked new contact at %@.", [NSDate date].string];

        [str appendFormat:@" And found %ld new contacts", (long)newContacts.count];
		DDLogInfo(str);

        if (newContacts.count) {
            completionHandler(UIBackgroundFetchResultNewData);
        }else{
            completionHandler(UIBackgroundFetchResultNoData);
        }
	}];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [MagicalRecord cleanUp];
}

#pragma mark - Notification actions
- (void)setupInteractiveNotifications {
	
	//CREATE THE ACTION
	UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeNone;
	// take notes action
	UIMutableUserNotificationAction *takeNotesAction = [UIMutableUserNotificationAction new];
	takeNotesAction.identifier = @"TAKE_NOTE_ACTION_ID";
	takeNotesAction.activationMode = UIUserNotificationActivationModeForeground;
#ifdef __IPHONE_9_0
    takeNotesAction.parameters = [NSDictionary dictionaryWithObject:@"Done" forKey:UIUserNotificationTextInputActionButtonTitleKey];
    takeNotesAction.activationMode = UIUserNotificationActivationModeBackground;
    [takeNotesAction setBehavior:UIUserNotificationActionBehaviorTextInput];
#endif
    
	takeNotesAction.title = @"Take Notes";
	
	//later action
	UIMutableUserNotificationAction *later = [UIMutableUserNotificationAction new];
	// set an identifier for the action, this is used to differentiate actions from eachother when the notifiaction action handler method is called
	later.identifier = @"LATER_ACTION_ID";
	// UIUserActivationMode is used to tell the system whether it should bring your app into the foregroudn, or leave it in the background, in this case, the app can complete the request to update our backed in the background, so we don't have to open the app
	later.activationMode = UIUserNotificationActivationModeBackground;
	later.title = @"Remind me in 3 days";
    
    // Remind in 3 days action
    UIMutableUserNotificationAction *remindInThreeDaysAction = [UIMutableUserNotificationAction new];
    remindInThreeDaysAction.identifier = @"REMIND_IN_3_DAYS_ACTION_ID";
    remindInThreeDaysAction.activationMode = UIUserNotificationActivationModeBackground;
    remindInThreeDaysAction.title = @"Remind me in 3 days";
    
    // Remind in a week action
    UIMutableUserNotificationAction *remindInAWeekAction = [UIMutableUserNotificationAction new];
    remindInAWeekAction.identifier = @"REMIND_IN_A_WEEK_ACTION_ID";
    remindInAWeekAction.activationMode = UIUserNotificationActivationModeBackground;
    remindInAWeekAction.title = @"Remind me in a week";

	// CREATE THE CATEGORY
	UIMutableUserNotificationCategory *category = [UIMutableUserNotificationCategory new];
	// set its identifier. The APS dictionary you send for your push notifications must have a key named 'category' whose object is set to a string that matches this identifier in order for you actions to appear.
	category.identifier = kReminderCategory;
	[category setActions:@[takeNotesAction, remindInThreeDaysAction, remindInAWeekAction] forContext:UIUserNotificationActionContextDefault];
//    [category setActions:@[takeNotesAction, remindInAWeekAction] forContext:UIUserNotificationActionContextDefault];
	[category setActions:@[takeNotesAction, later] forContext:UIUserNotificationActionContextMinimal];
	UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObjects:category, nil]];
	[[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
	[[UIApplication sharedApplication] registerForRemoteNotifications];
}


// In your app delegate, override this method
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
 
    [self handleNotificationInfo:userInfo WithActionIdentifier:identifier];
	
	if(completionHandler)    //Finally call completion handler if its not nil
		completionHandler();
}

//#ifdef __IPHONE_8_0

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler {
    
    [self handleNotificationInfo:notification.userInfo WithActionIdentifier:identifier];

	if(completionHandler)    //Finally call completion handler if its not nil
		completionHandler();
}
//#endif

#ifdef __IPHONE_9_0

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)())completionHandler {

    NSDictionary *dataInfo;
    if ([identifier isEqualToString:@"TAKE_NOTE_ACTION_ID"]){
        dataInfo = [NSDictionary dictionaryWithObjectsAndKeys:responseInfo[UIUserNotificationActionResponseTypedTextKey],@"TAKE_NOTE",notification.userInfo,@"USER_INFO", nil];
    }else{
        dataInfo = notification.userInfo;
    }
    
    [self handleNotificationInfo:dataInfo WithActionIdentifier:identifier];
    
    if(completionHandler)    //Finally call completion handler if its not nil
        completionHandler();
         completionHandler();
}

- (void)handleNotificationInfo:(NSDictionary *)userInfo WithActionIdentifier:(nullable NSString *)identifier{
    NSDate *threeDaysLater = [[NSDate new] timeByAddingMinutes: 3 * 24 * 60];
    NSDate *weekLater = [[NSDate new] timeByAddingMinutes: 7 * 24 * 60];
    if ([identifier isEqualToString:@"TAKE_NOTE_ACTION_ID"]){
        
        static NSTimer *timer;
        [timer invalidate];
        timer = [NSTimer bk_scheduledTimerWithTimeInterval:1.5 block:^(NSTimer *timer) {
            DDLogInfo(@"Observed take notes");
            [[NSNotificationCenter defaultCenter]postNotificationName:kShowActionNote object:nil userInfo:userInfo];
        } repeats:NO];
        //NSNotificationSuspensionBehaviorDrop
        
        //open note view
    }
    else if ([identifier isEqualToString:@"LATER_ACTION_ID"]) {
        
        DDLogInfo(@"Schedule later");
        //reschedule a notification
        [self scheduleLocalNotificationWithUserInfo:userInfo inDate:threeDaysLater];
    }
    else if ([identifier isEqualToString:@"REMIND_IN_3_DAYS_ACTION_ID"])
    {
        DDLogInfo(@"Scheduled in 3 days");
        [self scheduleLocalNotificationWithUserInfo:userInfo inDate:threeDaysLater];
    }
    else if ([identifier isEqualToString:@"REMIND_IN_A_WEEK_ACTION_ID"])
    {
        DDLogInfo(@"Scheduled in a week");
        [self scheduleLocalNotificationWithUserInfo:userInfo inDate:weekLater];
    }
}


#endif



- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
	DDLogVerbose(@"Registered user notification");
}


#pragma Push notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
	DDLogInfo(@"Push token received: %@", deviceToken);
	PFInstallation *currentInstallation = [PFInstallation currentInstallation];
	[currentInstallation setDeviceTokenFromData:deviceToken];
	[currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
	DDLogError(@"Failed to register push: %@", error.description);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	DDLogInfo(@"Received push notification: %@", userInfo);
	[PFPush handlePush:userInfo];
}

#pragma mark - Local notification actions

- (void)scheduleLocalNotificationWithUserInfo:(NSDictionary *)userInfo inDate:(NSDate *)fireDate
{
    NSArray *names = [userInfo valueForKey:@"names"];
    NSString *reminderStr;
    if (names.count > 1) {
        reminderStr = [NSString stringWithFormat:@"You recently met %@ and %ld other people. Add a quick note?", names.firstObject, (long)names.count-1];
    } else {
        reminderStr = [NSString stringWithFormat:@"You recently met %@. Add a quick note?", names.firstObject];
    }
    
    UILocalNotification *note = [UILocalNotification new];
    note.alertTitle = @"New Contacts";
    note.alertBody = reminderStr;
    note.soundName = @"reminder.caf";
    note.category = kReminderCategory;
    
//    NSDate * date1 = [NSDate dateWithTimeIntervalSince1970:60*60*(-8)+60*60*18+60*1];
    note.fireDate = fireDate;
    note.userInfo = userInfo;
    //note.repeatInterval = 0;
//    note.repeatInterval=kCFCalendarUnitDay;
    [[UIApplication sharedApplication] scheduleLocalNotification:note];
}

@end
