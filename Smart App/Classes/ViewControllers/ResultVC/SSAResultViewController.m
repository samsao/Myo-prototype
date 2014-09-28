//
//  SSAResultViewController.m
//  Smart App
//
//  Created by Lukasz on 28/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAResultViewController.h"
#import "JBChartView/JBLineChartView.h"
#import "CHCircleGaugeView.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "SSAMyoUtils.h"
#import "NSMutableArray+SSAQueueStack.h"
#import "SSACoordinates.h"

@interface SSAResultViewController ()

@property (strong, nonatomic) JBLineChartView *lineChartView;

@end

@implementation SSAResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Result";
    self.navigationController.navigationBar.translucent = NO;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _lineChartView = [[JBLineChartView alloc] initWithFrame:CGRectMake(30, 28, 315, 254)];
    [self.view addSubview:_lineChartView];
    
    _lineChartView.delegate = self;
    _lineChartView.dataSource = self;
    _lineChartView.backgroundColor = [UIColor lightGrayColor];
    [_lineChartView setMaximumValue:60];
    [_lineChartView setMinimumValue:0];
    
    [_lineChartView reloadData];
}


# pragma mark - Graph

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
    return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    return _userMaxCoords.count;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    SSACoordinates *coord = _userMaxCoords[horizontalIndex];
    return coord.pitch;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return [UIColor redColor];
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    return 2;
}


@end
