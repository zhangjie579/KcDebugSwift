//
//  KcObjcCheckoutCycleReference.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//  查询objc的循环引用

#import <Foundation/Foundation.h>
#import "KcCheckoutCycleReferenceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 查询objc的循环引用
@interface KcObjcCheckoutCycleReference : NSObject <KcCheckoutCycleReferenceProtocol>

/// 执行下一个
@property (nonatomic) NSArray<NSString *> *_Nullable(^doNextCycleReference)(KcReferencePropertyInfo *child, NSInteger depth);

@end

NS_ASSUME_NONNULL_END
