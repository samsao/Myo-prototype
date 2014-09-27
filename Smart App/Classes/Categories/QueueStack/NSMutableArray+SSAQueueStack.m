//
//  NSMutableArray+SSAQueueStack.m
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import "NSMutableArray+SSAQueueStack.h"

@implementation NSMutableArray (SSAQueueStack)

-(id)queuePop
{
    if ([self count] == 0) {
        return nil;
    }
    
    id queueObject = [self objectAtIndex:0];
    
    [self removeObjectAtIndex:0];
    
    return queueObject;
}


-(void)queuePush:(id)anObject
{
    [self addObject:anObject];
}


-(id)stackPop
{
    id lastObject = [self lastObject];
    
    if (lastObject)
        [self removeLastObject];
    
    return lastObject;
}

-(void)stackPush:(id)obj
{
    [self addObject: obj];
}

@end
