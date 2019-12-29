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

struct LectureGet {
    
    static func fetchArticle(completion: @escaping ([Lecture]) -> Swift.Void) {
        
        let requestUrl = "https://dev.api.twinte.net/v1/timetables/?date=2020-01-15"
        
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
                // パース実施
                let resultSet = try JSONDecoder().decode([Lecture].self, from: data)
                //print(resultSet)
                completion(resultSet)
            } catch let error {
                print("## error: \(error)")
            }
        }
        // 通信開始
        task.resume()
        
    }
}

class TodayViewController: UIViewController, NCWidgetProviding,UITableViewDelegate {
    

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var articles: [Lecture] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        LectureGet.fetchArticle(completion: { (articles) in
            let lectures:[Lecture] = articles
            // 授業の時間と配列のindexを対応させて格納する
            for i in 0..<6 {
                lectures.forEach{
                    if $0.period == i+1 {
                        self.articles.append($0)
                    }
                }
                if self.articles.count != i+1{
                    self.articles.append(Lecture(period: 0,room: "----",lecture_name: "----",instructor: ""))
                }
            }
            
            print(articles)
            
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode,
                                          withMaximumSize maxSize: CGSize) {
        if (activeDisplayMode == .compact) {
            self.preferredContentSize = maxSize;
        } else {
            self.preferredContentSize = CGSize(width: 0, height: 430);
        }
    }
    
    
}

extension TodayViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
        // セルに表示する値を設定する
        let article = articles[indexPath.row]
        cell.textLabel?.text = article.lecture_name
        cell.detailTextLabel?.text = article.room
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
}
