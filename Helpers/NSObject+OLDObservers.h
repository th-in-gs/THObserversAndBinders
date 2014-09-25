//
//  NSObject+Observers.h
//  THObserversAndBinders
//
//  Created by Maxim Khatskevich on 12/10/13.
//  Copyright (c) 2013 Maxim Khatskevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THObserversAndBinders.h"

@interface NSObject (OLDObservers)

@property (readonly, nonatomic) NSMutableArray *observerList;
@property (readonly, nonatomic) NSMutableArray *binderList;

- (void)removeObservers;
- (void)removeBinders;
- (void)removeObserversAndBinders;

@end
