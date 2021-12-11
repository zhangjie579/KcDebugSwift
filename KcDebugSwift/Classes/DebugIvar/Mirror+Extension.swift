//
//  Mirror+Extension.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/10.
//

import UIKit

/*
 注意点
 1.objc class mirror children = 0
 */

// MARK: - 初始化

public extension Mirror {
    /// 初始化, 过滤可选
    static func kc_makeFilterOptional(reflecting: Any) -> (Mirror, Any)? {
        let mirror = Mirror(reflecting: reflecting)
        
        return mirror.kc_filterOptionalReflectValue(reflecting)
    }
}

// MARK: - 信息

public extension Mirror {
    /// 对象是否为optional
    var kc_isOptionalValue: Bool {
        return displayStyle == .optional || _typeName(subjectType).hasPrefix("Swift.ImplicitlyUnwrappedOptional<")
    }
    
    /// 去反射value的可选值的mirror: 当反射value为optional, 它为value去optional的mirror
    func kc_filterOptionalReflectValue(_ value: Any) -> (Mirror, Any)? {
        guard kc_isOptionalValue else {
            return (self, value)
        }
        
//        if let wapperValue = children.first?.value {
//            return Mirror(reflecting: wapperValue).kc_filterOptionalReflectValue(wapperValue)
//        }
        for (key, value) in children where key == "some" {
            return Mirror(reflecting: value).kc_filterOptionalReflectValue(value)
        }
        return nil
    }
    
    /// 获取类名
    var kc_className: String {
        return Self.kc_className(subjectType: subjectType)
    }
    
    /// 是否是自定义class
    var kc_isCustomClass: Bool {
        return Self.kc_isCustomClass(subjectType: subjectType)
    }
    
    /// 计算_getChildMetadata使用的index, 需要把swift super class的加上
    func computeChildMetadataIndex(_ index: Int) -> Int {
        var superMirror = superclassMirror
        
        var result = index
        while superMirror != nil, let subjectType = superMirror?.subjectType {
            if !Mirror.kc_isCustomClass(subjectType: subjectType) {
                break
            }
            
            result += superMirror?.children.count ?? 0
            
            superMirror = superMirror?.superclassMirror
        }
        
        return result
    }
}

// MARK: - 元信息

public extension Mirror {
    /// 是否是自定义class
    static func kc_isCustomClass(subjectType: Any.Type) -> Bool {
        guard let aClass = subjectType as? AnyClass else {
            return false
        }
        return kc_isCustomClass(aClass)
    }
    
    /// 是否是自定义class
    static func kc_isCustomClass(_ aClass: AnyClass) -> Bool {
        let path = Bundle.init(for: aClass).bundlePath
        return path.hasPrefix(Bundle.main.bundlePath)
    }
    
    /// 是否为class
    static func kc_isClass(value: Any) -> Bool {
        return kc_isClass(type: type(of: value))
    }
    
    /// 是否为class
    static func kc_isClass(type: Any.Type) -> Bool {
        return type is AnyClass
    }
    
    static func kc_className(subjectType: Any.Type) -> String {
//        let name: String?
//        if let object = object {
//            name = "\(type(of: object))"
//        } else if let ivar = ivar {
//            name = "\(type(of: ivar))"
//        } else {
//            name = nil
//        }
        
//        String(reflecting: subjectType)
        
        do { // 过滤Any
            let point = withUnsafePointer(to: subjectType, { $0 })
            let value = UnsafeRawPointer(point).load(as: Int.self)
            
            if value == 0 {
                return "Any"
            }
        }
        
        let type = _typeName(subjectType)
            .replacingOccurrences(of: "__C.", with: "")
            .replacingOccurrences(of: "Swift.", with: "")
        
        return type
    }
    
    /// 对象的类型名
    static func kc_instanceTypeName<T>(_ instance: T) -> String {
        let instanceType = type(of: instance)
        return String(reflecting: instanceType)
    }
    
    /// 对象地址的开始偏移offset
    static func kc_classStartOffset(with value: Any) -> Int {
        if kc_isClass(value: value) {
            return is64BitPlatform ? 16 : 12
        }
        return 0
    }
    
    /// 是否为64位
    static var is64BitPlatform: Bool {
        return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
    }
}

// MARK: - 苹果API

// https://github1s.com/apple/swift/blob/HEAD/stdlib/public/runtime/ReflectionMirror.cpp#L158

struct _FieldReflectionMetadata {
    typealias NameFreeFunc = @convention(c) (UnsafePointer<CChar>?) -> Void
    
    var name: UnsafePointer<CChar>?
    var freeFunc: NameFreeFunc?
    var isStrong: Bool = false
    var isVar: Bool = false
}

/// 获取属性的元数据
@_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
internal func _getChildMetadata(
  _: Any.Type,
  index: Int,
  fieldMetadata: UnsafeMutablePointer<_FieldReflectionMetadata>
) -> Any.Type

@_silgen_name("swift_isClassType")
internal func _isClassType(_: Any.Type) -> Bool
