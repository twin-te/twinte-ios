//
//  smallWidget.swift
//  smallWidget
//
//  Created by tako on 2021/05/30.
//  Copyright © 2021 tako. All rights reserved.
//

import WidgetKit
import SwiftUI


struct smallWidgetProvider: TimelineProvider {
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
        // 各授業時間開始時刻+30分の定義（ウィジェットの更新時間）
        var firstClassTimeComponent = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        firstClassTimeComponent.hour = 9;
        firstClassTimeComponent.minute = 10;
        firstClassTimeComponent.second = 0;
        var secondClassTimeComponent = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        secondClassTimeComponent.hour = 10;
        secondClassTimeComponent.minute = 40;
        secondClassTimeComponent.second = 0;
        var thirdClassTimeComponent = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        thirdClassTimeComponent.hour = 12;
        thirdClassTimeComponent.minute = 45;
        thirdClassTimeComponent.second = 0;
        var fourthClassTimeComponent = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        fourthClassTimeComponent.hour = 14;
        fourthClassTimeComponent.minute = 15;
        fourthClassTimeComponent.second = 0;
        var fifthClassTimeComponent = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        fifthClassTimeComponent.hour = 15;
        fifthClassTimeComponent.minute = 45;
        fifthClassTimeComponent.second = 0;
        var sixthClassTimeComponent = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        sixthClassTimeComponent.hour = 17;
        sixthClassTimeComponent.minute = 15;
        sixthClassTimeComponent.second = 0;
        
        // 今日の19:00の定義（今日の更新タイミング）
        var components = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        components.hour = 19;
        components.minute = 0;
        components.second = 0;
        let todayUpdateTime = Calendar(identifier: .gregorian).date(from: components)!
        
        if(Date() < todayUpdateTime){
            //            print("今日の更新時間以前")
            // 今が19時以前の場合。今日の予定を表示&次表示を更新するのは今日の19時以降
            modifiedDate = Date()
            fetchAPI(date: getday(format:"yyyy-MM-dd"),completion: {(todayInformationList) in
                var entries: [SimpleEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                // 今が1限開始前の場合
                if(Date() < Calendar(identifier: .gregorian).date(from: firstClassTimeComponent)!){
                    entries.append(SimpleEntry(date: Date(), FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:0)))
                }
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: firstClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:1)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: secondClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:2)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: thirdClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:3)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: fourthClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:4)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: fifthClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:5)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: sixthClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:6)))
                // 配列
                let timeline = Timeline(entries: entries, policy: .after(todayUpdateTime))
                completion(timeline)
            })
        }else{
            //            print("今日の更新時間以降")
            // 今が19時以降の場合。明日の予定を表示&次表示を更新するのは明日の19時以降
            
            // 更新タイムラインの日付を明日にする
            firstClassTimeComponent.day = firstClassTimeComponent.day! + 1;
            secondClassTimeComponent.day = secondClassTimeComponent.day! + 1;
            thirdClassTimeComponent.day = thirdClassTimeComponent.day! + 1;
            fourthClassTimeComponent.day = fourthClassTimeComponent.day! + 1;
            fifthClassTimeComponent.day = fifthClassTimeComponent.day! + 1;
            sixthClassTimeComponent.day = sixthClassTimeComponent.day! + 1;
            
            // 明日の更新時間の定義。（前述の更新時間に一日を加えたもの）
            let tomorrowUpdateTime = Calendar.current.date(byAdding: .day, value: 1, to: todayUpdateTime)!
            modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            fetchAPI(date: getday(format:"yyyy-MM-dd"),completion: {(todayInformationList) in
                var entries: [SimpleEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                entries.append(SimpleEntry(date: Date(), FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:0)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: firstClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:1)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: secondClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:2)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: thirdClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:3)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: fourthClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:4)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: fifthClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:5)))
                entries.append(SimpleEntry(date: Calendar(identifier: .gregorian).date(from: sixthClassTimeComponent)!, FinalInformationList: smallWidgetNowAndNextClass(arg:todayInformationList,period:6)))
                // 配列
                let timeline = Timeline(entries: entries, policy: .after(tomorrowUpdateTime))
                completion(timeline)
            })
        }
    }
}

// 今日の授業情報を受け取って、指定された時限をLecture[0]に、次に予定されている授業を[1]に格納して返却
// periodが0の時は1限が始まる前なので、Lecture[0]は授業がありません、Lecture[1]を1限にする
func smallWidgetNowAndNextClass(arg:FinalInformationList,period:Int) -> FinalInformationList{
    let LecturesList:[Lecture] = arg.Lectures;
    var returnLecturesList:[Lecture] = [];
    
    for i in period ... arg.Lectures.count{
        if i >= arg.Lectures.count {
            returnLecturesList.insert(Lecture(period: 0, name: "授業がありません", room: "-"), at: 0);
            break;
        }else{
            if arg.Lectures[i].name != "授業がありません" {
                returnLecturesList.insert(LecturesList[i], at: 0);
                break;
            }
        }
    }
    
    
    return FinalInformationList(Lectures: returnLecturesList, description: arg.description, changeTo: arg.changeTo, module: arg.module,lectureCounter: arg.lectureCounter);
}

struct smallWidgetEntryView : View {
    let twintePrimaryColor = Color("PrimaryColor");
    let textDefaultColor = Color("WidgetMainText");
    let widgetBaseColor = Color("WidgetBackground");
    let noneLectureColor = Color("WidgetNoneText");
    let widgetRoomScheduleColor = Color("WidgetSubText");
    @Environment(\.colorScheme) var colorScheme
    var entry: smallWidgetProvider.Entry
    
    var body: some View {
        // 「現在の時限: 授業がある, 現在以降の時限: 授業がある」のライトモードのデザインデータ
        
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.FinalInformationList.module) \(getday(format:"MM/dd(EEE)"))")
                    .fontWeight(.bold)
                    .font(.subheadline)
                    .foregroundColor(textDefaultColor)
                    .lineSpacing(19.60)
                    //                    .frame(width: .infinity,alignment:.leading)
                    .lineLimit(1)
                
                if entry.FinalInformationList.description != "" {
                    Text(entry.FinalInformationList.description)
                        .font(.caption)
                        .foregroundColor(textDefaultColor)
                        .lineSpacing(16.80)
                        .frame(width: .infinity,alignment:.leading)
                        .lineLimit(1)
                }else if entry.FinalInformationList.changeTo == "" {
                    Text("通常日課")
                        .font(.caption)
                        .foregroundColor(textDefaultColor)
                        .lineSpacing(16.80)
                        //                        .frame(width: .infinity,alignment:.leading)
                        .lineLimit(1)
                }
                else{
                    HStack(alignment: .top, spacing: 0) {
                        Text(entry.FinalInformationList.changeTo)
                            .fontWeight(.bold)
                            .font(.caption)
                            .foregroundColor(Color(red: 232/256, green: 127/256, blue: 147/256))
                            .lineSpacing(16.80)
                            //.frame(width: 105,alignment:.leading)
                            .lineLimit(1)
                        Text("日課")
                            .font(.caption)
                            .foregroundColor(Color(red: 232/256, green: 127/256, blue: 147/256))
                            .lineSpacing(16.80)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("次の授業")
                        .fontWeight(.medium)
                        .font(.caption2)
                        .lineSpacing(14)
                        .foregroundColor(textDefaultColor)
                    
                    if colorScheme == .dark {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black)
                            .frame(maxWidth: 110, maxHeight: 5, alignment:.leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(widgetBaseColor,lineWidth: 1)
                                    .shadow(color: Color.white, radius: 2, x: 0, y: 5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .shadow(color: Color(red: 31/256, green: 45/256, blue: 58/256), radius: 2, x: -2, y: -2.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            )
                    }else{
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(maxWidth: 110, maxHeight: 5, alignment:.leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(widgetBaseColor,lineWidth: 1)
                                    .shadow(color: Color.white, radius: 2, x: 5, y: 5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .shadow(color: Color(red: 132/256, green: 167/256, blue: 188/256), radius: 2, x: -2, y: -2.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 3) {
                    if entry.FinalInformationList.Lectures[0].name == "授業がありません"{
                        Text(entry.FinalInformationList.Lectures[0].name)
                            .fontWeight(.medium)
                            .font(.caption)
                            .foregroundColor(noneLectureColor)
                            .lineSpacing(16.80)
                            .lineLimit(1)
                            .frame(width: 150, alignment: .leading)
                    }else{
                        Text(entry.FinalInformationList.Lectures[0].name)
                            .fontWeight(.medium)
                            .font(.caption)
                            .foregroundColor(textDefaultColor)
                            .lineSpacing(16.80)
                            .lineLimit(1)
                            .frame(width: 150, alignment: .leading)
                    }
                    
                    HStack(alignment: .top, spacing: 4) {
                        HStack(alignment: .top, spacing: 2) {
                            if entry.FinalInformationList.Lectures[0].name == "授業がありません"{
                                if colorScheme == .dark {
                                    Image("room-dark-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }else{
                                    Image("room-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }
                                Text(entry.FinalInformationList.Lectures[0].room)
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
                                Text(entry.FinalInformationList.Lectures[0].room)
                                    .font(.caption2)
                                    .foregroundColor(widgetRoomScheduleColor)
                                    .lineSpacing(14)
                                    .lineLimit(1)
                                    .frame(width: 60,alignment:.leading)
                            }
                            
                        }
                        
                        HStack(alignment: .top, spacing: 2) {
                            if entry.FinalInformationList.Lectures[0].name == "授業がありません"{
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
                                Text(LectureStartTime(number: entry.FinalInformationList.Lectures[0].period))
                                    .font(.caption2)
                                    .foregroundColor(widgetRoomScheduleColor)
                                    .lineSpacing(14)
                                    .lineLimit(1)
                                    .frame(width: 40,alignment:.leading)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .padding(.leading, 10)
        //        .frame(width: .infinity, height: .infinity)
        .background(widgetBaseColor)
        .cornerRadius(21.67)
    }
}


struct smallWidget: Widget {
    let kind: String = "smallWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: smallWidgetProvider()) { entry in
            smallWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Twin:te")
        .description("今日の日課と次の授業を表示します")
        .supportedFamilies([.systemSmall])
    }
}

struct smallWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFinalInformationList:FinalInformationList = FinalInformationList(Lectures: [
            Lecture(period:1,name:"授業がありません",room: "-"),
            Lecture(period:2,name:"内科系スポーツ医学演習",room: "3C213"),
            Lecture(period:3,name:"発展体育シューティングスポーツ",room: "1H201"),
            Lecture(period:4,name:"インド仏教思想",room: "第3体育館"),
            Lecture(period:5,name:"情報社会と法制度",room: "GBAE12345567889"),
            Lecture(period:6,name:"寺子屋実習",room: "東京あ江戸あいうえお博物館"),
        ], description: "", changeTo: "水曜", module: "春AB",lectureCounter:0)
        
        smallWidgetEntryView(entry: SimpleEntry(date: Date(), FinalInformationList: sampleFinalInformationList))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        //            .environment(\.colorScheme, .dark)
    }
}
