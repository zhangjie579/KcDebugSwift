//
//  KcCycleReferenceConfiguration.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//  配置

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcCycleReferenceConfiguration : NSObject

/// 过滤class name
@property (nonatomic, strong) NSMutableSet<NSString *> *excludeClassNames;

/// 过滤class
@property (nonatomic, strong) NSMutableSet<Class> *excludeClasses;

/// 过滤对象, 用NSValue包装
@property (nonatomic, strong) NSPointerArray *excludeObjcs;

/// 过滤class name的前缀
@property (nonatomic, strong) NSMutableSet<NSString *> *excludeClassPrefixName;

+ (instancetype)shardInstance;

- (void)addExcludeObjc:(id)objc;

/// 是否是过滤的
- (BOOL)isExcludeObjc:(id)objc typeName:(NSString *)typeName;

@end

NS_ASSUME_NONNULL_END
