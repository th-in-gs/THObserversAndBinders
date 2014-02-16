//
//  THObserver+CallbackQueue.m
//  THObserversAndBinders
//
//  Created by Luis Recuenco on 16/02/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import "THObserver+CallbackQueue.h"
#import "THObserver+Private.h"

@implementation THObserver (CallbackQueue)

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
                  block:(THObserverBlock)block
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:0
                    operationQueue:operationQueue
                     dispatchQueue:nil
                             block:(dispatch_block_t)block
                blockArgumentsKind:THObserverBlockArgumentsNone];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                  block:(THObserverBlock)block
{
    return [self observerForObject:object
                               keyPath:keyPath
                               options:0
                        operationQueue:nil
                         dispatchQueue:dispatchQueue
                                 block:(dispatch_block_t)block
                    blockArgumentsKind:THObserverBlockArgumentsNone];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    operationQueue:operationQueue
                     dispatchQueue:nil
                             block:(dispatch_block_t)block
                blockArgumentsKind:THObserverBlockArgumentsOldAndNew];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    operationQueue:nil
                     dispatchQueue:dispatchQueue
                             block:(dispatch_block_t)block
                blockArgumentsKind:THObserverBlockArgumentsOldAndNew];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
            changeBlock:(THObserverBlockWithChangeDictionary)block
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:options
                    operationQueue:operationQueue
                     dispatchQueue:nil
                             block:(dispatch_block_t)block
                blockArgumentsKind:THObserverBlockArgumentsChangeDictionary];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
          dispatchQueue:(dispatch_queue_t)dispatchQueue
            changeBlock:(THObserverBlockWithChangeDictionary)block
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:options
                    operationQueue:nil
                     dispatchQueue:dispatchQueue
                             block:(dispatch_block_t)block
                blockArgumentsKind:THObserverBlockArgumentsChangeDictionary];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
                 action:(SEL)action
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:0
                    operationQueue:operationQueue
                     dispatchQueue:nil
                            target:target
                            action:action];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
                 action:(SEL)action
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:0
                    operationQueue:nil
                     dispatchQueue:dispatchQueue
                            target:target
                            action:action];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
                 action:(SEL)action
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:options
                    operationQueue:operationQueue
                     dispatchQueue:nil
                            target:target
                            action:action];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
                 action:(SEL)action
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:options
                    operationQueue:nil
                     dispatchQueue:dispatchQueue
                            target:target
                            action:action];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
            valueAction:(SEL)valueAction
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:0
                    operationQueue:operationQueue
                     dispatchQueue:nil
                            target:target
                       valueAction:valueAction];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
            valueAction:(SEL)valueAction
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:0
                    operationQueue:nil
                     dispatchQueue:dispatchQueue
                            target:target
                       valueAction:valueAction];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
            valueAction:(SEL)valueAction
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:options
                    operationQueue:operationQueue
                     dispatchQueue:nil
                            target:target
                       valueAction:valueAction];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
            valueAction:(SEL)valueAction
{
    return [self observerForObject:object
                           keyPath:keyPath
                           options:options
                    operationQueue:nil
                     dispatchQueue:dispatchQueue
                            target:target
                       valueAction:valueAction];
}

@end
