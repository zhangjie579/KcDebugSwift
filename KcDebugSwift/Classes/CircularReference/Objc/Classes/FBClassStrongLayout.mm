/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBClassStrongLayout.h"

//#import <math.h>
//#import <memory>
#import <objc/runtime.h>
//#import <vector>

#import <UIKit/UIKit.h>

#import "FBIvarReference.h"


NSArray<id<FBObjectReference>> *FBGetClassReferences(Class aCls) {
  NSMutableArray<id<FBObjectReference>> *result = [NSMutableArray new];

  unsigned int count;
  Ivar *ivars = class_copyIvarList(aCls, &count);

  for (unsigned int i = 0; i < count; ++i) {
    Ivar ivar = ivars[i];
    FBIvarReference *wrapper = [[FBIvarReference alloc] initWithIvar:ivar];

    if (wrapper.type == FBStructType) { // 不处理结构体
        
    } else {
      [result addObject:wrapper];
    }
  }
  free(ivars);

  return [result copy];
}

static NSIndexSet *FBGetLayoutAsIndexesForDescription(NSUInteger minimumIndex, const uint8_t *layoutDescription) {
  NSMutableIndexSet *interestingIndexes = [NSMutableIndexSet new];
  NSUInteger currentIndex = minimumIndex;

  while (*layoutDescription != '\x00') {
    int upperNibble = (*layoutDescription & 0xf0) >> 4;
    int lowerNibble = *layoutDescription & 0xf;

    // Upper nimble is for skipping
    currentIndex += upperNibble;

    // Lower nimble describes count
    [interestingIndexes addIndexesInRange:NSMakeRange(currentIndex, lowerNibble)];
    currentIndex += lowerNibble;

    ++layoutDescription;
  }

  return interestingIndexes;
}

static NSUInteger FBGetMinimumIvarIndex(__unsafe_unretained Class aCls) {
  NSUInteger minimumIndex = 1;
  unsigned int count;
  Ivar *ivars = class_copyIvarList(aCls, &count);

  if (count > 0) {
    Ivar ivar = ivars[0];
    ptrdiff_t offset = ivar_getOffset(ivar);
    minimumIndex = offset / (sizeof(void *));
  }

  free(ivars);

  return minimumIndex;
}

static NSArray<id<FBObjectReference>> *FBGetStrongReferencesForClass(Class aCls) {
  NSArray<id<FBObjectReference>> *ivars = [FBGetClassReferences(aCls) filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    if ([evaluatedObject isKindOfClass:[FBIvarReference class]]) {
      FBIvarReference *wrapper = evaluatedObject;
      return wrapper.type != FBUnknownType;
    }
    return YES;
  }]];

  const uint8_t *fullLayout = class_getIvarLayout(aCls);

  if (!fullLayout) {
    return @[];
  }

  NSUInteger minimumIndex = FBGetMinimumIvarIndex(aCls);
  NSIndexSet *parsedLayout = FBGetLayoutAsIndexesForDescription(minimumIndex, fullLayout);

  NSArray<id<FBObjectReference>> *filteredIvars =
  [ivars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<FBObjectReference> evaluatedObject,
                                                                           NSDictionary *bindings) {
    return [parsedLayout containsIndex:[evaluatedObject indexInIvarLayout]];
  }]];

  return filteredIvars;
}

NSArray<id<FBObjectReference>> *FBGetObjectStrongReferences(id obj,
                                                            NSMutableDictionary<Class, NSArray<id<FBObjectReference>> *> *layoutCache) {
  NSMutableArray<id<FBObjectReference>> *array = [NSMutableArray new];

  __unsafe_unretained Class previousClass = nil;
  __unsafe_unretained Class currentClass = object_getClass(obj);

  while (previousClass != currentClass) {
    NSArray<id<FBObjectReference>> *ivars;
    
    if (layoutCache && currentClass) {
      ivars = layoutCache[currentClass];
    }
    
    if (!ivars) {
      ivars = FBGetStrongReferencesForClass(currentClass);
      if (layoutCache && currentClass) {
        layoutCache[(id<NSCopying>)currentClass] = ivars;
      }
    }
    [array addObjectsFromArray:ivars];

    previousClass = currentClass;
    currentClass = class_getSuperclass(currentClass);
  }

  return [array copy];
}
