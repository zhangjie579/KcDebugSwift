//
//  KcAssociationManager.swift
//  KcDebugSwift
//
//  Created by 张杰 on 2021/12/12.
//

import UIKit

// MARK: - KcAssociationCycleReference

@objc(KcAssociationCycleReference)
@objcMembers
public class KcAssociationCycleReference: NSObject {}

@objc
public extension KcAssociationCycleReference {
    class func findStrongAssociationsWithProperty(_ property: KcReferencePropertyInfo,
                                                  doNext: (KcReferencePropertyInfo) -> Void) {
        guard let value = property.value else {
            return
        }
        
        let isExcluded = KcCycleReferenceConfiguration.shardInstance().isExcludeObjc(value, typeName: "\(type(of: value))")
        if isExcluded {
            return
        }
        
        let result = FBAssociationManager.strongAssociations(for: value)
        
        if result.count <= 0 {
            return
        }
        
        for (_, value) in result {
//            guard let nskey = key as? NSValue else {
//                return
//            }
            
            let name: String = {
                var associationName = "[association"
                
//                if let pointer = nskey.pointerValue {
//                    associationName += "+key: \(pointer)"
//                }
                
                associationName += "+value: \(value)]"
                
                return associationName
            }()
            
            let isExcluded = KcCycleReferenceConfiguration.shardInstance().isExcludeObjc(value, typeName: "\(type(of: value))")
            if isExcluded {
                continue
            }

            let childProperty = KcReferencePropertyInfo()
            childProperty.name = name
            childProperty.value = value as AnyObject
            childProperty.isStrong = true
            childProperty.superProperty = property
            property.childrens.add(childProperty)

            doNext(childProperty)
        }
    }
}


// MARK: - KcAssociationManager 管理关联对象hook

//@objc(KcAssociationManager)
//@objcMembers
//public class KcAssociationManager: NSObject {
//
//    public static let shared = KcAssociationManager()
//
//    public var associationMap = [ObjectIdentifier : [UnsafeRawPointer : Any]]()
//
//    public lazy var lock = NSLock()
//}
//
//@objc
//public extension KcAssociationManager {
//    func removeAllObjects(_ object: Any) {
//        lock.lock()
//        defer {
//            lock.unlock()
//        }
//
//        let identity = ObjectIdentifier(object as AnyObject)
//        associationMap[identity] = nil
//    }
//
//    func addObject(_ object: Any, _ key: UnsafeRawPointer, _ value: Any?) {
//        lock.lock()
//        defer {
//            lock.unlock()
//        }
//
//        let identity = ObjectIdentifier(object as AnyObject)
//        if associationMap[identity] == nil {
//            associationMap[identity] = [:]
//        }
//
//        associationMap[identity]?[key] = value
//    }
//
//    func objcStrongAssociations(_ object: Any) -> [Int : Any]? {
//        let identity = ObjectIdentifier(object as AnyObject)
//        guard let map = associationMap[identity] else {
//            return nil
//        }
//
//        return map.reduce(into: [Int : Any]()) { result, element in
//            let key = element.key.load(as: Int.self)
//            result[key] = element.value
//        }
//    }
//}
//
//public extension KcAssociationManager {
//    /// 获取strong关联对象
//    func strongAssociations(_ object: Any) -> [UnsafeRawPointer : Any]? {
//        let identity = ObjectIdentifier(object as AnyObject)
//        return associationMap[identity]
//    }
//}

//public func objc_setAssociatedObject(_ object: Any, _ key: UnsafeRawPointer, _ value: Any?, _ policy: objc_AssociationPolicy) {
//    switch policy {
//    case .OBJC_ASSOCIATION_COPY, .OBJC_ASSOCIATION_COPY_NONATOMIC,
//         .OBJC_ASSOCIATION_RETAIN, .OBJC_ASSOCIATION_RETAIN_NONATOMIC:
//        KcAssociationManager.shared.addObject(object, key, value)
//    case .OBJC_ASSOCIATION_ASSIGN:
//        break
//    @unknown default:
//        break
//    }
//    
//    kc_objc_setAssociatedObject(object, key, value, policy)
//}
//
//
//public func objc_removeAssociatedObjects(_ object: Any) {
//    KcAssociationManager.shared.removeAllObjects(object)
//    
//    kc_objc_removeAssociatedObjects(object)
//}
