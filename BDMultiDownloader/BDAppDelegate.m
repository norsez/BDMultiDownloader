//
//  BDAppDelegate.m
//  BDMultiDownloader
//
//  Created by Nor Oh on 6/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDAppDelegate.h"
#import "BDCacheDemoViewController.h"
#import "BDViewController.h"

@implementation BDAppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    BDViewController *v1 = [[BDViewController alloc] initWithStyle:UITableViewStylePlain];
    BDCacheDemoViewController *v2 = [[BDCacheDemoViewController alloc] initWithNibName:nil bundle:nil];
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = [NSArray arrayWithObjects:v1,v2, nil];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
