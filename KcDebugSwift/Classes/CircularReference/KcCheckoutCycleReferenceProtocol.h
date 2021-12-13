//
//  KcCheckoutCycleReferenceProtocol.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/12.
//

#ifndef KcCheckoutCycleReferenceProtocol_h
#define KcCheckoutCycleReferenceProtocol_h

@class KcReferencePropertyInfo;

NS_ASSUME_NONNULL_BEGIN

/// 查询循环引用
@protocol KcCheckoutCycleReferenceProtocol <NSObject>

/// 最大查询深度
@property (nonatomic) NSInteger maxDepth;

/// 谁的循环引用
@property (nonatomic, weak) id reflectingObjc;

/// 查找
- (nullable NSMutableArray<NSString *> *)startFindStrongReferenceWithProperty:(KcReferencePropertyInfo *)property depth:(NSInteger)depth;

- (size_t)objectAddress;

/**
 @return class of the object
 */
- (nullable Class)objectClass;

@end

NS_ASSUME_NONNULL_END

#endif /* KcCheckoutCycleReferenceProtocol_h */
