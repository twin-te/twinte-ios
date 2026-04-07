//
//  AppWatchSessionManager.swift
//  Twinte
//
//  Created by Takayuki Ueno on 2025/05/22.
//  Copyright © 2025 tako. All rights reserved.
//

import WatchConnectivity
import V4API

struct WatchAppDto: Codable {
    let description: String
    let today: String
    let module: String
    // [月, 火, 水, 木, 金, 土]
    let timetable: [[Lecture]]
    
    let specials: [Lecture]
}

struct Lecture: Codable {
    let name: String
    let room: String
    let methods: [Int]
    let period: Int32
}

func fetchApiForWatch(date: Date) async -> WatchAppDto? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ja")
    formatter.dateFormat = "yyyy-MM-dd"
    let fmtDate = formatter.string(from: date as Date)
    
    let calendar = Calendar(identifier: .gregorian)
    async let timetableTask = withCheckedContinuation({ continuation in
        V4APIClient.shared.timetableClient.listRegisteredCourses(request: .with {
            var year = calendar.component(.year, from: date)
            if calendar.component(.month, from: date) <= 3 {
                year -= 1
            }
            var academicYear = Shared_AcademicYear()
            academicYear.value = Int32(year)
            
            $0.year = academicYear
        }) { result in
            continuation.resume(returning: result)
        }
    })
    let response = await withCheckedContinuation({ continuation in
        V4APIClient.shared.unifiedClient.getByDate(request: .with {
            $0.date = .with { $0.value = fmtDate }
        }) { result in
            continuation.resume(returning: result)
        }
    })
    
    
    guard let message = response.message else {
        return nil
    }
    
    var timetable = Array(repeating: [] as [Lecture], count: 6)
    var special: [Lecture] = []
    
    var displayToday = ""
    var displayDescription = ""
    var displayModule = ""
    
    if message.events.count > 0 {
        displayDescription = message.events[0].description_p
        // 日課変更がある場合にはchangeToに格納する
        if message.events[0].changeTo != .unspecified {
            //                today = message.events[0].changeTo
            displayToday = convertWeekdayToJapanese(message.events[0].changeTo)
        }
    }
    
    if message.module != .unspecified {
        displayModule = convertModuleToJapanese(message.module)
    }
    
    let courses = await timetableTask
    guard let timetableMessage = courses.message else {
        return WatchAppDto(description: displayDescription, today: displayToday, module: displayModule, timetable: timetable, specials: [])
    }
    
    for course in timetableMessage.registeredCourses {
        let schedules = course.schedules.filter({ schedule in
            areModulesEquivalent(schedule.module, message.module)
        })
        for schedule in schedules {
            let methods = course.methods.map({ method in method.rawValue})
            let lecture = Lecture(
                name: course.name,
                room: schedule.locations,
                methods: methods,
                period: schedule.period
            )
            
            if case .UNRECOGNIZED(_) = schedule.day {
                continue
            }
            
            if schedule.day == .anyTime || schedule.day == .appointment ||
                schedule.day == .intensive || schedule.day == .nt || schedule.day == .unspecified {
                special.append(lecture)
                continue
            }
            
            let weekday = switch schedule.day {
            case .sun: 0
            case .mon: 1
            case .tue: 2
            case .wed: 3
            case .thu: 4
            case .fri: 5
            case .sat: 6
            default: -1
            }
            
            timetable[weekday].append(Lecture(
                name: course.name,
                room: schedule.locations,
                methods: methods,
                period: schedule.period,
            ))
        }
    }
    special.sort(by: { $0.period < $1.period })
    for i in 0..<6 {
        timetable[i].sort(by: { $0.period < $1.period })
    }
    
    return WatchAppDto(description: displayDescription, today: displayToday, module: displayModule, timetable: timetable, specials: special)
}

class AppWatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = AppWatchSessionManager()
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            
            print("iOS: WCSession activated")
        } else {
            print("iOS: WCSession not supported")
        }
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("iOS: Session activated with state: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS: inactivated")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS: deactivated")
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        print("iOS: received message \(message)")
        let req = message["request"] as? String
        
        if req == "fetchTimetable" {
            let date = Date()
            Task {
                let result = await fetchApiForWatch(date: date)
                guard let res = result else {
                    replyHandler(["error": "Fetch error."])
                    return
                }
                let encoder = JSONEncoder()
                let encoded = try encoder.encode(res)
                replyHandler(["data": encoded])
            }
        } else {
            replyHandler(["error": "Unknown request."])
        }
    }
}
