//
//  SSAExerciceViewController.h
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JBChartView/JBLineChartView.h"
#import <MyoKit/MyoKit.h>

@interface SSAExerciceViewController : UIViewController <JBLineChartViewDelegate, JBLineChartViewDataSource>

@property (strong, nonatomic) TLMMyo *myo;

@end
