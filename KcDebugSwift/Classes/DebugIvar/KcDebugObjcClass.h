//
//  KcDebugObjcClass.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/4/20.
//  调试objc对象、布局

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcDebugObjcClass : NSObject

/// 所有方法(包括层级)
+ (NSString *)methodsWithClass:(Class)cls;

/// 所有自定义方法
+ (NSString *)customMethodsWithClass:(Class)cls;

/// 获取所有成员变量
+ (NSString *)ivarsWithObjc:(id)objc;

@end

NS_ASSUME_NONNULL_END
