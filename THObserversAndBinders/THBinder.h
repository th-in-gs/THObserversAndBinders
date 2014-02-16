//
//  THBinder.h
//  THObserversAndBinders
//
//  Created by James Montgomerie on 29/11/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THBinder : NSObject

typedef id(^THBinderTransformationBlock)(id value);

+ (instancetype)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
                        toObject:(id)toObject keyPath:(NSString *)toKeyPath;

+ (instancetype)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
                        toObject:(id)toObject keyPath:(NSString *)toKeyPath
                valueTransformer:(NSValueTransformer *)valueTransformer;

+ (instancetype)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
                        toObject:(id)toObject keyPath:(NSString *)toKeyPath
                       formatter:(NSFormatter *)formatter;

+ (instancetype)binderFromObject:(id)fromObject keyPath:(NSString *)fromKeyPath
                        toObject:(id)toObject keyPath:(NSString *)toKeyPath
             transformationBlock:(THBinderTransformationBlock)transformationBlock;

// This is a one-way street. Call it to stop the observer functioning.
// The THBinder will do this cleanly when it deallocs, but calling it manually
// can be useful in ensuring an orderly teardown.
- (void)stopBinding;

@end
