//
//  NSObject+KcDebugObjcClass.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/4/20.
//

#import "NSObject+KcDebugObjcClass.h"

@implementation NSObject (KcDebugObjcClass)

#pragma mark - objc class相关属性

/// 所有方法(包括层级)
+ (NSString *)kc_log_methods {
    NSString *description = [self kc_log_performSelectorName:@"_methodDescription"];
    NSLog(@"%@", description);
    return description;
}

/// 所有自定义方法
+ (NSString *)kc_log_customMethods {
    NSString *description = [self kc_log_performSelectorName:@"_shortMethodDescription"];
    NSLog(@"%@", description);
    return description;
}

/// 获取所有成员变量
- (NSString *)kc_log_ivars {
    NSString *description = [self kc_log_performSelectorName:@"_ivarDescription"];
    NSLog(@"%@", description);
    return description;
}

#pragma mark - UI、布局相关

+ (NSString *)kc_log_rootWindowViewHierarchy {
    return [UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.delegate.window kc_log_viewHierarchy];
}

+ (NSString *)kc_log_keyWindowViewHierarchy {
    return [UIApplication.sharedApplication.keyWindow kc_log_viewHierarchy];
}

/// 打印view层级
- (NSString *)kc_log_viewHierarchy {
    NSString *description = [self kc_log_performSelectorName:@"recursiveDescription"];
    NSLog(@"%@", description);
    return description;
}

/// 打印ViewController的层级
- (void)kc_log_viewControllerHierarchy {
    NSString *description = [self kc_log_performSelectorName:@"_printHierarchy"];
    NSLog(@"%@", description);
}

/// 打印自动布局层级
- (NSString *)kc_log_autoLayoutHierarchy {
    NSString *description = [self kc_log_performSelectorName:@"_autolayoutTrace"];
    NSLog(@"%@", description);
    return description;
}

#pragma mark - private

+ (id)kc_log_performSelectorName:(NSString *)selectorName {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:NSSelectorFromString(selectorName)];
    #pragma clang diagnostic pop
}

- (id)kc_log_performSelectorName:(NSString *)selectorName {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:NSSelectorFromString(selectorName)];
    #pragma clang diagnostic pop
}

@end
