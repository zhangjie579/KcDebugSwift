//
//  KcObjcCheckoutCycleReference.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//

#import "KcObjcCheckoutCycleReference.h"
#import <objc/runtime.h>
#import "FBClassStrongLayout.h"
#import "FBObjectReference.h"
#import "KcReferencePropertyInfo.h"
#import "KcCycleReferenceConfiguration.h"
#import "FBAssociationManager.h"

@implementation KcObjcCheckoutCycleReference

static NSMutableDictionary<Class, NSArray<id<FBObjectReference>> *> *layoutCache;

#pragma mark - 打开关联对象的检测

+ (void)load {
    [FBAssociationManager hook];
}

/// 查找
- (nullable NSMutableArray<NSString *> *)startFindStrongReferenceWithProperty:(KcReferencePropertyInfo *)property depth:(NSInteger)depth {
    if (depth > self.maxDepth || !property.value) {
        return nil;
    }
    
    Class aCls = object_getClass(property.value);
    if (!aCls) {
        return nil;
    }
    
    if (class_isMetaClass(aCls)) {
        return nil;
    }
    
    if ([property.value isMemberOfClass:[NSObject class]]) {
        return nil;
    }
    
    BOOL isExcluded = [KcCycleReferenceConfiguration.shardInstance isExcludeObjc:property.value typeName:NSStringFromClass(aCls)];
    if (isExcluded) {
        return nil;
    }
    
    if (!layoutCache) {
        layoutCache = [[NSMutableDictionary alloc] init];
    }
    
    NSArray *strongIvars = FBGetObjectStrongReferences(property.value, layoutCache);

    NSMutableArray<NSString *> *cycleKeyPath = [[NSMutableArray alloc] init];
    
    for (id<FBObjectReference> ref in strongIvars) {
        // 过滤私有属性
        if ([ref.name hasPrefix:@"__"]) {
            continue;
        }
        
        id referencedObject = [ref objectReferenceFromObject:property.value];
        
        if (!referencedObject) {
            continue;
        }
        
        BOOL isExcluded = [KcCycleReferenceConfiguration.shardInstance isExcludeObjc:referencedObject typeName:NSStringFromClass([referencedObject class])];
        if (isExcluded) {
            continue;
        }
        
        KcReferencePropertyInfo *childProperty = [self.class makePropertyFieldWithReferencedObject:referencedObject ref:ref name:@"" superProperty:property];
        [property.childrens addObject:childProperty];
        
//        NSLog(@"dd 1--- %@", childProperty.propertyKeyPath);
        
        if ([childProperty isEqual:self.reflectingObjc]) {
            [cycleKeyPath addObject:childProperty.propertyKeyPath];
            continue;
        }
        
        NSArray<NSString *> *_Nullable childKeyPath = [self findCycleModelInModelWithProperty:childProperty depth:depth + 1];
        if (childKeyPath && childKeyPath.count > 0) {
            [cycleKeyPath addObjectsFromArray:childKeyPath];
        }
    }
//
    return cycleKeyPath;
}

/// 查询model中model的循环引用
- (NSMutableArray<NSString *> *)findCycleModelInModelWithProperty:(KcReferencePropertyInfo *)property depth:(NSInteger)depth {
    id referencedObject = property.value;
    NSMutableArray<NSString *> *cycleKeyPath = [[NSMutableArray alloc] init];
    
    if ([referencedObject isKindOfClass:[NSArray class]]) {
        NSArray<NSString *> *childKeyPath = [self handleCollectionObjc:referencedObject
                                                              property:property
                                                                 depth:depth + 1];
        [cycleKeyPath addObjectsFromArray:childKeyPath];
    } else if ([referencedObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)referencedObject;
        NSArray<NSString *> *childKeyPath = [self handleDictCycleReference:dict
                                                                  property:property
                                                                     depth:depth + 1];
        [cycleKeyPath addObjectsFromArray:childKeyPath];
    } else if ([referencedObject isKindOfClass:[NSSet class]]) {
        NSSet *set = (NSSet *)referencedObject;
        NSArray<NSString *> *childKeyPath = [self handleCollectionObjc:set.allObjects
                                                              property:property
                                                                 depth:depth + 1];
        [cycleKeyPath addObjectsFromArray:childKeyPath];
    } else {
        NSArray<NSString *> *_Nullable childKeyPath = self.doNextCycleReference(property, depth + 1);
        if (childKeyPath && childKeyPath.count > 0) {
            [cycleKeyPath addObjectsFromArray:childKeyPath];
        }
    }
    
    return cycleKeyPath;
}

/// 查询dict的循环引用
- (NSMutableArray<NSString *> *)handleDictCycleReference:(NSDictionary *)dict property:(KcReferencePropertyInfo *)property depth:(NSInteger)depth {
    NSMutableArray<NSString *> *cycleKeyPath = [[NSMutableArray alloc] init];
    
    for (id key in dict.allKeys) {
        id value = dict[key];
        
        if (!value) {
            continue;
        }
        
        BOOL isExcluded = [KcCycleReferenceConfiguration.shardInstance isExcludeObjc:value typeName:NSStringFromClass([value class])];
        if (isExcluded) {
            continue;
        }
        
        NSString *name = [NSString stringWithFormat:@"%@", [key description] ?: @""];
        
        KcReferencePropertyInfo *child = [self.class makePropertyFieldWithReferencedObject:value ref:nil name:name superProperty:property];
        [property.childrens addObject:child];
        
        if ([self isFindCycleReference:child]) {
            [cycleKeyPath addObject:child.propertyKeyPath];
            continue;
        }
        
        // 因为element还可能是集合
        NSArray<NSString *> *_Nullable childKeyPath = [self findCycleModelInModelWithProperty:child depth:depth + 1];
        if (childKeyPath && childKeyPath.count > 0) {
            [cycleKeyPath addObjectsFromArray:childKeyPath];
        }
    }
    
    return cycleKeyPath;
}

/// 查询集合
- (NSMutableArray<NSString *> *)handleCollectionObjc:(NSArray<id> *)array property:(KcReferencePropertyInfo *)property depth:(NSInteger)depth {
    
    NSMutableArray<NSString *> *cycleKeyPath = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < array.count; i++) {
        id element = array[i];
        
        if (!element) {
            continue;
        }
        
        BOOL isExcluded = [KcCycleReferenceConfiguration.shardInstance isExcludeObjc:element typeName:NSStringFromClass([element class])];
        if (isExcluded) {
            continue;
        }
        
        NSString *name = [NSString stringWithFormat:@"%ld", i];
        
        KcReferencePropertyInfo *child = [self.class makePropertyFieldWithReferencedObject:element ref:nil name:name superProperty:property];
        [property.childrens addObject:child];
        
        if ([self isFindCycleReference:child]) {
            [cycleKeyPath addObject:child.propertyKeyPath];
            
            return cycleKeyPath;
        }
        
        NSArray<NSString *> *_Nullable childKeyPath = [self findCycleModelInModelWithProperty:child depth:depth + 1];
        if (childKeyPath && childKeyPath.count > 0) {
            [cycleKeyPath addObjectsFromArray:childKeyPath];
        }
    }
    
    return cycleKeyPath;
}

- (BOOL)isFindCycleReference:(KcReferencePropertyInfo *)property {
    if ((uint64_t)property.value == (uint64_t)self.objectAddress) {
        return true;
    }
    
//    if ([property isEqual:self.reflecting]) {
//        return true;
//    }
    return false;
}

//- (BOOL)_objectRetainsEnumerableValues
//{
//  if ([self.object respondsToSelector:@selector(valuePointerFunctions)]) {
//    NSPointerFunctions *pointerFunctions = [self.object valuePointerFunctions];
//    if (pointerFunctions.acquireFunction == NULL) {
//      return NO;
//    }
//    if (pointerFunctions.usesWeakReadAndWriteBarriers) {
//      return NO;
//    }
//  }
//
//  return YES;
//}
//
//- (BOOL)_objectRetainsEnumerableKeys
//{
//  if ([self.object respondsToSelector:@selector(pointerFunctions)]) {
//    // NSHashTable and similar
//    // If object shows what pointer functions are used, lets try to determine
//    // if it's not retaining objects
//    NSPointerFunctions *pointerFunctions = [self.object pointerFunctions];
//    if (pointerFunctions.acquireFunction == NULL) {
//      return NO;
//    }
//    if (pointerFunctions.usesWeakReadAndWriteBarriers) {
//      // It's weak - we should not touch it
//      return NO;
//    }
//  }
//
//  if ([self.object respondsToSelector:@selector(keyPointerFunctions)]) {
//    NSPointerFunctions *pointerFunctions = [self.object keyPointerFunctions];
//    if (pointerFunctions.acquireFunction == NULL) {
//      return NO;
//    }
//    if (pointerFunctions.usesWeakReadAndWriteBarriers) {
//      return NO;
//    }
//  }
//
//  return YES;
//}

+ (KcReferencePropertyInfo *)makePropertyFieldWithReferencedObject:(id)referencedObject
                                                               ref:(nullable id<FBObjectReference>)ref
                                                              name:(NSString *)name
                                           superProperty:(KcReferencePropertyInfo *)superProperty {
    KcReferencePropertyInfo *childProperty = [[KcReferencePropertyInfo alloc] init];
    childProperty.name = ref.name ?: name;
    childProperty.isStrong = true;
    childProperty.value = referencedObject;
    childProperty.superProperty = superProperty;
//        childProperty.type = aCls;
    
    return childProperty;
}

- (size_t)objectAddress {
    return (size_t)self.reflectingObjc;
}

/**
 @return class of the object
 */
- (nullable Class)objectClass {
    return [self.reflectingObjc class];
}

@synthesize maxDepth = _maxDepth;

@synthesize reflectingObjc = _reflectingObjc;

@end
