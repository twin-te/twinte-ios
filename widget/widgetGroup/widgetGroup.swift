//
//  widgetGroup.swift
//  widgetGroup
//
//  Created by tako on 2021/07/17.
//  Copyright © 2021 tako. All rights reserved.
//

import SwiftUI
import WidgetKit

// サンプル表示用
func getDate(format: String = "MM/dd(EEE)") -> String {
    let formatter: DateFormatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
    formatter.locale = Locale(identifier: "ja")
    formatter.dateFormat = format
    return formatter.string(from: Date())
}

@main
struct widgetGroup: WidgetBundle {
    var body: some Widget {
        largeWidget()
        mediumWidget()
        smallWidget()
    }
}
