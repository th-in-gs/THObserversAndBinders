//
//  __THObserversAndBindersStorage.h
//  THObserversAndBinders
//
//  Created by Yan Rabovik on 20.07.13.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface __THObserversStorage : NSObject

+(void)addObject:(id)object;
+(void)removeObject:(id)object;
+(NSUInteger)count;

@end
