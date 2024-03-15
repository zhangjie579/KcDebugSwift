//
//  KcLeaksGlobalObjectsFinder.m
//

//#if __has_feature(objc_arc)
//#error This file must be compiled without ARC. Use -fno-objc-arc flag.
//#endif

#import "KcLeaksGlobalObjectsFinder.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import "KcObjcInternal.h"

@implementation KcLeaksGlobalObjectsFinder

//#if __arm64__
//#define MLeaks_ISA_MASK        0x0000000ffffffff8ULL
//#define MLeaks_ISA_MAGIC_MASK  0x000003f000000001ULL
//#define MLeaks_ISA_MAGIC_VALUE 0x000001a000000001ULL
//#elif __x86_64__
//#define MLeaks_ISA_MASK        0x00007ffffffffff8ULL
//#define MLeaks_ISA_MAGIC_MASK  0x001f800000000001ULL
//#define MLeaks_ISA_MAGIC_VALUE 0x001d800000000001ULL
//#else
////#error unknown architecture for packed isa
//#define MLeaks_ISA_MASK         0
//#define MLeaks_ISA_MAGIC_MASK   0
//#define MLeaks_ISA_MAGIC_VALUE  0
//#endif

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
#define MLeaks_SEGMENT_CMD_TYPE LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
#define MLeaks_SEGMENT_CMD_TYPE LC_SEGMENT
#endif

//static Class *global_allClasses;
//static int global_classCount;
static NSString *global_executableName;

static CFMutableSetRef global_registeredClasses;

+ (uintptr_t)addreeWithObjc:(id)objc {
//    uintptr_t address = (uintptr_t)((__bridge void *)objc);
    uintptr_t address = (uintptr_t)objc;
    
    return address;
}

+ (void)contatinObjc:(id)objc {
    uintptr_t address = (uintptr_t)objc;
    
    CFMutableSetRef set = [self globalObjects];
    
    if (CFSetContainsValue(set, (void *)address)) {
        NSLog(@"");
    }
}

/// 获取所有全局对象 - 全局对象存储在 Mach-O 文件的 __DATA segment __bss section
/// 问题: 1.全局对象要先使用, 否则的话拿不到
+ (CFMutableSetRef)globalObjects {
//    NSMutableArray<NSObject *> *objectArray = [NSMutableArray array];
    CFMutableSetRef objectSet = CFSetCreateMutable(NULL, 0, NULL);
    
    // 1.class列表
    [self updateRegisteredClasses];
    
    // 2.包名
    [self getExecutableName];
    
    // 2.遍历镜像
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t *header = (const mach_header_t*)_dyld_get_image_header(i);

        // 2.1.截取最后一段作为image_name
        const char *image_name = strrchr(_dyld_get_image_name(i), '/');
        if (image_name) {
            image_name = image_name + 1;
        }

        // 2.2.仅检测主APP
        if (strncmp(image_name, global_executableName.UTF8String, global_executableName.length) != 0) {
            continue;
        }

        // 2.3.获取image偏移量
        vm_address_t slide = _dyld_get_image_vmaddr_slide(i);
        long offset = (long)header + sizeof(mach_header_t);
        for (uint32_t i = 0; i < header->ncmds; i++) {
            const segment_command_t *segment = (const segment_command_t *)offset;
            // 获取__DATA.__bss section的数据，即静态内存分配区
            if (segment->cmd != MLeaks_SEGMENT_CMD_TYPE || strncmp(segment->segname, "__DATA", 6) != 0) {
                offset += segment->cmdsize;
                continue;
            }
            section_t *section = (section_t *)((char *)segment + sizeof(segment_command_t));
            for (uint32_t j = 0; j < segment->nsects; j++) {
//                NSLog(@"ss --- section: %s, size: %ld", section->sectname, (vm_size_t)section->size);
                /*
                 __data：这个section包含所有初始化的全局或静态变量，也就是说。这些变量通常是在程序启动时由系统进行初始化的。
                 __bss：这个section包含所有未初始化的全局或静态变量，但是由于它们的值默认为0，所以实际上并不占用任何磁盘空间。当程序运行时，系统会自动将__bss section 中的变量清零。
                 __const：这个section包含所有“只读”数据，例如字符串常量等。这些数据在程序运行期间不能被修改。
                 __cstring：这个section包含所有以NULL结尾的C字符串常量。
                 */
                if ((strncmp(section->sectname, "__bss", 5) != 0)
                    && (strncmp(section->sectname, "__common", 8) != 0)
//                    && (strncmp(section->sectname, "__data", 6) != 0)
//                    && (strncmp(section->sectname, "__const", 7) != 0)
                    ) {
                    section = (section_t *)((char *)section + sizeof(section_t));
                    continue;
                }
                
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
                        if (zp_isObjcObject((void *)pointee, global_registeredClasses)) {
                            // 这里其实可以不用存NSObject, 存address到时候对比address就可以了
//                            NSObject *objc = (NSObject *)pointee;
//                            [objectArray addObject:(__bridge NSObject *)((void *)pointee)];
//                            NSLog(@"kk --- %@", (NSObject *)pointee);
//                            NSLog(@"xx --- %s", section->sectname);
//                            [testNames addObject:[NSString stringWithFormat:@"%s", section->sectname]];
//                            [objectArray addObject:[NSNumber numberWithInteger:pointee]];
//                            [objectArray addObject:[NSValue valueWithPointer:(void *)pointee]];
                            
                            CFSetAddValue(objectSet, (void *)pointee);
                        }
                    }
                }
            }
            offset += segment->cmdsize;
        }
        // 仅针对主APP image执行一次，执行完直接break
        break;
    }
//    return objectArray;
    return objectSet;
}

#pragma mark - 工具

+ (void)updateRegisteredClasses {
    if (global_registeredClasses) {
        return;
    }
    
    unsigned int classCount = 0;
    Class *allClasses = objc_copyClassList(&classCount);
    global_registeredClasses = CFSetCreateMutable(NULL, 0, NULL);
    
    // 对于swift来说, 这里可以只过滤包含包名的class, 计算class嵌套在某个命名空间下, 它也是包含包名的, 比如: _TtCC7SawaKSA29MyCollectRewardViewController22GiftCollectionViewCell
    for (int i = 0; i < classCount; i++) {
        Class cls = allClasses[i];
        NSString *className = NSStringFromClass(cls);
        // 过滤 - 系统的
        if ([self filterSystemSomeClassName:className]) {
            continue;
        }
        
        // 如果有命名空间去掉命名空间
        NSRange range = [className rangeOfString:@"."];
        if (range.location != NSNotFound) {
            className = [className substringFromIndex:range.location + range.length];
            if ([self isFilterSpecialClassName:className]) {
                continue;
            }
        } else if ([self isFilterSpecialClassName:className]) {
            continue;
        }
        
        CFSetAddValue(global_registeredClasses, (__bridge const void *)(allClasses[i]));
    }
    
    free(allClasses);
}

+ (void)getExecutableName {
    if (global_executableName == nil || global_executableName.length == 0) {
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSDictionary* infoDict = [mainBundle infoDictionary];
        NSString* executableName = infoDict[@"CFBundleExecutable"];
        global_executableName = executableName;
    }
}

/// 过滤系统一些class
+ (BOOL)filterSystemSomeClassName:(NSString *)className {
    // 过滤 - 系统的
    if ([className hasPrefix:@"OS"] || [className hasPrefix:@"NSURL"] || [className hasPrefix:@"ISO"] || [className hasPrefix:@"NSNotification"] || [className hasPrefix:@"NSBundle"] || [className hasPrefix:@"__NSCFCharacterSet"] || [className hasPrefix:@"UIImage"] || [className hasPrefix:@"NSPathStore"]) {
        return true;
    }
    
    // 过滤string
    if ([className isEqualToString:@"__NSCFString"] || [className isEqualToString:@"__NSCFConstantString"] || [className isEqualToString:@"NSPlaceholderString"] || [className isEqualToString:@"NSTaggedPointerString"]) {
        return true;
    }
    
    if ([className isEqualToString:@"NSDictionary"]
        || [className isEqualToString:@"NSOwnedDictionaryProxy"]
        || [className isEqualToString:@"NSSimpleAttributeDictionary"]
        || [className isEqualToString:@"__NSDictionaryI"]
        || [className isEqualToString:@"__NSFrozenDictionaryM"]
        || [className isEqualToString:@"NSMutableDictionary"]) {
        return true;
    }
    
    return false;
}

/// 过滤特殊的class
+ (BOOL)isFilterSpecialClassName:(NSString *)className {
    if ([className hasPrefix:@"FLEX"] || [className hasPrefix:@"Kc"] || [className hasPrefix:@"ML"]) {
        return true;
    }
    
    return false;
}


@end
