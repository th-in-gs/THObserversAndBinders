//
//  THObserver+Owner.m
//  THObserversAndBinders
//
//  Created by Luis Recuenco on 20/01/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import "THObserver+Owner.h"
#import <objc/runtime.h>

@implementation THObserver (Owner)

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
                block:(THObserverBlock)block
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath block:block];
    }];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
       oldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath oldAndNewBlock:block];
    }];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
              options:(NSKeyValueObservingOptions)options
          changeBlock:(THObserverBlockWithChangeDictionary)block
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath options:options changeBlock:block];
    }];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
               target:(id)target
               action:(SEL)action
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath target:target action:action];
    }];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
              options:(NSKeyValueObservingOptions)options
               target:(id)target
               action:(SEL)action
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath options:options target:target action:action];
    }];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
               target:(id)target
          valueAction:(SEL)valueAction
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath target:target valueAction:valueAction];
    }];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
              options:(NSKeyValueObservingOptions)options
               target:(id)target
          valueAction:(SEL)valueAction
{
    [self observeWithOwner:owner observerBlock:^THObserver *{
        return [self observerForObject:object keyPath:keyPath options:options target:target valueAction:valueAction];
    }];
}

#pragma mark - Private

+ (void)observeWithOwner:(id)owner observerBlock:(THObserver *(^)(void))observerBlock
{
    NSAssert(owner, @"Owner cannot be nil");
    
    [self addObserver:observerBlock() asPropertyOfOwner:owner];
}

+ (void)addObserver:(THObserver *)observer asPropertyOfOwner:(id)owner
{
    objc_setAssociatedObject(owner, (__bridge void *)observer, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
