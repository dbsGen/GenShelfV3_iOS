//
//  AppDelegate.m
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "AppDelegate.h"
#import "GSHomeController.h"
#include <utils/FileSystem.h>
#include <utils/NotificationCenter.h>
#import "load_classes.h"
#include <core/Array.h>
#import "RKDropdownAlert.h"
#include "Common/Models/Settings.h"
#import "GSAnalysis.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    GS_load_classes();
    gr::FileSystem::getInstance()->setResourcePath([NSBundle mainBundle].resourcePath.UTF8String);
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"%@", path);
    gr::FileSystem::getInstance()->setStoragePath(path.UTF8String);
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    GSHomeController *menu = [[GSHomeController alloc] init];
    self.window.rootViewController = menu;
    [self.window makeKeyAndVisible];
    
    [GSAnalysis run];
    
    gr::NotificationCenter::getInstance()->listen(nl::Settings::NOTIFICATION_SHOW_MESSAGE, C([](const char *str){
        [RKDropdownAlert title:[NSString stringWithUTF8String:str]
                          time:2];
    }));
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
