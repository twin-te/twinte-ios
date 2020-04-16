//
//  AppSettingsViewController.swift
//  Twinte
//
//  Created by tako on 2020/03/31.
//  Copyright © 2020 tako. All rights reserved.
//

import UIKit

// 授業振替情報を格納
struct substitute: Codable {
    let date: String
    let change_to: String
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
        
        scheduleAllNotification()
        // Do any additional setup after loading the view.
        
        if #available(iOS 13.0, *) {
            let coloredAppearance = UINavigationBarAppearance()
            coloredAppearance.configureWithOpaqueBackground()
            coloredAppearance.backgroundColor = UIColor(red: 0, green: 192/255, blue: 192/255, alpha: 1)
            coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = coloredAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        }
        
        let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
        
        // ユーザーが通知ONOFFを設定していない場合はOFFに
        if userDefaults?.object(forKey: "notificationSwitch") == nil{
            notificationSwitchObject.isOn = false
        }else{
            notificationSwitchObject.isOn = userDefaults!.bool(forKey: "notificationSwitch")
        }
        
        if !notificationSwitchObject.isOn{
            notificationLabel1.isEnabled=false
            notificationDateLabel.isEnabled=false
            changeDateButton.isEnabled=false
        }
        
        // ユーザーが設定した時刻がない場合は初期設定の時間を反映
        if userDefaults?.object(forKey: "notificationHour") == nil{
            userDefaults?.set(getday(format:"HH",modifiedDate: todayInitialTime()),forKey: "notificationHour")
            userDefaults?.set(getday(format:"mm",modifiedDate: todayInitialTime()),forKey: "notificationMinute")
            userDefaults?.synchronize()
        }else{
            notificationDateLabel.text = (userDefaults?.string(forKey: "notificationHour"))!+":"+(userDefaults?.string(forKey: "notificationMinute"))!
        }
        datePicker.date = todayInitialTime()
    }
    
    @IBAction func changeDate(_ sender: Any) {
        datePicker.isHidden = false
        confirmDateButton.isHidden = false
        
        ///
        /// デバッグ用
        ///
        /*
         let center = UNUserNotificationCenter.current()
         center.getPendingNotificationRequests { requests in
         print(requests.count)
         
         for element in requests {
         print(element)
         }
         
         }
         */
        /// ここまで
    }
    
    @IBAction func confirmDate(_ sender: Any) {
        datePicker.isHidden = true
        confirmDateButton.isHidden = true
        notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
        // 設定時刻をUserDefaultsに保存
        // UserDefaults のインスタンス
        let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
        // AppGroupのUserDefaultsに通知時間を保存
        userDefaults?.set(getday(format:"HH",modifiedDate: datePicker.date),forKey: "notificationHour")
        userDefaults?.set(getday(format:"mm",modifiedDate: datePicker.date),forKey: "notificationMinute")
        userDefaults?.synchronize()
        
        scheduleAllNotification()
    }
    
    @IBAction func notificationSwitch(_ sender: UISwitch) {
        // UserDefaults のインスタンス
        let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
        // AppGroupのUserDefaultsに通知するかどうか保存
        userDefaults?.set(sender.isOn,forKey: "notificationSwitch")
        
        if sender.isOn {
            notificationLabel1.isEnabled=true
            notificationDateLabel.isEnabled=true
            changeDateButton.isEnabled=true
            notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
            scheduleAllNotification()
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
    
    /// 全ての通知をスケジューリング
    func scheduleAllNotification(){
        // 現在登録されている全ての通知を消去
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        schoolCalender { (substitutes) in
            // UserDefaults のインスタンス
            let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
            
            for element in substitutes{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.locale = Locale(identifier: "ja")
                let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: dateFormatter.date(from: element.date)!)
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate!)
                dateComponents.hour = userDefaults?.integer(forKey: "notificationHour")
                dateComponents.minute = userDefaults?.integer(forKey: "notificationMinute")
                // 過去のものに関してはスケジュールしない
                if(Date() < Calendar.current.date(from: dateComponents)!){
                    self.createNotification(body: "明日は\(element.change_to)曜日日程です。ウィジェットから詳細をご確認ください。", notificationTime: dateComponents)
                }
            }
        }
        
    }
    
    /// 通知をしてくれる関数
    /// - Parameters:
    ///   - body: 通知文の本文
    ///   - notificationTime: 通知したい時刻
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
    func schoolCalender(completion: @escaping ([substitute]) -> Void){
        let requestUrl = "https://api.twinte.net/v1/school-calender/substitutes/list?year="+getday(format:"yyyy",modifiedDate: Date())
        
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
