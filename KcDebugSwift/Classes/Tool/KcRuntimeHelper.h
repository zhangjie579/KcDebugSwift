//
//  KcRuntimeHelper.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcRuntimeHelper : NSObject

+ (void)updateRegisteredClasses;

/// 更新黑名单的类
+ (void)updateBlackClass;

+ (BOOL)isBlackClassWithObjc:(id)objc;

/// 是否是黑名单class
+ (BOOL)isBlackClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
