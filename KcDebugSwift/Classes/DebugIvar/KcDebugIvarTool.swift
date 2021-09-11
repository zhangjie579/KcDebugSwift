//
//  KcDebugIvarTool.swift
//  swiftTest
//
//  Created by 张杰 on 2021/4/18.
//  调试ivar工具, 可以在lldb环境下根据address使用

import UIKit

// MARK: - 外部使用接口

/*
 1.改成objc - 要在任何地方都可以使用、通过address执行
    * 因为在swift环境下，debug UI时，根据address执行方法，lldb会报错❌找不到方法
 2.没必要包括super、children的情况，没找到自己再查找就是了
 */

/*
 1.本想用个KcIvarTool类来管理这些方法的, but如果它是swift文件的话, lldb有class name的烦恼, 比如为SWIFT_CLASS("_TtC9swiftTest10KcIvarTool"), 要用这个name, so直接定义在NSObject中
 */
@objc
public extension NSObject {
    /// 查找UI的属性名(这里包含了CALayer)
    /// expr -l objc++ -O -- [0x7f8738007690 kc_debug_findUIPropertyName]
    /*
     查不到的情况
     1. delegate设置为不是UIResponder对象, 或者它不在图层树上
     */
    func kc_debug_findUIPropertyName() {
        
        /// 处理layer delegate情况, 默认情况下delegate为UIView
        func handleLayerDelegate(delegate: CALayerDelegate) {
            if let responder = delegate as? UIResponder {
                UIView.kc_debug_findObjcPropertyName(object: self, startSearchView: responder)
            } else { // 这种情况暂时不知道如何处理
                print("------------ 👻 请换过其他方式处理, CALayerDelegate不为UIView对象: \(delegate) 👻 ---------------")
            }
        }
        
        if isKind(of: UIView.self) {
            (self as? UIView)?.kc_debug_findPropertyName()
        } else if isKind(of: CALayer.self), let layer = self as? CALayer {
            if let delegate = layer.delegate {
                handleLayerDelegate(delegate: delegate)
            } else { // 没有代理
                var superlayer = layer.superlayer
                
                while let nextLayer = superlayer {
                    if let delegate = nextLayer.delegate {
                        handleLayerDelegate(delegate: delegate)
                        break
                    } else {
                        superlayer = superlayer?.superlayer
                    }
                }
            }
        }
    }
    
    /// 输出所有ivar
    /// expr -l objc++ -O -- [((NSObject *)0x7f8738007690) kc_debug_ivarDescription:0]
    func kc_debug_ivarDescription(_ rawValue: KcAnalyzeIvarType = .default) {
        type(of: self).kc_debug_ivarDescription(self, rawValue: rawValue)
    }
    
    /// 输出UI相关的ivar
    // expr -l objc++ -O -- [((NSObject *)0x7f8738007690) kc_debug_UIIvarDescription:0]
    func kc_debug_UIIvarDescription(_ rawValue: KcAnalyzeIvarType = .default) {
        type(of: self).kc_debug_UIIvarDescription(self, rawValue: rawValue)
    }
    
    /// 输出所有ivar
    /// expr -l objc++ -O -- [NSObject kc_debug_ivarDescription:0x7f8738007690 rawValue:0]
    class func kc_debug_ivarDescription(_ value: Any, rawValue: KcAnalyzeIvarType = .default) {
        print("------------ 👻 ivar description 👻 ---------------")
        let ivarTool = KcAnalyzePropertyTool.init(type: rawValue)
        let ivarInfo = ivarTool.ivarsFromValue(value, depth: 0)
        ivarInfo?.log { _ in
            return true
        }
        print("------------ 👻 ivar description 👻 ---------------")
    }
    
    /// 输出UI相关的ivar
    // expr -l objc++ -O -- [NSObject kc_debug_UIIvarDescription:0x7f8738007690 rawValue:0]
    class func kc_debug_UIIvarDescription(_ value: Any, rawValue: KcAnalyzeIvarType = .default) {
        print("------------ 👻 UI ivar description 👻 ---------------")
        let ivarTool = KcAnalyzePropertyTool.init(type: rawValue)
        let ivarInfo = ivarTool.ivarsFromValue(value, depth: 0)
        ivarInfo?.log { info in
            guard let objc = info.value as? NSObject else {
                return false
            }
            
            if objc.isKind(of: UIResponder.self) ||
                objc.isKind(of: CALayer.self) {
                return true
            }
            
            return false
        }
        print("------------ 👻 UI ivar description 👻 ---------------")
    }
}

// MARK: - UIView

@objc
public extension UIView {
    /// 查找UI的属性名
    /// expr -l objc++ -O -- [0x7f8738007690 kc_debug_findPropertyName]
    func kc_debug_findPropertyName() {
        UIView.kc_debug_findObjcPropertyName(object: self, startSearchView: next)
    }
}

extension UIView {
    /// 查找objc的属性名
    /// - Parameters:
    ///   - object: 要查询的对象
    ///   - startSearchView: 从这个view的properties开始查, 然后递归nextResponder
    class func kc_debug_findObjcPropertyName(object: NSObject, startSearchView: UIResponder?) {
        print("------------ 👻 查询属性name 👻 ---------------")
        
        var container: NSObject?
        var propertyInfo: KcPropertyInfo?
        
        /// 查找property
        func findProperty(from ivarInfo: KcPropertyInfo, currentContainer: UIResponder) -> Bool {
            // 遍历当前容器的propertys
            for childInfo in ivarInfo.childs where childInfo.isEqual(objc: object) {
                container = currentContainer
                propertyInfo = childInfo
                return true
            }
            
            // 遍历super容器的propertys
            for superInfo in ivarInfo.supers where !superInfo.childs.isEmpty {
                for childInfo in superInfo.childs where childInfo.isEqual(objc: object) {
                    container = currentContainer
                    propertyInfo = childInfo
                    return true
                }
            }
            
            return false
        }
        
        let ivarTool = KcAnalyzePropertyTool(type: .hasSuper)
        
        var nextResponder: UIResponder? = startSearchView
        
        while let next = nextResponder {
            defer {
                nextResponder = nextResponder?.next
            }
            
            let mirror = Mirror(reflecting: next)
            guard mirror.kc_isCustomClass,
                  let ivarInfo = ivarTool.ivarsFromValue(next, depth: 0, name: "查询对象😄"),
                  !ivarInfo.childs.isEmpty else {
                continue
            }
            
            if findProperty(from: ivarInfo, currentContainer: next) {
                break
            }
        }
        
        if let objc = container, let info = propertyInfo {
            let containClassName = info.containMirror?.kc_className ?? Mirror(reflecting: objc).kc_className
            let log = """
                in \(containClassName):
                😁😁😁 查找属性的属性名name: \(info.name),
                😁😁😁 查找属性: \(object)
                😁😁😁 容器: \(objc)
                """
            print(log)
        }
        
        print("------------ 👻 ivar description 👻 ---------------")
    }
}

// MARK: - KcAnalyzePropertyTool 分析属性工具

@objc
public enum KcAnalyzeIvarType : Int {
    case `default` = 0
    case hasSuper = 1
    case hasChild = 2
    case hasSuperChild = 3
}

/// 分析ivar
public class KcAnalyzePropertyTool {
    
    /// 最大处理深度(避免死循环, 当循环依赖时)
    let maxDepth: Int
    /// 是否包含super
    let isContainSuper: Bool
    /// 是否包含child中的child
    let isContainChildInChild: Bool
    
    public init(isContainSuper: Bool, isContainChildInChild: Bool, maxDepth: Int = 5) {
        self.isContainSuper = isContainSuper
        self.isContainChildInChild = isContainChildInChild
        self.maxDepth = maxDepth
    }
    
    public init(type: KcAnalyzeIvarType, maxDepth: Int = 5) {
        switch type {
        case .default:
            self.isContainSuper = false
            self.isContainChildInChild = false
        case .hasSuper:
            self.isContainSuper = true
            self.isContainChildInChild = false
        case .hasChild:
            self.isContainSuper = false
            self.isContainChildInChild = true
        case .hasSuperChild:
            self.isContainSuper = true
            self.isContainChildInChild = true
        }
        
        self.maxDepth = maxDepth
    }
    
    public static let `default` = KcAnalyzePropertyTool(isContainSuper: false, isContainChildInChild: false)
    
}

// MARK: - public

public extension KcAnalyzePropertyTool {
    /// 查询对象的属性列表 properties
    /// - Parameters:
    ///   - value: 要查询的对象
    ///   - depth: 深度
    ///   - name: 查询对象的key
    /// - Returns: KcPropertyInfo?
    func ivarsFromValue(_ value: Any, depth: Int = 0, name: String = "顶层😄") -> KcPropertyInfo? {
        guard let filterOptionalResult = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        let ivarInfo = KcPropertyInfo(name: name,
                                  value: filterOptionalResult.1,
                                  mirror: filterOptionalResult.0,
                                  depth: depth)
        
        if isContainSuper {
            superIvarsWithMirror(filterOptionalResult.0, ivarInfo: ivarInfo, depth: depth + 1)
        }
        ivarsWithMirror(filterOptionalResult.0, ivarInfo: ivarInfo, depth: depth + 1)
        
        return ivarInfo
    }
}

// MARK: - private

private extension KcAnalyzePropertyTool {
    /// 当前对象的properties
    /// - Parameters:
    ///   - containerMirror: 当前对象
    ///   - ivarInfo: 当前对象info
    ///   - depth: 当前深度
    func ivarsWithMirror(_ containerMirror: Mirror, ivarInfo: KcPropertyInfo, depth: Int = 0) {
        if depth > maxDepth { // 最多处理3层
            return
        }
        
        for case let (label?, childValue) in containerMirror.children {
            // childValue可能为nil, but Any不能与nil比较
            // 这里本来也要判断只处理自定义的结构的, but不知道如何判断⚠️
            guard let childResult = Mirror.kc_makeFilterOptional(reflecting: childValue) else {
                continue
            }
            let childIvarInfo = KcPropertyInfo(name: label,
                                           value: childResult.1,
                                           mirror: childResult.0,
                                           containMirror: containerMirror,
                                           depth: depth)
            ivarInfo.childs.append(childIvarInfo)
            // 如果A中有B, B中有A, 会死循环 - 限制了层数
            if isContainChildInChild {
                ivarsWithMirror(childResult.0, ivarInfo: childIvarInfo, depth: depth + 1)
            }
        }
    }
    
    /// 处理super的properties
    /// - Parameters:
    ///   - mirror: 当前对象
    ///   - ivarInfo: 当前对象的信息info (全部的super都是加到当前对象info, super的属性是加到自己)
    ///   - depth: 深度
    func superIvarsWithMirror(_ mirror: Mirror, ivarInfo: KcPropertyInfo, depth: Int = 0) {
        guard depth <= maxDepth,
              let superclassMirror = mirror.superclassMirror,
              shouldHandleMirror(superclassMirror) else {
            return
        }
        
        let superIvarInfo = KcPropertyInfo(name: "super",
                                       value: ivarInfo.value,
                                       mirror: superclassMirror,
                                       containMirror: ivarInfo.containMirror,
                                       depth: 0)
        ivarInfo.supers.insert(superIvarInfo, at: 0)
        
        superIvarsWithMirror(superclassMirror, ivarInfo: ivarInfo, depth: depth + 1)
        // 处理自己的ivar, so depth是从1开始
        ivarsWithMirror(superclassMirror, ivarInfo: superIvarInfo, depth: 1)
    }
    
    /// 是否处理mirror (只处理自定义的)
    func shouldHandleMirror(_ mirror: Mirror) -> Bool {
        return mirror.kc_isCustomClass
        
//        guard let aClass = mirror.subjectType as? AnyClass else {
//            return false
//        }
//        let path = Bundle.init(for: aClass).bundlePath
//        return path.hasPrefix(Bundle.main.bundlePath)
    }
}

// MARK: - KcPropertyInfo 属性信息

public class KcPropertyInfo {
    public let containMirror: Mirror? // 容器
    
    // --- 当前对象的
    
    public let name: String // 属性name
    public let mirror: Mirror // 当前对象
    public var value: Any?
    public let address: String? // 地址
    
    public let depth: Int       // 深度 - 最多3层
    
    /// 当前对象继承的super层级 (super自己的属性, 在自己的childs中)
    public var supers: [KcPropertyInfo] = []
    /// 当前对象属性列表
    public var childs: [KcPropertyInfo]
    
    public init(name: String,
                value: Any?,
                mirror: Mirror,
                containMirror: Mirror? = nil,
                depth: Int = 0,
                childs: [KcPropertyInfo] = []) {
        self.name = KcPropertyInfo.propertyNameFormatter(name)
        self.mirror = mirror
        self.containMirror = containMirror
        self.depth = depth
        self.childs = childs
        self.value = value
        
        // address
        if mirror.displayStyle == .class, let objc = value {
            let point = Unmanaged.passUnretained(objc as AnyObject).toOpaque()
//                let hashValue2 = withUnsafePointer(to: &value) { point in
//                    return point.hashValue
//                }
            address = "\(point)"
        } else {
            address = nil
        }
    }
}

public extension KcPropertyInfo {
    var className: String {
        return mirror.kc_className
    }
    
    /// 输出log
    func log(filter: (KcPropertyInfo) -> Bool) {
//        let spaceString = String.init(repeating: " ", count: (depth + 1) * 2)
        
        func recursionChilds(info: KcPropertyInfo) -> String {
            var result = ""
            
            // 1.super
            info.supers.forEach { info in
                let supers = recursionChilds(info: info)
                result.append(supers)
            }
            
            // 2.当前
            // depth = 0 为起点
            if info.depth == 0 || filter(info) {
                result += info.description + "\n"
            }
            
            // 3.child
            info.childs.forEach { info in
                let childs = recursionChilds(info: info)
                result.append(childs)
            }
            return result
        }
        
        let description = recursionChilds(info: self)
        print(description)
    }
    
    /// 判断是否相等, 有些情况也不知道如何处理⚠️
    func isEqual(objc: NSObject) -> Bool {
        if objc.isEqual(value) {
            return true
        }
        
        switch mirror.displayStyle {
        case .collection:
            if let array = value as? [AnyObject] {
                return array.contains(where: { objc.isEqual($0) })
            } else {
                return false
            }
        case .dictionary:
            if let dict = value as? [String : AnyObject] {
                return dict.values.contains(where: { objc.isEqual($0) })
            } else {
                return false
            }
        case .set:
            if let set = value as? Set<NSObject> {
                return set.contains(where: { objc.isEqual($0) })
            } else {
                return false
            }
        case .tuple: // 不知道如何处理
            return false
        default:
            return false
        }
    }
    
    var description: String {
        let value = self.value ?? ""
        
        if depth == 0 { // 顶层
            return "in \(mirror.subjectType):"
        }
        let prefixString = String.init(repeating: "   | ", count: depth)
        
        let address = self.address == nil ? "" : " address: \(self.address ?? ""),"
        let className = " className: \(self.className),"
        
        return "\(prefixString)name: \(name),\(address)\(className) 属性value: \(value)"
    }
}

private extension KcPropertyInfo {
    /// 格式化属性name
    static func propertyNameFormatter(_ name: String) -> String {
        var result = name
        // 1.懒加载的属性, name会以这个开头
        if name.hasPrefix("$__lazy_storage_$_") {
            result = String(name[name.index(name.startIndex, offsetBy: "$__lazy_storage_$_".count)...])
        }
        
        return result
    }
}

// MARK: - Mirror

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
    
    /// 初始化, 过滤可选
    static func kc_makeFilterOptional(reflecting: Any) -> (Mirror, Any)? {
        let mirror = Mirror(reflecting: reflecting)
        
        return mirror.kc_filterOptionalReflectValue(reflecting)
    }
    
    /// 获取类名
    var kc_className: String {
//        let name: String?
//        if let object = object {
//            name = "\(type(of: object))"
//        } else if let ivar = ivar {
//            name = "\(type(of: ivar))"
//        } else {
//            name = nil
//        }
        
//        return "\(mirror.subjectType)"
        
        let type = _typeName(subjectType)
            .replacingOccurrences(of: "__C.", with: "")
            .replacingOccurrences(of: "Swift.", with: "")
        
        return type
    }
    
    /// 是否是自定义class
    var kc_isCustomClass: Bool {
        guard let aClass = subjectType as? AnyClass else {
            return false
        }
        let path = Bundle.init(for: aClass).bundlePath
        return path.hasPrefix(Bundle.main.bundlePath)
    }
}



