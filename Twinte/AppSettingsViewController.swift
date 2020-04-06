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
        notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
    }
    
    @IBAction func changeDate(_ sender: Any) {
        datePicker.isHidden = false
        confirmDateButton.isHidden = false
        
    }
    
    
    @IBAction func confirmDate(_ sender: Any) {
        datePicker.isHidden = true
        confirmDateButton.isHidden = true
        notificationDateLabel.text = getday(format:"HH:mm",modifiedDate: datePicker.date)
        print("現在時刻:\(Date())")
        print("通知時刻:\(datePicker.date)")
        if Date() < datePicker.date{
            print("通知時刻は未来")
            // セマフォを0で初期化
            let semaphore = DispatchSemaphore(value: 0)
            // 明日の予定を取得する
            self.schoolCalender(date: self.getday(format:"yyyy-MM-dd",modifiedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!),completion: {
                semaphore.signal()
            })
            // セマフォをデクリメント（-1）、ただしセマフォが0の場合はsignal()の実行を待つ
            semaphore.wait()
            // 今日の指定時間(datePickerの値)に通知を予約
            createNotification(body:"明日は\(self.g_Calender)です。",notificationTime:datePicker.date)
        }else{
            print("通知時刻は過去")
        }
    }
    
    @IBAction func notificationSwitch(_ sender: UISwitch) {
        if sender.isOn {
            notificationLabel1.isEnabled=true
            notificationDateLabel.isEnabled=true
            changeDateButton.isEnabled=true
            datePicker.date = Date()
            confirmDate((Any).self)
            
            print(Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
            print(getday(format:"yyyy-MM-dd HH:mm:ss",modifiedDate: Date()))
            print(getday(format:"yyyy-MM-dd HH:mm:ss",modifiedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!))
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
    
    
    
    // 通知に渡す予定
    var g_Calender:String = "初期設定のまま"
    
    /// 通知をしてくれる関数
    /// - Parameters:
    ///   - body: 通知文の本文
    ///   - notificationTime: 通知したい時刻(UTC)
    func createNotification(body:String,notificationTime:Date){
        // 通知の登録
        //プッシュ通知のインスタンス
        let notification = UNMutableNotificationContent()
        //通知のタイトル
        notification.title = "特別日程のお知らせ"
        //通知の本文
        notification.body = body
        //通知の音
        notification.sound = UNNotificationSound.default
        //通知タイミングを指定(今回は5秒ご)
        let hour = Int(getday(format:"HH",modifiedDate: notificationTime))!
        let minute = Int(getday(format:"mm",modifiedDate: notificationTime))!
        print("\(hour)時\(minute)分")
        let date = DateComponents(hour:hour, minute:minute)
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: date, repeats: false)
        //通知のリクエスト
        let request = UNNotificationRequest(identifier: "\(getday(format:"yyyy-MM-dd-HH:mm:ss",modifiedDate: Date()))", content: notification,trigger: trigger)
        //通知を実装
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // 日付を格納
    //var modifiedDate:Date = Date()
    
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
    
    // イベント情報の取得
    func schoolCalender(date:String,completion: @escaping () -> Void){
        let requestUrl = "https://api.twinte.net/v1/school-calender/"+date
        
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
