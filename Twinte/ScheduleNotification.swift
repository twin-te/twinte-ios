//
//  ScheduleNotification.swift
//  Twinte
//
//  Created by tako on 2021/03/23.
//  Copyright © 2021 tako. All rights reserved.
//
//  通知関連の機能を集めたクラス
import UIKit
import V4API

class ScheduleNotification {
    /// 全ての通知をスケジューリング
    func scheduleAllNotification() {
        ///
        /// デバッグ用
        ///

//                let center = UNUserNotificationCenter.current()
//                center.getPendingNotificationRequests { requests in
//                    print(requests.count)
//
//                    for element in requests {
//                        dump(element)
//                        print(element.content.body)
//                        print("****************************")
//                    }
//
//                }

        /// ここまで
        // 現在登録されている全ての通知を消去
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // UserDefaults のインスタンス
        guard let userDefaults = UserDefaults(suiteName: "group.net.twinte.app") else { return }
        if userDefaults.object(forKey: "notificationSwitch") != nil {
            if userDefaults.bool(forKey: "notificationSwitch") {
                fetchTomorrowEvents { events in
                    for event in events {
                        // イベントタイプが授業変更の時のみ通知
                        if event.type == .substituteDay || event.type == .holiday {
                            // 今日の設定された時間に通知をスケジュールする
                            var notificationTime = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                            notificationTime.hour = userDefaults.integer(forKey: "notificationHour")
                            notificationTime.minute = userDefaults.integer(forKey: "notificationMinute")

                            // print(element)
                            if event.type == .substituteDay {
                                self.createNotification(
                                    title: "特別日程のお知らせ",
                                    body: "明日は\(convertWeekdayToJapanese(event.changeTo))日課です。ウィジェットから詳細をご確認ください。",
                                    notificationTime: notificationTime,
                                )
                            } else {
                                self.createNotification(
                                    title: "臨時休講のお知らせ",
                                    body: "明日は\(event.description_p)のため休講です。詳細は学年暦をご覧ください。",
                                    notificationTime: notificationTime,
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    /// 通知をしてくれる関数
    /// - Parameters:
    ///   - title: 通知のタイトル
    ///   - body: 通知文の本文
    ///   - notificationTime: 通知したい時刻
    func createNotification(title: String, body: String, notificationTime: DateComponents) {
        // 通知の登録
        // プッシュ通知のインスタンス
        let notification = UNMutableNotificationContent()
        // 通知のタイトル
        notification.title = title
        // 通知の本文
        notification.body = body
        // 通知の音
        notification.sound = UNNotificationSound.default
        // 通知タイミングを指定
        let trigger = UNCalendarNotificationTrigger(dateMatching: notificationTime, repeats: false)
        // DateComponentsからDate形式に変換
        let date = Calendar.current.date(from: notificationTime)!
        // 通知のリクエスト
        let request = UNNotificationRequest(identifier: "\(getday(format: "yyyy-MM-dd", modifiedDate: date))", content: notification, trigger: trigger)
        // 通知を実装
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    /// 指定された日付を引数で指定されたフォーマットに変換
    /// - Parameters:
    ///   - format: 戻り値の日付のフォーマットを指定
    ///   - modifiedDate: 変換したい日付(UTC)
    /// - Returns: 日本標準時(GMT+9)で指定された形式で日付をStringで返す
    func getday(format: String, modifiedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        formatter.dateFormat = format
        return formatter.string(from: modifiedDate)
    }

    /// 明日のイベント情報の取得
    /// - Parameters:
    ///   - completion: 場合に応じてsemaphore.signal()を実行するとよい
    func fetchTomorrowEvents(completion: @escaping ([Schoolcalendar_V1_Event]) -> Void) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        V4APIClient.shared.schoolcalendarClient.listEventsByDate(
            request: .with { $0.date = convertDateToRFC3339FullDate(tomorrow) }
        ) { response in
            if let message = response.message {
                completion(message.events)
            } else {
                completion([])
            }
        }
    }
}
