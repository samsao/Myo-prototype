//
//  SSAResultViewController.h
//  Smart App
//
//  Created by Lukasz on 28/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JBChartView/JBLineChartView.h"

@interface SSAResultViewController : UIViewController <JBLineChartViewDelegate, JBLineChartViewDataSource>

@property (strong, nonatomic) NSArray *userMaxCoords;

@end
