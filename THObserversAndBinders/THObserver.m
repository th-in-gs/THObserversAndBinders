//
//  THObserver.m
//  THObserversAndBinders
//
//  Created by James Montgomerie on 29/11/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import "THObserver.h"
#import "THObserver_Private.h"
#import "__THObserversStorage.h"

#import <objc/message.h>

#import "NSObject+RSDeallocHandler.h"

@implementation THObserver {
    __weak id _observedObject;
    NSString *_keyPath;
    dispatch_block_t _block;
    BOOL _observingStopped;
}

- (id)initForObject:(id)object
            keyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
              block:(dispatch_block_t)block
 blockArgumentsKind:(THObserverBlockArgumentsKind)blockArgumentsKind
             target:(id)target // used for unregistering
{
    if((self = [super init])) {
        if(!object || !keyPath || !block) {
            [NSException raise:NSInternalInconsistencyException format:@"Observation must have a valid object (%@), keyPath (%@) and block(%@)", object, keyPath, block];
            self = nil;
        } else {
            _observedObject = object;
            _keyPath = [keyPath copy];
            _block = [block copy];
                        
            [_observedObject addObserver:self
                              forKeyPath:_keyPath
                                 options:options
                                 context:(void *)blockArgumentsKind];
            
            // Automatic unregistering when observed object dies
            __typeof(self) __weak weakSelf = self;
            __unsafe_unretained id unsafeObservedObject = _observedObject;
            [_observedObject rs_addDeallocHandler:^{
                __typeof(self) strongSelf = weakSelf;
                if (strongSelf && !strongSelf->_observingStopped) {
                    // weak reference to observed object used in stopObserving
                    // is already nil, so we can not use it for removing KVO observer;
                    // but unsafe reference still references just deallocated object,
                    // so we can use it instead
                    [unsafeObservedObject removeObserver:strongSelf forKeyPath:strongSelf->_keyPath];
                    // cleaning up
                    [strongSelf stopObserving];
                }
            } owner:self];
            
            // Automatic unregistering when target dies
            if (target) {
                [target rs_addDeallocHandler:^{
                    [weakSelf stopObserving];
                } owner:self];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    if(_observedObject) {
        [self stopObserving];
    }
}

- (void)stopObserving
{
    if (_observingStopped) return;
    _observingStopped = YES;
    [_observedObject removeObserver:self forKeyPath:_keyPath];
    _block = nil;
    _keyPath = nil;
    _observedObject = nil;
    [__THObserversStorage removeObject:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    switch((THObserverBlockArgumentsKind)context) {
        case THObserverBlockArgumentsNone:
            ((THObserverBlock)_block)();
            break;
        case THObserverBlockArgumentsOldAndNew:
            ((THObserverBlockWithOldAndNew)_block)(change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
            break;
        case THObserverBlockArgumentsChangeDictionary:
            ((THObserverBlockWithChangeDictionary)_block)(change);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"%s called on %@ with unrecognised context (%p)", __func__, self, context];
    }
}


#pragma mark -
#pragma mark Block-based observer construction.

#pragma mark └ observers

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                  block:(THObserverBlock)block
{
    return [[self alloc] initForObject:object
                               keyPath:keyPath
                               options:0
                                 block:(dispatch_block_t)block
                    blockArgumentsKind:THObserverBlockArgumentsNone
                                target:nil];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    return [[self alloc] initForObject:object
                               keyPath:keyPath
                               options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 block:(dispatch_block_t)block
                    blockArgumentsKind:THObserverBlockArgumentsOldAndNew
                                target:nil];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
            changeBlock:(THObserverBlockWithChangeDictionary)block
{
    return [[self alloc] initForObject:object
                               keyPath:keyPath
                               options:options
                                 block:(dispatch_block_t)block
                    blockArgumentsKind:THObserverBlockArgumentsChangeDictionary
                                target:nil];
}

#pragma mark └ auto-lifetime observation
+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
            withBlock:(THObserverBlock)block
{
    THObserver *observer = [THObserver observerForObject:object keyPath:keyPath block:block];
    [__THObserversStorage addObject:observer];
}

+ (void)observeObject:(id)object
            keyPath:(NSString *)keyPath
 withOldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    THObserver *observer = [THObserver observerForObject:object keyPath:keyPath oldAndNewBlock:block];
    [__THObserversStorage addObject:observer];
}

+ (void)observeObject:(id)object
            keyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
    withChangeBlock:(THObserverBlockWithChangeDictionary)block
{
    THObserver *observer = [THObserver observerForObject:object
                                                 keyPath:keyPath
                                                 options:options
                                             changeBlock:block];
    [__THObserversStorage addObject:observer];
}


#pragma mark -
#pragma mark Target-action based observer construction.

static NSUInteger SelectorArgumentCount(SEL selector)
{
    NSUInteger argumentCount = 0;
    
    const char *selectorStringCursor = sel_getName(selector);
    char ch;
    while((ch = *selectorStringCursor)) {
        if(ch == ':') {
            ++argumentCount;
        }
        ++selectorStringCursor;
    }
    
    return argumentCount;
}

#pragma mark └ observers

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                 target:(id)target
                 action:(SEL)action
{
    id ret = nil;
    
    __weak id wTarget = target;
    __weak id wObject = object;

    dispatch_block_t block = nil;
    THObserverBlockArgumentsKind blockArgumentsKind;

    // Was doing this with an NSMethodSignature by calling
    // [target methodForSelector:action], but that will fail if the method
    // isn't defined on the target yet, beating ObjC's dynamism a bit.
    // This looks a little hairier, but it won't fail (and is probably a lot
    // more efficient anyway).
    NSUInteger actionArgumentCount = SelectorArgumentCount(action);
    
    switch(actionArgumentCount) {
        case 0: {
            block = [^{
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, action);
                }
            } copy];
            blockArgumentsKind = THObserverBlockArgumentsNone;
        }
            break;
        case 1: {
            block = [^{
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, action, wObject);
                }
            } copy];
            blockArgumentsKind = THObserverBlockArgumentsNone;
        }
            break;
        case 2: {
            NSString *myKeyPath = [keyPath copy];
            block = [^{
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, action, wObject, myKeyPath);
                }
            } copy];
            blockArgumentsKind = THObserverBlockArgumentsNone;
        }
            break;
        case 3: {
            NSString *myKeyPath = [keyPath copy];
            block = [(dispatch_block_t)(^(NSDictionary *change) {
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, action, wObject, myKeyPath, change);
                }
            }) copy];
            blockArgumentsKind = THObserverBlockArgumentsChangeDictionary;
        }
            break;
        case 4: {
            NSString *myKeyPath = [keyPath copy];
            options |=  NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
            block = [(dispatch_block_t)(^(id oldValue, id newValue) {
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, action, wObject, myKeyPath, oldValue, newValue);
                }
            }) copy];
            blockArgumentsKind = THObserverBlockArgumentsOldAndNew;
        }
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Incorrect number of arguments (%ld) in action for %s (should be 0 - 4)", (long)actionArgumentCount, __func__];
    }
    
    if(block) {
        ret = [[self alloc] initForObject:object
                                  keyPath:keyPath
                                  options:options
                                    block:block
                       blockArgumentsKind:blockArgumentsKind
                                   target:target];
    }
    
    return ret;
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                 target:(id)target
                 action:(SEL)action
{
    return [self observerForObject:object keyPath:keyPath options:0 target:target action:action];
}

#pragma mark └ auto-lifetime observing

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
           withTarget:(id)target
               action:(SEL)action
{
    [self observeObject:object
                keyPath:keyPath
                options:0
             withTarget:target
                 action:action];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
           withTarget:(id)target
               action:(SEL)action
{
    THObserver *observer = [self observerForObject:object
                                           keyPath:keyPath
                                           options:options
                                            target:target
                                            action:action];
    [__THObserversStorage addObject:observer];
}

#pragma mark -
#pragma mark Value-only target-action observers.

#pragma mark └ observers

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions)options
                 target:(id)target
            valueAction:(SEL)valueAction
{
    id ret = nil;
    
    __weak id wTarget = target;

    THObserverBlockWithChangeDictionary block = nil;
    
    NSUInteger actionArgumentCount = SelectorArgumentCount(valueAction);
    
    switch(actionArgumentCount) {
        case 1: {
            options |= NSKeyValueObservingOptionNew;
            block = [^(NSDictionary *change) {
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, valueAction, change[NSKeyValueChangeNewKey]);
                }
            } copy];
        }
            break;
        case 2: {
            options |= NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
            block = [^(NSDictionary *change) {
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, valueAction, change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
                }
            } copy];
        }
            break;
        case 3: {
            __weak id wObject = object;

            options |= NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
            block = [^(NSDictionary *change) {
                id msgTarget = wTarget;
                if(msgTarget) {
                    objc_msgSend(msgTarget, valueAction, wObject, change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
                }
            } copy];
        }
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Incorrect number of arguments (%ld) in action for %s (should be 1 - 2)", (long)actionArgumentCount, __func__];
    }
    
    if(block) {
        ret = [[self alloc] initForObject:object
                                  keyPath:keyPath
                                  options:options
                                    block:(dispatch_block_t)block
                       blockArgumentsKind:THObserverBlockArgumentsChangeDictionary
                                   target:target];
    }
    
    return ret;
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                 target:(id)target
            valueAction:(SEL)valueAction
{
    return [self observerForObject:object keyPath:keyPath options:0 target:target valueAction:valueAction];
}

#pragma mark └ auto-lifetime observation

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
           withTarget:(id)target
          valueAction:(SEL)valueAction
{
    [self observeObject:object
                keyPath:keyPath
                options:0
             withTarget:target
            valueAction:valueAction];
}

+ (void)observeObject:(id)object
              keyPath:(NSString *)keyPath
              options:(NSKeyValueObservingOptions)options
           withTarget:(id)target
          valueAction:(SEL)valueAction
{
    THObserver *observer = [self observerForObject:object
                                           keyPath:keyPath
                                           options:options
                                            target:target
                                       valueAction:valueAction];
    [__THObserversStorage addObject:observer];
}

@end
