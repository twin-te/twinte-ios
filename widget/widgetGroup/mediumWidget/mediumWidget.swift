//
//  mediumWidget.swift
//  mediumWidget
//
//  Created by tako on 2021/05/03.
//  Copyright © 2021 tako. All rights reserved.
//

import SwiftUI
import WidgetKit

struct mediumWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> mediumWidgetDayInfoEntry {
        mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)], nextLectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)], lectureAllInfo: sampleWidgetAllInfo)
    }

    func getSnapshot(in context: Context, completion: @escaping (mediumWidgetDayInfoEntry) -> Void) {
        let entry = mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)], nextLectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)], lectureAllInfo: sampleWidgetAllInfo)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            await createTimeline()
        }
        @Sendable func createTimeline() async {
            // 各授業時間開始時刻の定義
            let todayFirstClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 8, minute: 40, second: 0, of: Date())!
            let todaySecondClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 10, minute: 10, second: 0, of: Date())!
            let todayThirdClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 12, minute: 15, second: 0, of: Date())!
            let todayFourthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 13, minute: 45, second: 0, of: Date())!
            let todayFifthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 15, minute: 15, second: 0, of: Date())!
            let todaySixthClassTime = Calendar(identifier: .gregorian).date(bySettingHour: 16, minute: 45, second: 0, of: Date())!
            let todaySixthClassEndTime = Calendar(identifier: .gregorian).date(bySettingHour: 18, minute: 00, second: 0, of: Date())!
            // 今日の19:00の定義（今日の更新タイミング）
            let todayUpdateTime = Calendar(identifier: .gregorian).date(bySettingHour: 19, minute: 0, second: 0, of: Date())!

            if Date() < todayUpdateTime {
                // 今が19時以前の場合。今日の予定を表示&次表示を更新するのは今日の19時以降
                let todayClassUpdateTimes = [todayFirstClassTime, todaySecondClassTime, todayThirdClassTime, todayFourthClassTime, todayFifthClassTime, todaySixthClassTime, todaySixthClassEndTime]
                let widgetInfo = WidgetInfo()
                let todayWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if todayWidgetAllInfo.error {
                    let entries: [mediumWidgetDayInfoEntry] = [
                        mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: .content(period: 1, name: todayWidgetAllInfo.event.content), nextLectureInfo: .content(period: 1, name: todayWidgetAllInfo.event.content), lectureAllInfo: todayWidgetAllInfo),
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 10, to: Date())!))
                    completion(timeline)
                }

                var entries: [mediumWidgetDayInfoEntry] = []
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                var todayExistLectures: [WidgetInfo.Lecture] = todayWidgetAllInfo.lectures.filter { $0.exist }
                todayExistLectures.insert(.empty(period: 0), at: 0)
                let todayLastPeriod = (todayExistLectures.last?.period ?? 0) + 1
                todayExistLectures.append(.empty(period: todayLastPeriod))
                for todayExistLecturesIndex in 0..<todayExistLectures.count {
                    if todayExistLecturesIndex == 0 {
                        // 最初の授業が始まる前ならすぐに最初の授業の情報(or授業が全くない旨)を表示する．
                        if Date() < todayClassUpdateTimes[todayExistLectures[1].period - 1] {
                            entries.append(mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: todayExistLectures[0], nextLectureInfo: todayExistLectures[1], lectureAllInfo: todayWidgetAllInfo))
                        }
                    } else {
                        let todayNowClassUpdateTimesIndex = todayExistLectures[todayExistLecturesIndex].period - 1
                        if todayExistLecturesIndex + 1 < todayExistLectures.count {
                            entries.append(mediumWidgetDayInfoEntry(date: todayClassUpdateTimes[todayNowClassUpdateTimesIndex], nowLectureInfo: todayExistLectures[todayExistLecturesIndex], nextLectureInfo: todayExistLectures[todayExistLecturesIndex + 1], lectureAllInfo: todayWidgetAllInfo))
                        } else {
                            entries.append(mediumWidgetDayInfoEntry(date: todayClassUpdateTimes[todayNowClassUpdateTimesIndex], nowLectureInfo: .empty(period: todayLastPeriod), nextLectureInfo: .empty(period: todayLastPeriod), lectureAllInfo: todayWidgetAllInfo))
                        }
                    }
                }
                let timeline = Timeline(entries: entries, policy: .after(todayUpdateTime))
                completion(timeline)
            } else {
                // 今が19時以降の場合。明日の予定を表示&次表示を更新するのは明日の19時以降
                // 更新タイムラインの日付を明日にする
                let tomorrowFirstClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayFirstClassTime)!
                let tomorrowSecondClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todaySecondClassTime)!
                let tomorrowThirdClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayThirdClassTime)!
                let tomorrowFourthClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayFourthClassTime)!
                let tomorrowFifthClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todayFifthClassTime)!
                let tomorrowSixthClassTime = Calendar.current.date(byAdding: .day, value: 1, to: todaySixthClassTime)!
                let tomorrowSixthClassEndTime = Calendar.current.date(byAdding: .day, value: 1, to: todaySixthClassEndTime)!
                let tomorrowClassUpdateTimes = [tomorrowFirstClassTime, tomorrowSecondClassTime, tomorrowThirdClassTime, tomorrowFourthClassTime, tomorrowFifthClassTime, tomorrowSixthClassTime, tomorrowSixthClassEndTime]

                let widgetInfo = WidgetInfo()
                widgetInfo.updateDate(newDate: Calendar.current.date(byAdding: .day, value: 1, to: widgetInfo.date)!)
                let tomorrowWidgetAllInfo = await widgetInfo.getWidgetAllInfo()
                // エラー発生時は更新頻度を10分毎に&表示をエラー表示に
                if tomorrowWidgetAllInfo.error {
                    let entries: [mediumWidgetDayInfoEntry] = [
                        mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: .content(period: 1, name: tomorrowWidgetAllInfo.event.content), nextLectureInfo: .content(period: 1, name: tomorrowWidgetAllInfo.event.content), lectureAllInfo: tomorrowWidgetAllInfo),
                    ]
                    let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 10, to: Date())!))
                    completion(timeline)
                }

                var entries: [mediumWidgetDayInfoEntry] = []
                var tomorrowExistLectures: [WidgetInfo.Lecture] = tomorrowWidgetAllInfo.lectures.filter { $0.exist }
                tomorrowExistLectures.insert(.empty(period: 0), at: 0)
                let tomorrowLastPeriod = (tomorrowExistLectures.last?.period ?? 0) + 1
                tomorrowExistLectures.append(.empty(period: tomorrowLastPeriod))

                for tomorrowExistLecturesIndex in 0..<tomorrowExistLectures.count {
                    if tomorrowExistLecturesIndex == 0 {
                        // 最初の授業が始まる前ならすぐに最初の授業の情報(or授業が全くない旨)を表示する．
                        if Date() < tomorrowClassUpdateTimes[tomorrowExistLectures[1].period - 1] {
                            entries.append(mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: tomorrowExistLectures[0], nextLectureInfo: tomorrowExistLectures[1], lectureAllInfo: tomorrowWidgetAllInfo))
                        }
                    } else {
                        let tomorrowClassUpdateTimesIndex = tomorrowExistLectures[tomorrowExistLecturesIndex].period - 1
                        if tomorrowExistLecturesIndex + 1 < tomorrowExistLectures.count {
                            entries.append(mediumWidgetDayInfoEntry(date: tomorrowClassUpdateTimes[tomorrowClassUpdateTimesIndex], nowLectureInfo: tomorrowExistLectures[tomorrowExistLecturesIndex], nextLectureInfo: tomorrowExistLectures[tomorrowExistLecturesIndex + 1], lectureAllInfo: tomorrowWidgetAllInfo))
                        } else {
                            entries.append(mediumWidgetDayInfoEntry(date: tomorrowClassUpdateTimes[tomorrowClassUpdateTimesIndex], nowLectureInfo: .empty(period: tomorrowLastPeriod), nextLectureInfo: .empty(period: tomorrowLastPeriod), lectureAllInfo: tomorrowWidgetAllInfo))
                        }
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

struct mediumWidgetDayInfoEntry: TimelineEntry {
    let date: Date
    let nowLectureInfo: WidgetInfo.Lecture
    let nextLectureInfo: WidgetInfo.Lecture
    let lectureAllInfo: WidgetInfo.WidgetAllInfo
}

struct mediumWidgetEntryView: View {
    let twintePrimaryColor = Color("PrimaryColor")
    let textDefaultColor = Color("WidgetMainText")
    let widgetBaseColor = Color("WidgetBackground")
    let noneLectureColor = Color("WidgetNoneText")
    let widgetRoomScheduleColor = Color("WidgetSubText")
    @Environment(\.widgetFamily) var family: WidgetFamily
    @Environment(\.colorScheme) var colorScheme

    var entry: mediumWidgetProvider.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.lectureAllInfo.module + " " + entry.lectureAllInfo.day)
                    .fontWeight(.bold)
                    .font(.subheadline)
                    .foregroundColor(textDefaultColor)
                    .lineSpacing(19.60)
                    .frame(width: 130, alignment: .leading)
                    .lineLimit(1)
                Text(entry.lectureAllInfo.event.content)
                    .fontWeight(entry.lectureAllInfo.event.normal ? .regular : .bold)
                    .font(.caption)
                    .lineSpacing(16.80)
                    .lineLimit(1)
                    .foregroundColor(entry.lectureAllInfo.event.normal ? textDefaultColor : Color(red: 232 / 256, green: 127 / 256, blue: 147 / 256))
                Text("\(String(entry.lectureAllInfo.lectureCount))コマの授業")
                    .font(.caption)
                    .lineSpacing(16.80)
                    .foregroundColor(twintePrimaryColor)
            }
            .padding(.leading, 25)
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("現在の授業")
                            .fontWeight(.medium)
                            .font(.caption2)
                            .lineSpacing(14)
                            .foregroundColor(textDefaultColor)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorScheme == .dark ? Color.black : Color.white)
                            .frame(maxWidth: 110, maxHeight: 5, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(widgetBaseColor, lineWidth: 1)
                                    .shadow(color: Color.white, radius: 2, x: 0, y: 5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .shadow(color: colorScheme == .dark ? Color(red: 31 / 256, green: 45 / 256, blue: 58 / 256) : Color(red: 132 / 256, green: 167 / 256, blue: 188 / 256), radius: 2, x: -2, y: -2.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.nowLectureInfo.name)
                            .fontWeight(.medium)
                            .font(.caption)
                            .foregroundColor(entry.nowLectureInfo.exist ? textDefaultColor : noneLectureColor)
                            .lineSpacing(16.80)
                            .lineLimit(1)
                            .frame(width: 150, alignment: .leading)

                        HStack(alignment: .top, spacing: 8) {
                            HStack(alignment: .top, spacing: 2) {
                                if colorScheme == .dark {
                                    Image(entry.nowLectureInfo.exist ? "room-dark" : "room-dark-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(entry.nowLectureInfo.exist ? "room" : "room-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }
                                Text(entry.nowLectureInfo.room)
                                    .font(.caption2)
                                    .foregroundColor(entry.nowLectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                    .lineSpacing(14)
                                    .lineLimit(1)
                                    .frame(width: 60, alignment: .leading)
                            }

                            HStack(alignment: .top, spacing: 2) {
                                if colorScheme == .dark {
                                    Image(entry.nowLectureInfo.exist ? "schedule-dark" : "schedule-dark-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(entry.nowLectureInfo.exist ? "schedule" : "schedule-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }
                                Text(entry.nowLectureInfo.startTime)
                                    .font(.caption2)
                                    .foregroundColor(entry.nowLectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                    .lineSpacing(14)
                                    .lineLimit(1)
                                    .frame(width: 30, alignment: .leading)
                            }
                        }
                    }
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
                            .frame(maxWidth: 110, maxHeight: 5, alignment: .leading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(widgetBaseColor, lineWidth: 1)
                                    .shadow(color: Color.white, radius: 2, x: 0, y: 5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .shadow(color: colorScheme == .dark ? Color(red: 31 / 256, green: 45 / 256, blue: 58 / 256) : Color(red: 132 / 256, green: 167 / 256, blue: 188 / 256), radius: 2, x: -2, y: -2.5)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.nextLectureInfo.name)
                            .fontWeight(.medium)
                            .font(.caption)
                            .foregroundColor(entry.nextLectureInfo.exist ? textDefaultColor : noneLectureColor)
                            .lineSpacing(16.80)
                            .lineLimit(1)
                            .frame(width: 150, alignment: .leading)

                        HStack(alignment: .top, spacing: 8) {
                            HStack(alignment: .top, spacing: 2) {
                                if colorScheme == .dark {
                                    Image(entry.nextLectureInfo.exist ? "room-dark" : "room-dark-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(entry.nextLectureInfo.exist ? "room" : "room-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }
                                Text(entry.nextLectureInfo.room)
                                    .font(.caption2)
                                    .foregroundColor(entry.nextLectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                    .lineSpacing(14)
                                    .lineLimit(1)
                                    .frame(width: 60, alignment: .leading)
                            }

                            HStack(alignment: .top, spacing: 2) {
                                if colorScheme == .dark {
                                    Image(entry.nextLectureInfo.exist ? "schedule-dark" : "schedule-dark-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(entry.nextLectureInfo.exist ? "schedule" : "schedule-disabled")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }
                                Text(entry.nextLectureInfo.startTime)
                                    .font(.caption2)
                                    .foregroundColor(entry.nextLectureInfo.exist ? widgetRoomScheduleColor : noneLectureColor)
                                    .lineSpacing(14)
                                    .lineLimit(1)
                                    .frame(width: 30, alignment: .leading)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(stops: [
                .init(color: Color("BorderShadowRight"), location: 0.0),
                .init(color: widgetBaseColor, location: 0.03),

            ]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("BorderColor"), lineWidth: 1.2))
            .compositingGroup()
            .shadow(radius: 10, x: 13, y: 0)
        }
        .background(widgetBaseColor)
        .cornerRadius(21.67)
    }
}

struct mediumWidget: Widget {
    let kind: String = "mediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: mediumWidgetProvider()) { entry in
            mediumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Twin:te")
        .description("現在の授業と次の授業を表示します")
        .supportedFamilies([.systemMedium])
    }
}

struct mediumWidget_Previews: PreviewProvider {
    static var previews: some View {
        mediumWidgetEntryView(entry: mediumWidgetDayInfoEntry(date: Date(), nowLectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)], nextLectureInfo: sampleWidgetAllInfo.lectures[Int.random(in: 0...5)], lectureAllInfo: sampleWidgetAllInfo))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
