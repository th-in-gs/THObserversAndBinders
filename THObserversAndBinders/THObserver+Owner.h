//
//  THObserver+Owner.h
//  THObserversAndBinders
//
//  Created by Luis Recuenco on 20/01/14.
//  Copyright (c) 2014 James Montgomerie. All rights reserved.
//

#import "THObserver.h"

/**
 This class aims at creating a clean and easy way to avoid holding
 the observer strongly to unsubscribe later, this is, a sort of automatic
 deregistration. The anonymous observer will be created under the hood and 
 attached to the owner via associated objects. When the owner is released,
 so will be the observer. This simple technique avoids more obscure ways like 
 method swizzling or method forwarding to achieve so.
 */
@interface THObserver (Owner)

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
                block:(THObserverBlock)block;

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
       oldAndNewBlock:(THObserverBlockWithOldAndNew)block;

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
              options:(NSKeyValueObservingOptions)options
          changeBlock:(THObserverBlockWithChangeDictionary)block;

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
               target:(id)target
               action:(SEL)action;

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
              options:(NSKeyValueObservingOptions)options
               target:(id)target
               action:(SEL)action;

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
               target:(id)target
          valueAction:(SEL)valueAction;

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
                owner:(id)owner
              options:(NSKeyValueObservingOptions)options
               target:(id)target
          valueAction:(SEL)valueAction;
@end
