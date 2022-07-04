//
//  MongoHelper.swift
//  Wallet
//
//  Created by 龙培 on 2022/7/4.
//

import UIKit

class MongoHelper: NSObject {
    static let shared = MongoHelper()
    private override init() {
        super.init()
    }
    
    func getAndReadCSVFile(code: String,
                           from: String? = "",
                           to: String? = "",
                           days: Int? = 20) {
       
       let url = URL(string: String(format: "https://quotes.money.163.com/service/chddata.html?code=%@&start=20200720&end=20220629.csv", code))
       let session = URLSession.shared
       var request = URLRequest(url: url!)
       
       request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
       request.timeoutInterval = 60.0;
       session.configuration.timeoutIntervalForRequest = 30.0
       let task = session.downloadTask(with: request) { (localUrl, response, error) in
           if let tempLocalUrl = localUrl, error == nil {
               if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                   print("Successfully downloaded. Status code: \(statusCode)")
               }
               
               let downloadedData = try? Data(contentsOf: tempLocalUrl)
               let string = self.transferFromData(gbkData: downloadedData!)
               self.praseFromOriginString(contentString: string)
               
           } else {
               print("Error" )
           }
       }
       
       task.resume()
   }
    

    func transferFromData(gbkData: Data) -> String {
        //获取GBK编码, 使用GB18030是因为它向下兼容GBK
        let cfEncoding = CFStringEncodings.GB_18030_2000
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        //从GBK编码的Data里初始化NSString, 返回的NSString是UTF-16编码
        if let str = NSString(data: gbkData, encoding: encoding) {
            let string = str as String
            return string
        } else {
            return ""
        }
    }
   
    func praseFromOriginString(contentString: String) -> [MongoItem] {
        var mongos: [MongoItem] = []

        if contentString.contains("\r\n") {
            let array = contentString.components(separatedBy: "\r\n")

            for item in array {
                let dataArray = item.components(separatedBy: ",")
                if dataArray.count == 16 {
                    let model = MongoItem()
                    model.dateStr = dataArray[0]
                    model.codeStr = dataArray[1]
                    model.nameString = dataArray[2]
                    model.dayEnd = dataArray[3]
                    model.dayHigh = dataArray[4]
                    model.dayLow = dataArray[5]
                    model.dayStart = dataArray[6]
                    model.beforeDayEnd = dataArray[7]
                    model.upOrDownValue = dataArray[8]
                    model.upOrDownRate = dataArray[9]
                    model.changeRate = dataArray[10]
                    model.dealNumber = dataArray[11]
                    model.dealMoney = dataArray[12]
                    model.totalValue = dataArray[13]
                    model.flowValue = dataArray[14]
                    model.dealPenCount = dataArray[15]
                    mongos.append(model)
                } else {
                    print("data出错了")
                }
            }
        }
        return mongos
    }
}


class MongoItem: NSObject {
    var dateStr: String = ""
    var codeStr: String = ""
    var nameString: String = ""
    var dayEnd: String = ""
    var dayHigh: String = ""
    var dayLow: String = ""
    var dayStart: String = ""
    var beforeDayEnd: String = ""
    var upOrDownValue: String = ""
    var upOrDownRate: String = ""
    var changeRate: String = ""
    var dealNumber: String = ""
    var dealMoney: String = ""
    var totalValue: String = ""
    var flowValue: String = ""
    var dealPenCount: String = ""
    
}
