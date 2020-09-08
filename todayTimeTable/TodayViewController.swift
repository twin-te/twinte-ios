//
//  TodayViewController.swift
//  todayTimeTable
//
//  Created by tako on 2019/12/28.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import NotificationCenter

// 授業情報を格納
struct Lecture: Codable {
    let period: Int
    let room: String
    let lecture_name: String
    let instructor: String
    let formats: [String]
}

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

struct LectureGet {
    
    static func fetchArticle(date:String,completion: @escaping ([Lecture]) -> Swift.Void) {
        
        let requestUrl = "https://api.twinte.net/v1/timetables/?date="+date
        
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
                // jsonのパース実施
                let resultSet = try JSONDecoder().decode([Lecture].self, from: data)
                //print(resultSet)
                completion(resultSet)
            } catch let error {
                print("## error: \(error)")
                // ログインしていない場合にこのエラーが出る（jsonで返ってこないので）
                let resultSet = [Lecture(period: 1,room: "未認証です",lecture_name: "Twin:teにログインしてください",instructor: "",formats: []),Lecture(period: 2,room: "未認証です",lecture_name: "ここに時間割が表示されます！",instructor: "",formats: [])]
                completion(resultSet)
            }
        }
        // 通信開始
        task.resume()
        
    }
}


// カスタムセルの専用クラス
class CustomTableViewCell:UITableViewCell {
    
    @IBOutlet weak var lecturePeriodLabel: UILabel!
    @IBOutlet weak var lectureNameLabel: UILabel!
    @IBOutlet weak var lectureRoomLabel: UILabel!
    @IBOutlet weak var onlineAsynchronous: UIImageView!
    @IBOutlet weak var onlineSynchronous: UIImageView!
    @IBOutlet weak var faceToFace: UIImageView!
    
}


class TodayViewController: UIViewController, NCWidgetProviding,UITableViewDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    // 日付を格納
    var modifiedDate:Date = Date()
    
    fileprivate var articles: [Lecture] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dateLabel.text = getday(format:"MM/dd(EEE)")
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        LectureGet.fetchArticle(date: getday(format:"yyyy-MM-dd"),completion: { (articles) in
            self.arrayTimetableParse(lectures: articles)
            self.schoolCalender(date: self.getday(format:"yyyy-MM-dd"))
            //print(articles)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    // 授業の時間と配列のindexを対応させて格納する
    func arrayTimetableParse(lectures:[Lecture]){
        // 配列の中身を消去しないと無限に配列の要素が増える
        self.articles.removeAll()
        for i in 1...6 {
            lectures.forEach{
                if $0.period == i {
                    self.articles.append($0)
                }
            }
            if self.articles.count != i{
                self.articles.append(Lecture(period: i,room: "----",lecture_name: "----",instructor: "",formats: []))
            }
        }
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode,
                                          withMaximumSize maxSize: CGSize) {
        if (activeDisplayMode == .compact) {
            self.preferredContentSize = maxSize;
        } else {
            self.preferredContentSize = CGSize(width: 0, height: 430);
        }
    }
    
    
    
    @IBAction func leftButton(_ sender: Any) {
        modifiedDate = Calendar.current.date(byAdding: .day, value: -1, to: modifiedDate)!
        dateLabel.text = self.getday(format:"MM/dd(EEE)")
        LectureGet.fetchArticle(date: self.getday(format:"yyyy-MM-dd"),completion: { (articles) in
            DispatchQueue.main.async {
                self.rightButton.isEnabled = false
                self.leftButton.isEnabled = false
            }
            self.arrayTimetableParse(lectures: articles)
            //print(articles)
            self.schoolCalender(date: self.getday(format:"yyyy-MM-dd"))
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.rightButton.isEnabled = true
                self.leftButton.isEnabled = true
            }
        })
    }
    
    
    @IBAction func rightButton(_ sender: Any) {
        modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: modifiedDate)!
        dateLabel.text = self.getday(format:"MM/dd(EEE)")
        LectureGet.fetchArticle(date: self.getday(format:"yyyy-MM-dd"),completion: { (articles) in
            DispatchQueue.main.async {
                self.rightButton.isEnabled = false
                self.leftButton.isEnabled = false
            }
            self.arrayTimetableParse(lectures: articles)
            //print(articles)
            self.schoolCalender(date: self.getday(format:"yyyy-MM-dd"))
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.rightButton.isEnabled = true
                self.leftButton.isEnabled = true
            }
            
        })
        
    }
    
    // 日付を引数で指定されたフォーマットに変換
    func getday(format:String) -> String{
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        formatter.dateFormat = format
        return formatter.string(from: modifiedDate as Date)
    }
    
    // イベント情報の取得
    func schoolCalender(date:String){
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
                
                DispatchQueue.main.async {
                    // 優先度：substituteDay > event > module
                    if let substituteDay = resultSet.substituteDay{
                        self.eventLabel.text = "今日は\(substituteDay.change_to)曜日課です"
                    } else if let event = resultSet.event{
                        self.eventLabel.text = "\(event.event_type) \(event.description)"
                    } else if let module = resultSet.module{
                        self.eventLabel.text = "\(module)"
                    }else{
                        self.eventLabel.text = ""
                    }
                }
            } catch let error {
                print("## error: \(error)")
            }
        }
        // 通信開始
        task.resume()
        
    }
}

// ダークモード判定
extension UITraitCollection {
    
    public static var isDarkMode: Bool {
        if #available(iOS 13, *), current.userInterfaceStyle == .dark {
            return true
        }
        return false
    }
    
}


extension TodayViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        guard let cell: CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as? CustomTableViewCell else{
            return UITableViewCell()
        }
        // セルに表示する値を設定する
        let article = articles[indexPath.row]
        //cell.textLabel?.text = article.lecture_name
        cell.lectureNameLabel?.text = article.lecture_name
        cell.lectureRoomLabel?.text = article.room
        cell.lecturePeriodLabel?.text = article.period.description
        cell.lecturePeriodLabel?.textColor = UIColor.white
        
        // 全てdisableアイコンにする
        if (UITraitCollection.isDarkMode){
            cell.onlineAsynchronous.image = UIImage(named: "disable-dark-online-asynchronous")
            cell.onlineSynchronous.image = UIImage(named: "disable-dark-online-synchronous")
            cell.faceToFace.image = UIImage(named: "disable-dark-face-to-face")
        }else{
            cell.onlineAsynchronous.image = UIImage(named: "disable-light-online-asynchronous")
            cell.onlineSynchronous.image = UIImage(named: "disable-light-online-synchronous")
            cell.faceToFace.image = UIImage(named: "disable-light-face-to-face")
        }
        // 授業フォーマットに記載がある場合
        if(article.formats.count != 0){
            article.formats.forEach{
                // ダークモード判定
                if (UITraitCollection.isDarkMode){
                    switch $0 {
                    case "Asynchronous":
                        cell.onlineAsynchronous.image = UIImage(named: "dark-online-asynchronous")
                    case "Synchronous":
                        cell.onlineSynchronous.image = UIImage(named: "dark-online-synchronous")
                    case "FaceToFace":
                        cell.faceToFace.image = UIImage(named: "dark-face-to-face")
                    default:
                        break
                    }
                }else{
                    switch $0 {
                    case "Asynchronous":
                        cell.onlineAsynchronous.image = UIImage(named: "light-online-asynchronous")
                    case "Synchronous":
                        cell.onlineSynchronous.image = UIImage(named: "light-online-synchronous")
                    case "FaceToFace":
                        cell.faceToFace.image = UIImage(named: "light-face-to-face")
                    default:
                        break
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    // タップされた時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = URL(string: "twinte-app://") else { return }
        extensionContext?.open(url, completionHandler: { (success: Bool) in })
    }
}
