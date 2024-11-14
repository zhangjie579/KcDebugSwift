//
//  KcSwiftFindPropertyTooler.swift
//  Pods
//
//  Created by 张杰 on 2024/11/10.
//  查找对象属性相关信息

import Foundation

public class KcSwiftFindPropertyTooler {
    /// 获取属性列表
    public class func propertyList(value: Any) -> [String : String]? {
        guard let mirror = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        var dict = [String : String]()
        
        var currentMirror: Mirror? = mirror.0
        
        while let _currentMirror = currentMirror {
            // 遍历所有属性
            for (label, childValue) in _currentMirror.children {
                guard let propertyName = label else {
                    continue
                }
                
                let name = KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(propertyName)
                
                dict[name] = Mirror.typeName(value: childValue)
            }
            
            currentMirror = currentMirror?.superclassMirror
        }
        
        return dict
    }
    
    /// 搜索value的属性
    public class func searchProperty(value: Any, key: String) -> Any? {
        guard let mirror = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        // 遍历所有属性
        for (label, childValue) in mirror.0.children {
            guard let propertyName = label else {
                continue
            }
            
            let name = KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(propertyName)
            
            guard name == key else {
                continue
            }
            
            // KcJSONHelper.decodeToJSON(childValue) 调用这个方法的话, 如果value不是oc的类型, 转换可能会出现问题⚠️
            return KcJSONHelper.decodeSwiftToJSON(childValue)
        }
        
        return nil
    }
    
    /// 搜索value的keyPath属性
    public class func searchProperty(value: Any, keyPath: String) -> Any? {
        guard var mirror = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        let keys = keyPath.split(separator: ".")
            .map(String.init)
        
        for (i, key) in keys.enumerated() {
            var hasFind = false
            
            for (label, childValue) in mirror.0.children {
                guard let propertyName = label else {
                    continue
                }
                
                let name = KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(propertyName)
                
                guard name == key else {
                    continue
                }
                
                hasFind = true
                
                // 最后1个
                if i == keys.count - 1 {
                    // KcJSONHelper.decodeToJSON(childValue) 调用这个方法的话, 如果value不是oc的类型, 转换可能会出现问题⚠️
                    return KcJSONHelper.decodeSwiftToJSON(childValue)
                } else if let childMirror = Mirror.kc_makeFilterOptional(reflecting: childValue) {
                    mirror = childMirror
                    break
                } else {
                    hasFind = false
                    break
                }
            }
            
            if !hasFind {
                return nil
            }
        }
        
        // 遍历所有属性
        
        return nil
    }
}
