//
//  NSObject+KcObjcDump.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//

#import "NSObject+KcObjcDump.h"
//#import "KcDebugSwift/KcDebugSwift-Swift.h"

@implementation NSObject (KcObjcDump)

// MAKR: - dump swift

+ (void)kc_dump_swiftValue:(id)objc {
//    [NSObject kc_dumpSwift:objc];
    [NSObject performSelector:NSSelectorFromString(@"kc_dumpSwift:") withObject:objc];
}

// MAKR: - dump objective-c

/// 所有方法(包括层级)
+ (NSString *)kc_dump_allMethodDescription {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"_methodDescription")];
    #pragma clang diagnostic pop
    return description;
}

/// 所有自定义方法
+ (NSString *)kc_dump_allCustomMethodDescription {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"_shortMethodDescription")];
    #pragma clang diagnostic pop
    return description;
}

/// 某个class的方法描述
+ (NSString *)kc_dump_methodDescriptionForClass:(Class)cls {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"__methodDescriptionForClass:") withObject:cls];
    #pragma clang diagnostic pop
    return description;
}

/// 所有属性的描述
+ (NSString *)kc_dump_allPropertyDescription {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"_propertyDescription")];
    #pragma clang diagnostic pop
    return description;
}

+ (NSString *)kc_dump_propertyDescriptionForClass:(Class)cls {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"__propertyDescriptionForClass:") withObject:cls];
    #pragma clang diagnostic pop
    return description;
}

/// 获取所有成员变量
- (NSString *)kc_dump_allIvarDescription {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"_ivarDescription")];
    #pragma clang diagnostic pop
    return description;
}

- (NSString *)kc_dump_ivarDescriptionForClass:(Class)cls {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *description = [self performSelector:NSSelectorFromString(@"__ivarDescriptionForClass:") withObject:cls];
    #pragma clang diagnostic pop
    return description;
}

#pragma mark - UI、布局相关

+ (NSString *)kc_dump_rootWindowViewHierarchy {
    return [UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.delegate.window kc_dump_viewHierarchy];
}

+ (NSString *)kc_dump_keyWindowViewHierarchy {
    return [UIApplication.sharedApplication.keyWindow kc_dump_viewHierarchy];
}

/// 打印view层级
- (NSString *)kc_dump_viewHierarchy {
    NSString *description = [self kc_log_performSelectorName:@"recursiveDescription"];
    return description;
}

/// 打印ViewController的层级
- (NSString *)kc_dump_viewControllerHierarchy {
    NSString *description = [self kc_log_performSelectorName:@"_printHierarchy"];
    return description;
}

/// 打印自动布局层级
- (NSString *)kc_dump_autoLayoutHierarchy {
    NSString *description = [self kc_log_performSelectorName:@"_autolayoutTrace"];
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
