//
//  KcCycleReferenceFinder.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/11.
//  查询循环引用

import UIKit

@objc(KcCycleReferenceFinder)
@objcMembers
public class KcCycleReferenceFinder: NSObject {
    
    public var maxDepth: Int = 10
    
    public weak var reflectingObjc: AnyObject?
    
    public let pointer: UnsafeMutableRawPointer
    
    /// 标识 - 用于比较
    public let identifier: ObjectIdentifier
    
    public private(set) lazy var circularReferences = [String]()
    
    public init(reflecting: AnyObject, maxDepth: Int = 10) {
        pointer = Unmanaged.passUnretained(reflecting).toOpaque()
        identifier = ObjectIdentifier(reflecting)
        super.init()
        
        self.reflectingObjc = reflecting
        self.maxDepth = maxDepth
    }
    
    /// 查询objc的循环引用
    private lazy var objcCycleReference: KcObjcCheckoutCycleReference = {
        let objc = KcObjcCheckoutCycleReference()
        objc.reflectingObjc = reflectingObjc
        objc.maxDepth = maxDepth
        
        objc.doNextCycleReference = { [weak self] (property, depth) -> [String]? in
            guard let value = property.value else {
                return nil
            }
            
            let mirror = Mirror.kc_makeFilterOptional(reflecting: value)
            
            return self?.findStrongReference(mirror: mirror?.0, property: property, depth: depth)
        }
        
        return objc
    }()
}

// MARK: - public

@objc
public extension KcCycleReferenceFinder {
    /// 查找循环引用
    @discardableResult
    func startCheck() -> [String] {
        guard let reflecting = reflectingObjc,
              let mirror = Mirror.kc_makeFilterOptional(reflecting: reflecting) else {
            return []
        }
        
        let property = KcReferencePropertyInfo()
        property.name = "[😄]"
        property.value = mirror.1 as AnyObject
        property.isStrong = true
        
        let result = findStrongReference(mirror: mirror.0, property: property, depth: 1)
        
        circularReferences.append(contentsOf: result)
        
        switch circularReferences.count <= 0 {
        case true:
            print("--- 😄没有找到循环引用😄 ---")
        case false:
            print("--- 😭找到循环引用😭 ---")
            print("retainedCycle --- ", result.description)
            print("--- 😭找到循环引用😭 ---")
        }
        
        return result
    }
    
    func objectAddress() -> size_t {
        return reflectingObjc.flatMap { Unmanaged.passUnretained($0).toOpaque().load(as: Int.self) } ?? 0
    }
    
    func objectClass() -> AnyClass? {
        return reflectingObjc.flatMap { type(of: $0) }
    }
}

// MARK: - NSObject

@objc
public extension NSObject {
    
    /// 查找循环引用
    /// expr -l objc++ -O -- [0x7f8738007690 kc_finderCycleReferenceWithMaxDepth:10]
    @discardableResult
    func kc_finderCycleReference(maxDepth: Int = 10) -> [String] {
        let finder = KcCycleReferenceFinder(reflecting: self)
        return finder.startCheck()
    }
}

// MARK: - private 查找循环引用

extension KcCycleReferenceFinder {
    /*
     全部都需要从swift开始, 因为查询到的property, 可能有mirror + ivars + 关联对象
     */
    func findStrongReference(mirror: Mirror?, property: KcReferencePropertyInfo, depth: Int) -> [String] {
        var result = [String]()
        
        // 处理objc的ivar
        let resultKeyPath = objcCycleReference.startFindStrongReference(withProperty: property, depth: depth)
        if (resultKeyPath?.count ?? 0) > 0 {
            resultKeyPath?.forEach { element in
                if let path = element as? String {
                    result.append(path)
                }
            }
        }
        
        // 对象关联对象
        KcAssociationCycleReference.findStrongAssociationsWithProperty(property) { childProperty in
            // 如果匹配, 说明找到了一个环
            if childProperty.isEqual(self.identifier) {
                result.append(childProperty.propertyKeyPath)
                return
            }
            
            // TODO: swift -> oc crash
            // Constraint 用NSMutableSet存, mirror的时候会转换为NSObject, 然后crash
            if let array = childProperty.value as? NSArray, array.count > 0, !(array.firstObject is NSObject) {
                return
            } else if let set = childProperty.value as? NSSet, set.count > 0, !(set.allObjects.first is NSObject) {
                return
            } else if let dict = childProperty.value as? NSDictionary, dict.allKeys.count > 0, !(dict.allValues.first is NSObject) {
                return
            }
            
            // 查看child的属性
            guard let childValue = childProperty.value,
                  let childMirror = Mirror.kc_makeFilterOptional(reflecting: childValue) else {
                return
            }
            
            // 没有找到环, 继续递归children
            let childKeyPaths = self.findStrongReference(mirror: childMirror.0,
                                                         property: childProperty,
                                                         depth: depth + 1)
            result.append(contentsOf: childKeyPaths)
        }
        
        if mirror != nil {
            let swiftKeyPaths = findSwiftStrongReference(mirror: mirror!, property: property, depth: depth)
            if let value = swiftKeyPaths {
                result.append(contentsOf: value)
            }
        }
        
        return result
    }
    
    /// 查找swift
    /// 可以通过class_copyIvarList获取到, but ivar_getTypeEncoding = ""
    func findSwiftStrongReference(mirror: Mirror, property: KcReferencePropertyInfo, depth: Int) -> [String]? {
        if depth > maxDepth {
            return nil
        }
        
        var keyPaths = [String]()
        
        // 递归super, 先把superclassMirror.kc_isCustomClass这个判断去掉
        if let superclassMirror = mirror.superclassMirror {
            let superKeyPaths = findSwiftStrongReference(mirror: superclassMirror, property: property, depth: depth)
            if let result = superKeyPaths {
                keyPaths.append(contentsOf: result)
            }
        }
        
        // 处理swift的ivar index, 需要把super的加上
        let currentCustomSwiftClassPropertyCount = property.currentCustomSwiftClassPropertyCount
        property.currentCustomSwiftClassPropertyCount += mirror.children.count
        
        // children
        for (index, children) in mirror.children.enumerated() {
            let value: Any? = children.value
            
            guard value != nil else {
                continue
            }
            
            var fieldMetadata = _FieldReflectionMetadata()
            
            // index需要把自定义super class的property count加上⚠️
            let childType = _getChildMetadata(mirror.subjectType,
                                              index: currentCustomSwiftClassPropertyCount + index,
                                              fieldMetadata: &fieldMetadata)
            
            // 过滤
            if isExcluded(value: children.value, subjectType: childType) {
                continue
            }
            
            // 只关注strong
            guard fieldMetadata.isStrong,
               let childMirror = Mirror.kc_makeFilterOptional(reflecting: children.value) else {
                continue
            }
            
            if let displayStyle = childMirror.0.displayStyle {
                switch displayStyle {
                case .class:
//                        if !childMirror.0.kc_isCustomClass {
//                            continue
//                        }
                    break
                case .collection, .dictionary, .set, .tuple, .optional:
                    break
                case .struct, .enum: // 结构体、枚举不处理
                    continue
                @unknown default:
                    break
                }
                
                let childProperty = KcReferencePropertyInfo()
                childProperty.name = children.label ?? ""
                childProperty.value = children.value as AnyObject
                childProperty.isStrong = fieldMetadata.isStrong
//                childProperty.isVar = fieldMetadata.isVar
                childProperty.superProperty = property
                
                property.childrens.add(childProperty)
                
//                print("dd --- ", childProperty.propertyKeyPath)
                
                // 如果匹配, 说明找到了一个环
                if childProperty.isEqual(self.reflectingObjc) {
                    keyPaths.append(childProperty.propertyKeyPath)
                    continue
                }
                
                // 没有找到环, 继续递归children
                let childKeyPaths = findStrongReference(mirror: childMirror.0, property: childProperty, depth: depth + 1)
                keyPaths.append(contentsOf: childKeyPaths)
            } else {
//                let kind = Kind(type: type(of: childMirror.1))
//
//                if kind == .function { // 闭包
//                    let resolver = ClosureResolver()
//                    let result = resolver.strongCaptureValues(block: childMirror.1)
//                    print("---- 闭包捕获的: ", property.value, childProperty.propertyKeyPath, result, " ----")
//                    if result.contains(pointer) { // 找到环
//                        reversedLink(property: childProperty)
//                        continue
//                    }
//                }
            }
        }
        
        return keyPaths
    }
}

// MARK: - 过滤

private extension KcCycleReferenceFinder {
    /// 是否是过滤的类型
    func isExcluded(value: Any, subjectType: Any.Type) -> Bool {
        
        do { // 过滤Any
            let point = withUnsafePointer(to: subjectType, { $0 })
            let value = UnsafeRawPointer(point).load(as: Int.self)
            
            if value == 0 {
                return true
            }
        }
        
        let typeName = Mirror.kc_className(subjectType: subjectType)
        
//        // 过滤前缀
//        if let index = typeName.lastIndex(of: "."),
//           let startIndex = typeName.index(index, offsetBy: 1, limitedBy: typeName.endIndex) {
//            typeName = String(typeName[startIndex...])
//        }
        
        // 过滤私有, 会把_ArrayBuffer过滤掉
//        if typeName.hasPrefix("_") {
//            return true
//        }
        
        return KcCycleReferenceConfiguration.shardInstance().isExcludeObjc(value, typeName: typeName)
    }
}

// MARK: - help

@objc
public extension NSString {
    var kc_formatterPropertyName: NSString {
        return KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(self as String) as NSString
    }
}
