//
//  NSObject+KcDebugObjcClass.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/4/20.
//  调试objc对象、布局

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 使用自定义的class包装方法需要强转使用 [KcDebugObjcClass ivarsWithObjc:(NSObject *)0x7fea43513c50] so才扩展的NSObject方法
// 使用: e -l objc -O -- [0x7fea43513c50 kc_log_methods]
// expr -l objc++ -O -- [0x7fea43513c50 kc_log_methods]
// 如果address为对象: e -l objc -O -- [[0x7fb35dd09390 class] kc_log_methods]
@interface NSObject (KcDebugObjcClass)

#pragma mark - objc class相关属性

/// 所有方法(包括层级)
+ (NSString *)kc_log_methods;

/// 所有自定义方法
+ (NSString *)kc_log_customMethods;

/// 获取所有成员变量
- (NSString *)kc_log_ivars;

#pragma mark - UI、布局相关
/// 系统的扩展 (UIView (UIConstraintBasedLayoutDebugging)), 通过view.hasAmbiguousLayout 找到对应定义地方

+ (NSString *)kc_log_rootWindowViewHierarchy;

+ (NSString *)kc_log_keyWindowViewHierarchy;

/// 打印view层级
- (NSString *)kc_log_viewHierarchy;

/// 打印ViewController的层级
- (void)kc_log_viewControllerHierarchy;

/// 打印自动布局层级
- (NSString *)kc_log_autoLayoutHierarchy;

@end

NS_ASSUME_NONNULL_END
