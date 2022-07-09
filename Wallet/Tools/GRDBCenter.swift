//
//  GRDBCenter.swift
//  Wallet
//
//  Created by 龙培 on 2022/7/5.
//

import UIKit
//import GRDB
class GRDBCenter: NSObject {
    static let shared = GRDBCenter()
    
    var curDatabaseVersion = 0
    var grdbPool: DatabasePool?
    var databaseName = ""

    // MARK: - 基础配置
    func createPool() {
        // 如果存在数据池，而且是同一个用户，不用重新构建数据连接池
        if self.grdbPool != nil {
            return
        }

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL = URL(fileURLWithPath: documentsPath)
        databaseName = String(format: "public_grdb_1_sqlite")
        let sqliteFileURL = documentsURL.appendingPathComponent(databaseName)
        print("Path:>>>>>>>>>>>>>>>>>>> \(sqliteFileURL)")
        do {
            self.grdbPool = try DatabasePool(path: sqliteFileURL.absoluteString)
        } catch let errorInfo as DatabaseError {
            print(errorInfo.message)
        } catch {
            let error = DatabaseError.errorDomain
            print(error)
        }
    }
    // MARK: - 检查更新
    func checkAndUpdateDatabase() {
        var localInfo: [String: String] = UserDefaults.standard.value(forKey: "LocalGRDBVersionInfo") as? [String: String] ?? [:]
        var localVersion: String = localInfo["CatCatLocalVersion"] ?? ""
        if localVersion.isEmpty == true {
            // 本地没有数据库，版本为0
            localInfo["CatCatLocalVersion"] = "0"
            UserDefaults.standard.setValue(localInfo, forKey: "LocalGRDBVersionInfo")
            localVersion = "0"
        }

        let version = NSString(string: localVersion).intValue
        if version == self.curDatabaseVersion {
            return
        }

        if self.grdbPool == nil {
            return
        }

        let curVersion = String(format: "%d", self.curDatabaseVersion)

        var migrator = DatabaseMigrator()

        if version < 1 {
            /*
            migrator.registerMigration("1") { db in
                try db.alter(table: "CustomTable", body: { customT in
                    customT.add(column: "isLatest", .boolean).defaults(to: false)
                })
            }*/
        }


        do {
            try migrator.migrate(self.grdbPool!)
            localInfo["CatCatLocalVersion"] = curVersion
            UserDefaults.standard.setValue(localInfo, forKey: "LocalGRDBVersionInfo")
            print("完成数据升级")
        } catch let errorInfo as DatabaseError {
            print(errorInfo.message)
        } catch {
            print("数据库升级失败")
        }
    }
    
    func checkAndCreateCatTable() {
        if self.grdbPool == nil {
            return
        }

        do {
            try self.grdbPool!.write({ db in
                if try db.tableExists("MongoCat") {
                    Log("MongoCat 表已存在")
                    return
                }

                do {
                    try db.create(table: "MongoCat", body: { t in
                        t.autoIncrementedPrimaryKey("customID", onConflict: .replace)
                        t.column("dateInfo", .integer)
                        t.column("codeStr", .text)
                        t.column("nameString", .text)
                        t.column("dayEnd", .text)
                        t.column("dayHigh", .text)
                        t.column("dayLow", .text)
                        t.column("dayStart", .text)
                        t.column("beforeDayEnd", .text)
                        t.column("upOrDownValue", .text)
                        t.column("upOrDownRate", .text)
                        t.column("changeRate", .text)
                        t.column("dealNumber", .text)
                        t.column("dealMoney", .text)
                        t.column("totalValue", .text)
                        t.column("flowValue", .text)
                        t.column("dealPenCount", .text)
                    })
                } catch let errorInfo as DatabaseError {
                    Log(errorInfo.message)
                }

                // 给name添加索引
                let res = try db.indexes(on: "MongoCat").filter({ $0.name == "code_index" }).isEmpty
                if res == true {
                    try db.create(index: "code_index", on: "MongoCat", columns: ["codeStr"])
                }
                
                let dateIndex = try db.indexes(on: "MongoCat").filter({ $0.name == "date_index" }).isEmpty
                if dateIndex == true {
                    try db.create(index: "date_index", on: "MongoCat", columns: ["dateInfo"])
                }

            })
        } catch {
            let error = DatabaseError.errorDomain
            Log(error)
        }

    }
    
    // MARK: - 增
    func insertCatModelsToDatabase(models: [MongoItem]) {
        if self.grdbPool == nil {
            return
        }

        do {
            try self.grdbPool?.write({ db in

                for model in models {
                    let sqlString = String(format: "select * from MongoCat where codeStr='%@' and dateInfo='%@'", model.codeStr, model.dateStr)
                    let curData = try MongoCatRecord.fetchAll(db, sql: sqlString )
                    var contain = false
                    if curData.count > 0 {
                        contain = true
                    }
                    let dateValue = NSString(format: "%@", model.dateStr).integerValue
                    let table = MongoCatRecord.init(dateInfo: dateValue,
                                                    codeStr: model.codeStr,
                                                    nameString: model.nameString,
                                                    dayEnd: model.dayEnd,
                                                    dayHigh: model.dayHigh,
                                                    dayLow: model.dayLow,
                                                    dayStart: model.dayStart,
                                                    beforeDayEnd: model.beforeDayEnd,
                                                    upOrDownValue: model.upOrDownValue,
                                                    upOrDownRate: model.upOrDownRate,
                                                    changeRate: model.changeRate,
                                                    dealNumber: model.dealNumber,
                                                    dealMoney: model.dealMoney,
                                                    totalValue: model.totalValue,
                                                    flowValue: model.flowValue,
                                                    dealPenCount: model.dealPenCount)
                    do {
                        if contain == false {
                            try table.insert(db)
                        }
                    } catch let errorInfo as DatabaseError {
                        Log(errorInfo.message)
                        Log(errorInfo.sql)
                    } catch {
                        let error = DatabaseError.errorDomain
                        Log(error)
                    }
                }
            })
        } catch let errorInfo as DatabaseError {
            Log(errorInfo.message)
        } catch {
            let error = DatabaseError.errorDomain
            Log(error)
        }
    }
    
    // MARK: - 删
    func removeAllCat() {
        if self.grdbPool == nil {
            return
        }
        do {
            try _ = self.grdbPool!.write({ db in
                try MongoCatRecord.deleteAll(db)
            })
        } catch {
            Log("delete error")
        }
    }
    
    // MARK: - 查
    func fetchAllCatRecords(catCode: String, fromDate: String, endDate: String) -> ([MongoCatRecord]?) {
        if self.grdbPool == nil {
            return []
        }
        let fromValue = NSString(format: "%@", fromDate).integerValue
        let endValue = NSString(format: "%@", endDate).integerValue
        let sqlStr = String(format: "SELECT * from MongoCat where codeStr='%@' and dateInfo>%ld and dateInfo<%ld order by dateInfo desc", catCode, fromValue, endValue)
//        let sqlStr = String(format: "SELECT * from MongoCat where codeStr='%@' order by dateInfo desc", catCode, fromDate, endDate)

        let originData = self.readNodeDataWithCondition(sqlString: sqlStr)
        return originData
    }
    
    func readNodeDataWithCondition(sqlString: String) -> ([MongoCatRecord]?) {
        if self.grdbPool == nil {
            return nil
        }

        do {
            let resultArr: [MongoCatRecord] = try self.grdbPool!.read({ db in
                if sqlString.isEmpty == true {
                    return try MongoCatRecord.fetchAll(db)
                } else {
                    return try MongoCatRecord.fetchAll(db, sql: sqlString)
                }
            })
            return resultArr
        } catch let errorInfo as DatabaseError {
            Log(errorInfo.message)
        } catch {
            let error = DatabaseError.errorDomain
            Log(error)
        }

        return nil
    }



}



// GRDB
class MongoCatRecord: Record {
    var dateInfo: Int = 666
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

    init(dateInfo: Int,
         codeStr: String,
         nameString: String,
         dayEnd: String,
         dayHigh: String,
         dayLow: String,
         dayStart: String,
         beforeDayEnd: String,
         upOrDownValue: String,
         upOrDownRate: String,
         changeRate: String,
         dealNumber: String,
         dealMoney: String,
         totalValue: String,
         flowValue: String,
         dealPenCount: String) {
        self.dateInfo = dateInfo
        self.codeStr = codeStr
        self.nameString = nameString
        self.dayEnd = dayEnd
        self.dayHigh = dayHigh
        self.dayLow = dayLow
        self.dayStart = dayStart
        self.beforeDayEnd = beforeDayEnd
        self.upOrDownValue = upOrDownValue
        self.upOrDownRate = upOrDownRate
        self.changeRate = changeRate
        self.dealNumber = dealNumber
        self.dealMoney = dealMoney
        self.totalValue = totalValue
        self.flowValue = flowValue
        self.dealPenCount = dealPenCount
        super.init()
    }

    override class var databaseTableName: String { "MongoCat" }

    enum columns: String, ColumnExpression {
        case dateInfo, codeStr, nameString, dayEnd, dayHigh, dayLow, dayStart, beforeDayEnd, upOrDownValue, upOrDownRate, changeRate, dealNumber, dealMoney, totalValue, flowValue, dealPenCount
    }
    required init(row: Row) {
        dateInfo = row[columns.dateInfo]
        codeStr = row[columns.codeStr]
        nameString = row[columns.nameString]
        dayEnd = row[columns.dayEnd]
        dayHigh = row[columns.dayHigh]
        dayLow = row[columns.dayLow]
        dayStart = row[columns.dayStart]
        beforeDayEnd = row[columns.beforeDayEnd]
        upOrDownValue = row[columns.upOrDownValue]
        upOrDownRate = row[columns.upOrDownRate]
        changeRate = row[columns.changeRate]
        dealNumber = row[columns.dealNumber]
        dealMoney = row[columns.dealMoney]
        totalValue = row[columns.totalValue]
        flowValue = row[columns.flowValue]
        dealPenCount = row[columns.dealPenCount]
        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[columns.dateInfo] = dateInfo
        container[columns.codeStr] = codeStr
        container[columns.nameString] = nameString
        container[columns.dayEnd] = dayEnd
        container[columns.dayHigh] = dayHigh
        container[columns.dayLow] = dayLow
        container[columns.dayStart] = dayStart
        container[columns.beforeDayEnd] = beforeDayEnd
        container[columns.upOrDownValue] = upOrDownValue
        container[columns.upOrDownRate] = upOrDownRate
        container[columns.changeRate] = changeRate
        container[columns.dealNumber] = dealNumber
        container[columns.dealMoney] = dealMoney
        container[columns.totalValue] = totalValue
        container[columns.flowValue] = flowValue
        container[columns.dealPenCount] = dealPenCount
    }
    override func didInsert(with rowID: Int64, for column: String?) {
//        id = rowID
    }
}
