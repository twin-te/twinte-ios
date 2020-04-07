//
//  AppSettingsViewController.swift
//  Twinte
//
//  Created by tako on 2020/03/31.
//  Copyright © 2020 tako. All rights reserved.
//

import UIKit

// イベント情報格納
struct OutputSchoolCalender: Codable {
    let module:String?
    let event:event?
    let substituteDay:substituteDay?
    
    struct event: Codable{
        let description:String
        let event_type:String
    }
    
    struct substituteDay: Codable{
        let change_to:String
    }
}

class AppSettingsViewController: UIViewController {
    
    
    @IBOutlet weak var notificationLabel1: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var notificationDateLabel: UILabel!
    @IBOutlet weak var changeDateButton: UIButton!
    @IBOutlet weak var confirmDateButton: UIButton!
    @IBOutlet weak var notificationSwitchObject: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        notificationSwitchObject.isOn = false
        // ユーザーが設定した時刻がない場合は初期設定の時間を反映
        datePicker.date = todayInitialTime()
        notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
    }
    
    @IBAction func changeDate(_ sender: Any) {
        datePicker.isHidden = false
        confirmDateButton.isHidden = false
        
        ///
        /// デバッグ用
        ///
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            print(requests.count)
            
            for element in requests {
                print(element)
            }
        }
        /// ここまで
    }
    
    @IBAction func confirmDate(_ sender: Any) {
        datePicker.isHidden = true
        confirmDateButton.isHidden = true
        notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
        createFirstnotification()
    }
    
    @IBAction func notificationSwitch(_ sender: UISwitch) {
        if sender.isOn {
            notificationLabel1.isEnabled=true
            notificationDateLabel.isEnabled=true
            changeDateButton.isEnabled=true
            notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
            createFirstnotification()
            periodicExecution()
            
        }else{
            notificationLabel1.isEnabled=false
            notificationDateLabel.isEnabled=false
            changeDateButton.isEnabled=false
            datePicker.isHidden = true
            confirmDateButton.isHidden = true
            // 現在登録されている全ての通知を消去
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    /// 初回の通知の登録処理する関数
    func createFirstnotification(){
        
        // 現在登録されている全ての通知を消去
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        print("現在時刻:\(Date())")
        print("通知時刻:\(datePicker.date)")
        
        // 設定された時間を過ぎているか確認
        if Date() < datePicker.date{
            print("通知時刻は未来")
            // セマフォを0で初期化
            let semaphore = DispatchSemaphore(value: 0)
            // 明日の予定を取得する
            self.schoolCalender(date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,completion: {
                semaphore.signal()
            })
            // セマフォをデクリメント（-1）、ただしセマフォが0の場合はsignal()の実行を待つ
            semaphore.wait()
            // 今日の指定時間(datePickerの値)に通知を予約
            let year = Int(self.getday(format:"yyyy",modifiedDate: self.datePicker.date))!
            let month = Int(self.getday(format:"MM",modifiedDate: self.datePicker.date))!
            let day = Int(self.getday(format:"dd",modifiedDate: self.datePicker.date))!
            let hour = Int(self.getday(format:"HH",modifiedDate: self.datePicker.date))!
            let minute = Int(self.getday(format:"mm",modifiedDate: self.datePicker.date))!
            let date = DateComponents(year:year,month:month,day:day,hour:hour, minute:minute)
            createNotification(body:"明日は\(self.g_Calender)です。",notificationTime: date)
        }else{
            print("通知時刻は過去")
        }
    }
    
    /// 定期実行する関数
    func periodicExecution(){
        // 通知がOFFの場合は終了
        if !notificationSwitchObject.isOn {
            return
        }
        
        // 明日の通知がスケジューリングされているか
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            // 明日の日付を格納する変数
            let tommorowString:String = self.getday(format:"yyyy-MM-dd",modifiedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
            // identifierに明日のyyyy-MM-ddと一致するものが格納されていた場合終了
            for element in requests {
                if(element.identifier.contains(tommorowString)){
                    return
                }
            }
            
            // なかった場合
            // セマフォを0で初期化
            let semaphore = DispatchSemaphore(value: 0)
            // 明後日の予定を取得する
            self.schoolCalender(date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,completion: {
                semaphore.signal()
            })
            // セマフォをデクリメント（-1）、ただしセマフォが0の場合はsignal()の実行を待つ
            semaphore.wait()
            // 明日の日付を格納
            let tommorowDate:Date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            // 明日の指定時間(datePickerの値)に通知を予約
            let year = Int(self.getday(format:"yyyy",modifiedDate: tommorowDate))!
            let month = Int(self.getday(format:"MM",modifiedDate: tommorowDate))!
            let day = Int(self.getday(format:"dd",modifiedDate: tommorowDate))!
            // 指定された時分
            let hour = 21
            let minute = 0
            let date = DateComponents(year:year,month:month,day:day,hour:hour, minute:minute)
            self.createNotification(body:"明日は\(self.g_Calender)です。",notificationTime:date)
        }
    }
    
    
    // 通知に渡す予定
    var g_Calender:String = "初期設定のまま"
    
    /// 通知をしてくれる関数
    /// - Parameters:
    ///   - body: 通知文の本文
    ///   - notificationTime: 通知したい時刻(UTC)
    func createNotification(body:String,notificationTime:DateComponents){
        // 通知の登録
        //プッシュ通知のインスタンス
        let notification = UNMutableNotificationContent()
        //通知のタイトル
        notification.title = "特別日程のお知らせ"
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
    
    /// 今日の設定上の初期時間を返す関数
    /// - Returns: Date形式で返す
    func todayInitialTime()->Date{
        let today = Date()
        let year = Int(self.getday(format:"yyyy",modifiedDate: today))!
        let month = Int(self.getday(format:"MM",modifiedDate: today))!
        let day = Int(self.getday(format:"dd",modifiedDate: today))!
        // 指定された時分
        let hour = 21
        let minute = 0
        let components = DateComponents(year:year,month:month,day:day,hour:hour, minute:minute)
        return Calendar.current.date(from: components)!
    }
    
    /// イベント情報の取得
    /// - Parameters:
    ///   - date: 取得したいイベントの日付をDate形式で渡す
    ///   - completion: 場合に応じてsemaphore.signal()を実行するとよい
    func schoolCalender(date:Date,completion: @escaping () -> Void){
        let requestUrl = "https://api.twinte.net/v1/school-calender/"+getday(format:"yyyy-MM-dd",modifiedDate: date)
        
        // URL生成
        guard let url = URL(string: requestUrl) else {
            // URL生成失敗
            return
        }
        
        // リクエスト生成
        let request = URLRequest(url: url)
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
                let resultSet = try JSONDecoder().decode(OutputSchoolCalender.self, from: data)
                // 優先度：substituteDay > event > module
                if let substituteDay = resultSet.substituteDay{
                    self.g_Calender = "\(substituteDay.change_to)曜日課"
                } else if let event = resultSet.event{
                    self.g_Calender = "\(event.event_type) \(event.description)"
                } else if let module = resultSet.module{
                    self.g_Calender = module
                }else{
                    print("")
                }
            } catch let error {
                print("## error: \(error)")
            }
            completion()
        }
        // 通信開始
        task.resume()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
