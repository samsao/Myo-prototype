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
#import "SSAReccordViewController.h"
#import <Parse/Parse.h>
#import "SSAExerciceViewController.h"

@interface SSAStartViewController ()

@property (strong, nonatomic) TLMMyo *myo;
@property (weak, nonatomic) IBOutlet UILabel *connectingLabel;
@property (weak, nonatomic) IBOutlet UIButton *reccordExerciceButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteTestDataButton;
@property (weak, nonatomic) IBOutlet UIButton *exerciceButton;

- (IBAction)reccordExerciceClick:(id)sender;
- (IBAction)deleteTestDataClick:(id)sender;
- (IBAction)exerciceClick:(id)sender;

@end

@implementation SSAStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Smart app";
    self.navigationController.navigationBar.translucent = NO;
    
    _reccordExerciceButton.hidden = YES;
    _deleteTestDataButton.hidden = YES;
    _exerciceButton.hidden = YES;
    _connectingLabel.text = @"Connecting to Myo...";
    
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
    
    _connectingLabel.text = @"You are now connected to Myo";
    _reccordExerciceButton.hidden = NO;
    _deleteTestDataButton.hidden = NO;
    _exerciceButton.hidden = NO;
}

- (void)didReceiveDisconnectEvent:(NSNotification*)notification
{
    NSLog(@"Disconnect event");
    
    _myo = nil;
    
    _connectingLabel.text = @"Deconnected from Myo";
    _reccordExerciceButton.hidden = YES;
    _deleteTestDataButton.hidden = YES;
    _exerciceButton.hidden = YES;
}

- (IBAction)reccordExerciceClick:(id)sender
{
    [self.navigationController pushViewController:[SSAReccordViewController new] animated:YES];
}

- (IBAction)deleteTestDataClick:(id)sender
{
    NSLog(@"Retreiving existing exercice");
    PFQuery *query = [PFQuery queryWithClassName:@"ExerciceData"];
    [query whereKey:@"typeID" equalTo:@99];
    query.limit = 1000;
    [query findObjectsInBackgroundWithBlock:^(NSArray *existingObjects, NSError *error) {
        NSLog(@"Deleting %ld existing objects", (long)existingObjects.count);
        [PFObject deleteAllInBackground:existingObjects block:^(BOOL succeeded, NSError *error) {
            NSLog(@"Deleted with success: %d", succeeded);
        }];
    }];
}

- (IBAction)exerciceClick:(id)sender
{
    [self.navigationController pushViewController:[SSAExerciceViewController new] animated:YES];
}


@end
