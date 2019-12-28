//
//  TodayViewController.swift
//  todayTimeTable
//
//  Created by tako on 2019/12/28.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import NotificationCenter

struct Lecture: Codable {
    let period: Int
    let room: String
    let lecture_name: String
    let instructor: String
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // 今日の時間割を取得する関数
        let date:String = "2019-12-11"
        todayget(date: date)
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func todayget(date: String){
        let requestUrl = "https://dev.api.twinte.net/v1/timetables/?date="+date
        
        // URL生成
        guard let url = URL(string: requestUrl) else {
            // URL生成失敗
            return
        }
        
        // リクエスト生成
        var request = URLRequest(url: url)
        // UserDefaults のインスタンス
        let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
        if let stringCookie = userDefaults?.string(forKey: "stringCookie"){
            // UserDefaultsからCookieを取得
            request.setValue(stringCookie, forHTTPHeaderField: "Cookie")
        }
        // 商品検索APIをコールして商品検索を行う
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
            /*
             let str = String(decoding: data, as: UTF8.self)
             print(str)
             // jsonをそのまま表示
             
             do {
             let object = try JSONSerialization.jsonObject(with: data, options: [])
             print(object)
             } catch let e {
             print(e)
             }
             */
            do {
                // パース実施
                let resultSet = try JSONDecoder().decode([Lecture].self, from: data)
                print(resultSet)
            } catch let error {
                print("## error: \(error)")
            }
        }
        // 通信開始
        task.resume()
    }
    
    
}
