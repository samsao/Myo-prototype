//
//  SSAMyoUtils.h
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MyoKit/MyoKit.h>

@interface SSAMyoUtils : NSObject

+ (NSArray *)convertedAxisFromQuaternion:(GLKQuaternion)quat;

@end
