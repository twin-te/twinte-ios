//
//  ScheduleNotification.swift
//  Twinte
//
//  Created by tako on 2021/03/23.
//  Copyright © 2021 tako. All rights reserved.
//
//  通知関連の機能を集めたクラス
import UIKit

// 授業振替情報を格納
struct substitute: Codable {
    let date: String
    let changeTo: String?
    let eventType: String
    let description: String
}

class ScheduleNotification {
    /// 全ての通知をスケジューリング
    func scheduleAllNotification(){
        ///
        /// デバッグ用
        ///
        
//                let center = UNUserNotificationCenter.current()
//                center.getPendingNotificationRequests { requests in
//                    print(requests.count)
//
//                    for element in requests {
//                        dump(element)
//                        print(element.content.body)
//                        print("****************************")
//                    }
//
//                }
        
        /// ここまで
        // 現在登録されている全ての通知を消去
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // UserDefaults のインスタンス
        let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
        if userDefaults?.object(forKey: "notificationSwitch") != nil{
            if userDefaults!.bool(forKey: "notificationSwitch"){
                
                schoolCalender { (substitutes) in
                    // UserDefaults のインスタンス
                    let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
                    
                    for element in substitutes{
                        // イベントタイプが授業変更の時のみ通知
                        if element.eventType == "SubstituteDay" || element.eventType == "Holiday"{
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            dateFormatter.locale = Locale(identifier: "ja")
                            let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: dateFormatter.date(from: String(element.date.prefix(10)))!) // 2021-04-06T00:00:00.000Zという文字列形式なので、先頭から10文字切り取って扱う
                            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate!)
                            dateComponents.hour = userDefaults?.integer(forKey: "notificationHour")
                            dateComponents.minute = userDefaults?.integer(forKey: "notificationMinute")
                            
                            //print(element)
                            if(Date() < Calendar(identifier: .gregorian).date(from: dateComponents)!){
                                if element.eventType == "SubstituteDay"{
                                    self.createNotification(title: "特別日程のお知らせ",body: "明日は\(self.convertDayEnglishToJapanese(en: element.changeTo!))日課です。ウィジェットから詳細をご確認ください。", notificationTime: dateComponents)
                                }else{
                                    self.createNotification(title: "臨時休講のお知らせ",body: "明日は\(element.description)のため休講です。詳細は学年暦をご覧ください。", notificationTime: dateComponents)
                                }
                            }
                        }
                    }
                }
            }}
        
    }
    
    /// 通知をしてくれる関数
    /// - Parameters:
    ///   - title: 通知のタイトル
    ///   - body: 通知文の本文
    ///   - notificationTime: 通知したい時刻
    func createNotification(title:String,body:String,notificationTime:DateComponents){
        // 通知の登録
        //プッシュ通知のインスタンス
        let notification = UNMutableNotificationContent()
        //通知のタイトル
        notification.title = title
        //通知の本文
        notification.body = body
        //通知の音
        notification.sound = UNNotificationSound.default
        //通知タイミングを指定
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: notificationTime, repeats: false)
        //DateComponentsからDate形式に変換
        let date = Calendar.current.date(from: notificationTime)!
        //通知のリクエスト
        let request = UNNotificationRequest(identifier: "\(getday(format: "yyyy-MM-dd", modifiedDate: date))", content: notification,trigger: trigger)
        //通知を実装
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
    /// 指定された日付を引数で指定されたフォーマットに変換
    /// - Parameters:
    ///   - format: 戻り値の日付のフォーマットを指定
    ///   - modifiedDate: 変換したい日付(UTC)
    /// - Returns: 日本標準時(GMT+9)で指定された形式で日付をStringで返す
    func getday(format:String,modifiedDate:Date) -> String{
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        formatter.dateFormat = format
        return formatter.string(from: modifiedDate)
    }
    
    func convertDayEnglishToJapanese(en:String)->String{
        switch en {
        case "Sun":
            return "日曜"
        case "Mon":
            return "月曜"
        case "Tue":
            return "火曜"
        case "Wed":
            return "水曜"
        case "Thu":
            return "木曜"
        case "Fri":
            return "金曜"
        case "Sat":
            return "土曜"
        default:
            return "特殊"
        }
    }
    
    /// イベント情報の取得
    /// - Parameters:
    ///   - completion: 場合に応じてsemaphore.signal()を実行するとよい
    func schoolCalender(completion: @escaping ([substitute]) -> Void){
        
        let calendar = Calendar(identifier: .gregorian)
        let date = Date()
        let thisMonth = calendar.component(.month, from: date)
        let schoolYear = thisMonth <= 3 ? String(calendar.component(.year, from:calendar.date(byAdding: .year, value: -1, to: date)!)) : String(calendar.component(.year, from: date))
        
        let requestUrl = "https://app.twinte.net/api/v3/school-calendar/events?year=\(schoolYear)"

        // URL生成
        guard let url = URL(string: requestUrl) else {
            // URL生成失敗
            return
        }
        
        // リクエスト生成
        var request = URLRequest(url: url)
        // Cookieをセット
        //UserDefaults のインスタンス
        let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
        if let stringCookie = userDefaults?.string(forKey: "stringCookie"){
            // UserDefaultsからCookieを取得
            request.setValue(stringCookie, forHTTPHeaderField: "Cookie")
        }
        // APIを殴る
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data:Data?,
                                                      response:URLResponse?, error:Error?) in
            // 通信完了後の処理
            // エラーチェック
            guard error == nil else {
                // エラー表示
                let alert = UIAlertController(title: "エラー",
                                              message: error?.localizedDescription,
                                              preferredStyle: UIAlertController.Style.alert)
                print(alert)
                return
            }
            
            // JSONで返却されたデータをパースして格納する
            guard let data = data else {
                // データなし
                return
            }
            
            do {
                // jsonのパース実施
                let resultSet = try JSONDecoder().decode([substitute].self, from: data)
                completion(resultSet)
            } catch let error {
                print("## error: \(error)")
                let resultSet = [substitute]()
                completion(resultSet)
            }
        }
        // 通信開始
        task.resume()
    }
    
}
