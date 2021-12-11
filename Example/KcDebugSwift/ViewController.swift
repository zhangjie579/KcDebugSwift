//
//  ViewController.swift
//  KcDebugSwift
//
//  Created by 张杰 on 04/19/2021.
//  Copyright (c) 2021 张杰. All rights reserved.
//

import UIKit
import KcDebugSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(btn)
        
    }
    
    private var btn = UIButton()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        navigationController?.pushViewController(AViewController(), animated: true)
    }

}
