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
    let sampleWidgetAllInfo = WidgetInfo.WidgetAllInfo(
        day: getDate(), module: "春A", event: WidgetInfo.WidgetAllInfo.Event(normal: false, content: "水曜日日課"), lectures: [
            WidgetInfo.Lecture(period:1, startTime: "8:40",name:"つくば市史概論",room: "1B202",exist: true),
            WidgetInfo.Lecture(period:2, startTime: "10:10",name:"基礎ネコ語AII",room: "平砂宿舎",exist: true),
            WidgetInfo.Lecture(period:3, startTime: "12:15",name:"授業がありません",room: "-",exist: false),
            WidgetInfo.Lecture(period:4, startTime: "13:45",name:"筑波大学〜野草と食〜",room: "4C213",exist: true),
            WidgetInfo.Lecture(period:5, startTime: "15:15",name:"東京教育大学の遺産",room: "春日講堂",exist: true),
            WidgetInfo.Lecture(period:6, startTime: "16:45",name:"日常系作品の実際",room: "オンライン",exist: true),
        ], lectureCount: 5, error: false
    )
    
    func placeholder(in context: Context) -> largeWidgetDayInfoEntry {
        largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: sampleWidgetAllInfo)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (largeWidgetDayInfoEntry) -> ()) {
        let entry = largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: sampleWidgetAllInfo)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<largeWidgetDayInfoEntry>) -> ()) {
        Task{
            await createTimeline()
        }
        @Sendable func createTimeline() async{
            // 今日の19:00の定義（今日の更新タイミング）
            let todayUpdateTime = Calendar(identifier: .gregorian).date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
            if(Date() < todayUpdateTime){
                // 今が19時以前の場合。今日の予定を表示&次表示を更新するのは今日の19時以降
                let widgetInfo = WidgetInfo()
                let todayWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if(todayWidgetAllInfo.error){
                    let entries: [largeWidgetDayInfoEntry] = [
                        largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: todayWidgetAllInfo)
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute,value: 10, to: Date())!))
                    completion(timeline)
                }
                let entries: [largeWidgetDayInfoEntry] = [
                    largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: todayWidgetAllInfo)
                ]
                let timeline = Timeline(entries: entries, policy: .after(todayUpdateTime))
                completion(timeline)
            }else{
                // 今が19時以降の場合。明日の予定を表示&次表示を更新するのは明日の19時以降
                let widgetInfo = WidgetInfo()
                widgetInfo.updateDate(newDate: Calendar.current.date(byAdding: .day, value: 1, to: widgetInfo.date)!)
                let tommorowWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if(tommorowWidgetAllInfo.error){
                    let entries: [largeWidgetDayInfoEntry] = [
                        largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: tommorowWidgetAllInfo)
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute,value: 10, to: Date())!))
                    completion(timeline)
                }
                let entries: [largeWidgetDayInfoEntry] = [
                    largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: tommorowWidgetAllInfo)
                ]
                // 明日の更新時間の定義。（前述の更新時間に一日を加えたもの）
                let tomorrowUpdateTime = Calendar.current.date(byAdding: .day, value: 1, to: todayUpdateTime)!
                let timeline = Timeline(entries: entries, policy: .after(tomorrowUpdateTime))
                completion(timeline)
            }
        }
    }
}

struct largeWidgetDayInfoEntry: TimelineEntry {
    let date: Date
    let lectureAllInfo: WidgetInfo.WidgetAllInfo
}

struct largeWidgetEntryView : View {
    let entry: largeWidgetProvider.Entry
    let twintePrimaryColor = Color("PrimaryColor");
    let textDefaultColor = Color("WidgetMainText");
    let widgetBaseColor = Color("WidgetBackground");
    let noneLectureColor = Color("WidgetNoneText");
    let widgetRoomScheduleColor = Color("WidgetSubText");
    @Environment(\.widgetFamily) var family: WidgetFamily
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.lectureAllInfo.module + " " + entry.lectureAllInfo.day)
                    .fontWeight(.bold)
                    .font(.subheadline)
                    .foregroundColor(textDefaultColor)
                    .lineSpacing(19.60)
                    .frame(width: 120,alignment:.leading)
                    .lineLimit(1)
                
                Text(entry.lectureAllInfo.event.content)
                    .fontWeight(entry.lectureAllInfo.event.normal ? .regular : .bold)
                    .font(.caption)
                    .foregroundColor(entry.lectureAllInfo.event.normal ? textDefaultColor : Color(red: 232/256, green: 127/256, blue: 147/256))
                    .lineSpacing(16.80)
                    .frame(width: 105,alignment:.leading)
                    .lineLimit(1)
                
                Text("\(String(entry.lectureAllInfo.lectureCount))コマの授業")
                    .font(.caption)
                    .lineSpacing(16.80)
                    .foregroundColor(twintePrimaryColor)
            }
            .padding(.leading, 20)
            .padding(.top, 20)
            
            VStack(spacing: 0){
                ForEach(entry.lectureAllInfo.lectures, id: \.hashValue) {lectureInfo in
                    HStack(spacing: 8) {
                        Text(String(lectureInfo.period))
                            .fontWeight(.medium)
                            .font(.subheadline)
                            .foregroundColor(textDefaultColor)
                            .lineSpacing(21)
                            .frame(width: 10)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            
                            Text(lectureInfo.name)
                                .fontWeight(.medium)
                                .font(.caption)
                                .foregroundColor(lectureInfo.exist ? textDefaultColor : noneLectureColor)
                                .lineSpacing(16.80)
                                .lineLimit(1)
                                .frame(width: 130, alignment: .leading)
                            
                            HStack(alignment: .top, spacing: 4) {
                                HStack(alignment: .center, spacing: 2) {
                                    if(lectureInfo.exist){
                                        Image(colorScheme == .dark ? "room-dark" : "room")
                                            .resizable()
                                            .frame(width: 14, height: 14)
                                    }else{
                                        Image(colorScheme == .dark ? "room-dark-disabled" : "room-disabled")
                                            .resizable()
                                            .frame(width: 14, height: 14)
                                    }
                                    Text(lectureInfo.room)
                                        .font(.caption2)
                                        .foregroundColor(lectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                        .lineSpacing(14)
                                        .lineLimit(1)
                                        .frame(width: 60,alignment:.leading)
                                    
                                    HStack(alignment: .center, spacing: 2) {
                                        if(lectureInfo.exist){
                                            Image(colorScheme == .dark ? "schedule-dark" : "schedule")
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        }else{
                                            Image(colorScheme == .dark ? "schedule-dark-disabled" : "schedule-disabled")
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        }
                                        Text(lectureInfo.startTime)
                                            .font(.caption2)
                                            .foregroundColor(lectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                            .lineSpacing(14)
                                            .lineLimit(1)
                                            .frame(width: 40,alignment:.leading)
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
                }}
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
        let sampleWidgetAllInfo = WidgetInfo.WidgetAllInfo(
            day: getDate(), module: "秋A", event: WidgetInfo.WidgetAllInfo.Event(normal: true, content: "通常日課"), lectures: [
                WidgetInfo.Lecture(period:1, startTime: "8:40",name:"つくば市史概論",room: "1B202",exist: true),
                WidgetInfo.Lecture(period:2, startTime: "10:10",name:"基礎ネコ語AII",room: "平砂宿舎",exist: true),
                WidgetInfo.Lecture(period:3, startTime: "12:15",name:"授業がありません",room: "-",exist: false),
                WidgetInfo.Lecture(period:4, startTime: "13:45",name:"筑波大学〜野草と食〜",room: "4C213",exist: true),
                WidgetInfo.Lecture(period:5, startTime: "15:15",name:"東京教育大学の遺産",room: "春日講堂",exist: true),
                WidgetInfo.Lecture(period:6, startTime: "16:45",name:"日常系作品の実際",room: "オンライン",exist: true),
            ], lectureCount: 5,error: false
        )
        
        largeWidgetEntryView(entry: largeWidgetDayInfoEntry(date: Date(),lectureAllInfo: sampleWidgetAllInfo))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
