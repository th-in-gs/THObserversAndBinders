//
//  THObserversAndBindersTests.m
//  THObserversAndBindersTests
//
//  Created by James Montgomerie on 29/11/2012.
//  Copyright (c) 2012 James Montgomerie. All rights reserved.
//

#import "THObserversAndBindersTests.h"
#import "THOBTestSelfObservationTestObject.h"

#import <THObserversAndBinders/THObserversAndBinders.h>

@interface AddOneTransformer: NSValueTransformer

@end

@implementation AddOneTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    return @([value integerValue] + 1);
}

@end


@implementation THObserversAndBindersTests {
    BOOL test0ArgTargetActionCallbackTriggered;
    BOOL test1ArgTargetActionCallbackTriggered;
    BOOL test2ArgTargetActionCallbackTriggered;
    BOOL test3ArgTargetActionCallbackTriggered;
    BOOL test3ArgTargetActionPriorCallbackTriggered;
    BOOL test4ArgTargetActionCallbackTriggered;
    
    BOOL testTargetValueActionNewTrigered;
    BOOL testTargetValueActionOldAndNewTrigered;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

#pragma mark -
#pragma mark Block based observation

- (void)testNoChange
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    __block BOOL triggered = NO;
    THObserver *observer = [THObserver observerForObject:test keyPath:@"testKey" block:^{
        triggered = YES;
    }];
    
    test[@"notTestKey"] = @"changedKey";
    
    STAssertFalse(triggered, @"Changing a non-observed keypath triggered an observation");
    
    [observer stopObserving];
}

- (void)testStopObservation
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    __block BOOL triggered = NO;
    THObserver *observer = [THObserver observerForObject:test keyPath:@"testKey" block:^{
        triggered = YES;
    }];
    
    [observer stopObserving];

    test[@"testKey"] = @"changedValue";
    
    STAssertFalse(triggered, @"Changing an observed keypath after removing the observer triggered an observation.");
}

- (void)testPlainChange
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    __block BOOL triggered = NO;
    THObserver *observer = [THObserver observerForObject:test keyPath:@"testKey" block:^{
        triggered = YES;
    }];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(triggered, @"Changing an observed keypath did not trigger an observation.");
    
    [observer stopObserving];
}

- (void)testOldNewChange
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    __block BOOL triggered = NO;
    THObserver *observer = [THObserver observerForObject:test keyPath:@"testKey" oldAndNewBlock:^(id oldValue, id newValue) {
        STAssertEqualObjects(@"testValue", oldValue, @"Old value is not correct");
        STAssertEqualObjects(@"changedValue", newValue, @"New value is not correct");
        
        triggered = YES;
    }];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(triggered, @"Changing an observed keypath did not trigger an observation");
    
    [observer stopObserving];
}

- (void)testChangeDictionary
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    __block BOOL triggered = NO;
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                             changeBlock:^(NSDictionary *change) {
                                                 STAssertNotNil(change, @"Change dictionary is nil");
                                                 STAssertEqualObjects(@"testValue", change[NSKeyValueChangeNewKey], @"Reported value is not correct");
                                                 triggered = YES;
                                             }];
    
    STAssertTrue(triggered, @"Using NSKeyValueObservingOptionInitial did not trigger an initial observation");
    
    [observer stopObserving];
}

/*
- (void)testPlainChangeReleasingObservedObject
{
    // This will cause KVO to complain.  It's something the user should not do 
    // though - the observer should be released, or have -stopObserving called 
    // on it, before the observed object is released.
 
    THObserver *observer = nil;
    
    @autoreleasepool {
        id object = [[NSObject alloc] init];
        observer = [THObserver observerForObject:object keyPath:@"testKey" block:^{}];
    }
    
    NSLog(@"%@", observer);
}
*/

#pragma mark -
#pragma mark Target-Action based observation

- (void)_0ArgTargetActionCallback
{
    test0ArgTargetActionCallbackTriggered = YES;
}

- (void)test0ArgTargetAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                                  action:@selector(_0ArgTargetActionCallback)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(test0ArgTargetActionCallbackTriggered, @"0 argument action not called as expected");
    
    [observer stopObserving];
}

- (void)_1ArgTargetActionCallback:(id)object
{
    STAssertEqualObjects(object, [NSMutableDictionary dictionaryWithObject:@"changedValue" forKey:@"testKey"],
                         @"Object is not as expected");
    
    test1ArgTargetActionCallbackTriggered = YES;
}

- (void)test1ArgTargetAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                                  action:@selector(_1ArgTargetActionCallback:)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(test1ArgTargetActionCallbackTriggered, @"1 argument action not called as expected");
    
    [observer stopObserving];
}

- (void)_2ArgTargetActionCallback:(id)object keyPath:(NSString *)keyPath
{
    STAssertEqualObjects(object, [NSMutableDictionary dictionaryWithObject:@"changedValue" forKey:@"testKey"],
                         @"Object is not as expected");
    STAssertEqualObjects(keyPath, @"testKey", @"Keypath is not as expected");
    
    test2ArgTargetActionCallbackTriggered = YES;
}

- (void)test2ArgTargetAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                                  action:@selector(_2ArgTargetActionCallback:keyPath:)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(test2ArgTargetActionCallbackTriggered, @"2 argument action not called as expected");
    
    [observer stopObserving];
}


- (void)_3ArgTargetActionCallback:(id)object keyPath:(NSString *)keyPath change:(NSDictionary *)change
{
    STAssertEqualObjects(object, [NSMutableDictionary dictionaryWithObject:@"changedValue" forKey:@"testKey"],
                         @"Object is not as expected");
    STAssertEqualObjects(keyPath, @"testKey", @"Keypath is not as expected");
    STAssertEquals([change count], (NSUInteger)1,
                   @"Expected only one entry in the change dictionary since no options specified");
    
    test3ArgTargetActionCallbackTriggered = YES;
}

- (void)test3ArgTargetAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                                  action:@selector(_3ArgTargetActionCallback:keyPath:change:)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(test3ArgTargetActionCallbackTriggered, @"3 argument action not called as expected");
    
    [observer stopObserving];
}

- (void)_3ArgTargetActionPriorCallback:(id)object keyPath:(NSString *)keyPath change:(NSDictionary *)change
{
    STAssertEqualObjects(object, [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"],
                         @"Object is not as expected");
    STAssertEqualObjects(keyPath, @"testKey", @"Keypath is not as expected");
    STAssertEqualObjects(@"testValue", change[NSKeyValueChangeNewKey], @"Reported value is not correct");

    test3ArgTargetActionPriorCallbackTriggered = YES;
}

- (void)test3ArgTargetActionPrior
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                  target:self
                                                  action:@selector(_3ArgTargetActionPriorCallback:keyPath:change:)];
    
    STAssertTrue(test3ArgTargetActionPriorCallbackTriggered, @"3 argument action not called as expected");
    
    [observer stopObserving];
}

- (void)_4ArgTargetActionCallback:(id)object keyPath:(NSString *)keyPath oldValue:(id)oldValue newValue:(id)newValue
{
    STAssertEqualObjects(object, [NSMutableDictionary dictionaryWithObject:@"changedValue" forKey:@"testKey"],
                         @"Object is not as expected");
    STAssertEqualObjects(keyPath, @"testKey", @"Keypath is not as expected");
    STAssertEqualObjects(@"testValue", oldValue, @"Old value is not correct");
    STAssertEqualObjects(@"changedValue", newValue, @"New value is not correct");
    
    test4ArgTargetActionCallbackTriggered = YES;
}

- (void)test4ArgTargetAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                                  action:@selector(_4ArgTargetActionCallback:keyPath:oldValue:newValue:)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(test4ArgTargetActionCallbackTriggered, @"4 argument action not called as expected");
    
    [observer stopObserving];
}

- (void)_targetActionCallbackForNewValue:(id)value
{
    STAssertEqualObjects(value, @"changedValue", @"Object is not as expected");
    
    testTargetValueActionNewTrigered = YES;
}

- (void)test1ArgTargetValueAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                             valueAction:@selector(_targetActionCallbackForNewValue:)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(testTargetValueActionNewTrigered, @"1 argument action not called as expected");
    
    [observer stopObserving];
}

- (void)_targetActionCallbackForOldValue:(id)oldValue newValue:(id)newValue
{
    STAssertEqualObjects(oldValue, @"testValue", @"Object is not as expected");
    STAssertEqualObjects(newValue, @"changedValue", @"Object is not as expected");
    
    testTargetValueActionOldAndNewTrigered = YES;
}

- (void)test2ArgTargetValueAction
{
    NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
    
    THObserver *observer = [THObserver observerForObject:test
                                                 keyPath:@"testKey"
                                                  target:self
                                             valueAction:@selector(_targetActionCallbackForOldValue:newValue:)];
    
    test[@"testKey"] = @"changedValue";
    
    STAssertTrue(testTargetValueActionOldAndNewTrigered, @"2 argument action not called as expected");
    
    [observer stopObserving];
}


#pragma mark -
#pragma mark Binding

- (void)testSimpleBinding
{
    NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@"testFromValue" forKey:@"testFromKey"];
    NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@"testToValue" forKey:@"testToKey"];

    THBinder *binder = [THBinder binderFromObject:testFrom keyPath:@"testFromKey"
                                         toObject:testTo keyPath:@"testToKey"];
    
    testFrom[@"testFromKey"] = @"changedValue";
    
    STAssertEqualObjects(testTo[@"testToKey"], @"changedValue", @"New value in to object is not correct");
    
    [binder stopBinding];
}

- (void)testStopBinding
{
    NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@"testFromValue" forKey:@"testFromKey"];
    NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@"testToValue" forKey:@"testToKey"];
    
    THBinder *binder = [THBinder binderFromObject:testFrom keyPath:@"testFromKey"
                                         toObject:testTo keyPath:@"testFromKey"];
    
    [binder stopBinding];
    
    testFrom[@"testFromKey"] = @"changedValue";
    
    STAssertEqualObjects(testTo[@"testToKey"], @"testToValue", @"New value in to object has changed");
}

- (void)testSimpleKeypathBinding
{
    NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionaryWithObject:@"testFromValue" forKey:@"testFromKey"]
                                                                       forKey:@"testFromKey"];
    NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionaryWithObject:@"testToValue" forKey:@"testToKey"]
                                                                     forKey:@"testToKey"];
    
    THBinder *binder = [THBinder binderFromObject:testFrom keyPath:@"testFromKey.testFromKey"
                                         toObject:testTo keyPath:@"testToKey.testToKey"];
    
    testFrom[@"testFromKey"][@"testFromKey"] = @"changedValue";
    
    STAssertEqualObjects(testTo[@"testToKey"][@"testToKey"], @"changedValue", @"New value in to object is not correct");
    
    [binder stopBinding];
}

- (void)testBindingWithNSValueTransformer
{
    NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@1 forKey:@"testFromKey"];
    NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@0 forKey:@"testToKey"];
    
    THBinder *binder = [THBinder binderFromObject:testFrom keyPath:@"testFromKey"
                                         toObject:testTo keyPath:@"testToKey"
                        valueTransformer:[[AddOneTransformer alloc] init]];
    
    testFrom[@"testFromKey"] = @5;
        
    STAssertEqualObjects(testTo[@"testToKey"], @6, @"Transformed value in to object is not correct");
    
    [binder stopBinding];
}

- (void)testBindingWithTransformerBlock
{
    NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@1 forKey:@"testFromKey"];
    NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@0 forKey:@"testToKey"];
    
    THBinder *binder = [THBinder binderFromObject:testFrom keyPath:@"testFromKey"
                                         toObject:testTo keyPath:@"testToKey"
                              transformationBlock:^id(id value) {
                                  return @([value integerValue] + 5);
                              }];
    
    testFrom[@"testFromKey"] = @5;
    
    STAssertEqualObjects(testTo[@"testToKey"], @10, @"Transformed value in to object is not correct");
    
    [binder stopBinding];
}

- (void)testSelfObservation
{
    THOBTestSelfObservationTestObject *object = [[THOBTestSelfObservationTestObject alloc] init];
    NSLog(@"Test object: %@", object);
}

- (void)testBindingWithFormatter
{
    NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@1 forKey:@"testFromKey"];
    NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@0 forKey:@"testToKey"];

	NSNumberFormatter *formatter = [NSNumberFormatter new];
	formatter.numberStyle = NSNumberFormatterNoStyle;

    THBinder *binder = [THBinder binderFromObject:testFrom keyPath:@"testFromKey"
                                         toObject:testTo keyPath:@"testToKey"
										formatter:formatter];

    testFrom[@"testFromKey"] = @5;

    STAssertEqualObjects(testTo[@"testToKey"], @"5", @"Transformed value in to object is not correct");

    [binder stopBinding];
}

@end
