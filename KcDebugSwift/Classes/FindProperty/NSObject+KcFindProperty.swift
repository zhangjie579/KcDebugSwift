//
//  NSObject+KcFindProperty.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2024/11/8.
//

import UIKit

// MARK: - 用于LLDB调试

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
    func kc_dumpSwift() -> Any {
        return dump(self)
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
    
    /// 查找UI的属性名
    func kc_debug_findPropertyNameResult() -> KcFindPropertyTooler.PropertyResult? {
        var findObjc: UIResponder? = self
        
        // 循环作用: 当查询的对象为系统控件下面的控件, 比如UIButton下的imageView
        while let objc = findObjc {
            if let result = KcFindPropertyTooler.findResponderChainObjcPropertyName(object: objc,
                                                                     startSearchView: objc.next,
                                                                     isLog: true) {
                if self !== objc {
                    return nil
                } else {
                    return result
                }
            }
            
            findObjc = objc.next
        }
        
        return nil
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

// MARK: - 查找属性

@objc
public extension NSObject {
    
    /// 获取属性列表
    /// expr -l objc++ -O -- [self kc_propertyList]
    func kc_propertyList() -> [String : String]? {
        return KcFindPropertyTooler.propertyList(value: self)
    }
    
    /// 查找属性的JSON
    /// expr -l objc++ -O -- [self kc_searchPropertyWithKey:xxx]
    func kc_searchProperty(key: String) -> Any? {
        return KcFindPropertyTooler.searchProperty(value: self, key: key)
    }
    
    /// 查找属性的JSON
    // expr -l objc++ -O -- [self kc_searchPropertyWithKeyPath:xxx]
    func kc_searchProperty(keyPath: String) -> Any? {
        return KcFindPropertyTooler.searchProperty(value: self, keyPath: keyPath)
    }
}
