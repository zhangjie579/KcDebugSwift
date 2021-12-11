//
//  KcRuntimeHelper.m
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/10.
//

#import "KcRuntimeHelper.h"
#import <objc/message.h>

@implementation KcRuntimeHelper

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
