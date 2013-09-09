//
//  THOBTestDeallocationVerifier.h
//  THObserversAndBinders
//
//  Created by James Montgomerie on 09/09/2013.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THOBTestDeallocationVerifier : NSObject

- (id)initWithDeallocationFlag:(BOOL *)deallocationFlag;

@property (nonatomic, strong) NSString *testProperty;

@end
