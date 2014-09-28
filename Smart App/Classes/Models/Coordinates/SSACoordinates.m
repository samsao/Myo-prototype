//
//  SSACoordinates.m
//  Smart App
//
//  Created by Lukasz on 28/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSACoordinates.h"
#import "SSAMyoUtils.h"

@implementation SSACoordinates

- (instancetype)initWithCoordinates:(SSACoordinates *)coordinates
{
    self = [super init];
    if(!self) {
        return nil;
    }
    
    _roll = coordinates.roll;
    _pitch = coordinates.pitch;
    _yaw = coordinates.yaw;
    
    return self;
}

- (instancetype)initWithQuaternion:(GLKQuaternion)quaternion
{
    self = [super init];
    if(!self) {
        return nil;
    }
    
    NSArray *axises = [SSAMyoUtils convertedAxisFromQuaternion:quaternion];
    _roll = [axises[0] intValue];
    _pitch = [axises[1] intValue];
    _yaw = [axises[2] intValue];
    
    return self;
}

- (instancetype)initWithRoll:(int)roll pitch:(int)pitch yaw:(int)yaw
{
    self = [super init];
    if(!self) {
        return nil;
    }
    
    _roll = roll;
    _pitch = pitch;
    _yaw = yaw;
    
    return self;
}
@end
