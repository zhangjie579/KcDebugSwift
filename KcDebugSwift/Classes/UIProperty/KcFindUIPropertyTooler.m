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
    return [self matchSubviewsFromRootView:rootView propertyName:[self propertyNameWithPropertyType:propertyType]];
}

/// 查找图层树下某个属性有多少个子树设置
+ (NSArray<KcFindUIPropertyModel *> *)matchSubviewsFromRootView:(UIView *)rootView propertyName:(NSString *)propertyName {
    NSMutableArray<KcFindUIPropertyModel *> *resultArray = [[NSMutableArray alloc] init];
    
    [self matchSubviewsFromRootView:rootView propertyName:propertyName resultArray:resultArray];
    
    return resultArray;
}

+ (NSArray<KcFindUIPropertyModel *> *)matchSuperviewsFromRootView:(UIView *)rootView propertyName:(NSString *)propertyName {
    NSMutableArray<KcFindUIPropertyModel *> *resultArray = [[NSMutableArray alloc] init];
    
    id<KcFindUIPropertyService> service = [self getFindUIPropertyTypeService:propertyName];
    
    UIView *view = rootView;
    while (view != nil) {
        if ([service matchPropertyWithView:view]) {
            KcFindUIPropertyModel *model = [[KcFindUIPropertyModel alloc] init];
            model.view = view;
            model.propertyDescription = [service propertyDescriptionWithView:view];
            model.propertyResult = [view kc_debug_findPropertyNameResult];
            
            [resultArray addObject:model];
        }
        
        view = view.superview;
    }
    
    return resultArray;
}

// MARK: - private

+ (void)matchSubviewsFromRootView:(UIView *)rootView
                     propertyName:(NSString *)propertyName
                      resultArray:(NSMutableArray<KcFindUIPropertyModel *> *)resultArray {
    id<KcFindUIPropertyService> service = [self getFindUIPropertyTypeService:propertyName];
    
    if ([service matchPropertyWithView:rootView]) {
        KcFindUIPropertyModel *model = [[KcFindUIPropertyModel alloc] init];
        model.view = rootView;
        model.propertyDescription = [service propertyDescriptionWithView:rootView];
        model.propertyResult = [rootView kc_debug_findPropertyNameResult];
        
        [resultArray addObject:model];
    }
    
    for (UIView *childView in rootView.subviews) {
        [self matchSubviewsFromRootView:childView propertyName:propertyName resultArray:resultArray];
    }
}

+ (id<KcFindUIPropertyService>)getFindUIPropertyTypeService:(NSString *)propertyName {
    NSString *name = propertyName.lowercaseString;
    
    if ([name isEqualToString:@"backgroundcolor"]) {
        return [[KcFindUIBgColorProperty alloc] init];
    } else if ([name isEqualToString:@"cornerradius"]) {
        return [[KcFindUICornerRadiusProperty alloc] init];
    } else if ([name isEqualToString:@"bordercolor"] || [name isEqualToString:@"borderwidth"]) {
        return [[KcFindUIBorderProperty alloc] init];
    } else {
        return [[KcFindUIPropertyName alloc] initWithPropertyName:propertyName];
    }
}

+ (NSString *)propertyNameWithPropertyType:(KcFindUIPropertyType)propertyType {
    switch (propertyType) {
        case KcFindUIPropertyTypeBgColor:
            return @"backgroundColor";
        case KcFindUIPropertyTypeCornerRadius:
            return @"cornerRadius";
        case KcFindUIPropertyTypeBorder:
            return @"borderColor";
    }
}

@end

#pragma mark - KcFindUIPropertyModel

@implementation KcFindUIPropertyModel

@end

@implementation UIView (KcFindUIProperty)

/// 查找图层树下某个属性有多少个子树设置
- (NSString *)matchSubviewsWithPropertyType:(KcFindUIPropertyType)propertyType {
    return [self matchSubviewsWithPropertyName:[KcFindUIPropertyTooler propertyNameWithPropertyType:propertyType]];
}

/// 查找图层树下某个属性有多少个子树设置
- (NSString *)matchSubviewsWithPropertyName:(NSString *)propertyName {
    NSArray<KcFindUIPropertyModel *> *results = [KcFindUIPropertyTooler matchSubviewsFromRootView:self propertyName:propertyName];
    
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    
    for (KcFindUIPropertyModel *model in results) {
        [mutableString appendFormat:@"<%@: %p>\n", NSStringFromClass(model.view.class), model.view];
        [mutableString appendFormat:@"    %@\n", model.propertyDescription];
        [mutableString appendFormat:@"    %@\n", model.propertyResult.debugLog ?: @"未找到属性名😭"];
    }
    
    return mutableString.copy;
}

- (NSString *)matchSuperviewsWithPropertyName:(NSString *)propertyName {
    NSArray<KcFindUIPropertyModel *> *results = [KcFindUIPropertyTooler matchSuperviewsFromRootView:self propertyName:propertyName];
    
    NSMutableString *mutableString = [[NSMutableString alloc] init];
    
    for (KcFindUIPropertyModel *model in results) {
        [mutableString appendFormat:@"<%@: %p>\n", NSStringFromClass(model.view.class), model.view];
        [mutableString appendFormat:@"    %@\n", model.propertyDescription];
        [mutableString appendFormat:@"    %@\n", model.propertyResult.debugLog ?: @"未找到属性名😭"];
    }
    
    return mutableString.copy;
}

@end
