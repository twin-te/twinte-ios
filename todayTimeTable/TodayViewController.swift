//
//  TodayViewController.swift
//  todayTimeTable
//
//  Created by tako on 2019/12/28.
//  Copyright © 2019 tako. All rights reserved.
//

import NotificationCenter
import UIKit
import V4API

// 最終的にウィジェットで使う授業情報
struct ReturnObject {
    let Lectures: [Lecture]
    let description: String
    let changeTo: String
    let module: String
}

struct Lecture {
    let name: String
    let room: String
    let methods: [Timetable_V1_CourseMethod]
    let period: Int32
}

/// データ読み込み処理
func fetchAPI(date: String, completion: @escaping (ReturnObject) -> Void) {
    V4APIClient.shared.unifiedClient.getByDate(request: .with {
        $0.date = .with { $0.value = date }
    }) { response in
        guard let message = response.message else {
            var todayLectureListWithoutDuplicate: [Lecture] = []
            todayLectureListWithoutDuplicate.append(Lecture(name: "---", room: "未認証です", methods: [], period: 1))
            todayLectureListWithoutDuplicate.append(Lecture(name: "---", room: "Twin:teにログインしてください", methods: [], period: 2))
            todayLectureListWithoutDuplicate.append(Lecture(name: "---", room: "ログイン済みでこのエラーが出る場合は", methods: [], period: 3))
            todayLectureListWithoutDuplicate.append(Lecture(name: "---", room: "お手数ですが運営までご連絡ください。", methods: [], period: 4))
            for i: Int32 in 5...6 {
                todayLectureListWithoutDuplicate.append(Lecture(name: "---", room: "", methods: [], period: i))
            }
            completion(ReturnObject(Lectures: todayLectureListWithoutDuplicate, description: "", changeTo: "", module: ""))
            return
        }

        // 最後に返すオブジェクトの中に入れる配列
        var todayLectureListWithoutDuplicate: [Lecture] = []
        // 重複ありでとりあえず今日登録してる授業一覧を格納
        var todayLectureList: [Lecture] = []
        // 日課変更がない場合は指定された日の曜日を取得
        // ある場合には後ほど格納
        var changeTo = convertDateToWeekday(Date())

        // ウィジェットに表示する用
        var displayDescription: String = ""
        var displayChangeTo: String = ""
        var displayModule: String = ""

        // print(decodedResponse.module.module)
        if message.events.count > 0 {
            displayDescription = message.events[0].description_p
            // 日課変更がある場合にはchangeToに格納する
            if message.events[0].changeTo != .unspecified {
                changeTo = message.events[0].changeTo
                displayChangeTo = convertWeekdayToJapanese(message.events[0].changeTo)
            }
        }
        // モジュールが記載されない時（冬休み）があるのでその対処
        if message.module != .unspecified {
            displayModule = convertModuleToJapanese(message.module)
            for course in message.registeredCourses {
                // 今日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                let newScheduleArray = course.schedules.filter { schedule in
                    areModulesEquivalent(schedule.module, message.module) && areWeekdaysEquivalent(schedule.day, changeTo)
                }
                for schedule in newScheduleArray {
                    todayLectureList.append(Lecture(
                        name: course.name,
                        room: schedule.locations,
                        methods: course.methods,
                        period: schedule.period,
                    ))
                }
            }
        }
        // 授業時間順にソート
        todayLectureList.sort(by: { $0.period < $1.period })

        for i: Int32 in 1...6 {
            let tmpArray = todayLectureList.filter { $0.period == i }
            if tmpArray.count > 1 { // その時間の授業が2つ以上ある場合
                todayLectureListWithoutDuplicate.append(Lecture(name: "授業が重複しています", room: "", methods: [], period: i))
            } else if tmpArray.count == 0 { // その時限に授業が登録されていない場合
                todayLectureListWithoutDuplicate.append(Lecture(name: "---", room: "---", methods: [], period: i))
            } else {
                todayLectureListWithoutDuplicate.append(tmpArray[0])
            }
        }
        completion(ReturnObject(Lectures: todayLectureListWithoutDuplicate, description: displayDescription, changeTo: displayChangeTo, module: displayModule))
    }
}

// ここに格納される日付がAPIから取得する対象の日付
var modifiedDate: Date = Date()

// カスタムセルの専用クラス
class CustomTableViewCell: UITableViewCell {
    @IBOutlet var lecturePeriodLabel: UILabel!
    @IBOutlet var lectureNameLabel: UILabel!
    @IBOutlet var lectureRoomLabel: UILabel!
    @IBOutlet var onlineAsynchronous: UIImageView!
    @IBOutlet var onlineSynchronous: UIImageView!
    @IBOutlet var faceToFace: UIImageView!
}

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var eventLabel: UILabel!

    @IBOutlet var rightButton: UIButton!
    @IBOutlet var leftButton: UIButton!

    fileprivate var articles: [Lecture] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dateLabel.text = getday(format: "MM/dd(EEE)")
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }

    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        // Perform any setup necessary in order to update the view.

        fetchAPI(date: getday(format: "yyyy-MM-dd"), completion: { articles in
            self.articles = articles.Lectures
            // print(articles)
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
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize
        } else {
            self.preferredContentSize = CGSize(width: 0, height: 430)
        }
    }

    @IBAction func leftButton(_ sender: Any) {
        modifiedDate = Calendar.current.date(byAdding: .day, value: -1, to: modifiedDate)!
        dateLabel.text = self.getday(format: "MM/dd(EEE)")
        fetchAPI(date: self.getday(format: "yyyy-MM-dd"), completion: { articles in
            self.articles = articles.Lectures
            self.updateWidgetTexts(element: articles)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    @IBAction func rightButton(_ sender: Any) {
        modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: modifiedDate)!
        dateLabel.text = self.getday(format: "MM/dd(EEE)")
        fetchAPI(date: self.getday(format: "yyyy-MM-dd"), completion: { articles in
            self.articles = articles.Lectures
            self.updateWidgetTexts(element: articles)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    // 日付を引数で指定されたフォーマットに変換
    func getday(format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        formatter.dateFormat = format
        return formatter.string(from: modifiedDate as Date)
    }

    func updateWidgetTexts(element: ReturnObject) {
        DispatchQueue.main.async {
            // 優先度：substituteDay > event > module
            if element.changeTo != "" {
                self.eventLabel.text = "今日は\(element.changeTo)日課です"
            } else if element.description != "" {
                self.eventLabel.text = element.description
            } else {
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
        guard let cell: CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as? CustomTableViewCell else {
            return UITableViewCell()
        }
        // セルに表示する値を設定する
        let article = articles[indexPath.row]
        // cell.textLabel?.text = article.lecture_name
        cell.lectureNameLabel?.text = article.name
        cell.lectureRoomLabel?.text = article.room
        cell.lecturePeriodLabel?.text = article.period.description
        cell.lecturePeriodLabel?.textColor = UIColor.white

        // 全てdisableアイコンにする
        if UITraitCollection.isDarkMode {
            cell.onlineAsynchronous.image = UIImage(named: "disable-dark-online-asynchronous")
            cell.onlineSynchronous.image = UIImage(named: "disable-dark-online-synchronous")
            cell.faceToFace.image = UIImage(named: "disable-dark-face-to-face")
        } else {
            cell.onlineAsynchronous.image = UIImage(named: "disable-light-online-asynchronous")
            cell.onlineSynchronous.image = UIImage(named: "disable-light-online-synchronous")
            cell.faceToFace.image = UIImage(named: "disable-light-face-to-face")
        }
        // 授業フォーマットに記載がある場合
        if article.methods.count != 0 {
            for method in article.methods {
                // ダークモード判定
                if UITraitCollection.isDarkMode {
                    switch method {
                    case .onlineAsynchronous:
                        cell.onlineAsynchronous.image = UIImage(named: "dark-online-asynchronous")
                    case .onlineSynchronous:
                        cell.onlineSynchronous.image = UIImage(named: "dark-online-synchronous")
                    case .faceToFace:
                        cell.faceToFace.image = UIImage(named: "dark-face-to-face")
                    default:
                        break
                    }
                } else {
                    switch method {
                    case .onlineAsynchronous:
                        cell.onlineAsynchronous.image = UIImage(named: "light-online-asynchronous")
                    case .onlineSynchronous:
                        cell.onlineSynchronous.image = UIImage(named: "light-online-synchronous")
                    case .faceToFace:
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
