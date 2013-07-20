//
//  __THObserversAndBindersStorage.m
//  THObserversAndBinders
//
//  Created by Yan Rabovik on 20.07.13.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import "__THObserversStorage.h"

@implementation __THObserversStorage

+(NSMutableArray *)storage{
    static NSMutableArray *storage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        storage = [NSMutableArray array];
    });
    return storage;
}

+(void)addObject:(id)object
{
    @synchronized(self){
        [self.storage addObject:object];
    }
}

+(void)removeObject:(id)object
{
    @synchronized(self){
        [self.storage removeObject:object];
    }
}

+(NSUInteger)count
{
    @synchronized(self){
        return self.storage.count;
    }
}

@end
