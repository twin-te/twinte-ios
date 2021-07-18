//
//  widgetGroup.swift
//  widgetGroup
//
//  Created by tako on 2021/07/17.
//  Copyright © 2021 tako. All rights reserved.
//

import WidgetKit
import SwiftUI

//
//
//      小中大で共通なメソッドの定義
//
//

// 新ウィジェットAPI用
struct todayList: Codable {
    let module:module?
    let events:[event]
    let courses:[eachCourse]
    
    struct module: Codable{
        let module:String
    }
    
    struct event: Codable{
        let eventType:String
        let description:String
        // 存在しないことがある
        let changeTo:String?
    }
    
    struct eachCourse: Codable{
        let name:String?
        let course:course?  // カスタム講義の場合は存在しない
        let schedules: [schedule]?  // ユーザーが変更した場合に追加される
        
        struct course: Codable {
            let name:String
            let schedules: [schedule]
        }
        
        struct schedule: Codable {
            let module:String
            let day:String
            let period:Int
            let room:String
        }
    }
}

// 最終的にウィジェットで使う授業情報
struct FinalInformationList{
    let Lectures:[Lecture]
    let description:String
    let changeTo:String
    let module:String
    let lectureCounter:Int
}

struct Lecture:Hashable{
    let period:Int
    let name:String
    let room:String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let FinalInformationList: FinalInformationList
}

/// データ読み込み処理
func fetchAPI(date:String,completion: @escaping (FinalInformationList) -> Void) {
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
    //UserDefaults のインスタンス
    let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
    if let stringCookie = userDefaults?.string(forKey: "stringCookie"){
        // UserDefaultsからCookieを取得して付与
        request.setValue(stringCookie, forHTTPHeaderField: "Cookie")
        // もしCookieがなかったらエラー表示
        if(!stringCookie.contains("twinte_session")){
            todayLectureListWithoutDuplicate.append(Lecture(period:1,name:"未認証です。",room:"-"))
            todayLectureListWithoutDuplicate.append(Lecture(period:2,name:"Twin:teに",room:"-"))
            todayLectureListWithoutDuplicate.append(Lecture(period:3,name:"ログインしてください。",room:"-"))
            todayLectureListWithoutDuplicate.append(Lecture(period:4,name:"ログイン済みの場合は",room:"-"))
            todayLectureListWithoutDuplicate.append(Lecture(period:5,name:"アプリを再起動して",room:"-"))
            todayLectureListWithoutDuplicate.append(Lecture(period:6,name:"やり直してください。",room:"-"))
            
            completion(FinalInformationList(Lectures:todayLectureListWithoutDuplicate,description:"",changeTo:"",module: "",lectureCounter: 0))
        }
    }
    
    
    /// URLにアクセス
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {    // データ取得チェック
            let decorder = JSONDecoder()
            guard let decodedResponse = try? decorder.decode(todayList.self, from: data) else {
                print("Json decode エラー")
                todayLectureListWithoutDuplicate.append(Lecture(period:1,name:"不明なエラー",room:"-"))
                todayLectureListWithoutDuplicate.append(Lecture(period:2,name:"授業情報取得に",room:"-"))
                todayLectureListWithoutDuplicate.append(Lecture(period:3,name:"失敗しました。",room:"-"))
                todayLectureListWithoutDuplicate.append(Lecture(period:4,name:"---",room:"-"))
                for i in 5...6 {
                    todayLectureListWithoutDuplicate.append(Lecture(period:i,name:"---",room:"-"))
                }
                
                completion(FinalInformationList(Lectures:todayLectureListWithoutDuplicate,description:"",changeTo:"",module: "",lectureCounter: 0))
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
                    
                    var lectureName:String
                    if let name = element.name{
                        // 授業名を変更されている場合 or カスタム講義の場合
                        lectureName = name
                    }else{
                        // 授業名を変更されていない場合
                        if let course = element.course{
                            lectureName = course.name
                        }else{
                            // 授業名を変更していない授業は必ずcourseが存在するので発生し得ない。
                            lectureName = "不明な授業（エラー）"
                        }
                        
                    }
                    
                    // スケジュール変更されている場合
                    if let schedules = element.schedules{
                        // 今日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                        let newScheduleArray = schedules.filter{$0.day == changeTo && $0.module == decodedResponse.module!.module }
                        newScheduleArray.forEach{
                            todayLectureList.append(Lecture(period:$0.period,name:lectureName,room:$0.room))
                        }
                    }else{
                        // スケジュール変更されていない場合
                        if let course = element.course{
                            // 今日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                            let newScheduleArray = course.schedules.filter{$0.day == changeTo && $0.module == decodedResponse.module!.module }
                            newScheduleArray.forEach{
                                todayLectureList.append(Lecture(period:$0.period,name:lectureName,room:$0.room))
                            }
                        }else{
                            // スケジュール変更していない授業&カスタムじゃない授業は必ずcourseが存在するので発生し得ない。
                        }
                    }
                }
            }
            // 授業時間順にソート
            todayLectureList.sort(by: {$0.period < $1.period})
            // 授業のコマ数
            var lectureCounter = 0
            
            for i in 1...6 {
                let tmpArray = todayLectureList.filter{$0.period == i}
                // その時間の授業が2つ以上ある場合
                if tmpArray.count > 1 {
                    todayLectureListWithoutDuplicate.append(Lecture(period:i,name:"授業が重複しています",room:"-"))
                }else if tmpArray.count == 0{ // その時限に授業が登録されていない場合
                    todayLectureListWithoutDuplicate.append(Lecture(period:i,name:"授業がありません",room:"-"))
                }else{
                    todayLectureListWithoutDuplicate.append(tmpArray[0])
                    lectureCounter = lectureCounter + 1
                }
            }
            completion(FinalInformationList(Lectures: todayLectureListWithoutDuplicate, description: displayDescription, changeTo:displayChangeTo,module: displayModule,lectureCounter: lectureCounter))
            
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

// 授業時限と開始時間の対応
func LectureStartTime(number:Int)->String{
    switch number {
    case 1:
        return "8:40"
    case 2:
        return "10:10"
    case 3:
        return "12:15"
    case 4:
        return "13:45"
    case 5:
        return "15:15"
    case 6:
        return "16:45"
    default:
        return "-"
    }
}

// 日付を引数で指定されたフォーマットに変換
func getday(format:String) -> String{
    
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja")
    formatter.dateFormat = format
    return formatter.string(from: modifiedDate as Date)
}





















@main
struct widgetGroup: WidgetBundle {
    
    var body: some Widget {
        largeWidget();
        mediumWidget();
        smallWidget();
    }
}


