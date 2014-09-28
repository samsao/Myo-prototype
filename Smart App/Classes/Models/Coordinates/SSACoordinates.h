//
//  SSACoordinates.h
//  Smart App
//
//  Created by Lukasz on 28/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MyoKit/MyoKit.h>

@interface SSACoordinates : NSObject

@property (assign, nonatomic) int roll;
@property (assign, nonatomic) int pitch;
@property (assign, nonatomic) int yaw;

- (instancetype)initWithCoordinates:(SSACoordinates *)coordinates;
- (instancetype)initWithQuaternion:(GLKQuaternion)quaternion;
- (instancetype)initWithRoll:(int)roll pitch:(int)pitch yaw:(int)yaw;

@end
