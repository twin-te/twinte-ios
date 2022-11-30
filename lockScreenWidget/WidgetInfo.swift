//
//  File.swift
//  lockScreenWidgetExtension
//
//  Created by takonasu on 2022/11/21.
//  Copyright © 2022 tako. All rights reserved.
//

import Foundation

class WidgetInfo {
    private(set) var date:Date = Date()
    private let apiEndpoint = "https://app.twinte.net/api/v3/timetable/"
    
    struct WidgetAllInfo {
        var day:String
        var module:String
        var event: Event
        var lectures:[Lecture]
        var lectureCount: Int
        
        struct Event {
            var normal: Bool // 祝日や通常日課はtrue，授業振替がある場合はfalse
            var content: String
        }
    }
    
    struct Lecture:Hashable{
        let period:Int
        let startTime:String
        let name:String
        let room:String
        let exist:Bool // 授業が登録されているかどうか．されていない場合他の情報は無視される．
    }
    
    // APIデコード用
    private struct dayLectureEventInfo: Codable {
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
    
    func updateDate(newDate: Date) {
        self.date = newDate;
    }
    
    func getWidgetAllInfo()async -> WidgetAllInfo{
        do{
            let myDayLectureEventInfo = try await self.fetchAPI()
            
            var myWidgetAllInfo = WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: true, content: "通常日課"), lectures: [], lectureCount: 0);
            
            // 重複ありで登録してる授業一覧を格納
            var dayLectureList:[Lecture] = []
            
            // 日課変更がない場合は指定された日の曜日を取得
            // ある場合には後ほど格納
            var changeTo:String = getWeekDate()
            
            if myDayLectureEventInfo.events.count > 0 {
                myWidgetAllInfo.event.content = myDayLectureEventInfo.events[0].description
                // 日課変更がある場合
                if myDayLectureEventInfo.events[0].changeTo != nil{
                    changeTo = myDayLectureEventInfo.events[0].changeTo!
                    myWidgetAllInfo.event.normal = false
                    myWidgetAllInfo.event.content = convertDayEnglishToJapanese(day: myDayLectureEventInfo.events[0].changeTo!) + "日課"
                }
            }
            // モジュールが記載されない時（冬休み）があるのでその対処
            if(myDayLectureEventInfo.module != nil){
                myWidgetAllInfo.module = convertModuleEnglishToJapanese(module: myDayLectureEventInfo.module!.module)
                for element in myDayLectureEventInfo.courses{
                    var lectureName:String
                    if let name = element.name{
                        // 授業名が変更されている場合 or カスタム講義の場合
                        lectureName = name
                    }else{
                        // 授業名が変更されていない場合
                        if let course = element.course{
                            lectureName = course.name
                        }else{
                            // 授業名を変更していない授業は必ずcourseが存在するので発生し得ない。
                            lectureName = "不明な授業（エラー）"
                        }
                    }
                    
                    // スケジュール変更されている場合 or カスタム講義の場合
                    if let schedules = element.schedules{
                        // 指定日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                        let newScheduleArray = schedules.filter{$0.day == changeTo && $0.module == myDayLectureEventInfo.module!.module }
                        newScheduleArray.forEach{
                            dayLectureList.append(Lecture(period:$0.period,startTime: LectureStartTime(number: $0.period), name:lectureName,room:$0.room,exist: true))
                        }
                    }else{
                        // スケジュール変更されていない場合
                        if let course = element.course{
                            // 指定日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                            let newScheduleArray = course.schedules.filter{$0.day == changeTo && $0.module == myDayLectureEventInfo.module!.module }
                            newScheduleArray.forEach{
                                dayLectureList.append(Lecture(period:$0.period,startTime: LectureStartTime(number: $0.period), name:lectureName,room:$0.room,exist: true))
                            }
                        }else{
                            // スケジュール変更していない授業&カスタムじゃない授業は必ずcourseが存在するので発生し得ない。
                        }
                    }
                }
            }
            // 授業時間順にソート
            dayLectureList.sort(by: {$0.period < $1.period})
            
            for i in 1...6 {
                let tmpArray = dayLectureList.filter{$0.period == i}
                // その時間の授業が2つ以上ある場合
                if tmpArray.count > 1 {
                    myWidgetAllInfo.lectures.append(Lecture(period:i,startTime: LectureStartTime(number: i), name:"授業が重複しています",room:"-",exist: true))
                }else if tmpArray.count == 0{ // その時限に授業が登録されていない場合
                    myWidgetAllInfo.lectures.append(Lecture(period:i,startTime: LectureStartTime(number: i), name:"-",room:"-",exist: false))
                }else{
                    myWidgetAllInfo.lectures.append(tmpArray[0])
                    myWidgetAllInfo.lectureCount = myWidgetAllInfo.lectureCount + 1
                }
            }
            
            return myWidgetAllInfo
        }catch APIClientError.serverError{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"エラーが発生", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"しました。", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"時間を置いて", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"アプリを再起動後", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"改善しない場合", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"運営にご連絡ください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:1"), lectures: message, lectureCount: 0)
        }catch APIClientError.badStatus{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"エラーが発生", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"しました。", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"---", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"BadStatus", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"改善しない場合", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"運営にご連絡ください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:2"), lectures: message, lectureCount: 0)
        }catch APIClientError.invalidURL{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"エラーが発生", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"しました。", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"---", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"InvalidURL", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"改善しない場合", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"運営にご連絡ください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:3"), lectures: message, lectureCount: 0)
        }catch APIClientError.responseError{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"エラーが発生", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"しました。", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"インターネット接続", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"をご確認ください。", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"改善しない場合", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"運営にご連絡ください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:4"), lectures: message, lectureCount: 0)
        }catch AppInternalError.jsonDecodeError{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"未認証です。", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"Twin:teに", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"ログインしてください。", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"JsonParseError", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"改善しない場合", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"運営にご連絡ください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:5"), lectures: message, lectureCount: 0)
        }catch AppInternalError.cookieError{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"未認証です。", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"Twin:teに", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"ログインしてください。", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"ログイン済みの場合は", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"アプリを再起動して", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"やり直してください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:6"), lectures: message, lectureCount: 0)
        }catch{
            let message:[Lecture] = [
                Lecture(period:1,startTime:"-", name:"エラーが発生しました。", room:"-", exist: false),
                Lecture(period:2,startTime:"-", name:"アプリ・端末の", room:"-", exist: false),
                Lecture(period:3,startTime:"-", name:"再起動を", room:"-", exist: false),
                Lecture(period:4,startTime:"-", name:"お試しください。", room:"-", exist: false),
                Lecture(period:5,startTime:"-", name:"運営にご連絡", room:"-", exist: false),
                Lecture(period:6,startTime:"-", name:"ください。", room:"-", exist: false),
            ]
            return WidgetAllInfo(day: dateToString(format:"MM/dd(EEE)"),module: "", event: WidgetAllInfo.Event(normal: false, content: "Error:7"), lectures: message, lectureCount: 0)
        }
        
        // dateの曜日をSun,Mon... 形式の文字列で返す
        func getWeekDate() -> String{
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en")
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "E", options: 0, locale: Locale.current)
            return formatter.string(from: date)
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
    }
    
    private func fetchAPI() async throws -> dayLectureEventInfo {
        let urlString = self.apiEndpoint + dateToString()
        guard let url = URL(string: urlString) else {
            /// 文字列が有効なURLでない場合の処理
            throw APIClientError.invalidURL
        }
        do {
            // ①リクエスト
            var request = URLRequest(url: url)
            // UserDefaultsからCookieを取得して付与
            let userDefaults = UserDefaults(suiteName: "group.net.twinte.app")
            if let stringCookie = userDefaults?.string(forKey: "stringCookie"){
                // もしCookieがなかったらエラー表示
                if(!stringCookie.contains("twinte_session")){
                    throw AppInternalError.cookieError
                }
                // UserDefaultsからCookieを取得して付与
                request.setValue(stringCookie, forHTTPHeaderField: "Cookie")
            }
            let (data, urlResponse) = try await URLSession.shared.data(for: request, delegate: nil)
            guard let httpStatus = urlResponse as? HTTPURLResponse else {
                // ネットにつながっていないなど（？）
                throw APIClientError.responseError
            }
            
            // ②ステータスコードによって処理を分ける
            switch httpStatus.statusCode {
            case 200 ..< 400:
                let decorder = JSONDecoder()
                guard let decodedResponse = try? decorder.decode(dayLectureEventInfo.self, from: data) else {
                    throw AppInternalError.jsonDecodeError
                }
                return decodedResponse
            case 400... :
                throw APIClientError.badStatus(statusCode: httpStatus.statusCode)
            default:
                fatalError()
                break
            }
        } catch {
            throw APIClientError.serverError(error)
        }
    }
    
    private func dateToString(format: String = "yyyy-MM-dd") -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.locale = Locale(identifier: "ja")
        formatter.dateFormat = format
        return formatter.string(from: self.date)
    }
    
    private enum APIClientError: Error {
        case serverError(Error)
        case badStatus(statusCode:Int)
        case invalidURL
        case responseError
    }
    private enum AppInternalError: Error {
        case jsonDecodeError
        case cookieError
    }
    
}
