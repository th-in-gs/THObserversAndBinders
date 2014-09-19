//
//  NSObject+Observers.m
//  THObserversAndBinders
//
//  Created by Maxim Khatskevich on 19/09/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import "NSObject+Observers.h"
#import <objc/runtime.h>

static void *ObserversKey;

//===

@implementation NSObject (Observers)

#pragma mark - Property accessors

- (NSMapTable *)observers
{
    NSMapTable *result =
    objc_getAssociatedObject(self, &ObserversKey);
    
    //===
    
    if (!result)
    {
        result = [NSMapTable weakToStrongObjectsMapTable];
        
        objc_setAssociatedObject(self,
                                 &ObserversKey,
                                 result,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    //===
    
    return result;
}

#pragma mark - Private

- (void)storeObserver:(THObserver *)observer forObject:(id)object
{
    id theKey = object;
    
    NSMutableArray *relatedObservers = [self.observers objectForKey:theKey];
    
    if (!relatedObservers)
    {
        relatedObservers = [NSMutableArray array];
    }
    
    [relatedObservers addObject:observer];
    
    [self.observers setObject:relatedObservers forKey:theKey];
}

#pragma mark - Public

- (void)addObserverForObject:(id)object
                     keyPath:(NSString *)keyPath
                       block:(THObserverBlock)block
{
    THObserver *observer =
    [THObserver
     observerForObject:object
     keyPath:keyPath
     block:block];
    
    [self storeObserver:observer forObject:object];
}

- (void)addObserverForObject:(id)object
                     keyPath:(NSString *)keyPath
              oldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    THObserver *observer =
    [THObserver
     observerForObject:object
     keyPath:keyPath
     oldAndNewBlock:block];
    
    [self storeObserver:observer forObject:object];
}

- (void)addObserverForObject:(id)object
                     keyPath:(NSString *)keyPath
                     options:(NSKeyValueObservingOptions)options
                 changeBlock:(THObserverBlockWithChangeDictionary)block
{
    THObserver *observer =
    [THObserver
     observerForObject:object
     keyPath:keyPath
     options:options
     changeBlock:block];
    
    [self storeObserver:observer forObject:object];
}

- (void)removeObserversForObject:(id)object
{
    [self.observers removeObjectForKey:object];
}

@end
