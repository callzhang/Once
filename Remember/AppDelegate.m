//
//  AppDelegate.m
//  Contacts Reminder
//
//  Created by Lee on 11/9/14.
//  Copyright (c) 2014 Lee. All rights reserved.
//

#import "AppDelegate.h"
#import "NSDate+Extend.h"
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
    //[Parse setApplicationId:kParseApplicationId clientKey:kParseClientKey];
    
    //background fetch
#ifdef DEBUG
	[application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
#else
    [application setMinimumBackgroundFetchInterval:3600*2];
#endif
	
    //manager
    [CRContactsManager sharedManager];
    
    //push
    /*
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeNone;
	UIMutableUserNotificationAction *notes = [UIMutableUserNotificationAction new];
	notes.activationMode = UIUserNotificationActivationModeForeground;
	notes.authenticationRequired = NO;
    notes.title = @"Notes";
	//this button doesn't bring the app to theh foreground but activates the app in background
	UIMutableUserNotificationAction *later = [UIMutableUserNotificationAction new];
	later.activationMode = UIUserNotificationActivationModeBackground;
	later.authenticationRequired = NO;
    later.title = @"Later";
	UIMutableUserNotificationAction *cancel = [UIMutableUserNotificationAction new];
	cancel.activationMode = UIUserNotificationActivationModeBackground;
	cancel.authenticationRequired = NO;
	cancel.destructive = YES;
    cancel.title = @"Cancel";
	UIMutableUserNotificationCategory *category = [UIMutableUserNotificationCategory new];
	[category setActions:@[notes, later, cancel] forContext:UIUserNotificationActionContextDefault];
	[category setActions:@[notes, cancel] forContext:UIUserNotificationActionContextMinimal];
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObjects:category, nil]];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
     */
    return YES;
}


#pragma Push notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    DDLogInfo(@"Push token: %@", deviceToken);
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    DDLogInfo(@"Failed to register push: %@", error.description);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    DDLogInfo(@"Received push notification: %@", userInfo);
    [PFPush handlePush:userInfo];
}

#pragma mark - Background fetch


#pragma mark - Background fetch method (this is called periodocially
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogInfo(@"======== Launched in background due to background fetch event ==========");
    CRContactsManager *manager = [CRContactsManager sharedManager];
	//[manager scheduleReactivateLocalNotification];
    [manager checkNewContactsAndNotifyWithCompletion:^(NSArray *newContacts) {
		//log info
        NSMutableString *str = [NSMutableString stringWithFormat:@"=====> Remember checked new contact at %@.", [NSDate date].string];
        if (newContacts.count > 0) {
            [str appendFormat:@" And found %ld new contacts", (long)newContacts.count];
        }
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
	
	//instantiate the action
	UIMutableUserNotificationAction *likeAction = [UIMutableUserNotificationAction new];
	
	// set an identifier for the action, this is used to differentiate actions from eachother when the notifiaction action handler method is called
	likeAction.identifier = @"LIKE_ACTION_IDENTIFIER";
	
	// Set the Title.. here we find the unicode value of the "thumbs up" emoji that the will appear inside the button corresponding to this action inside the push notification
	likeAction.title = @"\U0001F44D";
	
	// If this is set to destructive, the background color of the button corresponding to this action will be red, otherwise it will be blue
	likeAction.destructive = NO;
	
	// UIUserActivationMode is used to tell the system whether it should bring your app into the foregroudn, or leave it in the background, in this case, the app can complete the request to update our backed in the background, so we don't have to open the app
	likeAction.activationMode = UIUserNotificationActivationModeBackground;
	
	
	
	// CREATE THE CATEGORY
	
	// instantiate the category
	UIMutableUserNotificationCategory *postCategory = [UIMutableUserNotificationCategory new];
	
	// set its identifier. The APS dictionary you send for your push notifications must have a key named 'category' whose object is set to a string that matches this identifier in order for you actions to appear.
	postCategory.identifier = @"POST_CATEGORY";
	
	// set the actions that are associated with this type of push notification category
	// you can use the UIUserNotificationActionContext to determine which actions will show up in different
	// push notification presentation contexts, for example, on the lock screen, as a banner notification, or as an alert view notification
	[postCategory setActions:@[likeAction]
				  forContext:UIUserNotificationActionContextDefault];
	
	
	// REGISTER THE CATEGORY
	NSSet *categorySet = [NSSet setWithObjects:postCategory, nil];
	UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert
																			 categories:categorySet];
	
	[[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}


// In your app delegate, override this method
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
 
	if ([identifier isEqualToString:@"LIKE_ACTION_IDENTIFIER"]){
		
		
	}
	if(completionHandler)    //Finally call completion handler if its not nil
		completionHandler();
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler {
	
	// Handle actions of location notifications here. You can identify the action by using "identifier" and perform appropriate operations
	
	if(completionHandler)    //Finally call completion handler if its not nil
		completionHandler();
}

@end
