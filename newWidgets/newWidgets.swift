//
//  newWidgets.swift
//  newWidgets
//
//  Created by tako on 2021/03/29.
//  Copyright © 2021 tako. All rights reserved.
//

import WidgetKit
import SwiftUI

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

struct Provider: TimelineProvider {
    let sampleFinalInformationList:FinalInformationList = FinalInformationList(Lectures: [
        Lecture(period:1,name:"つくば市史概論",room: "1B202"),
        Lecture(period:2,name:"基礎ネコ語AII",room: "平砂宿舎"),
        Lecture(period:3,name:"授業がありません",room: "-"),
        Lecture(period:4,name:"筑波大学〜野草と食〜",room: "2D202"),
        Lecture(period:5,name:"東京教育大学の遺産",room: "春日講堂"),
        Lecture(period:6,name:"日常系作品の実際",room: "オンライン"),
    ], description: "", changeTo: "水曜", module: "",lectureCounter: 5)
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), FinalInformationList: sampleFinalInformationList)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), FinalInformationList: sampleFinalInformationList)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 今日の19:00の定義（今日の更新タイミング）
        var components = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        components.hour = 19;
        components.minute = 0;
        components.second = 0;
        let todayUpdateTime = Calendar(identifier: .gregorian).date(from: components)!
        dump(todayUpdateTime)
        if(Date() < todayUpdateTime){
            print("今日の更新時間以前")
            // 今が19時以前の場合。今日の予定を表示&次表示を更新するのは今日の19時以降
            modifiedDate = Date()
            fetchAPI(date: getday(format:"yyyy-MM-dd"),completion: {(todayInformationList) in
                var entries: [SimpleEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                let entry = SimpleEntry(date: Date(), FinalInformationList: todayInformationList)
                entries.append(entry)
                // 配列
                let timeline = Timeline(entries: entries, policy: .after(todayUpdateTime))
                completion(timeline)
            })
        }else{
            print("今日の更新時間以降")
            // 今が19時以降の場合。明日の予定を表示&次表示を更新するのは明日の19時以降
            // 明日の更新時間の定義。（前述の更新時間に一日を加えたもの）
            let tomorrowUpdateTime = Calendar.current.date(byAdding: .day, value: 1, to: todayUpdateTime)!
            modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            fetchAPI(date: getday(format:"yyyy-MM-dd"),completion: {(todayInformationList) in
                var entries: [SimpleEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                let entry = SimpleEntry(date: Date(), FinalInformationList: todayInformationList)
                entries.append(entry)
                // 配列
                let timeline = Timeline(entries: entries, policy: .after(tomorrowUpdateTime))
                completion(timeline)
            })
        }
    }
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
    //request.setValue("connect.sid=test", forHTTPHeaderField: "Cookie")
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
                    // 今日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
                    let newScheduleArray = element.course.schedules.filter{$0.day == changeTo && $0.module == decodedResponse.module!.module }
                    
                    newScheduleArray.forEach{
                        todayLectureList.append(Lecture(period:$0.period,name:element.course.name,room:$0.room))
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

struct newWidgetsEntryView : View {
    var entry: Provider.Entry
    let twintePrimaryColor = Color("PrimaryColor");
    let textDefaultColor = Color("WidgetMainText");
    let widgetBaseColor = Color("WidgetBackground");
    let noneLectureColor = Color("WidgetNoneText");
    let widgetRoomScheduleColor = Color("WidgetSubText");
    @Environment(\.widgetFamily) var family: WidgetFamily
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        switch family {
        //        case .systemSmall:
        //
        //        case .systemMedium:
        
        case .systemLarge:
            // 「全てのコマに授業が入っている場合」のライトモードのデザインデータ
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.FinalInformationList.module) \(getday(format:"MM/dd(EEE)"))")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .foregroundColor(textDefaultColor)
                        .lineSpacing(19.60)
                        .frame(width: 120,alignment:.leading)
                        .lineLimit(1)
                    
                    if entry.FinalInformationList.description != "" {
                        Text(entry.FinalInformationList.description)
                            .font(.caption)
                            .foregroundColor(textDefaultColor)
                            .lineSpacing(16.80)
                            .frame(width: 105,alignment:.leading)
                            .lineLimit(1)
                    }else if entry.FinalInformationList.changeTo == "" {
                        Text("通常日課")
                            .font(.caption)
                            .foregroundColor(textDefaultColor)
                            .lineSpacing(16.80)
                            .frame(width: 105,alignment:.leading)
                            .lineLimit(1)
                    }
                    else{
                        Text("\(entry.FinalInformationList.changeTo)日課")
                            .font(.caption)
                            .foregroundColor(textDefaultColor)
                            .lineSpacing(16.80)
                            .frame(width: 105,alignment:.leading)
                            .lineLimit(1)
                    }
                    
                    Text("\(String(entry.FinalInformationList.lectureCounter))コマの授業")
                        .font(.caption)
                        .lineSpacing(16.80)
                        .foregroundColor(twintePrimaryColor)
                    
                }
                .padding(.leading, 20)
                .padding(.top, 20)
                
                VStack(spacing: 0) {
                    
                    ForEach(entry.FinalInformationList.Lectures, id: \.hashValue) {element in
                        HStack(spacing: 8) {
                            Text(String(element.period))
                                .fontWeight(.medium)
                                .font(.subheadline)
                                .foregroundColor(textDefaultColor)
                                .lineSpacing(21)
                                .frame(width: 10)
                            
                            
                            VStack(alignment: .leading, spacing: 0) {
                                if element.name == "授業がありません"{
                                    Text(element.name)
                                        .fontWeight(.medium)
                                        .font(.caption)
                                        .foregroundColor(noneLectureColor)
                                        .lineSpacing(16.80)
                                        .lineLimit(1)
                                        .frame(width: 130, alignment: .leading)
                                }else{
                                    Text(element.name)
                                        .fontWeight(.medium)
                                        .font(.caption)
                                        .foregroundColor(textDefaultColor)
                                        .lineSpacing(16.80)
                                        .lineLimit(1)
                                        .frame(width: 130, alignment: .leading)
                                }
                                
                                
                                HStack(alignment: .top, spacing: 4) {
                                    HStack(alignment: .center, spacing: 2) {
                                        if element.name == "授業がありません"{
                                            if colorScheme == .dark {
                                                Image("room-dark-disabled")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }else{
                                                Image("room-disabled")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }
                                            Text(element.room)
                                                .font(.caption2)
                                                .foregroundColor(noneLectureColor)
                                                .lineSpacing(14)
                                                .lineLimit(1)
                                                .frame(width: 60,alignment:.leading)
                                        }else{
                                            if colorScheme == .dark {
                                                Image("room-dark")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }else{
                                                Image("room")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }
                                            Text(element.room)
                                                .font(.caption2)
                                                .foregroundColor(widgetRoomScheduleColor)
                                                .lineSpacing(14)
                                                .lineLimit(1)
                                                .frame(width: 60,alignment:.leading)
                                        }
                                    }
                                    
                                    HStack(alignment: .center, spacing: 2) {
                                        if element.name == "授業がありません"{
                                            if colorScheme == .dark {
                                                Image("schedule-dark-disabled")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }else{
                                                Image("schedule-disabled")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }
                                            
                                            Text("-")
                                                .font(.caption2)
                                                .foregroundColor(noneLectureColor)
                                                .lineSpacing(14)
                                                .lineLimit(1)
                                                .frame(width: 30,alignment:.leading)
                                        }else{
                                            if colorScheme == .dark {
                                                Image("schedule-dark")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }else{
                                                Image("schedule")
                                                    .resizable()
                                                    .frame(width: 14, height: 14)
                                            }
                                            Text(LectureStartTime(number: element.period))
                                                .font(.caption2)
                                                .foregroundColor(widgetRoomScheduleColor)
                                                .lineSpacing(14)
                                                .lineLimit(1)
                                                .frame(width: 40,alignment:.leading)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 10)
                }
                .padding(.bottom,20)
                .padding(.leading,20)
                .padding(.top,20)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(stops: [
                    .init(color: Color("BorderShadowRight"), location: 0.0),
                    .init(color: widgetBaseColor, location: 0.03),
                    
                ]), startPoint: .leading, endPoint: .trailing))
                
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("BorderColor"), lineWidth: 1.2))
                .compositingGroup()
                .shadow(radius: 10, x: 13, y: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(widgetBaseColor)
            .cornerRadius(21.67)
            
        default: Text("エラー")
        }
    }
}

@main
struct newWidgets: Widget {
    let kind: String = "Twin:te"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            newWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Twin:te")
        .description("今日の時間割を表示します")
        .supportedFamilies([.systemLarge])
        //            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct newWidgets_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFinalInformationList:FinalInformationList = FinalInformationList(Lectures: [
            Lecture(period:1,name:"授業がありません",room: "-"),
            Lecture(period:2,name:"内科系スポーツ医学演習",room: "3C213"),
            Lecture(period:3,name:"発展体育シューティングスポーツ",room: "1H201"),
            Lecture(period:4,name:"インド仏教思想",room: "第3体育館"),
            Lecture(period:5,name:"情報社会と法制度",room: "GBAE12345567889"),
            Lecture(period:6,name:"寺子屋実習",room: "東京あ江戸あいうえお博物館"),
        ], description: "", changeTo: "", module: "",lectureCounter:0)
        
        
        newWidgetsEntryView(entry: SimpleEntry(date: Date(), FinalInformationList: sampleFinalInformationList))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
