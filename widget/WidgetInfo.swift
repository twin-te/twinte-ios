//
//  WidgetInfo.swift
//  Twinte
//
//  Created by takonasu on 2022/11/21.
//  Copyright © 2023 tako. All rights reserved.
//

import Connect
import Foundation
import V4API

class WidgetInfo {
    private(set) var date: Date = Date()
    // 任意の日付を設定することができる
    // private(set) var date:Date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2023, month: 1, day: 23))!

    struct WidgetAllInfo {
        var day: String
        var module: String
        var event: Event
        var lectures: [Lecture]
        var lectureCount: Int
        var error: Bool

        struct Event {
            var normal: Bool // 祝日や通常日課はtrue，授業振替がある場合はfalse
            var content: String
        }
    }

    struct Lecture: Hashable {
        let period: Int
        let startTime: String
        let name: String
        let room: String
        let methods: [Timetable_V1_CourseMethod]
        let exist: Bool // 授業が登録されているかどうか．されていない場合他の情報は無視される．

        static func empty(period: Int) -> WidgetInfo.Lecture {
            return WidgetInfo.Lecture(period: period, startTime: "-", name: "授業がありません", room: "-", methods: [], exist: false)
        }

        static func content(period: Int, name: String) -> WidgetInfo.Lecture {
            return WidgetInfo.Lecture(period: period, startTime: "-", name: name, room: "-", methods: [], exist: false)
        }
    }

    func updateDate(newDate: Date) {
        self.date = newDate
    }

    func getWidgetAllInfo() async -> WidgetAllInfo {
        let response = await V4APIClient.shared.unifiedClient.getByDate(request: .with {
            $0.date = .with { $0.value = dateToString() }
        })
        guard let message = response.message else {
            print(response)
            return handleError(error: response.error!)
        }

        // 日課変更がない場合は指定された日の曜日を取得
        // ある場合には後ほど格納
        var changeTo = convertDateToWeekday(self.date)

        var event: WidgetAllInfo.Event
        if let eventMsg = message.events.first {
            if eventMsg.changeTo != .unspecified {
                // 日課変更がある場合
                changeTo = eventMsg.changeTo
                event = WidgetAllInfo.Event(
                    normal: false,
                    content: convertWeekdayToJapanese(changeTo) + "日課",
                )
            } else {
                // 日課変更でないイベントがある場合
                event = WidgetAllInfo.Event(
                    normal: true,
                    content: eventMsg.description_p,
                )
            }
        } else {
            // 通常日課
            event = WidgetAllInfo.Event(normal: true, content: "通常日課")
        }

        // 重複ありでとりあえず今日登録してる授業一覧を格納
        var todayLectureList: [Lecture] = []
        for course in message.registeredCourses {
            // 今日のモジュールかつ、今日の曜日(日課変更の場合は変更後の曜日)のもの
            let newScheduleArray = course.schedules.filter { schedule in
                areModulesEquivalent(schedule.module, message.module) && areWeekdaysEquivalent(schedule.day, changeTo)
            }
            for schedule in newScheduleArray {
                todayLectureList.append(Lecture(
                    period: Int(schedule.period),
                    startTime: convertPeriodToLectureStartTime(period: Int(schedule.period)),
                    name: course.name,
                    room: schedule.locations,
                    methods: course.methods,
                    exist: true,
                ))
            }
        }
        // 授業時間順にソート
        todayLectureList.sort(by: { $0.period < $1.period })

        var lectureCount = 0
        var todayLectureListWithoutDuplicate: [Lecture] = []
        for i in 1...6 {
            let tmpArray = todayLectureList.filter { $0.period == i }
            if tmpArray.count > 1 { // その時間の授業が2つ以上ある場合
                todayLectureListWithoutDuplicate.append(Lecture(period: i, startTime: convertPeriodToLectureStartTime(period: i), name: "授業が重複しています", room: "", methods: [], exist: true))
            } else if tmpArray.count == 0 { // その時限に授業が登録されていない場合
                todayLectureListWithoutDuplicate.append(.empty(period: i))
            } else {
                todayLectureListWithoutDuplicate.append(tmpArray[0])
                lectureCount += 1
            }
        }

        return WidgetAllInfo(
            day: dateToString(format: "MM/dd(EEE)"),
            module: convertModuleToJapanese(message.module),
            event: event,
            lectures: todayLectureListWithoutDuplicate,
            lectureCount: lectureCount,
            error: false,
        )

        func handleError(error: ConnectError) -> WidgetAllInfo {
            let (errorCode, messages) = switch error.code {
            case .unknown:
                (1, ["エラーが発生", "しました。", "時間を置いて", "アプリを再起動後", "改善しない場合", "運営にご連絡ください。"])
            case .unimplemented:
                (2, ["エラーが発生", "しました。", "時間を置いて", "アプリを再起動後", "改善しない場合", "運営にご連絡ください。"])
            case .unavailable:
                (4, ["エラーが発生", "しました。", "インターネット接続", "をご確認ください。", "改善しない場合", "運営にご連絡ください。"])
            case .unauthenticated:
                (6, ["未認証です。", "Twin:teに", "ログインしてください。", "ログイン済みの場合は", "アプリを再起動して", "やり直してください。"])
            default:
                (7, ["エラーが発生しました。", "アプリ・端末の", "再起動を", "お試しください。", "運営にご連絡", "ください。"])
            }
            return WidgetAllInfo(
                day: dateToString(format: "MM/dd(EEE)"),
                module: "",
                event: WidgetAllInfo.Event(normal: false, content: "Error:\(errorCode)"),
                lectures: messages.enumerated().map { i, message in .content(period: i, name: message) },
                lectureCount: 0,
                error: true
            )
        }

        // 授業時限と開始時間の対応
        func convertPeriodToLectureStartTime(period: Int) -> String {
            switch period {
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
        case badStatus(statusCode: Int)
        case invalidURL
        case responseError
    }

    private enum AppInternalError: Error {
        case jsonDecodeError
        case cookieError
    }
}

let sampleWidgetAllInfo = WidgetInfo.WidgetAllInfo(
    day: "10/14(木)", module: "秋A", event: WidgetInfo.WidgetAllInfo.Event(normal: true, content: "通常日課"), lectures: [
        WidgetInfo.Lecture(period: 1, startTime: "8:40", name: "つくば市史概論", room: "1B202", methods: [], exist: true),
        WidgetInfo.Lecture(period: 2, startTime: "10:10", name: "基礎ネコ語AII", room: "平砂宿舎", methods: [], exist: true),
        WidgetInfo.Lecture(period: 3, startTime: "12:15", name: "授業がありません", room: "-", methods: [], exist: false),
        WidgetInfo.Lecture(period: 4, startTime: "13:45", name: "筑波大学〜野草と食〜", room: "4C213", methods: [], exist: true),
        WidgetInfo.Lecture(period: 5, startTime: "15:15", name: "東京教育大学の遺産", room: "春日講堂", methods: [], exist: true),
        WidgetInfo.Lecture(period: 6, startTime: "16:45", name: "日常系作品の実際", room: "オンライン", methods: [], exist: true),
    ], lectureCount: 5, error: false
)
