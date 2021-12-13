//
//  KcReferencePropertyInfo.h
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcReferencePropertyInfo : NSObject

@property (nonatomic, copy, nullable) NSString *name;

@property (nonatomic, weak, nullable) id value;

@property (nonatomic) BOOL isStrong;

//@property (nonatomic) BOOL isVar;

/// 当前自定义swift class的属性的count
/// _getChildMetadata 获取信息, 传入的index 需要加上super的count
@property (nonatomic) NSInteger currentCustomSwiftClassPropertyCount;

@property (nonatomic, weak, nullable) KcReferencePropertyInfo *superProperty;

@property (nonatomic, strong) NSMutableArray<KcReferencePropertyInfo *> *childrens;

@property (nonatomic, nullable, readonly) Class clsType;

/// 格式化后的name
@property (nonatomic, copy, readonly) NSString *formatterPropertyName;

/// keyPath
@property (nonatomic, copy, readonly) NSString *propertyKeyPath;

@end

NS_ASSUME_NONNULL_END
