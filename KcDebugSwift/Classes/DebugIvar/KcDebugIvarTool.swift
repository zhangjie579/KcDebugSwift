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
        let ivarTool = KcAnalyzeIvarTool.init(type: rawValue)
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
        let ivarTool = KcAnalyzeIvarTool.init(type: rawValue)
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

// MARK: - KcIvarInfo

public class KcIvarInfo {
    let name: String
    let containMirror: Mirror? // 容器
    let mirror: Mirror // 当前对象
    let ivar: Any?
    weak var object: AnyObject?
    let address: String? // 地址
    let depth: Int       // 深度 - 最多3层
    
    var supers: [KcIvarInfo] = []
    var childs: [KcIvarInfo] // 子类
    
    public init(name: String,
                ivar: Any?,
                mirror: Mirror,
                containMirror: Mirror? = nil,
                depth: Int = 0,
                childs: [KcIvarInfo] = []) {
        self.name = KcIvarInfo.propertyNameFormatter(name)
        self.mirror = mirror
        self.containMirror = containMirror
        self.depth = depth
        self.childs = childs
        
        if mirror.displayStyle == .class {
            self.object = ivar as AnyObject
            self.ivar = nil
        } else {
            self.ivar = ivar
        }
        
        if let p = object {
            let point = Unmanaged.passUnretained(p).toOpaque()
            address = "\(point)"
        } else {
            address = nil
        }
    }
}

public extension KcIvarInfo {
    var value: Any? {
        if let object = object {
            return object
        } else if let ivar = ivar {
            return ivar
        } else {
            return nil
        }
    }
    
    var className: String {
//        let name: String?
//        if let object = object {
//            name = "\(type(of: object))"
//        } else if let ivar = ivar {
//            name = "\(type(of: ivar))"
//        } else {
//            name = nil
//        }
        
        return "\(mirror.subjectType)"
    }
    
    func log(filter: (KcIvarInfo) -> Bool) {
//        let spaceString = String.init(repeating: " ", count: (depth + 1) * 2)
        
        func recursionChilds(info: KcIvarInfo) -> String {
            var result = ""
            
            // 1.super
            info.supers.forEach { info in
                let supers = recursionChilds(info: info)
                result.append(supers)
            }
            
            // 2.当前
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
    
    var description: String {
        let value = self.value ?? ""
        
        if depth == 0 { // 顶层
            return "in \(mirror.subjectType):"
        }
        let prefixString = String.init(repeating: "   | ", count: depth)
        
        let address = self.address == nil ? "" : " address: \(self.address ?? ""),"
        let className = " className: \(self.className),"
        
        return "\(prefixString)name: \(name),\(address)\(className) ivar: \(value)"
    }
}

private extension KcIvarInfo {
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

// MARK: - KcAnalyzeIvarTool

@objc
public enum KcAnalyzeIvarType : Int {
    case `default` = 0
    case hasSuper = 1
    case hasChild = 2
    case hasSuperChild = 3
}

/// 分析ivar
public struct KcAnalyzeIvarTool {
    
    /// 最大处理深度
    let maxDepth = 3
    /// 是否包含super
    let isContainSuper: Bool
    /// 是否包含child中的child
    let isContainChildInChild: Bool
    
    public init(isContainSuper: Bool, isContainChildInChild: Bool) {
        self.isContainSuper = isContainSuper
        self.isContainChildInChild = isContainChildInChild
    }
    
    public init(type: KcAnalyzeIvarType) {
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
    }
    
    public static let `default` = KcAnalyzeIvarTool(isContainSuper: false, isContainChildInChild: false)
    
    public func ivarsFromValue(_ value: Any, depth: Int = 0) -> KcIvarInfo? {
        guard let filterOptionalResult = Mirror.init(reflecting: value).kc_filterOptionalReflectValue(value) else {
            return nil
        }
        let ivarInfo = KcIvarInfo(name: "顶层😄", ivar: filterOptionalResult.1, mirror: filterOptionalResult.0, depth: depth)
        
        if isContainSuper {
            superIvarsWithMirror(filterOptionalResult.0, ivarInfo: ivarInfo, depth: depth + 1)
        }
        ivarsWithMirror(filterOptionalResult.0, ivarInfo: ivarInfo, depth: depth + 1)
        
        return ivarInfo
    }
}

private extension KcAnalyzeIvarTool {
    /// 当前的
    func ivarsWithMirror(_ mirror: Mirror, ivarInfo: KcIvarInfo, depth: Int = 0) {
        if depth > maxDepth { // 最多处理3层
            return
        }
        
        for case let (label?, childValue) in mirror.children {
            // childValue可能为nil, but Any不能与nil比较
            // 这里本来也要判断只处理自定义的结构的, but不知道如何判断⚠️
            guard let filterOptionalResult = Mirror(reflecting: childValue)
                        .kc_filterOptionalReflectValue(childValue) else {
                continue
            }
            let childIvarInfo = KcIvarInfo(name: label, ivar: filterOptionalResult.1, mirror: filterOptionalResult.0, containMirror: mirror, depth: depth)
            ivarInfo.childs.append(childIvarInfo)
            // 如果A中有B, B中有A, 会死循环 - 限制了层数
            if isContainChildInChild {
                ivarsWithMirror(filterOptionalResult.0, ivarInfo: childIvarInfo, depth: depth + 1)
            }
        }
    }
    
    /// 处理super的
    func superIvarsWithMirror(_ mirror: Mirror, ivarInfo: KcIvarInfo, depth: Int = 0) {
        guard depth <= maxDepth,
              let superclassMirror = mirror.superclassMirror,
              shouldHandleMirror(superclassMirror) else {
            return
        }
        
        let superIvarInfo = KcIvarInfo(name: "super", ivar: nil, mirror: superclassMirror, containMirror: nil, depth: 0)
        ivarInfo.supers.insert(superIvarInfo, at: 0)
        
        superIvarsWithMirror(superclassMirror, ivarInfo: ivarInfo, depth: depth + 1)
        // 处理自己的ivar, so depth是从1开始
        ivarsWithMirror(superclassMirror, ivarInfo: superIvarInfo, depth: 1)
    }
    
    /// 是否处理mirror (只处理自定义的)
    func shouldHandleMirror(_ mirror: Mirror) -> Bool {
        guard let aClass = mirror.subjectType as? AnyClass else {
            return false
        }
        let path = Bundle.init(for: aClass).bundlePath
        return path.hasPrefix(Bundle.main.bundlePath)
    }
}

public extension Mirror {
    /// 对象是否为optional
    var kc_isOptionalValue: Bool {
        return displayStyle == .optional
    }
    
    /// 去反射value的可选值的mirror: 当反射value为optional, 它为value去optional的mirror
    func kc_filterOptionalReflectValue(_ value: Any) -> (Mirror, Any)? {
        guard kc_isOptionalValue else {
            return (self, value)
        }
        for (key, value) in children where key == "some" {
            return Mirror(reflecting: value).kc_filterOptionalReflectValue(value)
        }
        return nil
    }
}



