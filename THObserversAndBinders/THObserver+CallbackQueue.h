//
//  THObserver+CallbackQueue.h
//  THObserversAndBinders
//
//  Created by Luis Recuenco on 16/02/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import "THObserver.h"

@interface THObserver (CallbackQueue)

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
                  block:(THObserverBlock)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                  block:(THObserverBlock)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
            changeBlock:(THObserverBlockWithChangeDictionary)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
          dispatchQueue:(dispatch_queue_t)dispatchQueue
            changeBlock:(THObserverBlockWithChangeDictionary)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
                 action:(SEL)action;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
                 action:(SEL)action;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
                 action:(SEL)action;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
                 action:(SEL)action;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
            valueAction:(SEL)valueAction;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
            valueAction:(SEL)valueAction;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
                 target:(id)target
            valueAction:(SEL)valueAction;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
            valueAction:(SEL)valueAction;

@end
