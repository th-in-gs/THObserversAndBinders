//
//  NSObject+Observers.m
//  THObserversAndBinders
//
//  Created by Maxim Khatskevich on 12/10/13.
//  Copyright (c) 2013 Maxim Khatskevich. All rights reserved.
//

#import "NSObject+Observers.h"
#import <objc/runtime.h>

static void *ObserverListKey;

@implementation NSObject (Observers)

#pragma mark - Property accessors

- (NSMutableArray *)observerList
{
    @synchronized(self)
    {
        NSMutableArray *result =
        objc_getAssociatedObject(self, &ObserverListKey);
        
        //===
        
        if (!result)
        {
            result = [NSMutableArray array];
            
            objc_setAssociatedObject(self,
                                     &ObserverListKey,
                                     result,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        //===
        
        return result;
    }
}

#pragma mark - Helpers

- (void)removeObservers
{
    @synchronized(self)
    {
        [self.observerList makeObjectsPerformSelector:@selector(stopObserving)];
        [self.observerList removeAllObjects];
        
        //===
        
        objc_setAssociatedObject(self,
                                 &ObserverListKey,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
