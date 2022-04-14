//
//  KcFindPropertyTool.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/13.
//  调试ivar工具, 可以在lldb环境下根据address使用

import UIKit

// MARK: - 外部使用接口 - 用于LLDB调试

// MARK: - 方案1: 根据要查找对象的address, 向上查找它的容器, 从而得到property info (从下向上 - 适用于UI)

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
    @discardableResult
    func kc_debug_findUIPropertyName() -> String {
        
        /// 处理layer delegate情况, 默认情况下delegate为UIView
        func handleLayerDelegate(delegate: CALayerDelegate) -> KcFindPropertyTooler.PropertyResult? {
            if let responder = delegate as? UIResponder {
                return KcFindPropertyTooler.findResponderChainObjcPropertyName(object: self, startSearchView: responder, isLog: true)
            } else { // 这种情况暂时不知道如何处理
                // 👻 请换过其他方式处理, CALayerDelegate不为UIView对象: \(delegate) 👻
                return nil
            }
        }
        
        /// 递归图层layer
        func recursSuperLayer(layer: CALayer) -> String {
            var superlayer = layer.superlayer
            
            while let nextLayer = superlayer {
                if let delegate = nextLayer.delegate,
                   let result = handleLayerDelegate(delegate: delegate) {
                    return result.debugLog
                } else {
                    if Mirror.kc_isCustomClass(type(of: nextLayer)),
                       let result = NSObject.kc_debug_findPropertyName(container: nextLayer, object: self) {
                        return result.debugLog
                    }
                    
                    superlayer = superlayer?.superlayer
                }
            }
            
            return "😭😭😭 未找到"
        }
        
        if isKind(of: UIView.self) {
            return (self as? UIView)?.kc_debug_findPropertyName() ?? "😭😭😭 未找到"
        } else if isKind(of: CALayer.self), let layer = self as? CALayer {
            if let delegate = layer.delegate, let result = handleLayerDelegate(delegate: delegate) {
                return result.debugLog
            } else { // 没有代理
                return recursSuperLayer(layer: layer)
            }
        }
        
        return "😭😭😭 未找到"
    }
    
    /// 为了能在runtime lldb使用
    /// expr -l objc++ -O -- [NSObject kc_dumpSwift:0x7f8738007690]
    class func kc_dumpSwift(_ value: Any) {
        dump(value)
    }
    
    /// expr -l objc++ -O -- [0x7f8738007690 kc_dumpSwift]
    func kc_dumpSwift() {
        dump(self)
    }
    
    /// 从container容器对象, 查找object的属性名, 不存在返回false (只会从当前对象查找, 不会查找对象属性下的属性的⚠️)
    /// - Parameters:
    ///   - container: 容器
    ///   - object: 要查找的对象
    /// - Returns: 是否找到
    class func kc_debug_findPropertyName(container: Any, object: AnyObject) -> KcFindPropertyTooler.PropertyResult? {
        return KcFindPropertyTooler.findObjcPropertyName(containerObjc: container, object: object, isLog: true)?.propertyResult
    }
}

// MARK: - UIView

@objc
public extension UIView {
    /// 查找UI的属性名
    /// expr -l objc++ -O -- [0x7f8738007690 kc_debug_findPropertyName]
    @discardableResult
    func kc_debug_findPropertyName() -> String {
        var findObjc: UIResponder? = self
        
        // 循环作用: 当查询的对象为系统控件下面的控件, 比如UIButton下的imageView
        while let objc = findObjc {
            if let result = KcFindPropertyTooler.findResponderChainObjcPropertyName(object: objc,
                                                                     startSearchView: objc.next,
                                                                     isLog: true) {
                if self !== objc {
                    return "🐶🐶🐶 查询的是系统控件的子控件: \(self) "
                } else {
                    return result.debugLog
                }
            }
            
            findObjc = objc.next
        }
        
        return "😭😭😭 未找到"
    }
}

// MARK: - 方案2: log出容器的all property info, 然后自己根据address, 去检索

@objc
public extension NSObject {
    /// 输出所有ivar
    /// expr -l objc++ -O -- [((NSObject *)0x7f8738007690) kc_debug_ivarDescription:0]
    func kc_debug_ivarDescription(_ rawValue: KcFindPropertyType = .default) {
        type(of: self).kc_debug_ivarDescription(self, rawValue: rawValue)
    }
    
    /// 输出UI相关的ivar
    // expr -l objc++ -O -- [((NSObject *)0x7f8738007690) kc_debug_UIIvarDescription:0]
    func kc_debug_UIIvarDescription(_ rawValue: KcFindPropertyType = .default) {
        type(of: self).kc_debug_UIIvarDescription(self, rawValue: rawValue)
    }
    
    /// 输出所有ivar
    /// expr -l objc++ -O -- [NSObject kc_debug_ivarDescription:0x7f8738007690 rawValue:0]
    class func kc_debug_ivarDescription(_ value: Any, rawValue: KcFindPropertyType = .default) {
        print("------------ 👻 ivar description 👻 ---------------")
        let ivarTool = KcFindPropertyTooler.init(type: rawValue)
        let ivarInfo = ivarTool.ivarsFromValue(value, depth: 0)
        ivarInfo?.log { _ in
            return true
        }
        print("------------ 👻 ivar description 👻 ---------------")
    }
    
    /// 输出UI相关的ivar
    // expr -l objc++ -O -- [NSObject kc_debug_UIIvarDescription:0x7f8738007690 rawValue:0]
    class func kc_debug_UIIvarDescription(_ value: Any, rawValue: KcFindPropertyType = .default) {
        print("------------ 👻 UI ivar description 👻 ---------------")
        let ivarTool = KcFindPropertyTooler.init(type: rawValue)
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

// MARK: - KcFindPropertyTooler 分析属性工具

@objc
public enum KcFindPropertyType : Int {
    case `default` = 0
    case hasSuper = 1
    case hasChild = 2
    case hasSuperChild = 3
}

/// 分析ivar
@objc(KcFindPropertyTooler)
public class KcFindPropertyTooler: NSObject {
    
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
    
    public init(type: KcFindPropertyType, maxDepth: Int = 5) {
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
    
    public static let `default` = KcFindPropertyTooler(isContainSuper: false, isContainChildInChild: false)
    
}

// MARK: - public  oc外部可用

@objc
public extension KcFindPropertyTooler {
    /// 查找objc的属性名, 通过响应链
    /// - Parameters:
    ///   - object: 要查询的对象
    ///   - startSearchView: 如果startSearchView为nil, 并且object为UIResponder, 从它的next开始, 然后递归nextResponder
    @discardableResult
    class func findResponderChainObjcPropertyName(object: NSObject,
                                                  startSearchView: UIResponder?,
                                                  isLog: Bool = false) -> PropertyResult? {
        var nextResponder: UIResponder? = startSearchView
        
        // 如果startSearchView为nil, 并且object为UIResponder, 从它的next开始
        if nextResponder == nil, let responder = object as? UIResponder {
            nextResponder = responder.next
        }
        
        while let next = nextResponder {
            defer {
                nextResponder = nextResponder?.next
            }
            
            if let result = findObjcPropertyName(containerObjc: next, object: object, isLog: isLog) {
                return result.propertyResult
            }
        }
        
        return nil
    }
    
    /// 查找property info
    /// - Parameters:
    ///   - containerObjc: containerObjc从哪个对象开始查, 容器
    ///   - object: object要查询的对象
    /// - Returns: 返回查询到的结果
    @discardableResult
    class func findPropertyInfo(containerObjc: NSObject, object: NSObject) -> PropertyResult? {
        guard let result = findObjcPropertyName(containerObjc: containerObjc, object: object) else {
            return nil
        }
        return result.propertyResult
    }
}

// MARK: - swift外部可用

public extension KcFindPropertyTooler {
    /// 从当前对象, 查找objc的属性名, 不存在返回false (只会从当前对象查找, 不会查找对象属性下的属性的⚠️)
    /// - Parameters:
    ///   - containerObjc: 容器
    ///   - object: 要查询的对象
    ///   - isLog: 是否log
    /// - Returns: 查找到的信息 KcFindPropertyResult
    @discardableResult
    class func findObjcPropertyName(containerObjc: Any, object: AnyObject, isLog: Bool = false) -> Result? {
        var container: Any?
        var propertyInfo: PropertyInfo?
        
        /// 查找property
        func findProperty(from ivarInfo: PropertyInfo, currentContainer: Any) -> Bool {
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
        
        let ivarTool = KcFindPropertyTooler(type: .hasSuper)
        
        let mirror = Mirror(reflecting: containerObjc)
        guard mirror.kc_isCustomClass,
              let ivarInfo = ivarTool.ivarsFromValue(containerObjc, depth: 0, name: "查询对象😄"),
              !ivarInfo.childs.isEmpty else {
            return nil
        }
        
        guard findProperty(from: ivarInfo, currentContainer: containerObjc) else {
            return nil
        }
        
        if isLog {
            print("------------ 👻 查询属性name 👻 ---------------")

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
        
        return Result(property: propertyInfo, container: container, object: object)
    }
    
    /// 查询对象的属性列表 properties
    /// - Parameters:
    ///   - value: 要查询的对象
    ///   - depth: 深度
    ///   - name: 查询对象的key
    /// - Returns: PropertyInfo?
    func ivarsFromValue(_ value: Any, depth: Int = 0, name: String = "顶层😄") -> PropertyInfo? {
        guard let filterOptionalResult = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        let ivarInfo = PropertyInfo(name: name,
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

private extension KcFindPropertyTooler {
    /// 当前对象的properties
    /// - Parameters:
    ///   - containerMirror: 当前对象
    ///   - ivarInfo: 当前对象info
    ///   - depth: 当前深度
    func ivarsWithMirror(_ containerMirror: Mirror, ivarInfo: PropertyInfo, depth: Int = 0) {
        if depth > maxDepth { // 最多处理3层
            return
        }
        
        for case let (label?, childValue) in containerMirror.children {
            // childValue可能为nil, but Any不能与nil比较
            // 这里本来也要判断只处理自定义的结构的, but不知道如何判断⚠️
            guard let childResult = Mirror.kc_makeFilterOptional(reflecting: childValue) else {
                continue
            }
            let childIvarInfo = PropertyInfo(name: label,
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
    func superIvarsWithMirror(_ mirror: Mirror, ivarInfo: PropertyInfo, depth: Int = 0) {
        guard depth <= maxDepth,
              let superclassMirror = mirror.superclassMirror,
              shouldHandleMirror(superclassMirror) else {
            return
        }
        
        let superIvarInfo = PropertyInfo(name: "super",
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
    }
}

