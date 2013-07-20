//
//  THObserversAndBindersAutoUnregisterTests.m
//  THObserversAndBinders
//
//  Created by Yan Rabovik on 20.07.13.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import "THObserver.h"
#import "THBinder.h"
#import "THObserversAndBindersAutoUnregisterTests.h"

@interface THObserver (){
    @public
    dispatch_block_t _block;
}
@end

@interface THBinder (){
    @public
    THObserver *_observer;
}
@end

@implementation THObserversAndBindersAutoUnregisterTests{
}

#pragma mark - Observers

-(void)testStopObservingNilsBlockIvar
{
    THObserver *observer = [THObserver observerForObject:[NSObject new] keyPath:@"testKey" block:^{}];
    STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
    [observer stopObserving];
    STAssertTrue(observer->_block == nil, @"Observers' block should be nil.");
}

-(void)testStopObservingCalledOnObservedObjectDies
{
    THObserver *observer = nil;
    @autoreleasepool {
        id object = [[NSObject alloc] init];
        observer = [THObserver observerForObject:object keyPath:@"testKey" block:^{}];
        STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(observer->_block == nil, @"StopObserving was not called");
}

-(void)testStopObservingCalledOnTargetDies
{
    THObserver *observer;
    NSObject *observedObject = [NSObject new];
    @autoreleasepool {
        id target = [NSObject new];
        observer = [THObserver observerForObject:observedObject
                                         keyPath:@"testKey"
                                          target:target
                                          action:@selector(testSelector)];
        STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
    }
    STAssertTrue(observer->_block == nil, @"StopObserving was not called");
}

-(void)testSameTargetAndObservedObject
{
    THObserver *observer;
    @autoreleasepool {
        id object = [NSObject new];
        observer = [THObserver observerForObject:object
                                         keyPath:@"testKey"
                                          target:object
                                          action:@selector(testSelector)];
        STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(observer->_block == nil, @"StopObserving was not called");
}

#pragma mark - Bindings

-(void)testStopBindingNilsBlockIvar
{
    THBinder *binder = [THBinder binderFromObject:[NSObject new]
                                          keyPath:@"testKey"
                                         toObject:[NSObject new]
                                          keyPath:@"testKey"];
    THObserver *observer = binder->_observer;
    STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
    [binder stopBinding];
    STAssertTrue(observer->_block == nil, @"Observers' block should be nil.");
}

-(void)testStopObservingCalledOnBindFromObjectDies
{
    THBinder *binder;
    THObserver *observer;
    NSObject *testTo = [NSObject new];
    @autoreleasepool {
        NSObject *testFrom = [NSObject new];
        binder = [THBinder binderFromObject:testFrom
                                    keyPath:@"testKey"
                                   toObject:testTo
                                    keyPath:@"testKey"];
        observer = binder->_observer;
        STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(observer->_block == nil, @"Observers' block should be nil.");
}

-(void)testStopObservingCalledOnBindToObjectDies
{
    THBinder *binder;
    THObserver *observer;
    NSObject *testFrom = [NSObject new];
    @autoreleasepool {
        NSObject *testTo = [NSObject new];
        binder = [THBinder binderFromObject:testFrom
                                    keyPath:@"testKey"
                                   toObject:testTo
                                    keyPath:@"testKey"];
        observer = binder->_observer;
        STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
    }
    STAssertTrue(observer->_block == nil, @"Observers' block should be nil.");
}

-(void)testSameBindToAndBindFromObjects
{
    THBinder *binder;
    THObserver *observer;
    @autoreleasepool {
        NSObject *testObject = [NSObject new];
        binder = [THBinder binderFromObject:testObject
                                    keyPath:@"testKey1"
                                   toObject:testObject
                                    keyPath:@"testKey2"];
        observer = binder->_observer;
        STAssertTrue(observer->_block != nil, @"Observers' block is nil.");
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(observer->_block == nil, @"Observers' block should be nil.");
}

@end
