//
//  KcRuntimeHelper.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/10.
//

#import "KcRuntimeHelper.h"
#import <objc/message.h>

@implementation KcRuntimeHelper

/// 所有class list
static CFMutableSetRef registeredClasses;

/// objc 黑名单类 (不需要处理的)
static CFMutableSetRef objcBlackClasses;

+ (void)updateRegisteredClasses {
    if (!registeredClasses) {
        registeredClasses = CFSetCreateMutable(NULL, 0, NULL);
    } else {
        CFSetRemoveAllValues(registeredClasses);
    }
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int i = 0; i < count; i++) { // 用NSMutableArray存会crash JSExport
        CFSetAddValue(registeredClasses, (__bridge const void *)(classes[i]));
    }
    free(classes);
}

#pragma mark - 黑名单

/// 更新黑名单的类
+ (void)updateBlackClass {
    if (!objcBlackClasses) {
        objcBlackClasses = CFSetCreateMutable(NULL, 0, NULL);
    } else {
        CFSetRemoveAllValues(registeredClasses);
    }
    
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int i = 0; i < count; i++) {
        const char *name = class_getName(classes[i]);
        if (name == NULL) {
            continue;
        }
        if ((strncmp(name, "_", 1) == 0 && strncmp(name, "__NS", 4) != 0 && strncmp(name,"_NS",3) != 0)
            || strncmp(name,"__NSCFType",10) == 0) {
            CFSetAddValue(objcBlackClasses, (__bridge const void *)(classes[i]));
        }
    }
    free(classes);
}

/// 是否是黑名单class
+ (BOOL)isBlackClass:(Class)cls {
    return CFSetContainsValue(objcBlackClasses, (__bridge const void *)cls);
}

+ (BOOL)isBlackClassWithObjc:(id)objc {
    Class cls = [objc class];
    return CFSetContainsValue(objcBlackClasses, (__bridge const void *)cls);
}

+ (NSArray<Class> *)objcClassList {
//    UInt32 count = 0;
//
//    NSMutableArray<Class> *result = [NSMutableArray array];
//    Class *classList = objc_copyClassList(&count);
//
//    for (UInt32 i = 0; i < count; i++) {
//        [result addObject:classList[i]];
//    }
//
//    return result;
    
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL,0);
    
    NSMutableArray<Class> *result = [NSMutableArray array];
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        // swift下会crash
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            NSLog(@"%@", classes[i]);
            [result addObject:classes[i]];
        }
        free(classes);
    }
    
    return result;
}

@end
