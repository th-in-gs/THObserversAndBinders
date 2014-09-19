//
//  NSObject+Observers.h
//  THObserversAndBinders
//
//  Created by Maxim Khatskevich on 19/09/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THObserversAndBinders.h"

@interface NSObject (Observers)

- (void)addObserverForObject:(id)object
                     keyPath:(NSString *)keyPath
                       block:(THObserverBlock)block;

- (void)addObserverForObject:(id)object
                     keyPath:(NSString *)keyPath
              oldAndNewBlock:(THObserverBlockWithOldAndNew)block;

- (void)addObserverForObject:(id)object
                     keyPath:(NSString *)keyPath
                     options:(NSKeyValueObservingOptions)options
                 changeBlock:(THObserverBlockWithChangeDictionary)block;

- (void)removeObserversForObject:(id)object;

@end
