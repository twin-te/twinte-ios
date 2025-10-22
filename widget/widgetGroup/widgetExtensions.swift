//
//  widgetExtensions.swift
//  Twinte
//
//  Created by User on 2025/10/22.
//  Copyright © 2025 tako. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func widgetBackground(_ style: some ShapeStyle) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                ContainerRelativeShape().foregroundStyle(style)
            }
        } else {
            self.background(style)
        }
    }
}
