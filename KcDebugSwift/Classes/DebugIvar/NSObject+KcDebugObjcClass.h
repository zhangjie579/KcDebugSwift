//
//  NSObject+KcDebugObjcClass.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/4/20.
//  调试objc对象、布局

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/* 常用的lldb调试命令
 
 1.help 什么
    * help express ...
 2.执行
    * e
    * p
    * frame variable
    * po
 3.swift - oc 相互转换
    * 在swift环境中 expression -l swift —
    * oc环境中 expr -l objc++ -O --
 4.根据内存查找崩溃信息的位置
    * image lookup --address 0x00000001041d3936
 5.查看内存情况
    * language swift refcount 对象
 6.监听某个对象
    * watch set variable dog->_skill
 7.打印寄存器
    * po $arg1 $arg2
 
 线程、帧相关
    * 帧信息: frame info
    * 所有线程: thread list
    * thread info
    * 堆栈信息: bt
 
 别名
    * command alias poc expression -l objc -O --
 
 读取寄存器
    * register read $arg1 $arg2
 */

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
