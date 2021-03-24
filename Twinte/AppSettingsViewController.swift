//
//  AppSettingsViewController.swift
//  Twinte
//
//  Created by tako on 2020/03/31.
//  Copyright © 2020 tako. All rights reserved.
//

import UIKit

class AppSettingsViewController: UIViewController {
    
    @IBOutlet weak var notificationLabel1: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var notificationDateLabel: UILabel!
    @IBOutlet weak var changeDateButton: UIButton!
    @IBOutlet weak var confirmDateButton: UIButton!
    @IBOutlet weak var notificationSwitchObject: UISwitch!
    
    // 通知作成のためのクラス
    let Notification = ScheduleNotification()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if #available(iOS 13.0, *) {
            // ダークモード時ヘッダの背景色がおかしくなる問題に対処
            if UITraitCollection.current.userInterfaceStyle == .dark {
                let coloredAppearance = UINavigationBarAppearance()
                coloredAppearance.configureWithOpaqueBackground()
                coloredAppearance.backgroundColor = UIColor(red: 27/255, green: 32/255, blue: 44/255, alpha: 1)
                coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = coloredAppearance
                UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
            }}
        
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
        
        Notification.scheduleAllNotification()
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
            Notification.scheduleAllNotification()
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
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
