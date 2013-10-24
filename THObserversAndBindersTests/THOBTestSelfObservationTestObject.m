//
//  THOBTestSelfObservationTestObject.m
//  THObserversAndBinders
//
//  Created by James Montgomerie on 15/04/2013.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import "THOBTestSelfObservationTestObject.h"
#import <THObserversAndBinders/THObserversAndBinders.h>

@implementation THOBTestSelfObservationTestObject {
    THObserver *_testObserver;
}

- (id)init
{
    if((self = [super init])) {
        __weak THOBTestSelfObservationTestObject *wSelf = self;
        _testObserver = [THObserver observerForObject:self keyPath:@"string" block:^{
            NSLog(@"String: %@", wSelf.string);
        }];
    }
    return self;
}

- (void)dealloc
{
    [_testObserver stopObserving];
    _testObserver = nil;
}

@end
