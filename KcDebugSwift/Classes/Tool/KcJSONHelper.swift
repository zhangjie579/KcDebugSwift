//
//  KcJSONHelper.swift
//  KcDebugSwift_Example
//
//  Created by 张杰 on 2024/10/10.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

@objc(KcJSONHelper)
//@objcMembers
public class KcJSONHelper: NSObject {
    
}

// MARK: - public oc接口 (代码调用的话, 不要直接使用oc接口, 类型可能会桥架错误⚠️)

// 最好只用于动态调用，调试时使用，比如lldb、动态方法调用 🐶
@objc
public extension KcJSONHelper {
    
    /// 解析字段到基本数据类型, 去 model 化
    class func decodeToJSON(_ value: Any) -> Any? {
        return _decodeToJSON(value, currentIndex: 1, maxCount: 10)
    }
    
    /// 解析单个对象到JSON
    /// ⚠️外部调用推荐使用参数为 mirror 的接口
    class func decodeToJSONSingleValue(_ object: Any) -> [String: Any]? {
        guard let mirror = Mirror.kc_makeFilterOptional(reflecting: object) else {
            return nil
        }
        
        return _decodeToJSONSingleValue(mirror: mirror.0, currentIndex: 1, maxCount: 10)
    }
    
    /// 判断是否基础类型
    class func toBasicObjc(objc: Any) -> Any? {
        return toBasicValue(value: objc)
    }
}

// MARK: - public swift接口

//@nonobjc
public extension KcJSONHelper {
    
    /// 解析字段到基本数据类型, 去 model 化
    class func decodeSwiftToJSON(_ value: Any) -> Any? {
        return _decodeToJSON(value, currentIndex: 1, maxCount: 10)
    }
    
    /// 解析单个对象到JSON
    class func decodeToJSONSingleValue(mirror: Mirror, maxCount: Int = 10) -> [String: Any]? {
        return _decodeToJSONSingleValue(mirror: mirror, currentIndex: 1, maxCount: maxCount)
    }
    
    /// 判断是否基础类型
    class func toBasicValue(value: Any) -> Any? {
        if let value = value as? String {
            return value
        } else if let value = value as? Int {
            return value
        } else if let value = value as? Bool {
            return value
        } else if let value = value as? Double {
            return value
        } else if let value = value as? Float {
            return value
        } else if let value = value as? CGFloat {
            return value
        } else if let value = value as? CGSize {
            return value
        } else if let value = value as? CGRect {
            return value
        } else if let value = value as? UIEdgeInsets {
            return value
        } else if let array = value as? [Any] {
            let s = array.compactMap { toBasicValue(value: $0) }
            
            if s.count != array.count {
                return nil
            } else {
                return s
            }
        } else if let dict = value as? [String : Any] {
            
            var s = [String : Any]()
            
            for (k, v) in dict {
                s[k] = toBasicValue(value: v)
            }
            
            if s.count != dict.count {
                return nil
            } else {
                return s
            }
        } else {
            return nil
        }
    }
}

// MARK: - private
//@nonobjc
private extension KcJSONHelper {
    
    /// 解析字段到基本数据类型, 去 model 化
    class func _decodeToJSON(_ value: Any, currentIndex: Int, maxCount: Int) -> Any? {
        if let s = toBasicValue(value: value) {
            return s
        } else if let s = value as? [Any] {
            return s.compactMap { _decodeToJSON($0, currentIndex: currentIndex + 1, maxCount: maxCount) }
        } else if let s = value as? [String : Any] { // any不是基本数据类型
            let s1 = s.compactMapValues { _decodeToJSON($0, currentIndex: currentIndex + 1, maxCount: maxCount) }
            
            if s1.count == s.count {
                return s1
            } else {
                return nil
            }
        } else if let mirrorTuple = Mirror.kc_makeFilterOptional(reflecting: value),
                    mirrorTuple.0.children.count > 0,
                    let s = _decodeToJSONSingleValue(mirror: mirrorTuple.0, currentIndex: currentIndex + 1, maxCount: maxCount) {
            return s
        } else if let s = _decodeToJSONSingleValue(value, currentIndex: currentIndex + 1, maxCount: maxCount) {
            return s
        } else {
            return nil
        }
    }
    
    /// 解析单个对象到JSON
    /// ⚠️外部调用推荐使用参数为 mirror 的接口
    class func _decodeToJSONSingleValue(_ object: Any, currentIndex: Int, maxCount: Int) -> [String: Any]? {
        guard let mirror = Mirror.kc_makeFilterOptional(reflecting: object) else {
            return nil
        }
        
        return _decodeToJSONSingleValue(mirror: mirror.0, currentIndex: currentIndex + 1, maxCount: maxCount)
    }
    
    /// 解析单个对象到JSON
    class func _decodeToJSONSingleValue(mirror: Mirror, currentIndex: Int, maxCount: Int) -> [String: Any]? {
        if currentIndex > maxCount {
            return nil
        }
        
        var dict: [String: Any] = [:]
        
        // 遍历所有属性
        for (label, value) in mirror.children {
            guard let name = label,
                    let childMirror = Mirror.kc_makeFilterOptional(reflecting: value) else { continue }
            
            let propertyName = Mirror.propertyName(name)
            
            let childValue = childMirror.1
            
            if let value = toBasicValue(value: childValue) {
                dict[propertyName] = value
            } else if let displayStyle = childMirror.0.displayStyle, (displayStyle == .tuple || displayStyle == .collection || displayStyle == .dictionary) {
                
                if let v = childValue as? [Any] {
                    var array = [Any]()
                    
                    for item in v {
                        guard let s = _decodeToJSON(item, currentIndex: currentIndex + 1, maxCount: maxCount) else { continue }
                        
                        array.append(s)
                    }
                    
                    dict[propertyName] = array
                } else if let childDict = childValue as? [String : Any] {
                    var dic = [String : Any]()
                    
                    for (k, v) in childDict {
                        guard let s = _decodeToJSON(v, currentIndex: currentIndex + 1, maxCount: maxCount) else { continue }
                        
                        dic[k] = s
                    }
                    
                    dict[propertyName] = dic
                } else { // tuple
                    
                }
            } else if let nestedValue = _decodeToJSONSingleValue(mirror: childMirror.0, currentIndex: currentIndex + 1, maxCount: maxCount) {
                // 如果是嵌套对象，进行递归转换
                dict[propertyName] = nestedValue
            } else {
                dict[propertyName] = "\(value)"
            }
        }
        
        return dict.isEmpty ? nil : dict
    }
    
    /// 处理objc
    class func _decodeObjcToJSON(objc: NSObject, currentIndex: Int, maxCount: Int) -> [String : Any]? {
        var currentCls: AnyClass? = object_getClass(objc)
        
        var dict: [String: Any] = [:]
        
        while let _currentCls = currentCls {
            var count: UInt32 = 0
            
            currentCls = class_getSuperclass(_currentCls)
            
            guard let ivars = class_copyIvarList(_currentCls, &count) else {
                continue
            }
            
            for i in 0 ..< count {
                guard let name = ivar_getName(ivars[Int(i)]) else {
                    continue
                }
                
                let nameStr = String(cString: name)
                
                // let value = object_getIvar(objc, ivars[Int(i)]) 这种可能会crash
                // kvo也存在crash
                let value = objc.value(forKey: nameStr)
                
                if let _value = value {
                    dict[nameStr] = _decodeToJSON(_value, currentIndex: currentIndex + 1, maxCount: maxCount)
                }
            }
        }
        
        return dict.isEmpty ? nil : dict
    }
}
