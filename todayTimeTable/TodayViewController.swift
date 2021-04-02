//
//  TodayViewController.swift
//  todayTimeTable
//
//  Created by tako on 2019/12/28.
//  Copyright © 2019 tako. All rights reserved.
//

import UIKit
import NotificationCenter


// 新ウィジェットAPI用
struct todayList: Codable {
    let module:module?
    let events:[event]
    let courses:[eachCourse]
    
    struct module: Codable{
        let module:String
        let year:Int
    }
    
    struct event: Codable{
        let eventType:String
        let description:String
        // 存在しないことがある
        let changeTo:String?
    }
    
    struct eachCourse: Codable{
        let year:Int
        let course:course
        
        struct course: Codable {
            let name:String
            let methods: [String]
            let schedules: [schedule]
            
            struct schedule: Codable {
                let module:String
                let day:String
                let period:Int
                let room:String
            }
        }
    }
}

// 最終的にウィジェットで使う授業情報
struct ReturnObject{
    let Lectures:[Lecture]
    let description:String
    let changeTo:String
    let module:String
}

struct Lecture{
    let name:String
    let room:String
    let methods:[String]
    let period:Int
}

/// データ読み込み処理
func fetchAPI(date:String,completion: @escaping (ReturnObject) -> Void) {
    
    // 重複している時間帯は"重複しています"という授業を登録
    // 最後に返すオブジェクトの中に入れる配列
    var todayLectureListWithoutDuplicate:[Lecture] = []
    
    /// URLの生成
    guard let url = URL(string: "https://app.twinte.net/api/v3/timetable/"+date) else {
        /// 文字列が有効なURLでない場合の処理
        return
    }
    /// URLリクエストの生成
    var request = URLRequest(url: url)
    // UserDefaults のインスタンス
    let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
    if let stringCookie = userDefaults?.string(forKey: "stringCookie"){
        // UserDefaultsからCookieを取得
        request.setValue(stringCookie, forHTTPHeaderField: "Cookie")
    }
    /// URLにアクセス
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {    // データ取得チェック
            let decorder = JSONDecoder()
            guard let decodedResponse = try? decorder.decode(todayList.self, from: data) else {
                print("Json decode エラー")
                todayLectureListWithoutDuplicate.append(Lecture(name:"---",room:"未認証です",methods:[],period:1))
                todayLectureListWithoutDuplicate.append(Lecture(name:"---",room:"Twin:teにログインしてください",methods:[],period:2))
                todayLectureListWithoutDuplicate.append(Lecture(name:"---",room:"ログイン済みでこのエラーが出る場合は",methods:[],period:3))
                todayLectureListWithoutDuplicate.append(Lecture(name:"---",room:"お手数ですが運営までご連絡ください。",methods:[],period:4))
                for i in 5...6 {
                    todayLectureListWithoutDuplicate.append(Lecture(name:"---",room:"",methods:[],period:i))
                }
                
                completion(ReturnObject(Lectures:todayLectureListWithoutDuplicate,description:"",changeTo:"",module: ""))
                return
            }
            // 重複ありでとりあえず今日登録してる授業一覧を格納
            var todayLectureList:[Lecture] = []
            // 日課変更がない場合は指定された日の曜日を取得
            // ある場合には後ほど格納
            var changeTo:String = getWeekDate()
            
            // ウィジェットに表示する用
            var displayDescription:String = ""
            var displayChangeTo:String = ""
            var displayModule:String = ""
            
            // print(decodedResponse.module.module)
            if decodedResponse.events.count > 0 {
                displayDescription = decodedResponse.events[0].description
                // 日課変更がある場合にはchangeToに格納する
                if decodedResponse.events[0].changeTo != nil{
                    changeTo = decodedResponse.events[0].changeTo!
                    displayChangeTo = convertDayEnglishToJapanese(day: decodedResponse.events[0].changeTo!)
                }
            }
            // モジュールが記載されない時（冬休み）があるのでその対処
            if(decodedResponse.module != nil){
                displayModule = convertModuleEnglishToJapanese(module: decodedResponse.module!.module)
                for element in decodedResponse.courses{
                    // 今日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                    let newScheduleArray = element.course.schedules.filter{$0.day == changeTo && $0.module == decodedResponse.module!.module }
                    
                    newScheduleArray.forEach{
                        todayLectureList.append(Lecture(name:element.course.name,room:$0.room,methods:element.course.methods,period:$0.period))
                    }
                }
            }
            // 授業時間順にソート
            todayLectureList.sort(by: {$0.period < $1.period})
            
            for i in 1...6 {
                let tmpArray = todayLectureList.filter{$0.period == i}
                // その時間の授業が2つ以上ある場合
                if tmpArray.count > 1 {
                    todayLectureListWithoutDuplicate.append(Lecture(name:"授業が重複しています",room:"",methods:[],period:i))
                }else if tmpArray.count == 0{ // その時限に授業が登録されていない場合
                    todayLectureListWithoutDuplicate.append(Lecture(name:"---",room:"---",methods:[],period:i))
                }else{
                    todayLectureListWithoutDuplicate.append(tmpArray[0])
                }
            }
            completion(ReturnObject(Lectures: todayLectureListWithoutDuplicate, description: displayDescription, changeTo:displayChangeTo,module: displayModule))
            
        } else {
            /// データが取得できなかった場合の処理
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }.resume()
}


// ここに格納される日付がAPIから取得する対象の日付
var modifiedDate:Date = Date()

// modifiedDateの曜日をSun,Mon... 形式の文字列で返す
func getWeekDate()->String{
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en")
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "E", options: 0, locale: Locale.current)
    return formatter.string(from: modifiedDate)
}


func convertModuleEnglishToJapanese(module:String)->String{
    switch module {
    case "SpringA":
        return "春A"
    case "SpringB":
        return "春AB"
    case "SpringC":
        return "春C"
    case "SummerVacation":
        return "夏休み"
    case "FallA":
        return "秋A"
    case "FallB":
        return "秋B"
    case "FallC":
        return "秋C"
    case "SpringVacation":
        return "春休み"
    default:
        return ""
    }
}

func convertDayEnglishToJapanese(day:String)->String{
    switch day {
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
    case "":
        return ""
    default:
        return "特殊"
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
    
    
    fileprivate var articles: [Lecture] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dateLabel.text = getday(format:"MM/dd(EEE)")
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        fetchAPI(date: getday(format:"yyyy-MM-dd"),completion: { (articles) in
            self.articles = articles.Lectures
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
        fetchAPI(date: self.getday(format:"yyyy-MM-dd"),completion: { (articles) in
            self.articles = articles.Lectures
            self.updateWidgetTexts(element: articles)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    
    @IBAction func rightButton(_ sender: Any) {
        modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: modifiedDate)!
        dateLabel.text = self.getday(format:"MM/dd(EEE)")
        fetchAPI(date: self.getday(format:"yyyy-MM-dd"),completion: { (articles) in
            self.articles = articles.Lectures
            self.updateWidgetTexts(element: articles)
            DispatchQueue.main.async {
                self.tableView.reloadData()
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
    
    func updateWidgetTexts(element:ReturnObject){
        DispatchQueue.main.async {
            // 優先度：substituteDay > event > module
            if element.changeTo != ""{
                self.eventLabel.text = "今日は\(element.changeTo)日課です"
            }else if element.description != ""{
                self.eventLabel.text = element.description
            }else{
                self.eventLabel.text = element.module
            }
        }
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
        cell.lectureNameLabel?.text = article.name
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
        if(article.methods.count != 0){
            article.methods.forEach{
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
