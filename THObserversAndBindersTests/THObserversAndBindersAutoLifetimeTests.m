//
//  THObserversAndBindersAutoLifetimeTests.m
//  THObserversAndBinders
//
//  Created by Yan Rabovik on 20.07.13.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import "THObserversAndBindersAutoLifetimeTests.h"
#import "THObserver.h"
#import "THObserver_Private.h"
#import "__THObserversStorage.h"
#import "THBinder.h"

@interface AutoLifetimeAddOneTransformer: NSValueTransformer

@end

@implementation AutoLifetimeAddOneTransformer

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


@implementation THObserversAndBindersAutoLifetimeTests{
    BOOL test0ArgTargetActionCallbackTriggered;
    BOOL test3ArgTargetActionPriorCallbackTriggered;
    BOOL testTargetValueActionNewTrigered;
}

-(void)setUp{
    [super setUp];
    STAssertTrue(0 == [__THObserversStorage count], @"Global storage is not empty.");
}

-(void)tearDown{
    [super tearDown];
    STAssertTrue(0 == [__THObserversStorage count], @"Global storage is not empty.");
}

#pragma mark - Block based observation

- (void)testAutoLifetimePlainChange
{
    @autoreleasepool {
        
        NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
        
        __block BOOL triggered = NO;
        
        @autoreleasepool {
            [THObserver observeObject:test keyPath:@"testKey" withBlock:^{
                triggered = YES;
            }];
        }
        
        test[@"testKey"] = @"changedValue";
        
        STAssertTrue(triggered, @"Changing an observed keypath did not trigger an observation.");
    }
}

- (void)testAutoLifetimeOldNewChange
{
    @autoreleasepool {
        NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
        
        __block BOOL triggered = NO;
        @autoreleasepool {
            [THObserver observeObject:test keyPath:@"testKey" withOldAndNewBlock:^(id oldValue, id newValue) {
                STAssertEqualObjects(@"testValue", oldValue, @"Old value is not correct");
                STAssertEqualObjects(@"changedValue", newValue, @"New value is not correct");
                triggered = YES;
            }];
        }
        
        test[@"testKey"] = @"changedValue";
        
        STAssertTrue(triggered, @"Changing an observed keypath did not trigger an observation");
    }
}

- (void)testAutoLifetimeChangeDictionary
{
    @autoreleasepool {
        NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
        
        __block BOOL triggered = NO;
        @autoreleasepool {
            [THObserver observeObject:test
                              keyPath:@"testKey"
                              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      withChangeBlock:^(NSDictionary *change) {
                          STAssertNotNil(change, @"Change dictionary is nil");
                          STAssertEqualObjects(@"testValue", change[NSKeyValueChangeNewKey], @"Reported value is not correct");
                          triggered = YES;
                      }];
        }
        STAssertTrue(triggered, @"Using NSKeyValueObservingOptionInitial did not trigger an initial observation");
    }
}

#pragma mark -
#pragma mark Target-Action based observation

- (void)_0ArgTargetActionCallback
{
    test0ArgTargetActionCallbackTriggered = YES;
}

- (void)testAutoLifetime0ArgTargetAction
{
    @autoreleasepool {
        NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
        
        @autoreleasepool {
            [THObserver observeObject:test
                              keyPath:@"testKey"
                           withTarget:self
                               action:@selector(_0ArgTargetActionCallback)];
        }

        test[@"testKey"] = @"changedValue";        
        STAssertTrue(test0ArgTargetActionCallbackTriggered, @"0 argument action not called as expected");
    }
}

- (void)_3ArgTargetActionPriorCallback:(id)object keyPath:(NSString *)keyPath change:(NSDictionary *)change
{
    STAssertEqualObjects(object, [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"],
                         @"Object is not as expected");
    STAssertEqualObjects(keyPath, @"testKey", @"Keypath is not as expected");
    STAssertEqualObjects(@"testValue", change[NSKeyValueChangeNewKey], @"Reported value is not correct");
    
    test3ArgTargetActionPriorCallbackTriggered = YES;
}

- (void)testAutoLifetime3ArgTargetActionPrior
{
    @autoreleasepool {
        NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
        @autoreleasepool {
            [THObserver observeObject:test
                              keyPath:@"testKey"
                              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                           withTarget:self
                               action:@selector(_3ArgTargetActionPriorCallback:keyPath:change:)];
        }
        STAssertTrue(test3ArgTargetActionPriorCallbackTriggered, @"3 argument action not called as expected");
    }
}

#pragma mark - Value-only target-action based observation

- (void)_targetActionCallbackForNewValue:(id)value
{
    STAssertEqualObjects(value, @"changedValue", @"Object is not as expected");
    
    testTargetValueActionNewTrigered = YES;
}

- (void)testAutoLifetime1ArgTargetValueAction
{
    @autoreleasepool {
        NSMutableDictionary *test = [NSMutableDictionary dictionaryWithObject:@"testValue" forKey:@"testKey"];
        
        [THObserver observeObject:test
                          keyPath:@"testKey"
                       withTarget:self
                      valueAction:@selector(_targetActionCallbackForNewValue:)];
        
        test[@"testKey"] = @"changedValue";
        
        STAssertTrue(testTargetValueActionNewTrigered, @"1 argument action not called as expected");
    }
}

#pragma mark - Binding
- (void)testAutoLifetimeSimpleBinding
{
    @autoreleasepool {
        NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@"testFromValue"
                                                                           forKey:@"testFromKey"];
        NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@"testToValue"
                                                                         forKey:@"testToKey"];
        @autoreleasepool {
            [THBinder bindFromObject:testFrom keyPath:@"testFromKey"
                            toObject:testTo keyPath:@"testToKey"];
        }
        testFrom[@"testFromKey"] = @"changedValue";
        STAssertEqualObjects(testTo[@"testToKey"], @"changedValue", @"New value in to object is not correct");
    }
}

- (void)testAutoLifetimeBindingWithNSValueTransformer
{
    @autoreleasepool {
        NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@1 forKey:@"testFromKey"];
        NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@0 forKey:@"testToKey"];
        @autoreleasepool {
            [THBinder bindFromObject:testFrom keyPath:@"testFromKey"
                            toObject:testTo keyPath:@"testToKey"
                    valueTransformer:[[AutoLifetimeAddOneTransformer alloc] init]];
        }
        testFrom[@"testFromKey"] = @5;
        STAssertEqualObjects(testTo[@"testToKey"], @6, @"Transformed value in to object is not correct");
    }
}

- (void)testAutoLifetimeBindingWithTransformerBlock
{
    @autoreleasepool {
        NSMutableDictionary *testFrom = [NSMutableDictionary dictionaryWithObject:@1 forKey:@"testFromKey"];
        NSMutableDictionary *testTo = [NSMutableDictionary dictionaryWithObject:@0 forKey:@"testToKey"];
        @autoreleasepool {
            [THBinder bindFromObject:testFrom keyPath:@"testFromKey"
                            toObject:testTo keyPath:@"testToKey"
                 transformationBlock:^id(id value) {
                     return @([value integerValue] + 5);
                 }];
        }
        testFrom[@"testFromKey"] = @5;
        STAssertEqualObjects(testTo[@"testToKey"], @10, @"Transformed value in to object is not correct");
    }
}




@end
