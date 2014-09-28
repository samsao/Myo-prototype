//
//  AppDelegate.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "AppDelegate.h"
#import <MyoKit/MyoKit.h>
#import "SSAStartViewController.h"
#import <Parse/Parse.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TLMHub sharedHub];
    [TLMHub sharedHub].applicationIdentifier = @"com.samsao.smartapp";
    
    [Parse setApplicationId:@"UL1HrX8pATNbmoEfREItjPf9ZVWT5hsc0cSw0Y1T"
                  clientKey:@"YwqY4N5NnBxZ3YVaNoMCvX4QkKLcP0AS0TXaUyHE"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UINavigationController *vc = [[UINavigationController alloc] initWithRootViewController:[SSAStartViewController new]];
    
    self.window.rootViewController = vc;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
