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
//        MongoHelper.shared.getAndReadCSVFile(code: "1000983")
//        MongoHelper.shared.getAndReadCSVFile(code: "1000983", from: "20220601", to: "20220708", days: nil) {
           
            let result = DBDataManager.shared.fetchMongoItems(code: "000983", from: "20220601", end: "20220708")
            print(result)
//        }
    }
        

    

    

}

