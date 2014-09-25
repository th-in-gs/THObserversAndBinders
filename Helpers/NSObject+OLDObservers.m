//
//  NSObject+Observers.m
//  THObserversAndBinders
//
//  Created by Maxim Khatskevich on 12/10/13.
//  Copyright (c) 2013 Maxim Khatskevich. All rights reserved.
//

#import "NSObject+OLDObservers.h"
#import <objc/runtime.h>

static void *ObserverListKey;
static void *BinderListKey;

@implementation NSObject (OLDObservers)

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

- (NSMutableArray *)binderList
{
    @synchronized(self)
    {
        NSMutableArray *result =
        objc_getAssociatedObject(self, &BinderListKey);
        
        //===
        
        if (!result)
        {
            result = [NSMutableArray array];
            
            objc_setAssociatedObject(self,
                                     &BinderListKey,
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
        for (id item in self.observerList)
        {
            if ([item isKindOfClass:[THObserver class]])
            {
                [(THObserver *)item stopObserving];
            }
        }
        
        //===
        
        [self.observerList removeAllObjects];
        
        //===
        
        objc_setAssociatedObject(self,
                                 &ObserverListKey,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)removeBinders
{
    @synchronized(self)
    {
        for (id item in self.observerList)
        {
            if ([item isKindOfClass:[THBinder class]])
            {
                [(THBinder *)item stopBinding];
            }
        }
        
        //===
        
        [self.binderList removeAllObjects];
        
        //===
        
        objc_setAssociatedObject(self,
                                 &BinderListKey,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)removeObserversAndBinders
{
    [self removeObservers];
    [self removeBinders];
}

@end
