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

/// 查找图层树下某个属性有多少个子树设置
+ (NSArray<KcFindUIPropertyModel *> *)matchSubviewsFromRootView:(UIView *)rootView propertyName:(NSString *)propertyName;

@end

@interface UIView (KcFindUIProperty)

/// 查找图层树下某个属性有多少个子树设置
/// e -l objc++ -O -- [0x7fea43513c50 matchSubviewsWithPropertyType:1]
- (NSString *)matchSubviewsWithPropertyType:(KcFindUIPropertyType)propertyType;

/// 查找图层树下某个属性有多少个子树设置
/// e -l objc++ -O -- [0x7fea43513c50 matchSubviewsWithPropertyName:@"image"]
- (NSString *)matchSubviewsWithPropertyName:(NSString *)propertyName;


- (NSString *)matchSuperviewsWithPropertyName:(NSString *)propertyName;

@end

NS_ASSUME_NONNULL_END
