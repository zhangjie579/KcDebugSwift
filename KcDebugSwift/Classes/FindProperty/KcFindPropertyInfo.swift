//
//  KcFindPropertyInfo.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/13.
//

import UIKit

// MARK: - PropertyInfo 属性信息

public extension KcFindPropertyTooler {
    class PropertyInfo {
        public let containMirror: Mirror? // 容器
        
        // --- 当前对象的
        
        public let name: String // 属性name
        public let mirror: Mirror // 当前对象
        public var value: Any?
        public let address: String? // 地址
        
        public let depth: Int       // 深度 - 最多3层
        
        /// 当前对象继承的super层级 (super自己的属性, 在自己的childs中)
        public var supers: [PropertyInfo] = []
        /// 当前对象属性列表
        public var childs: [PropertyInfo]
        
        public init(name: String,
                    value: Any?,
                    mirror: Mirror,
                    containMirror: Mirror? = nil,
                    depth: Int = 0,
                    childs: [PropertyInfo] = []) {
            self.name = PropertyInfo.propertyNameFormatter(name)
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
}

// MARK: - public

public extension KcFindPropertyTooler.PropertyInfo {
    var className: String {
        return mirror.kc_className
    }
    
    /// 输出log
    func log(filter: (KcFindPropertyTooler.PropertyInfo) -> Bool) {
//        let spaceString = String.init(repeating: " ", count: (depth + 1) * 2)
        
        func recursionChilds(info: KcFindPropertyTooler.PropertyInfo) -> String {
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
    func isEqual(objc: AnyObject) -> Bool {
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
        case .tuple: // 不知道如何处理 - 不知道内存布局, 虽然跟struct布局一样
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

// MARK: - help

extension KcFindPropertyTooler.PropertyInfo {
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

// MARK: - Result 查找的属性的结果

public extension KcFindPropertyTooler {
    /// 查找的属性的结果
    class Result: NSObject {
        /// 属性info
        public let property: KcFindPropertyTooler.PropertyInfo?
        /// 属性所属容器
        public let container: Any?
        /// 属性
        public let object: AnyObject
        
        public init(property: KcFindPropertyTooler.PropertyInfo?, container: Any?, object: AnyObject) {
            self.object = object
            self.property = property
            self.container = container
            super.init()
        }
    }
}

public extension KcFindPropertyTooler.Result {
    /// 容器的类名
    var containClassName: String {
        if let className = property?.containMirror?.kc_className {
            return className
        }
        return container.map { Mirror(reflecting: $0) }?.kc_className ?? ""
    }
    
    /// 属性名
    var propertyName: String {
        return property?.name ?? ""
    }
    
    /// 属性地址
    var address: String {
        return "\(Unmanaged.passUnretained(object).toOpaque())"
    }
    
    /// 属性名
    var className: String {
        return "\(type(of: object))"
    }
}

extension KcFindPropertyTooler.Result {
    /// 生成propertyResult
    var propertyResult: KcFindPropertyTooler.PropertyResult {
        return .init(name: propertyName,
                     address: address,
                     className: className,
                     containClassName: containClassName)
    }
}

// MARK: - PropertyResult 用于oc的结果

@objc
public extension KcFindPropertyTooler {
    @objc(KcPropertyResult)
    @objcMembers
    class PropertyResult: NSObject {
        
        public let name: String // 属性name
        public let address: String? // 地址
        public let className: String // 属性类名
        public let containClassName: String // 属性所属容器类名
        
        public init(name: String, address: String?, className: String, containClassName: String) {
            self.name = name
            self.address = address
            self.className = className
            self.containClassName = containClassName
        }
    }
}


