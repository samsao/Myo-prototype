//
//  SSAExerciceViewController.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAExerciceViewController.h"
#import "JBChartView/JBLineChartView.h"
#import "CHCircleGaugeView.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "SSAMyoUtils.h"
#import "NSMutableArray+SSAQueueStack.h"
#import "SSACoordinates.h"
#import "SSAResultViewController.h"

typedef enum {
    kSSAExerciceModeBegin,
    kSSAExerciceModeAscending,
    kSSAExerciceModeDescending,
    kSSAExerciceModeFinished,
} SSAExerciceMode;

@interface SSAExerciceViewController ()

@property (weak, nonatomic) IBOutlet JBLineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *repetitionsLabel;
@property (weak, nonatomic) IBOutlet UILabel *logLabel;

@property (strong, nonatomic) CHCircleGaugeView *circleChartView;

@property (strong, nonatomic) NSMutableArray *referenceMovement;
@property (strong, nonatomic) NSMutableArray *userMovement;
@property (strong, nonatomic) NSMutableArray *userMaxCoords;
@property (strong, nonatomic) SSACoordinates *referenceMovementMaxCoord;
@property (strong, nonatomic) SSACoordinates *referenceMovementMinCoord;
@property (strong, nonatomic) SSACoordinates *userMaxReachCoord;
@property (assign, nonatomic) BOOL shouldReccord;
@property (assign, nonatomic) BOOL shouldPauseReccord;
@property (assign, nonatomic) BOOL showBothMovements;
@property (assign, nonatomic) BOOL shouldUpdateLog;
@property (assign, nonatomic) BOOL exerciceStarted;
@property (assign, nonatomic) double lastEventSeconds;
@property (assign, nonatomic) int userRepetitions;
@property (assign, nonatomic) SSAExerciceMode exerciceMode;

- (IBAction)switchValueChanged:(id)sender;
- (IBAction)startClick:(id)sender;

@end

@implementation SSAExerciceViewController

static int const kRepetitions = 5;
static int const kDescendingDeltaDetection = 5;
static int const kExerciceRemoteId = 10;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Try exercice";
    self.navigationController.navigationBar.translucent = NO;
    
    [self configureCircleChart];
    [self configureLineChart];
    
    [self updateRepetitions];
    _logLabel.text = @"Hit the start button when you are ready";
    
    [self loadExercice];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationEvent:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(didReceivePoseEvent:)
//                                                 name:TLMMyoDidReceivePoseChangedNotification
//                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMMyoDidReceiveOrientationEventNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:TLMMyoDidReceivePoseChangedNotification object:nil];
}

- (void)configureCircleChart
{
    _circleChartView = [[CHCircleGaugeView alloc] initWithFrame:_lineChartView.frame];
    [self.view addSubview:_circleChartView];
    [_circleChartView setValue:0.0 animated:YES];
}

- (void)configureLineChart
{
    _lineChartView.delegate = self;
    _lineChartView.dataSource = self;
    _lineChartView.backgroundColor = [UIColor lightGrayColor];
    [_lineChartView setMaximumValue:60];
    [_lineChartView setMinimumValue:0];
    _lineChartView.hidden = YES;
}


- (void)loadExercice
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSLog(@"Load exercice request");
    PFQuery *query = [PFQuery queryWithClassName:@"ExerciceData"];
    [query whereKey:@"typeID" equalTo:[NSNumber numberWithInt:kExerciceRemoteId]];
    query.limit = 1000;
    [query orderByAscending:@"order"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Retreived %ld objects", (long)objects.count);
        _referenceMovement = [NSMutableArray arrayWithCapacity:objects.count];
        for(PFObject *object in objects) {
            SSACoordinates *coord = [[SSACoordinates alloc] initWithRoll:[object[@"roll"] intValue] pitch:[object[@"pitch"] intValue] yaw:[object[@"yaw"] intValue]];
            [_referenceMovement addObject:coord];
        }
        
        NSLog(@"Loading finished");
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [_lineChartView reloadData];
    }];
}

- (void)updateRepetitions
{
    _repetitionsLabel.text = [NSString stringWithFormat:@"Repetitions: %d/%d", _userRepetitions, kRepetitions];
}

- (void)updateLog
{
    NSLog(@"Update logs");
    
    NSString *log;
    switch (_exerciceMode) {
        case kSSAExerciceModeBegin:
            log = @"Start exercice by resting your arm along your body. Remember to keep your arm straight all the time";
            break;
        case kSSAExerciceModeAscending:
            log = @"Elevate your arm to the max upper your head";
            break;
        case kSSAExerciceModeDescending:
            log = @"Come back to the start position";
            break;
        case kSSAExerciceModeFinished:
            if(_userRepetitions == kRepetitions) {
                log = @"Well done! Wanna try again ?";
            } else {
                log = @"Better luck next time bro";
            }
            
            break;
    }
    
    _logLabel.text = log;
}


# pragma mark - Graph

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
    return _userMovement ? 6 : 3;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    if(_userMovement) {
        return _userMovement.count;
    }
    
    return _referenceMovement ? _referenceMovement.count : 0;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    SSACoordinates *coord;
    if(lineIndex <= 2) {
        NSUInteger index = horizontalIndex;
        if(horizontalIndex > _referenceMovement.count - 1) {
            index = _referenceMovement.count - 1;
        }
        
        coord = _referenceMovement[index];
    } else {
        coord = _userMovement[horizontalIndex];
        lineIndex -= 3;
    }
    
    if(lineIndex == 0) {
        return coord.roll;
    } else if(lineIndex == 1) {
        return coord.pitch;
    } else {
        return coord.yaw;
    }
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    //    return lineIndex <= 2 ? [UIColor redColor] : [UIColor blackColor];
    BOOL alpha = _userMovement != nil;
    CGFloat alphaVal = 0.2f;
    switch (lineIndex) {
        case 0:
            return alpha ? [[UIColor redColor] colorWithAlphaComponent:alphaVal] : [UIColor redColor];
        case 1:
            return alpha ? [[UIColor greenColor] colorWithAlphaComponent:alphaVal] : [UIColor greenColor];
        case 2:
            return alpha ? [[UIColor blueColor] colorWithAlphaComponent:alphaVal] : [UIColor blueColor];
        case 3:
            return [UIColor redColor];
        case 4:
            return [UIColor greenColor];
        case 5:
        default:
            return [UIColor blueColor];
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
    
    SSACoordinates *coord = [[SSACoordinates alloc] initWithQuaternion:quat];
    
    switch (_exerciceMode) {
        case kSSAExerciceModeBegin:
            if(coord.pitch <= _referenceMovementMinCoord.pitch) {
                NSLog(@"%d <= %d", coord.pitch, _referenceMovementMinCoord.pitch);
                NSLog(@"Switch to MODE ASC from BEGIN");
                _exerciceMode = kSSAExerciceModeAscending;
                [self updateLog];
                
                [_myo vibrateWithLength:TLMVibrationLengthShort];
                _exerciceStarted = YES;
            }
            break;
            
        case kSSAExerciceModeAscending:
            if(!_userMaxReachCoord || coord.pitch > _userMaxReachCoord.pitch) {
                NSLog(@"Set max reach coord: %d", coord.pitch);
                _userMaxReachCoord = coord;
            }
            
            if(coord.pitch >= _referenceMovementMaxCoord.pitch ||
               (coord.pitch <= _userMaxReachCoord.pitch - kDescendingDeltaDetection && coord.pitch >= _referenceMovementMinCoord.pitch + kDescendingDeltaDetection)) {
                NSLog(@"%d >= %d OR %d <= %d", coord.pitch, _referenceMovementMaxCoord.pitch, coord.pitch, _userMaxReachCoord.pitch - kDescendingDeltaDetection);
                NSLog(@"Switch to MODE DESC from ASC");
                
                [_userMaxCoords addObject:coord];
                
                _userMaxReachCoord = [[SSACoordinates alloc] initWithCoordinates:_referenceMovementMinCoord];
                
                _exerciceMode = kSSAExerciceModeDescending;
                [self updateLog];
                
                [_myo vibrateWithLength:TLMVibrationLengthShort];
            }
            break;
            
        case kSSAExerciceModeDescending:
            if(coord.pitch <= _referenceMovementMinCoord.pitch) {
                NSLog(@"%d <= %d", coord.pitch, _referenceMovementMinCoord.pitch);
                NSLog(@"Switch to MODE ASC from DESC");
                _exerciceMode = kSSAExerciceModeAscending;
                _userRepetitions++;
                [self updateRepetitions];
                
                if(_userRepetitions == kRepetitions) {
                    [_startButton sendActionsForControlEvents:UIControlEventTouchUpInside];
                    [_myo vibrateWithLength:TLMVibrationLengthLong];
                } else {
                    [self updateLog];
                    [_myo vibrateWithLength:TLMVibrationLengthShort];
                }
            }
            break;
    }
    
    if(_exerciceStarted) {
        [_userMovement addObject:coord];
        
        // convert to scale of x/100
        CGFloat pitchInPercent = (CGFloat)(coord.pitch * 100.0) / (CGFloat)_referenceMovementMaxCoord.pitch;
        CGFloat val = (CGFloat)pitchInPercent / 100.0f;
        [_circleChartView setValue:val animated:YES];
        
        [_lineChartView reloadData];
    }
}


# pragma mark - Actions

- (IBAction)switchValueChanged:(id)sender
{
    _lineChartView.hidden = !_lineChartView.hidden;
    _circleChartView.hidden = !_circleChartView.hidden;
}

- (IBAction)startClick:(id)sender
{
    _shouldReccord = !_shouldReccord;
    
    // start
    if(_shouldReccord) {
        _userMovement = [NSMutableArray array];
        _userMaxCoords = [NSMutableArray array];
        
        // get pitches
        NSArray *pitches = [_referenceMovement valueForKeyPath:@"pitch"];
        
        // get max and min values
        int maxPitch = [[pitches valueForKeyPath:@"@max.intValue"] intValue] - 5;
        int minPitch = [[pitches valueForKeyPath:@"@min.intValue"] intValue] + 5;
        NSLog(@"Min: %d - Max: %d", minPitch, maxPitch);
        
        NSArray *rolls = [_referenceMovement valueForKeyPath:@"roll"];
        int maxRoll = [[rolls valueForKeyPath:@"@max.intValue"] intValue] - 5;
        int minRoll = [[rolls valueForKeyPath:@"@min.intValue"] intValue] + 5;
        
        NSArray *yaws = [_referenceMovement valueForKeyPath:@"yaw"];
        int maxYaw = [[yaws valueForKeyPath:@"@max.intValue"] intValue] - 5;
        int minYaw = [[yaws valueForKeyPath:@"@min.intValue"] intValue] + 5;
        
        _referenceMovementMinCoord = [[SSACoordinates alloc] initWithRoll:minRoll pitch:minPitch yaw:minYaw];
        _referenceMovementMaxCoord = [[SSACoordinates alloc] initWithRoll:maxRoll pitch:maxPitch yaw:maxYaw];
        
        _userRepetitions = 0;
        [self updateRepetitions];
        
        _exerciceMode = kSSAExerciceModeBegin;
        _shouldUpdateLog = YES;
        [self updateLog];
        
        _repetitionsLabel.hidden = NO;
        _logLabel.hidden = NO;
        
        [_startButton setTitle:@"Stop exercice" forState:UIControlStateNormal];
    }
    // stop
    else {
        _exerciceMode = kSSAExerciceModeFinished;
        _exerciceStarted = NO;
        
        [self updateLog];
        
        if(_userRepetitions == kRepetitions) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"See graph" style:UIBarButtonItemStylePlain target:self action:@selector(seeGraphClick)];
            self.navigationItem.rightBarButtonItem = button;
        }
        
        [_startButton setTitle:@"Restart exercice" forState:UIControlStateNormal];
    }
}

- (void)seeGraphClick
{
    SSAResultViewController *vc = [SSAResultViewController new];
    vc.userMaxCoords = _userMaxCoords;
    [self.navigationController pushViewController:vc animated:YES];
}






@end
