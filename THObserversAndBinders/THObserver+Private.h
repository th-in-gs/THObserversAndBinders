//
//  THObserver+Private.h
//  THObserversAndBinders
//
//  Created by Luis Recuenco on 16/02/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import "THObserver.h"

typedef NS_ENUM(NSUInteger, THObserverBlockArgumentsKind) {
    THObserverBlockArgumentsNone,
    THObserverBlockArgumentsOldAndNew,
    THObserverBlockArgumentsChangeDictionary
};

@interface THObserver (Private)

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                  block:(dispatch_block_t)block
     blockArgumentsKind:(THObserverBlockArgumentsKind)blockArgumentsKind;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
                 action:(SEL)action;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
         operationQueue:(NSOperationQueue *)operationQueue
          dispatchQueue:(dispatch_queue_t)dispatchQueue
                 target:(id)target
            valueAction:(SEL)valueAction;

@end
