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
#import <MyoKit/MyoKit.h>
#import "SSAMyoUtils.h"
#import "NSMutableArray+SSAQueueStack.h"

@interface SSAExerciceViewController ()

@property (weak, nonatomic) IBOutlet JBLineChartView *lineChartView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) CHCircleGaugeView *circleChartView;

@property (strong, nonatomic) NSMutableArray *referenceMovement;
@property (strong, nonatomic) NSMutableArray *userMovement;
@property (assign, nonatomic) BOOL shouldReccord;
@property (assign, nonatomic) BOOL shouldPauseReccord;
@property (assign, nonatomic) BOOL showBothMovements;
@property (assign, nonatomic) double lastEventSeconds;

- (IBAction)switchValueChanged:(id)sender;
- (IBAction)startClick:(id)sender;

@end

@implementation SSAExerciceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Try exercice";
    self.navigationController.navigationBar.translucent = NO;
    
    _lineChartView.delegate = self;
    _lineChartView.dataSource = self;
    _lineChartView.backgroundColor = [UIColor lightGrayColor];
    [_lineChartView setMaximumValue:60];
    [_lineChartView setMinimumValue:0];
    _lineChartView.hidden = YES;
    
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
}


- (void)loadExercice
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSLog(@"Load exercice request");
    PFQuery *query = [PFQuery queryWithClassName:@"ExerciceData"];
    [query whereKey:@"typeID" equalTo:@10];
    query.limit = 1000;
    [query orderByAscending:@"order"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Retreived %ld objects", (long)objects.count);
        _referenceMovement = [NSMutableArray arrayWithCapacity:objects.count];
        for(PFObject *object in objects) {
            NSArray *axises = @[object[@"roll"], object[@"pitch"], object[@"yaw"]];
            [_referenceMovement addObject:axises];
        }
        
        NSLog(@"Loading finished");
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        [_lineChartView reloadData];
    }];
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
    if(lineIndex <= 2) {
        NSUInteger index = horizontalIndex;
        if(horizontalIndex > _referenceMovement.count - 1) {
            index = _referenceMovement.count - 1;
        }
        NSArray *axises = _referenceMovement[index];
        return [axises[lineIndex] floatValue];
    }
    
    NSArray *axises = _userMovement[horizontalIndex];
    return [axises[lineIndex - 3] floatValue];
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
    
    
    NSArray *axises = [SSAMyoUtils convertedAxisFromQuaternion:quat];
    [_userMovement addObject:axises];
    
    [_lineChartView reloadData];
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
    
    if(_shouldReccord) {
        _userMovement = [NSMutableArray array];
        [_startButton setTitle:@"Stop exercice" forState:UIControlStateNormal];
    } else {
        [_startButton setTitle:@"Restart exercice" forState:UIControlStateNormal];
    }
}

@end
