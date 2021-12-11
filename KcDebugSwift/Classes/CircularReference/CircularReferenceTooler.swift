//
//  CircleCycleFinder.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/7.
//  检测循环引用

import UIKit

@objc(CircularReferenceFinder)
@objcMembers
final public class CircleCycleFinder: NSObject {
    public weak var reflecting: AnyObject?
    
    public let pointer: UnsafeMutableRawPointer
    
    /// 标识 - 用于比较
    let identifier: ObjectIdentifier
    
    /// 最大深度
    public let maxDepth: Int
    
    public private(set) lazy var circularReferences = [String]()
    
    public init(reflecting: AnyObject, maxDepth: Int = 10) {
        self.maxDepth = maxDepth
        pointer = Unmanaged.passUnretained(reflecting).toOpaque()
        identifier = ObjectIdentifier(reflecting)
        self.reflecting = reflecting
    }
}

@objc
public extension NSObject {
    /// 查找循环引用
    func kc_finderCircularReference() {
        let finder = CircleCycleFinder(reflecting: self)
        finder.collection()
    }
}

extension CircleCycleFinder {
    /// 查找
    public func collection() {
        guard let reflecting = reflecting,
              let mirror = Mirror.kc_makeFilterOptional(reflecting: reflecting),
              mirror.0.kc_isCustomClass else {
            return
        }
        
        let property = PropertyField()
        property.type = mirror.0.subjectType
        property.value = reflecting
        property.displayStyle = mirror.0.displayStyle

        dump(mirror: mirror.0, property: property, depth: 1)
        
        switch circularReferences.isEmpty {
        case true:
            print("--- 😄没有找到循环引用😄 ---")
        case false:
            print("--- 😭找到循环引用😭 ---")
            print("retainedCycle --- ", circularReferences)
            print("--- 😭找到循环引用😭 ---")
        }
    }
    
    func dump(mirror: Mirror, property: PropertyField, depth: Int) {
        if depth > maxDepth {
            return
        }
        
        // 递归super, 先把superclassMirror.kc_isCustomClass这个判断去掉
        #warning("objc的class mirror children = 0")
        if let superclassMirror = mirror.superclassMirror {
            dump(mirror: superclassMirror, property: property, depth: depth)
        }
        
        // 更新
        let currentCustomSwiftClassPropertyCount = property.currentCustomSwiftClassPropertyCount
        if mirror.kc_isCustomClass {
            property.currentCustomSwiftClassPropertyCount += mirror.children.count            
        }
        
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
            if isExcludedType(childType) {
                continue
            }
            
            if children.label == "delegate" {
                print("")
            }
            
            if children.label == "nonmodalPresentedInfos" {
                print("")
            }
            
            if children.label == "presentationController" {
                print("")
            }
            
            // 只关注strong
            #warning("kc_test 这里可以过滤一些")
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
                
                let childProperty = PropertyField()
                childProperty.name = children.label ?? ""
                childProperty.type = childMirror.0.subjectType
                childProperty.displayStyle = childMirror.0.displayStyle
                childProperty.value = children.value
                childProperty.isStrong = fieldMetadata.isStrong
                childProperty.isVar = fieldMetadata.isVar
                childProperty.superProperty = property
                
                property.childrens.append(childProperty)
                
                print("dd --- ", childProperty.propertyKeyPath)
                
                // 如果匹配, 说明找到了一个环
                if identifier == ObjectIdentifier(children.value as AnyObject) {
                    reversedLink(property: childProperty)
                    continue
                }
                
                // 没有找到环, 继续递归children
                dump(mirror: childMirror.0, property: childProperty, depth: depth + 1)
                
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
    }
    
    /// 从后往前找链
    func reversedLink(property: PropertyField) {
        circularReferences.append(property.propertyKeyPath)
    }
}

// MARK: - 过滤

private extension CircleCycleFinder {
    /// 是否是过滤的类型
    func isExcludedType(_ subjectType: Any.Type) -> Bool {
        
        do { // 过滤Any
            let point = withUnsafePointer(to: subjectType, { $0 })
            let value = UnsafeRawPointer(point).load(as: Int.self)
            
            if value == 0 {
                return true
            }
        }
        
        let typeName = Mirror.kc_className(subjectType: subjectType)
        
        // 过滤私有, 会把_ArrayBuffer过滤掉
//        if typeName.hasPrefix("_") {
//            return true
//        }
        
        #warning("这里可以再暴露个接口给外部注入一些过滤的类型")
        let excludedTypes = Self.defaultExcludedTypes
        
        if excludedTypes.contains(typeName) {
            return true
        }
        
        // 过滤前缀
        if Self.defaultExcludedTypesPrefix.contains(where: { typeName.hasPrefix($0) }) {
            return true
        }
        
//        do { // 过滤一些系统类的子类
//            let excludedClassChildClass: [AnyClass] = [
//                UIView.self,
//                UIControl.self,
//                UIButton.self,
//                UIScrollView.self
//            ]
//
//            if typeName.hasPrefix("UI"),
//               let objcCls = NSClassFromString(typeName), let superCls = class_getSuperclass(objcCls), excludedClassChildClass.contains(where: { $0 == superCls }) {
//                return true
//            }
//        }
        
        return false
    }
    
    /// 过滤类型的前缀
    static var defaultExcludedTypesPrefix: Set<String> = [
        "Int", "UInt",
        "Bool",
        "CG",
        "NS",
    ]
    
    /// 过滤类型
    static var defaultExcludedTypes: Set<String> = [
//        "CGFloat", "CGRect", "CGPoint", "CGSize", "CGImage",
        "Double", "Float",
        "UIImage", "UIEdgeInsets", "UIView", "UIButton", "UILabel", "UIControl", "UIScrollView",
        "Date", "NSDate",
        "Data", "NSData",
        "NSAttributedString", "String", "NSString",
        "URL", "NSURL",
    ]
    
    /// 过滤系统类
    static var excludedSystemTypes: Set<String> = {
        var result = Set<String>()
        let clsList = KcRuntimeHelper.objcClassList()
        let excludedClassChildClass: [AnyClass] = [
            UIView.self,
            UIControl.self,
            UIButton.self,
            UIScrollView.self
        ]
        
        for cls in clsList {
            if let superCls = class_getSuperclass(cls),
               excludedClassChildClass.contains(where: { superCls == $0 }) {
                result.insert(NSStringFromClass(cls))
            }
        }
        
        return result
    }()
}

// MARK: - 属性信息

class PropertyField {
    var name: String = ""
    /// 属性类型
    var type: Any.Type?
    
    var displayStyle: Mirror.DisplayStyle?
    /// 属性值
    var value: Any?
    
    /// 当前自定义swift class的属性的count
    /// _getChildMetadata 获取信息, 传入的index 需要加上super的count, objc的父类不用加上
    var currentCustomSwiftClassPropertyCount: Int = 0
    
    var isStrong: Bool = true
    var isVar: Bool = false
    
//    var supers: [PropertyField] = []
    weak var superProperty: PropertyField?
    var childrens: [PropertyField] = []
}

extension PropertyField {
    /// 从当前找到最顶端的keyPath
    var propertyKeyPath: String {
        var preNode: PropertyField? = self
        var keyPath = [String]()
        while preNode != nil {
            if let name = preNode?.name, name.count > 0 {
                keyPath.append(KcPropertyInfo.propertyNameFormatter(name))
            }
            preNode = preNode?.superProperty
        }
        
        return keyPath.reversed().joined(separator: "->")
    }
}


