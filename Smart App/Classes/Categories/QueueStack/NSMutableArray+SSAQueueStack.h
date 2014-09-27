//
//  NSMutableArray+SSAQueueStack.h
//  Smart App
//
//  Created by Lukasz on 27/09/14.
//  Copyright (c) 2014 Samsao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (SSAQueueStack)

-(id)queuePop;
-(void)queuePush:(id)obj;
-(id)stackPop;
-(void)stackPush:(id)obj;

@end
