//
//  NSObject+DLIntrospection.h
//  DLIntrospection
//
//  Created by Denis Lebedev on 12/27/12.
//  Copyright (c) 2012 Denis Lebedev. All rights reserved.
//  类的信息

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (DLIntrospection)

+ (NSArray *)classes;
+ (nullable NSArray *)properties;
+ (nullable NSArray *)instanceVariables;
+ (NSArray *)classMethods;
+ (NSArray *)instanceMethods;

+ (NSArray *)protocols;
+ (NSDictionary *)descriptionForProtocol:(Protocol *)proto;


+ (NSString *)parentClassHierarchy;
@end

NS_ASSUME_NONNULL_END
