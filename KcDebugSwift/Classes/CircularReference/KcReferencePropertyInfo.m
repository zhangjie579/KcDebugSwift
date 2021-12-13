//
//  KcReferencePropertyInfo.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//

#import "KcReferencePropertyInfo.h"

// 为了处理静态库、动态库的情况
#if __has_include("KcDebugSwift/KcDebugSwift-Swift.h")
#import "KcDebugSwift/KcDebugSwift-Swift.h"
#else
#import "KcDebugSwift-Swift.h"
#endif

@implementation KcReferencePropertyInfo

- (instancetype)init {
    if (self = [super init]) {
        self.isStrong = false;
        self.currentCustomSwiftClassPropertyCount = 0;
    }
    return self;
}

/// 格式化后的属性name
- (NSString *)formatterPropertyName {
    return [self.name kc_formatterPropertyName];
}

/// keyPath
- (NSString *)propertyKeyPath {
    KcReferencePropertyInfo *preNode = self;
    
    NSMutableArray<NSString *> *keyPath = [[NSMutableArray alloc] init];
    while (preNode) {
        if (preNode.name && preNode.name.length > 0) {
            [keyPath addObject:preNode.formatterPropertyName];
        }
        
        preNode = preNode.superProperty;
    }
    if (keyPath.count <= 0) {
        return @"";
    }
    
    return [keyPath.reverseObjectEnumerator.allObjects componentsJoinedByString:@"->"];
}

- (BOOL)isEqual:(id)object {
    if (!self.value || !object) {
        return false;
    }
    
    uint64_t lhsAddress = (uint64_t)self.value;
    uint64_t rhsAddress = (uint64_t)object;
    
    return lhsAddress == rhsAddress;
}

- (Class)clsType {
    return [self.value class];
}

- (NSMutableArray<KcReferencePropertyInfo *> *)childrens {
    if (!_childrens) {
        _childrens = [[NSMutableArray alloc] init];
    }
    return _childrens;
}

@end
