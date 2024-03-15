//
//  QNGlobalObjectsFinder.m
//  QQNews
//
//  Created by JerryChu on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled without ARC. Use -fno-objc-arc flag.
#endif

#import "QNGlobalObjectsFinder.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

@implementation QNGlobalObjectsFinder

#if __arm64__
#define QN_ISA_MASK        0x0000000ffffffff8ULL
#define QN_ISA_MAGIC_MASK  0x000003f000000001ULL
#define QN_ISA_MAGIC_VALUE 0x000001a000000001ULL
#elif __x86_64__
#define QN_ISA_MASK        0x00007ffffffffff8ULL
#define QN_ISA_MAGIC_MASK  0x001f800000000001ULL
#define QN_ISA_MAGIC_VALUE 0x001d800000000001ULL
#else
//#error unknown architecture for packed isa
#define QN_ISA_MASK         0
#define QN_ISA_MAGIC_MASK   0
#define QN_ISA_MAGIC_VALUE  0
#endif

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
#define QN_SEGMENT_CMD_TYPE LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
#define QN_SEGMENT_CMD_TYPE LC_SEGMENT
#endif

static Class *global_allClasses;
static int global_classCount;
static NSString *global_executableName;

+ (NSInteger)addreeWithObjc:(id)objc {
    NSInteger address = (NSInteger)objc;
    
    return address;
}

/// 获取所有全局对象 - 全局对象存储在 Mach-O 文件的 __DATA segment __bss section
/// 问题: 1.全局对象要先使用, 否则的话拿不到
+ (NSArray<NSObject *> *)globalObjects {
    NSMutableArray<NSObject *> *objectArray = [NSMutableArray array];

    // 1.class列表
    if (global_classCount <= 0) {
        int classCount = objc_getClassList(NULL, 0);
        Class *allClasses = (Class *)malloc(sizeof(Class) * (classCount + 1));
        classCount = objc_getClassList(allClasses, classCount);
        
//        for (int i = 0; i < classCount; i++) {
//            Class cls = allClasses[i];
//            NSLog(@" --- %@", NSStringFromClass(cls));
//        }
        
        global_classCount = 0;
        global_allClasses = (Class *)calloc(classCount + 1, sizeof(Class));
        for (int i = 0; i < classCount; i++) {
            Class cls = allClasses[i];
            NSString *className = NSStringFromClass(cls);
            // 过滤
            if ([className hasPrefix:@"OS"]) {
                continue;
            }
            
            // 过滤string
            if ([className isEqualToString:@"__NSCFString"] || [className isEqualToString:@"__NSCFConstantString"] || [className isEqualToString:@"NSPlaceholderString"] || [className isEqualToString:@"NSTaggedPointerString"]) {
                continue;
            }
            
            global_allClasses[i] = cls;
            global_classCount += 1;
        }
        
        free(allClasses);
    }

    // 2.遍历镜像
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t *header = (const mach_header_t*)_dyld_get_image_header(i);

        // 2.1.截取最后一段作为image_name
        const char *image_name = strrchr(_dyld_get_image_name(i), '/');
        if (image_name) {
            image_name = image_name + 1;
        }

        // 2.2.仅检测主APP - 如果是动态库的话, 这里就会出问题⚠️, 拿取到的是自己的库名
        if (global_executableName == nil || global_executableName.length == 0) {
            NSBundle* mainBundle = [NSBundle mainBundle];
            NSDictionary* infoDict = [mainBundle infoDictionary];
            NSString* executableName = infoDict[@"CFBundleExecutable"];
            global_executableName = executableName;
        }
        if (strncmp(image_name, global_executableName.UTF8String, global_executableName.length) != 0) {
            continue;
        }

        // 2.3.获取image偏移量
        vm_address_t slide = _dyld_get_image_vmaddr_slide(i);
        long offset = (long)header + sizeof(mach_header_t);
        for (uint32_t i = 0; i < header->ncmds; i++) {
            const segment_command_t *segment = (const segment_command_t *)offset;
            // 获取__DATA.__bss section的数据，即静态内存分配区
            if (segment->cmd != QN_SEGMENT_CMD_TYPE || strncmp(segment->segname, "__DATA", 6) != 0) {
                offset += segment->cmdsize;
                continue;
            }
            section_t *section = (section_t *)((char *)segment + sizeof(segment_command_t));
            for (uint32_t j = 0; j < segment->nsects; j++) {
                NSLog(@"ss --- section: %s, size: %ld", section->sectname, (vm_size_t)section->size);
                // swift很多数据都是存在这里面, so把这个放开
//                if ((strncmp(section->sectname, "__bss", 5) != 0)) {
//                    section = (section_t *)((char *)section + sizeof(section_t));
//                    continue;
//                }
                // 遍历获取所有全局对象
                vm_address_t begin = (vm_address_t)section->addr + slide;
                vm_size_t size = (vm_size_t)section->size;
                vm_size_t end = begin + size;
                section = (section_t *)((char *)section + sizeof(section_t));

                const uint32_t align_size = sizeof(void *);
                if (align_size <= size) {
                    uint8_t *ptr_addr = (uint8_t *)begin;
                    // OOMDetector库的CMemoryChecker.mm - void CMemoryChecker::check_ptr_in_vmrange(vm_range_t range, memory_type type) 也是这样判断
                    for (uint64_t addr = begin; addr < end && ((end - addr) >= align_size); addr += align_size, ptr_addr += align_size) {
                        vm_address_t *dest_ptr = (vm_address_t *)ptr_addr;
                        // 不能直接缓存这个pointer, 对于未使用的, 指针就是未初始化, 只有使用了才有值⚠️
                        uintptr_t pointee = (uintptr_t)(*dest_ptr);
                        if (pointee == 0) {
                            continue;
                        }
                        
                        // 判断pointee指向的内容是否为OC的NSObject对象
                        if (isObjcObject((void *)pointee, global_allClasses, global_classCount)) {
                            NSLog(@"ss --- %@", (NSObject *)pointee);
                            [objectArray addObject:(NSObject *)pointee];
                        }
//                        [objectArray addObject:[NSValue valueWithPointer:(void *)pointee]];
//                        [objectArray addObject:[NSNumber numberWithInteger:pointee]];
                    }
                }
            }
            offset += segment->cmdsize;
        }
        // 仅针对主APP image执行一次，执行完直接break
        break;
    }
//    free(allClasses);
    return objectArray;
}

#if TARGET_OS_OSX && __x86_64__
//  64-bit Mac - tag bit is LSB
#   define _OBJC_TAG_MASK 1UL
#else
//  Everything else - tag bit is MSB
#   define _OBJC_TAG_MASK (1ULL << 63)
#endif

static inline bool _objc_isTaggedPointer(const void * _Nullable ptr) {
    return ((uintptr_t)ptr & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
}

/// 是否是swift的class - 来自 objc-internal.h
BOOL _class_isSwift(Class _Nullable cls);

// 参考: https://blog.timac.org/2016/1124-testing-if-an-arbitrary-pointer-is-a-valid-objective-c-object/
// https://github.com/NativeScript/ios-jsc
// 注意：去除了`IsObjcTaggedPointer`的判断
/**
 Test if a pointer is an Objective-C object

 @param inPtr is the pointer to check
 @return true if the pointer is an Objective-C object
 
 能够识别swift class、嵌套在某个命名空间里面的swift class
 */
//bool isObjcObject(const void *inPtr, const Class *allClasses, int classCount);
static bool isObjcObject(const void *inPtr, const Class *allClasses, int classCount) {
    //
    // NULL pointer is not an Objective-C object
    //
    if (inPtr == NULL) {
        return false;
    }

    //
    // Check for tagged pointers
    //
    //    if(IsObjcTaggedPointer(inPtr, NULL))
    //    {
    //        return true;
    //    }
    if (_objc_isTaggedPointer(inPtr)) { // 直接把这个过滤掉, 本来它其实是算objc的
        return false;
    }

    //
    // Check if the pointer is aligned
    //
    if (((uintptr_t)inPtr % sizeof(uintptr_t)) != 0) {
        return false;
    }

    //
    // From LLDB:
    // Objective-C runtime has a rule that pointers in a class_t will only have bits 0 thru 46 set
    // so if any pointer has bits 47 thru 63 high we know that this is not a valid isa
    // See http://llvm.org/svn/llvm-project/lldb/trunk/examples/summaries/cocoa/objc_runtime.py
    //
    if (((uintptr_t)inPtr & 0xFFFF800000000000) != 0) {
        return false;
    }

    //
    // Check if the memory is valid and readable
    //
    if (!isValidReadableMemory(inPtr)) {
        return false;
    }

    //
    // Get the Class from the pointer
    // From http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html :
    // If you are writing a debugger-like tool, the Objective-C runtime exports some variables
    // to help decode isa fields. objc_debug_isa_class_mask describes which bits are the class pointer:
    // (isa & class_mask) == class pointer.
    // objc_debug_isa_magic_mask and objc_debug_isa_magic_value describe some bits that help
    // distinguish valid isa fields from other invalid values:
    // (isa & magic_mask) == magic_value for isa fields that are not raw class pointers.
    // These variables may change in the future so do not use them in application code.
    //
    //
    uintptr_t isa = (*(uintptr_t *)inPtr);
    Class ptrClass = NULL;

    /*
     struct swift_class_t : objc_class {
     
     struct objc_class : objc_object {
     
     struct objc_object {
     private:
         isa_t isa;
     ...
     }
     
    */
    if ((isa & ~QN_ISA_MASK) == 0) {
        ptrClass = (Class)isa;
    } else {
        // jerrychu: 即使是non-pointer isa, isa & isa_magic_mask == isa_magic_value 条件也不成立，先取消判断。
        // isa & isa_magic_mask != isa_magic_value
        ptrClass = (Class)(isa & QN_ISA_MASK);
//        if ((isa & QN_ISA_MAGIC_MASK) == QN_ISA_MAGIC_VALUE) {
//            ptrClass = (Class)(isa & QN_ISA_MASK);
//        } else {
//            ptrClass = (Class)isa;
//        }
    }

    if (ptrClass == NULL) {
        return false;
    }

    //
    // Verifies that the found Class is a known class.
    //
    bool isKnownClass = false;
    for (int i = 0; i < classCount; i++) {
        if (allClasses[i] == ptrClass) {
            isKnownClass = true;
            break;
        }
    }

    if (!isKnownClass) {
        return false;
    }

    //
    // From Greg Parker
    // https://twitter.com/gparker/status/801894068502433792
    // You can filter out some false positives by checking malloc_size(obj) >= class_getInstanceSize(cls).
    //
    size_t pointerSize = malloc_size(inPtr);
    if (pointerSize > 0 && pointerSize < class_getInstanceSize(ptrClass)) {
        return false;
    }

    return true;
}

/**
 Test if the pointer points to readable and valid memory.

 @param inPtr is the pointer
 @return true if the pointer points to readable and valid memory.
 */
static bool isValidReadableMemory(const void* inPtr) {
    kern_return_t error = KERN_SUCCESS;

    // Check for read permissions
    bool hasReadPermissions = false;

    vm_size_t vmsize;
    vm_address_t address = (vm_address_t)inPtr;
    vm_region_basic_info_data_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;

    memory_object_name_t object;

    error = vm_region_64(mach_task_self(), &address, &vmsize, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &info_count, &object);
    if (error != KERN_SUCCESS) {
        // vm_region/vm_region_64 returned an error
        hasReadPermissions = false;
    } else {
        hasReadPermissions = (info.protection & VM_PROT_READ);
    }

    if (!hasReadPermissions) {
        return false;
    }

    // Read the memory
    char buf[sizeof(uintptr_t)];
    vm_size_t size = 0;
    error = vm_read_overwrite(mach_task_self(), (vm_address_t)inPtr, sizeof(uintptr_t), (vm_address_t)buf, &size);
    if (error != KERN_SUCCESS) {
        // vm_read returned an error
        return false;
    }

    return true;
}

@end
