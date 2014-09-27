//
//  SSAStartViewController.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAStartViewController.h"
#import <MyoKit/MyoKit.h>
#import "SSAChartViewController.h"

@interface SSAStartViewController ()

@property (strong, nonatomic) TLMMyo *myo;

@end

@implementation SSAStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Smart app";
    
    [self connectMyo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveConnectionEvent:)
                                                 name:TLMHubDidConnectDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDisconnectEvent:)
                                                 name:TLMHubDidDisconnectDeviceNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMHubDidConnectDeviceNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMHubDidDisconnectDeviceNotification object:nil];
}

- (void)connectMyo
{
    NSLog(@"Connecting to adjacent myo");
    [[TLMHub sharedHub] attachToAdjacent];
}


# pragma mark - Notifications

- (void)didReceiveConnectionEvent:(NSNotification*)notification
{
    NSLog(@"Connection event");
    NSArray *devices = [[TLMHub sharedHub] myoDevices];
    if(devices.count == 0) {
        NSLog(@"Cannot find device");
        return;
    }
    
    _myo = devices[0];
    NSLog(@"Myo connected: %@ - %@", _myo.name, [_myo.identifier UUIDString]);
    
    [self.navigationController pushViewController:[SSAChartViewController new] animated:YES];
}

- (void)didReceiveDisconnectEvent:(NSNotification*)notification
{
    NSLog(@"Disconnect event");
    
    _myo = nil;
}

@end
