//
//  SSAReccordViewController.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAReccordViewController.h"
#import <MyoKit/MyoKit.h>
#import "SSAMyoUtils.h"
#import "NSMutableArray+SSAQueueStack.h"
#import <Parse/Parse.h>

@interface SSAReccordViewController ()

@property (weak, nonatomic) IBOutlet JBLineChartView *graphView;
@property (weak, nonatomic) IBOutlet UIButton *reccordButton;
@property (weak, nonatomic) IBOutlet UIButton *rotateButton;

@property (strong, nonatomic) NSMutableArray *liveMovement;
@property (strong, nonatomic) NSMutableArray *reccordMovement;

@property (assign, nonatomic) BOOL shouldReccord;
@property (assign, nonatomic) BOOL shouldPauseReccord;
@property (assign, nonatomic) BOOL verticalGraph;
@property (assign, nonatomic) double lastEventSeconds;

- (IBAction)reccordClick:(id)sender;
- (IBAction)rotateClick:(id)sender;

@end

@implementation SSAReccordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Reccord";
    self.navigationController.navigationBar.translucent = NO;
    
    _graphView.delegate = self;
    _graphView.dataSource = self;
    _graphView.backgroundColor = [UIColor lightGrayColor];
    [_graphView setMaximumValue:60];
    [_graphView setMinimumValue:0];
    
    _lastEventSeconds = [[NSDate new] timeIntervalSince1970];
    
    [_reccordButton setTitle:@"Start reccord" forState:UIControlStateNormal];
    [_rotateButton setTitle:@"Rotate vertical" forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationEvent:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseEvent:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMMyoDidReceiveOrientationEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMMyoDidReceivePoseChangedNotification object:nil];
}


# pragma mark - Graph

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
    return 3;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    return _reccordMovement ? _reccordMovement.count : 0;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    NSArray *axises = _reccordMovement[horizontalIndex];
    return [axises[lineIndex] floatValue];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    //    return lineIndex <= 2 ? [UIColor redColor] : [UIColor blackColor];
    
    switch (lineIndex) {
        case 0:
            return [UIColor redColor];
            break;
        case 1:
            return [UIColor greenColor];
            break;
        case 2:
        default:
            return [UIColor blueColor];
            break;
    }
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    return 2;
}


# pragma mark - Notifications

- (void)didReceiveOrientationEvent:(NSNotification*)notification
{
    if(!_shouldReccord) {
        return;
    }
    
    if(_shouldPauseReccord) {
        return;
    }
    
    double time = [[NSDate date] timeIntervalSince1970];
    if(time - _lastEventSeconds < 0.03) {
        return;
    }
    _lastEventSeconds = time;
    
    
    TLMOrientationEvent *orientation = notification.userInfo[kTLMKeyOrientationEvent];
    GLKQuaternion quat = orientation.quaternion;
    
    
    NSArray *axises = [SSAMyoUtils convertedAxisFromQuaternion:quat];
    if(_liveMovement.count > 60) {
        [_liveMovement queuePop];
    }
    
    [_liveMovement addObject:axises];
    [_reccordMovement addObject:axises];
    
    [_graphView reloadData];
}

- (void)didReceivePoseEvent:(NSNotification*)notification
{
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    switch (pose.type) {
        case TLMPoseTypeFist:
            if(_shouldReccord) {
                _shouldPauseReccord = YES;
            }
            break;
//        case TLMPoseTypeWaveIn:
//            [_reccordButton sendActionsForControlEvents:UIControlEventTouchUpInside];
//            break;
        case TLMPoseTypeFingersSpread:
            if(_shouldReccord) {
                _shouldPauseReccord = NO;
            }
            break;
    }
}



# pragma mark - Actions

- (IBAction)reccordClick:(id)sender
{
    _shouldReccord = !_shouldReccord;
    
    if(_shouldReccord) {
        if(!_liveMovement) {
            _liveMovement = [NSMutableArray array];
            _reccordMovement = [NSMutableArray array];
            
            [_reccordButton setTitle:@"Stop reccord" forState:UIControlStateNormal];
        }
        // send data
        else {
            _shouldReccord = NO;
            
            NSMutableArray *objects = [NSMutableArray arrayWithCapacity:_reccordMovement.count];
            int order = 0;
            for(NSArray *axises in _reccordMovement) {
                PFObject *object = [PFObject objectWithClassName:@"ExerciceData"];
                object[@"type"] = @"Frontal elevation";
                object[@"typeID"] = @10;
                object[@"roll"] = axises[0];
                object[@"pitch"] = axises[1];
                object[@"yaw"] = axises[2];
                object[@"order"] = [NSNumber numberWithInt:order];
                [objects addObject:object];
                
                order++;
            }
            
            NSLog(@"Retreiving existing exercice");
            PFQuery *query = [PFQuery queryWithClassName:@"ExerciceData"];
            [query whereKey:@"typeID" equalTo:@10];
            query.limit = 1000;
            [query findObjectsInBackgroundWithBlock:^(NSArray *existingObjects, NSError *error) {
                NSLog(@"Deleting %ld existing objects", (long)existingObjects.count);
                [PFObject deleteAllInBackground:existingObjects block:^(BOOL succeeded, NSError *error) {
                    NSLog(@"Deleted with success: %d", succeeded);
                    if(!succeeded) {
                        return;
                    }
                    
                    NSLog(@"Sending data (%ld objects)", (long)objects.count);
                    _reccordButton.enabled = NO;
                    
                    [PFObject saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
                        NSLog(@"Sent with success: %d", succeeded);
                        
                        _liveMovement = nil;
                        _reccordMovement = nil;
                        
                        _reccordButton.enabled = YES;
                        [_reccordButton setTitle:@"Start reccord" forState:UIControlStateNormal];
                    }];
                }];
            }];
        }
        
    } else {
        [_reccordButton setTitle:@"Send data" forState:UIControlStateNormal];
    }
}

- (IBAction)rotateClick:(id)sender
{
    _verticalGraph = !_verticalGraph;
    
    CGFloat angle;
    NSString *title;
    if(_verticalGraph) {
        angle = M_PI_2;
        title = @"Rotate horizontal";
    } else {
        angle = 2 * M_PI;
        title = @"Rotate vertical";
    }
    
    _graphView.transform = CGAffineTransformMakeRotation(angle);
    _graphView.frame = CGRectMake(8, 8, _graphView.frame.size.height, _graphView.frame.size.width);
    
    [_rotateButton setTitle:title forState:UIControlStateNormal];
}

@end
