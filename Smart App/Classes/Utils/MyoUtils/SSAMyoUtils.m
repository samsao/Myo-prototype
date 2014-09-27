//
//  SSAMyoUtils.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "SSAMyoUtils.h"

static CGFloat const kRadianMax = 48;

@implementation SSAMyoUtils

+ (NSArray *)convertedAxisFromQuaternion:(GLKQuaternion)quat
{
    float roll = atan2(2.0f * (quat.w * quat.x + quat.y * quat.z),
                       1.0f - 2.0f * (quat.x * quat.x + quat.y * quat.y));
    float pitch = asin(2.0f * (quat.w * quat.y - quat.z * quat.x));
    float yaw = atan2(2.0f * (quat.w * quat.z + quat.x * quat.y),
                      1.0f - 2.0f * (quat.y * quat.y + quat.z * quat.z));
    
    int roll_w = ((roll + (float)M_PI)/(M_PI * 2.0f) * kRadianMax);
    int pitch_w = ((pitch + (float)M_PI/2.0f)/M_PI * kRadianMax);
    int yaw_w = ((yaw + (float)M_PI)/(M_PI * 2.0f) * kRadianMax);
    
    return @[[NSNumber numberWithFloat:roll_w], [NSNumber numberWithFloat:pitch_w], [NSNumber numberWithFloat:yaw_w]];
}

@end
