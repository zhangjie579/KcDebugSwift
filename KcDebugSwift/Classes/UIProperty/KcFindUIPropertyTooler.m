//
//  KcFindUIPropertyTooler.m
//  Pods
//
//  Created by 张杰 on 2022/12/2.
//

#import "KcFindUIPropertyTooler.h"
#if __has_include("KcDebugSwift/KcDebugSwift-Swift.h")
    #import "KcDebugSwift/KcDebugSwift-Swift.h"
#else
    #import "KcDebugSwift-Swift.h"
#endif

@implementation KcFindUIPropertyTooler

/// 查找图层树下某个属性有多少个子树设置
+ (NSArray<KcFindUIPropertyModel *> *)matchSubviewsFromRootView:(UIView *)rootView propertyType:(KcFindUIPropertyType)propertyType {
    NSMutableArray<KcFindUIPropertyModel *> *resultArray = [[NSMutableArray alloc] init];
    
    [self matchSubviewsFromRootView:rootView propertyType:propertyType resultArray:resultArray];
    
    return resultArray;
}

// MARK: - private

+ (void)matchSubviewsFromRootView:(UIView *)rootView
                     propertyType:(KcFindUIPropertyType)propertyType
                      resultArray:(NSMutableArray<KcFindUIPropertyModel *> *)resultArray {
    id<KcFindUIPropertyService> service = [self getFindUIPropertyTypeService:propertyType];
    
    if ([service matchPropertyWithView:rootView]) {
        KcFindUIPropertyModel *model = [[KcFindUIPropertyModel alloc] init];
        model.view = rootView;
        model.propertyDescription = [service propertyDescriptionWithView:rootView];
        model.propertyResult = [rootView kc_debug_findPropertyNameResult];
        
        [resultArray addObject:model];
    }
    
    for (UIView *childView in rootView.subviews) {
        [self matchSubviewsFromRootView:childView propertyType:propertyType resultArray:resultArray];
    }
}

+ (id<KcFindUIPropertyService>)getFindUIPropertyTypeService:(KcFindUIPropertyType)propertyType {
    switch (propertyType) {
        case KcFindUIPropertyTypeBgColor:
            return [[KcFindUIBgColorProperty alloc] init];
        case KcFindUIPropertyTypeCornerRadius:
            return [[KcFindUICornerRadiusProperty alloc] init];
        case KcFindUIPropertyTypeBorder:
            return [[KcFindUIBorderProperty alloc] init];
    }
}

@end

#pragma mark - KcFindUIPropertyModel

@implementation KcFindUIPropertyModel

@end

@implementation UIView (KcFindUIProperty)

/// 查找图层树下某个属性有多少个子树设置
- (NSString *)matchSubviewsWithPropertyType:(KcFindUIPropertyType)propertyType {
    NSArray<KcFindUIPropertyModel *> *results = [KcFindUIPropertyTooler matchSubviewsFromRootView:self propertyType:propertyType];
    
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    
    for (KcFindUIPropertyModel *model in results) {
        [mutableString appendFormat:@"<%@: %p>\n", NSStringFromClass(model.view.class), model.view];
        [mutableString appendFormat:@"    %@\n", model.propertyDescription];
        [mutableString appendFormat:@"    %@\n", model.propertyResult.debugLog ?: @"未找到属性名😭"];
    }
    
    return mutableString.copy;
}

@end
