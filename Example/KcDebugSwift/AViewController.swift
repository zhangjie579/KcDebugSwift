//
//  AViewController.swift
//  KcDebugSwift_Example
//
//  Created by 张杰 on 2021/12/7.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import KcDebugSwift

@objc
class Base: NSObject {
    var params: [String: Any?]? = [:]
}

class Person: Base {
//    var a1: [String] = ["a", "b"]
//    var a2: Set<Int> = [1, 2]
    
//    var a3 = ["a": 1, "b": 2]
    
//    var a4: (String, Int) = ("haha", 12)
//    var a5: (AnyObject?, Int)?
    
//    var a6 = [AnyObject?]()
    
//    var a7 = [String : AnyObject]()
    
//    var a8: (() -> Void)?
    
    weak var delegate: AnyObject?
}

struct FunctionPairTy {
    var FunctionPtrTy: UnsafeMutableRawPointer
//    var RefCountedPtrTy: UnsafeMutablePointer<Box>
    var RefCountedPtrTy: UnsafeMutableRawPointer
//    var RefCountedPtrTy: BoxPointer
}

struct HeapObject {
    var Kind: UInt64
//    var refcount: UInt64
    var strongRetainCounts: Int32
    var weakRetainCounts: Int32
}

struct Box {
    var refCounted: HeapObject
    // 捕获的值...
//    var value: Int
    var point1: UnsafeMutablePointer<HeapObject>
    var point2: UnsafeMutablePointer<HeapObject>
}

class BoxPointer {
    var refCounted: HeapObject?
}

struct KcBlock {
//    var block: (() -> Void)?
    var block: Any
//    var block: () -> Void
}

//class KcBlock {
//    var block: (() -> Void)?
//
//    init(block: (() -> Void)?) {
//        self.block = block
//    }
//}

func makeIncrementer() -> () -> Int {
    var runningTotal = 12
    func incrementer() -> Int {
        runningTotal += 1
        return runningTotal
    }
    return incrementer
}

class AViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .lightGray
        
        test1()
        
        kc_finderCircularReference()
        
        print("")
    }
    
    func test1() {
        var age = 23
        
        person.delegate = self
//        person.a8 = { [weak self] in
//            print(self?.view)
//
//        }
        
        
//        person.a8 = { [weak self] in
////            age += 1
////            print(age, self.view)
//            print(self)
//        }
        
        print(self)
        
        
        
        var strongSelf = self
        var printAge = {
//            let temp = age
            age += 1
            print(age, self.view)
        }
        
        var b1 = KcBlock(block: printAge)

        var f1 = withUnsafeMutablePointer(to: &b1) { pointer in
            return UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: FunctionPairTy.self).pointee
        }

//        let t1: Any? = b1.block
//        if let t2 = t1 {
//            let kind = Kind.init(type: type(of: t2))
//            print(kind)
//        }


//        let kind = Kind.init(type: type(of: b1.block))

        print(f1)
        print(malloc_size(f1.RefCountedPtrTy), f1.RefCountedPtrTy)
//        let array = f1.RefCountedPtrTy.assumingMemoryBound(to: [Int].self).pointee

        var add = 0
        let cls = object_getClass(f1.RefCountedPtrTy)
        for i in 0..<(malloc_size(f1.RefCountedPtrTy) / 8) {
            let pointer = f1.RefCountedPtrTy.advanced(by: add).load(as: UnsafeRawPointer.self)
            
            if i == 0 {
                let value = unsafeBitCast(pointer, to: UnsafeMutablePointer<Int>.self)
                let kind = Kind(flag: value.pointee)
                print("")
            }
            
//            let value = pointer.load(as: UnsafeRawPointer.self)
//            print("0x", String.init(array[i], radix: 16))
//            let mirror = Mirror(reflecting: pointer.customMirror)
            print(pointer, malloc_size(pointer))

            add += 8
        }
        
        print("")
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        
        if parent == nil {
            let finder = CircleCycleFinder.init(reflecting: self)
            finder.collection()
        }
    }
    
    deinit {
        print("AViewController deinit")
    }

    var person = Person()
}
