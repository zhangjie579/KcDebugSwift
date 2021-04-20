//
//  KcDebugObjcClass.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/4/20.
//

#import "KcDebugObjcClass.h"

@implementation KcDebugObjcClass

/// 所有方法(包括层级)
+ (NSString *)methodsWithClass:(Class)cls {
    NSString *description = [self performSelectorName:@"_methodDescription" target:cls];
    NSLog(@"%@", description);
    return description;
}

/// 所有自定义方法
+ (NSString *)customMethodsWithClass:(Class)cls {
    NSString *description = [self performSelectorName:@"_shortMethodDescription" target:cls];
    NSLog(@"%@", description);
    return description;
}

/// 获取所有成员变量
+ (NSString *)ivarsWithObjc:(id)objc {
    NSString *description = [self performSelectorName:@"_ivarDescription" target:objc];
    NSLog(@"%@", description);
    return description;
}
//
///// 打印ViewController的层级
//- (void)kc_debug_viewControllerHierarchy {
//    #pragma clang diagnostic push
//    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//    NSString *description = [self performSelector:NSSelectorFromString(@"_printHierarchy")];
//    #pragma clang diagnostic pop
//    NSLog(@"%@", description);
//}
//
//+ (NSString *)kc_debug_rootWindowViewHierarchy {
//    return [UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.delegate.window kc_debug_viewHierarchy];
//}
//
//+ (NSString *)kc_debug_keyWindowViewHierarchy {
//    return [UIApplication.sharedApplication.keyWindow kc_debug_viewHierarchy];
//}
//
///// 打印view层级
//- (NSString *)kc_debug_viewHierarchy {
//    #pragma clang diagnostic push
//    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//    NSString *description = [self performSelector:NSSelectorFromString(@"recursiveDescription")];
//    #pragma clang diagnostic pop
//    NSLog(@"%@", description);
//    return description;
//}
//
///// 打印自动布局层级
//- (NSString *)kc_debug_autoLayoutHierarchy {
//    #pragma clang diagnostic push
//    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//    NSString *description = [self performSelector:NSSelectorFromString(@"_autolayoutTrace")];
//    #pragma clang diagnostic pop
//    NSLog(@"%@", description);
//    return description;
//}

+ (id)performSelectorName:(NSString *)selectorName target:(id)target {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:NSSelectorFromString(selectorName)];
    #pragma clang diagnostic pop
}

@end
