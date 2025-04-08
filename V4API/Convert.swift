//
//  Convert.swift
//  Twinte
//
//  Created by User on 2025/04/06.
//  Copyright © 2025 tako. All rights reserved.
//

import Foundation

public func convertModuleToJapanese(_ module: Schoolcalendar_V1_Module) -> String {
    switch module {
    case .springA: return "春A"
    case .springB: return "春AB"
    case .springC: return "春C"
    case .summerVacation: return "夏休み"
    case .fallA: return "秋A"
    case .fallB: return "秋B"
    case .fallC: return "秋C"
    case .springVacation: return "春休み"
    default: return ""
    }
}

public func convertWeekdayToJapanese(_ weekday: Shared_Weekday) -> String {
    switch weekday {
    case .sunday: return "日曜"
    case .monday: return "月曜"
    case .tuesday: return "火曜"
    case .wednesday: return "水曜"
    case .thursday: return "木曜"
    case .friday: return "金曜"
    case .saturday: return "土曜"
    default: return "特殊"
    }
}

public func convertDateToWeekday(_ date: Date) -> Shared_Weekday {
    let weekdayNumber = Calendar.current.component(.weekday, from: date)

    switch weekdayNumber {
    case 1: return .sunday
    case 2: return .monday
    case 3: return .tuesday
    case 4: return .wednesday
    case 5: return .thursday
    case 6: return .friday
    case 7: return .saturday
    default: return .unspecified
    }
}

public func areWeekdaysEquivalent(_ s: Timetable_V1_Day, _ t: Shared_Weekday) -> Bool {
    switch s {
    case .sun: return t == .sunday
    case .mon: return t == .monday
    case .tue: return t == .tuesday
    case .wed: return t == .wednesday
    case .thu: return t == .thursday
    case .fri: return t == .friday
    case .sat: return t == .saturday
    default: return false
    }
}

public func areModulesEquivalent(_ s: Timetable_V1_Module, _ t: Schoolcalendar_V1_Module) -> Bool {
    switch s {
    case .springA: return t == .springA
    case .springB: return t == .springB
    case .springC: return t == .springC
    case .summerVacation: return t == .summerVacation
    case .fallA: return t == .fallA
    case .fallB: return t == .fallB
    case .fallC: return t == .fallC
    case .springVacation: return t == .springVacation
    default: return false
    }
}
