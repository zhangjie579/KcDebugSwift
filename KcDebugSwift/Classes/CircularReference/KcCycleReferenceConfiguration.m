//
//  KcCycleReferenceConfiguration.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//

#import "KcCycleReferenceConfiguration.h"
#import <objc/message.h>

@implementation KcCycleReferenceConfiguration

+ (instancetype)shardInstance {
    static dispatch_once_t onceToken;
    static KcCycleReferenceConfiguration *configure;
    dispatch_once(&onceToken, ^{
        configure = [[KcCycleReferenceConfiguration alloc] init];
    });
    
    return configure;
}

- (void)addExcludeObjc:(id)objc {
    [self.excludeObjcs addPointer:(__bridge void *)objc];
}

- (BOOL)isExcludeObjc:(id)objc typeName:(NSString *)typeName {
    if (!objc) {
        return true;
    }
    
    // 1.白名单
    // 如果为UIViewController都处理
    if ([objc isKindOfClass:[UIViewController self]]) {
        return false;
    }
    
    // 2.黑名单
    // 过滤命名空间
    NSRange range = [typeName rangeOfString:@"." options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        typeName = [typeName substringFromIndex:range.location + range.length];
    }
    
    if ([self.excludeClassNames containsObject:typeName]) {
        return true;
    }
    
    if ([self.excludeObjcs.allObjects containsObject:objc]) {
        return true;
    }
    
    // 前缀
    for (NSString *prefix in self.excludeClassPrefixName.allObjects) {
        if ([typeName hasPrefix:prefix]) {
            return true;
        }
    }
    
    Class cls = [objc class];
    
    if ([self.excludeClasses containsObject:cls]) {
        return true;
    }
    
    { // 过滤一些系统类的子类
        NSArray<Class> *excludedClassChildClass = @[
            UIView.class,
            UIControl.class,
            UIButton.class,
            UIScrollView.class,
            UIGestureRecognizer.class,
        ];
        
        Class objcCls = NSClassFromString(typeName);
        BOOL isSystemClass = [typeName hasPrefix:@"UI"] || [typeName hasPrefix:@"NS"];
        
        if ([excludedClassChildClass containsObject:objcCls] && isSystemClass) {
            return true;
        }
        
        Class superCls = class_getSuperclass(objcCls);
        
        if (superCls && [excludedClassChildClass containsObject:superCls] && isSystemClass) {
            return true;
        }
        
        if ([typeName hasPrefix:@"UI"]) {
            
        }
    }
    
    return false;
}

#pragma mark - get

- (NSPointerArray *)excludeObjcs {
    if (!_excludeObjcs) {
        _excludeObjcs = [NSPointerArray weakObjectsPointerArray];
    }
    return _excludeObjcs;
}

- (NSMutableSet<Class> *)excludeClasses {
    if (!_excludeClasses) {
        _excludeClasses = [[NSMutableSet alloc] init];
    }
    return _excludeClasses;
}

/// 过滤类名
- (NSMutableSet<NSString *> *)excludeClassNames {
    if (!_excludeClassNames) {
        _excludeClassNames = [[NSMutableSet alloc] initWithArray:@[
            @"Double", @"Float",
            @"UIImage", @"UIEdgeInsets", @"UIView", @"UIButton", @"UILabel", @"UIControl", @"UIScrollView",
            @"Date", @"NSDate",
            @"Data", @"NSData",
            @"NSAttributedString", @"String", @"NSString",
            @"URL", @"NSURL",
            @"UIFieldEditor", // UIAlertControllerTextField
            @"UINavigationBar",
            @"_UIAlertControllerActionView",
            @"_UIVisualEffectBackdropView",
            @"UISwitch",
//            @"UINavigationItem", @"UINavigationBar", @"UIBarItem",
            @"UITraitCollection",
        ]];
    }
    return _excludeClassNames;
}

/// 过滤类的前缀
- (NSMutableSet<NSString *> *)excludeClassPrefixName {
    if (!_excludeClassPrefixName) {
        _excludeClassPrefixName = [[NSMutableSet alloc] initWithArray:@[
            @"Int", @"UInt",
            @"Bool",
            @"CG",
            @"NS",
            @"Kc", @"kc", @"KC",
            @"UIBar", @"UINavigation",
            @"Snp"
        ]];
    }
    return _excludeClassPrefixName;
}

@end
