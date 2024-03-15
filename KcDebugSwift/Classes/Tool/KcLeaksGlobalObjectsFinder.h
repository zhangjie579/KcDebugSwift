//
//  MLeaksGlobalObjectsFinder.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcLeaksGlobalObjectsFinder : NSObject

/// 对象 -> 指针
+ (uintptr_t)addreeWithObjc:(id)objc;

+ (void)contatinObjc:(id)objc;

/// 获取所有全局对象（__DATA.__bss __DATA.__common section）
/// 问题:
///     1. 对于全局对象: 只能获取到已经使用过的, 因为未使用的话, 未初始化, 不知道值, so可能需要用过后再次调用这个方法⚠️
//+ (NSArray<NSObject *> *)globalObjects;
+ (CFMutableSetRef)globalObjects;

@end

NS_ASSUME_NONNULL_END
