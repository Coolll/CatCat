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
        requestData()
    }
    
    func requestData() {
        let header = HTTPHeaders(["Cookie" : "_9755xjdesxxd_=32; gdxidpyhxdE=1ns%2BZclnPe6U9%5Cs5WsgmMQ%2B9xViyQeu1Cc66%2FI4oLk%2FlUyzdyBqOtXRRsa%5C%2FxJPSlbMIVa0Y4Qy%5CnKyrIVX8SIssYn%5CDT9lao%2Fj%2FsM4Rl%5CK%5CdgbZmuhoEY1W8RCjZI48GCmb6gdVo2HmPk6%2FnaGNokVgUxgP8PSwH33tbA3L5IAln5l4%3A1591150324013",
                                  "Accept-Encoding": "gzip, deflate, br",
                                  "Accept": "*/*",
                                  "User-Agent": "tztMobileApp_zxsc2.0/4.01.011 (iPhone; iOS 14.3; Scale/3.00)",
                                  "Accept-Language": "en-CN;q=1, es-CN;q=0.9, zh-Hans-CN;q=0.8"])
        AF.request("https://kong.citics.com/xtgjson/stockAtt/SZSE/1/000983.json", method: .get, headers: header).responseData { (data) in
            print(data)
        }
        
        AF.request("https://kong.citics.com/xtgjson/stockAtt/SZSE/2/000983.json", method: .get, headers: header).responseData { (data) in
            let result = data.result
            print(data)

            
        }
        
        let downloadUrl: String = "https://kong.citics.com/xtgjson/stockAtt/SZSE/2/000983.json"
        let destinationPath: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
            let fileURL = documentsURL.appendingPathComponent("000983.json")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download("https://kong.citics.com/xtgjson/stockAtt/SZSE/2/000983.json", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header, interceptor: nil, to: destinationPath).responseData { (data) in
            print(data)

        }
        
//        AF.download("https://kong.citics.com/xtgjson/stockAtt/SZSE/2/000983.json", method: .get, parameters: nil, encoder: ParameterEncoder.self, headers: header, interceptor: nil, requestModifier: nil, to: fileURL)
//
//        Alamofire.download(dpUrl!, method: .get, parameters: parameters, encoding: JSONEncoding.default, to: destination)
//            .downloadProgress(queue: DispatchQueue.global(qos: .utility)) { progress in
//                print("Progress: \(progress.fractionCompleted)")
//            }
//            .responseJSON { response in
//                if let statusCode = response.response?.statusCode, statusCode == 200 {
//                    let pdfUrl = URL(fileURLWithPath: self.destinationURLForFile.path)
//                    let requestObj = NSURLRequest(url: pdfUrl as URL)
//                    self.webPreview?.loadRequest(requestObj as URLRequest)
//                }
//                return
//            }


    }
    
    

    

}

