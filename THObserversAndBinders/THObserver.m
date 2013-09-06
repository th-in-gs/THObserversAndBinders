//
//  THObserver.m
//  THObserversAndBinders
//
//  Created by James Montgomerie on 29/11/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import "THObserver.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import <pthread.h>

@interface NSObject (THObserverSwizzledDealloc)
- (void)th_observerSwizzledRelease;
@end

@implementation THObserver {
    __weak id _observedObject;
    NSString *_keyPath;
    dispatch_block_t _block;
}

typedef enum THObserverBlockArgumentsKind {
    THObserverBlockArgumentsNone,
    THObserverBlockArgumentsOldAndNew,
    THObserverBlockArgumentsChangeDictionary
} THObserverBlockArgumentsKind;

- (id)initForObject:(id)object
            keyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
              block:(dispatch_block_t)block
 blockArgumentsKind:(THObserverBlockArgumentsKind)blockArgumentsKind
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

            [self _setUpMagicDeregistration];
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
    [_observedObject removeObserver:self forKeyPath:_keyPath];
    _block = nil;
    _keyPath = nil;
    
    NSHashTable *myObservers;
    
    NSMapTable *objectsToObservers = THObserverObjectsToObservers();
    @synchronized(objectsToObservers) {
        myObservers = [objectsToObservers objectForKey:_observedObject];
    }
    
    // myObservers may already be nil if we're being called from inside
    // ReplacementRelease()
    if(myObservers) {
        @synchronized(myObservers) {
            [myObservers removeObject:self];
        }
    }
    
    _observedObject = nil;
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
#pragma mark Magic Deregistration

static NSMapTable *THObserverObjectsToObservers(void)
{
    static NSMapTable *sObjectsToObservers;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sObjectsToObservers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsObjectPointerPersonality
                                                    valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality];
    });
    
    return sObjectsToObservers;
}

static void ReplacementRelease(__unsafe_unretained id self, SEL cmd)
{
    if(CFGetRetainCount((__bridge CFTypeRef)self) == 1) {
        NSHashTable *myObservers = nil;
        
        NSMapTable *objectsToObservers = THObserverObjectsToObservers();
        @synchronized(objectsToObservers) {
            myObservers = [objectsToObservers objectForKey:self];
            if(myObservers) {
                [objectsToObservers removeObjectForKey:self];
            }
        }
        
        // No need to synchronize here - if two threads are causing the retain
        // count to drop to 0 at the same time we have bigger problems...
        if(myObservers) {
            // Note: there will not be any observers in this table if they've
            // all stopped observing already.
            for(THObserver *observer in myObservers) {
                // Safe to call this because, even though it will remove itsself
                // from the objectsToObservers map, we've already done that.
                [observer stopObserving];
            }
        }
    }
    
    [self th_observerSwizzledRelease];
}

- (void)_setUpMagicDeregistration
{
    // We need to make sure that the KVO observation on the observed object is
    // stopped _before_ its dealloc is called.
    // The strategy here is to replace the implementation of -release with one
    // that will, if the retain count is about to drop to 0, stop the
    // observation, before calling the original -release, before the system
    // calls -dealloc.
    //
    // This sounds like it may not work under ARC, but the ARC spec actually
    // requires "valid object [s ...] with “well-behaved” retaining operations"
    // See http://clang.llvm.org/docs/AutomaticReferenceCounting.html#retain-count-semantics
    // and http://clang.llvm.org/docs/AutomaticReferenceCounting.html#retainable-object-pointers
    //
    // The only hairy part is depending on CFGetRetainCount working as expected
    // (i.e. returning '1' inside the final call to release).  It seems like
    // a safe bet that this won't change though.
    
    Class objectClass = [_observedObject class];
    
    // Usint a mutex because we can't just @synchronized(objectClass) - there
    // might be another thread modifying a subclass or superclass at the same
    // time.
    static pthread_mutex_t sClassIsSwizzledMutex = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&sClassIsSwizzledMutex);
    {
        // First, check if we've already swizzled this class (or a superclass).
        const SEL swizzledReleaseSelector = @selector(th_observerSwizzledRelease);
        if(!class_getInstanceMethod(objectClass, swizzledReleaseSelector)) {
            const SEL releaseSelector = NSSelectorFromString(@"release");
            const Method releaseMethod = class_getInstanceMethod(objectClass, releaseSelector);
            
            // Just in case my elaborate justification of why this is a valid
            // thing to do under ARC is wrong, or changes, at least we'll
            // know when this assertion fails.
            NSParameterAssert(releaseMethod != NULL);
            
            const IMP originalImp = method_getImplementation(releaseMethod);
            const IMP replacementImp = (IMP)ReplacementRelease;
            
            const char *typeEncoding = method_getTypeEncoding(releaseMethod);
            
            // Add a -th_observerSwizzledRelease method with the
            // original release method's implementation.
            class_addMethod(objectClass,
                            swizzledReleaseSelector,
                            originalImp,
                            typeEncoding);
            
            // Replace the original release with our ReplacementRelease
            // (which will call -th_observerSwizzledRelease when
            // it's done to get the original -release code to run).
            class_replaceMethod(objectClass,
                                releaseSelector,
                                replacementImp,
                                typeEncoding);
        }
    }
    pthread_mutex_unlock(&sClassIsSwizzledMutex);
    
    NSHashTable *myObservers;
    
    NSMapTable *objectsToObservers = THObserverObjectsToObservers();
    @synchronized(objectsToObservers) {
        myObservers = [objectsToObservers objectForKey:_observedObject];
        if(!myObservers) {
            myObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsObjectPersonality];
            [objectsToObservers setObject:myObservers forKey:_observedObject];
        }
    }
    
    @synchronized(myObservers) {
        [myObservers addObject:self];
    }
}

#pragma mark -
#pragma mark Block-based observer construction.

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
                  block:(THObserverBlock)block
{
    return [[self alloc] initForObject:object
                               keyPath:keyPath
                               options:0
                                 block:(dispatch_block_t)block
                    blockArgumentsKind:THObserverBlockArgumentsNone];
}

+ (id)observerForObject:(id)object
                keyPath:(NSString *)keyPath
         oldAndNewBlock:(THObserverBlockWithOldAndNew)block
{
    return [[self alloc] initForObject:object
                               keyPath:keyPath
                               options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 block:(dispatch_block_t)block
                    blockArgumentsKind:THObserverBlockArgumentsOldAndNew];
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
                    blockArgumentsKind:THObserverBlockArgumentsChangeDictionary];
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
                       blockArgumentsKind:blockArgumentsKind];
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


#pragma mark -
#pragma mark Value-only target-action observers.

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
                       blockArgumentsKind:THObserverBlockArgumentsChangeDictionary];
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


@end
