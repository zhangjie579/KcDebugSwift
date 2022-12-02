//
//  KcFindUIPropertyTooler.h
//  Pods
//
//  Created by 张杰 on 2022/12/2.
//  查找图层树下某个属性

#import <UIKit/UIKit.h>
@class KcPropertyResult;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, KcFindUIPropertyType) {
    /// 背景色
    KcFindUIPropertyTypeBgColor,
    /// 圆角
    KcFindUIPropertyTypeCornerRadius,
    /// 边框
    KcFindUIPropertyTypeBorder,
};

@interface KcFindUIPropertyModel : NSObject

@property (nonatomic) UIView *view;

@property (nonatomic) NSString *propertyDescription;

@property (nonatomic, nullable) KcPropertyResult *propertyResult;

@end

/// 查找图层树某个属性
@interface KcFindUIPropertyTooler : NSObject

/// 查找图层树下某个属性有多少个子树设置
+ (NSArray<KcFindUIPropertyModel *> *)matchSubviewsFromRootView:(UIView *)rootView propertyType:(KcFindUIPropertyType)propertyType;

@end

@interface UIView (KcFindUIProperty)

/// 查找图层树下某个属性有多少个子树设置
- (NSString *)matchSubviewsWithPropertyType:(KcFindUIPropertyType)propertyType;

@end

NS_ASSUME_NONNULL_END
