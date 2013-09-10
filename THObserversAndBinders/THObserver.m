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
#import <libkern/OSAtomic.h>

@implementation THObserver {
    // The reason this is __unsafe_unretained, rather than __weak, is so that
    // it's still valid when our magic deregistration routines, called from
    // the observed object's dealloc, fire.  If we use __weak, it's zeroed out
    // before our code runs.
    // This is still a weak reference in effect, because it'll be zeroed out
    // manually when the deregistration routines run.
    __unsafe_unretained id _observedObject;
    
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
    
    // Remove ourselves from the list of active observers of this object (the
    // list that's used to to remove observers when an object deallocates - see
    // the "Magic Deregistration" implementation, below, for more
    // explanation).
    NSHashTable *myObservers;
    
    NSMapTable *objectsToObservers = THObserverObjectsToObservers();
    @synchronized(objectsToObservers) {
        myObservers = [objectsToObservers objectForKey:_observedObject];
    }
    
    // if() because myObservers may be nil if we're being called from inside
    // ReplacementDealloc()
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

static NSMutableSet *THObserverDeallocSwizzledClasses(void)
{
    static NSMutableSet *sDeallocSwizzledClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sDeallocSwizzledClasses = [NSMutableSet set];
    });
    return sDeallocSwizzledClasses;
}

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

static void ReplacementDealloc(__unsafe_unretained id self)
{
    NSHashTable *myObservers = nil;
    
    NSMapTable *objectsToObservers = THObserverObjectsToObservers();
    @synchronized(objectsToObservers) {
        myObservers = [objectsToObservers objectForKey:self];
        if(myObservers) {
            [objectsToObservers removeObjectForKey:self];
        }
    }
    
    // No need to synchronize access to myObservers here - by this time, the
    // only place myObservers is accessed is inside dealloc, and that's not
    // going to be running concurrently with itsself.

    // Note: there will not be any observers in this table if they've
    // all stopped observing already
    for(THObserver *observer in myObservers) {
        // It's safe to call -stopObserving even though it will try to remove
        // the observer from the myObservers map table because when it looks up
        // the myObservers map table in objectsToObservers it's going to get
        // nil back, because we already removed it, above.
        [observer stopObserving];
    }
}

- (void)_setUpMagicDeregistration
{
    // We need to make sure that the KVO observation on the observed object is
    // stopped _before_ its dealloc is called.
    
    // The strategy here is to replace the implementation of -dealloc with one
    // that will deregister any observers before calling the original dealloc.
    // This must be done _after_ the observation is added so that KVO can do
    // its magic before we do our raplacement, so that our replacement is
    // guaranteed to run first.
    
    Class objectClass = [_observedObject class];
    
    // We only need to do this once per class, so we store what classes we've
    // already done it to in deallocSwizzledClasses.
    NSMutableSet *deallocSwizzledClasses = THObserverDeallocSwizzledClasses();
    @synchronized(deallocSwizzledClasses) {
        if(![deallocSwizzledClasses containsObject:objectClass]) {
            const SEL deallocSelector = NSSelectorFromString(@"dealloc");

            // To keep things thread-safe, we fill in the originalDealloc later,
            // with the result of the class_replaceMethod call (see more comments
            // below).
            __block IMP originalDealloc = NULL;
            __block volatile int32_t originalDeallocIsSet = 0;
            
            IMP replacementDeallocImp = imp_implementationWithBlock(^(__unsafe_unretained id impSelf) {
                ReplacementDealloc(impSelf);
                
                while(OSAtomicAdd32(0, &originalDeallocIsSet) != 1) {
                    // Just in case the originalDealloc isn't set yet, wait
                    // until we know for sure that it is.
                    //
                    // Without a guard mechanism, it's possible that another
                    // thread could call call dealloc between the call to
                    // class_replaceMethod swizzling the methods and its
                    // return value being set.  This would cause us to fall
                    // through to super's dealloc erroneously, because
                    // originalDealloc would still be NULL.
                    //
                    // Waiting by spinning should be fine - it's very
                    // implausible that it wouldn' be set yet, and even if it's
                    // not it will be very soon.
                }
                
                if(originalDealloc) {
                    // If there was a dealloc at the time we replaced it with
                    // this block, call it.  It will call [super dealloc] at its
                    // end, we don't need to worry about that.
    
                    // The reason we are casting the IMP to a function pointer
                    // here is that if we use an IMP, ARC will retain the first
                    // 'id' argument of an IMP before calling it, because it's
                    // not defined as __unsafe_unretained.  That's obviously bad
                    // in the middle of a -dealloc call.
                    void(*originalDeallocImpFunction)(__unsafe_unretained id s, SEL _c) =
                        (typeof(originalDeallocImpFunction))originalDealloc;
                    
                    originalDeallocImpFunction(impSelf, deallocSelector);
                } else {
                    // There was no dealloc method on this class originally.
                    // Simulate the dynamic falling through to the superclass
                    // dealloc that would originally have happened.
                    void(*superDeallocImpFunction)(__unsafe_unretained id s, SEL _c) =
                        (typeof(superDeallocImpFunction))class_getMethodImplementation(class_getSuperclass(objectClass), deallocSelector);
                    
                    superDeallocImpFunction(impSelf, deallocSelector);
                }
            });
            
            const Method deallocMethod = class_getInstanceMethod(objectClass, deallocSelector);
            const char *deallocTypeEncoding = method_getTypeEncoding(deallocMethod);
            
            // Atomically replace the original dealloc with our replacement IMP,
            // made above. This will ensure that, in the very unlikely event
            // that someone else's code on another thread is messing with the
            // class' method list too, we have a valid -dealloc at all times
            // (presuming it's doing things in a thread-safe manner too).
            //
            // If this returns NULL, there was no implementation originally,
            // so the class inherited its superclass' one - we deal with that in
            // replacementDeallocImp's implementation, above.
            originalDealloc = class_replaceMethod(objectClass,
                                                  deallocSelector,
                                                  replacementDeallocImp,
                                                  deallocTypeEncoding);
            
            // Flag that we've set originalDealloc now (see comments in the
            // replacementDeallocImp block).
            OSAtomicIncrement32Barrier(&originalDeallocIsSet);
            
            [deallocSwizzledClasses addObject:objectClass];
        }
    }
    
    // Store a reference to ourselves in a list of observers for this object
    // (creating it if necessary) so that we can look all the observers for an
    // object up when ReplacementDealloc() is called (see implementation of
    // ReplacementDealloc, above).
    NSHashTable *myObservers;
    
    NSMapTable *objectsToObservers = THObserverObjectsToObservers();
    @synchronized(objectsToObservers) {
        myObservers = [objectsToObservers objectForKey:_observedObject];
        if(!myObservers) {
            myObservers = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsObjectPointerPersonality];
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
                    ((void(*)(id, SEL))objc_msgSend)(msgTarget, action);
                }
            } copy];
            blockArgumentsKind = THObserverBlockArgumentsNone;
        }
            break;
        case 1: {
            block = [^{
                id msgTarget = wTarget;
                if(msgTarget) {
                    ((void(*)(id, SEL, id))objc_msgSend)(msgTarget, action, wObject);
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
                    ((void(*)(id, SEL, id, NSString *))objc_msgSend)(msgTarget, action, wObject, myKeyPath);
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
                    ((void(*)(id, SEL, id, NSString *, NSDictionary *))objc_msgSend)(msgTarget, action, wObject, myKeyPath, change);
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
                    ((void(*)(id, SEL, id, NSString *, id, id))objc_msgSend)(msgTarget, action, wObject, myKeyPath, oldValue, newValue);
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
                    ((void(*)(id, SEL, id))objc_msgSend)(msgTarget, valueAction, change[NSKeyValueChangeNewKey]);
                }
            } copy];
        }
            break;
        case 2: {
            options |= NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
            block = [^(NSDictionary *change) {
                id msgTarget = wTarget;
                if(msgTarget) {
                    ((void(*)(id, SEL, id, id))objc_msgSend)(msgTarget, valueAction, change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
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
                    ((void(*)(id, SEL, id, id, id))objc_msgSend)(msgTarget, valueAction, wObject, change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey]);
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
