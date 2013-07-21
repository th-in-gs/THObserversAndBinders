//
//  THBinder.m
//  THObserversAndBinders
//
//  Created by James Montgomerie on 29/11/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import "THBinder.h"
#import "THObserver.h"
#import "THObserver_Private.h"
#import "__THObserversStorage.h"

@implementation THBinder {
    THObserver *_observer;
}

- (id)initForBindingFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
                      toObject:(id)toObject keyPath:(NSString *)toKeyPath
           transformationBlock:(THBinderTransformationBlock)transformationBlock
{
    if((self = [super init])) {
        __weak id wToObject = toObject;
        NSString *myToKeyPath = [toKeyPath copy];
        
        THObserverBlockWithChangeDictionary changeBlock;
        if(transformationBlock) {
            changeBlock = [^(NSDictionary *change) {
                [wToObject setValue:transformationBlock(change[NSKeyValueChangeNewKey])
                         forKeyPath:myToKeyPath];
            } copy];
        } else {
            changeBlock = [^(NSDictionary *change) {
                [wToObject setValue:change[NSKeyValueChangeNewKey]
                         forKeyPath:myToKeyPath];
            } copy];
        }
        
        _observer = [[THObserver alloc] initForObject:fromObject
                                              keyPath:fromKeyPath
                                              options:NSKeyValueObservingOptionNew
                                                block:(dispatch_block_t)changeBlock
                                   blockArgumentsKind:THObserverBlockArgumentsChangeDictionary
                                               target:toObject];
    }
    return self;
}

- (void)stopBinding
{
    [_observer stopObserving];
    _observer = nil;
}

#pragma mark - Binders

+ (id)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
              toObject:(id)toObject keyPath:(NSString *)toKeyPath
{
    return [[self alloc] initForBindingFromObject:fromObject keyPath:fromKeyPath
                                         toObject:toObject keyPath:toKeyPath
                              transformationBlock:nil];
}

+ (id)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
              toObject:(id)toObject keyPath:(NSString *)toKeyPath
      valueTransformer:(NSValueTransformer *)valueTransformer
{
    return [[self alloc] initForBindingFromObject:fromObject keyPath:fromKeyPath
                                         toObject:toObject keyPath:toKeyPath
                              transformationBlock:^id(id value) {
                                  return [valueTransformer transformedValue:value];
                              }];
}

+ (id)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
              toObject:(id)toObject keyPath:(NSString *)toKeyPath
   transformationBlock:(THBinderTransformationBlock)transformationBlock
{
    return [[self alloc] initForBindingFromObject:fromObject keyPath:fromKeyPath
                                         toObject:toObject keyPath:toKeyPath
                              transformationBlock:transformationBlock];
}

#pragma mark Auto-lifetime binding
+ (void)bindFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
              toObject:(id)toObject keyPath:(NSString *)toKeyPath
{
    THBinder *binder = [self binderFromObject:fromObject keyPath:fromKeyPath
                                     toObject:toObject keyPath:toKeyPath];
    [__THObserversStorage addObject:binder->_observer];
}

+ (void)bindFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
              toObject:(id)toObject keyPath:(NSString *)toKeyPath
      valueTransformer:(NSValueTransformer *)valueTransformer
{
    THBinder *binder = [self binderFromObject:fromObject keyPath:fromKeyPath
                                     toObject:toObject keyPath:toKeyPath
                             valueTransformer:valueTransformer];
    [__THObserversStorage addObject:binder->_observer];
}

+ (void)bindFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
              toObject:(id)toObject keyPath:(NSString *)toKeyPath
   transformationBlock:(THBinderTransformationBlock)transformationBlock
{
    THBinder *binder = [self binderFromObject:fromObject keyPath:fromKeyPath
                                     toObject:toObject keyPath:toKeyPath
                          transformationBlock:transformationBlock];
    [__THObserversStorage addObject:binder->_observer];
}

@end
