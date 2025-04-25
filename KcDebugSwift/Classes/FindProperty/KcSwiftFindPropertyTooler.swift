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
        guard let mirrorInfo = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        var mirror: Mirror? = mirrorInfo.0
        
        while let _mirror = mirror {
            // 遍历所有属性
            for (label, childValue) in _mirror.children {
                guard let propertyName = label else {
                    continue
                }
                
                let name = KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(propertyName)
                
                if name != key {
                    continue
                }
                
                // KcJSONHelper.decodeToJSON(childValue) 调用这个方法的话, 如果value不是oc的类型, 转换可能会出现问题⚠️
                return KcJSONHelper.decodeSwiftToJSON(childValue)
            }
            
            // 父类
            mirror = mirror?.superclassMirror
        }
        
        return nil
    }
    
    /// 搜索value的keyPath属性
    public class func searchProperty(value: Any, keyPath: String) -> Any? {
        guard let mirrorInfo = Mirror.kc_makeFilterOptional(reflecting: value) else {
            return nil
        }
        
        let keys = keyPath.split(separator: ".")
            .map(String.init)
        
        var mirror: Mirror? = mirrorInfo.0
        
        for (i, key) in keys.enumerated() {
            
            while let _mirror = mirror {
                // 是否发现当前
                var hasFindCurrent: Bool = false
                
                for (label, childValue) in _mirror.children {
                    guard let propertyName = label else {
                        continue
                    }
                    
                    let name = KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(propertyName)
                    
                    if name != key {
                        continue
                    }
                    
                    hasFindCurrent = true
                    
                    // 最后1个
                    if i == keys.count - 1 {
                        // KcJSONHelper.decodeToJSON(childValue) 调用这个方法的话, 如果value不是oc的类型, 转换可能会出现问题⚠️
                        return KcJSONHelper.decodeSwiftToJSON(childValue)
                    } else if let childMirror = Mirror.kc_makeFilterOptional(reflecting: childValue) {
                        mirror = childMirror.0
                        break
                    } else {
                        mirror = nil
                        break
                    }
                }
                
                if hasFindCurrent { // 当前的已经找到了 - 继续下一级
                    break
                } else { // 当前没找到 - 通过super找
                    mirror = mirror?.superclassMirror
                }
            }
            
            // 能到这说明，要么下一级、要么superclassMirror, 如果没有mirror肯定就不用再找了
            if mirror == nil {
                return nil
            }
        }
        
        // 遍历所有属性
        
        return nil
    }
}

// MARK: - private

private extension KcSwiftFindPropertyTooler {
    class func searchValueProperty(mirror: Mirror, key: String) -> Any? {
        var currentMirror: Mirror? = mirror
        
        while let _currentMirror = currentMirror {
            // 遍历当前
            for (label, childValue) in _currentMirror.children {
                guard let propertyName = label else {
                    continue
                }
                
                let name = KcFindPropertyTooler.PropertyInfo.propertyNameFormatter(propertyName)
                
                guard name == key else {
                    continue
                }
                
                return childValue
            }
            
            // 没找到就找super
            currentMirror = currentMirror?.superclassMirror
        }
        
        return nil
    }
}
