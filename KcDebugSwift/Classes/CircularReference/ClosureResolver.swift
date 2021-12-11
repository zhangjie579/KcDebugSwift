//
//  ClosureResolver.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/9.
//  闭包解析器

import UIKit

@objc(ClosureResolver)
@objcMembers
public class ClosureResolver: NSObject {
    
    public override init() {
        super.init()
    }
}


public extension ClosureResolver {
    /// 捕获的强引用
    func strongCaptureValues(block: Any) -> [UnsafeRawPointer] {
        var result = [UnsafeRawPointer]()
        
        var closureBox = ClosureBox(block: block)
        let funcValue = withUnsafeMutablePointer(to: &closureBox) { pointer in
            return UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: FunctionPairTy.self).pointee
        }
        
        let size = malloc_size(funcValue.refCountedPtrTy)
        
        // 捕获的包装
//        let captureBox = funcValue.refCountedPtrTy.advanced(by: size).load(as: UnsafeRawPointer.self)
        
//        let captureSize = malloc_size(captureBox)
        print(funcValue, size)
        if size <= 16 {
            return result
        }
        
        var offset = 16 // Kind + refcount + 捕获的
        // 因为如果捕获self的话, 是不会包装一层box的, 而捕获weak self是会多包装一层box
        for _ in 2..<(size / 8) { // 8字节对齐
            let captureValue = funcValue.refCountedPtrTy.advanced(by: offset).load(as: UnsafeRawPointer.self)
            result.append(captureValue)
            offset += 8
        }
        
        return result
    }
}



struct FunctionPairTy {
    var functionPtrTy: UnsafeMutableRawPointer
    var refCountedPtrTy: UnsafeMutableRawPointer
}

struct HeapObject {
    var Kind: UInt64
//    var refcount: UInt64
    var strongRetainCounts: Int32
    var weakRetainCounts: Int32
}

struct Box {
    var refCounted: HeapObject
    // 捕获的值...
}

// MARK: - ClosureBox 闭包包装器

/// 闭包包装器 - 为了解析闭包捕获的对象
struct ClosureBox {
    var block: Any
}
