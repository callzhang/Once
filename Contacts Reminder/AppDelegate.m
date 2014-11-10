//
//  AppDelegate.m
//  Contacts Reminder
//
//  Created by Lee on 11/9/14.
//  Copyright (c) 2014 Lee. All rights reserved.
//

#import "AppDelegate.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "CRContactsManager.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //core data
    //[MagicalRecord setupCoreDataStack];
    //[MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelWarn];
    
    //parse
    [Parse setApplicationId:@"xqiXF3hnqiLXFFkcE3pYs3b2oBORjSdJRiQdKCPK" clientKey:@"NOT06QA8LdXXLQjUmGKBHs6RWO1qPvrEyJUURxOI"];
    
    //background fetch
    [application setMinimumBackgroundFetchInterval:3600*8];
    
    //manager
    [CRContactsManager sharedManager];
    
    //push
#if !TARGET_IPHONE_SIMULATOR
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    return YES;
}


#pragma Push notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSLog(@"Push token: %@", deviceToken);
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"Failed to register push: %@", error.description);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"Received push notification: %@", userInfo);
    [PFPush handlePush:userInfo];
}

#pragma mark - Background fetch


#pragma mark - Background fetch method (this is called periodocially
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"======== Launched in background due to background fetch event ==========");
    CRContactsManager *manager = [CRContactsManager sharedManager];
    NSArray *newContacts = [manager newContactsSinceLastCheck];
    if (newContacts) {
        //find new!
        UILocalNotification *note = [UILocalNotification new];
        note.alertBody = @"Found new alert! This message will delay 24 hours in release mode.";
        note.soundName = @"default";
        [application scheduleLocalNotification:note];
    }
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


@end
