//
//  KcFindUIPropertyService.swift
//  Pods
//
//  Created by 张杰 on 2022/12/2.
//  查找UI属性的接口

import Foundation

@objc(KcFindUIPropertyService)
public protocol KcFindUIPropertyService: NSObjectProtocol {
    func matchProperty(view: UIView) -> Bool
    
    func propertyDescription(view: UIView) -> String
}

// MARK: - KcFindUIBgColorProperty 背景色

@objc(KcFindUIBgColorProperty)
public class KcFindUIBgColorProperty: NSObject, KcFindUIPropertyService {
    
    public func matchProperty(view: UIView) -> Bool {
        guard let backgroundColor = view.backgroundColor else {
            return false
        }
        
        return backgroundColor == .clear ? false : true
    }
    
    public func propertyDescription(view: UIView) -> String {
        return "backgroundColor: \(view.backgroundColor ?? .clear)"
    }
}

// MARK: - KcFindUIBorderProperty 边框

@objc(KcFindUIBorderProperty)
public class KcFindUIBorderProperty: NSObject, KcFindUIPropertyService {
    
    public func matchProperty(view: UIView) -> Bool {
        if view.layer.borderWidth < 0 {
            return false
        }
        
        guard let borderColor = view.layer.borderColor, borderColor != UIColor.clear.cgColor else {
            return false
        }
        
        return true
    }
    
    public func propertyDescription(view: UIView) -> String {
        return "borderWidth: \(view.layer.borderWidth), borderColor: \(view.layer.borderColor ?? UIColor.clear.cgColor)"
    }
}

// MARK: - KcFindUICornerRadiusProperty 圆角

@objc(KcFindUICornerRadiusProperty)
public class KcFindUICornerRadiusProperty: NSObject, KcFindUIPropertyService {
    
    public func matchProperty(view: UIView) -> Bool {
        return view.layer.cornerRadius > 0
    }
    
    public func propertyDescription(view: UIView) -> String {
        return "cornerRadius: \(view.layer.cornerRadius), clipsToBounds: \(view.clipsToBounds), masksToBounds: \(view.layer.masksToBounds)"
    }
}

// MARK: - KcFindUIPropertyName 圆角

@objc(KcFindUIPropertyName)
public class KcFindUIPropertyName: NSObject, KcFindUIPropertyService {
    
    private let propertyName: String
    
    @objc public init(propertyName: String) {
        self.propertyName = propertyName
        super.init()
    }
    
    public func matchProperty(view: UIView) -> Bool {
        if propertyName.contains(".") { // keyPath - 不判断
            return view.value(forKeyPath: propertyName) != nil
        } else {
            return view.responds(to: NSSelectorFromString(propertyName))
        }
    }
    
    public func propertyDescription(view: UIView) -> String {
//        let value = view.value(forKeyPath: propertyName)
        
        return "\(propertyName): \(view.value(forKeyPath: propertyName) ?? "None")"
    }
}
