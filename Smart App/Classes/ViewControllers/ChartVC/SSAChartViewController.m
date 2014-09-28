//
//  SSAChartViewController.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAChartViewController.h"
#import <MyoKit/MyoKit.h>
#import "SSAMyoUtils.h"
#import "NSMutableArray+SSAQueueStack.h"

@interface SSAChartViewController ()

@property (weak, nonatomic) IBOutlet JBLineChartView *graphView;
@property (weak, nonatomic) IBOutlet UIButton *reccordButton;
@property (weak, nonatomic) IBOutlet UILabel *logLabel;

@property (strong, nonatomic) NSMutableArray *movement;
@property (strong, nonatomic) NSArray *referenceAxises;
@property (assign, nonatomic) BOOL shouldReccord;
@property (assign, nonatomic) BOOL shouldPauseReccord;
@property (assign, nonatomic) double lastEventSeconds;

- (IBAction)reccordClick:(id)sender;

@end

@implementation SSAChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Tracker";
    self.navigationController.navigationBar.translucent = NO;
    
    _graphView.delegate = self;
    _graphView.dataSource = self;
    _graphView.backgroundColor = [UIColor lightGrayColor];
    [_graphView setMaximumValue:70];
    [_graphView setMinimumValue:0];
    
    // rotation 90 degrees
//    _graphView.transform = CGAffineTransformMakeRotation(M_PI_2);
//    _graphView.frame = CGRectMake(8, 8, _graphView.frame.size.height, _graphView.frame.size.width);
    
    _lastEventSeconds = [[NSDate new] timeIntervalSince1970];
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
    return _referenceAxises ? 6 : 3;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    return _movement ? _movement.count : 0;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    NSArray *axises;
    NSUInteger index;
    if(_referenceAxises && lineIndex <= 2) {
        axises = _referenceAxises;
    } else {
        axises = _movement[horizontalIndex];
    }
    
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
    if(_movement.count > 60) {
        [_movement queuePop];
    }
    
    [_movement addObject:axises];
    
    [_graphView reloadData];
}

- (void)didReceivePoseChange:(NSNotification*)notification
{
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    switch (pose.type) {
        case TLMPoseTypeFist:
            if(_shouldReccord) {
                _shouldPauseReccord = YES;
            }
            break;
        case TLMPoseTypeWaveIn:
            [_reccordButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
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
        _movement = [NSMutableArray array];
        
        // set reference point
        if(!_referenceAxises) {
            _logLabel.text = @"Configure the reference point";
            [_reccordButton setTitle:@"Save reference point" forState:UIControlStateNormal];
        }
        // start reccord
        else {
            _logLabel.text = @"Tracking the movement";
            [_reccordButton setTitle:@"Stop tracking" forState:UIControlStateNormal];
        }
        
    } else {
        // reference point saved
        if(!_referenceAxises) {
            _referenceAxises = [_movement lastObject];
            _movement = nil;
            
            _logLabel.text = @"";
            [_reccordButton setTitle:@"Start tracking" forState:UIControlStateNormal];
        }
        // tracking finished
        else {
            _movement = nil;
            _logLabel.text = @"Tracking finshed";
            [_reccordButton setTitle:@"Start tracking" forState:UIControlStateNormal];
        }
        
        
    }
    
    
}

@end
