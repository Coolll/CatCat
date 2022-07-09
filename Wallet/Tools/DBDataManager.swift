//
//  DBDataManager.swift
//  Wallet
//
//  Created by 龙培 on 2022/7/9.
//

import UIKit

class DBDataManager: NSObject {
    static let shared = DBDataManager()
    override init() {
        super.init()
        self.checkDatabase()
    }

    func checkDatabase() {
        GRDBCenter.shared.createPool()
        GRDBCenter.shared.checkAndCreateCatTable()
        GRDBCenter.shared.checkAndUpdateDatabase()
    }
    
    // 储存数据
    func saveOriginCats(originDataArray: [MongoItem]) {
        if originDataArray.isEmpty {
            return
        }
        self.checkDatabase()
        let center = GRDBCenter.shared
        center.insertCatModelsToDatabase(models: originDataArray)
    }
    
    func fetchMongoItems(code: String, from: String, end: String? = "") -> [MongoItem] {
        var endString = ""
        if end != nil {
            endString = end ?? ""
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            endString = formatter.string(from: Date())
        }
        
        GRDBCenter.shared.createPool()
        let originData = GRDBCenter.shared.fetchAllCatRecords(catCode: code, fromDate: from, endDate: endString)
        return transferCatRecordToMongoItem(cat: originData)
    }
    
    func transferCatRecordToMongoItem(cat: [MongoCatRecord]?) -> [MongoItem] {
        if let catArray = cat {
            var mongoArray: [MongoItem] = []
            for item in catArray {
                let mongoItem = MongoItem()
                mongoItem.dateStr = String(format: "%ld", item.dateInfo)
                mongoItem.codeStr = item.codeStr
                mongoItem.nameString = item.nameString
                mongoItem.dayEnd = item.dayEnd
                mongoItem.dayHigh = item.dayHigh
                mongoItem.dayLow = item.dayLow
                mongoItem.dayStart = item.dayStart
                mongoItem.beforeDayEnd = item.beforeDayEnd
                mongoItem.upOrDownValue = item.upOrDownValue
                mongoItem.upOrDownRate = item.upOrDownRate
                mongoItem.changeRate = item.changeRate
                mongoItem.dealNumber = item.dealNumber
                mongoItem.dealMoney = item.dealMoney
                mongoItem.totalValue = item.totalValue
                mongoItem.flowValue = item.flowValue
                mongoItem.dealPenCount = item.dealPenCount
                mongoArray.append(mongoItem)
            }
            return mongoArray
        }
        return []
    }

}
