//
//  ViewController.swift
//  KcDebugSwift
//
//  Created by 张杰 on 04/19/2021.
//  Copyright (c) 2021 张杰. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.hasAmbiguousLayout
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.tag = Int.random(in: 0...100)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
