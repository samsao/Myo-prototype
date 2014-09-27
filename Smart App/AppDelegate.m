//
//  AppDelegate.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "AppDelegate.h"
#import <MyoKit/MyoKit.h>
#import "SSAHomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TLMHub sharedHub];
    [TLMHub sharedHub].applicationIdentifier = @"com.samsao.smartapp";

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UINavigationController *vc = [[UINavigationController alloc] initWithRootViewController:[SSAHomeViewController new]];;
    
    self.window.rootViewController = vc;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
