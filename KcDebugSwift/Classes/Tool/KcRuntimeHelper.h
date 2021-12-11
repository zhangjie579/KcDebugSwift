//
//  KcRuntimeHelper.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcRuntimeHelper : NSObject

+ (NSArray<Class> *)objcClassList;

@end

NS_ASSUME_NONNULL_END
