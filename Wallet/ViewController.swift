//
//  ViewController.swift
//  Wallet
//
//  Created by 龙培 on 2022/6/19.
//

import UIKit
import Alamofire
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .gray
        MongoHelper.shared.getAndReadCSVFile(code: "1000983")
    }
        

    

    

}

