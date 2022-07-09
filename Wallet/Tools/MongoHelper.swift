//
//  MongoHelper.swift
//  Wallet
//
//  Created by 龙培 on 2022/7/4.
//

import UIKit

class MongoHelper: NSObject {
    typealias MongoBlock = () -> ()
    var saveBlock: MongoBlock?
    static let shared = MongoHelper()
    private override init() {
        super.init()
    }
    
    func getAndReadCSVFile(code: String,
                           from: String? = "",
                           to: String? = "",
                           days: Int? = 20,
                           completion: @escaping MongoBlock) {
       
        saveBlock = completion
        let res = createDateInfo(from: from, to: to, days: days)
        let fromDate = res.start
        let endDate = res.end
        let url = URL(string: String(format: "https://quotes.money.163.com/service/chddata.html?code=%@&start=%@&end=%@.csv", code, fromDate, endDate))
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0;
        session.configuration.timeoutIntervalForRequest = 30.0
        let task = session.downloadTask(with: request) {[weak self] (localUrl, response, error) in
            guard let self = self else {return}
           if let tempLocalUrl = localUrl, error == nil {
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                print("Successfully downloaded. Status code: \(statusCode)")
            }
               
            let downloadedData = try? Data(contentsOf: tempLocalUrl)
            let string = self.transferFromData(gbkData: downloadedData!)
            let mongoArray = self.praseFromOriginString(contentString: string)
            DBDataManager.shared.saveOriginCats(originDataArray: mongoArray)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.saveBlock?()
            }
           } else {
               print("Error" )
           }
            
        }
       
        task.resume()
    }
    
    

    func createDateInfo(from: String? = "",
                        to: String? = "",
                        days: Int? = 45) -> (start: String, end: String) {
      
        
        var fromString = from ?? ""
        var toString = to ?? ""
        let dayOffset: Int = days ?? 45
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        if fromString.isEmpty {
            
            let fromDate = Date.init(timeIntervalSinceNow: -(Double(dayOffset * 86400)))
            fromString = formatter.string(from: fromDate)
        }
        
        if toString.isEmpty {
            let fromDate: Date = formatter.date(from: fromString) ?? Date.init(timeIntervalSinceNow: -(Double(dayOffset * 86400)))
            let endDate = Date.init(timeInterval: (Double(dayOffset * 86400)), since: fromDate)
            
            toString = formatter.string(from: endDate)
        }
        
        return (fromString, toString)
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

            for index in 1..<array.count {
                let item = array[index]
                let dataArray = item.components(separatedBy: ",")
                if dataArray.count == 16 {
                    let model = MongoItem()
                    var dateStr = dataArray[0]
                    if dateStr.contains("-") {
                        dateStr = dateStr.replacingOccurrences(of: "-", with: "")
                    }
                    model.dateStr = dateStr
                    
                    var codeStr = dataArray[1]
                    if codeStr.contains("\'") {
                       codeStr = codeStr.replacingOccurrences(of: "\'", with: "")
                    }
                    model.codeStr = codeStr
                    
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
