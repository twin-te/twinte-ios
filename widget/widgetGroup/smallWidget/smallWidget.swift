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
    
    func placeholder(in context: Context) -> smallWidgetDayInfoEntry {
        smallWidgetDayInfoEntry(date: Date(),lectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)],lectureAllInfo: sampleWidgetAllInfo)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (smallWidgetDayInfoEntry) -> ()) {
        let entry = smallWidgetDayInfoEntry(date: Date(),lectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)],lectureAllInfo: sampleWidgetAllInfo)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<smallWidgetDayInfoEntry>) -> Void) {
        Task{
            await createTimeline()
        }
        @Sendable func createTimeline() async{
            // 各授業時間開始時刻+30分の定義（ウィジェットの更新時間）
            let todayFirstClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 9, minute: 10, second: 0, of: Date())!
            let todaySecondClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 10, minute: 40, second: 0, of: Date())!
            let todayThirdClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 12, minute: 45, second: 0, of: Date())!
            let todayFourthClassTime = Calendar(identifier: .gregorian).date(bySettingHour:14, minute: 15, second: 0, of: Date())!
            let todayFifthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 15, minute: 45, second: 0, of: Date())!
            let todaySixthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 17, minute: 15, second: 0, of: Date())!
            // 今日の19:00の定義（今日の更新タイミング）
            let todayUpdateTime = Calendar(identifier: .gregorian).date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
            if(Date() < todayUpdateTime){
                // 今が19時以前の場合。今日の予定を表示&次表示を更新するのは今日の19時以降
                let todayClassUpdateTimes = [todayFirstClassTime,todaySecondClassTime,todayThirdClassTime,todayFourthClassTime,todayFifthClassTime,todaySixthClassTime]
                let widgetInfo = WidgetInfo()
                let todayWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if(todayWidgetAllInfo.error){
                    let entries: [smallWidgetDayInfoEntry] = [
                        smallWidgetDayInfoEntry(date: Date(),lectureInfo: WidgetInfo.Lecture(period: 1, startTime: "", name: todayWidgetAllInfo.event.content, room: "", exist: false),lectureAllInfo: todayWidgetAllInfo)
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute,value: 10, to: Date())!))
                    completion(timeline)
                }
                
                var entries: [smallWidgetDayInfoEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                var todayExistLectures:[WidgetInfo.Lecture] = todayWidgetAllInfo.lectures.filter{$0.exist}
                let todayLastPeriod = (todayExistLectures.last?.period ?? 0) + 1
                todayExistLectures.append(WidgetInfo.Lecture(period: todayLastPeriod, startTime: "-", name: "授業がありません", room: "-", exist: false))
                for todayExistLecturesIndex in 0..<todayExistLectures.count {
                    if(todayExistLecturesIndex == 0){
                        // 最初の授業が始まる前ならすぐに最初の授業の情報(or授業が全くない旨)を表示する．
                        if(Date() < todayClassUpdateTimes[todayExistLectures[0].period - 1] || !todayExistLectures[0].exist){
                            entries.append(smallWidgetDayInfoEntry(date: Date(),lectureInfo: todayExistLectures[0],lectureAllInfo: todayWidgetAllInfo))
                        }
                    }else{
                        let todayClassUpdateTimesIndex = todayExistLectures[todayExistLecturesIndex].period - 2
                        entries.append(smallWidgetDayInfoEntry(date: todayClassUpdateTimes[todayClassUpdateTimesIndex],
                                                               lectureInfo: todayExistLectures[todayExistLecturesIndex],lectureAllInfo: todayWidgetAllInfo))
                    }
                }
                let timeline = Timeline(entries: entries, policy: .after(todayUpdateTime))
                completion(timeline)
            }else{
                // 今が19時以降の場合。明日の予定を表示&次表示を更新するのは明日の19時以降
                // 更新タイムラインの日付を明日にする
                let tommorowFirstClassTime = Calendar.current.date(byAdding: .day,value: 1, to: todayFirstClassTime)!
                let tommorowSecondClassTime = Calendar.current.date(byAdding: .day,value: 1, to: todaySecondClassTime)!
                let tommorowThirdClassTime = Calendar.current.date(byAdding: .day,value: 1, to: todayThirdClassTime)!
                let tommorowFourthClassTime = Calendar.current.date(byAdding: .day,value: 1, to: todayFourthClassTime)!
                let tommorowFifthClassTime = Calendar.current.date(byAdding: .day,value: 1, to: todayFifthClassTime)!
                let tommorowSixthClassTime = Calendar.current.date(byAdding: .day,value: 1, to: todaySixthClassTime)!
                let tommorowClassUpdateTimes = [tommorowFirstClassTime,tommorowSecondClassTime,tommorowThirdClassTime,tommorowFourthClassTime,tommorowFifthClassTime,tommorowSixthClassTime]
                
                let widgetInfo = WidgetInfo()
                widgetInfo.updateDate(newDate: Calendar.current.date(byAdding: .day, value: 1, to: widgetInfo.date)!)
                let tommorowWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if(tommorowWidgetAllInfo.error){
                    let entries: [smallWidgetDayInfoEntry] = [
                        smallWidgetDayInfoEntry(date: Date(),lectureInfo: WidgetInfo.Lecture(period: 1, startTime: "", name: tommorowWidgetAllInfo.event.content, room: "", exist: false),lectureAllInfo: tommorowWidgetAllInfo)
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute,value: 10, to: Date())!))
                    completion(timeline)
                }
                
                var entries: [smallWidgetDayInfoEntry] = []
                var tommorowExistLectures:[WidgetInfo.Lecture] = tommorowWidgetAllInfo.lectures.filter{$0.exist}
                let tommorowLastPeriod = (tommorowExistLectures.last?.period ?? 0) + 1
                tommorowExistLectures.append(WidgetInfo.Lecture(period: tommorowLastPeriod, startTime: "-", name: "授業がありません", room: "-", exist: false))
                for tommorowExistLecturesIndex in 0..<tommorowExistLectures.count {
                    if(tommorowExistLecturesIndex == 0){
                        entries.append(smallWidgetDayInfoEntry(date: Date(),
                                                               lectureInfo: tommorowExistLectures[tommorowExistLecturesIndex],lectureAllInfo: tommorowWidgetAllInfo))
                    }else{
                        let tommorowClassUpdateTimesIndex = tommorowExistLectures[tommorowExistLecturesIndex].period - 2
                        entries.append(smallWidgetDayInfoEntry(date: tommorowClassUpdateTimes[tommorowClassUpdateTimesIndex],
                                                               lectureInfo: tommorowExistLectures[tommorowExistLecturesIndex],lectureAllInfo: tommorowWidgetAllInfo))
                    }
                }
                // 明日の更新時間の定義。（前述の更新時間に一日を加えたもの）
                let tomorrowUpdateTime = Calendar.current.date(byAdding: .day, value: 1, to: todayUpdateTime)!
                let timeline = Timeline(entries: entries, policy: .after(tomorrowUpdateTime))
                completion(timeline)
            }
        }
    }
}

struct smallWidgetDayInfoEntry: TimelineEntry {
    let date: Date
    let lectureInfo: WidgetInfo.Lecture
    let lectureAllInfo: WidgetInfo.WidgetAllInfo
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
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.lectureAllInfo.module + " " + entry.lectureAllInfo.day)
                    .fontWeight(.bold)
                    .font(.subheadline)
                    .foregroundColor(textDefaultColor)
                    .lineSpacing(19.60)
                    .lineLimit(1)
                Text(entry.lectureAllInfo.event.content)
                    .fontWeight(entry.lectureAllInfo.event.normal ? .regular : .bold)
                    .font(.caption)
                    .lineSpacing(16.80)
                    .lineLimit(1)
                    .foregroundColor(entry.lectureAllInfo.event.normal ? textDefaultColor : Color(red: 232/256, green: 127/256, blue: 147/256))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("次の授業")
                        .fontWeight(.medium)
                        .font(.caption2)
                        .lineSpacing(14)
                        .foregroundColor(textDefaultColor)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme == .dark ? Color.black : Color.white)
                        .frame(maxWidth: 110, maxHeight: 5, alignment:.leading)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(widgetBaseColor,lineWidth: 1)
                                .shadow(color: Color.white, radius: 2, x: 0, y: 5)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .shadow(color: colorScheme == .dark ? Color(red: 31/256, green: 45/256, blue: 58/256) : Color(red: 132/256, green: 167/256, blue: 188/256), radius: 2, x: -2, y: -2.5)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        )
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.lectureInfo.name)
                        .fontWeight(.medium)
                        .font(.caption)
                        .foregroundColor(entry.lectureInfo.exist ? textDefaultColor : noneLectureColor)
                        .lineSpacing(16.80)
                        .lineLimit(1)
                        .frame(width: 150, alignment: .leading)
                    
                    HStack(alignment: .top, spacing: 4) {
                        HStack(alignment: .top, spacing: 2) {
                            if(colorScheme == .dark) {
                                Image(entry.lectureInfo.exist ? "room-dark" : "room-dark-disabled")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                            }else{
                                Image(entry.lectureInfo.exist ? "room" : "room-disabled")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                            }
                            Text(entry.lectureInfo.room)
                                .font(.caption2)
                                .foregroundColor(entry.lectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                .lineSpacing(14)
                                .lineLimit(1)
                                .frame(width: 60,alignment:.leading)
                        }
                        
                        HStack(alignment: .top, spacing: 2) {
                            if(colorScheme == .dark) {
                                Image(entry.lectureInfo.exist ? "schedule-dark" : "schedule-dark-disabled")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                            }else{
                                Image(entry.lectureInfo.exist ? "schedule" : "schedule-disabled")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                            }
                            Text(entry.lectureInfo.startTime)
                                .font(.caption2)
                                .foregroundColor(entry.lectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                .lineSpacing(14)
                                .lineLimit(1)
                                .frame(width: 30,alignment:.leading)
                        }
                    }
                }
            }
        }
        .padding()
        .padding(.leading, 10)
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
        
        smallWidgetEntryView(entry: smallWidgetDayInfoEntry(date: Date(),lectureInfo: sampleWidgetAllInfo.lectures[0], lectureAllInfo: sampleWidgetAllInfo))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

