//
//  lockScreenWidget.swift
//  lockScreenWidget
//
//  Created by takonasu on 2022/10/11.
//  Copyright © 2022 tako. All rights reserved.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DayInfoEntry {
        DayInfoEntry(date: Date(), lectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)])
    }

    func getSnapshot(in context: Context, completion: @escaping (DayInfoEntry) -> Void) {
        let entry = DayInfoEntry(date: Date(), lectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayInfoEntry>) -> Void) {
        Task {
            await createTimeline()
        }
        @Sendable func createTimeline() async {
            // 各授業時間開始時刻+30分の定義（ウィジェットの更新時間）
            let todayFirstClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 9, minute: 10, second: 0, of: Date())!
            let todaySecondClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 10, minute: 40, second: 0, of: Date())!
            let todayThirdClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 12, minute: 45, second: 0, of: Date())!
            let todayFourthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 14, minute: 15, second: 0, of: Date())!
            let todayFifthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 15, minute: 45, second: 0, of: Date())!
            let todaySixthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 17, minute: 15, second: 0, of: Date())!
            // 今日の19:00の定義（今日の更新タイミング）
            let todayUpdateTime = Calendar(identifier: .gregorian).date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
            if Date() < todayUpdateTime {
                // 今が19時以前の場合。今日の予定を表示&次表示を更新するのは今日の19時以降
                let todayClassUpdateTimes = [todayFirstClassTime, todaySecondClassTime, todayThirdClassTime, todayFourthClassTime, todayFifthClassTime, todaySixthClassTime]
                let widgetInfo = WidgetInfo()
                let todayWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if todayWidgetAllInfo.error {
                    let entries: [DayInfoEntry] = [
                        DayInfoEntry(date: Date(), lectureInfo: .content(period: 1, name: todayWidgetAllInfo.event.content)),
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 10, to: Date())!))
                    completion(timeline)
                }

                var entries: [DayInfoEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                var todayExistLectures: [WidgetInfo.Lecture] = todayWidgetAllInfo.lectures.filter { $0.exist }
                let todayLastPeriod = (todayExistLectures.last?.period ?? 0) + 1
                todayExistLectures.append(.empty(period: todayLastPeriod))
                for todayExistLecturesIndex in 0..<todayExistLectures.count {
                    if todayExistLecturesIndex == 0 {
                        // 最初の授業が始まる前ならすぐに最初の授業の情報(or授業が全くない旨)を表示する．
                        if Date() < todayClassUpdateTimes[todayExistLectures[0].period - 1] || !todayExistLectures[0].exist {
                            entries.append(DayInfoEntry(date: Date(), lectureInfo: todayExistLectures[0]))
                        }
                    } else {
                        let todayClassUpdateTimesIndex = todayExistLectures[todayExistLecturesIndex].period - 2
                        entries.append(DayInfoEntry(date: todayClassUpdateTimes[todayClassUpdateTimesIndex],
                                                    lectureInfo: todayExistLectures[todayExistLecturesIndex]))
                    }
                }
                let timeline = Timeline(entries: entries, policy: .after(todayUpdateTime))
                completion(timeline)
            } else {
                // 今が19時以降の場合。明日の予定を表示&次表示を更新するのは明日の19時以降
                // 更新タイムラインの日付を明日にする
                let tommorowFirstClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayFirstClassTime)!
                let tommorowSecondClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todaySecondClassTime)!
                let tommorowThirdClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayThirdClassTime)!
                let tommorowFourthClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayFourthClassTime)!
                let tommorowFifthClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayFifthClassTime)!
                let tommorowSixthClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todaySixthClassTime)!
                let tommorowClassUpdateTimes = [tommorowFirstClassTime, tommorowSecondClassTime, tommorowThirdClassTime, tommorowFourthClassTime, tommorowFifthClassTime, tommorowSixthClassTime]

                let widgetInfo = WidgetInfo()
                widgetInfo.updateDate(newDate: Calendar.current.date(byAdding: .day, value: 1, to: widgetInfo.date)!)
                let tommorowWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if tommorowWidgetAllInfo.error {
                    let entries: [DayInfoEntry] = [
                        DayInfoEntry(date: Date(), lectureInfo: .content(period: 1, name: tommorowWidgetAllInfo.event.content)),
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 10, to: Date())!))
                    completion(timeline)
                }

                var entries: [DayInfoEntry] = []
                var tommorowExistLectures: [WidgetInfo.Lecture] = tommorowWidgetAllInfo.lectures.filter { $0.exist }
                let tommorowLastPeriod = (tommorowExistLectures.last?.period ?? 0) + 1
                tommorowExistLectures.append(.empty(period: tommorowLastPeriod))
                for tommorowExistLecturesIndex in 0..<tommorowExistLectures.count {
                    if tommorowExistLecturesIndex == 0 {
                        entries.append(DayInfoEntry(date: Date(),
                                                    lectureInfo: tommorowExistLectures[tommorowExistLecturesIndex]))
                    } else {
                        let tommorowClassUpdateTimesIndex = tommorowExistLectures[tommorowExistLecturesIndex].period - 2
                        entries.append(DayInfoEntry(date: tommorowClassUpdateTimes[tommorowClassUpdateTimesIndex],
                                                    lectureInfo: tommorowExistLectures[tommorowExistLecturesIndex]))
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

struct DayInfoEntry: TimelineEntry {
    let date: Date
    let lectureInfo: WidgetInfo.Lecture
}

struct lockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            ZStack {
                Color.white.opacity(0.12)
                Image("twinteIcon")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(entry.lectureInfo.name)
                        .lineLimit(1)
                        .fontWeight(.semibold)
                    Spacer()
                }
                HStack(spacing: 3) {
                    Image("room")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text(entry.lectureInfo.room)
                        .lineLimit(1)
                    Spacer()
                }
                HStack(spacing: 3) {
                    Image("schedule")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text(entry.lectureInfo.startTime)
                    Spacer()
                }
            }
        case .accessoryInline:
            entry.lectureInfo.exist ?
                Text(entry.lectureInfo.room + " " + entry.lectureInfo.name)
                :
                Text(entry.lectureInfo.name)
        default:
            Text("Not implemented")
        }
    }
}

@main
struct lockScreenWidget: Widget {
    let kind: String = "lockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            lockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Twin:te")
        .description("次の授業を表示します")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct lockScreenWidget_Previews: PreviewProvider {
    static var previews: some View {
        lockScreenWidgetEntryView(entry: DayInfoEntry(date: Date(), lectureInfo: sampleWidgetAllInfo.lectures[0]))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName("Inline")

        lockScreenWidgetEntryView(entry: DayInfoEntry(date: Date(), lectureInfo: sampleWidgetAllInfo.lectures[0]))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")

        lockScreenWidgetEntryView(entry: DayInfoEntry(date: Date(), lectureInfo: sampleWidgetAllInfo.lectures[0]))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular")
    }
}
