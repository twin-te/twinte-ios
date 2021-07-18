//
//  largeWidget.swift
//  largeWidget
//
//  Created by tako on 2021/03/29.
//  Copyright © 2021 tako. All rights reserved.
//

import WidgetKit
import SwiftUI



struct largeWidgetProvider: TimelineProvider {
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



struct largeWidgetEntryView : View {
    var entry: largeWidgetProvider.Entry
    let twintePrimaryColor = Color("PrimaryColor");
    let textDefaultColor = Color("WidgetMainText");
    let widgetBaseColor = Color("WidgetBackground");
    let noneLectureColor = Color("WidgetNoneText");
    let widgetRoomScheduleColor = Color("WidgetSubText");
    @Environment(\.widgetFamily) var family: WidgetFamily
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        switch family {
        
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
                        HStack(alignment: .top, spacing: 0) {
                            Text(entry.FinalInformationList.changeTo)
                                .fontWeight(.bold)
                                .font(.caption)
                                .foregroundColor(Color(red: 232/256, green: 127/256, blue: 147/256))
                                .lineSpacing(16.80)
                                .lineLimit(1)
                            Text("日課")
                                .font(.caption)
                                .foregroundColor(Color(red: 232/256, green: 127/256, blue: 147/256))
                                .lineSpacing(16.80)
                                .lineLimit(1)
                        }
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


struct largeWidget: Widget {
    let kind: String = "largeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: largeWidgetProvider()) { entry in
            largeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Twin:te")
        .description("今日の時間割を表示します")
        .supportedFamilies([.systemLarge])
    }
}

struct largeWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFinalInformationList:FinalInformationList = FinalInformationList(Lectures: [
            Lecture(period:1,name:"授業がありません",room: "-"),
            Lecture(period:2,name:"内科系スポーツ医学演習",room: "3C213"),
            Lecture(period:3,name:"発展体育シューティングスポーツ",room: "1H201"),
            Lecture(period:4,name:"インド仏教思想",room: "第3体育館"),
            Lecture(period:5,name:"情報社会と法制度",room: "GBAE12345567889"),
            Lecture(period:6,name:"寺子屋実習",room: "東京あ江戸あいうえお博物館"),
        ], description: "", changeTo: "", module: "",lectureCounter:0)
        
        
        largeWidgetEntryView(entry: SimpleEntry(date: Date(), FinalInformationList: sampleFinalInformationList))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
