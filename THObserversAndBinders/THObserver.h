//
//  THObserver.h
//  THObserversAndBinders
//
//  Created by James Montgomerie on 29/11/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THObserver : NSObject

#pragma mark -
#pragma mark Block-based observers.

typedef void(^THObserverBlock)(void);
typedef void(^THObserverBlockWithOldAndNew)(id oldValue, id newValue);
typedef void(^THObserverBlockWithChangeDictionary)(NSDictionary *change);

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                  block:(THObserverBlock)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
            changeBlock:(THObserverBlockWithChangeDictionary)block;

#pragma mark -
#pragma mark Target-action based observers.

// Target-action based observers take a selector with a signature with 0-4
// arguments, and call it like this:
//
// 0 arguments: [target action];
//
// 1 argument:  [target actionForObject:object];
//
// 2 arguments: [target actionForObject:object keyPath:keyPath];
//
// 3 arguments: [target actionForObject:object keyPath:keyPath change:changeDictionary];
//     Don't expect anything in the change dictionary unless you supply some
//     NSKeyValueObservingOptions.
//
// 4 arguments: [target actionForObject:object keyPath:keyPath oldValue:oldValue newValue:newValue];
//     NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew will be
//     automatically added to your options if they're not already there and you
//     supply a 4-argument callback.
//
// The action should not return any value (i.e. should be declared to return
// void).
//
// Both the observer and the target are weakly referenced internally.

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                 target:(id)target
                 action:(SEL)action;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                 target:(id)target
                 action:(SEL)action;


// A second kind of target-action based observer; takes a selector with a
// signature with 1-2 arguments, and call it like this:
//
// 1 argument:  [target actionWithNewValue:newValue];
//
// 2 arguments: [target actionWithOldValue:oldValue newValue:newValue];
//
// 3 arguments: [target actionForObject:object oldValue:oldValue newValue:newValue];
//
// The action should not return any value (i.e. should be declared to return
// void).
//
// Both the observer and the target are weakly referenced internally.

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                 target:(id)target
            valueAction:(SEL)valueAction;

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                 target:(id)target
            valueAction:(SEL)valueAction;


#pragma mark - 
#pragma mark Lifetime management

// This is a one-way street. Call it to stop the observer functioning.
// The THObserver will do this cleanly when it deallocs, but calling it manually
// can be useful in ensuring an orderly teardown.
- (void)stopObserving;

@end
