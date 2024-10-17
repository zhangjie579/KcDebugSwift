//
//  Mirror+Extension.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/10.
//  反射

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
        while superMirror != nil {
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
    
    /// 是否为NSObject 子类
    static func kc_isNSObjectSubClass(classType: Any.Type) -> Bool {
        return classType is NSObject.Type
    }
    
    /// 是否为class
    static func kc_isClass(value: Any) -> Bool {
        return kc_isClass(type: type(of: value))
    }
    
    /// 是否为class
    static func kc_isClass(type: Any.Type) -> Bool {
        return _isClassType(type)
    }
    
    /// 获取superclass(可用于swift对象)
    /// 不是继承自NSObject的swift对象, 基类为_TtCs12_SwiftObject
    static func kc_getSuperclass(_ obj: Any?) -> AnyClass? {
        return class_getSuperclass(object_getClass(obj))
    }
    
    /// 获取类型名, 有命名空间
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
            
            if value == 0 { // 会导致crash
                return "Any"
            }
        }
        
        // 比如: KcDebugSwift_Example.ViewController
        // _mangledTypeName 这个方法返回的是没有解析好的
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

// MARK: - 其他信息

public extension Mirror {
    /// 格式化属性name
    static func propertyName(_ name: String) -> String {
        var result = name
        // 1.懒加载的属性, name会以这个开头
        if name.hasPrefix("$__lazy_storage_$_") {
            result = String(name[name.index(name.startIndex, offsetBy: "$__lazy_storage_$_".count)...])
        }
        
        return result
    }
    
    /// 类型名
    static func typeName(value: Any) -> String {
        return typeName(name: _typeName(type(of: value)))
    }
    
    /// 类型名
    static func typeName(name: String) -> String {
        var _name = name
        
        if _name.starts(with: "Swift.Optional<") { // 可选
            _name = String(_name[_name.index(_name.startIndex, offsetBy: "Swift.Optional<".count)..<_name.index(before: _name.endIndex)])
        }
        
        if _name.starts(with: "__C.") {
            _name = String(_name[_name.index(_name.startIndex, offsetBy: "__C.".count)...])
        }
        
        return _name
    }
}

// MARK: - ObjectIdentifier

public extension ObjectIdentifier {
    /// 生成ObjectIdentifier
    static func makeFromValue(_ value: Any) -> ObjectIdentifier? {
        let id: ObjectIdentifier?
        if type(of: value) is AnyObject.Type {
            // Object is a class (but not an ObjC-bridged struct)
            id = ObjectIdentifier(value as AnyObject)
        } else if let metatypeInstance = value as? Any.Type {
            // Object is a metatype
            id = ObjectIdentifier(metatypeInstance)
        } else {
            id = nil
        }
        
        return id
    }
}

// MARK: - 苹果API

// https://github1s.com/apple/swift/blob/HEAD/stdlib/public/runtime/ReflectionMirror.cpp#L158

/// 引用关系
struct _FieldReflectionMetadata {
    typealias NameFreeFunc = @convention(c) (UnsafePointer<CChar>?) -> Void
    
    var name: UnsafePointer<CChar>?
    var freeFunc: NameFreeFunc?
    var isStrong: Bool = false
    var isVar: Bool = false
}

/// 获取属性的元数据
/* 可以看出 index 会处理 super mirror的情况, so要加上
 const FieldType recursiveChildMetadata(intptr_t i,
                                        const char **outName,
                                        void (**outFreeFunc)(const char *)) override {
   if (hasSuperclassMirror()) {
     auto superMirror = superclassMirror();
     auto superclassFieldCount = superMirror.recursiveCount();

     if (i < superclassFieldCount) {
       return superMirror.recursiveChildMetadata(i, outName, outFreeFunc);
     } else {
       i -= superclassFieldCount;
     }
   }

   return childMetadata(i, outName, outFreeFunc);
 }
 */
@_silgen_name("swift_reflectionMirror_recursiveChildMetadata")
internal func _getChildMetadata(
  _: Any.Type,
  index: Int,
  fieldMetadata: UnsafeMutablePointer<_FieldReflectionMetadata>
) -> Any.Type

/// 是否是class
@_silgen_name("swift_isClassType")
internal func _isClassType(_: Any.Type) -> Bool


/// 获取枚举的case
@_silgen_name("swift_EnumCaseName")
internal func _getEnumCaseName<T>(_ value: T) -> UnsafePointer<CChar>?

@_silgen_name("swift_getMetadataKind")
internal func _metadataKind(_: Any.Type) -> UInt

@_silgen_name("_swift_isClassOrObjCExistentialType")
internal func _swift_isClassOrObjCExistentialType<T>(_ x: T.Type) -> Bool

///// 获取swift class的superclass
//@_silgen_name("_swift_class_getSuperclass")
//internal func _swift_class_getSuperclass(_ t: AnyClass) -> AnyClass?

/// 收集value的所有引用类型对象
internal func _collectAllReferencesInsideObjectImpl(_ value: Any,
                                                    references: inout [UnsafeRawPointer],
                                                    visitedItems: inout [ObjectIdentifier: Int]) {
  // Use the structural reflection and ignore any
  // custom reflectable overrides.
  let mirror = Mirror(reflecting: value)

  let id: ObjectIdentifier?
  let ref: UnsafeRawPointer?
  if type(of: value) is AnyObject.Type {
    // Object is a class (but not an ObjC-bridged struct)
    let toAnyObject = value as AnyObject
    ref = UnsafeRawPointer(Unmanaged.passUnretained(toAnyObject).toOpaque())
    id = ObjectIdentifier(toAnyObject)
  }
//  else if type(of: value) is Builtin.BridgeObject.Type {
//    ref = UnsafeRawPointer(
//      Builtin.bridgeToRawPointer(value as! Builtin.BridgeObject))
//    id = nil
//  } else if type(of: value) is Builtin.NativeObject.Type  {
//    ref = UnsafeRawPointer(
//      Builtin.bridgeToRawPointer(value as! Builtin.NativeObject))
//    id = nil
//  }
  else if let metatypeInstance = value as? Any.Type {
    // Object is a metatype
    id = ObjectIdentifier(metatypeInstance)
    ref = nil
  } else {
    id = nil
    ref = nil
  }

  if let theId = id {
    // Bail if this object was seen already.
    if visitedItems[theId] != nil {
      return
    }
    // Remember that this object was seen already.
    let identifier = visitedItems.count
    visitedItems[theId] = identifier
  }

  // If it is a reference, add it to the result.
  if let ref = ref {
    references.append(ref)
  }

  // Recursively visit the children of the current value.
  let count = mirror.children.count
  var currentIndex = mirror.children.startIndex
  for _ in 0..<count {
    let (_, child) = mirror.children[currentIndex]
    mirror.children.formIndex(after: &currentIndex)
    _collectAllReferencesInsideObjectImpl(
      child,
      references: &references,
      visitedItems: &visitedItems)
  }
}
